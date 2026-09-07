import '../services/supabase_service.dart';
import '../core/tenant/tenant_context.dart';

class Supplier {
  final String id;
  final String tenantId;
  final String companyId;
  final String partyId;
  final String supplierCode;
  final int paymentTermsDays;
  final String currencyCode;
  final String? taxProfileId;
  final int leadTimeDays;
  final String status;
  final String? legalName;
  final String? taxNumber;
  final String? phone;
  final String? email;

  const Supplier({
    required this.id,
    required this.tenantId,
    required this.companyId,
    required this.partyId,
    required this.supplierCode,
    required this.paymentTermsDays,
    required this.currencyCode,
    this.taxProfileId,
    required this.leadTimeDays,
    required this.status,
    this.legalName,
    this.taxNumber,
    this.phone,
    this.email,
  });

  factory Supplier.fromMap(Map<String, dynamic> map) {
    final partyMap = map['parties'] as Map<String, dynamic>?;
    return Supplier(
      id: map['id'] ?? '',
      tenantId: map['tenant_id'] ?? '',
      companyId: map['company_id'] ?? '',
      partyId: map['party_id'] ?? '',
      supplierCode: map['supplier_code'] ?? '',
      paymentTermsDays: map['payment_terms_days'] ?? 30,
      currencyCode: map['currency_code'] ?? 'SAR',
      taxProfileId: map['tax_profile_id'],
      leadTimeDays: map['lead_time_days'] ?? 7,
      status: map['status'] ?? 'ACTIVE',
      legalName: partyMap?['legal_name'],
      taxNumber: partyMap?['tax_number'],
      phone: partyMap?['phone'],
      email: partyMap?['email'],
    );
  }
}

class SupplierRepository {
  SupplierRepository._();
  static final SupplierRepository instance = SupplierRepository._();

  /// Şirkete ait tedarikçileri listeler
  Future<List<Supplier>> getSuppliers(String companyId,
      {bool onlyActive = true}) async {
    try {
      var query = SupabaseService.client
          .from('suppliers')
          .select('*, parties(legal_name, tax_number, phone, email)')
          .eq('company_id', companyId);

      if (onlyActive) {
        query = query.eq('status', 'ACTIVE');
      }

      final response = await query.order('supplier_code', ascending: true);
      return (response as List<dynamic>)
          .map((m) => Supplier.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Yeni tedarikçi master kaydı oluşturur
  Future<Supplier?> createSupplier({
    required String companyId,
    required String partyId,
    required String supplierCode,
    String? taxProfileId,
    int paymentTermsDays = 30,
    String currencyCode = 'SAR',
    int leadTimeDays = 7,
  }) async {
    try {
      final tenantId = TenantContext.instance.activeTenantId;
      if (tenantId == null) throw Exception('Aktif tenant seçilmedi.');

      final response = await SupabaseService.client
          .from('suppliers')
          .insert({
            'tenant_id': tenantId,
            'company_id': companyId,
            'party_id': partyId,
            'supplier_code': supplierCode.trim(),
            'tax_profile_id': taxProfileId,
            'payment_terms_days': paymentTermsDays,
            'currency_code': currencyCode,
            'lead_time_days': leadTimeDays,
            'status': 'ACTIVE',
          })
          .select('*, parties(legal_name, tax_number, phone, email)')
          .single();

      return Supplier.fromMap(response);
    } catch (_) {
      return null;
    }
  }
}
