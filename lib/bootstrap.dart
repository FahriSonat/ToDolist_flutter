import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/utils/app_date_format.dart';
import 'features/settings/data/settings_repository.dart';
import 'features/todos/application/reminder_scheduler.dart';
import 'features/todos/data/repositories/sqlite_todo_repository.dart';
import 'features/todos/presentation/pages/todo_detail_page.dart';
import 'platform/notification/notification_service.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// Uygulama başlatma ve altyapı kurulumu (architucture.md)
Future<ProviderContainer> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Tarih ve saat formatlama yerelleştirmesini başlat (tr_TR)
  await AppDateFormat.initialize();

  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Bildirim servisini başlat
  final notifService = NotificationService();
  await notifService.initialize();

  // Bildirime tıklandığında ilgili detayı açma dinleyicisi
  notifService.onNotificationClick.listen((todoId) {
    if (todoId.isNotEmpty) {
      appNavigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => TodoDetailPage(todoId: todoId)),
      );
    }
  });

  final container = ProviderContainer();

  // Açılışta bildirim planlarını yeniden hesapla (architucture.md kuralı)
  try {
    final settingsRepo = SettingsRepository();
    final settings = await settingsRepo.loadSettings();
    final todoRepo = SqliteTodoRepository();
    final scheduler = ReminderScheduler(
      repository: todoRepo,
      notificationService: notifService,
    );
    await scheduler.rescheduleAll(settings);
  } catch (_) {
    // Açılış planlama hataları uygulamayı kilitlemez
  }

  return container;
}
