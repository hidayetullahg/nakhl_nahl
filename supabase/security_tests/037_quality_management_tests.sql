-- ==============================================================================
-- NAKHL & NAHL — FAZ 17 TEST SUITE: QUALITY MANAGEMENT BOUNDED CONTEXT
-- File: supabase/security_tests/037_quality_management_tests.sql
-- Purpose:
-- 1. Quality Specifications & Parameters
-- 2. Incoming Inspection (PASS) -> lot quality_status = APPROVED
-- 3. Warehouse/Final Inspection (FAIL/QUARANTINE) -> lot quality_status = QUARANTINE
-- 4. Quarantine lot sales issue blockage test (trg_prevent_quarantine_lot_issue)
-- 5. Quality Traceability View verification (LOT -> WAREHOUSE -> PROCESS -> SHIPMENT)
-- 6. Audit Logging verification
-- ==============================================================================

DO $$
DECLARE
    v_tenant_id UUID;
    v_company_id UUID;
    v_user_admin UUID;
    v_role_admin UUID;
    v_wh_id UUID;
    v_item_id UUID;
    v_lot_id UUID;
    v_spec_id UUID;
    v_param_humidity UUID;
    v_param_brix UUID;

    v_insp_incoming_id UUID;
    v_insp_warehouse_id UUID;
    v_lot_status VARCHAR(50);
    v_trace_count INT;
    v_audit_count INT;

    v_exception_caught BOOLEAN;
    v_test_count INT := 0;
    v_pass_count INT := 0;
BEGIN
    RAISE NOTICE '====================================================================';
    RAISE NOTICE '=== FAZ 17: QUALITY MANAGEMENT BOUNDED CONTEXT TESTLERİ BAŞLIYOR ===';
    RAISE NOTICE '====================================================================';

    -- 0. KURULUM
    SELECT id INTO v_role_admin FROM roles WHERE code = 'TENANT_ADMIN' AND tenant_id IS NULL LIMIT 1;

    INSERT INTO tenants (code, legal_name, display_name)
    VALUES ('QM_TENANT', 'Quality Management Tenant', 'QMT')
    RETURNING id INTO v_tenant_id;

    INSERT INTO public.users (display_name, email)
    VALUES ('QM Quality Auditor', 'qm_auditor@nakhl-test.com')
    RETURNING id INTO v_user_admin;

    INSERT INTO tenant_users (tenant_id, user_id, role_id, status)
    VALUES (v_tenant_id, v_user_admin, v_role_admin, 'ACTIVE');

    INSERT INTO companies (tenant_id, code, legal_name)
    VALUES (v_tenant_id, 'QM_COMP', 'NAKHL Kalite ve Sertifikasyon A.Ş.')
    RETURNING id INTO v_company_id;

    -- Depo (Negatif stok AÇIK olsun ki negatif stok engeli değil, sadece karantina engeli test edilsin!)
    INSERT INTO warehouses (tenant_id, company_id, code, name, allow_negative_stock)
    VALUES (v_tenant_id, v_company_id, 'DEP-QM-01', 'Medine Kalite Kontrol Deposu', TRUE)
    RETURNING id INTO v_wh_id;

    -- Ürün Master
    INSERT INTO items (
        tenant_id, company_id, item_code, sku, item_name,
        category_name, base_unit, product_type, quality_required
    ) VALUES (
        v_tenant_id, v_company_id, 'HRM-MEB-01', 'SKU-MEB-1KG', 'Mebrûm Medine Hurması',
        'Hurma', 'Kg', 'FINISHED_GOOD', TRUE
    ) RETURNING id INTO v_item_id;

    -- Parti / Lot (Başlangıçta HOLD)
    INSERT INTO item_lots (
        tenant_id, company_id, item_id, lot_number,
        farm_name, country_of_origin, quality_status, halal_certified
    ) VALUES (
        v_tenant_id, v_company_id, v_item_id, 'LOT-MEB-2026-X1',
        'Al-Madinah Palm Gardens', 'SA', 'HOLD', TRUE
    ) RETURNING id INTO v_lot_id;

    -- =========================================================================
    -- ADIM 1: QUALITY SPECIFICATIONS & PARAMETERS
    -- =========================================================================
    v_test_count := v_test_count + 1;
    INSERT INTO quality_specifications (
        tenant_id, company_id, item_id, spec_code, spec_name, version, description
    ) VALUES (
        v_tenant_id, v_company_id, v_item_id, 'SPEC-MEB-EXP', 'Mebrum İhracat Kalite Standardı', '2.0',
        'Avrupa ve Körfez pazarı için A sınıfı Mebrum spesifikasyonu'
    ) RETURNING id INTO v_spec_id;

    INSERT INTO quality_parameters (
        tenant_id, specification_id, parameter_code, parameter_name,
        parameter_type, minimum_value, maximum_value, target_value, uom, is_critical
    ) VALUES (
        v_tenant_id, v_spec_id, 'PARAM-HUMIDITY', 'Nem Oranı',
        'NUMERIC', 16.00, 20.00, 18.00, '%', TRUE
    ) RETURNING id INTO v_param_humidity;

    INSERT INTO quality_parameters (
        tenant_id, specification_id, parameter_code, parameter_name,
        parameter_type, minimum_value, maximum_value, target_value, uom, is_critical
    ) VALUES (
        v_tenant_id, v_spec_id, 'PARAM-BRIX', 'Şeker / Briks Değeri',
        'NUMERIC', 65.00, 80.00, 72.00, 'Brix', FALSE
    ) RETURNING id INTO v_param_brix;

    RAISE NOTICE 'TEST 1: Quality Specifications and Parameters Setup';
    RAISE NOTICE '  EXPECTED: Spec ID and 2 Parameters created';
    RAISE NOTICE '  ACTUAL:   Spec ID = %, Param Humidity = %, Param Brix = %', v_spec_id, v_param_humidity, v_param_brix;

    IF v_spec_id IS NOT NULL AND v_param_humidity IS NOT NULL AND v_param_brix IS NOT NULL THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL';
    END IF;

    -- =========================================================================
    -- ADIM 2: INCOMING INSPECTION (PASS) -> LOT DURUMU: APPROVED
    -- =========================================================================
    v_test_count := v_test_count + 1;
    INSERT INTO quality_inspections (
        tenant_id, company_id, inspection_number, inspection_type,
        item_id, lot_id, warehouse_id, specification_id,
        inspection_date, inspector_user_id, result, action_taken, notes
    ) VALUES (
        v_tenant_id, v_company_id, 'INSP-2026-001', 'INCOMING',
        v_item_id, v_lot_id, v_wh_id, v_spec_id,
        NOW(), v_user_admin, 'PASS', 'Kabul edildi, depoya alındı', 'Giriş kalite kontrolü başarılı'
    ) RETURNING id INTO v_insp_incoming_id;

    SELECT quality_status INTO v_lot_status
    FROM item_lots
    WHERE id = v_lot_id;

    RAISE NOTICE 'TEST 2: Incoming Inspection (PASS) -> Lot Status Sync';
    RAISE NOTICE '  EXPECTED: lot quality_status = APPROVED';
    RAISE NOTICE '  ACTUAL:   lot quality_status = %', v_lot_status;

    IF v_lot_status = 'APPROVED' THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL (Lot durumu APPROVED olmadı!)';
    END IF;

    -- =========================================================================
    -- ADIM 3: WAREHOUSE INSPECTION (FAIL / QUARANTINE) -> LOT DURUMU: QUARANTINE
    -- Rutin depo kontrolünde nem artışı veya bozulma tespit edilir
    -- =========================================================================
    v_test_count := v_test_count + 1;
    INSERT INTO quality_inspections (
        tenant_id, company_id, inspection_number, inspection_type,
        item_id, lot_id, warehouse_id, specification_id,
        inspection_date, inspector_user_id, result, action_taken, notes
    ) VALUES (
        v_tenant_id, v_company_id, 'INSP-2026-002', 'WAREHOUSE',
        v_item_id, v_lot_id, v_wh_id, v_spec_id,
        NOW(), v_user_admin, 'QUARANTINE', 'Karantinaya sevk edildi', 'Soğutucu arızası nedeniyle nem %24 ölçüldü'
    ) RETURNING id INTO v_insp_warehouse_id;

    SELECT quality_status INTO v_lot_status
    FROM item_lots
    WHERE id = v_lot_id;

    RAISE NOTICE 'TEST 3: Warehouse Inspection (QUARANTINE) -> Lot Status Sync';
    RAISE NOTICE '  EXPECTED: lot quality_status = QUARANTINE';
    RAISE NOTICE '  ACTUAL:   lot quality_status = %', v_lot_status;

    IF v_lot_status = 'QUARANTINE' THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL (Lot durumu QUARANTINE olmadı!)';
    END IF;

    -- =========================================================================
    -- ADIM 4: QUARANTINE LOT SALES ISSUE BLOCKAGE (Karantina Çıkış Engeli)
    -- trg_prevent_quarantine_lot_issue tetikleyicisinin testi
    -- =========================================================================
    v_test_count := v_test_count + 1;
    v_exception_caught := FALSE;

    BEGIN
        INSERT INTO stock_ledger_entries (
            tenant_id, company_id, warehouse_id, item_id, lot_id,
            movement_type, quantity, unit, unit_cost, total_cost,
            document_type, document_reference, description, created_by
        ) VALUES (
            v_tenant_id, v_company_id, v_wh_id, v_item_id, v_lot_id,
            'SALE', -10.000, 'Kg', 40.00, 400.00,
            'INVOICE', 'INV-QUAR-01', 'Karantinadaki lottan satış denemesi', v_user_admin
        );
    EXCEPTION WHEN OTHERS THEN
        v_exception_caught := TRUE;
        RAISE NOTICE 'Karantina engelleme mesajı yakalandı: %', SQLERRM;
    END;

    RAISE NOTICE 'TEST 4: Quarantine Lot Sales Deduction Blocking';
    RAISE NOTICE '  EXPECTED: Exception (KARANTİNA ÇIKIŞ ENGELİ)';
    RAISE NOTICE '  ACTUAL:   Exception caught = %', v_exception_caught;

    IF v_exception_caught THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL (Karantinadaki lottan satış çıkışı yapılabildi!)';
    END IF;

    -- =========================================================================
    -- ADIM 5: TRACEABILITY CHAIN (LOT -> WAREHOUSE -> PROCESS -> SHIPMENT)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    SELECT COUNT(*) INTO v_trace_count
    FROM view_lot_traceability_quality
    WHERE lot_id = v_lot_id;

    RAISE NOTICE 'TEST 5: Quality Traceability View Verification';
    RAISE NOTICE '  EXPECTED: trace_count >= 2 (Incoming + Warehouse inspections)';
    RAISE NOTICE '  ACTUAL:   trace_count = %', v_trace_count;

    IF v_trace_count >= 2 THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL (İzlenebilirlik görünümünde muayene kayıtları bulunamadı!)';
    END IF;

    -- =========================================================================
    -- ADIM 6: AUDIT LOG VERIFICATION
    -- =========================================================================
    v_test_count := v_test_count + 1;
    SELECT COUNT(*) INTO v_audit_count
    FROM audit_logs
    WHERE tenant_id = v_tenant_id
      AND entity_type = 'quality_inspection';

    RAISE NOTICE 'TEST 6: Quality Audit Logging Verification';
    RAISE NOTICE '  EXPECTED: audit_count >= 2';
    RAISE NOTICE '  ACTUAL:   audit_count = %', v_audit_count;

    IF v_audit_count >= 2 THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL (Kalite audit kayıtları tutulmadı!)';
    END IF;

    -- =========================================================================
    -- TEST RAPORU
    -- =========================================================================
    RAISE NOTICE '====================================================================';
    RAISE NOTICE '=== FAZ 17 TEST SONUÇLARI: % / % TEST BAŞARIYLA GEÇTİ (PASS)     ===', v_pass_count, v_test_count;
    RAISE NOTICE '====================================================================';

    -- Temizlik (Test verilerini temizle)
    DELETE FROM audit_logs WHERE tenant_id = v_tenant_id;
    DELETE FROM stock_ledger_entries WHERE tenant_id = v_tenant_id;
    DELETE FROM quality_inspection_samples WHERE tenant_id = v_tenant_id;
    DELETE FROM quality_inspections WHERE tenant_id = v_tenant_id;
    DELETE FROM quality_parameters WHERE tenant_id = v_tenant_id;
    DELETE FROM quality_specifications WHERE tenant_id = v_tenant_id;
    DELETE FROM item_lots WHERE tenant_id = v_tenant_id;
    DELETE FROM items WHERE tenant_id = v_tenant_id;
    DELETE FROM warehouses WHERE tenant_id = v_tenant_id;
    DELETE FROM companies WHERE tenant_id = v_tenant_id;
    DELETE FROM tenant_users WHERE tenant_id = v_tenant_id;
    DELETE FROM public.users WHERE id = v_user_admin;
    DELETE FROM tenants WHERE id = v_tenant_id;

    RAISE NOTICE '=== TEST VERİLERİ BAŞARIYLA TEMİZLENDİ ===';
END $$;
