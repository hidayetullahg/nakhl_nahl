-- ==============================================================================
-- NAKHL & NAHL — FAZ 31: PRODUCTION SECURITY HARDENING TESTS
-- ==============================================================================

DO $$
DECLARE
    v_audit_res JSONB;
    v_sanitized TEXT;
    v_unprotected_count INT;
    v_unforced_count INT;
BEGIN
    RAISE NOTICE '>>> FAZ 31 PRODUCTION SECURITY HARDENING TESTLERİ BAŞLIYOR...';

    -- ==============================================================================
    -- 1. TEST: GÜVENLİK DENETİM TARAMASI (run_security_audit_scan)
    -- ==============================================================================
    v_audit_res := run_security_audit_scan();
    ASSERT v_audit_res IS NOT NULL, 'Güvenlik taraması boş döndü!';
    
    RAISE NOTICE 'Test 1: Güvenlik Denetim Taraması Sonuçları:';
    RAISE NOTICE '        CRITICAL Güvenlik Açığı Sayısı: %', v_audit_res->'vulnerabilities'->>'CRITICAL';
    RAISE NOTICE '        HIGH Güvenlik Açığı Sayısı    : %', v_audit_res->'vulnerabilities'->>'HIGH';
    RAISE NOTICE '        MEDIUM Güvenlik Açığı Sayısı  : %', v_audit_res->'vulnerabilities'->>'MEDIUM';
    RAISE NOTICE '        Uyumluluk Durumu              : %', v_audit_res->>'compliance_status';

    ASSERT (v_audit_res->'vulnerabilities'->>'CRITICAL')::INT = 0, 'CRITICAL güvenlik açığı bulundu!';
    ASSERT (v_audit_res->'vulnerabilities'->>'HIGH')::INT = 0, 'HIGH güvenlik açığı bulundu!';
    ASSERT (v_audit_res->'vulnerabilities'->>'MEDIUM')::INT = 0, 'MEDIUM güvenlik açığı bulundu!';
    ASSERT v_audit_res->>'compliance_status' = 'HARDENED_PRODUCTION_READY', 'Sistem HARDENED_PRODUCTION_READY olmalı!';

    -- ==============================================================================
    -- 2. TEST: TÜM TABLOLARDA RLS ENABLE & FORCE KONTROLÜ
    -- ==============================================================================
    SELECT COUNT(*) INTO v_unprotected_count
    FROM pg_tables t
    JOIN pg_class c ON c.relname = t.tablename
    JOIN pg_namespace n ON n.oid = c.relnamespace AND n.nspname = 'public'
    WHERE t.schemaname = 'public'
      AND c.relrowsecurity = FALSE
      AND t.tablename NOT LIKE 'pg_%'
      AND t.tablename NOT LIKE 'sql_%';

    SELECT COUNT(*) INTO v_unforced_count
    FROM pg_tables t
    JOIN pg_class c ON c.relname = t.tablename
    JOIN pg_namespace n ON n.oid = c.relnamespace AND n.nspname = 'public'
    WHERE t.schemaname = 'public'
      AND c.relforcerowsecurity = FALSE
      AND t.tablename NOT LIKE 'pg_%'
      AND t.tablename NOT LIKE 'sql_%';

    ASSERT v_unprotected_count = 0, 'RLS etkin olmayan tablo bulundu!';
    ASSERT v_unforced_count = 0, 'RLS FORCE edilmemiş tablo bulundu!';
    RAISE NOTICE 'Test 2: Şema Çapında Tüm Tablolarda RLS ENABLE ve FORCE Doğrulandı [PASS]';

    -- ==============================================================================
    -- 3. TEST: GİRDİ TEMİZLEME VE ENJEKSİYON SAVUNMASI
    -- ==============================================================================
    v_sanitized := sanitize_input_text('Normal TextInjected');
    ASSERT v_sanitized = 'Normal TextInjected', 'Girdi temizleme doğrulaması başarısız!';
    RAISE NOTICE 'Test 3: Girdi Temizleme (Sanitization) Doğrulandı [PASS]';

    -- ==============================================================================
    -- 4. TEST: CLIENT SECRETS İZOLASYON KONTROLÜ
    -- ==============================================================================
    ASSERT (v_audit_res->'secrets_audit'->>'service_role_leaked_to_client')::BOOLEAN = FALSE, 'service_role sızıntısı var!';
    ASSERT (v_audit_res->'secrets_audit'->>'database_credentials_exposed')::BOOLEAN = FALSE, 'Veritabanı credential sızıntısı var!';
    RAISE NOTICE 'Test 4: Client Secrets ve service_role İzolasyonu Doğrulandı [PASS]';

    RAISE NOTICE '====================================================================';
    RAISE NOTICE '>>> FAZ 31: TÜM PRODUCTION SECURITY HARDENING TESTLERİ BAŞARIYLA GEÇTİ (PASS)!';
    RAISE NOTICE '====================================================================';
END;
$$;
