import 'package:shared_preferences/shared_preferences.dart';
import '../domain/settings_entity.dart';

/// Ayarlar için SharedPreferences deposu
class SettingsRepository {
  static const String _keyNotifications = 'settings_notifications_enabled';
  static const String _keyHourlySummary = 'settings_hourly_summary_enabled';
  static const String _keySound = 'settings_sound_enabled';
  static const String _keyVibration = 'settings_vibration_enabled';
  static const String _keyQuietHoursEnabled = 'settings_quiet_hours_enabled';
  static const String _keyQuietStartHour = 'settings_quiet_start_hour';
  static const String _keyQuietStartMinute = 'settings_quiet_start_minute';
  static const String _keyQuietEndHour = 'settings_quiet_end_hour';
  static const String _keyQuietEndMinute = 'settings_quiet_end_minute';

  Future<SettingsEntity> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsEntity(
      notificationsEnabled: prefs.getBool(_keyNotifications) ?? true,
      hourlySummaryEnabled: prefs.getBool(_keyHourlySummary) ?? true,
      soundEnabled: prefs.getBool(_keySound) ?? true,
      vibrationEnabled: prefs.getBool(_keyVibration) ?? true,
      quietHoursEnabled: prefs.getBool(_keyQuietHoursEnabled) ?? false,
      quietHoursStartHour: prefs.getInt(_keyQuietStartHour) ?? 22,
      quietHoursStartMinute: prefs.getInt(_keyQuietStartMinute) ?? 0,
      quietHoursEndHour: prefs.getInt(_keyQuietEndHour) ?? 8,
      quietHoursEndMinute: prefs.getInt(_keyQuietEndMinute) ?? 0,
    );
  }

  Future<void> saveSettings(SettingsEntity settings) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setBool(_keyNotifications, settings.notificationsEnabled),
      prefs.setBool(_keyHourlySummary, settings.hourlySummaryEnabled),
      prefs.setBool(_keySound, settings.soundEnabled),
      prefs.setBool(_keyVibration, settings.vibrationEnabled),
      prefs.setBool(_keyQuietHoursEnabled, settings.quietHoursEnabled),
      prefs.setInt(_keyQuietStartHour, settings.quietHoursStartHour),
      prefs.setInt(_keyQuietStartMinute, settings.quietHoursStartMinute),
      prefs.setInt(_keyQuietEndHour, settings.quietHoursEndHour),
      prefs.setInt(_keyQuietEndMinute, settings.quietHoursEndMinute),
    ]);
  }
}
