import 'package:priority_todo/core/clock/clock.dart';
import 'package:priority_todo/features/settings/domain/settings_entity.dart';
import 'package:priority_todo/features/todos/domain/entities/todo.dart';
import 'package:priority_todo/features/todos/domain/repositories/todo_repository.dart';
import 'package:priority_todo/platform/notification/notification_service.dart';

/// Bildirim planlayıcı ve saatlik değerlendirici (architucture.md & project.md)
class ReminderScheduler {
  final TodoRepository repository;
  final NotificationService notificationService;
  final Clock clock;

  ReminderScheduler({
    required this.repository,
    required this.notificationService,
    this.clock = const SystemClock(),
  });

  /// Görev kaydedildiğinde veya güncellendiğinde çağrılır
  Future<void> onTodoSaved(Todo todo, SettingsEntity settings) async {
    if (todo.isDone) {
      await notificationService.cancelTodoNotifications(todo.id);
    } else {
      await notificationService.scheduleDueNotification(todo, settings);
    }
  }

  /// Görev silindiğinde çağrılır
  Future<void> onTodoDeleted(String todoId) async {
    await notificationService.cancelTodoNotifications(todoId);
  }

  /// Görev tamamlandığında veya geri açıldığında çağrılır
  Future<void> onTodoToggled(Todo todo, SettingsEntity settings) async {
    if (todo.isDone) {
      await notificationService.cancelTodoNotifications(todo.id);
    } else {
      await notificationService.scheduleDueNotification(todo, settings);
    }
  }

  /// Uygulama açılışında veya saat/reboot değişiminde tüm planları yeniden hesaplar
  Future<void> rescheduleAll(SettingsEntity settings) async {
    if (!settings.notificationsEnabled) {
      await notificationService.cancelAllNotifications();
      return;
    }

    final openTodos = await repository.getTodos(isDone: false);
    for (final todo in openTodos) {
      if (todo.dueAtUtc != null) {
        await notificationService.scheduleDueNotification(todo, settings);
      }
    }

    // Saatlik özet kontrolü
    await evaluateHourlySummary(settings);
  }

  /// Açık yüksek/kritik görevleri değerlendirir ve gerekiyorsa tek özet üretir
  Future<void> evaluateHourlySummary(SettingsEntity settings) async {
    if (!settings.notificationsEnabled || !settings.hourlySummaryEnabled) return;

    final urgentTodos = await repository.getUrgentPendingTodos();
    if (urgentTodos.isEmpty) return;

    final nowUtc = clock.nowUtc();
    final candidateTodos = <Todo>[];

    for (final todo in urgentTodos) {
      final lastReminded = todo.lastRemindedAtUtc;
      // Aynı görev için 60 dakika dolmadan ikinci bildirim üretilmez (project.md)
      if (lastReminded == null || nowUtc.difference(lastReminded).inMinutes >= 60) {
        candidateTodos.add(todo);
      }
    }

    if (candidateTodos.isNotEmpty) {
      await notificationService.showHourlySummaryNotification(
        urgentTodos: candidateTodos,
        settings: settings,
      );

      // Görevlerin last_reminded_at_utc alanını güncelle
      for (final todo in candidateTodos) {
        await repository.updateLastRemindedAt(todo.id, nowUtc);
      }
    }
  }
}
