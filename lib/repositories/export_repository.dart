import '../services/supabase_service.dart';
import '../core/tenant/tenant_context.dart';
import 'inventory_repository.dart';
import 'halal_repository.dart';

class TradeShipment {
  final String id;
  final String shipmentNumber;
  final String transportMode;
  final String? vesselOrPlate;
  final String? customsDeclarationNo;
  final String? billOfLadingNo;
  final DateTime departureDate;
  final DateTime? estimatedArrivalDate;
  final DateTime? actualArrivalDate;
  final String status;

  const TradeShipment({
    required this.id,
    required this.shipmentNumber,
    required this.transportMode,
    this.vesselOrPlate,
    this.customsDeclarationNo,
    this.billOfLadingNo,
    required this.departureDate,
    this.estimatedArrivalDate,
    this.actualArrivalDate,
    required this.status,
  });

  factory TradeShipment.fromJson(Map<String, dynamic> json) {
    return TradeShipment(
      id: json['id'] as String,
      shipmentNumber: json['shipment_number'] as String? ?? '',
      transportMode: json['transport_mode'] as String? ?? 'SEA',
      vesselOrPlate: json['vessel_or_plate'] as String?,
      customsDeclarationNo: json['customs_declaration_no'] as String?,
      billOfLadingNo: json['bill_of_lading_no'] as String?,
      departureDate: DateTime.parse(json['departure_date'] as String),
      estimatedArrivalDate: json['estimated_arrival_date'] != null
          ? DateTime.parse(json['estimated_arrival_date'] as String)
          : null,
      actualArrivalDate: json['actual_arrival_date'] != null
          ? DateTime.parse(json['actual_arrival_date'] as String)
          : null,
      status: json['status'] as String? ?? 'PREPARING',
    );
  }
}

class ExportFileModel {
  final String id;
  final String exportNumber;
  final String customerPartyId;
  final String? salesOrderId;
  final String? invoiceId;
  final String originCountryCode;
  final String destinationCountryCode;
  final String originPort;
  final String destinationPort;
  final String incoterm;
  final String currencyCode;
  final double fobValue;
  final double freightValue;
  final double insuranceValue;
  final double cifValue;
  final String status;
  final String? notes;
  final DateTime createdAt;

  const ExportFileModel({
    required this.id,
    required this.exportNumber,
    required this.customerPartyId,
    this.salesOrderId,
    this.invoiceId,
    required this.originCountryCode,
    required this.destinationCountryCode,
    required this.originPort,
    required this.destinationPort,
    required this.incoterm,
    required this.currencyCode,
    required this.fobValue,
    required this.freightValue,
    required this.insuranceValue,
    required this.cifValue,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  factory ExportFileModel.fromJson(Map<String, dynamic> json) {
    return ExportFileModel(
      id: json['id'] as String,
      exportNumber: json['export_number'] as String? ?? '',
      customerPartyId: json['customer_party_id'] as String,
      salesOrderId: json['sales_order_id'] as String?,
      invoiceId: json['invoice_id'] as String?,
      originCountryCode: json['origin_country_code'] as String? ?? 'SA',
      destinationCountryCode:
          json['destination_country_code'] as String? ?? 'TR',
      originPort: json['origin_port'] as String? ?? '',
      destinationPort: json['destination_port'] as String? ?? '',
      incoterm: json['incoterm'] as String? ?? 'FOB',
      currencyCode: json['currency_code'] as String? ?? 'USD',
      fobValue: (json['fob_value'] as num?)?.toDouble() ?? 0.0,
      freightValue: (json['freight_value'] as num?)?.toDouble() ?? 0.0,
      insuranceValue: (json['insurance_value'] as num?)?.toDouble() ?? 0.0,
      cifValue: (json['cif_value'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'DRAFT',
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class ExportItemModel {
  final String id;
  final String exportFileId;
  final String itemId;
  final String lotId;
  final String hsCode;
  final double quantity;
  final String uom;
  final double unitPrice;
  final double totalPrice;
  final double? netWeightKg;
  final double? grossWeightKg;
  final int palletCount;
  final int packageCount;

  const ExportItemModel({
    required this.id,
    required this.exportFileId,
    required this.itemId,
    required this.lotId,
    required this.hsCode,
    required this.quantity,
    required this.uom,
    required this.unitPrice,
    required this.totalPrice,
    this.netWeightKg,
    this.grossWeightKg,
    this.palletCount = 1,
    this.packageCount = 1,
  });

  factory ExportItemModel.fromJson(Map<String, dynamic> json) {
    return ExportItemModel(
      id: json['id'] as String,
      exportFileId: json['export_file_id'] as String,
      itemId: json['item_id'] as String,
      lotId: json['lot_id'] as String,
      hsCode: json['hs_code'] as String? ?? '0804.10.00.00',
      quantity: (json['quantity'] as num).toDouble(),
      uom: json['uom'] as String? ?? 'Kg',
      unitPrice: (json['unit_price'] as num).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),
      netWeightKg: (json['net_weight_kg'] as num?)?.toDouble(),
      grossWeightKg: (json['gross_weight_kg'] as num?)?.toDouble(),
      palletCount: (json['pallet_count'] as num?)?.toInt() ?? 1,
      packageCount: (json['package_count'] as num?)?.toInt() ?? 1,
    );
  }
}

class CustomsDeclarationModel {
  final String id;
  final String exportFileId;
  final String declarationNumber;
  final DateTime declarationDate;
  final String customsOffice;
  final String hsCode;
  final String countryOfOrigin;
  final double customsValue;
  final String currencyCode;
  final double dutiesAndTaxes;
  final DateTime? clearanceDate;
  final String status;
  final String? customsBrokerPartyId;
  final String? notes;

  const CustomsDeclarationModel({
    required this.id,
    required this.exportFileId,
    required this.declarationNumber,
    required this.declarationDate,
    required this.customsOffice,
    required this.hsCode,
    required this.countryOfOrigin,
    required this.customsValue,
    required this.currencyCode,
    required this.dutiesAndTaxes,
    this.clearanceDate,
    required this.status,
    this.customsBrokerPartyId,
    this.notes,
  });

  factory CustomsDeclarationModel.fromJson(Map<String, dynamic> json) {
    return CustomsDeclarationModel(
      id: json['id'] as String,
      exportFileId: json['export_file_id'] as String,
      declarationNumber: json['declaration_number'] as String? ?? '',
      declarationDate: DateTime.parse(json['declaration_date'] as String),
      customsOffice: json['customs_office'] as String? ?? '',
      hsCode: json['hs_code'] as String? ?? '0804.10.00.00',
      countryOfOrigin: json['country_of_origin'] as String? ?? 'SA',
      customsValue: (json['customs_value'] as num).toDouble(),
      currencyCode: json['currency_code'] as String? ?? 'USD',
      dutiesAndTaxes: (json['duties_and_taxes'] as num?)?.toDouble() ?? 0.0,
      clearanceDate: json['clearance_date'] != null
          ? DateTime.parse(json['clearance_date'] as String)
          : null,
      status: json['status'] as String? ?? 'SUBMITTED',
      customsBrokerPartyId: json['customs_broker_party_id'] as String?,
      notes: json['notes'] as String?,
    );
  }
}

class ExportContainerModel {
  final String id;
  final String exportFileId;
  final String? shipmentId;
  final String containerNumber;
  final String sealNumber;
  final String containerType;
  final double tareWeightKg;
  final double grossWeightKg;
  final double? maxPayloadKg;
  final double? volumeCbm;
  final double temperatureSettingCelsius;
  final bool isActive;

  const ExportContainerModel({
    required this.id,
    required this.exportFileId,
    this.shipmentId,
    required this.containerNumber,
    required this.sealNumber,
    required this.containerType,
    required this.tareWeightKg,
    required this.grossWeightKg,
    this.maxPayloadKg,
    this.volumeCbm,
    required this.temperatureSettingCelsius,
    required this.isActive,
  });

  factory ExportContainerModel.fromJson(Map<String, dynamic> json) {
    return ExportContainerModel(
      id: json['id'] as String,
      exportFileId: json['export_file_id'] as String,
      shipmentId: json['shipment_id'] as String?,
      containerNumber: json['container_number'] as String? ?? '',
      sealNumber: json['seal_number'] as String? ?? '',
      containerType: json['container_type'] as String? ?? '40_REEFER',
      tareWeightKg: (json['tare_weight_kg'] as num?)?.toDouble() ?? 0.0,
      grossWeightKg: (json['gross_weight_kg'] as num?)?.toDouble() ?? 0.0,
      maxPayloadKg: (json['max_payload_kg'] as num?)?.toDouble(),
      volumeCbm: (json['volume_cbm'] as num?)?.toDouble(),
      temperatureSettingCelsius:
          (json['temperature_setting_celsius'] as num?)?.toDouble() ?? -18.0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

class ExportDocumentModel {
  final String id;
  final String exportFileId;
  final String? shipmentId;
  final String? invoiceId;
  final String documentType;
  final String documentNumber;
  final DateTime issueDate;
  final String? documentUrl;
  final bool isVerified;
  final String? notes;

  const ExportDocumentModel({
    required this.id,
    required this.exportFileId,
    this.shipmentId,
    this.invoiceId,
    required this.documentType,
    required this.documentNumber,
    required this.issueDate,
    this.documentUrl,
    required this.isVerified,
    this.notes,
  });

  factory ExportDocumentModel.fromJson(Map<String, dynamic> json) {
    return ExportDocumentModel(
      id: json['id'] as String,
      exportFileId: json['export_file_id'] as String,
      shipmentId: json['shipment_id'] as String?,
      invoiceId: json['invoice_id'] as String?,
      documentType: json['document_type'] as String,
      documentNumber: json['document_number'] as String? ?? '',
      issueDate: DateTime.parse(json['issue_date'] as String),
      documentUrl: json['document_url'] as String?,
      isVerified: json['is_verified'] as bool? ?? true,
      notes: json['notes'] as String?,
    );
  }
}

class ExportLotTraceabilityModel {
  final String exportFileId;
  final String exportNumber;
  final String exportStatus;
  final String incoterm;
  final String? originPort;
  final String? destinationPort;
  final String? customerTradeName;
  final String itemCode;
  final String itemName;
  final String hsCode;
  final double exportQuantity;
  final String uom;
  final String lotId;
  final String lotNumber;
  final String? farmName;
  final DateTime? harvestDate;
  final String? qualityStatus;
  final bool halalCertified;
  final String? customsDeclarationNo;
  final String? customsStatus;
  final String? containerNumber;
  final String? sealNumber;
  final String? containerType;
  final double? temperatureSettingCelsius;
  final String? shipmentNumber;
  final String? shipmentStatus;
  final String? transportMode;
  final String? vesselOrPlate;
  final String? billOfLadingNo;
  final DateTime? departureDate;
  final DateTime? actualArrivalDate;

  const ExportLotTraceabilityModel({
    required this.exportFileId,
    required this.exportNumber,
    required this.exportStatus,
    required this.incoterm,
    this.originPort,
    this.destinationPort,
    this.customerTradeName,
    required this.itemCode,
    required this.itemName,
    required this.hsCode,
    required this.exportQuantity,
    required this.uom,
    required this.lotId,
    required this.lotNumber,
    this.farmName,
    this.harvestDate,
    this.qualityStatus,
    required this.halalCertified,
    this.customsDeclarationNo,
    this.customsStatus,
    this.containerNumber,
    this.sealNumber,
    this.containerType,
    this.temperatureSettingCelsius,
    this.shipmentNumber,
    this.shipmentStatus,
    this.transportMode,
    this.vesselOrPlate,
    this.billOfLadingNo,
    this.departureDate,
    this.actualArrivalDate,
  });

  factory ExportLotTraceabilityModel.fromJson(Map<String, dynamic> json) {
    return ExportLotTraceabilityModel(
      exportFileId: json['export_file_id'] as String,
      exportNumber: json['export_number'] as String? ?? '',
      exportStatus: json['export_status'] as String? ?? '',
      incoterm: json['incoterm'] as String? ?? '',
      originPort: json['origin_port'] as String?,
      destinationPort: json['destination_port'] as String?,
      customerTradeName: json['customer_trade_name'] as String?,
      itemCode: json['item_code'] as String? ?? '',
      itemName: json['item_name'] as String? ?? '',
      hsCode: json['hs_code'] as String? ?? '',
      exportQuantity: (json['export_quantity'] as num).toDouble(),
      uom: json['uom'] as String? ?? '',
      lotId: json['lot_id'] as String,
      lotNumber: json['lot_number'] as String? ?? '',
      farmName: json['farm_name'] as String?,
      harvestDate: json['harvest_date'] != null
          ? DateTime.parse(json['harvest_date'] as String)
          : null,
      qualityStatus: json['quality_status'] as String?,
      halalCertified: json['halal_certified'] as bool? ?? true,
      customsDeclarationNo: json['customs_declaration_no'] as String?,
      customsStatus: json['customs_status'] as String?,
      containerNumber: json['container_number'] as String?,
      sealNumber: json['seal_number'] as String?,
      containerType: json['container_type'] as String?,
      temperatureSettingCelsius:
          (json['temperature_setting_celsius'] as num?)?.toDouble(),
      shipmentNumber: json['shipment_number'] as String?,
      shipmentStatus: json['shipment_status'] as String?,
      transportMode: json['transport_mode'] as String?,
      vesselOrPlate: json['vessel_or_plate'] as String?,
      billOfLadingNo: json['bill_of_lading_no'] as String?,
      departureDate: json['departure_date'] != null
          ? DateTime.parse(json['departure_date'] as String)
          : null,
      actualArrivalDate: json['actual_arrival_date'] != null
          ? DateTime.parse(json['actual_arrival_date'] as String)
          : null,
    );
  }
}

class ExportRepository {
  ExportRepository._();
  static final ExportRepository instance = ExportRepository._();

  /// Şirketin aktif sevkiyatlarını listeler (Mevcut metot korunmuştur)
  Future<List<TradeShipment>> getShipments(String companyId) async {
    try {
      final response = await SupabaseService.client
          .from('shipments')
          .select()
          .eq('company_id', companyId)
          .order('departure_date', ascending: false);

      return (response as List<dynamic>)
          .map((data) => TradeShipment.fromJson(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Şirketin ihracat dosyalarını listeler
  Future<List<ExportFileModel>> getExportFiles(String companyId) async {
    try {
      final response = await SupabaseService.client
          .from('export_files')
          .select()
          .eq('company_id', companyId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((data) => ExportFileModel.fromJson(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Yeni İhracat Dosyası açar (Customer -> Sales -> Export File)
  Future<String?> createExportFile({
    required String companyId,
    required String exportNumber,
    required String customerPartyId,
    String? salesOrderId,
    String? invoiceId,
    String originCountryCode = 'SA',
    String destinationCountryCode = 'TR',
    String originPort = 'Cidde İslam Limanı (KSA)',
    String destinationPort = 'Mersin Uluslararası Limanı (TR)',
    String incoterm = 'FOB',
    String currencyCode = 'USD',
    double fobValue = 0.0,
    double freightValue = 0.0,
    double insuranceValue = 0.0,
    double cifValue = 0.0,
    String? notes,
  }) async {
    try {
      final tenantId = TenantContext.instance.activeTenantId;
      if (tenantId == null) throw Exception('Aktif tenant seçilmedi.');

      final res = await SupabaseService.client
          .from('export_files')
          .insert({
            'tenant_id': tenantId,
            'company_id': companyId,
            'export_number': exportNumber.trim(),
            'customer_party_id': customerPartyId,
            'sales_order_id': salesOrderId,
            'invoice_id': invoiceId,
            'origin_country_code': originCountryCode,
            'destination_country_code': destinationCountryCode,
            'origin_port': originPort,
            'destination_port': destinationPort,
            'incoterm': incoterm,
            'currency_code': currencyCode,
            'fob_value': fobValue,
            'freight_value': freightValue,
            'insurance_value': insuranceValue,
            'cif_value': cifValue,
            'status': 'DRAFT',
            'notes': notes,
          })
          .select('id')
          .single();

      return res['id'] as String;
    } catch (e) {
      rethrow;
    }
  }

  /// İhracat Dosyasına Ürün Kalemi & Lot Bağlantısı Ekler
  Future<String?> addExportFileItem({
    required String exportFileId,
    required String itemId,
    required String lotId,
    String hsCode = '0804.10.00.00',
    required double quantity,
    String uom = 'Kg',
    required double unitPrice,
    double? netWeightKg,
    double? grossWeightKg,
    int palletCount = 1,
    int packageCount = 1,
  }) async {
    try {
      final tenantId = TenantContext.instance.activeTenantId;
      if (tenantId == null) throw Exception('Aktif tenant seçilmedi.');

      final totalPrice = quantity * unitPrice;
      final res = await SupabaseService.client
          .from('export_file_items')
          .insert({
            'tenant_id': tenantId,
            'export_file_id': exportFileId,
            'item_id': itemId,
            'lot_id': lotId,
            'hs_code': hsCode,
            'quantity': quantity,
            'uom': uom,
            'unit_price': unitPrice,
            'total_price': totalPrice,
            'net_weight_kg': netWeightKg,
            'gross_weight_kg': grossWeightKg,
            'pallet_count': palletCount,
            'package_count': packageCount,
          })
          .select('id')
          .single();

      return res['id'] as String;
    } catch (e) {
      rethrow;
    }
  }

  /// Gümrük Beyannamesi (GÇB) Kaydı Ekler
  Future<String?> recordCustomsDeclaration({
    required String companyId,
    required String exportFileId,
    required String declarationNumber,
    DateTime? declarationDate,
    required String customsOffice,
    String hsCode = '0804.10.00.00',
    String countryOfOrigin = 'SA',
    required double customsValue,
    String currencyCode = 'USD',
    double dutiesAndTaxes = 0.0,
    String? customsBrokerPartyId,
    String? notes,
  }) async {
    try {
      final tenantId = TenantContext.instance.activeTenantId;
      if (tenantId == null) throw Exception('Aktif tenant seçilmedi.');

      final res = await SupabaseService.client
          .from('customs_declarations')
          .insert({
            'tenant_id': tenantId,
            'company_id': companyId,
            'export_file_id': exportFileId,
            'declaration_number': declarationNumber.trim(),
            'declaration_date': (declarationDate ?? DateTime.now())
                .toIso8601String()
                .substring(0, 10),
            'customs_office': customsOffice,
            'hs_code': hsCode,
            'country_of_origin': countryOfOrigin,
            'customs_value': customsValue,
            'currency_code': currencyCode,
            'duties_and_taxes': dutiesAndTaxes,
            'status': 'SUBMITTED',
            'customs_broker_party_id': customsBrokerPartyId,
            'notes': notes,
          })
          .select('id')
          .single();

      return res['id'] as String;
    } catch (e) {
      rethrow;
    }
  }

  /// Konteyner Atar (Mükerrer aktif konteyner kuralı ile)
  Future<String?> assignExportContainer({
    required String companyId,
    required String exportFileId,
    String? shipmentId,
    required String containerNumber,
    required String sealNumber,
    String containerType = '40_REEFER',
    double tareWeightKg = 0.0,
    double grossWeightKg = 0.0,
    double? maxPayloadKg,
    double? volumeCbm,
    double temperatureSettingCelsius = -18.0,
  }) async {
    try {
      final tenantId = TenantContext.instance.activeTenantId;
      if (tenantId == null) throw Exception('Aktif tenant seçilmedi.');

      final res = await SupabaseService.client
          .from('export_containers')
          .insert({
            'tenant_id': tenantId,
            'company_id': companyId,
            'export_file_id': exportFileId,
            'shipment_id': shipmentId,
            'container_number': containerNumber.trim().toUpperCase(),
            'seal_number': sealNumber.trim(),
            'container_type': containerType,
            'tare_weight_kg': tareWeightKg,
            'gross_weight_kg': grossWeightKg,
            'max_payload_kg': maxPayloadKg,
            'volume_cbm': volumeCbm,
            'temperature_setting_celsius': temperatureSettingCelsius,
            'is_active': true,
          })
          .select('id')
          .single();

      return res['id'] as String;
    } catch (e) {
      rethrow;
    }
  }

  /// Dış Ticaret Belgesi İlişkilendirir (Document Context)
  Future<String?> attachExportDocument({
    required String companyId,
    required String exportFileId,
    String? shipmentId,
    String? invoiceId,
    required String documentType,
    required String documentNumber,
    DateTime? issueDate,
    String? documentUrl,
    String? notes,
  }) async {
    try {
      final tenantId = TenantContext.instance.activeTenantId;
      if (tenantId == null) throw Exception('Aktif tenant seçilmedi.');

      final res = await SupabaseService.client
          .from('export_documents')
          .insert({
            'tenant_id': tenantId,
            'company_id': companyId,
            'export_file_id': exportFileId,
            'shipment_id': shipmentId,
            'invoice_id': invoiceId,
            'document_type': documentType,
            'document_number': documentNumber.trim(),
            'issue_date': (issueDate ?? DateTime.now())
                .toIso8601String()
                .substring(0, 10),
            'document_url': documentUrl,
            'is_verified': true,
            'notes': notes,
          })
          .select('id')
          .single();

      return res['id'] as String;
    } catch (e) {
      rethrow;
    }
  }

  /// İhracat Dosyası ve Sevkiyat Durumunu Günceller
  Future<void> updateExportStatus({
    required String exportFileId,
    required String status,
  }) async {
    try {
      await SupabaseService.client.from('export_files').update({
        'status': status,
        'updated_at': DateTime.now().toIso8601String()
      }).eq('id', exportFileId);
    } catch (e) {
      rethrow;
    }
  }

  /// Uçtan Uca İhracat Lot İzlenebilirlik Raporunu Getirir
  Future<List<ExportLotTraceabilityModel>> getExportLotTraceability(
      String exportFileId) async {
    try {
      final response = await SupabaseService.client
          .from('view_export_lot_traceability')
          .select()
          .eq('export_file_id', exportFileId);

      return (response as List<dynamic>)
          .map((data) =>
              ExportLotTraceabilityModel.fromJson(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Yeni İhracat Sevkiyatı açar ve Helal / Stok kontrollerini yapar (Mevcut metot korunmuştur)
  Future<String?> createExportShipment({
    required String companyId,
    String? tradeOrderId,
    String? exportFileId,
    required String shipmentNumber,
    required String transportMode,
    required String carrierCompany,
    required String vesselOrPlate,
    required String customsDeclarationNo,
    required String billOfLadingNo,
    required DateTime departureDate,
    DateTime? estimatedArrivalDate,
    required String warehouseId,
    required String itemId,
    String? lotId,
    required double tonaj,
    required double birimMaliyet,
    bool enforceHalalCheck = true,
  }) async {
    try {
      final tenantId = TenantContext.instance.activeTenantId;
      if (tenantId == null) throw Exception('Aktif tenant seçilmedi.');

      // 1. Helal Uygunluk Doğrulaması (İhracat Kuralı)
      if (enforceHalalCheck) {
        final isHalal =
            await HalalRepository.instance.isItemHalalCertified(itemId: itemId);
        if (!isHalal) {
          throw Exception(
              'Sevkiyat engellendi: Sevk edilmek istenen hurma çeşidinin geçerli bir Helal Sertifikası bulunmamaktadır!');
        }
      }

      // 2. Sevkiyat Kaydını Oluştur
      final res = await SupabaseService.client
          .from('shipments')
          .insert({
            'tenant_id': tenantId,
            'company_id': companyId,
            'trade_order_id': tradeOrderId,
            'export_file_id': exportFileId,
            'shipment_number': shipmentNumber.trim(),
            'transport_mode': transportMode,
            'carrier_company': carrierCompany,
            'vessel_or_plate': vesselOrPlate,
            'customs_declaration_no': customsDeclarationNo,
            'bill_of_lading_no': billOfLadingNo,
            'departure_date': departureDate.toIso8601String().substring(0, 10),
            'estimated_arrival_date':
                estimatedArrivalDate?.toIso8601String().substring(0, 10),
            'status': 'IN_TRANSIT',
          })
          .select('id')
          .single();

      final shipmentId = res['id'] as String;

      // 3. Stok Hareket Defterine Otomatik İhracat Çıkışı Yaz (Append-Only)
      await InventoryRepository.instance.recordStockMovement(
        companyId: companyId,
        warehouseId: warehouseId,
        itemId: itemId,
        lotId: lotId,
        movementType: 'SALES_ISSUE',
        quantity: -tonaj.abs(), // Negatif düşüm
        unit: 'Ton',
        unitCost: birimMaliyet,
        documentType: 'SHIPMENT',
        documentReference: shipmentNumber,
        description:
            'İhracat Liman Çıkışı: $shipmentNumber (GÇB: $customsDeclarationNo)',
      );

      return shipmentId;
    } catch (e) {
      rethrow;
    }
  }
}
