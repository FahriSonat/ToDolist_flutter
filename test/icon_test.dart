import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Uygulama İkonu ve Varlık Doğrulama Testleri (Launcher Icons)', () {
    test('1. Kaynak ikon dosyası (assets/icon/icon.png) mevcut ve geçerli olmalıdır', () {
      final sourceIcon = File('assets/icon/icon.png');
      expect(sourceIcon.existsSync(), isTrue, reason: 'assets/icon/icon.png dosyası bulunamadı');
      expect(sourceIcon.lengthSync(), greaterThan(1000), reason: 'Kaynak ikon dosyası boş veya bozuk');
    });

    test('2. Android Manifest dosyasında android:icon="@mipmap/launcher_icon" tanımlı olmalıdır', () {
      final manifest = File('android/app/src/main/AndroidManifest.xml');
      expect(manifest.existsSync(), isTrue);
      final content = manifest.readAsStringSync();
      expect(content.contains('android:icon="@mipmap/launcher_icon"'), isTrue,
          reason: 'AndroidManifest.xml launcher_icon referansını içermiyor');
    });

    test('3. Android mipmap çözünürlük klasörlerinde launcher_icon.png mevcut olmalıdır', () {
      final densities = ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi'];
      for (final density in densities) {
        final iconFile = File('android/app/src/main/res/mipmap-$density/launcher_icon.png');
        expect(iconFile.existsSync(), isTrue,
            reason: 'mipmap-$density/launcher_icon.png oluşturulmamış');
        expect(iconFile.lengthSync(), greaterThan(500),
            reason: 'mipmap-$density/launcher_icon.png boyutu geçersiz');
      }
    });

    test('4. Android 8.0+ Adaptif İkon (mipmap-anydpi-v26/launcher_icon.xml) mevcut ve geçerli olmalıdır', () {
      final xmlFile = File('android/app/src/main/res/mipmap-anydpi-v26/launcher_icon.xml');
      expect(xmlFile.existsSync(), isTrue,
          reason: 'Adaptif ikon XML dosyası oluşturulmamış');
      final content = xmlFile.readAsStringSync();
      expect(content.contains('<adaptive-icon'), isTrue);
      expect(content.contains('ic_launcher_background'), isTrue);
      expect(content.contains('ic_launcher_foreground'), isTrue);
    });

    test('5. Adaptif arka plan rengi (#F5F5F0) colors.xml içinde tanımlı olmalıdır', () {
      final colorsFile = File('android/app/src/main/res/values/colors.xml');
      expect(colorsFile.existsSync(), isTrue, reason: 'values/colors.xml dosyası oluşturulmamış');
      final content = colorsFile.readAsStringSync();
      expect(content.contains('ic_launcher_background'), isTrue);
      expect(content.contains('#F5F5F0'), isTrue,
          reason: 'Arka plan rengi #F5F5F0 olarak ayarlanmamış');
    });

    test('6. iOS AppIcon klasöründe ikonlar oluşturulmuş olmalıdır', () {
      final iosAppIconDir = Directory('ios/Runner/Assets.xcassets/AppIcon.appiconset');
      expect(iosAppIconDir.existsSync(), isTrue);
      final files = iosAppIconDir.listSync().whereType<File>().toList();
      expect(files.length, greaterThan(5), reason: 'iOS ikon setinde dosyalar eksik');
    });
  });
}
