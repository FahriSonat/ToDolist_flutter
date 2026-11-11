import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// Güvenli, çökmeyen tarih ve saat formatlama yardımcı sınıfı
class AppDateFormat {
  AppDateFormat._();

  static bool _initialized = false;

  /// intl yerelleştirmesini başlatır (tr_TR)
  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      await initializeDateFormatting('tr_TR', null);
      await initializeDateFormatting('tr', null);
      _initialized = true;
    } catch (_) {
      // Çevrimdışı veya hata durumunda fallback kullanılır
    }
  }

  /// 'd MMMM yyyy, HH:mm' (Örn: 9 Kasım 2026, 14:30)
  static String formatFull(DateTime dateTime) {
    try {
      return DateFormat('d MMMM yyyy, HH:mm', 'tr_TR').format(dateTime);
    } catch (_) {
      try {
        return DateFormat('d MMMM yyyy, HH:mm').format(dateTime);
      } catch (_) {
        final d = dateTime.day.toString().padLeft(2, '0');
        final m = dateTime.month.toString().padLeft(2, '0');
        final y = dateTime.year;
        final h = dateTime.hour.toString().padLeft(2, '0');
        final min = dateTime.minute.toString().padLeft(2, '0');
        return '$d.$m.$y, $h:$min';
      }
    }
  }

  /// 'd MMM, HH:mm' (Örn: 9 Kas, 14:30)
  static String formatShort(DateTime dateTime) {
    try {
      return DateFormat('d MMM, HH:mm', 'tr_TR').format(dateTime);
    } catch (_) {
      try {
        return DateFormat('d MMM, HH:mm').format(dateTime);
      } catch (_) {
        final d = dateTime.day.toString().padLeft(2, '0');
        final m = dateTime.month.toString().padLeft(2, '0');
        final h = dateTime.hour.toString().padLeft(2, '0');
        final min = dateTime.minute.toString().padLeft(2, '0');
        return '$d.$m, $h:$min';
      }
    }
  }

  /// 'HH:mm' (Örn: 14:30)
  static String formatTime(DateTime dateTime) {
    try {
      return DateFormat('HH:mm').format(dateTime);
    } catch (_) {
      final h = dateTime.hour.toString().padLeft(2, '0');
      final min = dateTime.minute.toString().padLeft(2, '0');
      return '$h:$min';
    }
  }

  /// Görev listesi ve detay ekranı için göreceli tarih gösterimi
  /// ('Bugün 14:30', 'Yarın 14:30', 'Dün 14:30' veya '9 Kas, 14:30' / '9 Kasım 2026, 14:30')
  static String formatRelative(DateTime dueAtUtc, {bool fullFormat = false}) {
    final local = dueAtUtc.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(local.year, local.month, local.day);
    final timeStr = formatTime(local);

    if (dueDay == today) {
      return fullFormat ? 'Bugün, $timeStr' : 'Bugün $timeStr';
    } else if (dueDay == today.add(const Duration(days: 1))) {
      return fullFormat ? 'Yarın, $timeStr' : 'Yarın $timeStr';
    } else if (dueDay == today.subtract(const Duration(days: 1))) {
      return fullFormat ? 'Dün, $timeStr' : 'Dün $timeStr';
    } else {
      return fullFormat ? formatFull(local) : formatShort(local);
    }
  }
}

