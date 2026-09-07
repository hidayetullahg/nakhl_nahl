import 'package:flutter_test/flutter_test.dart';
import 'package:nakhl_nahl/repositories/inventory_repository.dart';

void main() {
  group('FAZ 13: Product & Inventory Foundation Unit Tests', () {
    test('Product Master and Item Lot Model parsing', () {
      final itemMap = {
        'id': 'itm-uuid-001',
        'item_code': 'HRM-MDJ-01',
        'sku': 'MDJ-PREM-1KG',
        'barcode': '6281001234567',
        'item_name': 'Medjoul Jumbo Hurma',
        'category_name': 'Hurma',
        'base_unit': 'Kg',
        'sales_uom': 'Kg',
        'purchase_uom': 'Ton',
        'product_type': 'FINISHED_GOOD',
        'traceability_required': true,
        'lot_required': true,
        'halal_required': true,
        'quality_required': true,
        'min_stock_level': 50.0,
        'description': 'Birinci kalite Medine Medjoul hurması',
      };

      final stockItem = StockItem.fromMap(itemMap);
      expect(stockItem.itemCode, 'HRM-MDJ-01');
      expect(stockItem.sku, 'MDJ-PREM-1KG');
      expect(stockItem.barcode, '6281001234567');
      expect(stockItem.productType, 'FINISHED_GOOD');
      expect(stockItem.traceabilityRequired, isTrue);
      expect(stockItem.lotRequired, isTrue);
      expect(stockItem.halalRequired, isTrue);
      expect(stockItem.qualityRequired, isTrue);
      expect(stockItem.minStockLevel, 50.0);

      final lotMap = {
        'id': 'lot-uuid-001',
        'item_id': 'itm-uuid-001',
        'lot_number': 'LOT-2026-MDJ-09',
        'farm_name': 'Al-Ula Oasis Date Farms',
        'harvest_date': '2026-08-01',
        'harvest_batch_number': 'HARV-2026-A1',
        'supplier_party_id': 'party-uuid-99',
        'processing_facility': 'Medina Date Processing Plant #2',
        'processing_date': '2026-08-10',
        'packaging_date': '2026-08-12',
        'packaging_type': 'VACUUM_BOX',
        'temperature_control_required': true,
        'target_storage_temp_celsius': -18.0,
        'country_of_origin': 'SA',
        'production_date': '2026-08-10',
        'expiration_date': '2028-08-10',
        'halal_certified': true,
        'halal_certificate_number': 'HALAL-SA-2026-0988',
        'quality_status': 'APPROVED',
        'notes': 'İhracat kalitesi',
      };

      final lot = ItemLotModel.fromMap(lotMap);
      expect(lot.lotNumber, 'LOT-2026-MDJ-09');
      expect(lot.farmName, 'Al-Ula Oasis Date Farms');
      expect(lot.harvestBatchNumber, 'HARV-2026-A1');
      expect(lot.processingFacility, 'Medina Date Processing Plant #2');
      expect(lot.packagingType, 'VACUUM_BOX');
      expect(lot.temperatureControlRequired, isTrue);
      expect(lot.targetStorageTempCelsius, -18.0);
      expect(lot.halalCertified, isTrue);
      expect(lot.qualityStatus, 'APPROVED');
    });

    test('Inventory Ledger Balance calculation scenario: +100 -20 -30 +5 = 55',
        () {
      // Simulating append-only ledger entries
      final List<Map<String, dynamic>> ledgerEntries = [];

      void addLedgerEntry({
        required String movementType,
        required double quantity,
        required String warehouseId,
      }) {
        final direction = quantity >= 0 ? 'IN' : 'OUT';
        ledgerEntries.add({
          'movement_type': movementType,
          'quantity': quantity,
          'direction': direction,
          'warehouse_id': warehouseId,
        });
      }

      double calculateBalance(String warehouseId) {
        return ledgerEntries
            .where((e) => e['warehouse_id'] == warehouseId)
            .fold<double>(0.0, (sum, e) => sum + (e['quantity'] as double));
      }

      const wh1 = 'WH_MEDINA_1';
      const wh2 = 'WH_JEDDAH_2';

      // 1. PURCHASE: +100
      addLedgerEntry(
          movementType: StockMovementTypes.purchase,
          quantity: 100.0,
          warehouseId: wh1);
      expect(calculateBalance(wh1), 100.0);

      // 2. SALE: -20
      addLedgerEntry(
          movementType: StockMovementTypes.sale,
          quantity: -20.0,
          warehouseId: wh1);
      expect(calculateBalance(wh1), 80.0);

      // 3. TRANSFER: WH1 -> WH2 (30)
      addLedgerEntry(
          movementType: StockMovementTypes.transfer,
          quantity: -30.0,
          warehouseId: wh1);
      addLedgerEntry(
          movementType: StockMovementTypes.transfer,
          quantity: 30.0,
          warehouseId: wh2);
      expect(calculateBalance(wh1), 50.0);
      expect(calculateBalance(wh2), 30.0);

      // 4. RETURN: +5
      addLedgerEntry(
          movementType: StockMovementTypes.returnStock,
          quantity: 5.0,
          warehouseId: wh1);
      expect(calculateBalance(wh1), 55.0);

      // Verify total entries
      expect(ledgerEntries.length, 5);

      // Negative stock validation simulation
      bool canExitWithoutNegative({
        required String warehouseId,
        required double requestedExit,
        required bool allowNegativeStock,
      }) {
        final currentBal = calculateBalance(warehouseId);
        if ((currentBal - requestedExit) < 0) {
          return allowNegativeStock;
        }
        return true;
      }

      // Trying to exit 60 from WH1 (balance: 55) with allow_negative_stock = false
      expect(
        canExitWithoutNegative(
            warehouseId: wh1, requestedExit: 60.0, allowNegativeStock: false),
        isFalse,
      );

      // Trying to exit 60 from WH1 with allow_negative_stock = true
      expect(
        canExitWithoutNegative(
            warehouseId: wh1, requestedExit: 60.0, allowNegativeStock: true),
        isTrue,
      );
    });
  });
}
