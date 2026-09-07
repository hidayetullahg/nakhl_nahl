import '../services/supabase_service.dart';

class Tenant {
  final String id;
  final String code;
  final String legalName;
  final String displayName;
  final String countryCode;
  final String defaultCurrencyCode;

  const Tenant({
    required this.id,
    required this.code,
    required this.legalName,
    required this.displayName,
    required this.countryCode,
    required this.defaultCurrencyCode,
  });

  factory Tenant.fromMap(Map<String, dynamic> map) {
    return Tenant(
      id: map['id'] ?? '',
      code: map['code'] ?? '',
      legalName: map['legal_name'] ?? '',
      displayName: map['display_name'] ?? '',
      countryCode: map['country_code'] ?? 'SA',
      defaultCurrencyCode: map['default_currency_code'] ?? 'SAR',
    );
  }
}

class TenantRepository {
  TenantRepository._();
  static final TenantRepository instance = TenantRepository._();

  /// Kullanıcının üyesi olduğu tenant'ları listeler
  Future<List<Tenant>> getUserTenants() async {
    try {
      final response = await SupabaseService.client
          .from('tenant_users')
          .select(
              'tenant_id, tenants(id, code, legal_name, display_name, country_code, default_currency_code)')
          .eq('status', 'ACTIVE');

      final List<Tenant> tenants = [];
      for (final row in (response as List<dynamic>)) {
        if (row['tenants'] != null) {
          tenants.add(Tenant.fromMap(row['tenants'] as Map<String, dynamic>));
        }
      }
      return tenants;
    } catch (e) {
      return [];
    }
  }

  /// Yeni Tenant (Kiracı) kaydı oluşturur
  Future<Tenant?> createTenant({
    required String code,
    required String legalName,
    required String displayName,
    String countryCode = 'SA',
    String defaultCurrencyCode = 'SAR',
  }) async {
    try {
      final response = await SupabaseService.client
          .from('tenants')
          .insert({
            'code': code.toUpperCase().trim(),
            'legal_name': legalName.trim(),
            'display_name': displayName.trim(),
            'country_code': countryCode,
            'default_currency_code': defaultCurrencyCode,
          })
          .select()
          .single();

      return Tenant.fromMap(response);
    } catch (e) {
      return null;
    }
  }
}
