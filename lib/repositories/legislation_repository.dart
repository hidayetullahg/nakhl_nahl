import '../services/supabase_service.dart';
import '../core/tenant/tenant_context.dart';
import '../data/legislation_repository.dart' as static_data;
import '../models/legislation_model.dart';

export '../models/legislation_model.dart';
export '../data/legislation_repository.dart';

class LegislationRecordModel {
  final String id;
  final String countryCode;
  final String jurisdiction;
  final String legislationCode;
  final String title;
  final DateTime effectiveFrom;
  final DateTime? effectiveTo;
  final String version;
  final String? sourceReference;
  final String status;
  final String? notes;

  const LegislationRecordModel({
    required this.id,
    required this.countryCode,
    required this.jurisdiction,
    required this.legislationCode,
    required this.title,
    required this.effectiveFrom,
    this.effectiveTo,
    required this.version,
    this.sourceReference,
    required this.status,
    this.notes,
  });

  bool get isActive =>
      status == 'ACTIVE' &&
      (effectiveTo == null || effectiveTo!.isAfter(DateTime.now()));

  factory LegislationRecordModel.fromJson(Map<String, dynamic> json) {
    return LegislationRecordModel(
      id: json['id'] as String,
      countryCode: json['country_code'] as String,
      jurisdiction: json['jurisdiction'] as String? ?? 'NATIONAL',
      legislationCode: json['legislation_code'] as String? ?? '',
      title: json['title'] as String? ?? '',
      effectiveFrom: DateTime.parse(json['effective_from'] as String),
      effectiveTo: json['effective_to'] != null
          ? DateTime.parse(json['effective_to'] as String)
          : null,
      version: json['version'] as String? ?? '1.0',
      sourceReference: json['source_reference'] as String?,
      status: json['status'] as String? ?? 'ACTIVE',
      notes: json['notes'] as String?,
    );
  }
}

class TaxRuleModel {
  final String id;
  final String companyId;
  final String? legislationId;
  final String ruleCode;
  final String ruleName;
  final String taxType; // VAT, GST, WITHHOLDING, EXPORT_ZERO, CUSTOMS, EXCISE
  final double rate;
  final String countryCode;
  final String jurisdiction;
  final DateTime effectiveFrom;
  final DateTime? effectiveTo;
  final String? productCategoryId;
  final String? itemId;
  final String transactionType; // SALES, PURCHASE, EXPORT, IMPORT, ALL
  final bool isReverseCharge;
  final bool isRecoverable;
  final int priority;
  final bool isActive;

  const TaxRuleModel({
    required this.id,
    required this.companyId,
    this.legislationId,
    required this.ruleCode,
    required this.ruleName,
    required this.taxType,
    required this.rate,
    required this.countryCode,
    required this.jurisdiction,
    required this.effectiveFrom,
    this.effectiveTo,
    this.productCategoryId,
    this.itemId,
    required this.transactionType,
    required this.isReverseCharge,
    required this.isRecoverable,
    required this.priority,
    required this.isActive,
  });

  factory TaxRuleModel.fromJson(Map<String, dynamic> json) {
    return TaxRuleModel(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      legislationId: json['legislation_id'] as String?,
      ruleCode: json['rule_code'] as String? ?? '',
      ruleName: json['rule_name'] as String? ?? '',
      taxType: json['tax_type'] as String? ?? 'VAT',
      rate: (json['rate'] as num).toDouble(),
      countryCode: json['country_code'] as String? ?? 'SA',
      jurisdiction: json['jurisdiction'] as String? ?? 'NATIONAL',
      effectiveFrom: DateTime.parse(json['effective_from'] as String),
      effectiveTo: json['effective_to'] != null
          ? DateTime.parse(json['effective_to'] as String)
          : null,
      productCategoryId: json['product_category_id'] as String?,
      itemId: json['item_id'] as String?,
      transactionType: json['transaction_type'] as String? ?? 'ALL',
      isReverseCharge: json['is_reverse_charge'] as bool? ?? false,
      isRecoverable: json['is_recoverable'] as bool? ?? true,
      priority: (json['priority'] as num?)?.toInt() ?? 100,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

class TaxCalculationResult {
  final String? ruleId;
  final String ruleCode;
  final String taxType;
  final double rate;
  final double baseAmount;
  final double taxAmount;
  final double totalAmount;
  final bool isReverseCharge;
  final bool isRecoverable;
  final String legislationCode;
  final String legislationVersion;

  const TaxCalculationResult({
    this.ruleId,
    required this.ruleCode,
    required this.taxType,
    required this.rate,
    required this.baseAmount,
    required this.taxAmount,
    required this.totalAmount,
    required this.isReverseCharge,
    required this.isRecoverable,
    required this.legislationCode,
    required this.legislationVersion,
  });

  factory TaxCalculationResult.fromRpc(
      Map<String, dynamic> json, double baseAmount) {
    return TaxCalculationResult(
      ruleId: json['rule_id'] as String?,
      ruleCode: json['rule_code'] as String? ?? 'STANDARD',
      taxType: json['tax_type'] as String? ?? 'VAT',
      rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
      baseAmount: baseAmount,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? baseAmount,
      isReverseCharge: json['is_reverse_charge'] as bool? ?? false,
      isRecoverable: json['is_recoverable'] as bool? ?? true,
      legislationCode: json['legislation_code'] as String? ?? 'STANDARD',
      legislationVersion: json['legislation_version'] as String? ?? '1.0',
    );
  }

  /// Çevrimdışı / Local Hesaplama Fallback
  factory TaxCalculationResult.computeLocally({
    required double baseAmount,
    required double rate,
    String ruleCode = 'LOCAL_FALLBACK',
    String taxType = 'VAT',
    bool isReverseCharge = false,
    bool isRecoverable = true,
  }) {
    final tax = double.parse((baseAmount * (rate / 100.0)).toStringAsFixed(2));
    final total = double.parse((baseAmount + tax).toStringAsFixed(2));
    return TaxCalculationResult(
      ruleCode: ruleCode,
      taxType: taxType,
      rate: rate,
      baseAmount: baseAmount,
      taxAmount: tax,
      totalAmount: total,
      isReverseCharge: isReverseCharge,
      isRecoverable: isRecoverable,
      legislationCode: 'LOCAL_RULE',
      legislationVersion: '1.0',
    );
  }
}

/// NAKHL & NAHL — Merkezi Mevzuat ve Vergi Motoru Servisi
class TaxEngine {
  TaxEngine._();
  static final TaxEngine instance = TaxEngine._();

  /// Statik Ülke Mevzuatı Getir (Mevcut yapı korunmuştur)
  CountryLegislation getStaticLegislation(String countryCode) {
    return static_data.LegislationRepository.getLegislation(countryCode);
  }

  /// Veritabanı Mevzuat Kayıtlarını Listeler
  Future<List<LegislationRecordModel>> getLegislations({
    String? countryCode,
    String? jurisdiction,
  }) async {
    try {
      var query = SupabaseService.client.from('legislations').select();
      if (countryCode != null) {
        query = query.eq('country_code', countryCode);
      }
      if (jurisdiction != null) {
        query = query.eq('jurisdiction', jurisdiction);
      }

      final res = await query.order('effective_from', ascending: false);
      return (res as List<dynamic>)
          .map((data) =>
              LegislationRecordModel.fromJson(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Şirketin Vergi Kurallarını Listeler
  Future<List<TaxRuleModel>> getTaxRules(
    String companyId, {
    String? countryCode,
    String? transactionType,
  }) async {
    try {
      var query = SupabaseService.client
          .from('tax_rules')
          .select()
          .eq('company_id', companyId);

      if (countryCode != null) {
        query = query.eq('country_code', countryCode);
      }
      if (transactionType != null) {
        query = query
            .or('transaction_type.eq.$transactionType,transaction_type.eq.ALL');
      }

      final res = await query.order('priority', ascending: false);
      return (res as List<dynamic>)
          .map((data) => TaxRuleModel.fromJson(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// MERKEZİ VERGİ HESAPLAMA (Centralized Tax Calculation)
  /// UI içinde dağınık vergi hesabı bırakmaz.
  /// İşlem türü (SALES, PURCHASE, EXPORT), ülke, tarih ve ürün bazlı tarihsel vergi motoru.
  Future<TaxCalculationResult> calculateTax({
    required String companyId,
    required String transactionType, // SALES, PURCHASE, EXPORT, IMPORT
    required String countryCode,
    required double baseAmount,
    DateTime? transactionDate,
    String? itemId,
    String jurisdiction = 'NATIONAL',
  }) async {
    final tDate = transactionDate ?? DateTime.now();
    final tDateStr = tDate.toIso8601String().substring(0, 10);
    final tenantId = TenantContext.instance.activeTenantId;

    try {
      if (tenantId != null) {
        final res = await SupabaseService.client
            .rpc('calculate_transaction_tax', params: {
          'p_tenant_id': tenantId,
          'p_company_id': companyId,
          'p_transaction_type': transactionType,
          'p_country_code': countryCode,
          'p_transaction_date': tDateStr,
          'p_base_amount': baseAmount,
          'p_item_id': itemId,
          'p_jurisdiction': jurisdiction,
        });

        if (res is List && res.isNotEmpty) {
          return TaxCalculationResult.fromRpc(
              res.first as Map<String, dynamic>, baseAmount);
        } else if (res is Map<String, dynamic>) {
          return TaxCalculationResult.fromRpc(res, baseAmount);
        }
      }
    } catch (_) {
      // Çevrimdışı veya hata durumunda yerel kurala düş
    }

    // İhracatta varsayılan vergi istisnası (%0 Zero-Rated)
    if (transactionType == 'EXPORT') {
      return TaxCalculationResult.computeLocally(
        baseAmount: baseAmount,
        rate: 0.0,
        ruleCode: 'EXPORT_ZERO_RATED',
        taxType: 'EXPORT_ZERO',
      );
    }

    // Ülke bazlı varsayılan oran (SA: %15, TR: %10, vb.)
    double defaultRate = 15.0;
    if (countryCode == 'TR') {
      defaultRate = 1.0; // Toptan hurma teslimlerinde %1 KDV
    } else if (countryCode == 'AE') {
      defaultRate = 5.0;
    }

    return TaxCalculationResult.computeLocally(
      baseAmount: baseAmount,
      rate: defaultRate,
      ruleCode: '${countryCode}_DEFAULT_${defaultRate.toInt()}',
    );
  }
}
