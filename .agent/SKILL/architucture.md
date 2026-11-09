# Priority Todo — Teknik Mimari

## Mimari yaklaşım

Uygulama katmanlı ve offline-first tasarlanır: Flutter/Material 3 arayüzü, Riverpod durum yönetimi, Drift/SQLite kalıcı veri, `flutter_local_notifications` yerel bildirim, `timezone` zaman hesapları için kullanılır. Veritabanı kullanıcının kendi telefonundadır; v1’de API, hesap, bulut senkronizasyonu veya ağ katmanı yoktur. Bildirim servisinin arayüzü domain dışına çıkarılır; iş kuralları Android API’lerini doğrudan çağırmaz.

| Alan | Önerilen çözüm | Neden |
| --- | --- | --- |
| UI | Flutter + Material 3 | Android’de hızlı, erişilebilir arayüz |
| State | `flutter_riverpod` | Test edilebilir ekran durumu ve DI |
| Veri | `drift` + SQLite | İlişkiler, transaction ve migration |
| Anahtar | `flutter_secure_storage` | Şifreleme anahtarını güvenli saklama |
| Bildirim | `flutter_local_notifications` | Yerel, ağsız bildirim |
| Arka plan | `workmanager` | Pil dostu periyodik değerlendirme |

## Klasör düzeni

```text
lib/
  core/                 errors, theme, clock, helpers
  features/todos/
    domain/             entities, repository interfaces, use cases
    application/        controllers, states, reminder scheduler
    data/               Drift database, DAO, repository implementation
    presentation/       pages and reusable widgets
  features/settings/    notification and preference settings
  platform/             notification/background adapters
  bootstrap.dart
  main.dart
```

Bağımlılık yönü: `presentation → application → domain`. `data` domain repository arayüzlerini uygular. Domain katmanı Flutter widget’ı, SQL veya Android sınıfı bilmez.

Tema `core/theme/app_theme.dart` içinde tek bir `ThemeData.dark()` yapılandırmasıyla sabitlenir: `scaffoldBackgroundColor` siyah, ana metin beyazdır. Uygulama ayarlarında açık tema saklanmaz veya sunulmaz.

## Veri şeması

```sql
CREATE TABLE todos (
  id TEXT PRIMARY KEY NOT NULL,
  title TEXT NOT NULL CHECK(length(trim(title)) BETWEEN 1 AND 160),
  note TEXT NOT NULL DEFAULT '',
  priority INTEGER NOT NULL CHECK(priority BETWEEN 1 AND 4),
  due_at_utc INTEGER,
  is_done INTEGER NOT NULL DEFAULT 0,
  manual_position INTEGER NOT NULL,
  last_reminded_at_utc INTEGER,
  created_at_utc INTEGER NOT NULL,
  updated_at_utc INTEGER NOT NULL
);
CREATE TABLE checklist_items (
  id TEXT PRIMARY KEY NOT NULL,
  todo_id TEXT NOT NULL REFERENCES todos(id) ON DELETE CASCADE,
  text TEXT NOT NULL CHECK(length(trim(text)) BETWEEN 1 AND 500),
  is_done INTEGER NOT NULL DEFAULT 0,
  position INTEGER NOT NULL
);
```

Tarih alanları UTC saklanır, ekranda yerel saat dilimine çevrilir. İndeksler: `todos(is_done, priority, due_at_utc)` ve `checklist_items(todo_id, position)`. Migration’lar sürümlenir; güncellemede kullanıcı verisi silinmez.

## Temel iş akışları

```text
Kullanıcı eylemi → Controller/use case → Repository transaction → State refresh
                                                      ↓
                                              ReminderScheduler
                                                      ↓
                                            NotificationService
```

- Görev silme: görev ve checklist satırları tek transaction’da silinir, ardından bildirimi iptal edilir.
- Tamamlama: `is_done` ve `updated_at` yazılır; tamamlandıysa planlı bildirim iptal edilir.
- Sıralama: değişen tüm `manual_position` değerleri tek transaction’da güncellenir.
- Uygulama açılışında: tamamlanmamış görevler okunur, planlar yeniden hesaplanır.

Görev listesi ve detay ekranı aynı repository/provider akışını dinler. Böylece görev kutucuğu listeden veya detay sayfasından değiştirildiğinde, uzun notun çizik görünümü ve ana listedeki görünüm aynı veri durumundan üretilir.

## Bildirim tasarımı

İki plan türü kullanılır: esnek **saatlik özet** ve kullanıcının belirlediği **tek seferlik son tarih alarmı**. Saatlik iş, açık yüksek/kritik görevleri sorgular; sessiz saatleri ve son bildirim zamanını kontrol eder, ardından tek özet yollar. Kesin alarm yalnızca kullanıcı belirli saatte bildirim talep ettiğinde kullanılır.

Android 13+ için `POST_NOTIFICATIONS` izni gerekir. Android 12+ kesin alarm işlemleri ek izin isteyebilir; bu izin uygulama açılır açılmaz talep edilmez. Kullanıcı kesin zamanlı hatırlatma seçtiğinde gerekçe gösterilir. [Android alarm rehberi](https://developer.android.com/develop/background-work/services/alarms) ve [Android 14 kesin alarm değişikliği](https://developer.android.com/about/versions/14/changes/schedule-exact-alarms) kontrol edilmelidir.

Önerilen kanallar: `urgent_reminders` (ses/titreşim isteğe bağlı), `scheduled_reminders` ve `silent_summary`. Kanal oluşturulduktan sonra nihai ses davranışını kullanıcı Android sistem ayarından değiştirebilir.

## Güvenlik ve test

- Yerel veritabanı için SQLCipher veya uyumlu şifreli SQLite değerlendirilir; anahtar güvenli depoda tutulur.
- Hata loglarına başlık ve not metni yazılmaz.
- İzin reddi, kanalın sistemden kapatılması, yeniden başlatma, saat dilimi değişimi ve veritabanı hatası test edilir.
- Birim testleri sıralama/sessiz saat/tekrar önleme; repository testleri cascade delete ve rollback; entegrasyon testi ekle→kapat/aç→işaretle→taşı→sil akışını kapsar.
