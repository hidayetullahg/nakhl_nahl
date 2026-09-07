import '../services/supabase_service.dart';
import '../core/tenant/tenant_context.dart';

/// Fabrika İşleme ve Ambalajlama Veri Modeli
class FactoryProcessingModel {
  final String? id;
  final String lotId;
  final String factoryName;
  final DateTime cleaningDate;
  final String cleaningMethod;
  final DateTime sortingDate;
  final String sortingGrade;
  final double wasteQuantity;
  final String? wasteReason;
  final double wastePercentage;
  final String processingType;
  final DateTime processingDate;
  final DateTime packagingDate;
  final String packagingType;
  final String? packagingLine;
  final String shelfLocationCode;
  final String? notes;

  const FactoryProcessingModel({
    this.id,
    required this.lotId,
    required this.factoryName,
    required this.cleaningDate,
    required this.cleaningMethod,
    required this.sortingDate,
    required this.sortingGrade,
    required this.wasteQuantity,
    this.wasteReason,
    required this.wastePercentage,
    required this.processingType,
    required this.processingDate,
    required this.packagingDate,
    required this.packagingType,
    this.packagingLine,
    required this.shelfLocationCode,
    this.notes,
  });

  factory FactoryProcessingModel.fromJson(Map<String, dynamic> json) {
    return FactoryProcessingModel(
      id: json['id'] as String?,
      lotId: json['lot_id'] as String,
      factoryName: json['factory_name'] as String? ?? '',
      cleaningDate:
          DateTime.tryParse(json['cleaning_date']?.toString() ?? '') ??
              DateTime.now(),
      cleaningMethod: json['cleaning_method'] as String? ?? '',
      sortingDate: DateTime.tryParse(json['sorting_date']?.toString() ?? '') ??
          DateTime.now(),
      sortingGrade: json['sorting_grade'] as String? ?? '',
      wasteQuantity: (json['waste_quantity'] as num?)?.toDouble() ?? 0.0,
      wasteReason: json['waste_reason'] as String?,
      wastePercentage: (json['waste_percentage'] as num?)?.toDouble() ?? 0.0,
      processingType: json['processing_type'] as String? ?? '',
      processingDate:
          DateTime.tryParse(json['processing_date']?.toString() ?? '') ??
              DateTime.now(),
      packagingDate:
          DateTime.tryParse(json['packaging_date']?.toString() ?? '') ??
              DateTime.now(),
      packagingType: json['packaging_type'] as String? ?? '',
      packagingLine: json['packaging_line'] as String?,
      shelfLocationCode: json['shelf_location_code'] as String? ?? '',
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson(
      {required String tenantId, required String companyId}) {
    return {
      if (id != null) 'id': id,
      'tenant_id': tenantId,
      'company_id': companyId,
      'lot_id': lotId,
      'factory_name': factoryName,
      'cleaning_date': cleaningDate.toIso8601String().split('T')[0],
      'cleaning_method': cleaningMethod,
      'sorting_date': sortingDate.toIso8601String().split('T')[0],
      'sorting_grade': sortingGrade,
      'waste_quantity': wasteQuantity,
      'waste_reason': wasteReason,
      'waste_percentage': wastePercentage,
      'processing_type': processingType,
      'processing_date': processingDate.toIso8601String().split('T')[0],
      'packaging_date': packagingDate.toIso8601String().split('T')[0],
      'packaging_type': packagingType,
      'packaging_line': packagingLine,
      'shelf_location_code': shelfLocationCode,
      'notes': notes,
    };
  }
}

/// Lot İleriye Doğru İzlenebilirlik Modeli (SOURCE -> EXPORT)
class LotForwardTraceModel {
  final String lotNumber;
  final String itemId;
  final DateTime? expiryDate;
  final String status;
  final Map<String, dynamic> source;
  final Map<String, dynamic> processing;
  final List<Map<String, dynamic>> movement;
  final Map<String, dynamic> storage;
  final List<Map<String, dynamic>> sale;
  final List<Map<String, dynamic>> export;

  const LotForwardTraceModel({
    required this.lotNumber,
    required this.itemId,
    this.expiryDate,
    required this.status,
    required this.source,
    required this.processing,
    required this.movement,
    required this.storage,
    required this.sale,
    required this.export,
  });

  factory LotForwardTraceModel.fromJson(Map<String, dynamic> json) {
    return LotForwardTraceModel(
      lotNumber: json['lot_number']?.toString() ?? '',
      itemId: json['item_id']?.toString() ?? '',
      expiryDate: json['expiry_date'] != null
          ? DateTime.tryParse(json['expiry_date'].toString())
          : null,
      status: json['status']?.toString() ?? '',
      source: Map<String, dynamic>.from(json['source'] as Map? ?? {}),
      processing: Map<String, dynamic>.from(json['processing'] as Map? ?? {}),
      movement: (json['movement'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      storage: Map<String, dynamic>.from(json['storage'] as Map? ?? {}),
      sale: (json['sale'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      export: (json['export'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
    );
  }
}

/// Lot Acil Geri Çağırma & Karantina Analiz Modeli
class LotRecallAnalysisModel {
  final DateTime recallTimestamp;
  final String lotNumber;
  final String lotId;
  final String itemId;
  final List<Map<String, dynamic>> currentStockOnHand;
  final List<Map<String, dynamic>> affectedSales;
  final List<Map<String, dynamic>> affectedCustomers;
  final List<Map<String, dynamic>> affectedShipments;
  final List<Map<String, dynamic>> affectedContainers;

  const LotRecallAnalysisModel({
    required this.recallTimestamp,
    required this.lotNumber,
    required this.lotId,
    required this.itemId,
    required this.currentStockOnHand,
    required this.affectedSales,
    required this.affectedCustomers,
    required this.affectedShipments,
    required this.affectedContainers,
  });

  factory LotRecallAnalysisModel.fromJson(Map<String, dynamic> json) {
    return LotRecallAnalysisModel(
      recallTimestamp:
          DateTime.tryParse(json['recall_timestamp']?.toString() ?? '') ??
              DateTime.now(),
      lotNumber: json['lot_number']?.toString() ?? '',
      lotId: json['lot_id']?.toString() ?? '',
      itemId: json['item_id']?.toString() ?? '',
      currentStockOnHand: (json['current_stock_on_hand'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      affectedSales: (json['affected_sales'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      affectedCustomers: (json['affected_customers'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      affectedShipments: (json['affected_shipments'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      affectedContainers: (json['affected_containers'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
    );
  }

  /// Toplam geri çağrılması gereken müşteri sayısı
  int get affectedCustomerCount => affectedCustomers.length;

  /// Toplam sevk edilen veya satılan miktar
  double get totalSoldQuantity {
    double sum = 0.0;
    for (final sale in affectedSales) {
      sum += (sale['sold_quantity'] as num?)?.toDouble() ?? 0.0;
    }
    return sum;
  }
}

/// Müşteriden Çiftliğe Geriye Doğru İzleme Modeli
class ReverseTraceModel {
  final Map<String, dynamic> customer;
  final Map<String, dynamic> saleInvoice;
  final List<Map<String, dynamic>> tracedLots;

  const ReverseTraceModel({
    required this.customer,
    required this.saleInvoice,
    required this.tracedLots,
  });

  factory ReverseTraceModel.fromJson(Map<String, dynamic> json) {
    return ReverseTraceModel(
      customer: Map<String, dynamic>.from(json['customer'] as Map? ?? {}),
      saleInvoice:
          Map<String, dynamic>.from(json['sale_invoice'] as Map? ?? {}),
      tracedLots: (json['traced_lots'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
    );
  }
}

/// Uçtan Uca İzlenebilirlik ve Recall Repository Sınıfı
class TraceabilityRepository {
  TraceabilityRepository._();
  static final TraceabilityRepository instance = TraceabilityRepository._();

  String get _tenantId => TenantContext.instance.activeTenantId ?? '';
  String get _companyId => TenantContext.instance.activeCompanyId ?? '';

  /// 1. Forward Lot Trace (SOURCE -> PROCESSING -> MOVEMENT -> STORAGE -> SALE -> EXPORT)
  Future<LotForwardTraceModel> getForwardTrace(String lotNumber) async {
    final response = await SupabaseService.client.rpc(
      'get_lot_forward_trace',
      params: {
        'p_lot_number': lotNumber,
        'p_tenant_id': _tenantId,
      },
    );

    if (response == null) {
      throw Exception('Lot izlenebilirlik verisi bulunamadı: $lotNumber');
    }

    return LotForwardTraceModel.fromJson(
        Map<String, dynamic>.from(response as Map));
  }

  /// 2. Recall Analysis (LOT -> CURRENT STOCK -> SALES -> CUSTOMERS -> SHIPMENTS -> CONTAINERS)
  Future<LotRecallAnalysisModel> getRecallAnalysis(String lotNumber) async {
    final response = await SupabaseService.client.rpc(
      'get_lot_recall_analysis',
      params: {
        'p_lot_number': lotNumber,
        'p_tenant_id': _tenantId,
      },
    );

    if (response == null) {
      throw Exception('Lot geri çağırma analizi üretilemedi: $lotNumber');
    }

    return LotRecallAnalysisModel.fromJson(
        Map<String, dynamic>.from(response as Map));
  }

  /// 3. Reverse Trace (CUSTOMER -> SALE -> LOT -> PRODUCTION -> HARVEST -> FARM)
  Future<ReverseTraceModel> getReverseTrace({
    required String customerName,
    required String invoiceNumber,
  }) async {
    final response = await SupabaseService.client.rpc(
      'get_reverse_trace_from_customer',
      params: {
        'p_customer_name': customerName,
        'p_invoice_number': invoiceNumber,
        'p_tenant_id': _tenantId,
      },
    );

    if (response == null) {
      throw Exception(
          'Müşteriden geriye izlenebilirlik kaydı bulunamadı: $customerName - $invoiceNumber');
    }

    return ReverseTraceModel.fromJson(
        Map<String, dynamic>.from(response as Map));
  }

  /// 4. Fabrika İşleme ve Raf Bilgisi Kaydetme / Güncelleme
  Future<void> saveFactoryProcessing(FactoryProcessingModel processing) async {
    final data = processing.toJson(tenantId: _tenantId, companyId: _companyId);
    await SupabaseService.client
        .from('lot_factory_processings')
        .upsert(data, onConflict: 'lot_id');
  }

  /// 5. 22 Aşamalı Uçtan Uca Görünümden Veri Çekme
  Future<List<Map<String, dynamic>>> getTraceabilityView({
    String? lotNumber,
    int limit = 50,
  }) async {
    var query = SupabaseService.client
        .from('view_end_to_end_traceability')
        .select()
        .eq('tenant_id', _tenantId)
        .eq('company_id', _companyId);

    if (lotNumber != null && lotNumber.isNotEmpty) {
      query = query.eq('lot_number', lotNumber);
    }

    final response = await query.limit(limit);
    return List<Map<String, dynamic>>.from(response as List);
  }
}
