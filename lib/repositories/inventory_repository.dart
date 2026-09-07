import '../services/supabase_service.dart';
import '../core/tenant/tenant_context.dart';

/// Ürün Master Kartı Modeli (Product Master)
class StockItem {
  final String id;
  final String itemCode;
  final String? sku;
  final String? barcode;
  final String itemName;
  final String categoryName;
  final String? categoryId;
  final String baseUnit;
  final String? salesUom;
  final String? purchaseUom;
  final String
      productType; // FINISHED_GOOD, RAW_MATERIAL, PACKAGING, INTERMEDIATE
  final bool traceabilityRequired;
  final bool lotRequired;
  final bool halalRequired;
  final bool qualityRequired;
  final double minStockLevel;
  final String? description;

  const StockItem({
    required this.id,
    required this.itemCode,
    this.sku,
    this.barcode,
    required this.itemName,
    required this.categoryName,
    this.categoryId,
    required this.baseUnit,
    this.salesUom,
    this.purchaseUom,
    this.productType = 'FINISHED_GOOD',
    this.traceabilityRequired = true,
    this.lotRequired = true,
    this.halalRequired = true,
    this.qualityRequired = true,
    required this.minStockLevel,
    this.description,
  });

  factory StockItem.fromMap(Map<String, dynamic> map) {
    return StockItem(
      id: map['id'] ?? '',
      itemCode: map['item_code'] ?? '',
      sku: map['sku'],
      barcode: map['barcode'],
      itemName: map['item_name'] ?? map['name'] ?? '',
      categoryName: map['category_name'] ?? map['category'] ?? 'Hurma',
      categoryId: map['category_id'],
      baseUnit:
          map['base_unit'] ?? map['birim'] ?? map['unit_of_measure'] ?? 'Kg',
      salesUom: map['sales_uom'],
      purchaseUom: map['purchase_uom'],
      productType: map['product_type'] ?? 'FINISHED_GOOD',
      traceabilityRequired: map['traceability_required'] ?? true,
      lotRequired: map['lot_required'] ?? true,
      halalRequired: map['halal_required'] ?? true,
      qualityRequired: map['quality_required'] ?? true,
      minStockLevel: (map['min_stock_level'] as num?)?.toDouble() ?? 0.0,
      description: map['description'],
    );
  }

  Map<String, dynamic> toMap(String tenantId, String companyId) {
    return {
      'tenant_id': tenantId,
      'company_id': companyId,
      'item_code': itemCode,
      if (sku != null) 'sku': sku,
      if (barcode != null) 'barcode': barcode,
      'item_name': itemName,
      'category_name': categoryName,
      if (categoryId != null) 'category_id': categoryId,
      'base_unit': baseUnit,
      if (salesUom != null) 'sales_uom': salesUom,
      if (purchaseUom != null) 'purchase_uom': purchaseUom,
      'product_type': productType,
      'traceability_required': traceabilityRequired,
      'lot_required': lotRequired,
      'halal_required': halalRequired,
      'quality_required': qualityRequired,
      'min_stock_level': minStockLevel,
      if (description != null) 'description': description,
    };
  }
}

/// Parti / Lot İzlenebilirlik Modeli
class ItemLotModel {
  final String id;
  final String itemId;
  final String lotNumber;
  final String? farmName;
  final DateTime? harvestDate;
  final String? harvestBatchNumber;
  final String? supplierPartyId;
  final String? processingFacility;
  final DateTime? processingDate;
  final DateTime? packagingDate;
  final String packagingType;
  final bool temperatureControlRequired;
  final double targetStorageTempCelsius;
  final String countryOfOrigin;
  final DateTime? productionDate;
  final DateTime? expirationDate;
  final bool halalCertified;
  final String? halalCertificateNumber;
  final String qualityStatus; // APPROVED, QUARANTINE, REJECTED, HOLD
  final String? notes;

  const ItemLotModel({
    required this.id,
    required this.itemId,
    required this.lotNumber,
    this.farmName,
    this.harvestDate,
    this.harvestBatchNumber,
    this.supplierPartyId,
    this.processingFacility,
    this.processingDate,
    this.packagingDate,
    this.packagingType = 'BOX',
    this.temperatureControlRequired = true,
    this.targetStorageTempCelsius = -18.0,
    this.countryOfOrigin = 'SA',
    this.productionDate,
    this.expirationDate,
    this.halalCertified = true,
    this.halalCertificateNumber,
    this.qualityStatus = 'APPROVED',
    this.notes,
  });

  factory ItemLotModel.fromMap(Map<String, dynamic> map) {
    return ItemLotModel(
      id: map['id'] ?? '',
      itemId: map['item_id'] ?? '',
      lotNumber: map['lot_number'] ?? '',
      farmName: map['farm_name'],
      harvestDate: map['harvest_date'] != null
          ? DateTime.tryParse(map['harvest_date'].toString())
          : null,
      harvestBatchNumber: map['harvest_batch_number'],
      supplierPartyId: map['supplier_party_id'],
      processingFacility: map['processing_facility'],
      processingDate: map['processing_date'] != null
          ? DateTime.tryParse(map['processing_date'].toString())
          : null,
      packagingDate: map['packaging_date'] != null
          ? DateTime.tryParse(map['packaging_date'].toString())
          : null,
      packagingType: map['packaging_type'] ?? 'BOX',
      temperatureControlRequired: map['temperature_control_required'] ?? true,
      targetStorageTempCelsius:
          (map['target_storage_temp_celsius'] as num?)?.toDouble() ?? -18.0,
      countryOfOrigin: map['country_of_origin'] ?? 'SA',
      productionDate: map['production_date'] != null
          ? DateTime.tryParse(map['production_date'].toString())
          : null,
      expirationDate: map['expiration_date'] != null
          ? DateTime.tryParse(map['expiration_date'].toString())
          : null,
      halalCertified: map['halal_certified'] ?? true,
      halalCertificateNumber: map['halal_certificate_number'],
      qualityStatus: map['quality_status'] ?? 'APPROVED',
      notes: map['notes'],
    );
  }
}

/// Standart Stok Hareket Türleri
class StockMovementTypes {
  static const String purchase = 'PURCHASE';
  static const String receipt = 'RECEIPT';
  static const String transfer = 'TRANSFER';
  static const String sale = 'SALE';
  static const String consumption = 'CONSUMPTION';
  static const String production = 'PRODUCTION';
  static const String waste = 'WASTE';
  static const String adjustment = 'ADJUSTMENT';
  static const String returnStock = 'RETURN';

  // Geriye dönük uyumluluk takma adları
  static const String purchaseReceipt = 'PURCHASE_RECEIPT';
  static const String salesIssue = 'SALES_ISSUE';
  static const String transferIn = 'TRANSFER_IN';
  static const String transferOut = 'TRANSFER_OUT';
}

class InventoryRepository {
  InventoryRepository._();
  static final InventoryRepository instance = InventoryRepository._();

  /// Şirkete ait stok kartlarını listeler
  Future<List<StockItem>> getItems(String companyId) async {
    try {
      final response = await SupabaseService.client
          .from('items')
          .select()
          .eq('company_id', companyId)
          .eq('is_active', true)
          .order('item_code', ascending: true);

      return (response as List<dynamic>)
          .map((m) => StockItem.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Ürün kartını SKU veya barkod ile arar
  Future<StockItem?> getItemBySkuOrBarcode({
    required String companyId,
    String? sku,
    String? barcode,
  }) async {
    try {
      var query = SupabaseService.client
          .from('items')
          .select()
          .eq('company_id', companyId);

      if (sku != null && sku.isNotEmpty) {
        query = query.eq('sku', sku);
      } else if (barcode != null && barcode.isNotEmpty) {
        query = query.eq('barcode', barcode);
      } else {
        return null;
      }

      final res = await query.maybeSingle();
      if (res == null) return null;
      return StockItem.fromMap(res);
    } catch (e) {
      return null;
    }
  }

  /// Stok hareket defterine giriş/çıkış hareketi kaydeder (Append-Only)
  Future<String?> recordStockMovement({
    required String companyId,
    required String warehouseId,
    required String itemId,
    String? lotId,
    String? locationId,
    required String
        movementType, // PURCHASE, RECEIPT, TRANSFER, SALE, CONSUMPTION, PRODUCTION, WASTE, ADJUSTMENT, RETURN
    required double quantity, // Pozitif: Giriş, Negatif: Çıkış
    required String unit,
    required double unitCost,
    required String documentType,
    required String documentReference,
    String? description,
    String? createdBy,
  }) async {
    try {
      final tenantId = TenantContext.instance.activeTenantId;
      if (tenantId == null) throw Exception('Aktif tenant seçilmedi.');

      final totalCost = (quantity * unitCost).abs();
      final direction = quantity >= 0 ? 'IN' : 'OUT';

      final res = await SupabaseService.client
          .from('stock_ledger_entries')
          .insert({
            'tenant_id': tenantId,
            'company_id': companyId,
            'warehouse_id': warehouseId,
            'location_id': locationId,
            'item_id': itemId,
            'lot_id': lotId,
            'movement_type': movementType,
            'quantity': quantity,
            'direction': direction,
            'unit': unit,
            'unit_cost': unitCost,
            'total_cost': totalCost,
            'document_type': documentType,
            'document_reference': documentReference,
            'description': description,
            if (createdBy != null) 'created_by': createdBy,
          })
          .select('id')
          .single();

      return res['id'] as String;
    } catch (e) {
      rethrow;
    }
  }

  /// Satın alma kabul hareketi (PURCHASE / RECEIPT)
  Future<String?> recordPurchaseReceipt({
    required String companyId,
    required String warehouseId,
    required String itemId,
    String? lotId,
    required double quantity,
    required String unit,
    required double unitCost,
    required String documentReference,
    String? description,
  }) async {
    return recordStockMovement(
      companyId: companyId,
      warehouseId: warehouseId,
      itemId: itemId,
      lotId: lotId,
      movementType: StockMovementTypes.purchase,
      quantity: quantity.abs(), // Giriş daima pozitiftir
      unit: unit,
      unitCost: unitCost,
      documentType: 'PURCHASE_ORDER',
      documentReference: documentReference,
      description: description ?? 'Satın Alma Depo Girişi: $documentReference',
    );
  }

  /// Satış faturası onaylandığında stok hareket defterine otomatik çıkış (SALE) yazar
  Future<String?> recordSalesIssue({
    required String companyId,
    required String warehouseId,
    required String itemId,
    String? lotId,
    required double miktar,
    required String birim,
    required double birimMaliyet,
    required String faturaNo,
  }) async {
    return recordStockMovement(
      companyId: companyId,
      warehouseId: warehouseId,
      itemId: itemId,
      lotId: lotId,
      movementType: StockMovementTypes.sale,
      quantity: -miktar.abs(), // Satış çıkışı olduğu için daima negatiftir
      unit: birim,
      unitCost: birimMaliyet,
      documentType: 'INVOICE',
      documentReference: faturaNo,
      description: 'Satış Faturası Depo Çıkışı: $faturaNo',
    );
  }

  /// Depolar arası transfer hareketi (Kaynak depodan - miktar, hedef depoya + miktar)
  Future<Map<String, String?>> recordStockTransfer({
    required String companyId,
    required String sourceWarehouseId,
    required String targetWarehouseId,
    required String itemId,
    String? lotId,
    required double quantity,
    required String unit,
    required double unitCost,
    required String transferDocumentRef,
  }) async {
    final transferQty = quantity.abs();

    // 1. Kaynak depodan çıkış (-quantity)
    final outId = await recordStockMovement(
      companyId: companyId,
      warehouseId: sourceWarehouseId,
      itemId: itemId,
      lotId: lotId,
      movementType: StockMovementTypes.transfer,
      quantity: -transferQty,
      unit: unit,
      unitCost: unitCost,
      documentType: 'TRANSFER_ORDER',
      documentReference: transferDocumentRef,
      description: 'Depo Transfer Çıkışı -> Hedef: $targetWarehouseId',
    );

    // 2. Hedef depoya giriş (+quantity)
    final inId = await recordStockMovement(
      companyId: companyId,
      warehouseId: targetWarehouseId,
      itemId: itemId,
      lotId: lotId,
      movementType: StockMovementTypes.transfer,
      quantity: transferQty,
      unit: unit,
      unitCost: unitCost,
      documentType: 'TRANSFER_ORDER',
      documentReference: transferDocumentRef,
      description: 'Depo Transfer Girişi <- Kaynak: $sourceWarehouseId',
    );

    return {'transfer_out_id': outId, 'transfer_in_id': inId};
  }

  /// Müşteri iade veya tedarikçi iade hareketi (RETURN)
  Future<String?> recordReturn({
    required String companyId,
    required String warehouseId,
    required String itemId,
    String? lotId,
    required double
        quantity, // Pozitif: Müşteri İadesi (giriş), Negatif: Tedarikçiye İade (çıkış)
    required String unit,
    required double unitCost,
    required String returnDocRef,
    String? description,
  }) async {
    return recordStockMovement(
      companyId: companyId,
      warehouseId: warehouseId,
      itemId: itemId,
      lotId: lotId,
      movementType: StockMovementTypes.returnStock,
      quantity: quantity,
      unit: unit,
      unitCost: unitCost,
      documentType: 'RETURN_ORDER',
      documentReference: returnDocRef,
      description: description ?? 'İade Hareketi: $returnDocRef',
    );
  }

  /// Depo bazında anlık stok bakiyesini sorgular (View üzerinden)
  Future<List<Map<String, dynamic>>> getCurrentStockBalances(
      String warehouseId) async {
    try {
      final response = await SupabaseService.client
          .from('view_current_stock')
          .select()
          .eq('warehouse_id', warehouseId);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      return [];
    }
  }

  /// Ürünün mevcut depo bakiyesini döner
  Future<double> getItemCurrentBalance({
    required String warehouseId,
    required String itemId,
    String? lotId,
  }) async {
    try {
      var query = SupabaseService.client
          .from('view_current_stock')
          .select('current_quantity')
          .eq('warehouse_id', warehouseId)
          .eq('item_id', itemId);

      if (lotId != null) {
        query = query.eq('lot_id', lotId);
      }

      final res = await query;
      if ((res as List).isEmpty) return 0.0;

      double total = 0.0;
      for (final row in res) {
        total += (row['current_quantity'] as num?)?.toDouble() ?? 0.0;
      }
      return total;
    } catch (e) {
      return 0.0;
    }
  }

  /// Ürüne ait partileri/lotları listeler
  Future<List<ItemLotModel>> getItemLots(String itemId) async {
    try {
      final response = await SupabaseService.client
          .from('item_lots')
          .select()
          .eq('item_id', itemId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((m) => ItemLotModel.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
