# Priority Todo — Tasarım Sistemi

## Görsel yön

Arayüz yalnızca siyah bir çalışma zemini ve net beyaz tipografi kullanır. Öncelik için küçük durum rengi kullanılabilir, ancak ekranın ana karakteri siyah-beyaz kalır; açık tema bulunmaz. Amaç karmaşık bir proje yönetim aracı değil; kullanıcının kendi telefonunda hızla açıp uzun notlu görevler yazabileceği sakin bir kişisel alan sunmaktır.

## Tasarım tokenları

| Token | Değer | Kullanım |
| --- | --- | --- |
| `background` | `#000000` | Sayfa zemini |
| `surface` | `#121212` | Kart, giriş alanı |
| `surfaceRaised` | `#1C1C1E` | Seçili yüzey |
| `divider` | `#2C2C2E` | Ayraç |
| `textPrimary` | `#FFFFFF` | Başlık ve aktif metin |
| `textSecondary` | `#B0B0B5` | Yardımcı metin |
| `textDone` | `#929297` | Çizili metin |
| `priorityLow` | `#64B5F6` | Düşük |
| `priorityHigh` | `#FFB74D` | Yüksek |
| `priorityCritical` | `#FF5252` | Kritik |

Sayfa boşluğu 16 dp, kart iç boşluğu 16 dp, köşe yarıçapı 12 dp, minimum dokunma hedefi 48×48 dp’dir. Görev başlığı 16 sp, gövde 15–16 sp, yardımcı metin 13 sp kullanır.

## Ana liste

```text
┌────────────────────────────────────────┐
│ Bugün                              ⚙   │
│ 3 açık görev · 1 kritik                 │
│ [Açık] [Tamamlanan]  Sırala: Öncelik ▾ │
├────────────────────────────────────────┤
│ ⠿  □  Sunum taslağını bitir        ●  │
│        Bugün 14:00 · Kritik             │
│        2/5 alt madde                    │
├────────────────────────────────────────┤
│ ⠿  ☑  Market listesi                   │
│        süt, kahve, ekmek                │
└────────────────────────────────────────┘
                         [ + Yeni görev ]
```

Kutucuğa basmak yalnızca durumu değiştirir; satır gövdesi detay sayfasını açar. Sürükleme yalnızca `⠿` tutamacından başlar. Uzun başlık iki satırla sınırlandırılır ve detayda tamamı gösterilir. Öncelik renk yanında metinle de yazılır.

## Detay ekranı

```text
┌────────────────────────────────────────┐
│ ‹ Geri          Düzenle          Sil   │
├────────────────────────────────────────┤
│ □  Sunum taslağını bitir                │
│ ● Kritik       Bugün, 14:00             │
│                                        │
│ NOT                                    │
│ Uzun ve kaydırılabilir açıklama…        │
│                                        │
│ KONTROL LİSTESİ                         │
│ ☑ Kapak slaytı                          │
│ □ Maliyet tablosu                        │
│ + Madde ekle                             │
└────────────────────────────────────────┘
```

Görev tamamlanınca başlık, uzun not ve checklist başlığı hem ana listede hem görev detay sayfasında çizilir. Checklist satırı sadece kendisi tamamlandığında çizilir. Uzun not alanı kesilmeden dikey kaydırılır. Silme eylemi “Bu görev ve 3 alt madde silinecek; işlem geri alınamaz” metniyle onay ister.

## Form, bildirim ve erişilebilirlik

Yeni görev formu: başlık, not, öncelik, tarih/saat ve checklist alanlarından oluşur. Kaydet düğmesi yalnızca başlık geçerliyse etkin olur; klavye açıkken ulaşılabilir kalır.

Bildirim ayarları ses, titreşim, saatlik özet, sessiz saatler ve sistem bildirim ayarlarına bağlantıyı ayrı kontrol eder. İzin reddinde “Hatırlatmalar kapalı — Aç” açıklaması gösterilir, kullanıcı engellenmez.

- Kontrast en az WCAG AA hedefler.
- Dinamik metin ölçeğinde taşma test edilir.
- Onay kutuları “Görev: …, tamamlandı/tamamlanmadı” etiketi taşır.
- Ekran okuyucu için `Yukarı taşı`/`Aşağı taşı` alternatifleri bulunur.
- Boş listede: “Bugün için açık görevin yok.” ve `İlk görevini ekle` eylemi görünür.
- Not/görev sırası sürükle-bırakla değiştirildiğinde tutamaç, ekran okuyucuda “Sıralamayı değiştir” olarak okunur.
