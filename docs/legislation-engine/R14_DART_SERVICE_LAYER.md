# R14 — DART/FLUTTER SERVİS KATMANI TASARIMI
## Legislation Engine — Dart Service Layer Architecture

**Rapor No:** R14  
**Versiyon:** 1.0  
**Tarih:** 2026-09-07  
**Durum:** ONAY BEKLİYOR  

---

## 1. Servis Katmanı Genel Mimarisi

```
lib/
  services/
    legislation/                    ← YENİ dizin
      legislation_engine_service.dart     (Ana facade)
      sa_vat_service.dart                (SA KDV)
      sa_excise_service.dart             (SA ÖTV)
      zakat_calculation_service.dart     (Zekât)
      gcc_tariff_service.dart            (GCC Gümrük Tarifesi)
      withholding_tax_service.dart       (Stopaj Vergisi)
      compliance_check_service.dart      (Uyum Kontrol)
      legislation_source_service.dart    (Kaynak Referanslar)
    zatca_adapter.dart             ← MEVCUT (genişletilecek)
    einvoice_adapter.dart          ← MEVCUT (korunuyor)
```

---

## 2. Ana Veri Modelleri

```dart
// lib/models/legislation/tax_calculation_result.dart

enum UncertaintyLevel {
  certain,
  uncertain,
  unknown,
  inapplicable;
  
  String get displayLabel {
    switch (this) {
      case UncertaintyLevel.certain:     return 'Kesin';
      case UncertaintyLevel.uncertain:   return 'Belirsiz — Doğrulama Önerilir';
      case UncertaintyLevel.unknown:     return 'Bilinmiyor — Danışman Gerekli';
      case UncertaintyLevel.inapplicable:return 'Uygulanamaz';
    }
  }
  
  bool get allowsCalculation =>
    this == UncertaintyLevel.certain || this == UncertaintyLevel.uncertain;
}

class TaxCalculationResult {
  final String? ruleId;
  final String ruleCode;
  final String taxType;        // VAT, EXCISE, CUSTOMS, ZAKAT, WITHHOLDING
  final double rate;
  final double taxAmount;
  final double totalAmount;
  final bool isReverseCharge;
  final bool isRecoverable;
  final String? legislationCode;
  final String? legislationVersion;
  
  // Yeni alanlar (v2)
  final String? sourceUrl;
  final String? sourceReference;
  final UncertaintyLevel uncertaintyLevel;
  final String disclaimer;
  final String? calculationBasis;    // AD_VALOREM, SPECIFIC, COMPOUND
  final List<TaxCalculationResult>? additionalTaxes; // ÖTV + KDV birleşik

  bool get isCalculated => uncertaintyLevel.allowsCalculation;
  
  const TaxCalculationResult({
    this.ruleId,
    required this.ruleCode,
    required this.taxType,
    required this.rate,
    required this.taxAmount,
    required this.totalAmount,
    this.isReverseCharge = false,
    this.isRecoverable = true,
    this.legislationCode,
    this.legislationVersion,
    this.sourceUrl,
    this.sourceReference,
    this.uncertaintyLevel = UncertaintyLevel.certain,
    required this.disclaimer,
    this.calculationBasis,
    this.additionalTaxes,
  });
  
  factory TaxCalculationResult.fromJson(Map<String, dynamic> json) { ... }
  
  static TaxCalculationResult unknown({required String disclaimer}) =>
    TaxCalculationResult(
      ruleCode: 'UNKNOWN',
      taxType: 'UNKNOWN',
      rate: 0,
      taxAmount: 0,
      totalAmount: 0,
      uncertaintyLevel: UncertaintyLevel.unknown,
      disclaimer: disclaimer,
    );
}
```

---

## 3. Ana Facade: `LegislationEngineService`

```dart
// lib/services/legislation/legislation_engine_service.dart

class LegislationEngineService {
  final SupabaseClient _supabase;
  
  // Alt servisler
  late final SaVatService vat;
  late final SaExciseService excise;
  late final ZakatCalculationService zakat;
  late final GccTariffService tariff;
  late final WithholdingTaxService withholding;
  late final ComplianceCheckService compliance;
  
  LegislationEngineService(this._supabase) {
    vat        = SaVatService(_supabase);
    excise     = SaExciseService(_supabase);
    zakat      = ZakatCalculationService(_supabase);
    tariff     = GccTariffService(_supabase);
    withholding = WithholdingTaxService(_supabase);
    compliance = ComplianceCheckService(_supabase);
  }
  
  /// Evrensel vergi hesaplama (v2)
  /// Tüm kural tiplerini tek noktadan çağırır
  Future<TaxCalculationResult> calculateTax({
    required String companyId,
    required String transactionType,  // SALES, PURCHASE, EXPORT, IMPORT, ZAKAT
    required String countryCode,
    required DateTime transactionDate,
    required double baseAmount,
    String? itemId,
    String? hsCode,
    String? jurisdiction,
  }) async {
    try {
      final result = await _supabase.rpc(
        'calculate_transaction_tax_v2',
        params: {
          'p_tenant_id':         _tenantId,
          'p_company_id':        companyId,
          'p_transaction_type':  transactionType,
          'p_country_code':      countryCode,
          'p_transaction_date':  transactionDate.toIso8601String().substring(0, 10),
          'p_base_amount':       baseAmount,
          'p_item_id':           itemId,
          'p_jurisdiction':      jurisdiction ?? 'NATIONAL',
          'p_hs_code':           hsCode,
        }
      );
      return TaxCalculationResult.fromJson(result);
    } catch (e) {
      return TaxCalculationResult.unknown(
        disclaimer: LegislationDisclaimer.unknown,
      );
    }
  }
  
  /// Şirket uyum durumu değerlendirme
  Future<ComplianceReport> assessCompliance(String companyId) =>
    compliance.assessCompliance(companyId: companyId);
  
  /// Gelecek mevzuat değişikliklerini getir
  Future<List<LegislationChangeAlert>> getUpcomingChanges(String countryCode) async { ... }
}
```

---

## 4. SA KDV Servisi

```dart
// lib/services/legislation/sa_vat_service.dart

class SaVatService {
  final SupabaseClient _supabase;
  
  /// SA KDV hesaplama (calculate_transaction_tax_v2 sarmalayıcı)
  Future<TaxCalculationResult> calculateVat({
    required String companyId,
    required String transactionType,
    required double baseAmount,
    required DateTime transactionDate,
    String? itemId,
  }) async { ... }
  
  /// KDV muafiyeti kontrolü
  Future<bool> isExempt({
    required String itemCategory,
    required String transactionType,
    required DateTime date,
  }) async { ... }
  
  /// Reverse charge kontrolü
  Future<bool> requiresReverseCharge({
    required String transactionType,
    required String supplierCountry,
  }) async { ... }
}
```

---

## 5. Zekât Servisi

```dart
// lib/services/legislation/zakat_calculation_service.dart

class ZakatCalculationService {
  
  Future<ZakatAssessmentResult> calculate({
    required String companyId,
    required String assessmentYear,
    required ZakatBalanceSheet balanceSheet,
    required double saudiOwnershipRatio,
  }) async {
    final result = await _supabase.rpc('calculate_zakat', params: {
      'p_tenant_id':              _tenantId,
      'p_company_id':             companyId,
      'p_assessment_year':        assessmentYear,
      'p_paid_capital':           balanceSheet.paidCapital,
      'p_legal_reserves':         balanceSheet.legalReserves,
      'p_retained_earnings':      balanceSheet.retainedEarnings,
      'p_current_year_profit':    balanceSheet.currentYearProfit,
      'p_long_term_debt':         balanceSheet.longTermDebt,
      'p_fixed_assets_net':       balanceSheet.fixedAssetsNet,
      'p_intangible_assets':      balanceSheet.intangibleAssets,
      'p_long_term_investments':  balanceSheet.longTermInvestments,
      'p_long_term_advances':     balanceSheet.longTermAdvances,
      'p_saudi_ownership_ratio':  saudiOwnershipRatio,
    });
    return ZakatAssessmentResult.fromJson(result);
  }
  
  Future<double> getNisabThreshold(String hijriYear) async { ... }
  
  Future<void> saveAssessment(ZakatAssessmentResult result, String companyId) async { ... }
}

class ZakatBalanceSheet {
  final double paidCapital;
  final double legalReserves;
  final double retainedEarnings;
  final double currentYearProfit;
  final double longTermDebt;
  final double fixedAssetsNet;
  final double intangibleAssets;
  final double longTermInvestments;
  final double longTermAdvances;
  
  const ZakatBalanceSheet({...});
  
  double get zakatBase =>
    paidCapital + legalReserves + retainedEarnings + currentYearProfit +
    longTermDebt - fixedAssetsNet - intangibleAssets -
    longTermInvestments - longTermAdvances;
}
```

---

## 6. GCC Tarife Servisi

```dart
// lib/services/legislation/gcc_tariff_service.dart

class GccTariffService {
  
  /// HS kodu ile tarife arama
  Future<TariffLookupResult?> lookup({
    required String hsCode,
    required DateTime importDate,
  }) async { ... }
  
  /// Toplam ithalat maliyeti hesabı
  Future<ImportCostCalculation> calculateImportCost({
    required String hsCode,
    required double cifValue,
    required DateTime importDate,
    String originCountry = 'UNKNOWN',
    bool hasExemption = false,
  }) async { ... }
  
  /// Metin ile HS kodu arama
  Future<List<TariffCode>> searchByDescription(String query) async { ... }
  
  /// HS kodu geçerlilik kontrolü
  bool isValidHsCode(String code) =>
    RegExp(r'^\d{4,8}$').hasMatch(code.replaceAll('.', ''));
}

class ImportCostCalculation {
  final String hsCode;
  final String descriptionEn;
  final double cifValue;
  final double gccCetRate;
  final double customsDuty;
  final bool exciseApplicable;
  final double exciseAmount;
  final double vatBase;
  final double vatAmount;
  final double totalLandedCost;
  final String importStatus;     // ALLOWED, RESTRICTED, PROHIBITED
  final UncertaintyLevel uncertaintyLevel;
  final String disclaimer;
}
```

---

## 7. Bağımlılık Enjeksiyonu

```dart
// lib/main.dart içinde servis sağlayıcı

MultiProvider(
  providers: [
    Provider<LegislationEngineService>(
      create: (ctx) => LegislationEngineService(Supabase.instance.client),
    ),
    // Alt servisler LegislationEngineService üzerinden erişilir
  ],
  child: MyApp(),
)
```

---

## 8. Test Stratejisi (Servis Katmanı)

```dart
// test/legislation/legislation_engine_test.dart

void main() {
  group('SA VAT', () {
    test('Standard rate %15 after 2020-07-01', () async { ... });
    test('Export zero rate', () async { ... });
    test('Reverse charge for imported services', () async { ... });
  });
  
  group('Zakat', () {
    test('Full Saudi ownership 1M base → 25K zakat', () async { ... });
    test('Below nisab threshold → 0 zakat', () async { ... });
  });
  
  group('GCC Tariff', () {
    test('Smartphone HS 8517.13 → 5% duty', () async { ... });
    test('Prohibited item → PROHIBITED status', () async { ... });
    test('Unknown HS code → UNKNOWN result', () async { ... });
  });
  
  group('Compliance', () {
    test('Company with CSID → COMPLIANT', () async { ... });
    test('Company without CSID → NON_COMPLIANT CRITICAL', () async { ... });
  });
}
```

---

*Bu rapor R13 (Migrasyon Tasarımı) ile birlikte okunmalıdır. Dart servisleri R13'teki SQL fonksiyonlarının doğrudan sarmalayıcılarıdır.*
