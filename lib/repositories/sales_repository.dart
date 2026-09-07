import '../services/supabase_service.dart';
import '../core/tenant/tenant_context.dart';

/// Satış Siparişi Modeli
class SalesOrderModel {
  final String id;
  final String orderNumber;
  final DateTime orderDate;
  final DateTime? expectedDeliveryDate;
  final String customerId;
  final String warehouseId;
  final String currency;
  final double subtotal;
  final double taxAmount;
  final double grandTotal;
  final String
      status; // DRAFT, CONFIRMED, PROCESSING, SHIPPED, DELIVERED, CANCELLED
  final String? notes;

  const SalesOrderModel({
    required this.id,
    required this.orderNumber,
    required this.orderDate,
    this.expectedDeliveryDate,
    required this.customerId,
    required this.warehouseId,
    required this.currency,
    required this.subtotal,
    required this.taxAmount,
    required this.grandTotal,
    required this.status,
    this.notes,
  });

  factory SalesOrderModel.fromMap(Map<String, dynamic> map) {
    return SalesOrderModel(
      id: map['id'] ?? '',
      orderNumber: map['order_number'] ?? '',
      orderDate: DateTime.parse(map['order_date'].toString()),
      expectedDeliveryDate: map['expected_delivery_date'] != null
          ? DateTime.tryParse(map['expected_delivery_date'].toString())
          : null,
      customerId: map['customer_id'] ?? '',
      warehouseId: map['warehouse_id'] ?? '',
      currency: map['currency'] ?? 'SAR',
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (map['tax_amount'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (map['grand_total'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'DRAFT',
      notes: map['notes'],
    );
  }
}

/// Fatura Modeli (Satış ve Alış için)
class InvoiceModel {
  final String id;
  final String invoiceType; // SALES, PURCHASE
  final String invoiceNumber;
  final DateTime invoiceDate;
  final DateTime? dueDate;
  final String partyId;
  final String warehouseId;
  final String currency;
  final double subtotal;
  final double taxRate;
  final double taxAmount;
  final double grandTotal;
  final String status; // DRAFT, POSTED, CANCELLED
  final String? journalEntryId;
  final String? notes;

  const InvoiceModel({
    required this.id,
    required this.invoiceType,
    required this.invoiceNumber,
    required this.invoiceDate,
    this.dueDate,
    required this.partyId,
    required this.warehouseId,
    required this.currency,
    required this.subtotal,
    required this.taxRate,
    required this.taxAmount,
    required this.grandTotal,
    required this.status,
    this.journalEntryId,
    this.notes,
  });

  factory InvoiceModel.fromMap(Map<String, dynamic> map) {
    return InvoiceModel(
      id: map['id'] ?? '',
      invoiceType: map['invoice_type'] ?? 'SALES',
      invoiceNumber: map['invoice_number'] ?? '',
      invoiceDate: DateTime.parse(map['invoice_date'].toString()),
      dueDate: map['due_date'] != null
          ? DateTime.tryParse(map['due_date'].toString())
          : null,
      partyId: map['party_id'] ?? '',
      warehouseId: map['warehouse_id'] ?? '',
      currency: map['currency'] ?? 'SAR',
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      taxRate: (map['tax_rate'] as num?)?.toDouble() ?? 15.0,
      taxAmount: (map['tax_amount'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (map['grand_total'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'DRAFT',
      journalEntryId: map['journal_entry_id'],
      notes: map['notes'],
    );
  }
}

class SalesRepository {
  SalesRepository._();
  static final SalesRepository instance = SalesRepository._();

  /// Şirketin satış siparişlerini listeler
  Future<List<SalesOrderModel>> getSalesOrders(String companyId) async {
    try {
      final res = await SupabaseService.client
          .from('sales_orders')
          .select()
          .eq('company_id', companyId)
          .order('order_date', ascending: false);

      return (res as List<dynamic>)
          .map((m) => SalesOrderModel.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Şirketin satış faturalarını listeler
  Future<List<InvoiceModel>> getSalesInvoices(String companyId) async {
    try {
      final res = await SupabaseService.client
          .from('invoices')
          .select()
          .eq('company_id', companyId)
          .eq('invoice_type', 'SALES')
          .order('invoice_date', ascending: false);

      return (res as List<dynamic>)
          .map((m) => InvoiceModel.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// ATOMİK SATIŞ FATURASI OLUŞTURMA VE ONAYLAMA (RPC)
  /// INVOICE -> STOCK DEDUCTION -> JOURNAL ENTRY tek transaction
  Future<Map<String, dynamic>> createSalesInvoiceAtomic({
    required String companyId,
    required String invoiceNumber,
    required DateTime invoiceDate,
    required String currency,
    required String customerName,
    String? customerId,
    String? itemId,
    String? itemName,
    String? lotId,
    String? warehouseId,
    required double quantity,
    required String unit,
    required double unitPrice,
    required double subtotal,
    required double vatRate,
    required double vatAmount,
    required double grandTotal,
    bool isOfficialPosted = true,
    String? notes,
  }) async {
    final tenantId = TenantContext.instance.activeTenantId;
    if (tenantId == null) throw Exception('Aktif tenant seçilmedi.');

    final res = await SupabaseService.client.rpc(
      'create_sales_invoice_atomic',
      params: {
        'p_tenant_id': tenantId,
        'p_company_id': companyId,
        'p_invoice_number': invoiceNumber,
        'p_invoice_date': invoiceDate.toIso8601String().substring(0, 10),
        'p_currency': currency,
        'p_customer_name': customerName,
        'p_customer_id': customerId,
        'p_item_id': itemId,
        'p_item_name': itemName,
        'p_lot_id': lotId,
        'p_warehouse_id': warehouseId,
        'p_quantity': quantity,
        'p_unit': unit,
        'p_unit_price': unitPrice,
        'p_subtotal': subtotal,
        'p_vat_rate': vatRate,
        'p_vat_amount': vatAmount,
        'p_grand_total': grandTotal,
        'p_is_official_posted': isOfficialPosted,
        'p_notes': notes,
      },
    );

    return Map<String, dynamic>.from(res as Map);
  }
}
