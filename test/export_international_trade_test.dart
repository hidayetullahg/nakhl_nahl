import 'package:flutter_test/flutter_test.dart';
import 'package:nakhl_nahl/repositories/export_repository.dart';

void main() {
  group('FAZ 19: Export / International Trade Bounded Context Unit Tests', () {
    test('ExportFileModel parsing and CIF calculation', () {
      final exportMap = {
        'id': 'exp-file-001',
        'export_number': 'EXP-2026-TR-001',
        'customer_party_id': 'party-cust-001',
        'sales_order_id': 'so-exp-001',
        'origin_country_code': 'SA',
        'destination_country_code': 'TR',
        'origin_port': 'Cidde İslam Limanı (KSA)',
        'destination_port': 'Mersin Uluslararası Limanı (TR)',
        'incoterm': 'CIF',
        'currency_code': 'USD',
        'fob_value': 115000.0,
        'freight_value': 8500.0,
        'insurance_value': 1500.0,
        'cif_value': 125000.0,
        'status': 'CONFIRMED',
        'notes': 'Acve Hurması İhracat Dosyası',
        'created_at': '2026-09-06T10:00:00.000Z',
      };

      final exportFile = ExportFileModel.fromJson(exportMap);
      expect(exportFile.exportNumber, 'EXP-2026-TR-001');
      expect(exportFile.incoterm, 'CIF');
      expect(exportFile.cifValue, 125000.0);
      expect(
          exportFile.fobValue +
              exportFile.freightValue +
              exportFile.insuranceValue,
          exportFile.cifValue);
      expect(exportFile.status, 'CONFIRMED');
    });

    test('ExportItemModel parsing and Lot Traceability with HS Code', () {
      final itemMap = {
        'id': 'exp-item-001',
        'export_file_id': 'exp-file-001',
        'item_id': 'item-ajwa-01',
        'lot_id': 'lot-exp-2026-001',
        'hs_code': '0804.10.00.00',
        'quantity': 20000.0,
        'uom': 'Kg',
        'unit_price': 5.75,
        'total_price': 115000.0,
        'net_weight_kg': 20000.0,
        'gross_weight_kg': 21200.0,
        'pallet_count': 20,
        'package_count': 2000,
      };

      final exportItem = ExportItemModel.fromJson(itemMap);
      expect(exportItem.lotId, 'lot-exp-2026-001');
      expect(exportItem.hsCode, '0804.10.00.00');
      expect(exportItem.quantity, 20000.0);
      expect(exportItem.totalPrice, 115000.0);
      expect(exportItem.palletCount, 20);
    });

    test('CustomsDeclarationModel parsing and duty valuation', () {
      final customsMap = {
        'id': 'customs-001',
        'export_file_id': 'exp-file-001',
        'declaration_number': 'GCB-2026-JED-94812',
        'declaration_date': '2026-09-06',
        'customs_office': 'Cidde Liman Gümrük Müdürlüğü (ZATCA)',
        'hs_code': '0804.10.00.00',
        'country_of_origin': 'SA',
        'customs_value': 115000.0,
        'currency_code': 'USD',
        'duties_and_taxes': 0.0,
        'clearance_date': '2026-09-06',
        'status': 'CLEARED',
        'notes': 'Yeşil hat çıkış izni',
      };

      final customs = CustomsDeclarationModel.fromJson(customsMap);
      expect(customs.declarationNumber, 'GCB-2026-JED-94812');
      expect(customs.status, 'CLEARED');
      expect(customs.countryOfOrigin, 'SA');
      expect(customs.customsValue, 115000.0);
    });

    test('ExportContainerModel and ExportDocumentModel parsing', () {
      final containerMap = {
        'id': 'cnt-001',
        'export_file_id': 'exp-file-001',
        'shipment_id': 'shp-001',
        'container_number': 'MSKU-948123-0',
        'seal_number': 'SEAL-ZATCA-98124',
        'container_type': '40_REEFER',
        'tare_weight_kg': 4600.0,
        'gross_weight_kg': 25800.0,
        'volume_cbm': 67.5,
        'temperature_setting_celsius': -18.0,
        'is_active': true,
      };

      final container = ExportContainerModel.fromJson(containerMap);
      expect(container.containerNumber, 'MSKU-948123-0');
      expect(container.containerType, '40_REEFER');
      expect(container.temperatureSettingCelsius, -18.0);
      expect(container.isActive, isTrue);

      final docMap = {
        'id': 'doc-001',
        'export_file_id': 'exp-file-001',
        'shipment_id': 'shp-001',
        'document_type': 'BILL_OF_LADING',
        'document_number': 'MSK-MED-TR-098234',
        'issue_date': '2026-09-06',
        'document_url': 'https://docs.nakhl.com/bl.pdf',
        'is_verified': true,
      };

      final doc = ExportDocumentModel.fromJson(docMap);
      expect(doc.documentType, 'BILL_OF_LADING');
      expect(doc.documentNumber, 'MSK-MED-TR-098234');
      expect(doc.isVerified, isTrue);
    });

    test('ExportLotTraceabilityModel full chain verification', () {
      final traceMap = {
        'export_file_id': 'exp-file-001',
        'export_number': 'EXP-2026-TR-001',
        'export_status': 'DELIVERED',
        'incoterm': 'CIF',
        'origin_port': 'Cidde',
        'destination_port': 'Mersin',
        'customer_trade_name': 'Anadolu Hurma TR',
        'item_code': 'EXP-AJW-01',
        'item_name': 'Acve Medine Hurması',
        'hs_code': '0804.10.00.00',
        'export_quantity': 20000.0,
        'uom': 'Kg',
        'lot_id': 'lot-001',
        'lot_number': 'LOT-EXP-2026-001',
        'farm_name': 'Al-Ula Medine Vaha Çiftliği',
        'harvest_date': '2026-08-25',
        'quality_status': 'APPROVED',
        'halal_certified': true,
        'customs_declaration_no': 'GCB-2026-JED-94812',
        'customs_status': 'CLEARED',
        'container_number': 'MSKU-948123-0',
        'seal_number': 'SEAL-ZATCA-98124',
        'container_type': '40_REEFER',
        'temperature_setting_celsius': -18.0,
        'shipment_number': 'SHP-2026-EXP-001',
        'shipment_status': 'DELIVERED',
        'transport_mode': 'SEA',
        'vessel_or_plate': 'MSC PALOMA',
        'bill_of_lading_no': 'MSK-MED-TR-098234',
        'departure_date': '2026-09-06',
        'actual_arrival_date': '2026-09-17',
      };

      final trace = ExportLotTraceabilityModel.fromJson(traceMap);
      expect(trace.exportNumber, 'EXP-2026-TR-001');
      expect(trace.lotNumber, 'LOT-EXP-2026-001');
      expect(trace.hsCode, '0804.10.00.00');
      expect(trace.containerNumber, 'MSKU-948123-0');
      expect(trace.shipmentStatus, 'DELIVERED');
      expect(trace.halalCertified, isTrue);
      expect(trace.qualityStatus, 'APPROVED');
    });
  });
}
