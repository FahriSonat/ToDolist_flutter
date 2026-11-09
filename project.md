# Priority Todo — Ürün Gereksinimleri

## Ürün tanımı

**Priority Todo**, kullanıcının kendi telefonunda çalışan, reklamsız, koyu temalı ve ücretli bir görev yöneticisidir. Uygulama kişisel kullanım için tasarlanır: görevler ve uzun notlar yalnızca cihazda tutulur. Kullanıcı notlarını/görevlerini sıralayabilir, tamamladıklarını kutucuktan işaretleyebilir ve işi bittiğinde silebilir. Görev veya kontrol listesi satırı işaretlendiğinde hem listede hem detay not sayfasında metin üstü çizilir. Yüksek önem taşıyan açık görevler için kullanıcı isterse yerel sesli bildirim alır.

## Hedef kullanıcı ve ilkeler

- Uzun görev notları tutmak, fakat hesap açmak veya bulut kullanmak istemeyen kişiler.
- Todo listesini yalnızca kendi telefonunda, internetten bağımsız kullanmak isteyen kişiler.
- Hatırlatmaların kontrolünün tamamen kendisinde olmasını isteyenler.
- **Offline-first:** İnternet olmadan tüm temel akışlar çalışır.
- **Privacy-first:** V1’de reklam, analiz SDK’sı, hesap ve sunucuya veri aktarımı yoktur.
- **Açık davranış:** Bildirimlerin pil tasarrufu nedeniyle tam saatinde gelmeyebileceği kullanıcıya söylenir.

## Fonksiyonel gereksinimler

| ID | Gereksinim | Kabul kriteri |
| --- | --- | --- |
| FR-01 | Başlık, uzun not, öncelik ve opsiyonel son tarihli görev oluşturma | Boş başlık kaydedilemez; uygulama kapanıp açıldığında görev kalır. |
| FR-02 | Görev güncelleme ve silme | Silme onay ister; görevle birlikte tüm alt maddeler silinir. |
| FR-03 | Tamamlama | Kutucuğa basınca başlık ve detay notu çizilir; durum kalıcıdır. |
| FR-04 | Kontrol listesi | Her satır bağımsız işaretlenir ve yalnızca o satır çizilir. |
| FR-05 | Sıralama | Görevler ve alt maddeler sürükle-bırak ile taşınır; sıra korunur. |
| FR-06 | Öncelik | Düşük, Normal, Yüksek, Kritik değerleri hem metin hem simgeyle gösterilir. |
| FR-07 | Bildirim | Yüksek/Kritik, tamamlanmamış görevler için kullanıcı ayarına göre saatlik özet gelir. |
| FR-08 | Ses ve titreşim | Kullanıcı bunları ayrı ayrı kapatabilir. |
| FR-09 | Koyu görünüm | Uygulama yalnızca siyah zemin ve beyaz ağırlıklı yazıyla açılır; açık tema seçeneği yoktur. |
| FR-10 | Detayda çizik | Ana görev tamamlanınca görev detayındaki başlık ve uzun not da çizik görünür. |

## Sıralama ve bildirim kuralları

Varsayılan sıralama: açık görevler, önem (kritik ilk), son tarih (yakın ilk), manuel sıra. Kullanıcı `Özel sıra` görünümünü seçerse sürükle-bırak sırası kullanılır. Tamamlananlar listenin sonundadır.

Saatlik değerlendirme yalnızca tamamlanmamış Yüksek/Kritik görevlerde çalışır. Aynı görev için 60 dakika dolmadan ikinci bildirim üretilmez. Sessiz saatlerde bildirim gelmez; ilk uygun zamanda tek özet oluşturulur. Görev tamamlanır veya silinirse tüm planlı hatırlatmaları iptal edilir.

## Ekran akışı

1. **Ana liste:** Açık/tamamlanan filtreleri, sıralama ve `Yeni görev` düğmesi.
2. **Görev editörü:** Başlık, not, önem, tarih/saat ve checklist düzenleme.
3. **Görev detayı:** Tamamlama kutusu, uzun not, checklist, düzenle ve sil.
4. **Ayarlar:** Bildirim, ses, titreşim, sessiz saatler, sistem ayarlarına kısayol ve tüm veriyi silme.
5. **Bildirim tıklaması:** İlgili görevin detay ekranını açar.

## Uç durumlar

- Süresi geçen görev silinmez, “Süresi geçti” etiketi alır.
- Bildirim izni reddedilirse görev işlevleri devam eder; ayarlarda açıkça gösterilir.
- Cihaz yeniden başlatılır, saat/saat dilimi değişir veya uygulama güncellenirse planlar yeniden hesaplanır.
- Yazma başarısız olursa kullanıcıya hata verilir; yalnızca ekranda görünmekle veri kaydedilmiş sayılmaz.
- Bir kullanıcı görevini sildiğinde işlem yalnızca o telefondaki yerel veriyi etkiler; ağ isteği yapılmaz.

## Google Play yayın hedefi

Yayın `.aab` ile yapılır ve her yüklemede `versionCode` artırılır. 31 Ağustos 2026 itibarıyla yeni uygulamalar ve güncellemeler Android 16 / API 36 veya üstünü hedeflemelidir; yüklemeden önce Play Console politikasını yeniden kontrol edin. Uygulamanın nihai davranışına uygun gizlilik politikası ve Data safety beyanı zorunludur.

Kaynak: [Google Play hedef API şartları](https://support.google.com/googleplay/android-developer/answer/11926878), [AAB/Play App Signing](https://support.google.com/googleplay/android-developer/answer/9859152).

## Sürümleme

| Sürüm | Kapsam |
| --- | --- |
| MVP | Görev, not, checklist, koyu tema, kalıcı yerel veri, manuel sıralama |
| 1.0 | Bildirim tercihleri, saatlik özet, son tarih hatırlatması, dışa aktarma |
| 1.1 | Tekrarlayan görev, arama, arşiv ve biyometrik kilit |
