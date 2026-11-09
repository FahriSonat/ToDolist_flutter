/// Kullanıcı bildirim ve uygulama ayarları (project.md & architucture.md)
class SettingsEntity {
  final bool notificationsEnabled;
  final bool hourlySummaryEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool quietHoursEnabled;
  final int quietHoursStartHour;
  final int quietHoursStartMinute;
  final int quietHoursEndHour;
  final int quietHoursEndMinute;

  const SettingsEntity({
    this.notificationsEnabled = true,
    this.hourlySummaryEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.quietHoursEnabled = false,
    this.quietHoursStartHour = 22,
    this.quietHoursStartMinute = 0,
    this.quietHoursEndHour = 8,
    this.quietHoursEndMinute = 0,
  });

  /// Verilen yerel zamanın sessiz saatler aralığında olup olmadığını kontrol eder
  bool isWithinQuietHours(DateTime localTime) {
    if (!quietHoursEnabled) return false;

    final currentMinutes = localTime.hour * 60 + localTime.minute;
    final startMinutes = quietHoursStartHour * 60 + quietHoursStartMinute;
    final endMinutes = quietHoursEndHour * 60 + quietHoursEndMinute;

    if (startMinutes <= endMinutes) {
      // Örn: 01:00 - 06:00
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    } else {
      // Geceyi aşan aralık, örn: 22:00 - 08:00
      return currentMinutes >= startMinutes || currentMinutes < endMinutes;
    }
  }

  SettingsEntity copyWith({
    bool? notificationsEnabled,
    bool? hourlySummaryEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? quietHoursEnabled,
    int? quietHoursStartHour,
    int? quietHoursStartMinute,
    int? quietHoursEndHour,
    int? quietHoursEndMinute,
  }) {
    return SettingsEntity(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      hourlySummaryEnabled: hourlySummaryEnabled ?? this.hourlySummaryEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStartHour: quietHoursStartHour ?? this.quietHoursStartHour,
      quietHoursStartMinute: quietHoursStartMinute ?? this.quietHoursStartMinute,
      quietHoursEndHour: quietHoursEndHour ?? this.quietHoursEndHour,
      quietHoursEndMinute: quietHoursEndMinute ?? this.quietHoursEndMinute,
    );
  }
}
