// ==============================================================================
// NAKHL & NAHL — COMMERCIAL BILLING & DATA MIGRATION UNIT TESTS
// File: test/commercial_and_migration_test.dart
// Complies with Master Prompt Sections 133 & Evidence Mandate
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:nakhl_nahl/core/config/app_brand_config.dart';
import 'package:nakhl_nahl/services/billing/module_catalog_service.dart';
import 'package:nakhl_nahl/services/billing/subscription_billing_service.dart';
import 'package:nakhl_nahl/services/migration/data_migration_service.dart';

void main() {
  group('1. AppBrandConfig & White-label Decoupling Tests', () {
    test('Default brand configuration has expected parameters', () {
      final config = AppBrandConfig.current;
      expect(config.productName, equals('NAKHL & NAHL'));
      expect(config.shortName, equals('NAKHL'));
      expect(config.primaryDomain, equals('beeofdate.com'));
      expect(config.supportEmail, equals('support@beeofdate.com'));
      expect(config.salesEmail, equals('sales@beeofdate.com'));
      expect(config.privacyPolicyUrl, contains('beeofdate.com/privacy'));
      expect(config.termsOfServiceUrl, contains('beeofdate.com/terms'));
    });

    test('Custom AppBrandConfig instantiation decouples from defaults', () {
      const customConfig = AppBrandConfig(
        productName: 'AL-HIKMAH ERP',
        shortName: 'HIKMAH',
        companyLegalName: 'Al-Hikmah Software FZCO',
        primaryDomain: 'alhikmah-erp.com',
        supportEmail: 'care@alhikmah-erp.com',
        salesEmail: 'sales@alhikmah-erp.com',
        logoAsset: 'assets/custom_logo.png',
        faviconAsset: 'custom_favicon.png',
        privacyPolicyUrl: 'https://alhikmah-erp.com/privacy',
        termsOfServiceUrl: 'https://alhikmah-erp.com/terms',
        documentationUrl: 'https://alhikmah-erp.com/docs',
        copyrightText: '© 2026 Al-Hikmah Software FZCO',
      );

      expect(customConfig.productName, equals('AL-HIKMAH ERP'));
      expect(customConfig.primaryDomain, equals('alhikmah-erp.com'));
      expect(customConfig.supportEmail, equals('care@alhikmah-erp.com'));
    });
  });

  group('2. Commercial Module Catalog & Multi-Currency Pricing Tests', () {
    test('Catalog contains 18 sellable modular items', () async {
      final catalog = await ModuleCatalogService.instance.getCatalog();
      expect(catalog.length, equals(18));
    });

    test('Core module MOD_CORE is marked isCore and price is free', () async {
      final coreMod =
          await ModuleCatalogService.instance.getModule('MOD_CORE');
      expect(coreMod, isNotNull);
      expect(coreMod!.isCore, isTrue);
      expect(coreMod.category, equals(ModuleCategory.core));

      final sarPrice = coreMod.getPricing('SAR');
      expect(sarPrice?.monthlyPrice, equals(0.0));
      expect(sarPrice?.yearlyPrice, equals(0.0));
    });

    test('Multi-currency pricing returns distinct SAR and TRY amounts',
        () async {
      final accMod =
          await ModuleCatalogService.instance.getModule('MOD_ACCOUNTING');
      expect(accMod, isNotNull);

      final sarPrice = accMod!.getPricing('SAR');
      final tryPrice = accMod.getPricing('TRY');

      expect(sarPrice, isNotNull);
      expect(tryPrice, isNotNull);

      expect(sarPrice!.monthlyPrice, equals(150.0));
      expect(tryPrice!.monthlyPrice, equals(1250.0));
      expect(sarPrice.yearlyPrice, equals(1500.0));
      expect(tryPrice.yearlyPrice, equals(12500.0));
    });

    test('Module dependency checking identifies missing prerequisites', () async {
      final salesMod =
          await ModuleCatalogService.instance.getModule('MOD_SALES');
      expect(salesMod, isNotNull);

      // MOD_SALES depends on MOD_INVENTORY
      final missingWithNone = ModuleCatalogService.instance
          .checkMissingDependencies(salesMod!, ['MOD_CORE']);
      expect(missingWithNone, contains('MOD_INVENTORY'));

      final missingWithInv = ModuleCatalogService.instance
          .checkMissingDependencies(salesMod, ['MOD_CORE', 'MOD_INVENTORY']);
      expect(missingWithInv, isEmpty);
    });

    test('Data Migration module is categorized under MIGRATION', () async {
      final migMod =
          await ModuleCatalogService.instance.getModule('MOD_DATA_MIGRATION');
      expect(migMod, isNotNull);
      expect(migMod!.category, equals(ModuleCategory.migration));
      expect(migMod.isAddon, isTrue);
    });
  });

  group('3. Subscription Lifecycle & Grace Period Logic Tests', () {
    test('MOD_CORE is universally active even without database subscription',
        () async {
      final isEntitled = await SubscriptionBillingService.instance
          .hasActiveModule('MOD_CORE');
      expect(isEntitled, isTrue);
    });

    test('TenantSubscription evaluates isUsable correctly across lifecycle', () {
      final now = DateTime.now();

      // 1. Active subscription
      final activeSub = TenantSubscription(
        id: 'sub-1',
        tenantId: 'tenant-1',
        moduleCode: 'MOD_ACCOUNTING',
        status: SubscriptionStatus.active,
        billingCycle: 'MONTHLY',
        activatedAt: now.subtract(const Duration(days: 5)),
        expiresAt: now.add(const Duration(days: 25)),
        gracePeriodUntil: now.add(const Duration(days: 32)),
      );
      expect(activeSub.isUsable, isTrue);
      expect(activeSub.remainingDays, greaterThan(20));

      // 2. In Grace Period
      final graceSub = TenantSubscription(
        id: 'sub-2',
        tenantId: 'tenant-1',
        moduleCode: 'MOD_PURCHASE',
        status: SubscriptionStatus.grace,
        billingCycle: 'MONTHLY',
        activatedAt: now.subtract(const Duration(days: 32)),
        expiresAt: now.subtract(const Duration(days: 2)),
        gracePeriodUntil: now.add(const Duration(days: 5)),
      );
      expect(graceSub.isUsable, isTrue);
      expect(graceSub.remainingDays, greaterThanOrEqualTo(4));

      // 3. Expired subscription (grace period also passed)
      final expiredSub = TenantSubscription(
        id: 'sub-3',
        tenantId: 'tenant-1',
        moduleCode: 'MOD_SALES',
        status: SubscriptionStatus.expired,
        billingCycle: 'MONTHLY',
        activatedAt: now.subtract(const Duration(days: 40)),
        expiresAt: now.subtract(const Duration(days: 10)),
        gracePeriodUntil: now.subtract(const Duration(days: 3)),
      );
      expect(expiredSub.isUsable, isFalse);
    });
  });

  group('4. Data Migration Engine & Traffic Light Validation Tests', () {
    test('Supported source systems and target entities enums are complete', () {
      expect(MigrationSourceSystem.values.length, greaterThanOrEqualTo(10));
      expect(MigrationSourceSystem.logo.code, equals('LOGO'));
      expect(MigrationSourceSystem.mikro.code, equals('MIKRO'));
      expect(MigrationSourceSystem.excel.code, equals('EXCEL'));

      expect(MigrationTargetEntity.values.length, greaterThanOrEqualTo(6));
      expect(MigrationTargetEntity.customers.code, equals('CUSTOMERS'));
      expect(MigrationTargetEntity.suppliers.code, equals('SUPPLIERS'));
      expect(MigrationTargetEntity.products.code, equals('PRODUCTS'));
    });

    test('Staging row model parses traffic light validation status correctly', () {
      final greenRow = MigrationStagingRow.fromMap({
        'id': 'stg-1',
        'job_id': 'job-1',
        'row_number': 1,
        'external_id': 'C01',
        'raw_payload': {'cari_kod': 'C01', 'unvan': 'Marmara Gıda'},
        'mapped_payload': {'code': 'C01', 'name': 'Marmara Gıda'},
        'validation_status': 'GREEN',
        'validation_messages': [],
      });
      expect(greenRow.validationStatus, equals(ValidationTrafficLight.green));
      expect(greenRow.validationMessages, isEmpty);

      final yellowRow = MigrationStagingRow.fromMap({
        'id': 'stg-2',
        'job_id': 'job-1',
        'row_number': 2,
        'external_id': 'C02',
        'raw_payload': {'unvan': 'İsimsiz Şirket'},
        'mapped_payload': {'name': 'İsimsiz Şirket'},
        'validation_status': 'YELLOW',
        'validation_messages': ['Cari kodu belirtilmemiş (Otomatik atanacak).'],
      });
      expect(yellowRow.validationStatus, equals(ValidationTrafficLight.yellow));
      expect(yellowRow.validationMessages.length, equals(1));

      final redRow = MigrationStagingRow.fromMap({
        'id': 'stg-3',
        'job_id': 'job-1',
        'row_number': 3,
        'external_id': 'ROW_3',
        'raw_payload': {'kod': 'C03'},
        'mapped_payload': {'code': 'C03'},
        'validation_status': 'RED',
        'validation_messages': ['Cari unvanı/adı boş veya geçersiz.'],
      });
      expect(redRow.validationStatus, equals(ValidationTrafficLight.red));
      expect(redRow.validationMessages.first, contains('boş veya geçersiz'));
    });
  });
}
