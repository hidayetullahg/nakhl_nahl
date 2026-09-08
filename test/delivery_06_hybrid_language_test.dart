// ==============================================================================
// NAKHL & NAHL — DELIVERY 06: MULTILINGUAL HYBRID DISPLAY MODE TEST SUITE
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:nakhl_nahl/core/i18n/locale_script_manager.dart';

void main() {
  setUp(() {
    LocaleScriptManager.instance.initializeDefaults();
  });

  group('Delivery 06: Multilingual Hybrid Mode', () {
    test('translateHybrid yields primary, secondary, and tertiary strings', () {
      final manager = LocaleScriptManager.instance;
      manager.setMultilingualProfile(
        primaryLocale: 'tr-Latn',
        secondaryLocale: 'ar-Arab',
        tertiaryLocale: 'ar-Latn',
      );

      final hybrid = manager.translateHybrid('dashboard');
      expect(hybrid.primary, equals('Yönetici Paneli'));
      expect(hybrid.secondary, equals('لوحة التحكم'));
      expect(hybrid.tertiary, equals("Lawhat At-Tahakkum"));
    });

    test('DisplayMode toggle between singleLanguage and multilingualHybrid', () {
      final manager = LocaleScriptManager.instance;
      expect(manager.displayMode, equals(DisplayMode.singleLanguage));

      manager.setDisplayMode(DisplayMode.multilingualHybrid);
      expect(manager.displayMode, equals(DisplayMode.multilingualHybrid));

      manager.setDisplayMode(DisplayMode.singleLanguage);
      expect(manager.displayMode, equals(DisplayMode.singleLanguage));
    });
  });
}
