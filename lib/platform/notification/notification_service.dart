import 'dart:async';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../features/settings/domain/settings_entity.dart';
import '../../features/todos/domain/entities/todo.dart';

/// Bildirim adaptörü ve servisi (architucture.md)
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final StreamController<String> _onNotificationClick = StreamController<String>.broadcast();

  Stream<String> get onNotificationClick => _onNotificationClick.stream;

  static const String channelUrgentId = 'urgent_reminders';
  static const String channelScheduledId = 'scheduled_reminders';
  static const String channelSummaryId = 'silent_summary';

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const linuxSettings = LinuxInitializationSettings(defaultActionName: 'Aç');

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
      linux: linuxSettings,
    );

    await _notifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _onNotificationClick.add(payload);
        }
      },
    );

    await _createNotificationChannels();
  }

  Future<void> _createNotificationChannels() async {
    if (!Platform.isAndroid) return;

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          channelUrgentId,
          'Acil Görev Hatırlatmaları',
          description: 'Yüksek ve kritik öncelikli görevler için yerel uyarılar',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          channelScheduledId,
          'Son Tarih Hatırlatmaları',
          description: 'Görevin son teslim zamanında gelen uyarılar',
          importance: Importance.defaultImportance,
          playSound: true,
          enableVibration: true,
        ),
      );

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          channelSummaryId,
          'Saatlik Özet Bildirimleri',
          description: 'Bekleyen açık görevlerin periyodik durum özeti',
          importance: Importance.low,
          playSound: false,
          enableVibration: false,
        ),
      );
    }
  }

  /// Bildirim izinlerini ister
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidPlugin?.requestNotificationsPermission();
      return granted ?? false;
    } else if (Platform.isIOS || Platform.isMacOS) {
      final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true;
  }

  /// İzin durumunu kontrol eder
  Future<bool> checkPermissionStatus() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.areNotificationsEnabled() ?? false;
    }
    return true;
  }

  /// Görev ID'sinden sayısal bildirim ID'si türetir
  int _notificationId(String todoId, [int offset = 0]) {
    return (todoId.hashCode.abs() % 2147483000) + offset;
  }

  /// Görev için son tarih hatırlatması planlar
  Future<void> scheduleDueNotification(Todo todo, SettingsEntity settings) async {
    if (!settings.notificationsEnabled || todo.isDone || todo.dueAtUtc == null) {
      await cancelTodoNotifications(todo.id);
      return;
    }

    final localDue = todo.dueAtUtc!.toLocal();
    final now = DateTime.now();
    if (localDue.isBefore(now)) return; // Süresi geçmiş

    // Sessiz saat kontrolü
    if (settings.isWithinQuietHours(localDue)) return;

    final id = _notificationId(todo.id, 1);
    final tzDue = tz.TZDateTime.from(localDue, tz.local);

    final androidDetails = AndroidNotificationDetails(
      channelScheduledId,
      'Son Tarih Hatırlatmaları',
      importance: Importance.high,
      priority: Priority.high,
      playSound: settings.soundEnabled,
      enableVibration: settings.vibrationEnabled,
    );

    try {
      await _notifications.zonedSchedule(
        id: id,
        title: 'Son Tarih: ${todo.title}',
        body: todo.note.isNotEmpty ? todo.note : '${todo.priority.label} öncelikli görev yaklaşıyor.',
        scheduledDate: tzDue,
        notificationDetails: NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: todo.id,
      );
    } catch (_) {
      // Kesin alarm izni yoksa esnek planlama fallback
      await _notifications.zonedSchedule(
        id: id,
        title: 'Son Tarih: ${todo.title}',
        body: todo.note.isNotEmpty ? todo.note : '${todo.priority.label} öncelikli görev yaklaşıyor.',
        scheduledDate: tzDue,
        notificationDetails: NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: todo.id,
      );
    }
  }

  /// Acil/Kritik görevler için saatlik tek özet bildirimi üretir
  Future<void> showHourlySummaryNotification({
    required List<Todo> urgentTodos,
    required SettingsEntity settings,
  }) async {
    if (!settings.notificationsEnabled || !settings.hourlySummaryEnabled) return;
    if (urgentTodos.isEmpty) return;

    final now = DateTime.now();
    if (settings.isWithinQuietHours(now)) return;

    final count = urgentTodos.length;
    final topTodo = urgentTodos.first;
    final title = '$count Acil Görev Bekliyor';
    final body = count == 1
        ? '${topTodo.title} (${topTodo.priority.label})'
        : '${topTodo.title} ve ${count - 1} görev daha ilgini bekliyor.';

    final androidDetails = AndroidNotificationDetails(
      channelUrgentId,
      'Acil Görev Hatırlatmaları',
      importance: Importance.high,
      priority: Priority.high,
      playSound: settings.soundEnabled,
      enableVibration: settings.vibrationEnabled,
    );

    await _notifications.show(
      id: 999999, // Tek özet bildirim kanalı
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: androidDetails),
      payload: topTodo.id,
    );
  }

  /// Görev tamamlandığında veya silindiğinde planlı tüm bildirimleri iptal eder
  Future<void> cancelTodoNotifications(String todoId) async {
    final id1 = _notificationId(todoId, 0);
    final id2 = _notificationId(todoId, 1);
    await _notifications.cancel(id: id1);
    await _notifications.cancel(id: id2);
  }

  /// Tüm bildirimleri iptal eder
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
