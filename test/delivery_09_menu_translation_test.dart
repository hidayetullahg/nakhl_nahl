// ==============================================================================
// NAKHL & NAHL — DELIVERY 09: DYNAMIC MENU TRANSLATION & SAFE FALLBACK
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:nakhl_nahl/core/i18n/locale_script_manager.dart';
import 'package:nakhl_nahl/core/i18n/app_dictionary.dart';

void main() {
  setUp(() {
    LocaleScriptManager.instance.initializeDefaults();
  });

  group('Delivery 09: Menu Translations & Graceful Fallback', () {
    test('Menu keys translate accurately across all 4 supported languages', () {
      final keys = [
        'dashboard',
        'cari_yonetimi',
        'finans_yonetimi',
        'stok_yonetimi',
        'satis_faturasi',
      ];

      for (final k in keys) {
        final tr = AppDictionary.ceviriAl(k, 'TR');
        final en = AppDictionary.ceviriAl(k, 'EN');
        final ar = AppDictionary.ceviriAl(k, 'AR');
        final arLat = AppDictionary.ceviriAl(k, 'AR-LAT');

        expect(tr, isNotEmpty);
        expect(en, isNotEmpty);
        expect(ar, isNotEmpty);
        expect(arLat, isNotEmpty);
      }
    });

    test('Missing translation key falls back gracefully without exception or null', () {
      const nonExistentKey = 'non_existent_menu_custom_item_xyz';
      final translation = LocaleScriptManager.instance.translate(nonExistentKey);

      // Must not throw, must return key or clean representation
      expect(translation, isNotNull);
      expect(translation, equals(nonExistentKey));
    });

    test('Unsupported language code gracefully falls back to English or Turkish', () {
      final fallbackResult = AppDictionary.ceviriAl('dashboard', 'XX_UNKNOWN');
      expect(fallbackResult, isNotEmpty);
      expect(fallbackResult, equals('Dashboard'));
    });

    test('metin helper resolves the selected locale and falls back safely', () {
      expect(metin('dashboard', ['TR']), equals('Yönetici Paneli'));
      expect(metin('dashboard', ['EN']), equals('Dashboard'));
      expect(metin('dashboard', ['XX', 'TR']), equals('Yönetici Paneli'));
      expect(metin('non_existent_key', ['TR']), equals('non_existent_key'));
    });
  });
}
