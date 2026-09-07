import 'package:flutter_test/flutter_test.dart';
import 'package:nakhl_nahl/repositories/legislation_repository.dart';

void main() {
  group('FAZ 22: Legislation + Tax Centralized Engine Tests', () {
    test('LegislationRecordModel parses and evaluates active state correctly',
        () {
      final activeLegislation = LegislationRecordModel(
        id: 'leg-sa-001',
        countryCode: 'SA',
        jurisdiction: 'NATIONAL',
        legislationCode: 'ZATCA-VAT-2020',
        title: 'Saudi Arabia Unified VAT Law 15%',
        effectiveFrom: DateTime(2020, 7, 1),
        effectiveTo: null,
        version: '2.0',
        sourceReference: 'Royal Decree A/638',
        status: 'ACTIVE',
      );

      expect(activeLegislation.countryCode, 'SA');
      expect(activeLegislation.isActive, isTrue);
      expect(activeLegislation.version, '2.0');

      final historicalLegislation = LegislationRecordModel(
        id: 'leg-sa-002',
        countryCode: 'SA',
        jurisdiction: 'NATIONAL',
        legislationCode: 'ZATCA-VAT-2018',
        title: 'Saudi Arabia Initial VAT Law 5%',
        effectiveFrom: DateTime(2018, 1, 1),
        effectiveTo: DateTime(2020, 6, 30),
        version: '1.0',
        sourceReference: 'Royal Decree M/113',
        status: 'ACTIVE',
      );

      // Past effective_to date makes it non-active for current transactions
      expect(historicalLegislation.isActive, isFalse);
    });

    test('TaxRuleModel parses correctly from json map', () {
      final json = {
        'id': 'rule-001',
        'company_id': 'cmp-riyadh-01',
        'rule_code': 'VAT_STD_15',
        'rule_name': 'Saudi Standard VAT 15%',
        'tax_type': 'VAT',
        'rate': 15.0,
        'country_code': 'SA',
        'jurisdiction': 'NATIONAL',
        'effective_from': '2020-07-01T00:00:00.000',
        'effective_to': null,
        'transaction_type': 'SALES',
        'is_reverse_charge': false,
        'is_recoverable': true,
        'priority': 100,
        'is_active': true,
      };

      final rule = TaxRuleModel.fromJson(json);
      expect(rule.id, 'rule-001');
      expect(rule.companyId, 'cmp-riyadh-01');
      expect(rule.rate, 15.0);
      expect(rule.taxType, 'VAT');
      expect(rule.transactionType, 'SALES');
      expect(rule.countryCode, 'SA');
      expect(rule.isReverseCharge, isFalse);
    });

    test(
        'TaxCalculationResult computes exact net, tax and gross amounts locally',
        () {
      final result = TaxCalculationResult.computeLocally(
        baseAmount: 1000.0,
        rate: 15.0,
        ruleCode: 'SA_SALES_15',
        taxType: 'VAT',
      );

      expect(result.baseAmount, 1000.0);
      expect(result.taxAmount, 150.0);
      expect(result.totalAmount, 1150.0);
      expect(result.rate, 15.0);
      expect(result.isReverseCharge, isFalse);
    });

    test('Centralized TaxEngine calculates Sales tax correctly', () async {
      final calc = await TaxEngine.instance.calculateTax(
        companyId: 'cmp-01',
        transactionType: 'SALES',
        countryCode: 'SA',
        baseAmount: 5000.0,
      );

      expect(calc.baseAmount, 5000.0);
      expect(calc.rate, 15.0);
      expect(calc.taxAmount, 750.0);
      expect(calc.totalAmount, 5750.0);
    });

    test('Centralized TaxEngine applies zero-rated VAT for Export transactions',
        () async {
      final calc = await TaxEngine.instance.calculateTax(
        companyId: 'cmp-01',
        transactionType: 'EXPORT',
        countryCode: 'SA',
        baseAmount: 12000.0,
      );

      expect(calc.rate, 0.0);
      expect(calc.taxAmount, 0.0);
      expect(calc.totalAmount, 12000.0);
      expect(calc.taxType, 'EXPORT_ZERO');
      expect(calc.ruleCode, 'EXPORT_ZERO_RATED');
    });

    test(
        'Centralized TaxEngine handles country specific rates (e.g. TR %1 wholesale dates)',
        () async {
      final calc = await TaxEngine.instance.calculateTax(
        companyId: 'cmp-tr-01',
        transactionType: 'SALES',
        countryCode: 'TR',
        baseAmount: 20000.0,
      );

      expect(calc.rate, 1.0);
      expect(calc.taxAmount, 200.0);
      expect(calc.totalAmount, 20200.0);
    });

    test(
        'Preserved static LegislationRepository metadata remains fully accessible',
        () {
      final saLegislation = TaxEngine.instance.getStaticLegislation('SA');
      expect(saLegislation.code, 'SA');
      expect(saLegislation.standardVat, '%15');
      expect(saLegislation.taxAuthorityName, contains('ZATCA'));
      expect(saLegislation.eInvoiceSystemName, contains('ZATCA Fatoorah'));

      final trLegislation = TaxEngine.instance.getStaticLegislation('TR');
      expect(trLegislation.code, 'TR');
      expect(trLegislation.taxAuthorityName, contains('Vergi Dairesi'));
    });
  });
}
