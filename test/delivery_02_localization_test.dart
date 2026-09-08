// ==============================================================================
// NAKHL & NAHL — DELIVERY 02: MULTI-LANGUAGE & INSTANT SWITCHING TEST SUITE
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:nakhl_nahl/core/i18n/locale_script_manager.dart';
import 'package:nakhl_nahl/core/i18n/app_dictionary.dart';

void main() {
  setUp(() {
    // Reset to defaults
    LocaleScriptManager.instance.initializeDefaults();
  });

  group('Delivery 02: Localization & Language Switching', () {
    test('Default configuration is Turkish (tr-Latn)', () {
      final manager = LocaleScriptManager.instance;
      expect(manager.primaryLocaleCode, equals('tr-Latn'));
      expect(manager.activeLanguageCode, equals('tr'));
      expect(manager.activeScriptCode, equals('Latn'));
      expect(manager.isRtl, isFalse);
    });

    test('Switch to English (en-Latn) updates active locale immediately without reload', () async {
      final manager = LocaleScriptManager.instance;
      bool notified = false;
      manager.addListener(() => notified = true);

      await manager.switchToLanguage('en');
      expect(manager.activeLanguageCode, equals('en'));
      expect(manager.primaryLocaleCode, equals('en-Latn'));
      expect(manager.isRtl, isFalse);
      expect(notified, isTrue);

      final translation = manager.translate('dashboard');
      expect(translation.toLowerCase(), contains('dashboard'));
    });

    test('Switch to Arabic (ar-Arab) sets Arabic script and RTL direction', () async {
      final manager = LocaleScriptManager.instance;
      await manager.switchToLanguage('ar');

      expect(manager.activeLanguageCode, equals('ar'));
      expect(manager.activeScriptCode, equals('Arab'));
      expect(manager.isRtl, isTrue);

      final translation = manager.translate('dashboard');
      expect(translation, equals('لوحة التحكم'));
    });

    test('Switch to Latinized Arabic (ar-Latn) sets Latin script and LTR direction', () async {
      final manager = LocaleScriptManager.instance;
      await manager.switchToLanguageAndScript('ar', 'Latn');

      expect(manager.activeLanguageCode, equals('ar'));
      expect(manager.activeScriptCode, equals('Latn'));
      expect(manager.isRtl, isFalse);

      final translation = manager.translate('dashboard');
      expect(translation, equals("Lawhat At-Tahakkum"));
    });

    test('Primary, secondary and tertiary languages can be set independently', () {
      final manager = LocaleScriptManager.instance;
      manager.setMultilingualProfile(
        primaryLocale: 'ar-Arab',
        secondaryLocale: 'ar-Latn',
        tertiaryLocale: 'en-Latn',
      );

      expect(manager.primaryLocaleCode, equals('ar-Arab'));
      expect(manager.secondaryLocaleCode, equals('ar-Latn'));
      expect(manager.tertiaryLocaleCode, equals('en-Latn'));
      expect(manager.isRtl, isTrue);
    });

    test('AppDictionary provides translations for TR, EN, AR, and AR-LAT', () {
      expect(AppDictionary.ceviriAl('dashboard', 'TR'), equals('Yönetici Paneli'));
      expect(AppDictionary.ceviriAl('dashboard', 'EN'), equals('Dashboard'));
      expect(AppDictionary.ceviriAl('dashboard', 'AR'), equals('لوحة التحكم'));
      expect(AppDictionary.ceviriAl('dashboard', 'AR-LAT'), equals("Lawhat At-Tahakkum"));
    });
  });
}
