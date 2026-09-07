import '../services/supabase_service.dart';
import '../core/tenant/tenant_context.dart';
import 'sales_repository.dart';

/// Satın Alma Siparişi Modeli
class PurchaseOrderModel {
  final String id;
  final String orderNumber;
  final DateTime orderDate;
  final DateTime? expectedDeliveryDate;
  final String supplierId;
  final String warehouseId;
  final String currency;
  final double subtotal;
  final double taxAmount;
  final double grandTotal;
  final int paymentTermsDays;
  final String
      status; // DRAFT, APPROVED, PARTIALLY_RECEIVED, COMPLETED, CANCELLED
  final String? notes;

  const PurchaseOrderModel({
    required this.id,
    required this.orderNumber,
    required this.orderDate,
    this.expectedDeliveryDate,
    required this.supplierId,
    required this.warehouseId,
    required this.currency,
    required this.subtotal,
    required this.taxAmount,
    required this.grandTotal,
    required this.paymentTermsDays,
    required this.status,
    this.notes,
  });

  factory PurchaseOrderModel.fromMap(Map<String, dynamic> map) {
    return PurchaseOrderModel(
      id: map['id'] ?? '',
      orderNumber: map['order_number'] ?? '',
      orderDate: DateTime.parse(map['order_date'].toString()),
      expectedDeliveryDate: map['expected_delivery_date'] != null
          ? DateTime.tryParse(map['expected_delivery_date'].toString())
          : null,
      supplierId: map['supplier_id'] ?? '',
      warehouseId: map['warehouse_id'] ?? '',
      currency: map['currency'] ?? 'SAR',
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (map['tax_amount'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (map['grand_total'] as num?)?.toDouble() ?? 0.0,
      paymentTermsDays: map['payment_terms_days'] ?? 30,
      status: map['status'] ?? 'DRAFT',
      notes: map['notes'],
    );
  }
}

class PurchaseRepository {
  PurchaseRepository._();
  static final PurchaseRepository instance = PurchaseRepository._();

  /// Şirketin satın alma siparişlerini listeler
  Future<List<PurchaseOrderModel>> getPurchaseOrders(String companyId) async {
    try {
      final res = await SupabaseService.client
          .from('purchase_orders')
          .select()
          .eq('company_id', companyId)
          .order('order_date', ascending: false);

      return (res as List<dynamic>)
          .map((m) => PurchaseOrderModel.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Şirketin alış faturalarını listeler
  Future<List<InvoiceModel>> getPurchaseInvoices(String companyId) async {
    try {
      final res = await SupabaseService.client
          .from('invoices')
          .select()
          .eq('company_id', companyId)
          .eq('invoice_type', 'PURCHASE')
          .order('invoice_date', ascending: false);

      return (res as List<dynamic>)
          .map((m) => InvoiceModel.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// ATOMİK SATIN ALMA MAL KABUL RPC'Sİ (PURCHASE FLOW)
  /// SUPPLIER -> PO -> RECEIPT -> LOT -> STOCK -> JOURNAL tek transaction
  Future<Map<String, dynamic>> processPurchaseIntakeAtomic({
    required String companyId,
    required String supplierId,
    required String poNumber,
    required String invoiceNumber,
    required String warehouseId,
    required String itemId,
    required String lotNumber,
    required double quantity,
    required String uom,
    required double unitPrice,
    String currency = 'SAR',
    double taxRate = 15.0,
    String? farmName,
    DateTime? harvestDate,
    String? harvestBatchNumber,
    int paymentTermsDays = 30,
  }) async {
    final tenantId = TenantContext.instance.activeTenantId;
    if (tenantId == null) throw Exception('Aktif tenant seçilmedi.');

    final res = await SupabaseService.client.rpc(
      'process_purchase_intake_atomic',
      params: {
        'p_tenant_id': tenantId,
        'p_company_id': companyId,
        'p_supplier_id': supplierId,
        'p_po_number': poNumber,
        'p_invoice_number': invoiceNumber,
        'p_warehouse_id': warehouseId,
        'p_item_id': itemId,
        'p_lot_number': lotNumber,
        'p_quantity': quantity,
        'p_uom': uom,
        'p_unit_price': unitPrice,
        'p_currency': currency,
        'p_tax_rate': taxRate,
        'p_farm_name': farmName,
        'p_harvest_date':
            (harvestDate ?? DateTime.now()).toIso8601String().substring(0, 10),
        'p_harvest_batch_number': harvestBatchNumber,
        'p_payment_terms_days': paymentTermsDays,
      },
    );

    return Map<String, dynamic>.from(res as Map);
  }
}
