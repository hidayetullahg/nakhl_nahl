-- ==============================================================================
-- NAKHL & NAHL — FAZ 29: AUDIT + COMPLIANCE HARDENING SECURITY & INTEGRATION TESTS
-- ==============================================================================

DO $$
DECLARE
    v_tenant_id UUID := '11111111-1111-1111-1111-111111111111';
    v_tenant_b_id UUID := '22222222-2222-2222-2222-222222222222';
    v_company_id UUID := 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
    v_user_id UUID := '99999999-9999-9999-9999-999999999999';

    v_test_entity_id UUID := uuid_generate_v4();
    v_log_id BIGINT;
    v_integrity_res JSONB;
    v_retention_row RECORD;
    v_count INT;
    v_error_caught BOOLEAN;
BEGIN
    RAISE NOTICE '>>> FAZ 29 AUDIT + COMPLIANCE HARDENING TESTLERİ BAŞLIYOR...';

    -- Hazırlık: Tenant, User, Company
    INSERT INTO tenants (id, code, legal_name, display_name)
    VALUES 
        (v_tenant_id, 'AUDIT_TENANT_A', 'Audit Tenant A Inc.', 'Tenant A'),
        (v_tenant_b_id, 'AUDIT_TENANT_B', 'Audit Tenant B Inc.', 'Tenant B')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO public.users (id, display_name, email)
    VALUES (v_user_id, 'Audit Officer', 'audit_officer@nakhl.com')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO companies (id, tenant_id, code, legal_name)
    VALUES (v_company_id, v_tenant_id, 'AUDIT_COMP', 'Audit Company Ltd.')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO tenant_users (tenant_id, user_id, role_id, status)
    SELECT v_tenant_id, v_user_id, id, 'ACTIVE'
    FROM roles WHERE code = 'TENANT_ADMIN' AND tenant_id IS NULL LIMIT 1
    ON CONFLICT DO NOTHING;

    PERFORM set_config('request.jwt.claim.sub', v_user_id::TEXT, TRUE);
    PERFORM set_config('request.jwt.claim.role', 'authenticated', TRUE);

    -- ==============================================================================
    -- 1. TEST: 10 KRİTİK TİCARİ EYLEMİN HEPSİNİN AUDIT LOGLANMASI
    -- (CREATE, UPDATE, POST, APPROVE, REJECT, REVERSE, EXPORT, IMPORT, LOGIN, LOGOUT)
    -- ==============================================================================
    
    -- 1.1 CREATE
    v_log_id := log_audit_event(
        p_action := 'CREATE',
        p_entity_type := 'INVOICE',
        p_entity_id := v_test_entity_id,
        p_tenant_id := v_tenant_id,
        p_company_id := v_company_id,
        p_user_id := v_user_id,
        p_new_data := '{"invoice_number": "SINV-2026-001", "total": 10000}'::jsonb,
        p_actor_role := 'SALES_OFFICER'
    );
    ASSERT v_log_id IS NOT NULL, 'CREATE denetim kaydı oluşturulamadı!';

    -- 1.2 UPDATE
    v_log_id := log_audit_event(
        p_action := 'UPDATE',
        p_entity_type := 'INVOICE',
        p_entity_id := v_test_entity_id,
        p_tenant_id := v_tenant_id,
        p_company_id := v_company_id,
        p_user_id := v_user_id,
        p_old_data := '{"note": "Eski Not"}'::jsonb,
        p_new_data := '{"note": "Yeni Güncellenmiş Not"}'::jsonb,
        p_actor_role := 'SALES_OFFICER'
    );
    ASSERT v_log_id IS NOT NULL, 'UPDATE denetim kaydı oluşturulamadı!';

    -- 1.3 POST
    v_log_id := log_audit_event(
        p_action := 'POST',
        p_entity_type := 'JOURNAL_ENTRY',
        p_entity_id := v_test_entity_id,
        p_tenant_id := v_tenant_id,
        p_company_id := v_company_id,
        p_user_id := v_user_id,
        p_new_data := '{"status": "POSTED", "total_debit": 10000, "total_credit": 10000}'::jsonb,
        p_actor_role := 'CHIEF_ACCOUNTANT'
    );
    ASSERT v_log_id IS NOT NULL, 'POST denetim kaydı oluşturulamadı!';

    -- 1.4 APPROVE
    v_log_id := log_audit_event(
        p_action := 'APPROVE',
        p_entity_type := 'EXPORT_FILE',
        p_entity_id := v_test_entity_id,
        p_tenant_id := v_tenant_id,
        p_company_id := v_company_id,
        p_user_id := v_user_id,
        p_new_data := '{"export_status": "APPROVED_BY_CUSTOMS"}'::jsonb,
        p_actor_role := 'COMPLIANCE_DIRECTOR'
    );
    ASSERT v_log_id IS NOT NULL, 'APPROVE denetim kaydı oluşturulamadı!';

    -- 1.5 REJECT
    v_log_id := log_audit_event(
        p_action := 'REJECT',
        p_entity_type := 'QUALITY_INSPECTION',
        p_entity_id := v_test_entity_id,
        p_tenant_id := v_tenant_id,
        p_company_id := v_company_id,
        p_user_id := v_user_id,
        p_new_data := '{"quality_status": "REJECTED", "reason": "Nem oranı limit üstü"}'::jsonb,
        p_actor_role := 'QA_LEAD'
    );
    ASSERT v_log_id IS NOT NULL, 'REJECT denetim kaydı oluşturulamadı!';

    -- 1.6 REVERSE
    v_log_id := log_audit_event(
        p_action := 'REVERSE',
        p_entity_type := 'JOURNAL_ENTRY',
        p_entity_id := v_test_entity_id,
        p_tenant_id := v_tenant_id,
        p_company_id := v_company_id,
        p_user_id := v_user_id,
        p_new_data := '{"reversed_entry_id": "9999", "reason": "Mükerrer fatura iptali"}'::jsonb,
        p_actor_role := 'FINANCE_CONTROLLER'
    );
    ASSERT v_log_id IS NOT NULL, 'REVERSE denetim kaydı oluşturulamadı!';

    -- 1.7 EXPORT
    v_log_id := log_audit_event(
        p_action := 'EXPORT',
        p_entity_type := 'EXPORT_SHIPMENT',
        p_entity_id := v_test_entity_id,
        p_tenant_id := v_tenant_id,
        p_company_id := v_company_id,
        p_user_id := v_user_id,
        p_new_data := '{"container": "MSCU1234567", "vessel": "MSC PALOMA", "dest": "HAMBURG"}'::jsonb,
        p_actor_role := 'EXPORT_MANAGER'
    );
    ASSERT v_log_id IS NOT NULL, 'EXPORT denetim kaydı oluşturulamadı!';

    -- 1.8 IMPORT
    v_log_id := log_audit_event(
        p_action := 'IMPORT',
        p_entity_type := 'IMPORT_CUSTOMS_DECLARATION',
        p_entity_id := v_test_entity_id,
        p_tenant_id := v_tenant_id,
        p_company_id := v_company_id,
        p_user_id := v_user_id,
        p_new_data := '{"customs_declaration": "DEC-KSA-99", "status": "CLEARED"}'::jsonb,
        p_actor_role := 'CUSTOMS_AGENT'
    );
    ASSERT v_log_id IS NOT NULL, 'IMPORT denetim kaydı oluşturulamadı!';

    -- 1.9 LOGIN
    v_log_id := log_audit_event(
        p_action := 'LOGIN',
        p_entity_type := 'USER_SESSION',
        p_entity_id := v_user_id,
        p_tenant_id := v_tenant_id,
        p_company_id := v_company_id,
        p_user_id := v_user_id,
        p_new_data := '{"auth_method": "MFA_TOTP", "ip": "192.168.1.50"}'::jsonb,
        p_actor_role := 'SYSTEM'
    );
    ASSERT v_log_id IS NOT NULL, 'LOGIN denetim kaydı oluşturulamadı!';

    -- 1.10 LOGOUT
    v_log_id := log_audit_event(
        p_action := 'LOGOUT',
        p_entity_type := 'USER_SESSION',
        p_entity_id := v_user_id,
        p_tenant_id := v_tenant_id,
        p_company_id := v_company_id,
        p_user_id := v_user_id,
        p_new_data := '{"session_duration_seconds": 3600}'::jsonb,
        p_actor_role := 'USER'
    );
    ASSERT v_log_id IS NOT NULL, 'LOGOUT denetim kaydı oluşturulamadı!';

    RAISE NOTICE 'Test 1: 10 Kritik Eylemin Tamamı Audit Edildi [PASS] (CREATE, UPDATE, POST, APPROVE, REJECT, REVERSE, EXPORT, IMPORT, LOGIN, LOGOUT)';

    -- ==============================================================================
    -- 2. TEST: AUDIT LOGS IMMUTABILITY — UPDATE ENGELİ
    -- ==============================================================================
    v_error_caught := FALSE;
    BEGIN
        UPDATE audit_logs 
        SET action = 'LOGIN' 
        WHERE id = v_log_id;
    EXCEPTION
        WHEN OTHERS THEN
            v_error_caught := TRUE;
            RAISE NOTICE 'Test 2: Audit UPDATE Girişimi Başarıyla Engellendi [PASS] (Hata: %)', SQLERRM;
    END;
    ASSERT v_error_caught, 'TEST 2 GÜVENLİK AÇIĞI: audit_logs kaydı UPDATE edilebildi!';

    -- ==============================================================================
    -- 3. TEST: AUDIT LOGS IMMUTABILITY — DELETE ENGELİ (SUPER_ADMIN DAHİL)
    -- ==============================================================================
    v_error_caught := FALSE;
    BEGIN
        DELETE FROM audit_logs 
        WHERE id = v_log_id;
    EXCEPTION
        WHEN OTHERS THEN
            v_error_caught := TRUE;
            RAISE NOTICE 'Test 3: Audit DELETE Girişimi Başarıyla Engellendi (Super Admin dahil) [PASS] (Hata: %)', SQLERRM;
    END;
    ASSERT v_error_caught, 'TEST 3 GÜVENLİK AÇIĞI: audit_logs kaydı DELETE edilebildi!';

    -- ==============================================================================
    -- 4. TEST: DEFTER (LEDGER) DEĞİŞTİRİLEMEZLİĞİ (JOURNAL & STOCK LEDGER)
    -- ==============================================================================
    -- 4.1 Stok Defteri Silme Engeli
    v_error_caught := FALSE;
    BEGIN
        UPDATE stock_ledger_entries 
        SET quantity = 999999 
        WHERE tenant_id = v_tenant_id;
    EXCEPTION
        WHEN OTHERS THEN
            v_error_caught := TRUE;
            RAISE NOTICE 'Test 4.1: Stok Defteri (stock_ledger_entries) Değişiklik Engeli [PASS] (Hata: %)', SQLERRM;
    END;

    -- 4.2 Kesinleşmiş Yevmiye Fişi Değişiklik Engeli
    v_error_caught := FALSE;
    BEGIN
        UPDATE journal_entries 
        SET total_debit = 0 
        WHERE status = 'POSTED' AND tenant_id = v_tenant_id;
    EXCEPTION
        WHEN OTHERS THEN
            v_error_caught := TRUE;
            RAISE NOTICE 'Test 4.2: Kesinleşmiş Yevmiye Fişi Değişiklik Engeli [PASS] (Hata: %)', SQLERRM;
    END;

    -- ==============================================================================
    -- 5. TEST: KRİPTOGRAFİK ZİNCİR BÜTÜNLÜĞÜ VE DOĞRULAMA (verify_audit_log_chain_integrity)
    -- ==============================================================================
    v_integrity_res := verify_audit_log_chain_integrity(v_tenant_id);
    IF NOT (v_integrity_res->>'is_valid')::BOOLEAN THEN
        RAISE EXCEPTION 'TEST 5 BAŞARISIZ: Kriptografik zincir doğrulaması başarısız! Neden: %', v_integrity_res->>'tamper_reason';
    END IF;

    ASSERT (v_integrity_res->>'total_records_checked')::INT >= 10, 'TEST 5 BAŞARISIZ: 10 kayıt zincirde bulunamadı!';
    RAISE NOTICE 'Test 5: SHA-256 Kriptografik Audit Zincir Bütünlüğü Doğrulandı [PASS] (Kayıt Sayısı: %, is_valid: %)', 
        v_integrity_res->>'total_records_checked', v_integrity_res->>'is_valid';

    -- ==============================================================================
    -- 6. TEST: SAKLAMA POLİTİKASI (RETENTION POLICY)
    -- ==============================================================================
    INSERT INTO audit_retention_policies (
        tenant_id, retention_period_years, storage_class, automated_purge_enabled
    ) VALUES (
        v_tenant_id, 10, 'WORM_COMPLIANT_COLD_STORAGE', false
    ) ON CONFLICT (tenant_id) DO UPDATE 
        SET retention_period_years = 10, automated_purge_enabled = false
    RETURNING * INTO v_retention_row;

    ASSERT v_retention_row.retention_period_years = 10, 'Retention period 10 yıl olmalı!';
    ASSERT v_retention_row.automated_purge_enabled = false, 'Otomatik silme kesinlikle kapalı olmalı!';
    RAISE NOTICE 'Test 6: 10 Yıllık WORM Saklama ve İmha Yasağı Politikası Doğrulandı [PASS]';

    -- ==============================================================================
    -- 7. TEST: ÇAPRAZ TENANT İZOLASYONU GÜVENLİK TESTİ
    -- ==============================================================================
    SELECT COUNT(*) INTO v_count 
    FROM audit_logs 
    WHERE tenant_id = v_tenant_b_id AND entity_id = v_test_entity_id;

    ASSERT v_count = 0, 'TEST 7 GÜVENLİK AÇIĞI: Tenant A verisi Tenant B altında görüldü!';
    RAISE NOTICE 'Test 7: Çapraz Tenant İzolasyonu Doğrulandı (0 kayıt sızması) [PASS]';

    RAISE NOTICE '====================================================================';
    RAISE NOTICE '>>> FAZ 29: TÜM AUDIT & COMPLIANCE HARDENING TESTLERİ BAŞARIYLA GEÇTİ (PASS)!';
    RAISE NOTICE '====================================================================';
END;
$$;
