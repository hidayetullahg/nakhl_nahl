import 'package:flutter_test/flutter_test.dart';
import 'package:nakhl_nahl/repositories/quality_repository.dart';

void main() {
  group('FAZ 17: Quality Management Bounded Context Unit Tests', () {
    test('QualitySpecificationModel and QualityParameterModel parsing', () {
      final specMap = {
        'id': 'spec-uuid-001',
        'item_id': 'item-mebrum-01',
        'spec_code': 'SPEC-MEB-EXP',
        'spec_name': 'Mebrum İhracat Kalite Standardı',
        'version': '2.0',
        'description': 'Avrupa pazarı ihracat kalite kriterleri',
        'is_active': true,
      };

      final spec = QualitySpecificationModel.fromMap(specMap);
      expect(spec.specCode, 'SPEC-MEB-EXP');
      expect(spec.specName, 'Mebrum İhracat Kalite Standardı');
      expect(spec.version, '2.0');
      expect(spec.isActive, isTrue);

      final paramMap = {
        'id': 'param-uuid-001',
        'specification_id': 'spec-uuid-001',
        'parameter_code': 'PARAM-HUMIDITY',
        'parameter_name': 'Nem Oranı',
        'parameter_type': 'NUMERIC',
        'minimum_value': 16.0,
        'maximum_value': 20.0,
        'target_value': 18.0,
        'uom': '%',
        'is_critical': true,
      };

      final param = QualityParameterModel.fromMap(paramMap);
      expect(param.parameterCode, 'PARAM-HUMIDITY');
      expect(param.minimumValue, 16.0);
      expect(param.maximumValue, 20.0);
      expect(param.targetValue, 18.0);
      expect(param.uom, '%');
      expect(param.isCritical, isTrue);
    });

    test('QualityInspectionModel parsing and result evaluation', () {
      final inspMap = {
        'id': 'insp-uuid-001',
        'inspection_number': 'INSP-2026-001',
        'inspection_type': 'INCOMING',
        'item_id': 'item-mebrum-01',
        'lot_id': 'lot-mebrum-01',
        'warehouse_id': 'wh-medina-01',
        'specification_id': 'spec-uuid-001',
        'inspection_date': '2026-09-06T10:00:00.000Z',
        'inspector_user_id': 'user-auditor-01',
        'result': 'PASS',
        'action_taken': 'Kabul edildi',
        'notes': 'Tüm değerler uygun',
      };

      final inspection = QualityInspectionModel.fromMap(inspMap);
      expect(inspection.inspectionNumber, 'INSP-2026-001');
      expect(inspection.inspectionType, 'INCOMING');
      expect(inspection.result, 'PASS');
      expect(inspection.actionTaken, 'Kabul edildi');

      // Quality Results checklist
      final validResults = ['PASS', 'FAIL', 'CONDITIONAL', 'QUARANTINE'];
      expect(validResults.contains(inspection.result), isTrue);
    });

    test('Quality Parameter Tolerance Range evaluation check', () {
      bool isValueWithinRange({
        required double measured,
        required double min,
        required double max,
      }) {
        return measured >= min && measured <= max;
      }

      // Medjoul humidity standard: 16% - 20%
      const minHum = 16.0;
      const maxHum = 20.0;

      expect(isValueWithinRange(measured: 18.0, min: minHum, max: maxHum),
          isTrue); // PASS
      expect(isValueWithinRange(measured: 15.5, min: minHum, max: maxHum),
          isFalse); // FAIL (Too dry)
      expect(isValueWithinRange(measured: 24.0, min: minHum, max: maxHum),
          isFalse); // FAIL -> QUARANTINE
    });
  });
}
