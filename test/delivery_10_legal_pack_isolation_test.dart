// ==============================================================================
// NAKHL & NAHL — DELIVERY 10: LEGAL PACK ISOLATION & JURISDICTION INTEGRITY
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:nakhl_nahl/services/legislation/legal_pack_registry_service.dart';
import 'package:nakhl_nahl/services/legislation/cross_border_legal_engine_service.dart';

void main() {
  group('Delivery 10: Legal Pack Jurisdiction Isolation', () {
    test('Legal packs registry contains active packs: SAUDI_ARABIA, TURKEY, EU, GERMANY', () {
      final registry = LegalPackRegistryService.instance;
      final activePacks = registry.getActivePacks();

      final packIds = activePacks.map((p) => p.packId).toList();
      expect(packIds, contains('SAUDI_ARABIA_PACK'));
      expect(packIds, contains('TURKEY_PACK'));
      expect(packIds, contains('EU_FOOD_IMPORT_PACK'));
      expect(packIds, contains('GERMANY_FOOD_IMPORT_PACK'));
    });

    test('Non-loaded countries remain NOT_LOADED and cannot produce active rules', () {
      final registry = LegalPackRegistryService.instance;

      final jpPack = registry.getPackForCountry('JP');
      expect(jpPack, isNull);

      final isJpActive = registry.isCountryPackActive('JP');
      expect(isJpActive, isFalse);

      final isUaeActive = registry.isCountryPackActive('AE');
      expect(isUaeActive, isFalse);
    });

    test('Saudi Arabian VAT and ZATCA rules are never mixed with Turkish GIB / KDV rules', () {
      final engine = CrossBorderLegalEngineService.instance;

      // Saudi local export transaction
      final saudiAnalysis = engine.analyzeExportCompliance(
        originCountry: 'SA',
        destinationCountry: 'SA',
        hsCode: '0804.10.00',
        productType: 'DATES',
      );

      final saudiAuthorities = saudiAnalysis.applicableAuthorities;
      expect(saudiAuthorities, contains('ZATCA'));
      expect(saudiAuthorities, isNot(contains('GİB')));

      // Turkey local export transaction
      final turkeyAnalysis = engine.analyzeExportCompliance(
        originCountry: 'TR',
        destinationCountry: 'TR',
        hsCode: '0804.10.00',
        productType: 'DATES',
      );

      final turkeyAuthorities = turkeyAnalysis.applicableAuthorities;
      expect(turkeyAuthorities, contains('GİB'));
      expect(turkeyAuthorities, isNot(contains('ZATCA')));
    });

    test('Cross-border trade from SA to EU activates both export and import requirements cleanly', () {
      final engine = CrossBorderLegalEngineService.instance;

      final tradeAnalysis = engine.analyzeExportCompliance(
        originCountry: 'SA',
        destinationCountry: 'DE', // Germany in EU
        hsCode: '0804.10.00',
        productType: 'DATES',
      );

      expect(
        tradeAnalysis.documentNames.any((d) => d.contains('Certificate of Origin')),
        isTrue,
      );
      expect(
        tradeAnalysis.documentNames.any((d) => d.contains('Phytosanitary Certificate')),
        isTrue,
      );
      expect(tradeAnalysis.applicableAuthorities, contains('ZATCA'));
      expect(tradeAnalysis.applicableAuthorities, contains('SFDA'));
      expect(tradeAnalysis.applicableAuthorities, contains('TRACES NT'));
    });
  });
}
