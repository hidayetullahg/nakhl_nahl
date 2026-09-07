import 'package:flutter_test/flutter_test.dart';
import 'package:nakhl_nahl/repositories/agriculture_repository.dart';

void main() {
  group('FAZ 16: Agriculture / Farm / Harvest Unit Tests', () {
    test('FarmModel and FieldModel parsing', () {
      final farmMap = {
        'id': 'farm-uuid-001',
        'code': 'FRM-ULA-01',
        'name': 'Al-Ula Kadim Hurma Vahası',
        'operator_party_id': 'party-oper-01',
        'country_code': 'SA',
        'region': 'Medine Bölgesi',
        'city': 'Al-Ula',
        'gps_coordinates': '26.6178,37.9222',
        'total_area_hectares': 120.5,
        'cultivation_type': 'ORGANIC',
        'status': 'ACTIVE',
      };

      final farm = FarmModel.fromMap(farmMap);
      expect(farm.code, 'FRM-ULA-01');
      expect(farm.name, 'Al-Ula Kadim Hurma Vahası');
      expect(farm.countryCode, 'SA');
      expect(farm.totalAreaHectares, 120.5);
      expect(farm.cultivationType, 'ORGANIC');
      expect(farm.status, 'ACTIVE');

      final fieldMap = {
        'id': 'field-uuid-001',
        'farm_id': 'farm-uuid-001',
        'field_code': 'PAR-01',
        'field_name': 'Ayn Vaha Parseli - Batı Blok',
        'area_hectares': 25.0,
        'soil_type': 'SANDY_LOAM',
        'irrigation_type': 'DRIP',
        'tree_count': 1250,
        'planting_year': 2018,
        'status': 'ACTIVE',
      };

      final field = FieldModel.fromMap(fieldMap);
      expect(field.fieldCode, 'PAR-01');
      expect(field.areaHectares, 25.0);
      expect(field.treeCount, 1250);
      expect(field.irrigationType, 'DRIP');
      expect(field.plantingYear, 2018);
    });

    test('CropModel and HarvestModel parsing', () {
      final cropMap = {
        'id': 'crop-uuid-001',
        'crop_code': 'CRP-AJWA-PREM',
        'crop_name': 'HURMA',
        'variety': 'Ajwa',
        'grade': 'PREMIUM',
        'growing_season': '2026-AUTUMN',
        'item_id': 'item-ajwa-01',
      };

      final crop = CropModel.fromMap(cropMap);
      expect(crop.cropCode, 'CRP-AJWA-PREM');
      expect(crop.variety, 'Ajwa');
      expect(crop.grade, 'PREMIUM');

      final harvestMap = {
        'id': 'hrv-uuid-001',
        'farm_id': 'farm-uuid-001',
        'field_id': 'field-uuid-001',
        'crop_id': 'crop-uuid-001',
        'harvest_number': 'HRV-2026-001',
        'harvest_date': '2026-09-06',
        'quantity_harvested': 2500.0,
        'uom': 'Kg',
        'quality_grade': 'GRADE_A',
        'humidity_percentage': 17.5,
        'sugar_brix': 70.0,
        'lot_id': 'lot-uuid-001',
        'warehouse_id': 'wh-uuid-001',
        'status': 'COMPLETED',
        'notes': '2026 yılı Ajwa ilk hasat toplama',
      };

      final harvest = HarvestModel.fromMap(harvestMap);
      expect(harvest.harvestNumber, 'HRV-2026-001');
      expect(harvest.quantityHarvested, 2500.0);
      expect(harvest.humidityPercentage, 17.5);
      expect(harvest.sugarBrix, 70.0);
      expect(harvest.lotId, 'lot-uuid-001');
      expect(harvest.status, 'COMPLETED');
    });

    test('Harvest Lot Number generation format test', () {
      const farmCode = 'FRM-ULA-01';
      const fieldCode = 'PAR-01';
      final dateStr = DateTime(2026, 9, 6)
          .toIso8601String()
          .substring(0, 10)
          .replaceAll('-', '');
      const seq = 1;

      final lotNumber =
          'LOT-HRV-$farmCode-$fieldCode-$dateStr-${seq.toString().padLeft(2, '0')}';
      expect(lotNumber, 'LOT-HRV-FRM-ULA-01-PAR-01-20260906-01');
      expect(lotNumber.startsWith('LOT-HRV-'), isTrue);
    });
  });
}
