import '../services/supabase_service.dart';

class Warehouse {
  final String id;
  final String tenantId;
  final String companyId;
  final String? branchId;
  final String? businessUnitId;
  final String code;
  final String name;
  final String warehouseType;
  final String? address;
  final String countryCode;
  final bool temperatureControlled;
  final bool halalControlled;
  final bool qualityControlled;

  const Warehouse({
    required this.id,
    required this.tenantId,
    required this.companyId,
    this.branchId,
    this.businessUnitId,
    required this.code,
    required this.name,
    required this.warehouseType,
    this.address,
    required this.countryCode,
    required this.temperatureControlled,
    required this.halalControlled,
    required this.qualityControlled,
  });

  factory Warehouse.fromMap(Map<String, dynamic> map) {
    return Warehouse(
      id: map['id'] ?? '',
      tenantId: map['tenant_id'] ?? '',
      companyId: map['company_id'] ?? '',
      branchId: map['branch_id'],
      businessUnitId: map['business_unit_id'],
      code: map['code'] ?? '',
      name: map['name'] ?? '',
      warehouseType: map['warehouse_type'] ?? 'RAW_MATERIAL',
      address: map['address'],
      countryCode: map['country_code'] ?? 'SA',
      temperatureControlled: map['temperature_controlled'] ?? false,
      halalControlled: map['halal_controlled'] ?? true,
      qualityControlled: map['quality_controlled'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tenant_id': tenantId,
      'company_id': companyId,
      'branch_id': branchId,
      'business_unit_id': businessUnitId,
      'code': code,
      'name': name,
      'warehouse_type': warehouseType,
      'address': address,
      'country_code': countryCode,
      'temperature_controlled': temperatureControlled,
      'halal_controlled': halalControlled,
      'quality_controlled': qualityControlled,
    };
  }
}

class WarehouseRepository {
  WarehouseRepository._();
  static final WarehouseRepository instance = WarehouseRepository._();

  /// Şirkete ait depoları listeler
  Future<List<Warehouse>> getWarehouses(String companyId) async {
    try {
      final response = await SupabaseService.client
          .from('warehouses')
          .select()
          .eq('company_id', companyId)
          .eq('status', 'ACTIVE')
          .order('code', ascending: true);

      return (response as List<dynamic>)
          .map((m) => Warehouse.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Yeni depo oluşturur
  Future<Warehouse?> createWarehouse({
    required String tenantId,
    required String companyId,
    String? branchId,
    String? businessUnitId,
    required String code,
    required String name,
    String warehouseType = 'RAW_MATERIAL',
    String? address,
    String countryCode = 'SA',
    bool temperatureControlled = false,
    bool halalControlled = true,
    bool qualityControlled = true,
  }) async {
    try {
      final response = await SupabaseService.client
          .from('warehouses')
          .insert({
            'tenant_id': tenantId,
            'company_id': companyId,
            'branch_id': branchId,
            'business_unit_id': businessUnitId,
            'code': code.toUpperCase().trim(),
            'name': name.trim(),
            'warehouse_type': warehouseType,
            'address': address?.trim(),
            'country_code': countryCode,
            'temperature_controlled': temperatureControlled,
            'halal_controlled': halalControlled,
            'quality_controlled': qualityControlled,
          })
          .select()
          .single();

      return Warehouse.fromMap(response);
    } catch (_) {
      return null;
    }
  }
}
