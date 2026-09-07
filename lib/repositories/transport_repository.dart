import '../services/supabase_service.dart';
import '../core/tenant/tenant_context.dart';

class VehicleModel {
  final String id;
  final String carrierPartyId;
  final String registrationPlate;
  final String vehicleType; // REEFER_TRUCK, DRY_TRUCK, TRAILER, VAN
  final double capacityPayloadKg;
  final double? capacityVolumeCbm;
  final bool isTemperatureControlled;
  final double minTempCelsius;
  final double maxTempCelsius;
  final String status; // AVAILABLE, ON_ROUTE, MAINTENANCE, INACTIVE

  const VehicleModel({
    required this.id,
    required this.carrierPartyId,
    required this.registrationPlate,
    required this.vehicleType,
    required this.capacityPayloadKg,
    this.capacityVolumeCbm,
    required this.isTemperatureControlled,
    required this.minTempCelsius,
    required this.maxTempCelsius,
    required this.status,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] as String,
      carrierPartyId: json['carrier_party_id'] as String,
      registrationPlate: json['registration_plate'] as String? ?? '',
      vehicleType: json['vehicle_type'] as String? ?? 'REEFER_TRUCK',
      capacityPayloadKg:
          (json['capacity_payload_kg'] as num?)?.toDouble() ?? 20000.0,
      capacityVolumeCbm: (json['capacity_volume_cbm'] as num?)?.toDouble(),
      isTemperatureControlled:
          json['is_temperature_controlled'] as bool? ?? true,
      minTempCelsius: (json['min_temp_celsius'] as num?)?.toDouble() ?? -25.0,
      maxTempCelsius: (json['max_temp_celsius'] as num?)?.toDouble() ?? 10.0,
      status: json['status'] as String? ?? 'AVAILABLE',
    );
  }
}

class DriverModel {
  final String id;
  final String carrierPartyId;
  final String fullName;
  final String licenseNumber;
  final String? phoneNumber;
  final String? nationalId;
  final String status; // ACTIVE, ON_TRIP, OFF_DUTY, SUSPENDED

  const DriverModel({
    required this.id,
    required this.carrierPartyId,
    required this.fullName,
    required this.licenseNumber,
    this.phoneNumber,
    this.nationalId,
    required this.status,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: json['id'] as String,
      carrierPartyId: json['carrier_party_id'] as String,
      fullName: json['full_name'] as String? ?? '',
      licenseNumber: json['license_number'] as String? ?? '',
      phoneNumber: json['phone_number'] as String?,
      nationalId: json['national_id'] as String?,
      status: json['status'] as String? ?? 'ACTIVE',
    );
  }
}

class TransportOrderModel {
  final String id;
  final String transportOrderNumber;
  final String? shipmentId;
  final String? exportFileId;
  final String carrierPartyId;
  final String? vehicleId;
  final String? driverId;
  final String pickupLocationType;
  final String? pickupWarehouseId;
  final String pickupAddress;
  final DateTime pickupTime;
  final String deliveryLocationType;
  final String? deliveryWarehouseId;
  final String deliveryAddress;
  final DateTime scheduledDeliveryTime;
  final DateTime? actualDeliveryTime;
  final String? routeCode;
  final String? routeDescription;
  final double? distanceKm;
  final String status;
  final String? notes;
  final DateTime createdAt;

  const TransportOrderModel({
    required this.id,
    required this.transportOrderNumber,
    this.shipmentId,
    this.exportFileId,
    required this.carrierPartyId,
    this.vehicleId,
    this.driverId,
    required this.pickupLocationType,
    this.pickupWarehouseId,
    required this.pickupAddress,
    required this.pickupTime,
    required this.deliveryLocationType,
    this.deliveryWarehouseId,
    required this.deliveryAddress,
    required this.scheduledDeliveryTime,
    this.actualDeliveryTime,
    this.routeCode,
    this.routeDescription,
    this.distanceKm,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  factory TransportOrderModel.fromJson(Map<String, dynamic> json) {
    return TransportOrderModel(
      id: json['id'] as String,
      transportOrderNumber: json['transport_order_number'] as String? ?? '',
      shipmentId: json['shipment_id'] as String?,
      exportFileId: json['export_file_id'] as String?,
      carrierPartyId: json['carrier_party_id'] as String,
      vehicleId: json['vehicle_id'] as String?,
      driverId: json['driver_id'] as String?,
      pickupLocationType:
          json['pickup_location_type'] as String? ?? 'WAREHOUSE',
      pickupWarehouseId: json['pickup_warehouse_id'] as String?,
      pickupAddress: json['pickup_address'] as String? ?? '',
      pickupTime: DateTime.parse(json['pickup_time'] as String),
      deliveryLocationType: json['delivery_location_type'] as String? ?? 'PORT',
      deliveryWarehouseId: json['delivery_warehouse_id'] as String?,
      deliveryAddress: json['delivery_address'] as String? ?? '',
      scheduledDeliveryTime:
          DateTime.parse(json['scheduled_delivery_time'] as String),
      actualDeliveryTime: json['actual_delivery_time'] != null
          ? DateTime.parse(json['actual_delivery_time'] as String)
          : null,
      routeCode: json['route_code'] as String?,
      routeDescription: json['route_description'] as String?,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      status: json['status'] as String? ?? 'DRAFT',
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class TransportOrderItemModel {
  final String id;
  final String transportOrderId;
  final String lotId;
  final String itemId;
  final double quantity;
  final String uom;
  final int packageCount;
  final int palletCount;

  const TransportOrderItemModel({
    required this.id,
    required this.transportOrderId,
    required this.lotId,
    required this.itemId,
    required this.quantity,
    required this.uom,
    this.packageCount = 1,
    this.palletCount = 1,
  });

  factory TransportOrderItemModel.fromJson(Map<String, dynamic> json) {
    return TransportOrderItemModel(
      id: json['id'] as String,
      transportOrderId: json['transport_order_id'] as String,
      lotId: json['lot_id'] as String,
      itemId: json['item_id'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      uom: json['uom'] as String? ?? 'Kg',
      packageCount: (json['package_count'] as num?)?.toInt() ?? 1,
      palletCount: (json['pallet_count'] as num?)?.toInt() ?? 1,
    );
  }
}

class ColdChainLogModel {
  final String id;
  final String contextType;
  final String? transportOrderId;
  final String? warehouseId;
  final String? containerId;
  final double recordedTemperature;
  final double targetTemperature;
  final double minThreshold;
  final double maxThreshold;
  final bool isBreached;
  final String severity; // NORMAL, WARNING, CRITICAL_EXCURSION
  final String? sensorId;
  final DateTime recordedAt;

  const ColdChainLogModel({
    required this.id,
    required this.contextType,
    this.transportOrderId,
    this.warehouseId,
    this.containerId,
    required this.recordedTemperature,
    required this.targetTemperature,
    required this.minThreshold,
    required this.maxThreshold,
    required this.isBreached,
    required this.severity,
    this.sensorId,
    required this.recordedAt,
  });

  factory ColdChainLogModel.fromJson(Map<String, dynamic> json) {
    return ColdChainLogModel(
      id: json['id'] as String,
      contextType: json['context_type'] as String,
      transportOrderId: json['transport_order_id'] as String?,
      warehouseId: json['warehouse_id'] as String?,
      containerId: json['container_id'] as String?,
      recordedTemperature: (json['recorded_temperature'] as num).toDouble(),
      targetTemperature:
          (json['target_temperature'] as num?)?.toDouble() ?? -18.0,
      minThreshold: (json['min_threshold'] as num?)?.toDouble() ?? -22.0,
      maxThreshold: (json['max_threshold'] as num?)?.toDouble() ?? -14.0,
      isBreached: json['is_breached'] as bool? ?? false,
      severity: json['severity'] as String? ?? 'NORMAL',
      sensorId: json['sensor_id'] as String?,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
    );
  }
}

class TransportLotTraceabilityModel {
  final String transportItemId;
  final String lotId;
  final String lotNumber;
  final String? farmName;
  final DateTime? harvestDate;
  final String? qualityStatus;
  final bool halalCertified;
  final String itemCode;
  final String itemName;
  final double transportedQuantity;
  final String uom;
  final String transportOrderId;
  final String transportOrderNumber;
  final String transportStatus;
  final String? routeCode;
  final double? distanceKm;
  final String pickupAddress;
  final String deliveryAddress;
  final String? carrierName;
  final String? registrationPlate;
  final String? vehicleType;
  final String? driverName;
  final String? shipmentNumber;
  final String? shipmentStatus;

  const TransportLotTraceabilityModel({
    required this.transportItemId,
    required this.lotId,
    required this.lotNumber,
    this.farmName,
    this.harvestDate,
    this.qualityStatus,
    required this.halalCertified,
    required this.itemCode,
    required this.itemName,
    required this.transportedQuantity,
    required this.uom,
    required this.transportOrderId,
    required this.transportOrderNumber,
    required this.transportStatus,
    this.routeCode,
    this.distanceKm,
    required this.pickupAddress,
    required this.deliveryAddress,
    this.carrierName,
    this.registrationPlate,
    this.vehicleType,
    this.driverName,
    this.shipmentNumber,
    this.shipmentStatus,
  });

  factory TransportLotTraceabilityModel.fromJson(Map<String, dynamic> json) {
    return TransportLotTraceabilityModel(
      transportItemId: json['transport_item_id'] as String,
      lotId: json['lot_id'] as String,
      lotNumber: json['lot_number'] as String? ?? '',
      farmName: json['farm_name'] as String?,
      harvestDate: json['harvest_date'] != null
          ? DateTime.parse(json['harvest_date'] as String)
          : null,
      qualityStatus: json['quality_status'] as String?,
      halalCertified: json['halal_certified'] as bool? ?? true,
      itemCode: json['item_code'] as String? ?? '',
      itemName: json['item_name'] as String? ?? '',
      transportedQuantity: (json['transported_quantity'] as num).toDouble(),
      uom: json['uom'] as String? ?? '',
      transportOrderId: json['transport_order_id'] as String,
      transportOrderNumber: json['transport_order_number'] as String? ?? '',
      transportStatus: json['transport_status'] as String? ?? '',
      routeCode: json['route_code'] as String?,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      pickupAddress: json['pickup_address'] as String? ?? '',
      deliveryAddress: json['delivery_address'] as String? ?? '',
      carrierName: json['carrier_name'] as String?,
      registrationPlate: json['registration_plate'] as String?,
      vehicleType: json['vehicle_type'] as String?,
      driverName: json['driver_name'] as String?,
      shipmentNumber: json['shipment_number'] as String?,
      shipmentStatus: json['shipment_status'] as String?,
    );
  }
}

class TransportRepository {
  TransportRepository._();
  static final TransportRepository instance = TransportRepository._();

  /// Şirketin araçlarını listeler
  Future<List<VehicleModel>> getVehicles(String companyId) async {
    try {
      final response = await SupabaseService.client
          .from('vehicles')
          .select()
          .eq('company_id', companyId)
          .order('registration_plate', ascending: true);

      return (response as List<dynamic>)
          .map((data) => VehicleModel.fromJson(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Yeni Araç Kaydeder
  Future<String?> registerVehicle({
    required String companyId,
    required String carrierPartyId,
    required String registrationPlate,
    String vehicleType = 'REEFER_TRUCK',
    double capacityPayloadKg = 20000.0,
    double? capacityVolumeCbm,
    bool isTemperatureControlled = true,
    double minTempCelsius = -25.0,
    double maxTempCelsius = 10.0,
  }) async {
    try {
      final tenantId = TenantContext.instance.activeTenantId;
      if (tenantId == null) throw Exception('Aktif tenant seçilmedi.');

      final res = await SupabaseService.client
          .from('vehicles')
          .insert({
            'tenant_id': tenantId,
            'company_id': companyId,
            'carrier_party_id': carrierPartyId,
            'registration_plate': registrationPlate.trim().toUpperCase(),
            'vehicle_type': vehicleType,
            'capacity_payload_kg': capacityPayloadKg,
            'capacity_volume_cbm': capacityVolumeCbm,
            'is_temperature_controlled': isTemperatureControlled,
            'min_temp_celsius': minTempCelsius,
            'max_temp_celsius': maxTempCelsius,
            'status': 'AVAILABLE',
          })
          .select('id')
          .single();

      return res['id'] as String;
    } catch (e) {
      rethrow;
    }
  }

  /// Yeni Sürücü Kaydeder
  Future<String?> registerDriver({
    required String companyId,
    required String carrierPartyId,
    required String fullName,
    required String licenseNumber,
    String? phoneNumber,
    String? nationalId,
  }) async {
    try {
      final tenantId = TenantContext.instance.activeTenantId;
      if (tenantId == null) throw Exception('Aktif tenant seçilmedi.');

      final res = await SupabaseService.client
          .from('drivers')
          .insert({
            'tenant_id': tenantId,
            'company_id': companyId,
            'carrier_party_id': carrierPartyId,
            'full_name': fullName.trim(),
            'license_number': licenseNumber.trim(),
            'phone_number': phoneNumber,
            'national_id': nationalId,
            'status': 'ACTIVE',
          })
          .select('id')
          .single();

      return res['id'] as String;
    } catch (e) {
      rethrow;
    }
  }

  /// Yeni Sevk / Taşıma Emri (Transport Order) Oluşturur
  Future<String?> createTransportOrder({
    required String companyId,
    required String transportOrderNumber,
    String? shipmentId,
    String? exportFileId,
    required String carrierPartyId,
    String? vehicleId,
    String? driverId,
    String pickupLocationType = 'WAREHOUSE',
    String? pickupWarehouseId,
    required String pickupAddress,
    required DateTime pickupTime,
    String deliveryLocationType = 'PORT',
    String? deliveryWarehouseId,
    required String deliveryAddress,
    required DateTime scheduledDeliveryTime,
    String routeCode = 'MEDINA-JEDDAH-EXPRESS',
    String? routeDescription,
    double distanceKm = 420.0,
    String? notes,
  }) async {
    try {
      final tenantId = TenantContext.instance.activeTenantId;
      if (tenantId == null) throw Exception('Aktif tenant seçilmedi.');

      final res = await SupabaseService.client
          .from('transport_orders')
          .insert({
            'tenant_id': tenantId,
            'company_id': companyId,
            'transport_order_number': transportOrderNumber.trim(),
            'shipment_id': shipmentId,
            'export_file_id': exportFileId,
            'carrier_party_id': carrierPartyId,
            'vehicle_id': vehicleId,
            'driver_id': driverId,
            'pickup_location_type': pickupLocationType,
            'pickup_warehouse_id': pickupWarehouseId,
            'pickup_address': pickupAddress,
            'pickup_time': pickupTime.toIso8601String(),
            'delivery_location_type': deliveryLocationType,
            'delivery_warehouse_id': deliveryWarehouseId,
            'delivery_address': deliveryAddress,
            'scheduled_delivery_time': scheduledDeliveryTime.toIso8601String(),
            'route_code': routeCode,
            'route_description': routeDescription,
            'distance_km': distanceKm,
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

  /// Taşıma Emrine Lot ve Ürün Kalemi Ekler
  Future<String?> addTransportOrderItem({
    required String transportOrderId,
    required String lotId,
    required String itemId,
    required double quantity,
    String uom = 'Kg',
    int packageCount = 1,
    int palletCount = 1,
  }) async {
    try {
      final tenantId = TenantContext.instance.activeTenantId;
      if (tenantId == null) throw Exception('Aktif tenant seçilmedi.');

      final res = await SupabaseService.client
          .from('transport_order_items')
          .insert({
            'tenant_id': tenantId,
            'transport_order_id': transportOrderId,
            'lot_id': lotId,
            'item_id': itemId,
            'quantity': quantity,
            'uom': uom,
            'package_count': packageCount,
            'pallet_count': palletCount,
          })
          .select('id')
          .single();

      return res['id'] as String;
    } catch (e) {
      rethrow;
    }
  }

  /// Soğuk Zincir Sıcaklık Sensör Logu Kaydeder
  Future<String?> recordTemperatureLog({
    required String companyId,
    required String
        contextType, // TRANSPORT_ORDER, SHIPMENT, WAREHOUSE, CONTAINER
    String? transportOrderId,
    String? warehouseId,
    String? containerId,
    required double recordedTemperature,
    double targetTemperature = -18.0,
    double minThreshold = -22.0,
    double maxThreshold = -14.0,
    String sensorId = 'SENS-REEFER-01',
    String? notes,
  }) async {
    try {
      final tenantId = TenantContext.instance.activeTenantId;
      if (tenantId == null) throw Exception('Aktif tenant seçilmedi.');

      final res = await SupabaseService.client
          .from('cold_chain_temperature_logs')
          .insert({
            'tenant_id': tenantId,
            'company_id': companyId,
            'context_type': contextType,
            'transport_order_id': transportOrderId,
            'warehouse_id': warehouseId,
            'container_id': containerId,
            'recorded_temperature': recordedTemperature,
            'target_temperature': targetTemperature,
            'min_threshold': minThreshold,
            'max_threshold': maxThreshold,
            'sensor_id': sensorId,
            'notes': notes,
          })
          .select('id')
          .single();

      return res['id'] as String;
    } catch (e) {
      rethrow;
    }
  }

  /// Taşıma Emri Durumunu Günceller
  Future<void> updateTransportStatus({
    required String transportOrderId,
    required String status,
    DateTime? actualDeliveryTime,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (actualDeliveryTime != null) {
        updates['actual_delivery_time'] = actualDeliveryTime.toIso8601String();
      }

      await SupabaseService.client
          .from('transport_orders')
          .update(updates)
          .eq('id', transportOrderId);
    } catch (e) {
      rethrow;
    }
  }

  /// Uçtan Uca Taşıma ve Lot İzlenebilirlik Raporu Getirir
  Future<List<TransportLotTraceabilityModel>> getTransportLotTraceability(
      String transportOrderId) async {
    try {
      final response = await SupabaseService.client
          .from('view_transport_lot_traceability')
          .select()
          .eq('transport_order_id', transportOrderId);

      return (response as List<dynamic>)
          .map((data) => TransportLotTraceabilityModel.fromJson(
              data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
