# Geliştirme Kılavuzu ve Kod Standartları

## Kod ilkeleri

- Widget içinde SQL, alarm planlama veya iş kuralı yazılmaz.
- Her kalıcı değişiklik repository üzerinden yapılır ve başarısızlık UI’ya aktarılır.
- Kullanıcı metni `trim()` ile doğrulanır; başlık 1–160, checklist maddesi 1–500 karakter olmalıdır.
- Asenkron işlemden sonra `BuildContext` kullanılacaksa `context.mounted` kontrol edilir.
- Zaman hesapları enjekte edilen `Clock` ve `timezone` ile yapılır; domain koduna dağılmış `DateTime.now()` kullanılmaz.

## Tamamlama / çizik bileşeni

Görsel stil saklanmaz; yalnızca `isDone` durumu saklanır. Böylece ana liste, detay not sayfası ve checklist aynı kuralı üretir. Ana görevin kutucuğu listede veya detay ekranında işaretlenirse görev başlığıyla birlikte uzun not da çizilir.

```dart
class StrikeText extends StatelessWidget {
  const StrikeText({super.key, required this.text, required this.done, this.style});
  final String text;
  final bool done;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final base = style ?? Theme.of(context).textTheme.bodyLarge!;
    return Text(
      text,
      softWrap: true,
      style: base.copyWith(
        color: done ? const Color(0xFF9E9E9E) : Colors.white,
        decoration: done ? TextDecoration.lineThrough : TextDecoration.none,
        decorationColor: const Color(0xFF9E9E9E),
        decorationThickness: 1.5,
      ),
    );
  }
}
```

Uzun not için `SelectableText` kullanılıyorsa aynı stil uygulanır. Detay sayfasındaki not alanı dikey kaydırılabilir olmalıdır; uzun not kesilmez. Çizik, metni okunamaz yapacak düşük opaklıkta olmamalıdır.

## Checklist davranışı

```dart
CheckboxListTile(
  value: item.isDone,
  onChanged: controller.isSaving
      ? null
      : (checked) => controller.toggleChecklistItem(
          todoId: todo.id, itemId: item.id, isDone: checked ?? false),
  controlAffinity: ListTileControlAffinity.leading,
  activeColor: Colors.white,
  checkColor: Colors.black,
  title: StrikeText(text: item.text, done: item.isDone),
)
```

Kutucuğa dokunulduğunda Controller use-case’i çağırır; repository satırı ve görev `updatedAt` değerini transaction içinde günceller; provider yeni veriyi yayınlar. Hata olursa UI veri kaynağından tekrar yüklenir ve hata mesajı görünür.

## Sürükle-bırak

```dart
void reorder(List<Todo> todos, int oldIndex, int newIndex) {
  if (newIndex > oldIndex) newIndex -= 1;
  final moved = todos.removeAt(oldIndex);
  todos.insert(newIndex, moved);
  // Güncel sıra transaction ile manual_position alanına yazılır.
}
```

Her satır kalıcı UUID ile `ValueKey(todo.id)` alır. Otomatik öncelik sıralı görünümde sürükleme kapatılır veya kullanıcı önce `Özel sıra` moduna alınır; aksi halde taşınan öğe anında eski konumuna dönebilir.

Kullanıcı görevleri/notları listede taşıdığında yalnızca o telefonun SQLite veritabanındaki `manual_position` alanı güncellenir. Görevler cihaz dışına aktarılmaz.

## Android izinleri ve sözleşme

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<!-- Yalnızca kesin zamanlı alarm özelliği gerekiyorsa: -->
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
```

Bildirim izni kullanıcı “Hatırlatmaları aç” eylemine bastığında istenir. Kesin alarm izni yalnızca özel saat özelliği seçilince açıklamayla istenir. Tamamlanmış görev planlanmaz; silinen görev iptal edilir; aynı saatte birden çok görev için tek özet üretilir.

## Kod inceleme kontrol listesi

- Uzun başlık ve not küçük ekranlarda taşmadan gösteriliyor mu?
- Silme onay istiyor ve bağlı veriyi transaction ile siliyor mu?
- Bildirim izni reddedilince uygulama normal çalışıyor mu?
- Her kontrol için ekran okuyucu etiketi var mı?
- Saat değişimi/reboot sonrası planlar yeniden kuruluyor mu?
- Hata logları not metni gibi hassas verileri içermiyor mu?
