import '../services/supabase_service.dart';
import '../core/tenant/tenant_context.dart';

class Customer {
  final String id;
  final String tenantId;
  final String companyId;
  final String partyId;
  final String customerCode;
  final String? taxProfileId;
  final int paymentTermsDays;
  final String currencyCode;
  final double creditLimit;
  final String status;
  final String? legalName;
  final String? taxNumber;
  final String? phone;
  final String? email;

  const Customer({
    required this.id,
    required this.tenantId,
    required this.companyId,
    required this.partyId,
    required this.customerCode,
    this.taxProfileId,
    required this.paymentTermsDays,
    required this.currencyCode,
    required this.creditLimit,
    required this.status,
    this.legalName,
    this.taxNumber,
    this.phone,
    this.email,
  });

  factory Customer.fromMap(Map<String, dynamic> map) {
    final partyMap = map['parties'] as Map<String, dynamic>?;
    return Customer(
      id: map['id'] ?? '',
      tenantId: map['tenant_id'] ?? '',
      companyId: map['company_id'] ?? '',
      partyId: map['party_id'] ?? '',
      customerCode: map['customer_code'] ?? '',
      taxProfileId: map['tax_profile_id'],
      paymentTermsDays: map['payment_terms_days'] ?? 30,
      currencyCode: map['currency_code'] ?? 'SAR',
      creditLimit: (map['credit_limit'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'ACTIVE',
      legalName: partyMap?['legal_name'],
      taxNumber: partyMap?['tax_number'],
      phone: partyMap?['phone'],
      email: partyMap?['email'],
    );
  }
}

class CustomerRepository {
  CustomerRepository._();
  static final CustomerRepository instance = CustomerRepository._();

  /// Şirkete ait müşterileri listeler
  Future<List<Customer>> getCustomers(String companyId,
      {bool onlyActive = true}) async {
    try {
      var query = SupabaseService.client
          .from('customers')
          .select('*, parties(legal_name, tax_number, phone, email)')
          .eq('company_id', companyId);

      if (onlyActive) {
        query = query.eq('status', 'ACTIVE');
      }

      final response = await query.order('customer_code', ascending: true);
      return (response as List<dynamic>)
          .map((m) => Customer.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Yeni müşteri master kaydı oluşturur
  Future<Customer?> createCustomer({
    required String companyId,
    required String partyId,
    required String customerCode,
    String? taxProfileId,
    int paymentTermsDays = 30,
    String currencyCode = 'SAR',
    double creditLimit = 0.0,
  }) async {
    try {
      final tenantId = TenantContext.instance.activeTenantId;
      if (tenantId == null) throw Exception('Aktif tenant seçilmedi.');

      final response = await SupabaseService.client
          .from('customers')
          .insert({
            'tenant_id': tenantId,
            'company_id': companyId,
            'party_id': partyId,
            'customer_code': customerCode.trim(),
            'tax_profile_id': taxProfileId,
            'payment_terms_days': paymentTermsDays,
            'currency_code': currencyCode,
            'credit_limit': creditLimit,
            'status': 'ACTIVE',
          })
          .select('*, parties(legal_name, tax_number, phone, email)')
          .single();

      return Customer.fromMap(response);
    } catch (_) {
      return null;
    }
  }
}
