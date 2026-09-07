import '../services/supabase_service.dart';

class Company {
  final String id;
  final String tenantId;
  final String code;
  final String legalName;
  final String? tradeName;
  final String? taxNumber;
  final String currencyCode;

  const Company({
    required this.id,
    required this.tenantId,
    required this.code,
    required this.legalName,
    this.tradeName,
    this.taxNumber,
    required this.currencyCode,
  });

  factory Company.fromMap(Map<String, dynamic> map) {
    return Company(
      id: map['id'] ?? '',
      tenantId: map['tenant_id'] ?? '',
      code: map['code'] ?? '',
      legalName: map['legal_name'] ?? '',
      tradeName: map['trade_name'],
      taxNumber: map['tax_number'],
      currencyCode: map['currency_code'] ?? 'SAR',
    );
  }
}

class CompanyRepository {
  CompanyRepository._();
  static final CompanyRepository instance = CompanyRepository._();

  /// Belirli bir tenant'a ait şirketleri listeler
  Future<List<Company>> getCompanies(String tenantId) async {
    try {
      final response = await SupabaseService.client
          .from('companies')
          .select()
          .eq('tenant_id', tenantId)
          .eq('status', 'ACTIVE');

      return (response as List<dynamic>)
          .map((m) => Company.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Yeni şirket oluşturur
  Future<Company?> createCompany({
    required String tenantId,
    required String code,
    required String legalName,
    String? tradeName,
    String? taxNumber,
    String currencyCode = 'SAR',
  }) async {
    try {
      final response = await SupabaseService.client
          .from('companies')
          .insert({
            'tenant_id': tenantId,
            'code': code.toUpperCase().trim(),
            'legal_name': legalName.trim(),
            'trade_name': tradeName?.trim(),
            'tax_number': taxNumber?.trim(),
            'currency_code': currencyCode,
          })
          .select()
          .single();

      return Company.fromMap(response);
    } catch (e) {
      return null;
    }
  }
}
