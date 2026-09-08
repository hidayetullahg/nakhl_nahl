// ==============================================================================
// NAKHL & NAHL — DELIVERY 04: RTL / LTR DIRECTIONAL ACCURACY TEST SUITE
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:nakhl_nahl/core/i18n/locale_script_manager.dart';
import 'package:nakhl_nahl/core/i18n/app_dictionary.dart';

void main() {
  group('Delivery 04: RTL / LTR Directional Switching', () {
    test('Arabic (AR) is strictly RTL in AppDictionary and LocaleScriptManager', () async {
      expect(AppDictionary.dilSagdanSolaMi('AR'), isTrue);

      final manager = LocaleScriptManager.instance;
      await manager.switchToLanguage('ar');
      expect(manager.isRtl, isTrue);
    });

    test('Latinized Arabic (AR-LAT) is strictly LTR', () async {
      expect(AppDictionary.dilSagdanSolaMi('AR-LAT'), isFalse);

      final manager = LocaleScriptManager.instance;
      await manager.switchToLanguageAndScript('ar', 'Latn');
      expect(manager.isRtl, isFalse);
    });

    test('Turkish (TR) and English (EN) are strictly LTR', () {
      expect(AppDictionary.dilSagdanSolaMi('TR'), isFalse);
      expect(AppDictionary.dilSagdanSolaMi('EN'), isFalse);

      final manager = LocaleScriptManager.instance;
      manager.setMultilingualProfile(primaryLocale: 'tr-Latn');
      expect(manager.isRtl, isFalse);

      manager.setMultilingualProfile(primaryLocale: 'en-Latn');
      expect(manager.isRtl, isFalse);
    });
  });
}
