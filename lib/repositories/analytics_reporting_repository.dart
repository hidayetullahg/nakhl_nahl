import '../services/supabase_service.dart';
import '../core/tenant/tenant_context.dart';

export '../services/raporlama_servisi.dart';

/// 13 Enterprise Rapor Türü
enum EnterpriseReportType {
  sales,
  purchase,
  inventory,
  stockMovement,
  lotTraceability,
  customer,
  supplier,
  accounting,
  cashFinance,
  exportTrade,
  shipment,
  quality,
  halal,
}

// ==============================================================================
// MODELLER (13 Boyut)
// ==============================================================================

class SalesReportRow {
  final String companyId;
  final String companyName;
  final String invoiceNumber;
  final DateTime invoiceDate;
  final String customerName;
  final String? customerCountry;
  final String currency;
  final double netSales;
  final double taxSales;
  final double grossSales;
  final String status;

  const SalesReportRow({
    required this.companyId,
    required this.companyName,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.customerName,
    this.customerCountry,
    required this.currency,
    required this.netSales,
    required this.taxSales,
    required this.grossSales,
    required this.status,
  });

  factory SalesReportRow.fromJson(Map<String, dynamic> json) {
    return SalesReportRow(
      companyId: json['company_id'] as String,
      companyName: json['company_name'] as String? ?? '',
      invoiceNumber: json['invoice_number'] as String? ?? '',
      invoiceDate: DateTime.parse(json['invoice_date'] as String),
      customerName: json['customer_name'] as String? ?? 'Genel Müşteri',
      customerCountry: json['customer_country'] as String?,
      currency: json['currency'] as String? ?? 'SAR',
      netSales: (json['net_sales'] as num?)?.toDouble() ?? 0.0,
      taxSales: (json['tax_sales'] as num?)?.toDouble() ?? 0.0,
      grossSales: (json['gross_sales'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'DRAFT',
    );
  }
}

class PurchaseReportRow {
  final String companyId;
  final String companyName;
  final String invoiceNumber;
  final DateTime invoiceDate;
  final String supplierName;
  final String? supplierCountry;
  final String currency;
  final double netPurchase;
  final double taxPurchase;
  final double grossPurchase;
  final String status;

  const PurchaseReportRow({
    required this.companyId,
    required this.companyName,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.supplierName,
    this.supplierCountry,
    required this.currency,
    required this.netPurchase,
    required this.taxPurchase,
    required this.grossPurchase,
    required this.status,
  });

  factory PurchaseReportRow.fromJson(Map<String, dynamic> json) {
    return PurchaseReportRow(
      companyId: json['company_id'] as String,
      companyName: json['company_name'] as String? ?? '',
      invoiceNumber: json['invoice_number'] as String? ?? '',
      invoiceDate: DateTime.parse(json['invoice_date'] as String),
      supplierName: json['supplier_name'] as String? ?? 'Genel Tedarikçi',
      supplierCountry: json['supplier_country'] as String?,
      currency: json['currency'] as String? ?? 'SAR',
      netPurchase: (json['net_purchase'] as num?)?.toDouble() ?? 0.0,
      taxPurchase: (json['tax_purchase'] as num?)?.toDouble() ?? 0.0,
      grossPurchase: (json['gross_purchase'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'DRAFT',
    );
  }
}

class InventoryReportRow {
  final String companyId;
  final String companyName;
  final String warehouseName;
  final String warehouseCode;
  final String itemSku;
  final String itemName;
  final String unitOfMeasure;
  final double currentQuantity;
  final double estimatedValuationSar;

  const InventoryReportRow({
    required this.companyId,
    required this.companyName,
    required this.warehouseName,
    required this.warehouseCode,
    required this.itemSku,
    required this.itemName,
    required this.unitOfMeasure,
    required this.currentQuantity,
    required this.estimatedValuationSar,
  });

  factory InventoryReportRow.fromJson(Map<String, dynamic> json) {
    return InventoryReportRow(
      companyId: json['company_id'] as String,
      companyName: json['company_name'] as String? ?? '',
      warehouseName: json['warehouse_name'] as String? ?? '',
      warehouseCode: json['warehouse_code'] as String? ?? '',
      itemSku: json['item_sku'] as String? ?? '',
      itemName: json['item_name'] as String? ?? '',
      unitOfMeasure: json['unit_of_measure'] as String? ?? 'Kg',
      currentQuantity: (json['current_quantity'] as num?)?.toDouble() ?? 0.0,
      estimatedValuationSar:
          (json['estimated_valuation_sar'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class StockMovementReportRow {
  final String companyId;
  final String companyName;
  final String movementType;
  final String direction;
  final String warehouseName;
  final String itemSku;
  final String itemName;
  final double quantity;
  final double totalCost;
  final DateTime movementTimestamp;

  const StockMovementReportRow({
    required this.companyId,
    required this.companyName,
    required this.movementType,
    required this.direction,
    required this.warehouseName,
    required this.itemSku,
    required this.itemName,
    required this.quantity,
    required this.totalCost,
    required this.movementTimestamp,
  });

  factory StockMovementReportRow.fromJson(Map<String, dynamic> json) {
    return StockMovementReportRow(
      companyId: json['company_id'] as String,
      companyName: json['company_name'] as String? ?? '',
      movementType: json['movement_type'] as String? ?? '',
      direction: json['direction'] as String? ?? 'IN',
      warehouseName: json['warehouse_name'] as String? ?? '',
      itemSku: json['item_sku'] as String? ?? '',
      itemName: json['item_name'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      totalCost: (json['total_cost'] as num?)?.toDouble() ?? 0.0,
      movementTimestamp: DateTime.parse(json['movement_timestamp'] as String),
    );
  }
}

class LotTraceabilityReportRow {
  final String companyId;
  final String companyName;
  final String lotNumber;
  final String itemName;
  final DateTime? harvestDate;
  final DateTime? expiryDate;
  final String lotStatus;
  final String latestQualityResult;
  final String halalComplianceStatus;

  const LotTraceabilityReportRow({
    required this.companyId,
    required this.companyName,
    required this.lotNumber,
    required this.itemName,
    this.harvestDate,
    this.expiryDate,
    required this.lotStatus,
    required this.latestQualityResult,
    required this.halalComplianceStatus,
  });

  factory LotTraceabilityReportRow.fromJson(Map<String, dynamic> json) {
    return LotTraceabilityReportRow(
      companyId: json['company_id'] as String,
      companyName: json['company_name'] as String? ?? '',
      lotNumber: json['lot_number'] as String? ?? '',
      itemName: json['item_name'] as String? ?? '',
      harvestDate: json['harvest_date'] != null
          ? DateTime.parse(json['harvest_date'] as String)
          : null,
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'] as String)
          : null,
      lotStatus: json['lot_status'] as String? ?? 'ACTIVE',
      latestQualityResult:
          json['latest_quality_result'] as String? ?? 'NOT_INSPECTED',
      halalComplianceStatus:
          json['halal_compliance_status'] as String? ?? 'PENDING_AUDIT',
    );
  }
}

class QualityReportRow {
  final String companyId;
  final String companyName;
  final String inspectionType;
  final int totalInspections;
  final int passCount;
  final int failCount;
  final int conditionalCount;
  final int quarantineCount;
  final double passPercentage;

  const QualityReportRow({
    required this.companyId,
    required this.companyName,
    required this.inspectionType,
    required this.totalInspections,
    required this.passCount,
    required this.failCount,
    required this.conditionalCount,
    required this.quarantineCount,
    required this.passPercentage,
  });

  factory QualityReportRow.fromJson(Map<String, dynamic> json) {
    return QualityReportRow(
      companyId: json['company_id'] as String,
      companyName: json['company_name'] as String? ?? '',
      inspectionType: json['inspection_type'] as String? ?? '',
      totalInspections: (json['total_inspections'] as num?)?.toInt() ?? 0,
      passCount: (json['pass_count'] as num?)?.toInt() ?? 0,
      failCount: (json['fail_count'] as num?)?.toInt() ?? 0,
      conditionalCount: (json['conditional_count'] as num?)?.toInt() ?? 0,
      quarantineCount: (json['quarantine_count'] as num?)?.toInt() ?? 0,
      passPercentage: (json['pass_percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class HalalReportRow {
  final String companyId;
  final String companyName;
  final String certificationBody;
  final int totalCertificatesCount;
  final int validCertificatesCount;
  final int expiredOrInvalidCount;
  final int certifiedLotsCount;

  const HalalReportRow({
    required this.companyId,
    required this.companyName,
    required this.certificationBody,
    required this.totalCertificatesCount,
    required this.validCertificatesCount,
    required this.expiredOrInvalidCount,
    required this.certifiedLotsCount,
  });

  factory HalalReportRow.fromJson(Map<String, dynamic> json) {
    return HalalReportRow(
      companyId: json['company_id'] as String,
      companyName: json['company_name'] as String? ?? '',
      certificationBody: json['certification_body'] as String? ?? '',
      totalCertificatesCount:
          (json['total_certificates_count'] as num?)?.toInt() ?? 0,
      validCertificatesCount:
          (json['valid_certificates_count'] as num?)?.toInt() ?? 0,
      expiredOrInvalidCount:
          (json['expired_or_invalid_count'] as num?)?.toInt() ?? 0,
      certifiedLotsCount: (json['certified_lots_count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// N+1 Sorguları Önleyen Yönetici Özeti Modeli
class ExecutiveDashboardSummary {
  final DateTime generatedAt;
  final String companyId;
  final String tenantId;
  final Map<String, dynamic> salesSummary;
  final Map<String, dynamic> purchaseSummary;
  final Map<String, dynamic> inventorySummary;
  final Map<String, dynamic> qualitySummary;
  final Map<String, dynamic> halalSummary;
  final Map<String, dynamic> tradeAndLogisticsSummary;
  final Map<String, dynamic> financeSummary;

  const ExecutiveDashboardSummary({
    required this.generatedAt,
    required this.companyId,
    required this.tenantId,
    required this.salesSummary,
    required this.purchaseSummary,
    required this.inventorySummary,
    required this.qualitySummary,
    required this.halalSummary,
    required this.tradeAndLogisticsSummary,
    required this.financeSummary,
  });

  factory ExecutiveDashboardSummary.fromJson(Map<String, dynamic> json) {
    return ExecutiveDashboardSummary(
      generatedAt: DateTime.tryParse(json['generated_at'] as String? ?? '') ??
          DateTime.now(),
      companyId: json['company_id'] as String? ?? '',
      tenantId: json['tenant_id'] as String? ?? '',
      salesSummary: json['sales_summary'] as Map<String, dynamic>? ?? {},
      purchaseSummary: json['purchase_summary'] as Map<String, dynamic>? ?? {},
      inventorySummary:
          json['inventory_summary'] as Map<String, dynamic>? ?? {},
      qualitySummary: json['quality_summary'] as Map<String, dynamic>? ?? {},
      halalSummary: json['halal_summary'] as Map<String, dynamic>? ?? {},
      tradeAndLogisticsSummary:
          json['trade_and_logistics_summary'] as Map<String, dynamic>? ?? {},
      financeSummary: json['finance_summary'] as Map<String, dynamic>? ?? {},
    );
  }
}

// ==============================================================================
// REPOSITORY (Reporting & Analytics Servisi)
// ==============================================================================

class AnalyticsReportingRepository {
  AnalyticsReportingRepository._();
  static final AnalyticsReportingRepository instance =
      AnalyticsReportingRepository._();

  /// 1. Satış Raporu (Sales)
  Future<List<SalesReportRow>> getSalesReport(
    String companyId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      var query = SupabaseService.client
          .from('view_report_sales')
          .select()
          .eq('company_id', companyId);

      if (startDate != null) {
        query = query.gte(
            'invoice_date', startDate.toIso8601String().substring(0, 10));
      }
      if (endDate != null) {
        query = query.lte(
            'invoice_date', endDate.toIso8601String().substring(0, 10));
      }

      final res = await query
          .order('invoice_date', ascending: false)
          .range(offset, offset + limit - 1);

      return (res as List<dynamic>)
          .map((e) => SalesReportRow.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 2. Satın Alma Raporu (Purchase)
  Future<List<PurchaseReportRow>> getPurchaseReport(
    String companyId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      var query = SupabaseService.client
          .from('view_report_purchase')
          .select()
          .eq('company_id', companyId);

      if (startDate != null) {
        query = query.gte(
            'invoice_date', startDate.toIso8601String().substring(0, 10));
      }
      if (endDate != null) {
        query = query.lte(
            'invoice_date', endDate.toIso8601String().substring(0, 10));
      }

      final res = await query
          .order('invoice_date', ascending: false)
          .range(offset, offset + limit - 1);

      return (res as List<dynamic>)
          .map((e) => PurchaseReportRow.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 3. Envanter Bakiye ve Değerleme Raporu (Inventory)
  Future<List<InventoryReportRow>> getInventoryReport(
    String companyId, {
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final res = await SupabaseService.client
          .from('view_report_inventory')
          .select()
          .eq('company_id', companyId)
          .order('estimated_valuation_sar', ascending: false)
          .range(offset, offset + limit - 1);

      return (res as List<dynamic>)
          .map((e) => InventoryReportRow.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 4. Stok Hareketleri Raporu (Stock Movement)
  Future<List<StockMovementReportRow>> getStockMovementReport(
    String companyId, {
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final res = await SupabaseService.client
          .from('view_report_stock_movement')
          .select()
          .eq('company_id', companyId)
          .order('movement_timestamp', ascending: false)
          .range(offset, offset + limit - 1);

      return (res as List<dynamic>)
          .map(
              (e) => StockMovementReportRow.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 5. Lot İzlenebilirlik Raporu (Lot Traceability)
  Future<List<LotTraceabilityReportRow>> getLotTraceabilityReport(
    String companyId, {
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final res = await SupabaseService.client
          .from('view_report_lot_traceability')
          .select()
          .eq('company_id', companyId)
          .range(offset, offset + limit - 1);

      return (res as List<dynamic>)
          .map((e) =>
              LotTraceabilityReportRow.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 6. Kalite Kontrol Raporu (Quality)
  Future<List<QualityReportRow>> getQualityReport(String companyId) async {
    try {
      final res = await SupabaseService.client
          .from('view_report_quality')
          .select()
          .eq('company_id', companyId);

      return (res as List<dynamic>)
          .map((e) => QualityReportRow.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 7. Helal Uygunluk Raporu (Halal)
  Future<List<HalalReportRow>> getHalalReport(String companyId) async {
    try {
      final res = await SupabaseService.client
          .from('view_report_halal')
          .select()
          .eq('company_id', companyId);

      return (res as List<dynamic>)
          .map((e) => HalalReportRow.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// N+1 Sorgusuz Yönetici Dashboard Özeti (Executive Dashboard Summary RPC)
  Future<ExecutiveDashboardSummary?> getExecutiveDashboardSummary({
    required String companyId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final tenantId = TenantContext.instance.activeTenantId;
    if (tenantId == null) return null;

    try {
      final res = await SupabaseService.client
          .rpc('get_executive_dashboard_summary', params: {
        'p_tenant_id': tenantId,
        'p_company_id': companyId,
        if (startDate != null)
          'p_start_date': startDate.toIso8601String().substring(0, 10),
        if (endDate != null)
          'p_end_date': endDate.toIso8601String().substring(0, 10),
      });

      if (res is Map<String, dynamic>) {
        return ExecutiveDashboardSummary.fromJson(res);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
