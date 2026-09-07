# R17 — TEST STRATEJİSİ
## Legislation Engine Test Strategy

**Rapor No:** R17  
**Versiyon:** 1.0  
**Tarih:** 2026-09-07  
**Durum:** ONAY BEKLİYOR  

---

## 1. Test Felsefesi — "KANIT YOKSA PASS YOK"

Mevcut sistemde:
- **145/145 test pass** (commercial_and_migration_test.dart)
- Flutter analyze: 0 issue

Bu rakamlar düşürülmeyecek. Yeni mevzuat motoru kapsamında:
- **Hedef**: Minimum 50 yeni test eklenir → Toplam 195+ test
- Her yeni kural tipi için en az 1 birim testi
- Her `UNKNOWN` durum için test
- Her `INAPPLICABLE` durum için test
- Cross-tenant izolasyon testi (PostgreSQL seviyesinde)

---

## 2. Test Katmanları

```
┌─────────────────────────────────────────────────────┐
│  KATMAN 4: E2E Testler (opsiyonel — manuel)         │
│  ZATCA Sandbox API testleri                         │
├─────────────────────────────────────────────────────┤
│  KATMAN 3: Widget Testleri                          │
│  TaxRuleLookupScreen, ZakatAssessmentScreen         │
├─────────────────────────────────────────────────────┤
│  KATMAN 2: Servis/Birim Testleri (Dart)             │
│  LegislationEngineService, ZakatCalculation vb.     │
├─────────────────────────────────────────────────────┤
│  KATMAN 1: PostgreSQL Fonksiyon Testleri            │
│  calculate_transaction_tax_v2, assess_compliance    │
│  Cross-tenant izolasyon                             │
└─────────────────────────────────────────────────────┘
```

---

## 3. Katman 1: PostgreSQL Testleri

**Dosya**: `supabase/security_tests/057_legislation_engine_tests.sql`

```sql
-- =============================================================
-- LEGISLATION ENGINE POSTGRESQL TEST SUITE
-- =============================================================

-- TEST 1: SA KDV %15 (2020 sonrası)
DO $$
DECLARE v RECORD;
BEGIN
  SELECT * INTO v FROM calculate_transaction_tax_v2(
    p_tenant_id := 'SYSTEM_TEST'::UUID,
    p_company_id := 'COMPANY_TEST'::UUID,
    p_transaction_type := 'SALES',
    p_country_code := 'SA',
    p_transaction_date := '2024-03-15',
    p_base_amount := 1000.00
  );
  ASSERT v.rate = 15.0, 'HATA: SA KDV oranı %15 olmalı, ' || v.rate || ' döndü';
  ASSERT v.uncertainty_level = 'CERTAIN', 'HATA: Kesin kural CERTAIN olmalı';
  ASSERT v.disclaimer IS NOT NULL, 'HATA: Disclaimer boş olamaz';
  RAISE NOTICE 'PASS: TEST 1 — SA KDV Standard %15';
END;
$$;

-- TEST 2: SA KDV %0 — İhracat
DO $$
DECLARE v RECORD;
BEGIN
  SELECT * INTO v FROM calculate_transaction_tax_v2(
    p_transaction_type := 'EXPORT',
    p_country_code := 'SA',
    p_transaction_date := '2024-03-15',
    p_base_amount := 5000.00,
    ...
  );
  ASSERT v.rate = 0.0, 'HATA: İhracat KDV %0 olmalı';
  ASSERT v.rule_code = 'SA_VAT_ZERO_EXPORT';
  RAISE NOTICE 'PASS: TEST 2 — SA KDV Sıfır İhracat';
END;
$$;

-- TEST 3: TR KDV %20 (2023 sonrası)
DO $$
DECLARE v RECORD;
BEGIN
  SELECT * INTO v FROM calculate_transaction_tax_v2(
    p_country_code := 'TR',
    p_transaction_date := '2024-06-01',
    p_base_amount := 1000.00,
    ...
  );
  ASSERT v.rate = 20.0, 'HATA: TR KDV 2024 %20 olmalı, ' || v.rate || ' döndü';
  RAISE NOTICE 'PASS: TEST 3 — TR KDV Standard %20 (2023 sonrası)';
END;
$$;

-- TEST 4: TR KDV %18 (2023 öncesi)
DO $$
DECLARE v RECORD;
BEGIN
  SELECT * INTO v FROM calculate_transaction_tax_v2(
    p_country_code := 'TR',
    p_transaction_date := '2022-06-01',
    p_base_amount := 1000.00,
    ...
  );
  ASSERT v.rate = 18.0, 'HATA: TR KDV 2022 %18 olmalı, ' || v.rate || ' döndü';
  RAISE NOTICE 'PASS: TEST 4 — TR KDV Tarihsel %18 (2023 öncesi)';
END;
$$;

-- TEST 5: Zekât — Tam Suudi sahiplik
DO $$
DECLARE v RECORD;
BEGIN
  SELECT * INTO v FROM calculate_zakat(
    p_assessment_year := '1446',
    p_paid_capital := 1000000,
    p_saudi_ownership_ratio := 1.0,
    ...
  );
  ASSERT v.zakat_amount = 25000, 'HATA: Zekât tutarı 25,000 SAR olmalı';
  ASSERT v.is_below_nisab = FALSE;
  RAISE NOTICE 'PASS: TEST 5 — Zekât Tam Suudi Sahiplik';
END;
$$;

-- TEST 6: UNKNOWN durumu — Bilinmeyen HS kodu
DO $$
DECLARE v RECORD;
BEGIN
  SELECT * INTO v FROM calculate_transaction_tax_v2(
    p_transaction_type := 'IMPORT',
    p_hs_code := '9999.99',
    ...
  );
  ASSERT v.uncertainty_level = 'UNKNOWN', 'HATA: Bilinmeyen HS UNKNOWN dönmeli';
  RAISE NOTICE 'PASS: TEST 6 — UNKNOWN durum bilinmeyen HS';
END;
$$;

-- TEST 7: Cross-tenant izolasyon — Zekât değerlendirmeleri
DO $$
DECLARE v_count INT;
BEGIN
  -- Tenant B, Tenant A'nın Zekât verilerini göremez
  SET app.current_tenant_id = 'tenant-b-uuid';
  SELECT COUNT(*) INTO v_count FROM zakat_assessments WHERE tenant_id = 'tenant-a-uuid';
  ASSERT v_count = 0, 'GÜVENLİK İHLALİ: Tenant B, Tenant A Zekât verilerini gördü!';
  RAISE NOTICE 'PASS: TEST 7 — Cross-tenant Zekât izolasyonu';
END;
$$;
```

---

## 4. Katman 2: Dart Birim Testleri

**Dosya**: `test/legislation/legislation_engine_test.dart`

```dart
void main() {
  
  group('SA VAT Rules', () {
    test('Standard rate 15% after 2020-07-01', () async {
      final result = await service.calculateTax(
        transactionType: 'SALES',
        countryCode: 'SA',
        transactionDate: DateTime(2024, 3, 15),
        baseAmount: 1000.0,
        companyId: testCompanyId,
      );
      expect(result.rate, equals(15.0));
      expect(result.uncertaintyLevel, equals(UncertaintyLevel.certain));
      expect(result.disclaimer, isNotEmpty);
      expect(result.sourceUrl, contains('zatca.gov.sa'));
    });
    
    test('Export zero rate', () async {
      final result = await service.calculateTax(
        transactionType: 'EXPORT',
        countryCode: 'SA',
        transactionDate: DateTime(2024, 3, 15),
        baseAmount: 5000.0,
        companyId: testCompanyId,
      );
      expect(result.rate, equals(0.0));
      expect(result.ruleCode, equals('SA_VAT_ZERO_EXPORT'));
    });
    
    test('UNKNOWN for missing rule', () async {
      final result = await service.calculateTax(
        transactionType: 'IMPORT',
        countryCode: 'XX',  // Tanımsız ülke
        transactionDate: DateTime(2024, 3, 15),
        baseAmount: 100.0,
        companyId: testCompanyId,
      );
      expect(result.uncertaintyLevel, equals(UncertaintyLevel.unknown));
      expect(result.isCalculated, isFalse);
    });
  });
  
  group('Turkey VAT Historical', () {
    test('18% rate before 2023-07-10', () async {
      final result = await service.calculateTax(
        countryCode: 'TR',
        transactionDate: DateTime(2022, 6, 1),
        baseAmount: 1000.0,
        companyId: testCompanyId,
        transactionType: 'SALES',
      );
      expect(result.rate, equals(18.0));
    });
    
    test('20% rate after 2023-07-10', () async {
      final result = await service.calculateTax(
        countryCode: 'TR',
        transactionDate: DateTime(2024, 6, 1),
        baseAmount: 1000.0,
        companyId: testCompanyId,
        transactionType: 'SALES',
      );
      expect(result.rate, equals(20.0));
    });
  });
  
  group('Zakat Calculation', () {
    test('Full Saudi ownership 1M base → 25K zakat', () async {
      final result = await zakatService.calculate(
        companyId: testCompanyId,
        assessmentYear: '1446',
        balanceSheet: ZakatBalanceSheet(
          paidCapital: 1_000_000,
          legalReserves: 0,
          retainedEarnings: 0,
          currentYearProfit: 0,
          longTermDebt: 0,
          fixedAssetsNet: 0,
          intangibleAssets: 0,
          longTermInvestments: 0,
          longTermAdvances: 0,
        ),
        saudiOwnershipRatio: 1.0,
      );
      expect(result.zakatAmount, equals(25000.0));
      expect(result.isBelowNisab, isFalse);
      expect(result.disclaimer, isNotEmpty);
    });
    
    test('Below nisab threshold → zero zakat', () async {
      final result = await zakatService.calculate(
        companyId: testCompanyId,
        assessmentYear: '1446',
        balanceSheet: ZakatBalanceSheet(paidCapital: 10000, ...),
        saudiOwnershipRatio: 1.0,
      );
      expect(result.isBelowNisab, isTrue);
      expect(result.zakatAmount, equals(0.0));
    });
    
    test('50% Saudi ownership → proportional zakat', () async {
      final result = await zakatService.calculate(
        saudiOwnershipRatio: 0.5,
        balanceSheet: ZakatBalanceSheet(paidCapital: 1_000_000, ...),
        ...
      );
      expect(result.zakatAmount, equals(12500.0));
    });
  });
  
  group('GCC Tariff', () {
    test('Smartphone 8517.13 → 5% duty', () async {
      final result = await tariffService.calculateImportCost(
        hsCode: '8517.13',
        cifValue: 1000.0,
        importDate: DateTime(2024, 3, 15),
      );
      expect(result.customsDuty, equals(50.0));
      expect(result.importStatus, equals('ALLOWED'));
    });
    
    test('Prohibited item → PROHIBITED status', () async {
      final result = await tariffService.calculateImportCost(
        hsCode: '2208.90',  // Alkol
        cifValue: 1000.0,
        importDate: DateTime(2024, 3, 15),
      );
      expect(result.importStatus, equals('PROHIBITED'));
    });
    
    test('Unknown HS → UNKNOWN uncertainty', () async {
      final result = await tariffService.lookup(
        hsCode: '9999.99',
        importDate: DateTime(2024, 3, 15),
      );
      expect(result, isNull);
    });
  });
  
  group('Compliance Check', () {
    test('Company with CSID → COMPLIANT on ZATCA check', () async {
      final report = await complianceService.assessCompliance(
        companyId: testCompanyWithCsidId,
      );
      final csidCheck = report.checks
          .firstWhere((c) => c.checkCode == 'SA_ZATCA_PHASE2_CSID');
      expect(csidCheck.status, equals('COMPLIANT'));
    });
    
    test('Company without CSID → NON_COMPLIANT CRITICAL', () async {
      final report = await complianceService.assessCompliance(
        companyId: testCompanyWithoutCsidId,
      );
      final csidCheck = report.checks
          .firstWhere((c) => c.checkCode == 'SA_ZATCA_PHASE2_CSID');
      expect(csidCheck.status, equals('NON_COMPLIANT'));
      expect(csidCheck.severity, equals('CRITICAL'));
    });
    
    test('Overall RED for CRITICAL non-compliance', () async {
      final report = await complianceService.assessCompliance(
        companyId: testCompanyWithoutCsidId,
      );
      expect(report.overallStatus, equals('RED'));
    });
  });
  
  group('Disclaimer Presence', () {
    test('Every tax result has non-empty disclaimer', () async {
      final result = await service.calculateTax(...);
      expect(result.disclaimer, isNotEmpty);
      expect(result.disclaimer.length, greaterThan(50));
    });
  });
}
```

---

## 5. Test Koşturma Komutu

```bash
flutter test test/legislation/legislation_engine_test.dart --coverage
flutter test --coverage  # Tüm testler
```

---

## 6. Test Başarı Kriterleri

| Kriter | Eşik |
|---|---|
| Toplam test sayısı | ≥ 195 (mevcut 145 + en az 50 yeni) |
| Başarı oranı | %100 (0 başarısız) |
| Flutter analyze | 0 issue |
| Flutter build web | Başarılı |
| SA KDV kural testleri | En az 8 test case |
| Zekât hesaplama testleri | En az 5 test case |
| UNKNOWN durum testleri | En az 5 test case |
| Cross-tenant izolasyon | En az 3 PostgreSQL testi |

---

*Bu rapor mevcut `test/commercial_and_migration_test.dart` ile uyumlu test yapısını korur.*
