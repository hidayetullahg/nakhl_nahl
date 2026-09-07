// ==============================================================================
// NAKHL & NAHL — CROSS-BORDER LEGISLATION & JURISDICTION SHELF TESTS
// Master Directive Verification: SA, TR, EU Food Import, DE, Empty Shelves
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nakhl_nahl/models/legislation/legal_pack_model.dart';
import 'package:nakhl_nahl/models/legislation/product_legal_profile_model.dart';
import 'package:nakhl_nahl/services/legislation/legal_pack_registry_service.dart';
import 'package:nakhl_nahl/services/legislation/cross_border_legal_engine_service.dart';
import 'package:nakhl_nahl/screens/legislation/legislation_library_screen.dart';
import 'package:nakhl_nahl/screens/legislation/cross_border_assessment_screen.dart';

void main() {
  group('1. Legal Pack Registry & Global Shelf Tests', () {
    final registry = LegalPackRegistryService.instance;

    test('Registry contains exactly 4 ACTIVE packs with high coverage', () {
      final activePacks = registry.getActivePacks();
      expect(activePacks.length, 4);

      final packCodes = activePacks.map((p) => p.packCode).toSet();
      expect(packCodes, containsAll([
        'SAUDI_ARABIA_PACK',
        'TURKEY_PACK',
        'EU_FOOD_IMPORT_PACK',
        'GERMANY_FOOD_IMPORT_PACK',
      ]));

      for (final pack in activePacks) {
        expect(pack.status, LegalShelfStatus.active);
        expect(pack.coveragePercentage, greaterThanOrEqualTo(90.0));
        expect(pack.primaryAuthorities, isNotEmpty);
        expect(pack.coveredDomains, isNotEmpty);
      }
    });

    test('Empty shelves are marked as NOT_LOADED without mocked legislation', () {
      final emptyShelves = registry.getEmptyShelves();
      expect(emptyShelves, isNotEmpty);
      expect(emptyShelves.length, greaterThanOrEqualTo(15));

      final shelfCodes = emptyShelves.map((s) => s.code).toSet();
      expect(shelfCodes, containsAll(['CN', 'IN', 'RU', 'AE', 'QA', 'KW', 'US', 'GB', 'JP']));

      for (final shelf in emptyShelves) {
        expect(shelf.shelfStatus, LegalShelfStatus.notLoaded);
        expect(shelf.isActive, isFalse);
        expect(shelf.officialPortalUrl, isNotNull);
      }
    });

    test('On-demand discovery request initiates DISCOVERY workflow safely', () {
      final requestResult = registry.requestPackDiscovery(
        countryCode: 'CN',
        targetProductCategory: 'Hurma İhracatı',
        requesterNote: 'Çin Şanghay limanına test sevkiyatı',
      );

      expect(requestResult['status'], 'DISCOVERY');
      expect(requestResult['countryCode'], 'CN');
      expect(requestResult['countryName'], 'Çin');
      expect(requestResult['workflow'], contains('LEGAL_REVIEW'));
      expect(requestResult['message'], contains('İnsan Hukuk İncelemesi'));
    });
  });

  group('2. Cross-Border Legal Engine — Scenario 1: Saudi Arabia to Germany (Dates)', () {
    final engine = CrossBorderLegalEngineService.instance;
    final profile = ProductLegalProfileModel.saudiMedjoolDatesToGermany();

    test('Strict Jurisdiction Isolation: SA export, EU food import and DE national rules are separated', () {
      final result = engine.resolveApplicableLegalFramework(profile);

      expect(result.sourceCountry, 'SA');
      expect(result.destinationCountry, 'DE');
      expect(result.isShelfEmpty, isFalse);

      // 1. Source (SA) Export Obligations
      expect(result.sourceExportObligations, isNotEmpty);
      expect(result.sourceExportObligations.any((o) => o.code == 'SA_EXP_FASAH_DECLARATION'), isTrue);
      expect(result.sourceExportObligations.any((o) => o.code == 'SA_EXP_MEWA_PHYTOSANITARY'), isTrue);
      expect(result.sourceExportObligations.any((o) => o.code == 'SA_EXP_VAT_ZERO_RATE'), isTrue);

      // 2. Supranational (EU) Food Import Obligations
      expect(result.supranationalObligations, isNotEmpty);
      expect(result.supranationalObligations.any((o) => o.code == 'EU_FOOD_GENERAL_LAW_TRACEABILITY'), isTrue);
      expect(result.supranationalObligations.any((o) => o.code == 'EU_OFFICIAL_CONTROLS_BCP'), isTrue);
      expect(result.supranationalObligations.any((o) => o.code == 'EU_TRACES_NT_CHED_D'), isTrue);
      expect(result.supranationalObligations.any((o) => o.code == 'EU_CONTAMINANTS_MRL_LIMITS'), isTrue);

      // 3. Member State (DE) National Obligations
      expect(result.destinationNationalObligations, isNotEmpty);
      expect(result.destinationNationalObligations.any((o) => o.code == 'DE_VERPACKG_LUCID_REGISTRATION'), isTrue);
      expect(result.destinationNationalObligations.any((o) => o.code == 'DE_LMIV_GERMAN_LANGUAGE_LABEL'), isTrue);
    });

    test('Verifies TRACES NT CHED-D, BCP and Lab analysis for non-animal food', () {
      final result = engine.resolveApplicableLegalFramework(profile);

      expect(result.isTracesNtRequired, isTrue);
      expect(result.tracesNtType, contains('CHED-D'));
      expect(result.isBorderControlPostRequired, isTrue);
      expect(result.isLabAnalysisRequired, isTrue);
    });

    test('Verifies Required Documents, Tariffs and Packaging obligations', () {
      final result = engine.resolveApplicableLegalFramework(profile);

      final docNames = result.requiredDocuments.map((d) => d.documentName).toList();
      expect(docNames.any((name) => name.contains('Commercial Invoice')), isTrue);
      expect(docNames.any((name) => name.contains('Bitki Sağlık')), isTrue);
      expect(docNames.any((name) => name.contains('Menşe Şahadetnamesi')), isTrue);
      expect(docNames.any((name) => name.contains('CHED-D')), isTrue);

      expect(result.customsDutyRate, 0.0);
      expect(result.importVatRate, 7.0); // German reduced food VAT
      expect(result.packagingAndRecyclingObligations.any((p) => p.contains('LUCID')), isTrue);
      expect(result.mandatoryLabelingElements.any((l) => l.contains('Datteln')), isTrue);
    });
  });

  group('3. Cross-Border Legal Engine — Other Core Routes', () {
    final engine = CrossBorderLegalEngineService.instance;

    test('Scenario 2: Turkey to Germany Food Export', () {
      final profile = ProductLegalProfileModel.turkeyFoodToGermany();
      final result = engine.resolveApplicableLegalFramework(profile);

      expect(result.sourceCountry, 'TR');
      expect(result.destinationCountry, 'DE');
      expect(result.sourceExportObligations.any((o) => o.code == 'TR_EXP_GUMRUK_BEYANNAME'), isTrue);
      expect(result.supranationalObligations.any((o) => o.code == 'EU_TRACES_NT_CHED_D'), isTrue);
      expect(result.destinationNationalObligations.any((o) => o.code == 'DE_VERPACKG_LUCID'), isTrue);
    });

    test('Scenario 3: Saudi Arabia to Turkey Food Import', () {
      final profile = ProductLegalProfileModel(
        productName: 'Suudi Safavi Hurma',
        hsCode: '080410',
        sourceCountry: 'SA',
        destinationCountry: 'TR',
        quantityKg: 10000,
      );
      final result = engine.resolveApplicableLegalFramework(profile);

      expect(result.sourceCountry, 'SA');
      expect(result.destinationCountry, 'TR');
      expect(result.supranationalObligations, isEmpty); // Non-EU route
      expect(result.destinationNationalObligations.any((o) => o.code == 'TR_IMP_TARIM_KONTROL'), isTrue);
      expect(result.importVatRate, 1.0); // Turkey wholesale dates KDV %1
      expect(result.mandatoryLabelingElements.any((l) => l.contains('Türkçe')), isTrue);
    });

    test('Scenario 4: Turkey to Saudi Arabia Food Import', () {
      final profile = ProductLegalProfileModel(
        productName: 'Türk Paketli Bisküvi & Tatlı',
        hsCode: '190531',
        sourceCountry: 'TR',
        destinationCountry: 'SA',
        quantityKg: 2000,
      );
      final result = engine.resolveApplicableLegalFramework(profile);

      expect(result.sourceCountry, 'TR');
      expect(result.destinationCountry, 'SA');
      expect(result.destinationNationalObligations.any((o) => o.code == 'SA_IMP_SFDA_FRS_REGISTRATION'), isTrue);
      expect(result.destinationNationalObligations.any((o) => o.code == 'SA_IMP_HALAL_CENTER_APPROVAL'), isTrue);
      expect(result.importVatRate, 15.0); // ZATCA standard VAT %15
      expect(result.customsDutyRate, 5.0); // GCC unified tariff
    });

    test('Empty Shelf Route (Saudi to China) returns NOT_LOADED without hallucinating', () {
      final profile = ProductLegalProfileModel(
        productName: 'Medjool Hurma',
        hsCode: '080410',
        sourceCountry: 'SA',
        destinationCountry: 'CN',
        quantityKg: 1000,
      );
      final result = engine.resolveApplicableLegalFramework(profile);

      expect(result.isShelfEmpty, isTrue);
      expect(result.riskLevel, 'HIGH');
      expect(result.riskAlerts.first, contains('NOT_LOADED'));
      expect(result.legalDisclaimer, contains('yasaktır'));
      expect(result.requiredDocuments, isEmpty);
    });
  });

  group('4. UI Widget Tests for Legislation Screens', () {
    testWidgets('LegislationLibraryScreen renders tabs, active packs and empty shelves', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: LegislationLibraryScreen(),
        ),
      );

      // Verify title & tabs
      expect(find.text('Mevzuat Kütüphanesi & Global Raflar'), findsOneWidget);
      expect(find.textContaining('Aktif Mevzuat'), findsOneWidget);

      // Verify Active Pack cards
      expect(find.text('Suudi Arabistan Tam Operasyonel Mevzuat Paketi'), findsOneWidget);
      expect(find.text('Türkiye Tam Operasyonel Mevzuat Paketi'), findsOneWidget);
      expect(find.text('Avrupa Birliği Gıda İthalatı & Resmi Kontroller Paketi'), findsOneWidget);
      expect(find.text('Almanya Ulusal Gıda İthalatı & Piyasaya Arz Paketi'), findsOneWidget);

      // Switch to Empty Shelves Tab using shelves icon
      await tester.tap(find.byIcon(Icons.shelves));
      await tester.pumpAndSettle();

      expect(find.text('Çin'), findsOneWidget);
      expect(find.text('Hindistan'), findsOneWidget);
      expect(find.text('Rusya'), findsOneWidget);
      expect(find.textContaining('Henüz yüklenmedi'), findsWidgets);
    });

    testWidgets('CrossBorderAssessmentScreen renders parameters and updates evaluation', (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: CrossBorderAssessmentScreen(),
        ),
      );

      expect(find.text('Çapraz Sınır Mevzuat Değerlendirmesi'), findsOneWidget);
      expect(find.text('Operasyon Parametreleri'), findsOneWidget);
      expect(find.textContaining('SA ➔ DE Değerlendirmesi'), findsOneWidget);
      expect(find.text('TRACES NT Dijital Ön Bildirim'), findsOneWidget);
      expect(find.text('Sınır Kontrol Noktası (BCP) Denetimi'), findsOneWidget);
      expect(find.textContaining('Almanya Ambalaj Yasası (VerpackG) LUCID'), findsOneWidget);
    });
  });
}
