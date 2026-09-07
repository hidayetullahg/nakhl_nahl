// ==============================================================================
// NAKHL & NAHL — FAZ 11 OTOMATİK BİRİM VE ENTEGRASYON TESTLERİ
// DİNAMİK KULLANICI PARAMETRELERİ + ÇOK DİLLİ + ÇOK ALFABELİ ERP + DİNAMİK MENÜ/ÜRÜN/SEKTÖR
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nakhl_nahl/core/i18n/locale_script_manager.dart';
import 'package:nakhl_nahl/models/sector_model.dart';
import 'package:nakhl_nahl/models/user_preferences_model.dart';
import 'package:nakhl_nahl/services/sector_service.dart';

void main() {
  group('FAZ 11 — 1. Çok Sektörlü ERP ve Dinamik Sektör Mimarisi', () {
    test('11 Çekirdek Global Sektör eksiksiz yüklenmeli ve kod bağımsız olmalıdır', () {
      final sectors = SectorService.defaultGlobalSectors;
      expect(sectors.length, 11);

      final codes = sectors.map((s) => s.code).toSet();
      expect(codes, containsAll([
        'DATES',
        'FOOD',
        'AGRI',
        'BEEKEEPING',
        'FURNITURE',
        'TEXTILE',
        'AUTOMOTIVE',
        'CONSTRUCTION',
        'LOGISTICS',
        'RETAIL',
        'WHOLESALE',
      ]));

      // Hurma sadece sektörlerden biridir, ana menü veya tek sektör değildir
      expect(sectors.any((s) => s.code == 'DATES'), isTrue);
      expect(sectors.any((s) => s.code == 'FURNITURE'), isTrue);
      expect(sectors.any((s) => s.code == 'BEEKEEPING'), isTrue);
    });

    test('Kullanıcı kod değiştirmeden dinamik olarak özel sektör ekleyebilmelidir', () async {
      final tenantId = 'test-tenant-123';
      final customSector = await SectorService.instance.addCustomSector(
        tenantId: tenantId,
        name: 'Güneş Enerjisi ve İklimlendirme',
      );

      expect(customSector.defaultName, 'Güneş Enerjisi ve İklimlendirme');
      expect(customSector.isGlobal, isFalse);
      expect(customSector.tenantId, tenantId);
      expect(customSector.code.startsWith('CUSTOM_'), isTrue);
    });

    test('TenantSektör çoklu seçim (Multi-Select) modeli doğru çalışmalıdır', () {
      final model = TenantSectorModel(
        id: 'ts-1',
        tenantId: 'tenant-abc',
        sectorId: 'sec-dates',
        isPrimary: true,
      );

      final map = model.toMap();
      expect(map['tenant_id'], 'tenant-abc');
      expect(map['sector_id'], 'sec-dates');
      expect(map['is_primary'], isTrue);
    });
  });

  group('FAZ 11 — 2. Dil ve Alfabe Ayrımı (Language ≠ Script)', () {
    test('Türkçe hem Latin hem de Arap alfabesiyle desteklenmelidir', () {
      final tr = LocaleScriptManager.languagesCatalog['tr']!;
      expect(tr.supportedScriptCodes, contains('Latn'));
      expect(tr.supportedScriptCodes, contains('Arab'));

      final trLatn = LocaleScriptManager.supportedLocales['tr-Latn']!;
      expect(trLatn.direction, TextDirection.ltr);
      expect(trLatn.isRtl, isFalse);

      final trArab = LocaleScriptManager.supportedLocales['tr-Arab']!;
      expect(trArab.direction, TextDirection.rtl);
      expect(trArab.isRtl, isTrue);
    });

    test('Uygurca hem Arap hem de Latin alfabesiyle desteklenmelidir', () {
      final ug = LocaleScriptManager.languagesCatalog['ug']!;
      expect(ug.supportedScriptCodes, contains('Arab'));
      expect(ug.supportedScriptCodes, contains('Latn'));

      final ugArab = LocaleScriptManager.supportedLocales['ug-Arab']!;
      expect(ugArab.direction, TextDirection.rtl);
      expect(ugArab.isRtl, isTrue);

      final ugLatn = LocaleScriptManager.supportedLocales['ug-Latn']!;
      expect(ugLatn.direction, TextDirection.ltr);
      expect(ugLatn.isRtl, isFalse);
    });

    test('Urduca, Farsça ve Arapça RTL olarak Arap yazı sistemiyle tanımlı olmalıdır', () {
      final urArab = LocaleScriptManager.supportedLocales['ur-Arab']!;
      expect(urArab.direction, TextDirection.rtl);
      expect(urArab.isRtl, isTrue);

      final faArab = LocaleScriptManager.supportedLocales['fa-Arab']!;
      expect(faArab.direction, TextDirection.rtl);
      expect(faArab.isRtl, isTrue);

      final arArab = LocaleScriptManager.supportedLocales['ar-Arab']!;
      expect(arArab.direction, TextDirection.rtl);
      expect(arArab.isRtl, isTrue);
    });

    test('Bengalce, Hintçe, Tagalog ve Amharca dilleri katalogda bulunmalıdır', () {
      final catalog = LocaleScriptManager.languagesCatalog;
      expect(catalog.containsKey('bn'), isTrue);
      expect(catalog.containsKey('hi'), isTrue);
      expect(catalog.containsKey('tl'), isTrue);
      expect(catalog.containsKey('am'), isTrue);
    });
  });

  group('FAZ 11 — 3. Tipografi Token Sistemi ve Okunabilirlik', () {
    test('Arap alfabesi için taban yazı boyutu 15.5px ve satır yüksekliği 1.6 olmalıdır', () {
      final arabicTypography = LocaleScriptManager.arabicTypography;
      final latinTypography = LocaleScriptManager.latinTypography;

      // Arap alfabesi okunabilirliği için belirgin şekilde daha büyük taban punto
      expect(arabicTypography.baseFontSize, greaterThan(latinTypography.baseFontSize));
      expect(arabicTypography.baseFontSize, 15.5);
      expect(arabicTypography.lineHeight, 1.6);
      expect(arabicTypography.primaryFontFamily, 'Amiri');

      // Latin kompakt düzen
      expect(latinTypography.baseFontSize, 13.0);
      expect(latinTypography.lineHeight, 1.35);
      expect(latinTypography.primaryFontFamily, 'Inter');
    });
  });

  group('FAZ 11 — 4. Maksimum 3 Dil Seçimi ve Hızlı Dil Değiştirici', () {
    test('Kullanıcı 1 ana dil + en fazla 2 opsiyonel dil seçebilmelidir', () {
      final manager = LocaleScriptManager.instance;
      manager.configureUserLanguages(
        primaryLanguage: 'ar',
        primaryScript: 'Arab',
        secondaryLanguage: 'ug',
        secondaryScript: 'Arab',
        tertiaryLanguage: 'tr',
        tertiaryScript: 'Latn',
      );

      expect(manager.userLanguages, ['ar', 'ug', 'tr']);
      expect(manager.activeLanguageCode, 'ar');
      expect(manager.activeScriptCode, 'Arab');
      expect(manager.isRtl, isTrue);
    });

    test('Kullanıcı seçili diller arasında anında geçiş yapabilmelidir', () async {
      final manager = LocaleScriptManager.instance;
      manager.configureUserLanguages(
        primaryLanguage: 'tr',
        primaryScript: 'Latn',
        secondaryLanguage: 'ar',
        secondaryScript: 'Arab',
      );

      expect(manager.activeLanguageCode, 'tr');
      expect(manager.isRtl, isFalse);

      await manager.switchToLanguage('ar');
      expect(manager.activeLanguageCode, 'ar');
      expect(manager.isRtl, isTrue);

      await manager.switchToLanguage('tr');
      expect(manager.activeLanguageCode, 'tr');
      expect(manager.isRtl, isFalse);
    });
  });

  group('FAZ 11 — 5. Dinamik Menü ve Localization Anahtarları', () {
    test('Ana menü "Hurma" değil "Ürün" (menu.product) olmalıdır', () {
      final manager = LocaleScriptManager.instance;

      // Türkçe
      manager.setLocale('tr-Latn');
      expect(manager.translate('menu.product'), 'Ürün');
      expect(manager.translate('menu.product'), isNot('Hurma'));

      // Arapça
      manager.setLocale('ar-Arab');
      expect(manager.translate('menu.product'), 'المنتجات');

      // İngilizce
      manager.setLocale('en-Latn');
      expect(manager.translate('menu.product'), 'Products');

      // Uygurca
      manager.setLocale('ug-Arab');
      expect(manager.translate('menu.product'), 'مەھسۇلات');

      // Urduca
      manager.setLocale('ur-Arab');
      expect(manager.translate('menu.product'), 'مصنوعات');
    });

    test('Kullanıcı parametreleri çeviri anahtarı doğru çalışmalıdır', () {
      final manager = LocaleScriptManager.instance;

      manager.setLocale('tr-Latn');
      expect(manager.translate('menu.user_parameters'), 'Kullanıcı Parametreleri');

      manager.setLocale('en-Latn');
      expect(manager.translate('menu.user_parameters'), 'User Parameters');

      manager.setLocale('ar-Arab');
      expect(manager.translate('menu.user_parameters'), 'معلمات المستخدم');
    });
  });

  group('FAZ 11 — 6. Kalite Seviyesi ve Fire Ayrımı', () {
    test('"Fire" normal kalite sınıfı olmamalı; muhasebe etki tipi WRITE_OFF olan ayrı bir kondisyon olmalıdır', () {
      final conditions = SectorService.defaultConditions;
      final fireCond = conditions.firstWhere((c) => c.code == 'FIRE_REJECT');

      expect(fireCond.isScrapFire, isTrue);
      expect(fireCond.accountingImpactType, 'WRITE_OFF');

      final soundCond = conditions.firstWhere((c) => c.code == 'SOUND_NORMAL');
      expect(soundCond.isScrapFire, isFalse);
      expect(soundCond.accountingImpactType, 'STANDARD');

      // Standart kalite sınıfları ayrı olmalıdır
      final grades = SectorService.defaultGrades;
      final gradeCodes = grades.map((g) => g.code).toList();
      expect(gradeCodes, containsAll(['PREMIUM', 'FIRST_GRADE', 'SECOND_GRADE', 'INDUSTRIAL']));
      expect(gradeCodes, isNot(contains('FIRE_REJECT')));
    });
  });

  group('FAZ 11 — 7. Kullanıcı Parametreleri ve Tercih Modeli', () {
    test('Kullanıcı tercihleri modeli serialization ve copyWith testi', () {
      final prefs = UserPreferencesModel(
        id: 'pref-1',
        userId: 'usr-1',
        tenantId: 'tnt-1',
        primaryLanguageCode: 'tr',
        primaryScriptCode: 'Latn',
        secondaryLanguageCode: 'ar',
        secondaryScriptCode: 'Arab',
        dateFormat: 'DD/MM/YYYY',
        numberFormat: '#,##0.00',
        currencyDisplayMode: 'SYMBOL',
      );

      final map = prefs.toMap();
      expect(map['primary_language_code'], 'tr');
      expect(map['primary_script_code'], 'Latn');
      expect(map['secondary_language_code'], 'ar');

      final copy = prefs.copyWith(primaryLanguageCode: 'ug', primaryScriptCode: 'Arab');
      expect(copy.primaryLanguageCode, 'ug');
      expect(copy.primaryScriptCode, 'Arab');
      expect(copy.secondaryLanguageCode, 'ar'); // korundu
    });
  });
}
