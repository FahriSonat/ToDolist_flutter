import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/settings_repository.dart';
import '../domain/settings_entity.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

class SettingsNotifier extends Notifier<AsyncValue<SettingsEntity>> {
  SettingsRepository get _repository => ref.read(settingsRepositoryProvider);

  @override
  AsyncValue<SettingsEntity> build() {
    load();
    return const AsyncValue.loading();
  }

  Future<void> load() async {
    try {
      final settings = await _repository.loadSettings();
      state = AsyncValue.data(settings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateSettings(SettingsEntity newSettings) async {
    state = AsyncValue.data(newSettings);
    await _repository.saveSettings(newSettings);
  }

  Future<void> setNotificationsEnabled(bool value) async {
    final current = state.asData?.value ?? const SettingsEntity();
    final updated = current.copyWith(notificationsEnabled: value);
    await updateSettings(updated);
  }

  Future<void> setHourlySummaryEnabled(bool value) async {
    final current = state.asData?.value ?? const SettingsEntity();
    final updated = current.copyWith(hourlySummaryEnabled: value);
    await updateSettings(updated);
  }

  Future<void> setSoundEnabled(bool value) async {
    final current = state.asData?.value ?? const SettingsEntity();
    final updated = current.copyWith(soundEnabled: value);
    await updateSettings(updated);
  }

  Future<void> setVibrationEnabled(bool value) async {
    final current = state.asData?.value ?? const SettingsEntity();
    final updated = current.copyWith(vibrationEnabled: value);
    await updateSettings(updated);
  }

  Future<void> setQuietHoursEnabled(bool value) async {
    final current = state.asData?.value ?? const SettingsEntity();
    final updated = current.copyWith(quietHoursEnabled: value);
    await updateSettings(updated);
  }

  Future<void> setQuietHoursInterval({
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
  }) async {
    final current = state.asData?.value ?? const SettingsEntity();
    final updated = current.copyWith(
      quietHoursStartHour: startHour,
      quietHoursStartMinute: startMinute,
      quietHoursEndHour: endHour,
      quietHoursEndMinute: endMinute,
    );
    await updateSettings(updated);
  }
}

final settingsNotifierProvider =
    NotifierProvider<SettingsNotifier, AsyncValue<SettingsEntity>>(SettingsNotifier.new);
