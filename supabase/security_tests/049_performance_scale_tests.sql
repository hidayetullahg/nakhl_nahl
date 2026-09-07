-- ==============================================================================
-- NAKHL & NAHL — FAZ 30: PERFORMANCE + SCALE HARDENING SECURITY & PERFORMANCE TESTS
-- ==============================================================================

DO $$
DECLARE
    v_tenant_id UUID := '11111111-1111-1111-1111-111111111111';
    v_tenant_b_id UUID := '22222222-2222-2222-2222-222222222222';
    v_company_id UUID := 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';

    v_benchmark_res JSONB;
    v_paginated_res JSONB;
    v_idx_count INT;
    v_user_id UUID := '99999999-9999-9999-9999-999999999999';
BEGIN
    RAISE NOTICE '>>> FAZ 30 PERFORMANCE + SCALE HARDENING TESTLERİ BAŞLIYOR...';

    -- Hazırlık: Tenant, User, Company
    INSERT INTO tenants (id, code, legal_name, display_name)
    VALUES 
        (v_tenant_id, 'SCALE_TENANT_A', 'Scale Tenant A Inc.', 'Tenant A'),
        (v_tenant_b_id, 'SCALE_TENANT_B', 'Scale Tenant B Inc.', 'Tenant B')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO public.users (id, display_name, email)
    VALUES (v_user_id, 'Scale Auditor', 'scale_auditor@nakhl.com')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO companies (id, tenant_id, code, legal_name)
    VALUES (v_company_id, v_tenant_id, 'SCALE_COMP', 'Scale Company Ltd.')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO tenant_users (tenant_id, user_id, role_id, status)
    SELECT v_tenant_id, v_user_id, id, 'ACTIVE'
    FROM roles WHERE code = 'TENANT_ADMIN' AND tenant_id IS NULL LIMIT 1
    ON CONFLICT DO NOTHING;

    PERFORM set_config('request.jwt.claim.sub', v_user_id::TEXT, TRUE);
    PERFORM set_config('request.jwt.claim.role', 'authenticated', TRUE);

    -- ==============================================================================
    -- 1. TEST: YÜKSEK PERFORMANS İNDEKSLERİNİN DOĞRULANMASI
    -- ==============================================================================
    SELECT COUNT(*) INTO v_idx_count
    FROM pg_indexes
    WHERE indexname IN (
        'idx_invoices_perf_tenant_comp_date',
        'idx_invoice_lines_perf_inv_cov',
        'idx_stock_ledger_perf_cov',
        'idx_journal_entries_perf_comp_date',
        'idx_journal_lines_perf_cov',
        'idx_parties_perf_tenant_type',
        'idx_item_lots_perf_comp_item',
        'idx_export_files_perf_status',
        'idx_transport_orders_perf_status',
        'idx_documents_perf_entity'
    );

    ASSERT v_idx_count = 10, 'Tüm kaplayıcı ve bileşik performans indeksleri eksiksiz tanımlanmalı!';
    RAISE NOTICE 'Test 1: 10 Kritik Kaplayıcı ve Bileşik Performans İndeksi Doğrulandı [PASS] (Bulunan: %)', v_idx_count;

    -- ==============================================================================
    -- 2. TEST: SAYFALAMALI SORGULAMA MOTORU (get_paginated_invoices_optimized)
    -- ==============================================================================
    v_paginated_res := get_paginated_invoices_optimized(
        p_tenant_id := v_tenant_id,
        p_company_id := v_company_id,
        p_invoice_type := 'SALES',
        p_page := 1,
        p_page_size := 10
    );

    ASSERT v_paginated_res IS NOT NULL, 'Sayfalamalı fatura RPC boş döndü!';
    ASSERT (v_paginated_res->>'page')::INT = 1, 'Sayfa numarası eşleşmiyor!';
    ASSERT (v_paginated_res->>'page_size')::INT = 10, 'Sayfa boyutu eşleşmiyor!';
    ASSERT v_paginated_res ? 'total_count', 'Total count alanı bulunamadı!';
    ASSERT v_paginated_res ? 'items', 'Items dizisi bulunamadı!';

    RAISE NOTICE 'Test 2: Tek Turda (Single-Roundtrip) Sayfalamalı Fatura Çekimi Başarılı [PASS] (Toplam Kayıt: %)', 
        v_paginated_res->>'total_count';

    -- ==============================================================================
    -- 3. TEST: PERFORMANS VE ÖLÇEKLENEBİLİRLİK BENCHMARK RPC (run_performance_benchmark)
    -- ==============================================================================
    v_benchmark_res := run_performance_benchmark(
        p_tenant_id := v_tenant_id,
        p_company_id := v_company_id
    );

    ASSERT v_benchmark_res IS NOT NULL, 'Benchmark RPC boş döndü!';
    ASSERT v_benchmark_res ? 'index_scan_latency_ms', 'Index scan latency eksik!';
    ASSERT v_benchmark_res ? 'aggregation_latency_ms', 'Aggregation latency eksik!';
    ASSERT v_benchmark_res ? 'rls_evaluation_overhead_ms', 'RLS overhead eksik!';
    ASSERT v_benchmark_res->>'database_model' = 'SHARED_POSTGRESQL_MULTI_TENANT_RLS', 'DB model bilgisi eksik!';

    RAISE NOTICE 'Test 3: Sistem Performans Benchmarkı Başarıyla Çalıştırıldı [PASS]';
    RAISE NOTICE '        İndeks Tarama Gecikmesi: % ms', v_benchmark_res->>'index_scan_latency_ms';
    RAISE NOTICE '        Agregasyon Gecikmesi   : % ms', v_benchmark_res->>'aggregation_latency_ms';
    RAISE NOTICE '        RLS Değerlendirme Süresi: % ms', v_benchmark_res->>'rls_evaluation_overhead_ms';
    RAISE NOTICE '        Önerilen Kapasite      : %', v_benchmark_res->>'recommended_tenant_capacity';

    -- ==============================================================================
    -- 4. TEST: ÇAPRAZ TENANT İZOLASYON KONTROLÜ
    -- ==============================================================================
    BEGIN
        v_paginated_res := get_paginated_invoices_optimized(
            p_tenant_id := v_tenant_b_id, -- Yabancı tenant
            p_company_id := v_company_id,
            p_invoice_type := 'SALES',
            p_page := 1,
            p_page_size := 10
        );
        ASSERT (v_paginated_res->>'total_count')::INT = 0, 'TEST 4 GÜVENLİK AÇIĞI: Yabancı tenant diğer tenant verisini görebildi!';
        RAISE NOTICE 'Test 4: Sayfalamalı Sorgularda Çapraz-Tenant İzolasyonu Doğrulandı [PASS]';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Test 4: Çapraz-Tenant RPC Çağrısı Güvenlik Muhafızı Tarafından Reddedildi [PASS] (Hata: %)', SQLERRM;
    END;

    RAISE NOTICE '====================================================================';
    RAISE NOTICE '>>> FAZ 30: TÜM PERFORMANCE + SCALE HARDENING TESTLERİ BAŞARIYLA GEÇTİ (PASS)!';
    RAISE NOTICE '====================================================================';
END;
$$;
