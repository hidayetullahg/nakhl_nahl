import '../services/supabase_service.dart';
import '../core/tenant/tenant_context.dart';

/// Kalite Şartname Modeli
class QualitySpecificationModel {
  final String id;
  final String itemId;
  final String specCode;
  final String specName;
  final String version;
  final String? description;
  final bool isActive;

  const QualitySpecificationModel({
    required this.id,
    required this.itemId,
    required this.specCode,
    required this.specName,
    this.version = '1.0',
    this.description,
    this.isActive = true,
  });

  factory QualitySpecificationModel.fromMap(Map<String, dynamic> map) {
    return QualitySpecificationModel(
      id: map['id'] ?? '',
      itemId: map['item_id'] ?? '',
      specCode: map['spec_code'] ?? '',
      specName: map['spec_name'] ?? '',
      version: map['version'] ?? '1.0',
      description: map['description'],
      isActive: map['is_active'] ?? true,
    );
  }
}

/// Kalite Test Parametre Modeli
class QualityParameterModel {
  final String id;
  final String specificationId;
  final String parameterCode;
  final String parameterName;
  final String parameterType; // NUMERIC, BOOLEAN, TEXT
  final double? minimumValue;
  final double? maximumValue;
  final double? targetValue;
  final String uom;
  final bool isCritical;

  const QualityParameterModel({
    required this.id,
    required this.specificationId,
    required this.parameterCode,
    required this.parameterName,
    this.parameterType = 'NUMERIC',
    this.minimumValue,
    this.maximumValue,
    this.targetValue,
    this.uom = '%',
    this.isCritical = false,
  });

  factory QualityParameterModel.fromMap(Map<String, dynamic> map) {
    return QualityParameterModel(
      id: map['id'] ?? '',
      specificationId: map['specification_id'] ?? '',
      parameterCode: map['parameter_code'] ?? '',
      parameterName: map['parameter_name'] ?? '',
      parameterType: map['parameter_type'] ?? 'NUMERIC',
      minimumValue: (map['minimum_value'] as num?)?.toDouble(),
      maximumValue: (map['maximum_value'] as num?)?.toDouble(),
      targetValue: (map['target_value'] as num?)?.toDouble(),
      uom: map['uom'] ?? '%',
      isCritical: map['is_critical'] ?? false,
    );
  }
}

/// Kalite Muayene Modeli
class QualityInspectionModel {
  final String id;
  final String inspectionNumber;
  final String
      inspectionType; // INCOMING, IN_PROCESS, FINAL, WAREHOUSE, SHIPMENT
  final String itemId;
  final String lotId;
  final String? warehouseId;
  final String? specificationId;
  final DateTime inspectionDate;
  final String? inspectorUserId;
  final String result; // PASS, FAIL, CONDITIONAL, QUARANTINE
  final String? actionTaken;
  final String? notes;

  const QualityInspectionModel({
    required this.id,
    required this.inspectionNumber,
    required this.inspectionType,
    required this.itemId,
    required this.lotId,
    this.warehouseId,
    this.specificationId,
    required this.inspectionDate,
    this.inspectorUserId,
    required this.result,
    this.actionTaken,
    this.notes,
  });

  factory QualityInspectionModel.fromMap(Map<String, dynamic> map) {
    return QualityInspectionModel(
      id: map['id'] ?? '',
      inspectionNumber: map['inspection_number'] ?? '',
      inspectionType: map['inspection_type'] ?? 'INCOMING',
      itemId: map['item_id'] ?? '',
      lotId: map['lot_id'] ?? '',
      warehouseId: map['warehouse_id'],
      specificationId: map['specification_id'],
      inspectionDate: DateTime.parse(map['inspection_date'].toString()),
      inspectorUserId: map['inspector_user_id'],
      result: map['result'] ?? 'PASS',
      actionTaken: map['action_taken'],
      notes: map['notes'],
    );
  }
}

class QualityRepository {
  QualityRepository._();
  static final QualityRepository instance = QualityRepository._();

  /// Şirkete ait kalite şartnamelerini listeler
  Future<List<QualitySpecificationModel>> getSpecifications(
      String companyId) async {
    try {
      final res = await SupabaseService.client
          .from('quality_specifications')
          .select()
          .eq('company_id', companyId)
          .eq('is_active', true)
          .order('spec_code', ascending: true);

      return (res as List<dynamic>)
          .map((m) =>
              QualitySpecificationModel.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Şartnameye ait test parametrelerini listeler
  Future<List<QualityParameterModel>> getParameters(
      String specificationId) async {
    try {
      final res = await SupabaseService.client
          .from('quality_parameters')
          .select()
          .eq('specification_id', specificationId)
          .order('parameter_code', ascending: true);

      return (res as List<dynamic>)
          .map((m) => QualityParameterModel.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Muayene kayıtlarını listeler
  Future<List<QualityInspectionModel>> getInspections(String companyId) async {
    try {
      final res = await SupabaseService.client
          .from('quality_inspections')
          .select()
          .eq('company_id', companyId)
          .order('inspection_date', ascending: false);

      return (res as List<dynamic>)
          .map((m) => QualityInspectionModel.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Yeni kalite muayenesi kaydeder (Tetikleyici ile lot durumunu otomatik günceller)
  Future<String> recordInspection({
    required String companyId,
    required String inspectionNumber,
    required String
        inspectionType, // INCOMING, IN_PROCESS, FINAL, WAREHOUSE, SHIPMENT
    required String itemId,
    required String lotId,
    String? warehouseId,
    String? specificationId,
    DateTime? inspectionDate,
    required String result, // PASS, FAIL, CONDITIONAL, QUARANTINE
    String? actionTaken,
    String? notes,
  }) async {
    final tenantId = TenantContext.instance.activeTenantId;
    if (tenantId == null) throw Exception('Aktif tenant seçilmedi.');

    final res = await SupabaseService.client
        .from('quality_inspections')
        .insert({
          'tenant_id': tenantId,
          'company_id': companyId,
          'inspection_number': inspectionNumber,
          'inspection_type': inspectionType,
          'item_id': itemId,
          'lot_id': lotId,
          'warehouse_id': warehouseId,
          'specification_id': specificationId,
          'inspection_date':
              (inspectionDate ?? DateTime.now()).toIso8601String(),
          'result': result,
          'action_taken': actionTaken,
          'notes': notes,
        })
        .select('id')
        .single();

    return res['id'] as String;
  }

  /// Lotun kalite geçmişini (view_lot_traceability_quality) listeler
  Future<List<Map<String, dynamic>>> getLotInspectionHistory(
      String lotId) async {
    try {
      final res = await SupabaseService.client
          .from('view_lot_traceability_quality')
          .select()
          .eq('lot_id', lotId)
          .order('inspection_date', ascending: true);

      return List<Map<String, dynamic>>.from(res as List);
    } catch (e) {
      return [];
    }
  }
}
