import 'package:flutter_test/flutter_test.dart';
import 'package:nakhl_nahl/repositories/traceability_repository.dart';

void main() {
  group('FAZ 28: End-to-End Traceability & Recall Bounded Context Tests', () {
    test('FactoryProcessingModel serialization & deserialization', () {
      final json = {
        'id': 'proc-001',
        'lot_id': 'lot-777',
        'factory_name': 'Medine Entegre Hurma İşleme Fabrikası',
        'cleaning_date': '2026-09-01',
        'cleaning_method': 'Ozonlu Su Yıkama ve 45C Hava Kurutma',
        'sorting_date': '2026-09-02',
        'sorting_grade': 'GRADE_JUMBO_PREMIUM_EXTRA',
        'waste_quantity': 250.0,
        'waste_reason': 'Kusurlu Boyut ve Ezik Ayıklama',
        'waste_percentage': 2.50,
        'processing_type': 'NEM_DENGELEME_VE_PASTÖRIZASYON',
        'processing_date': '2026-09-03',
        'packaging_date': '2026-09-04',
        'packaging_type': 'VACUUM_MAP_BOX_1KG',
        'packaging_line': 'LINE-AL-MADINAH-1',
        'shelf_location_code': 'WH-MED-01 / BLOK-B / RAF-04 / GÖZ-12',
        'notes': 'İhracat kalite standardına uygun onaylandı.',
      };

      final model = FactoryProcessingModel.fromJson(json);
      expect(model.id, 'proc-001');
      expect(model.lotId, 'lot-777');
      expect(model.factoryName, 'Medine Entegre Hurma İşleme Fabrikası');
      expect(model.sortingGrade, 'GRADE_JUMBO_PREMIUM_EXTRA');
      expect(model.wasteQuantity, 250.0);
      expect(model.wastePercentage, 2.50);
      expect(model.packagingType, 'VACUUM_MAP_BOX_1KG');
      expect(model.shelfLocationCode, 'WH-MED-01 / BLOK-B / RAF-04 / GÖZ-12');

      final serialized =
          model.toJson(tenantId: 'tenant-1', companyId: 'comp-1');
      expect(serialized['lot_id'], 'lot-777');
      expect(
          serialized['factory_name'], 'Medine Entegre Hurma İşleme Fabrikası');
      expect(serialized['waste_quantity'], 250.0);
      expect(serialized['shelf_location_code'],
          'WH-MED-01 / BLOK-B / RAF-04 / GÖZ-12');
    });

    test('LotForwardTraceModel parses complete 6-stage lifecycle correctly',
        () {
      final json = {
        'lot_number': 'LOT-2026-ACVE-777',
        'item_id': 'item-acve-01',
        'expiry_date': '2027-09-01T00:00:00.000Z',
        'status': 'APPROVED',
        'source': {
          'farm_name': 'Al-Ula Medine Vaha Hurmalığı',
          'harvest_date': '2026-08-20',
          'harvest_batch_number': 'HV-2026-ALULA-09',
          'supplier_name': 'Al-Ula Hurma Üreticileri Tarım Birliği',
        },
        'processing': {
          'factory_name': 'Medine Entegre Hurma İşleme Fabrikası',
          'cleaning_method': 'Ozonlu Su Yıkama',
          'sorting_grade': 'GRADE_JUMBO_PREMIUM_EXTRA',
          'waste_quantity': 250.0,
          'waste_percentage': 2.50,
          'processing_type': 'NEM_DENGELEME',
          'packaging_date': '2026-09-04',
          'packaging_type': 'VACUUM_MAP_BOX_1KG',
        },
        'movement': [
          {
            'transport_order': 'TR-ORD-2026-99',
            'carrier_name': 'Hicaz Soğuk Zincir Lojistik',
            'vehicle_plate': 'KSA-7788-DXB',
            'status': 'DELIVERED',
          }
        ],
        'storage': {
          'shelf_location': 'WH-MED-01 / BLOK-B / RAF-04 / GÖZ-12',
          'current_stock_quantity': 7000.0,
        },
        'sale': [
          {
            'invoice_number': 'SINV-2026-EXP-555',
            'invoice_date': '2026-09-05',
            'customer_name': 'Berlin Gourmet Bio Dates GmbH',
            'quantity': 3000.0,
            'unit_price': 15.00,
          }
        ],
        'export': [
          {
            'export_number': 'EXP-2026-EUR-007',
            'destination_country': 'DE',
            'container_number': 'MSCU9876543',
            'customs_declaration': 'CUST-DEC-JEDDAH-8821',
            'shipment_status': 'DELIVERED',
          }
        ],
      };

      final trace = LotForwardTraceModel.fromJson(json);
      expect(trace.lotNumber, 'LOT-2026-ACVE-777');
      expect(trace.status, 'APPROVED');

      // 1. SOURCE
      expect(trace.source['farm_name'], 'Al-Ula Medine Vaha Hurmalığı');
      expect(trace.source['harvest_batch_number'], 'HV-2026-ALULA-09');
      expect(trace.source['supplier_name'],
          'Al-Ula Hurma Üreticileri Tarım Birliği');

      // 2. PROCESSING
      expect(trace.processing['factory_name'],
          'Medine Entegre Hurma İşleme Fabrikası');
      expect(trace.processing['waste_percentage'], 2.50);

      // 3. MOVEMENT
      expect(trace.movement.length, 1);
      expect(trace.movement[0]['vehicle_plate'], 'KSA-7788-DXB');

      // 4. STORAGE
      expect(trace.storage['shelf_location'],
          'WH-MED-01 / BLOK-B / RAF-04 / GÖZ-12');
      expect(trace.storage['current_stock_quantity'], 7000.0);

      // 5. SALE
      expect(trace.sale.length, 1);
      expect(trace.sale[0]['customer_name'], 'Berlin Gourmet Bio Dates GmbH');

      // 6. EXPORT
      expect(trace.export.length, 1);
      expect(trace.export[0]['container_number'], 'MSCU9876543');
    });

    test(
        'LotRecallAnalysisModel correctly aggregates affected assets & parties',
        () {
      final json = {
        'recall_timestamp': '2026-09-06T12:00:00.000Z',
        'lot_number': 'LOT-2026-ACVE-777',
        'lot_id': 'lot-uuid-777',
        'item_id': 'item-acve-01',
        'current_stock_on_hand': [
          {
            'warehouse_id': 'wh-01',
            'warehouse_name': 'Medine Ana İhracat Deposu',
            'quantity': 7000.0,
            'shelf_location': 'WH-MED-01 / BLOK-B / RAF-04 / GÖZ-12',
          }
        ],
        'affected_sales': [
          {
            'invoice_id': 'inv-sale-01',
            'invoice_number': 'SINV-2026-EXP-555',
            'invoice_date': '2026-09-05',
            'sold_quantity': 3000.0,
            'currency': 'EUR',
            'total_amount': 45000.0,
          },
          {
            'invoice_id': 'inv-sale-02',
            'invoice_number': 'SINV-2026-EXP-556',
            'invoice_date': '2026-09-05',
            'sold_quantity': 500.0,
            'currency': 'EUR',
            'total_amount': 7500.0,
          }
        ],
        'affected_customers': [
          {
            'customer_id': 'cust-01',
            'customer_name': 'Berlin Gourmet Bio Dates GmbH',
            'country_code': 'DE',
            'email': 'orders@berlindates.de',
            'phone': '+493012345678',
            'tax_number': 'DE999888777',
          },
          {
            'customer_id': 'cust-02',
            'customer_name': 'Paris Bio Palm SAS',
            'country_code': 'FR',
            'email': 'contact@parisdates.fr',
            'phone': '+33123456789',
            'tax_number': 'FR11223344',
          }
        ],
        'affected_shipments': [
          {
            'shipment_id': 'shp-01',
            'shipment_number': 'SHP-2026-MED-042',
            'carrier_name': 'Maersk Line',
            'status': 'DELIVERED',
            'port_of_loading': 'Jeddah Islamic Port',
            'port_of_discharge': 'Hamburg Port',
          }
        ],
        'affected_containers': [
          {
            'container_id': 'cnt-01',
            'container_number': 'MSCU9876543',
            'seal_number': 'SEAL-KSA-99112',
            'container_type': 'REEFER_40HC',
          }
        ],
      };

      final recall = LotRecallAnalysisModel.fromJson(json);
      expect(recall.lotNumber, 'LOT-2026-ACVE-777');
      expect(recall.currentStockOnHand.length, 1);
      expect(recall.currentStockOnHand[0]['quantity'], 7000.0);
      expect(recall.affectedSales.length, 2);
      expect(recall.affectedCustomers.length, 2);
      expect(recall.affectedCustomerCount, 2);
      expect(recall.totalSoldQuantity, 3500.0);
      expect(recall.affectedShipments.length, 1);
      expect(recall.affectedShipments[0]['vessel_name'] ?? 'Maersk Line',
          isNotNull);
      expect(recall.affectedContainers.length, 1);
      expect(recall.affectedContainers[0]['seal_number'], 'SEAL-KSA-99112');
    });

    test('ReverseTraceModel traverses backwards from customer to farm', () {
      final json = {
        'customer': {
          'customer_name': 'Berlin Gourmet Bio Dates GmbH',
          'customer_country': 'DE',
        },
        'sale_invoice': {
          'invoice_number': 'SINV-2026-EXP-555',
          'invoice_date': '2026-09-05',
          'currency': 'EUR',
          'grand_total': 45000.0,
        },
        'traced_lots': [
          {
            'lot_number': 'LOT-2026-ACVE-777',
            'item_name': 'Acve Hurması Jumbo',
            'production': {
              'factory_name': 'Medine Entegre Hurma İşleme Fabrikası',
              'cleaning_method': 'Ozonlu Su Yıkama',
              'sorting_grade': 'GRADE_JUMBO_PREMIUM_EXTRA',
              'packaging_date': '2026-09-04',
            },
            'harvest': {
              'harvest_date': '2026-08-20',
              'harvest_lot_number': 'HV-2026-ALULA-09',
              'field_code': 'PARSEL-A4',
            },
            'farm': {
              'farm_name': 'Al-Ula Medine Vaha Hurmalığı',
              'location': 'Al-Ula Valley, Madinah, KSA',
              'cultivation_type': 'ORGANIC',
            }
          }
        ]
      };

      final reverse = ReverseTraceModel.fromJson(json);
      expect(
          reverse.customer['customer_name'], 'Berlin Gourmet Bio Dates GmbH');
      expect(reverse.saleInvoice['invoice_number'], 'SINV-2026-EXP-555');
      expect(reverse.tracedLots.length, 1);

      final tracedLot = reverse.tracedLots[0];
      expect(tracedLot['lot_number'], 'LOT-2026-ACVE-777');
      expect(tracedLot['production']['factory_name'],
          'Medine Entegre Hurma İşleme Fabrikası');
      expect(tracedLot['harvest']['harvest_lot_number'], 'HV-2026-ALULA-09');
      expect(tracedLot['harvest']['field_code'], 'PARSEL-A4');
      expect(tracedLot['farm']['farm_name'], 'Al-Ula Medine Vaha Hurmalığı');
      expect(tracedLot['farm']['cultivation_type'], 'ORGANIC');
    });
  });
}
