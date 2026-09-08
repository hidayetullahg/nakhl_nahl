// ==============================================================================
// NAKHL & NAHL — DELIVERY 05: LATINIZED ARABIC (AR-LAT) & TRANSLITERATION ENGINE
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:nakhl_nahl/core/i18n/arabic_transliteration_service.dart';
import 'package:nakhl_nahl/core/i18n/app_dictionary.dart';

void main() {
  group('Delivery 05: Arabic Transliteration & AR-LAT Romanization', () {
    test('Verified corporate terminology produces exact Romanized Arabizi outputs', () {
      final engine = ArabicTransliterationService.instance;

      expect(engine.transliterateTerm('فاتورة المبيعات'), equals("Fatoorat Al-Mabee'aat"));
      expect(engine.transliterateTerm('لوحة التحكم'), equals("Lawhat At-Tahakkum"));
      expect(engine.transliterateTerm('إدارة المخزون'), equals("Idarat Al-Makhzoon"));
      expect(engine.transliterateTerm('إدارة الحسابات والعملاء'), equals("Idarat Al-Hisabat Wal-'Umala"));
      expect(engine.transliterateTerm('المعاملات المالية'), equals("Al-Mu'amalat Al-Maliyyah"));
    });

    test('AR-LAT is strictly NOT English translation', () {
      final arLatInvoice = AppDictionary.ceviriAl('satis_faturasi', 'AR-LAT');
      final enInvoice = AppDictionary.ceviriAl('satis_faturasi', 'EN');

      expect(arLatInvoice, isNot(equals(enInvoice)));
      expect(arLatInvoice, equals("Fatoorat Al-Mabee'aat"));
      expect(enInvoice, equals('Sales Invoice'));
    });

    test('Phonetic rule-based fallback accurately romanizes Arabic characters', () {
      final engine = ArabicTransliterationService.instance;
      final result = engine.transliteratePhonetic('نخل ونحل');
      // ن = n, خ = kh, ل = l, و = wa, ن = n, ح = h, ل = l
      expect(result.toLowerCase(), contains('kh'));
      expect(result.toLowerCase(), contains('n'));
    });
  });
}
