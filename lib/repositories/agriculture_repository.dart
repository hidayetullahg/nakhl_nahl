import '../services/supabase_service.dart';
import '../core/tenant/tenant_context.dart';

/// Çiftlik / Vaha Modeli
class FarmModel {
  final String id;
  final String code;
  final String name;
  final String? operatorPartyId;
  final String countryCode;
  final String? region;
  final String? city;
  final String? gpsCoordinates;
  final double totalAreaHectares;
  final String cultivationType; // ORGANIC, CONVENTIONAL, BIODYNAMIC
  final String status; // ACTIVE, INACTIVE, SUSPENDED

  const FarmModel({
    required this.id,
    required this.code,
    required this.name,
    this.operatorPartyId,
    this.countryCode = 'SA',
    this.region,
    this.city,
    this.gpsCoordinates,
    required this.totalAreaHectares,
    this.cultivationType = 'ORGANIC',
    this.status = 'ACTIVE',
  });

  factory FarmModel.fromMap(Map<String, dynamic> map) {
    return FarmModel(
      id: map['id'] ?? '',
      code: map['code'] ?? '',
      name: map['name'] ?? '',
      operatorPartyId: map['operator_party_id'],
      countryCode: map['country_code'] ?? 'SA',
      region: map['region'],
      city: map['city'],
      gpsCoordinates: map['gps_coordinates'],
      totalAreaHectares:
          (map['total_area_hectares'] as num?)?.toDouble() ?? 0.0,
      cultivationType: map['cultivation_type'] ?? 'ORGANIC',
      status: map['status'] ?? 'ACTIVE',
    );
  }
}

/// Tarla / Parsel Modeli
class FieldModel {
  final String id;
  final String farmId;
  final String fieldCode;
  final String fieldName;
  final double areaHectares;
  final String soilType;
  final String irrigationType;
  final int treeCount;
  final int? plantingYear;
  final String status;

  const FieldModel({
    required this.id,
    required this.farmId,
    required this.fieldCode,
    required this.fieldName,
    required this.areaHectares,
    this.soilType = 'SANDY_LOAM',
    this.irrigationType = 'DRIP',
    this.treeCount = 0,
    this.plantingYear,
    this.status = 'ACTIVE',
  });

  factory FieldModel.fromMap(Map<String, dynamic> map) {
    return FieldModel(
      id: map['id'] ?? '',
      farmId: map['farm_id'] ?? '',
      fieldCode: map['field_code'] ?? '',
      fieldName: map['field_name'] ?? '',
      areaHectares: (map['area_hectares'] as num?)?.toDouble() ?? 0.0,
      soilType: map['soil_type'] ?? 'SANDY_LOAM',
      irrigationType: map['irrigation_type'] ?? 'DRIP',
      treeCount: map['tree_count'] ?? 0,
      plantingYear: map['planting_year'],
      status: map['status'] ?? 'ACTIVE',
    );
  }
}

/// Mahsul / Çeşit Modeli
class CropModel {
  final String id;
  final String cropCode;
  final String cropName;
  final String variety; // Medjoul, Sukkari, Ajwa, etc.
  final String grade; // JUMBO, PREMIUM, STANDARD, INDUSTRIAL
  final String growingSeason;
  final String? itemId;

  const CropModel({
    required this.id,
    required this.cropCode,
    required this.cropName,
    required this.variety,
    required this.grade,
    required this.growingSeason,
    this.itemId,
  });

  factory CropModel.fromMap(Map<String, dynamic> map) {
    return CropModel(
      id: map['id'] ?? '',
      cropCode: map['crop_code'] ?? '',
      cropName: map['crop_name'] ?? 'HURMA',
      variety: map['variety'] ?? '',
      grade: map['grade'] ?? 'PREMIUM',
      growingSeason: map['growing_season'] ?? '2026-AUTUMN',
      itemId: map['item_id'],
    );
  }
}

/// Hasat Operasyon Modeli
class HarvestModel {
  final String id;
  final String farmId;
  final String fieldId;
  final String cropId;
  final String harvestNumber;
  final DateTime harvestDate;
  final double quantityHarvested;
  final String uom;
  final String qualityGrade;
  final double humidityPercentage;
  final double sugarBrix;
  final String? lotId;
  final String warehouseId;
  final String status;
  final String? notes;

  const HarvestModel({
    required this.id,
    required this.farmId,
    required this.fieldId,
    required this.cropId,
    required this.harvestNumber,
    required this.harvestDate,
    required this.quantityHarvested,
    required this.uom,
    required this.qualityGrade,
    required this.humidityPercentage,
    required this.sugarBrix,
    this.lotId,
    required this.warehouseId,
    required this.status,
    this.notes,
  });

  factory HarvestModel.fromMap(Map<String, dynamic> map) {
    return HarvestModel(
      id: map['id'] ?? '',
      farmId: map['farm_id'] ?? '',
      fieldId: map['field_id'] ?? '',
      cropId: map['crop_id'] ?? '',
      harvestNumber: map['harvest_number'] ?? '',
      harvestDate: DateTime.parse(map['harvest_date'].toString()),
      quantityHarvested: (map['quantity_harvested'] as num?)?.toDouble() ?? 0.0,
      uom: map['uom'] ?? 'Kg',
      qualityGrade: map['quality_grade'] ?? 'GRADE_A',
      humidityPercentage:
          (map['humidity_percentage'] as num?)?.toDouble() ?? 18.5,
      sugarBrix: (map['sugar_brix'] as num?)?.toDouble() ?? 68.0,
      lotId: map['lot_id'],
      warehouseId: map['warehouse_id'] ?? '',
      status: map['status'] ?? 'COMPLETED',
      notes: map['notes'],
    );
  }
}

class AgricultureRepository {
  AgricultureRepository._();
  static final AgricultureRepository instance = AgricultureRepository._();

  /// Şirkete ait çiftlikleri listeler
  Future<List<FarmModel>> getFarms(String companyId) async {
    try {
      final res = await SupabaseService.client
          .from('farms')
          .select()
          .eq('company_id', companyId)
          .eq('status', 'ACTIVE')
          .order('code', ascending: true);

      return (res as List<dynamic>)
          .map((m) => FarmModel.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Çiftliğe ait tarlaları/parselleri listeler
  Future<List<FieldModel>> getFields(String farmId) async {
    try {
      final res = await SupabaseService.client
          .from('fields')
          .select()
          .eq('farm_id', farmId)
          .order('field_code', ascending: true);

      return (res as List<dynamic>)
          .map((m) => FieldModel.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Mahsul ve hurma çeşitlerini listeler
  Future<List<CropModel>> getCrops() async {
    try {
      final res = await SupabaseService.client
          .from('crops')
          .select()
          .eq('is_active', true)
          .order('variety', ascending: true);

      return (res as List<dynamic>)
          .map((m) => CropModel.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Hasat kayıtlarını listeler
  Future<List<HarvestModel>> getHarvests(String companyId) async {
    try {
      final res = await SupabaseService.client
          .from('harvests')
          .select()
          .eq('company_id', companyId)
          .order('harvest_date', ascending: false);

      return (res as List<dynamic>)
          .map((m) => HarvestModel.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// ATOMİK HASAT OPERASYONU VE STOK GİRİŞİ (RPC)
  /// FARM -> FIELD -> CROP -> HARVEST -> LOT -> STOCK tek transaction
  Future<Map<String, dynamic>> processFarmHarvestAtomic({
    required String companyId,
    required String farmId,
    required String fieldId,
    required String cropId,
    required String harvestNumber,
    required DateTime harvestDate,
    required double quantity,
    required String uom,
    required String warehouseId,
    String qualityGrade = 'GRADE_A',
    double humidityPercentage = 18.5,
    double sugarBrix = 68.0,
    String? notes,
  }) async {
    final tenantId = TenantContext.instance.activeTenantId;
    if (tenantId == null) throw Exception('Aktif tenant seçilmedi.');

    final res = await SupabaseService.client.rpc(
      'process_farm_harvest_atomic',
      params: {
        'p_tenant_id': tenantId,
        'p_company_id': companyId,
        'p_farm_id': farmId,
        'p_field_id': fieldId,
        'p_crop_id': cropId,
        'p_harvest_number': harvestNumber,
        'p_harvest_date': harvestDate.toIso8601String().substring(0, 10),
        'p_quantity': quantity,
        'p_uom': uom,
        'p_warehouse_id': warehouseId,
        'p_quality_grade': qualityGrade,
        'p_humidity_percentage': humidityPercentage,
        'p_sugar_brix': sugarBrix,
        'p_notes': notes,
      },
    );

    return Map<String, dynamic>.from(res as Map);
  }
}
