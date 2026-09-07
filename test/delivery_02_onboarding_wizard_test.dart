// ==============================================================================
// NAKHL & NAHL — DELIVERY 2 TEST SUITE: ONBOARDING WIZARD & GLOBAL LOCATION
// Tests:
// 1. 16-Step Dynamic Setup Flow & Navigation
// 2. Global Location Master & Priority Cities Integration (KSA + Turkey + World)
// 3. Country Business Rules Engine (SAR/TRY/AED, VAT rates, Tax IDs)
// 4. 9-Role Enterprise RBAC Selection & Provisioning in AuthService
// 5. Opening Balance Sheet Snapshot & TenantContext Activation
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nakhl_nahl/screens/onboarding/first_time_setup_screen.dart';
import 'package:nakhl_nahl/services/location_service.dart';
import 'package:nakhl_nahl/services/auth_service.dart';
import 'package:nakhl_nahl/services/opening_balance_service.dart';
import 'package:nakhl_nahl/core/tenant/tenant_context.dart';
import 'package:nakhl_nahl/core/address/address_catalog.dart';

void main() {
  group('1. Delivery 2: Country Business Rules & Global Location Tests', () {
    test('LocationService profiles enforce country-specific fiscal rules', () {
      final ksaProfile = LocationService.instance.getBusinessProfile('SA');
      expect(ksaProfile.currencyCode, equals('SAR'));
      expect(ksaProfile.defaultVatRate, equals(15.0));
      expect(ksaProfile.invoiceStandard, equals('ZATCA_PHASE_2'));
      expect(RegExp(ksaProfile.taxNumberValidationRegex).hasMatch('310123456700003'), isTrue);
      expect(RegExp(ksaProfile.taxNumberValidationRegex).hasMatch('1234567890'), isFalse);

      final trProfile = LocationService.instance.getBusinessProfile('TR');
      expect(trProfile.currencyCode, equals('TRY'));
      expect(trProfile.defaultVatRate, equals(20.0));
      expect(trProfile.invoiceStandard, equals('GIB_EFATURA'));
      expect(RegExp(trProfile.taxNumberValidationRegex).hasMatch('1234567890'), isTrue);

      final aeProfile = LocationService.instance.getBusinessProfile('AE');
      expect(aeProfile.currencyCode, equals('AED'));
      expect(aeProfile.defaultVatRate, equals(5.0));
      expect(aeProfile.invoiceStandard, equals('FTA_UAE'));
    });

    test('LocationService supplies priority cities for KSA and Turkey', () async {
      final ksaCities = await LocationService.instance.getCitiesByCountry('SA');
      expect(ksaCities.isNotEmpty, isTrue);
      final ksaNames = ksaCities.map((c) => c.cityNameAscii.toLowerCase()).toList();
      expect(ksaNames, contains('riyadh'));
      expect(ksaNames, contains('jeddah'));
      expect(ksaNames, contains('medina'));

      final trCities = await LocationService.instance.getCitiesByCountry('TR');
      expect(trCities.isNotEmpty, isTrue);
      final trNames = trCities.map((c) => c.cityNameAscii.toLowerCase()).toList();
      expect(trNames, contains('istanbul'));
      expect(trNames, contains('ankara'));
    });

    test('AddressCatalog hierarchically connects region, district, neighborhood', () {
      final saRegions = AddressCatalog.getRegionsByCountry('SA');
      expect(saRegions.isNotEmpty, isTrue);
      expect(saRegions.any((r) => r.name.contains('Riyad') || r.name.contains('Riyadh')), isTrue);

      final riyadhDistricts = AddressCatalog.getDistrictsByCity('Riyadh');
      expect(riyadhDistricts.isNotEmpty, isTrue);

      final trRegions = AddressCatalog.getRegionsByCountry('TR');
      expect(trRegions.isNotEmpty, isTrue);

      final istanbulDistricts = AddressCatalog.getDistrictsByCity('İstanbul');
      expect(istanbulDistricts.isNotEmpty, isTrue);
      expect(istanbulDistricts.any((d) => d.name == 'Kadıköy'), isTrue);
    });
  });

  group('2. Delivery 2: 16-Step Onboarding Wizard Widget Flow', () {
    testWidgets('Renders Step 1 with Multi-Language selection', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: FirstTimeSetupScreen(),
        ),
      );

      // Verify title & progress indicator
      expect(find.text('16 Adımlı ERP Kurulum Sihirbazı (1 / 16)'), findsOneWidget);
      expect(find.text('1. Hangi Dillerde Kullanmak İstiyorsunuz?'), findsOneWidget);
      expect(find.text('Türkçe'), findsWidgets);
      expect(find.text('Yardım Al'), findsOneWidget);
      expect(find.text('Devam Et'), findsOneWidget);
    });

    testWidgets('Navigates through language, script, country, and location steps', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: FirstTimeSetupScreen(),
        ),
      );

      final nextBtn = find.text('Devam Et');

      // Step 1 -> Step 2 (Alfabe / Script)
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();
      expect(find.text('2. Dil Alfabesi ve Yazı Sistemi Seçimi'), findsOneWidget);

      // Step 2 -> Step 3 (Ülke Seçimi)
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();
      expect(find.text('3. Faaliyet Gösterilen Ülkeler'), findsOneWidget);
      expect(find.text('Suudi Arabistan (KSA)'), findsOneWidget);
      expect(find.text('Türkiye'), findsOneWidget);

      // Step 3 -> Step 4 (Bölge)
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();
      expect(find.text('4. Bölge / Eyalet Seçimi'), findsOneWidget);

      // Step 4 -> Step 5 (Şehir)
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();
      expect(find.text('5. Şehir Seçimi (Global Lokasyon Master)'), findsOneWidget);
    });

    testWidgets('Step 15 displays all 9 enterprise roles for selection', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: FirstTimeSetupScreen(),
        ),
      );

      final nextBtn = find.text('Devam Et');

      // Fast-forward to Step 15
      for (int i = 0; i < 14; i++) {
        await tester.tap(nextBtn);
        await tester.pumpAndSettle();
      }

      // Step 15 should be active
      expect(find.text('15. Rol ve Yetkilendirme (RBAC)'), findsOneWidget);

      // Verify presence of enterprise roles
      expect(find.text(KullaniciRolu.owner.baslik), findsOneWidget);
      expect(find.text(KullaniciRolu.admin.baslik), findsOneWidget);
      expect(find.text(KullaniciRolu.manager.baslik), findsOneWidget);
      expect(find.text(KullaniciRolu.accountant.baslik), findsOneWidget);
      expect(find.text(KullaniciRolu.cashier.baslik), findsOneWidget);
      expect(find.text(KullaniciRolu.warehouse.baslik), findsOneWidget);
      expect(find.text(KullaniciRolu.sales.baslik), findsOneWidget);
      expect(find.text(KullaniciRolu.purchase.baslik), findsOneWidget);
      expect(find.text(KullaniciRolu.viewer.baslik), findsOneWidget);

      // Select Accountant role
      await tester.tap(find.text(KullaniciRolu.accountant.baslik));
      await tester.pumpAndSettle();

      // Proceed to Step 16
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      expect(find.text('16. ERP Kurulum Özeti ve Açılış Bilançosu'), findsOneWidget);
      expect(find.text('Sistemi Başlat'), findsOneWidget);
    });
  });

  group('3. Delivery 2: Opening Balance & Tenant Provisioning Verification', () {
    test('OpeningBalanceService records accurate opening financial snapshot', () {
      final service = OpeningBalanceService.instance;

      final snapshot = BusinessSnapshot(
        totalCash: 75000.0,
        totalBank: 250000.0,
        pocketCash: 8000.0,
        totalReceivables: 180000.0,
        totalPayables: 95000.0,
        totalInventoryValue: 420000.0,
        customerCount: 4,
        supplierCount: 3,
        productCount: 15,
        warehouseCount: 2,
        branchCount: 1,
        openingDate: DateTime.now(),
        currency: 'SAR',
      );

      service.saveSnapshot(snapshot);
      final current = service.currentSnapshot;

      expect(current, isNotNull);
      expect(current!.currency, equals('SAR'));
      expect(current.totalCash, equals(75000.0));
      expect(current.totalBank, equals(250000.0));
      expect(current.totalLiquidAssets, equals(333000.0)); // 75k + 250k + 8k
      // Total assets: 75k + 250k + 8k + 180k + 420k = 933,000
      // Net worth: 933,000 - 95,000 = 838,000
      expect(current.netWorth, equals(838000.0));
    });

    test('AuthService and TenantContext synchronize user session upon onboarding completion', () {
      final tenantId = '00000000-0000-0000-0000-000000000001';
      final companyId = '00000000-0000-0000-0000-000000000002';
      final userId = '00000000-0000-0000-0000-000000000003';

      // Simulate step 16 completion
      TenantContext.instance.setActiveTenant(
        tenantId: tenantId,
        tenantCode: 'NNG',
        companyId: companyId,
        companyName: 'NAKHL & NAHL Global Ticaret A.Ş.',
      );

      final profile = KullaniciProfili(
        uid: userId,
        email: 'yonetici@nakhlnahl.com',
        adSoyad: 'Hidayetullah Hoca',
        rol: KullaniciRolu.owner,
        pinKodu: '1234',
        sonGirisTarihi: DateTime.now(),
        olusturmaTarihi: DateTime.now(),
      );

      AuthService.instance.kullaniciProfiliAyarla(profile);

      // Verify TenantContext
      expect(TenantContext.instance.hasTenant, isTrue);
      expect(TenantContext.instance.activeTenantCode, equals('NNG'));
      expect(TenantContext.instance.activeCompanyName, equals('NAKHL & NAHL Global Ticaret A.Ş.'));
      expect(TenantContext.instance.userId, equals(userId));
      expect(TenantContext.instance.userEmail, equals('yonetici@nakhlnahl.com'));

      // Verify AuthService
      final active = AuthService.instance.aktifProfil;
      expect(active, isNotNull);
      expect(active!.adSoyad, equals('Hidayetullah Hoca'));
      expect(active.rol, equals(KullaniciRolu.owner));
      expect(active.pinKodu, equals('1234'));
      expect(AuthService.instance.pinDogrula('1234'), isTrue);
      expect(AuthService.instance.pinDogrula('9999'), isFalse);
      expect(AuthService.instance.yetkiVarMi('finans'), isTrue);
      expect(AuthService.instance.yetkiVarMi('stok'), isTrue);
    });
  });
}
