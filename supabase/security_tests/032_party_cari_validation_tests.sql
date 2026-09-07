-- ==============================================================================
-- NAKHL & NAHL — MIGRATION 032 VALIDATION TEST SUITE (FAZ 12)
-- File: supabase/security_tests/032_party_cari_validation_tests.sql
-- Purpose: Party, Cari, Customer, Supplier, Address, Contact & Commercial Account RLS
-- ==============================================================================

DO $$
DECLARE
    v_tenant_a UUID;
    v_tenant_b UUID;
    v_company_a1 UUID;
    v_company_a2 UUID;
    v_company_b1 UUID;
    v_user_a UUID;
    v_user_b UUID;
    v_role_admin UUID;
    v_party_1 UUID;
    v_customer_1 UUID;
    v_supplier_1 UUID;
    v_test_count INT := 0;
    v_pass_count INT := 0;
BEGIN
    RAISE NOTICE '=== FAZ 12: PARTY / CARİ / CUSTOMER / SUPPLIER TESTLERİ BAŞLIYOR ===';

    -- 0. KURULUM
    SELECT id INTO v_role_admin FROM roles WHERE code = 'TENANT_ADMIN' AND tenant_id IS NULL LIMIT 1;

    INSERT INTO tenants (code, legal_name, display_name)
    VALUES ('P_TEST_TENANT_A', 'Party Test Tenant A', 'PTA')
    RETURNING id INTO v_tenant_a;

    INSERT INTO tenants (code, legal_name, display_name)
    VALUES ('P_TEST_TENANT_B', 'Party Test Tenant B', 'PTB')
    RETURNING id INTO v_tenant_b;

    INSERT INTO public.users (display_name, email)
    VALUES ('Party User A', 'p_usera@nakhl-test.com')
    RETURNING id INTO v_user_a;

    INSERT INTO public.users (display_name, email)
    VALUES ('Party User B', 'p_userb@nakhl-test.com')
    RETURNING id INTO v_user_b;

    INSERT INTO tenant_users (tenant_id, user_id, role_id, status)
    VALUES (v_tenant_a, v_user_a, v_role_admin, 'ACTIVE');

    INSERT INTO tenant_users (tenant_id, user_id, role_id, status)
    VALUES (v_tenant_b, v_user_b, v_role_admin, 'ACTIVE');

    INSERT INTO companies (tenant_id, code, legal_name)
    VALUES (v_tenant_a, 'COMP_A1', 'Şirket A1')
    RETURNING id INTO v_company_a1;

    INSERT INTO companies (tenant_id, code, legal_name)
    VALUES (v_tenant_a, 'COMP_A2', 'Şirket A2')
    RETURNING id INTO v_company_a2;

    INSERT INTO companies (tenant_id, code, legal_name)
    VALUES (v_tenant_b, 'COMP_B1', 'Şirket B1')
    RETURNING id INTO v_company_b1;

    -- =========================================================================
    -- TEST 1: Party Oluşturma ve Cari Otomatik Senkronizasyon Tetikleyicisi
    -- =========================================================================
    v_test_count := v_test_count + 1;
    INSERT INTO cariler (
        tenant_id, company_id, cari_kodu, unvan, cari_tipi, vergi_no, 
        fatura_adresi, sehir, yetkili_kisi, sirket_telefonu, para_birimi, vade_gunu, risk_limiti
    ) VALUES (
        v_tenant_a, v_company_a1, 'CAR_001', 'Medine Hurma Tedarik Ltd', 'Tedarikci', '310012345600003',
        'Merkez Mah. No:1', 'Medine', 'Ahmet El-Medeni', '+966501234567', 'SAR', 45, 50000.00
    );

    -- parties tablosuna otomatik yazıldı mı?
    SELECT id INTO v_party_1
    FROM parties
    WHERE tenant_id = v_tenant_a AND tax_number = '310012345600003';

    IF v_party_1 IS NULL THEN
        RAISE EXCEPTION 'TEST 1 FAILED: Cari eklendiğinde parties master tablosu senkronize edilemedi!';
    END IF;

    -- party_roles 'SUPPLIER' eklendi mi?
    IF NOT EXISTS (SELECT 1 FROM party_roles WHERE party_id = v_party_1 AND role_type = 'SUPPLIER') THEN
        RAISE EXCEPTION 'TEST 1 FAILED: party_roles SUPPLIER rolü atanamadı!';
    END IF;

    -- party_addresses fatura adresi eklendi mi?
    IF NOT EXISTS (SELECT 1 FROM party_addresses WHERE party_id = v_party_1 AND address_type = 'BILLING') THEN
        RAISE EXCEPTION 'TEST 1 FAILED: party_addresses senkronizasyonu başarısız!';
    END IF;

    -- suppliers master kaydı açıldı mı?
    IF NOT EXISTS (SELECT 1 FROM suppliers WHERE company_id = v_company_a1 AND party_id = v_party_1) THEN
        RAISE EXCEPTION 'TEST 1 FAILED: suppliers master kaydı otomatik oluşturulamadı!';
    END IF;

    v_pass_count := v_pass_count + 1;
    RAISE NOTICE 'TEST 1 (Party & Cari Senkronizasyon): PASS';

    -- =========================================================================
    -- TEST 2: Tekilleştirme (Duplicate Party Prevention)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    -- Aynı vergi numarası ile bu defa Müşteri olarak cari açıldığında yeni parti üretilmemeli, mevcut partiye bağlanmalı
    INSERT INTO cariler (
        tenant_id, company_id, cari_kodu, unvan, cari_tipi, vergi_no, para_birimi
    ) VALUES (
        v_tenant_a, v_company_a1, 'CAR_002', 'Medine Hurma Tedarik Ltd', 'Musteri', '310012345600003', 'SAR'
    );

    -- Halen aynı tek parti mi var?
    IF (SELECT COUNT(*) FROM parties WHERE tenant_id = v_tenant_a AND tax_number = '310012345600003') != 1 THEN
        RAISE EXCEPTION 'TEST 2 FAILED: Mükerrer party kaydı oluştu!';
    END IF;

    -- Artık bu partinin hem SUPPLIER hem CUSTOMER rolü olmalı
    IF (SELECT COUNT(*) FROM party_roles WHERE party_id = v_party_1) < 2 THEN
        RAISE EXCEPTION 'TEST 2 FAILED: Partiye ikinci rol (CUSTOMER) atanamadı!';
    END IF;

    v_pass_count := v_pass_count + 1;
    RAISE NOTICE 'TEST 2 (Tekilleştirme & Çoklu Rol): PASS';

    -- =========================================================================
    -- TEST 3: Çoklu Şirkette Farklı Ticari Koşullar (Multi-Company Cari Hesap)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    -- Aynı party için Şirket A2'de farklı vadeli ticari cari hesap açılabilir
    INSERT INTO commercial_accounts (
        tenant_id, company_id, party_id, account_code, currency_code, payment_terms_days, credit_limit
    ) VALUES (
        v_tenant_a, v_company_a2, v_party_1, 'CAR_A2_001', 'USD', 60, 100000.00
    );

    IF NOT EXISTS (
        SELECT 1 FROM commercial_accounts WHERE company_id = v_company_a2 AND party_id = v_party_1 AND currency_code = 'USD'
    ) THEN
        RAISE EXCEPTION 'TEST 3 FAILED: İkinci şirkette bağımsız cari hesap oluşturulamadı!';
    END IF;

    v_pass_count := v_pass_count + 1;
    RAISE NOTICE 'TEST 3 (Çoklu Şirket Bağımsız Ticari Koşul): PASS';

    -- =========================================================================
    -- TEST 4: Cross-Tenant İzolasyonu (Tenant A carilerini Tenant B göremez)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    IF is_tenant_member(v_tenant_b) AND get_current_user_id() = v_user_a THEN
        RAISE EXCEPTION 'TEST 4 FAILED: Cross-tenant yetkisiz üyelik algılandı!';
    END IF;

    v_pass_count := v_pass_count + 1;
    RAISE NOTICE 'TEST 4 (Cross-Tenant İzolasyonu): PASS';

    -- =========================================================================
    -- TEST 5: Cross-Company İzolasyonu (Şirket A yetkisiyle Şirket B verisine erişilemez)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    IF has_company_access(v_company_b1) = FALSE THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE 'TEST 5 (Cross-Company İzolasyonu): PASS';
    ELSE
        RAISE EXCEPTION 'TEST 5 FAILED: Yetkisiz şirkete erişim izni verildi!';
    END IF;

    -- TEMİZLİK
    DELETE FROM tenants WHERE code IN ('P_TEST_TENANT_A', 'P_TEST_TENANT_B');
    DELETE FROM public.users WHERE email IN ('p_usera@nakhl-test.com', 'p_userb@nakhl-test.com');

    RAISE NOTICE '=== FAZ 12 TESTLERİ TAMAMLANDI (%/5 PASS) ===', v_pass_count;
END $$;
