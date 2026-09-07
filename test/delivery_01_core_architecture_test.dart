// ==============================================================================
// NAKHL & NAHL — DELIVERY 1: CORE ARCHITECTURE, AUTH & TENANT SECURITY TEST SUITE
// Tests Core Architecture, Login Flow, User 9-Role Hierarchy, Tenant Isolation,
// and Admin Foundation
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:nakhl_nahl/services/auth_service.dart';
import 'package:nakhl_nahl/core/tenant/tenant_context.dart';

void main() {
  group('1. Delivery 1: Authentication & User 9-Role Hierarchy Tests', () {
    test('KullaniciRolu enum supports all 9 enterprise roles with titles and descriptions', () {
      expect(KullaniciRolu.values.length, equals(9));

      expect(KullaniciRolu.owner.baslik, contains('Owner'));
      expect(KullaniciRolu.admin.baslik, contains('Admin'));
      expect(KullaniciRolu.manager.baslik, contains('Manager'));
      expect(KullaniciRolu.accountant.baslik, contains('Accountant'));
      expect(KullaniciRolu.cashier.baslik, contains('Cashier'));
      expect(KullaniciRolu.warehouse.baslik, contains('Warehouse'));
      expect(KullaniciRolu.sales.baslik, contains('Sales'));
      expect(KullaniciRolu.purchase.baslik, contains('Purchase'));
      expect(KullaniciRolu.viewer.baslik, contains('Viewer'));
    });

    test('KullaniciRolu.fromString string parsing and backward compatibility', () {
      expect(KullaniciRolu.fromString('owner'), equals(KullaniciRolu.owner));
      expect(KullaniciRolu.fromString('admin'), equals(KullaniciRolu.admin));
      expect(KullaniciRolu.fromString('manager'), equals(KullaniciRolu.manager));
      expect(KullaniciRolu.fromString('muhasebe'), equals(KullaniciRolu.accountant));
      expect(KullaniciRolu.fromString('accountant'), equals(KullaniciRolu.accountant));
      expect(KullaniciRolu.fromString('kasiyer'), equals(KullaniciRolu.cashier));
      expect(KullaniciRolu.fromString('cashier'), equals(KullaniciRolu.cashier));
      expect(KullaniciRolu.fromString('depo'), equals(KullaniciRolu.warehouse));
      expect(KullaniciRolu.fromString('warehouse'), equals(KullaniciRolu.warehouse));
      expect(KullaniciRolu.fromString('satis'), equals(KullaniciRolu.sales));
      expect(KullaniciRolu.fromString('satinalma'), equals(KullaniciRolu.purchase));
      expect(KullaniciRolu.fromString('viewer'), equals(KullaniciRolu.viewer));
      expect(KullaniciRolu.fromString(null), equals(KullaniciRolu.admin));
    });

    test('AuthService yetkiVarMi strictly enforces 9-role authorization boundaries', () {
      final auth = AuthService.instance;

      // 1. Owner & Admin have access to everything
      expect(auth.yetkiVarMi('dashboard', KullaniciRolu.owner), isTrue);
      expect(auth.yetkiVarMi('finans', KullaniciRolu.owner), isTrue);
      expect(auth.yetkiVarMi('stok', KullaniciRolu.admin), isTrue);

      // 2. Manager has access to all operational modules
      expect(auth.yetkiVarMi('dashboard', KullaniciRolu.manager), isTrue);
      expect(auth.yetkiVarMi('stok', KullaniciRolu.manager), isTrue);
      expect(auth.yetkiVarMi('satis', KullaniciRolu.manager), isTrue);

      // 3. Accountant has access to finance, sales, purchasing, reports, but NOT warehouse operations directly
      expect(auth.yetkiVarMi('finans', KullaniciRolu.accountant), isTrue);
      expect(auth.yetkiVarMi('rapor', KullaniciRolu.accountant), isTrue);
      expect(auth.yetkiVarMi('sevkiyat', KullaniciRolu.accountant), isFalse);

      // 4. Cashier has access to sales and cash operations
      expect(auth.yetkiVarMi('satis', KullaniciRolu.cashier), isTrue);
      expect(auth.yetkiVarMi('finans', KullaniciRolu.cashier), isTrue);
      expect(auth.yetkiVarMi('stok', KullaniciRolu.cashier), isFalse);

      // 5. Warehouse has access to stock and shipping
      expect(auth.yetkiVarMi('stok', KullaniciRolu.warehouse), isTrue);
      expect(auth.yetkiVarMi('sevkiyat', KullaniciRolu.warehouse), isTrue);
      expect(auth.yetkiVarMi('finans', KullaniciRolu.warehouse), isFalse);

      // 6. Sales representative
      expect(auth.yetkiVarMi('satis', KullaniciRolu.sales), isTrue);
      expect(auth.yetkiVarMi('cari', KullaniciRolu.sales), isTrue);
      expect(auth.yetkiVarMi('finans', KullaniciRolu.sales), isFalse);

      // 7. Purchase representative
      expect(auth.yetkiVarMi('satinalma', KullaniciRolu.purchase), isTrue);
      expect(auth.yetkiVarMi('stok', KullaniciRolu.purchase), isTrue);
      expect(auth.yetkiVarMi('satis', KullaniciRolu.purchase), isFalse);

      // 8. Viewer has read-only access to dashboard and reports
      expect(auth.yetkiVarMi('dashboard', KullaniciRolu.viewer), isTrue);
      expect(auth.yetkiVarMi('rapor', KullaniciRolu.viewer), isTrue);
      expect(auth.yetkiVarMi('finans', KullaniciRolu.viewer), isFalse);
      expect(auth.yetkiVarMi('stok', KullaniciRolu.viewer), isFalse);
    });

    test('KullaniciProfili serialization and PIN code integrity', () {
      const profil = KullaniciProfili(
        uid: 'user-001',
        email: 'admin@nakhlnahl.com',
        adSoyad: 'Bahtiyar Yöneticisi',
        rol: KullaniciRolu.owner,
        pinKodu: '1453',
      );

      final map = profil.toMap();
      expect(map['email'], equals('admin@nakhlnahl.com'));
      expect(map['rol'], equals('owner'));
      expect(map['pinKodu'], equals('1453'));

      final restored = KullaniciProfili.fromMap(map, 'user-001');
      expect(restored.uid, equals('user-001'));
      expect(restored.rol, equals(KullaniciRolu.owner));
      expect(restored.pinKodu, equals('1453'));
    });
  });

  group('2. Delivery 1: Tenant Context & Company Isolation Tests', () {
    setUp(() {
      TenantContext.instance.clearSession();
    });

    tearDown(() {
      TenantContext.instance.clearSession();
    });

    test('TenantContext manages active tenant, company, and user session securely', () {
      final context = TenantContext.instance;
      expect(context.hasTenant, isFalse);
      expect(context.activeTenantId, isNull);

      // Set active session
      context.setSession(userId: 'usr-101', userEmail: 'pilot@nakhlnahl.com');
      context.setActiveTenant(
        tenantId: 'tenant-ksa-01',
        tenantCode: 'KSA-CORP',
        companyId: 'comp-riyadh-01',
        companyName: 'Bahtiyar Hurma ve Gıda A.Ş.',
      );

      expect(context.hasTenant, isTrue);
      expect(context.userId, equals('usr-101'));
      expect(context.userEmail, equals('pilot@nakhlnahl.com'));
      expect(context.activeTenantId, equals('tenant-ksa-01'));
      expect(context.activeTenantCode, equals('KSA-CORP'));
      expect(context.activeCompanyId, equals('comp-riyadh-01'));
      expect(context.activeCompanyName, equals('Bahtiyar Hurma ve Gıda A.Ş.'));

      // Switch company within tenant
      context.setActiveCompany('comp-jeddah-02', 'Cidde Lojistik Şubesi');
      expect(context.activeCompanyId, equals('comp-jeddah-02'));
      expect(context.activeCompanyName, equals('Cidde Lojistik Şubesi'));
      expect(context.activeTenantId, equals('tenant-ksa-01')); // Tenant remains isolated

      // Clear session
      context.clearSession();
      expect(context.hasTenant, isFalse);
      expect(context.userId, isNull);
      expect(context.activeTenantId, isNull);
    });
  });
}
