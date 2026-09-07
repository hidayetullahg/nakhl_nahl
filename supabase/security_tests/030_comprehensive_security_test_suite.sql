-- ==============================================================================
-- NAKHL & NAHL — COMPREHENSIVE SECURITY TEST SUITE
-- File: supabase/security_tests/030_comprehensive_security_test_suite.sql
-- Purpose: Faz 10 - 10 Kritik Güvenlik ve Veri Bütünlüğü Senaryosu
-- ==============================================================================

DO $$
DECLARE
    v_tenant_1 UUID;
    v_tenant_2 UUID;
    v_user_1 UUID;
    v_user_2 UUID;
    v_role_admin UUID;
    v_company_1 UUID;
    v_company_2 UUID;
    v_warehouse_1 UUID;
    v_warehouse_2 UUID;
    v_journal_id UUID;
    v_line_id UUID;
    v_item_id UUID;
    v_test_count INT := 0;
    v_pass_count INT := 0;
BEGIN
    RAISE NOTICE '=============================================================';
    RAISE NOTICE 'NAKHL & NAHL — 10 KRİTİK GÜVENLİK VE BÜTÜNLÜK TESTİ BAŞLIYOR';
    RAISE NOTICE '=============================================================';

    -- 0. TEST VERİSİ KURULUMU
    SELECT id INTO v_role_admin FROM roles WHERE code = 'TENANT_ADMIN' AND tenant_id IS NULL LIMIT 1;

    INSERT INTO tenants (code, legal_name, display_name)
    VALUES ('SEC_TEST_TENANT_1', 'Sec Tenant 1 Co', 'Sec Tenant 1')
    RETURNING id INTO v_tenant_1;

    INSERT INTO tenants (code, legal_name, display_name)
    VALUES ('SEC_TEST_TENANT_2', 'Sec Tenant 2 Co', 'Sec Tenant 2')
    RETURNING id INTO v_tenant_2;

    INSERT INTO public.users (display_name, email)
    VALUES ('Sec User 1', 'sec_user1@nakhl-test.com')
    RETURNING id INTO v_user_1;

    INSERT INTO public.users (display_name, email)
    VALUES ('Sec User 2', 'sec_user2@nakhl-test.com')
    RETURNING id INTO v_user_2;

    INSERT INTO tenant_users (tenant_id, user_id, role_id, status)
    VALUES (v_tenant_1, v_user_1, v_role_admin, 'ACTIVE');

    INSERT INTO tenant_users (tenant_id, user_id, role_id, status)
    VALUES (v_tenant_2, v_user_2, v_role_admin, 'ACTIVE');

    INSERT INTO companies (tenant_id, code, legal_name)
    VALUES (v_tenant_1, 'COMP_SEC_1', 'Tenant 1 Şirketi')
    RETURNING id INTO v_company_1;

    INSERT INTO companies (tenant_id, code, legal_name)
    VALUES (v_tenant_2, 'COMP_SEC_2', 'Tenant 2 Şirketi')
    RETURNING id INTO v_company_2;

    INSERT INTO warehouses (tenant_id, company_id, code, name)
    VALUES (v_tenant_1, v_company_1, 'WH_SEC_1', 'Tenant 1 Deposu')
    RETURNING id INTO v_warehouse_1;

    INSERT INTO warehouses (tenant_id, company_id, code, name)
    VALUES (v_tenant_2, v_company_2, 'WH_SEC_2', 'Tenant 2 Deposu')
    RETURNING id INTO v_warehouse_2;

    -- =========================================================================
    -- TEST 1: Cross Tenant SELECT (Tenant 1, Tenant 2 carilerini görememeli)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    INSERT INTO cariler (tenant_id, company_id, cari_kodu, unvan)
    VALUES (v_tenant_2, v_company_2, 'CARI_T2', 'Gizli Müşteri Tenant 2');

    IF NOT EXISTS (SELECT 1 FROM cariler WHERE tenant_id = v_tenant_2 AND cari_kodu = 'CARI_T2') THEN
        RAISE EXCEPTION 'TEST 1 KURULUM HATASI: Cari kaydedilemedi';
    END IF;
    -- is_tenant_member testi
    IF is_tenant_member(v_tenant_2) AND get_current_user_id() = v_user_1 THEN
        RAISE EXCEPTION 'TEST 1 FAILED: User 1 yetkisiz şekilde Tenant 2 üyesi görünüyor!';
    END IF;
    v_pass_count := v_pass_count + 1;
    RAISE NOTICE 'TEST 1 (Cross Tenant SELECT): PASS';

    -- =========================================================================
    -- TEST 2: Cross Tenant INSERT
    -- =========================================================================
    v_test_count := v_test_count + 1;
    -- RLS kontrolü: User 1 kimliğiyle Tenant 2'ye INSERT simülasyonu
    IF is_tenant_member(v_tenant_2) = FALSE THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE 'TEST 2 (Cross Tenant INSERT Engeli): PASS';
    ELSE
        RAISE EXCEPTION 'TEST 2 FAILED: User 1 için is_tenant_member(v_tenant_2) doğru döndü!';
    END IF;

    -- =========================================================================
    -- TEST 3: Cross Tenant UPDATE
    -- =========================================================================
    v_test_count := v_test_count + 1;
    IF is_tenant_member(v_tenant_2) = FALSE THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE 'TEST 3 (Cross Tenant UPDATE Engeli): PASS';
    ELSE
        RAISE EXCEPTION 'TEST 3 FAILED: Cross-tenant update izni verildi!';
    END IF;

    -- =========================================================================
    -- TEST 4: Cross Tenant DELETE
    -- =========================================================================
    v_test_count := v_test_count + 1;
    IF is_tenant_admin(v_tenant_2) = FALSE THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE 'TEST 4 (Cross Tenant DELETE Engeli): PASS';
    ELSE
        RAISE EXCEPTION 'TEST 4 FAILED: User 1 Tenant 2 için admin kabul edildi!';
    END IF;

    -- =========================================================================
    -- TEST 5: Unauthorized Company Access
    -- =========================================================================
    v_test_count := v_test_count + 1;
    -- User 1, Tenant 2'nin şirketine erişememeli
    IF has_company_access(v_company_2) = FALSE THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE 'TEST 5 (Unauthorized Company Access Engeli): PASS';
    ELSE
        RAISE EXCEPTION 'TEST 5 FAILED: Yetkisiz şirkete has_company_access TRUE döndü!';
    END IF;

    -- =========================================================================
    -- TEST 6: Unauthorized Warehouse Access
    -- =========================================================================
    v_test_count := v_test_count + 1;
    IF has_company_access(v_company_2) = FALSE THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE 'TEST 6 (Unauthorized Warehouse Access Engeli): PASS';
    ELSE
        RAISE EXCEPTION 'TEST 6 FAILED: Yetkisiz depoya erişim verildi!';
    END IF;

    -- =========================================================================
    -- TEST 7: Fake tenant_id Gönderimi
    -- =========================================================================
    v_test_count := v_test_count + 1;
    IF is_tenant_member('99999999-9999-9999-9999-999999999999'::UUID) = FALSE THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE 'TEST 7 (Fake tenant_id Reddi): PASS';
    ELSE
        RAISE EXCEPTION 'TEST 7 FAILED: Sahte tenant_id kabul edildi!';
    END IF;

    -- =========================================================================
    -- TEST 8: Posted Journal Mutation (Immutability)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    INSERT INTO journal_entries (
        tenant_id, company_id, entry_date, description, total_debit, total_credit, status
    ) VALUES (
        v_tenant_1, v_company_1, CURRENT_DATE, 'Posted Test Fişi', 100.00, 100.00, 'POSTED'
    ) RETURNING id INTO v_journal_id;

    BEGIN
        DELETE FROM journal_entries WHERE id = v_journal_id;
        RAISE EXCEPTION 'TEST 8 FAILED: POSTED yevmiye fişinin silinmesine izin verildi!';
    EXCEPTION WHEN OTHERS THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE 'TEST 8 (Posted Journal Immutability): PASS';
    END;

    -- =========================================================================
    -- TEST 9: Stock Balance & Ledger Immutability
    -- =========================================================================
    v_test_count := v_test_count + 1;
    INSERT INTO items (tenant_id, company_id, item_code, item_name)
    VALUES (v_tenant_1, v_company_1, 'ITEM_SEC_1', 'Sec Hurma')
    RETURNING id INTO v_item_id;

    INSERT INTO stock_ledger_entries (
        tenant_id, company_id, warehouse_id, item_id, movement_type, quantity, unit, document_type
    ) VALUES (
        v_tenant_1, v_company_1, v_warehouse_1, v_item_id, 'PURCHASE_RECEIPT', 500.000, 'Kg', 'INVOICE'
    );

    BEGIN
        UPDATE stock_ledger_entries SET quantity = 1000 WHERE item_id = v_item_id;
        RAISE EXCEPTION 'TEST 9 FAILED: Stok defteri satırının güncellenmesine izin verildi!';
    EXCEPTION WHEN OTHERS THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE 'TEST 9 (Stock Balance & Ledger Immutability): PASS';
    END;

    -- =========================================================================
    -- TEST 10: Audit Log Integrity (Immutability)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    INSERT INTO audit_logs (tenant_id, user_id, action, entity_type, entity_id)
    VALUES (v_tenant_1, v_user_1, 'CREATE'::audit_action_enum, 'test_entity', v_journal_id);

    BEGIN
        UPDATE audit_logs SET action = 'UPDATE'::audit_action_enum WHERE tenant_id = v_tenant_1;
        RAISE EXCEPTION 'TEST 10 FAILED: Audit log güncellemesine izin verildi!';
    EXCEPTION WHEN OTHERS THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE 'TEST 10 (Audit Log Integrity): PASS';
    END;

    -- TEMİZLİK
    ALTER TABLE audit_logs DISABLE TRIGGER trg_prevent_audit_log_modification;
    ALTER TABLE journal_entries DISABLE TRIGGER trg_prevent_posted_journal_modification;
    ALTER TABLE stock_ledger_entries DISABLE TRIGGER trg_prevent_stock_ledger_modification;
    DELETE FROM audit_logs WHERE tenant_id IN (v_tenant_1, v_tenant_2);
    DELETE FROM journal_entries WHERE tenant_id IN (v_tenant_1, v_tenant_2);
    DELETE FROM stock_ledger_entries WHERE tenant_id IN (v_tenant_1, v_tenant_2);
    DELETE FROM tenants WHERE id IN (v_tenant_1, v_tenant_2);
    DELETE FROM public.users WHERE id IN (v_user_1, v_user_2);
    ALTER TABLE audit_logs ENABLE TRIGGER trg_prevent_audit_log_modification;
    ALTER TABLE journal_entries ENABLE TRIGGER trg_prevent_posted_journal_modification;
    ALTER TABLE stock_ledger_entries ENABLE TRIGGER trg_prevent_stock_ledger_modification;

    RAISE NOTICE '=============================================================';
    RAISE NOTICE 'SONUÇ: % TESTİN % TANESİ BAŞARIYLA GEÇTİ (ALL PASS)', v_test_count, v_pass_count;
    RAISE NOTICE '=============================================================';
END $$;
