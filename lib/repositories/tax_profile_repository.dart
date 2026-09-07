import '../services/supabase_service.dart';
import '../core/tenant/tenant_context.dart';

class TaxProfile {
  final String id;
  final String tenantId;
  final String companyId;
  final String? countryCode;
  final String code;
  final String name;
  final String taxType; // VAT, GST, WITHHOLDING, EXPORT_ZERO, CUSTOMS
  final double rate;
  final bool isRecoverable;
  final bool isActive;

  const TaxProfile({
    required this.id,
    required this.tenantId,
    required this.companyId,
    this.countryCode,
    required this.code,
    required this.name,
    required this.taxType,
    required this.rate,
    required this.isRecoverable,
    required this.isActive,
  });

  factory TaxProfile.fromMap(Map<String, dynamic> map) {
    return TaxProfile(
      id: map['id'] ?? '',
      tenantId: map['tenant_id'] ?? '',
      companyId: map['company_id'] ?? '',
      countryCode: map['country_code'],
      code: map['code'] ?? '',
      name: map['name'] ?? '',
      taxType: map['tax_type'] ?? 'VAT',
      rate: (map['rate'] as num?)?.toDouble() ?? 0.0,
      isRecoverable: map['is_recoverable'] ?? true,
      isActive: map['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tenant_id': tenantId,
      'company_id': companyId,
      'country_code': countryCode,
      'code': code,
      'name': name,
      'tax_type': taxType,
      'rate': rate,
      'is_recoverable': isRecoverable,
      'is_active': isActive,
    };
  }
}

class TaxProfileRepository {
  TaxProfileRepository._();
  static final TaxProfileRepository instance = TaxProfileRepository._();

  /// Şirkete veya ülkeye ait vergi profillerini listeler
  Future<List<TaxProfile>> getTaxProfiles(String companyId,
      {bool onlyActive = true}) async {
    try {
      var query = SupabaseService.client
          .from('tax_profiles')
          .select()
          .eq('company_id', companyId);

      if (onlyActive) {
        query = query.eq('is_active', true);
      }

      final response = await query.order('rate', ascending: true);
      return (response as List<dynamic>)
          .map((m) => TaxProfile.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Yeni vergi profili oluşturur
  Future<TaxProfile?> createTaxProfile({
    required String companyId,
    String? countryCode,
    required String code,
    required String name,
    String taxType = 'VAT',
    required double rate,
    bool isRecoverable = true,
  }) async {
    try {
      final tenantId = TenantContext.instance.activeTenantId;
      if (tenantId == null) throw Exception('Aktif tenant seçilmedi.');

      final response = await SupabaseService.client
          .from('tax_profiles')
          .insert({
            'tenant_id': tenantId,
            'company_id': companyId,
            'country_code': countryCode,
            'code': code.toUpperCase().trim(),
            'name': name.trim(),
            'tax_type': taxType,
            'rate': rate,
            'is_recoverable': isRecoverable,
          })
          .select()
          .single();

      return TaxProfile.fromMap(response);
    } catch (_) {
      return null;
    }
  }
}
