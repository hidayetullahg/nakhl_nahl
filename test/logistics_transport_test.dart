import 'package:flutter_test/flutter_test.dart';
import 'package:nakhl_nahl/repositories/transport_repository.dart';

void main() {
  group('FAZ 20: Logistics / Transport Bounded Context Unit Tests', () {
    test('VehicleModel parsing and cold chain capabilities', () {
      final vehicleMap = {
        'id': 'veh-001',
        'carrier_party_id': 'carrier-001',
        'registration_plate': '4321-JED',
        'vehicle_type': 'REEFER_TRUCK',
        'capacity_payload_kg': 22000.0,
        'capacity_volume_cbm': 65.0,
        'is_temperature_controlled': true,
        'min_temp_celsius': -25.0,
        'max_temp_celsius': 10.0,
        'status': 'AVAILABLE',
      };

      final vehicle = VehicleModel.fromJson(vehicleMap);
      expect(vehicle.registrationPlate, '4321-JED');
      expect(vehicle.vehicleType, 'REEFER_TRUCK');
      expect(vehicle.isTemperatureControlled, isTrue);
      expect(vehicle.capacityPayloadKg, 22000.0);
      expect(vehicle.minTempCelsius, -25.0);
      expect(vehicle.maxTempCelsius, 10.0);
    });

    test('DriverModel parsing and licensing', () {
      final driverMap = {
        'id': 'drv-001',
        'carrier_party_id': 'carrier-001',
        'full_name': 'Halid bin Velid Mansur',
        'license_number': 'DL-SA-982145',
        'phone_number': '+966 50 123 4567',
        'national_id': 'NID-108923412',
        'status': 'ACTIVE',
      };

      final driver = DriverModel.fromJson(driverMap);
      expect(driver.fullName, 'Halid bin Velid Mansur');
      expect(driver.licenseNumber, 'DL-SA-982145');
      expect(driver.status, 'ACTIVE');
    });

    test('TransportOrderModel and TransportOrderItemModel parsing', () {
      final orderMap = {
        'id': 'to-001',
        'transport_order_number': 'TO-2026-001',
        'shipment_id': 'shp-001',
        'carrier_party_id': 'carrier-001',
        'vehicle_id': 'veh-001',
        'driver_id': 'drv-001',
        'pickup_location_type': 'WAREHOUSE',
        'pickup_warehouse_id': 'wh-medina-01',
        'pickup_address': 'Medine Soğuk Hava Deposu',
        'pickup_time': '2026-09-06T12:00:00.000Z',
        'delivery_location_type': 'PORT',
        'delivery_warehouse_id': 'wh-jeddah-port',
        'delivery_address': 'Cidde İslam Limanı Rıhtım 5',
        'scheduled_delivery_time': '2026-09-06T18:00:00.000Z',
        'route_code': 'MEDINA-JEDDAH-EXPRESS',
        'route_description': 'Otoyol 15 ve Otoyol 40 Frigo Koridoru',
        'distance_km': 420.0,
        'status': 'DISPATCHED',
        'created_at': '2026-09-06T10:00:00.000Z',
      };

      final order = TransportOrderModel.fromJson(orderMap);
      expect(order.transportOrderNumber, 'TO-2026-001');
      expect(order.distanceKm, 420.0);
      expect(order.status, 'DISPATCHED');
      expect(order.routeCode, 'MEDINA-JEDDAH-EXPRESS');

      final itemMap = {
        'id': 'toi-001',
        'transport_order_id': 'to-001',
        'lot_id': 'lot-sug-001',
        'item_id': 'item-sug-01',
        'quantity': 15000.0,
        'uom': 'Kg',
        'package_count': 3000,
        'pallet_count': 20,
      };

      final item = TransportOrderItemModel.fromJson(itemMap);
      expect(item.lotId, 'lot-sug-001');
      expect(item.quantity, 15000.0);
      expect(item.palletCount, 20);
    });

    test('ColdChainLogModel normal vs excursion breach evaluation', () {
      final normalLogMap = {
        'id': 'ccl-001',
        'context_type': 'TRANSPORT_ORDER',
        'transport_order_id': 'to-001',
        'recorded_temperature': -18.2,
        'target_temperature': -18.0,
        'min_threshold': -22.0,
        'max_threshold': -14.0,
        'is_breached': false,
        'severity': 'NORMAL',
        'sensor_id': 'SENS-REEFER-01',
        'recorded_at': '2026-09-06T14:00:00.000Z',
      };

      final normalLog = ColdChainLogModel.fromJson(normalLogMap);
      expect(normalLog.recordedTemperature, -18.2);
      expect(normalLog.isBreached, isFalse);
      expect(normalLog.severity, 'NORMAL');

      // Sapma (Excursion) Ölçümü: -8.5°C (-14.0°C sınırını aştı!)
      final breachLogMap = {
        'id': 'ccl-002',
        'context_type': 'TRANSPORT_ORDER',
        'transport_order_id': 'to-001',
        'recorded_temperature': -8.5,
        'target_temperature': -18.0,
        'min_threshold': -22.0,
        'max_threshold': -14.0,
        'is_breached': true,
        'severity': 'CRITICAL_EXCURSION',
        'sensor_id': 'SENS-REEFER-01',
        'recorded_at': '2026-09-06T15:30:00.000Z',
      };

      final breachLog = ColdChainLogModel.fromJson(breachLogMap);
      expect(breachLog.recordedTemperature, -8.5);
      expect(breachLog.isBreached, isTrue);
      expect(breachLog.severity, 'CRITICAL_EXCURSION');
    });

    test('TransportLotTraceabilityModel full logistics chain verification', () {
      final traceMap = {
        'transport_item_id': 'toi-001',
        'lot_id': 'lot-001',
        'lot_number': 'LOT-TRP-2026-001',
        'farm_name': 'Vadi-i Akik Medine Çiftliği',
        'harvest_date': '2026-08-30',
        'quality_status': 'APPROVED',
        'halal_certified': true,
        'item_code': 'TRP-SUG-01',
        'item_name': 'Sugai Medine Hurması',
        'transported_quantity': 15000.0,
        'uom': 'Kg',
        'transport_order_id': 'to-001',
        'transport_order_number': 'TO-2026-001',
        'transport_status': 'DELIVERED',
        'route_code': 'MEDINA-JEDDAH-EXPRESS',
        'distance_km': 420.0,
        'pickup_address': 'Medine Hurma Soğuk Hava Deposu',
        'delivery_address': 'Cidde İslam Limanı Reefer Terminali',
        'carrier_name': 'Kızıldeniz Frigofirik Nakliyat',
        'registration_plate': '4321-JED',
        'vehicle_type': 'REEFER_TRUCK',
        'driver_name': 'Halid bin Velid Mansur',
        'shipment_number': 'SHP-TRP-2026-001',
        'shipment_status': 'DELIVERED',
      };

      final trace = TransportLotTraceabilityModel.fromJson(traceMap);
      expect(trace.lotNumber, 'LOT-TRP-2026-001');
      expect(trace.registrationPlate, '4321-JED');
      expect(trace.driverName, 'Halid bin Velid Mansur');
      expect(trace.transportStatus, 'DELIVERED');
      expect(trace.shipmentStatus, 'DELIVERED');
      expect(trace.halalCertified, isTrue);
    });
  });
}
