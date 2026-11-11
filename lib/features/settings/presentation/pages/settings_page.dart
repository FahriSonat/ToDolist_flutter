import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../todos/application/todo_providers.dart';
import '../../application/settings_notifier.dart';

/// Ayarlar Ekranı (project.md & design.md)
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final notifService = ref.read(notificationServiceProvider);
    final status = await notifService.checkPermissionStatus();
    if (mounted) {
      setState(() => _hasPermission = status);
    }
  }

  Future<void> _requestPermission() async {
    final notifService = ref.read(notificationServiceProvider);
    final granted = await notifService.requestPermissions();
    if (mounted) {
      setState(() => _hasPermission = granted);
      if (granted) {
        ref.read(settingsNotifierProvider.notifier).setNotificationsEnabled(true);
      }
    }
  }

  Future<void> _selectTime({
    required BuildContext context,
    required int currentHour,
    required int currentMinute,
    required void Function(int hour, int minute) onSelected,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentHour, minute: currentMinute),
      builder: (context, child) {
        return Theme(
          data: AppTheme.darkTheme,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      onSelected(picked.hour, picked.minute);
    }
  }

  String _formatTime(int hour, int minute) {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _handleClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tüm Verileri Sil'),
        content: const Text(
          'Tüm görevler, kontrol listeleri ve hatırlatıcılar kalıcı olarak silinecek. Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.priorityCritical,
              foregroundColor: AppTheme.textPrimary,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Evet, Hepsini Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(todoActionControllerProvider.notifier)
          .clearAllData();

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tüm veriler başarıyla silindi.'),
            backgroundColor: AppTheme.surfaceRaised,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsNotifierProvider);
    final settingsNotifier = ref.read(settingsNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        leading: IconButton(
          tooltip: 'Geri',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: settingsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.textPrimary),
        ),
        error: (err, _) => Center(child: Text('Hata: $err')),
        data: (settings) {
          return ListView(
            padding: const EdgeInsets.all(AppTheme.pagePadding),
            children: [
              // Bildirim İzni Durum Kartı
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  border: Border.all(
                    color: _hasPermission ? AppTheme.divider : AppTheme.priorityHigh,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _hasPermission ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                      color: _hasPermission ? AppTheme.textPrimary : AppTheme.priorityHigh,
                      size: 28,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _hasPermission ? 'Bildirim İzni Aktif' : 'Bildirimler Kapalı',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _hasPermission
                                ? 'Öncelikli görev uyarıları ve son tarih alarmları iletilecektir.'
                                : 'Hatırlatıcıları alabilmek için bildirim izni vermelisiniz.',
                            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    if (!_hasPermission)
                      ElevatedButton(
                        onPressed: _requestPermission,
                        child: const Text('İzin Ver'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // BİLDİRİM VE HATIRLATICILAR BÖLÜMÜ
              const Text(
                'BİLDİRİM VE HATIRLATICILAR',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Hatırlatmaları Etkinleştir'),
                      subtitle: const Text(
                        'Tüm yerel alarmlar ve özetleri yönetir',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                      value: settings.notificationsEnabled,
                      activeThumbColor: AppTheme.textPrimary,
                      onChanged: (val) => settingsNotifier.setNotificationsEnabled(val),
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('Saatlik Acil Görev Özeti'),
                      subtitle: const Text(
                        'Açık kritik/yüksek görevler için periyodik durum özeti',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                      value: settings.hourlySummaryEnabled,
                      activeThumbColor: AppTheme.textPrimary,
                      onChanged: settings.notificationsEnabled
                          ? (val) => settingsNotifier.setHourlySummaryEnabled(val)
                          : null,
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('Bildirim Sesi'),
                      value: settings.soundEnabled,
                      activeThumbColor: AppTheme.textPrimary,
                      onChanged: settings.notificationsEnabled
                          ? (val) => settingsNotifier.setSoundEnabled(val)
                          : null,
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('Titreşim'),
                      value: settings.vibrationEnabled,
                      activeThumbColor: AppTheme.textPrimary,
                      onChanged: settings.notificationsEnabled
                          ? (val) => settingsNotifier.setVibrationEnabled(val)
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // SESSİZ SAATLER
              const Text(
                'SESSİZ SAATLER',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Sessiz Saatleri Aç'),
                      subtitle: const Text(
                        'Belirtilen zaman aralığında bildirim gönderilmez',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                      value: settings.quietHoursEnabled,
                      activeThumbColor: AppTheme.textPrimary,
                      onChanged: (val) => settingsNotifier.setQuietHoursEnabled(val),
                    ),
                    if (settings.quietHoursEnabled) ...[
                      const Divider(),
                      ListTile(
                        title: const Text('Başlangıç Saati'),
                        trailing: Text(
                          _formatTime(settings.quietHoursStartHour, settings.quietHoursStartMinute),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        onTap: () => _selectTime(
                          context: context,
                          currentHour: settings.quietHoursStartHour,
                          currentMinute: settings.quietHoursStartMinute,
                          onSelected: (h, m) {
                            settingsNotifier.setQuietHoursInterval(
                              startHour: h,
                              startMinute: m,
                              endHour: settings.quietHoursEndHour,
                              endMinute: settings.quietHoursEndMinute,
                            );
                          },
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        title: const Text('Bitiş Saati'),
                        trailing: Text(
                          _formatTime(settings.quietHoursEndHour, settings.quietHoursEndMinute),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        onTap: () => _selectTime(
                          context: context,
                          currentHour: settings.quietHoursEndHour,
                          currentMinute: settings.quietHoursEndMinute,
                          onSelected: (h, m) {
                            settingsNotifier.setQuietHoursInterval(
                              startHour: settings.quietHoursStartHour,
                              startMinute: settings.quietHoursStartMinute,
                              endHour: h,
                              endMinute: m,
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // AÇIK DAVRANIŞ VE PİL BİLGİLENDİRMESİ (project.md ilkesi)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceRaised,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, color: AppTheme.textSecondary, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Açık Davranış: Android sisteminizin pil optimizasyonları ve kısıtlamaları nedeniyle bildirimler tam dakikasında gelmeyebilir veya gecikebilir. Tam verim için telefon ayarlarından uygulamanın pil tasarrufunu "Kısıtlamasız" yapabilirsiniz.',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // GİZLİLİK VE VERİ GÜVENLİĞİ
              const Text(
                'GİZLİLİK & GÜVENLİK',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '100% Cihaz İçi Depolama',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Görevleriniz, uzun notlarınız ve kontrol listeleriniz asla bir sunucuya veya buluta aktarılmaz. Reklam veya izleme SDK\'sı bulunmaz.',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // VERİ TEMİZLEME BUTONU
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surfaceRaised,
                  foregroundColor: AppTheme.priorityCritical,
                  side: const BorderSide(color: AppTheme.priorityCritical),
                ),
                onPressed: _handleClearAll,
                icon: const Icon(Icons.delete_forever_rounded),
                label: const Text('Tüm Verileri Sil'),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}
