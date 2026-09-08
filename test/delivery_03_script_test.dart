// ==============================================================================
// NAKHL & NAHL — DELIVERY 03: SCRIPT & LANGUAGE SEPARATION TEST SUITE
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:nakhl_nahl/core/i18n/locale_script_manager.dart';

void main() {
  group('Delivery 03: Script & Language Separation', () {
    test('Language code is distinct from script code', () {
      final catalog = LocaleScriptManager.localesCatalog;
      expect(catalog.containsKey('ar-Arab'), isTrue);
      expect(catalog.containsKey('ar-Latn'), isTrue);

      final arArab = catalog['ar-Arab']!;
      final arLatn = catalog['ar-Latn']!;

      expect(arArab.languageCode, equals('ar'));
      expect(arArab.scriptCode, equals('Arab'));
      expect(arArab.isRtl, isTrue);

      expect(arLatn.languageCode, equals('ar'));
      expect(arLatn.scriptCode, equals('Latn'));
      expect(arLatn.isRtl, isFalse);
    });

    test('Uyghur language supports both Arab and Latn scripts', () {
      final catalog = LocaleScriptManager.localesCatalog;
      expect(catalog.containsKey('ug-Arab'), isTrue);
      expect(catalog.containsKey('ug-Latn'), isTrue);

      expect(catalog['ug-Arab']!.isRtl, isTrue);
      expect(catalog['ug-Latn']!.isRtl, isFalse);
    });

    test('Scripts catalog defines Latn as LTR and Arab as RTL', () {
      final scripts = LocaleScriptManager.scriptsCatalog;
      expect(scripts['Latn']?.direction, equals('ltr'));
      expect(scripts['Arab']?.direction, equals('rtl'));
    });
  });
}
