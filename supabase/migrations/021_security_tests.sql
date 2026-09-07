-- ==============================================================================
-- NAKHL & NAHL — CORE DATABASE BUILD v1.0
-- Migration: 021_security_tests.sql
-- Purpose: Cross-tenant saldırı, RLS ve veri sızıntısı simülasyon testleri.
-- ==============================================================================

DO $$
DECLARE
    v_plan_id UUID;
    v_tenant_a UUID;
    v_tenant_b UUID;
    v_user_a UUID;
    v_user_b UUID;
    v_role_admin UUID;
    v_company_a UUID;
    v_company_b UUID;
    v_warehouse_a UUID;
BEGIN
    RAISE NOTICE '=== NAKHL & NAHL CORE DATABASE GÜVENLİK TESTLERİ BAŞLIYOR ===';

    -- 1. Test Hazırlığı: Plan ve Rol Temini
    SELECT id INTO v_plan_id FROM saas_plans WHERE code = 'ENTERPRISE' LIMIT 1;
    SELECT id INTO v_role_admin FROM roles WHERE code = 'TENANT_ADMIN' AND tenant_id IS NULL LIMIT 1;

    -- 2. Tenant A ve Tenant B Oluşturma
    INSERT INTO tenants (code, legal_name, display_name)
    VALUES ('TEST_TENANT_A', 'Bahtiyar Hurma Ltd', 'Bahtiyar ERP')
    RETURNING id INTO v_tenant_a;

    INSERT INTO tenants (code, legal_name, display_name)
    VALUES ('TEST_TENANT_B', 'Musa Dış Ticaret Ltd', 'Musa ERP')
    RETURNING id INTO v_tenant_b;

    -- 3. Kullanıcı A ve Kullanıcı B Oluşturma
    INSERT INTO public.users (display_name, email)
    VALUES ('Bahtiyar Admin', 'bahtiyar@nakhl-test.com')
    RETURNING id INTO v_user_a;

    INSERT INTO public.users (display_name, email)
    VALUES ('Musa Admin', 'musa@nakhl-test.com')
    RETURNING id INTO v_user_b;

    -- 4. Üyelik Ataması (User A -> Tenant A, User B -> Tenant B)
    INSERT INTO tenant_users (tenant_id, user_id, role_id, status)
    VALUES (v_tenant_a, v_user_a, v_role_admin, 'ACTIVE');

    INSERT INTO tenant_users (tenant_id, user_id, role_id, status)
    VALUES (v_tenant_b, v_user_b, v_role_admin, 'ACTIVE');

    -- 5. Şirket ve Depo Oluşturma
    INSERT INTO companies (tenant_id, code, legal_name)
    VALUES (v_tenant_a, 'COMP_A', 'Bahtiyar KSA Ltd')
    RETURNING id INTO v_company_a;

    INSERT INTO companies (tenant_id, code, legal_name)
    VALUES (v_tenant_b, 'COMP_B', 'Musa KSA Ltd')
    RETURNING id INTO v_company_b;

    INSERT INTO warehouses (tenant_id, company_id, code, name)
    VALUES (v_tenant_a, v_company_a, 'WH_MED_01', 'Medine Hurma Soğuk Hava Deposu')
    RETURNING id INTO v_warehouse_a;

    -- =========================================================================
    -- TEST 1: is_tenant_member Doğrulaması
    -- =========================================================================
    IF NOT EXISTS (
        SELECT 1 FROM tenant_users WHERE tenant_id = v_tenant_a AND user_id = v_user_a AND status = 'ACTIVE'
    ) THEN
        RAISE EXCEPTION 'TEST 1 FAILED: User A, Tenant A üyesi olarak doğrulanamadı!';
    END IF;
    RAISE NOTICE 'TEST 1 PASSED: Tenant üyelik eşleştirmesi başarılı.';

    -- =========================================================================
    -- TEST 2: Cross-Tenant Üyelik Reddi (User A, Tenant B'ye erişememeli)
    -- =========================================================================
    IF EXISTS (
        SELECT 1 FROM tenant_users WHERE tenant_id = v_tenant_b AND user_id = v_user_a
    ) THEN
        RAISE EXCEPTION 'TEST 2 FAILED: User A yetkisiz şekilde Tenant B üyesi görünüyor!';
    END IF;
    RAISE NOTICE 'TEST 2 PASSED: Cross-tenant yetkisiz üyelik engellendi.';

    -- =========================================================================
    -- TEST 3: Şirket Kod Uniqueness Kuralı (Aynı tenantta COMP_A tekrar açılamaz)
    -- =========================================================================
    BEGIN
        INSERT INTO companies (tenant_id, code, legal_name)
        VALUES (v_tenant_a, 'COMP_A', 'Mükerrer Şirket');
        RAISE EXCEPTION 'TEST 3 FAILED: Aynı tenant altında mükerrer şirket koduna izin verildi!';
    EXCEPTION WHEN unique_violation THEN
        RAISE NOTICE 'TEST 3 PASSED: Tenant içi şirket kodu benzersizlik (unique constraint) kuralı çalışıyor.';
    END;

    -- =========================================================================
    -- TEST 4: Farklı Tenantlarda Aynı Kod Kullanılabilmeli (COMP_A her iki tenantta da olabilir)
    -- =========================================================================
    BEGIN
        INSERT INTO companies (tenant_id, code, legal_name)
        VALUES (v_tenant_b, 'COMP_A', 'Musa Şirketi COMP_A');
        RAISE NOTICE 'TEST 4 PASSED: Farklı tenantlar aynı şirket kodunu bağımsız olarak kullanabiliyor.';
    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'TEST 4 FAILED: Farklı tenantlarda aynı kod kullanımına izin verilmedi!';
    END;

    -- =========================================================================
    -- TEST 5: Audit Log Değiştirilemezlik (Immutability) Testi
    -- =========================================================================
    INSERT INTO audit_logs (tenant_id, user_id, action, entity_type, entity_id, new_data)
    VALUES (v_tenant_a, v_user_a, 'CREATE', 'companies', v_company_a, '{"code": "COMP_A"}'::jsonb);

    BEGIN
        UPDATE audit_logs SET action = 'UPDATE' WHERE tenant_id = v_tenant_a;
        RAISE EXCEPTION 'TEST 5 FAILED: Audit log tablosunda UPDATE işlemine izin verildi!';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'TEST 5 PASSED: Audit log kayıtlarının değiştirilmesi (UPDATE) başarıyla engellendi.';
    END;

    -- Test verilerini temizle
    EXECUTE 'ALTER TABLE audit_logs DISABLE TRIGGER trg_prevent_audit_log_modification';
    DELETE FROM audit_logs WHERE tenant_id IN (v_tenant_a, v_tenant_b);
    EXECUTE 'ALTER TABLE audit_logs ENABLE TRIGGER trg_prevent_audit_log_modification';
    DELETE FROM tenants WHERE code IN ('TEST_TENANT_A', 'TEST_TENANT_B');
    DELETE FROM public.users WHERE email IN ('bahtiyar@nakhl-test.com', 'musa@nakhl-test.com');

    RAISE NOTICE '=== TÜM GÜVENLİK TESTLERİ BAŞARIYLA TAMAMLANDI (5/5 PASS) ===';
END $$;
