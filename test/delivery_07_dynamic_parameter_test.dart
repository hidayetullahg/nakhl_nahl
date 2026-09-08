// ==============================================================================
// NAKHL & NAHL — DELIVERY 07: DYNAMIC PARAMETER MANAGEMENT & SCOPES TEST SUITE
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:nakhl_nahl/core/parameter/parameter_scope.dart';
import 'package:nakhl_nahl/core/parameter/parameter_model.dart';
import 'package:nakhl_nahl/services/parameter/dynamic_parameter_service.dart';

void main() {
  setUp(() {
    DynamicParameterService.instance.initializeDefaults();
  });

  group('Delivery 07: Dynamic Parameter Management & Hierarchical Scopes', () {
    test('Default domain parameters are populated on initialization', () {
      final service = DynamicParameterService.instance;
      final accountingParams = service.getParametersByDomain(ParameterDomain.accounting);
      expect(accountingParams.isNotEmpty, isTrue);

      final vatParam = service.getParameter('TAX_DEFAULT_VAT_RATE');
      expect(vatParam, isNotNull);
      expect(vatParam?.domain, equals(ParameterDomain.tax));
    });

    test('Scope priority order strictly adheres to enterprise hierarchy', () {
      expect(ParameterScope.user.priority, greaterThan(ParameterScope.warehouse.priority));
      expect(ParameterScope.warehouse.priority, greaterThan(ParameterScope.businessUnit.priority));
      expect(ParameterScope.businessUnit.priority, greaterThan(ParameterScope.branch.priority));
      expect(ParameterScope.branch.priority, greaterThan(ParameterScope.company.priority));
      expect(ParameterScope.company.priority, greaterThan(ParameterScope.tenant.priority));
      expect(ParameterScope.tenant.priority, greaterThan(ParameterScope.country.priority));
      expect(ParameterScope.country.priority, greaterThan(ParameterScope.global.priority));
    });

    test('User scope overrides company and global scope values', () {
      final service = DynamicParameterService.instance;
      const code = 'ACC_CURRENCY_PRIMARY';

      // 1. Global default is SAR
      final globalVal = service.resolveValue(code);
      expect(globalVal, equals('SAR'));

      // 2. Set company-level override to TRY
      service.setScopedValue(
        parameterCode: code,
        scope: ParameterScope.company,
        scopeId: 'COMP_TURKEY',
        value: 'TRY',
      );

      final compVal = service.resolveValue(code, companyId: 'COMP_TURKEY');
      expect(compVal, equals('TRY'));

      // 3. Set user-level override to USD
      service.setScopedValue(
        parameterCode: code,
        scope: ParameterScope.user,
        scopeId: 'USER_AUDITOR',
        value: 'USD',
      );

      final userVal = service.resolveValue(code, userId: 'USER_AUDITOR', companyId: 'COMP_TURKEY');
      expect(userVal, equals('USD'));
    });

    test('New parameter can be registered dynamically via UI service', () {
      final service = DynamicParameterService.instance;
      const customCode = 'HALAL_EXPIRY_NOTIFICATION_DAYS';

      final customParam = ParameterModel(
        code: customCode,
        name: 'Helal Sertifika Bildirim Günü',
        domain: ParameterDomain.halal,
        dataType: ParameterDataType.number,
        defaultValue: '45',
        description: 'Sertifika bitimine kaç gün kala alarm verileceği',
      );

      service.registerParameter(customParam);
      expect(service.getParameter(customCode), isNotNull);
      expect(service.resolveValue(customCode), equals('45'));
    });
  });
}
