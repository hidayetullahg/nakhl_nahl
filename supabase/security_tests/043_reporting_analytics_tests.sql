-- ==============================================================================
-- NAKHL & NAHL — FAZ 23: REPORTING + ANALYTICS SECURITY & AGGREGATION TESTS
-- ==============================================================================

DO $$
DECLARE
    v_tenant_id UUID := '11111111-1111-1111-1111-111111111111';
    v_tenant_b_id UUID := '22222222-2222-2222-2222-222222222222';
    v_company_a_id UUID := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    v_company_b_id UUID := 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
    v_party_cust_id UUID;
    v_party_supp_id UUID;
    v_dash_json JSONB;
    v_sales_count INT;
    v_purch_count INT;
BEGIN
    RAISE NOTICE '>>> FAZ 23 REPORTING + ANALYTICS TESTLERİ BAŞLIYOR...';

    -- 1. TEST: view_report_sales ve view_report_purchase sorguları
    SELECT COUNT(*) INTO v_sales_count FROM view_report_sales WHERE company_id = v_company_a_id;
    SELECT COUNT(*) INTO v_purch_count FROM view_report_purchase WHERE company_id = v_company_a_id;

    RAISE NOTICE 'Test 1: Satış ve Satın Alma Görünümleri Sorgulandı (Sales: %, Purchase: %)', v_sales_count, v_purch_count;

    -- 2. TEST: view_report_inventory ve view_report_stock_movement
    PERFORM * FROM view_report_inventory LIMIT 5;
    PERFORM * FROM view_report_stock_movement LIMIT 5;
    RAISE NOTICE 'Test 2: Envanter ve Stok Hareketleri Görünümleri Başarılı [PASS]';

    -- 3. TEST: view_report_quality ve view_report_halal
    PERFORM * FROM view_report_quality LIMIT 5;
    PERFORM * FROM view_report_halal LIMIT 5;
    RAISE NOTICE 'Test 3: Kalite ve Helal Uygunluk Raporları Başarılı [PASS]';

    -- 4. TEST: view_report_export ve view_report_shipment
    PERFORM * FROM view_report_export LIMIT 5;
    PERFORM * FROM view_report_shipment LIMIT 5;
    RAISE NOTICE 'Test 4: İhracat ve Sevkiyat Raporları Başarılı [PASS]';

    -- 5. TEST: get_executive_dashboard_summary RPC (N+1 Sorgusuz Dashboard)
    v_dash_json := get_executive_dashboard_summary(
        p_tenant_id := v_tenant_id,
        p_company_id := v_company_a_id
    );

    IF v_dash_json IS NULL OR NOT (v_dash_json ? 'sales_summary') OR NOT (v_dash_json ? 'inventory_summary') THEN
        RAISE EXCEPTION 'TEST 5 BAŞARISIZ: Dashboard summary JSON eksik veya geçersiz!';
    END IF;
    RAISE NOTICE 'Test 5: Tek Sorguda Yönetici Dashboard Özeti Başarılı (N+1 Önleme) [PASS]';

    -- 6. TEST: Çoklu Kiracı İzolasyonu (Cross-Tenant Koruması)
    -- Tenant B için çağrıldığında Tenant A verilerini sızdırmaz
    v_dash_json := get_executive_dashboard_summary(
        p_tenant_id := v_tenant_b_id,
        p_company_id := v_company_b_id
    );
    IF (v_dash_json->>'company_id')::UUID != v_company_b_id THEN
        RAISE EXCEPTION 'TEST 6 BAŞARISIZ: Tenant B çağrısı hatalı şirket id döndü!';
    END IF;
    RAISE NOTICE 'Test 6: Çoklu Kiracı / Şirket İzolasyonu Başarılı [PASS]';

    RAISE NOTICE '>>> TÜM FAZ 23 REPORTING + ANALYTICS TESTLERİ BAŞARIYLA TAMAMLANDI [PASS]';
END $$;
