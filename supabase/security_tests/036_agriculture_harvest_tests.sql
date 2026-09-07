-- ==============================================================================
-- NAKHL & NAHL — FAZ 16 TEST SUITE: AGRICULTURE / FARM / HARVEST
-- File: supabase/security_tests/036_agriculture_harvest_tests.sql
-- Purpose:
-- 1. Farm master setup
-- 2. Field / parsel setup
-- 3. Crop master setup
-- 4. Harvest operation execution
-- 5. Generated Lot number format and item_lots deep traceability link verification
-- 6. Inventory stock ledger entry and view_current_stock verification
-- 7. Zero/negative quantity validation check
-- ==============================================================================

DO $$
DECLARE
    v_tenant_id UUID;
    v_company_id UUID;
    v_user_admin UUID;
    v_role_admin UUID;
    v_wh_id UUID;
    v_item_id UUID;
    v_operator_party UUID;

    v_farm_id UUID;
    v_field_id UUID;
    v_crop_id UUID;

    v_harvest_res JSONB;
    v_harvest_id UUID;
    v_lot_id UUID;
    v_lot_num VARCHAR(100);
    v_current_stock NUMERIC(15,3);

    v_exception_caught BOOLEAN;
    v_test_count INT := 0;
    v_pass_count INT := 0;
BEGIN
    RAISE NOTICE '====================================================================';
    RAISE NOTICE '=== FAZ 16: AGRICULTURE / FARM / HARVEST TESTLERİ BAŞLIYOR       ===';
    RAISE NOTICE '====================================================================';

    -- 0. KURULUM
    SELECT id INTO v_role_admin FROM roles WHERE code = 'TENANT_ADMIN' AND tenant_id IS NULL LIMIT 1;

    INSERT INTO tenants (code, legal_name, display_name)
    VALUES ('AGRI_TENANT', 'Agriculture Test Tenant', 'ATT')
    RETURNING id INTO v_tenant_id;

    INSERT INTO public.users (display_name, email)
    VALUES ('Agri Admin', 'agri_admin@nakhl-test.com')
    RETURNING id INTO v_user_admin;

    INSERT INTO tenant_users (tenant_id, user_id, role_id, status)
    VALUES (v_tenant_id, v_user_admin, v_role_admin, 'ACTIVE');

    INSERT INTO companies (tenant_id, code, legal_name)
    VALUES (v_tenant_id, 'AGRI_COMP', 'NAKHL Organik Tarım A.Ş.')
    RETURNING id INTO v_company_id;

    -- Depo (Medine Soğuk Hava Deposu)
    INSERT INTO warehouses (tenant_id, company_id, code, name, allow_negative_stock)
    VALUES (v_tenant_id, v_company_id, 'DEP-COLD-01', 'Medine Hurma Soğuk Hava Deposu', FALSE)
    RETURNING id INTO v_wh_id;

    -- Ürün Master (Items)
    INSERT INTO items (
        tenant_id, company_id, item_code, sku, item_name,
        category_name, base_unit, product_type
    ) VALUES (
        v_tenant_id, v_company_id, 'HRM-AJW-01', 'SKU-AJW-JUMBO', 'Aclî (Ajwa) Medine Hurması',
        'Hurma', 'Kg', 'FINISHED_GOOD'
    ) RETURNING id INTO v_item_id;

    -- Çiftlik İşletmecisi (Party)
    INSERT INTO parties (tenant_id, code, name, party_type, country_code)
    VALUES (v_tenant_id, 'PRT-OPER-01', 'Medine Hurma Vahaları İşletmesi', 'ORGANIZATION', 'SA')
    RETURNING id INTO v_operator_party;

    -- =========================================================================
    -- ADIM 1: FARM MASTER (ÇİFTLİK TANIMI)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    INSERT INTO farms (
        tenant_id, company_id, code, name, operator_party_id,
        country_code, region, city, total_area_hectares, cultivation_type, status
    ) VALUES (
        v_tenant_id, v_company_id, 'FRM-ULA-01', 'Al-Ula Kadim Hurma Vahası', v_operator_party,
        'SA', 'Medine Bölgesi', 'Al-Ula', 120.50, 'ORGANIC', 'ACTIVE'
    ) RETURNING id INTO v_farm_id;

    RAISE NOTICE 'TEST 1: Farm Master Creation';
    RAISE NOTICE '  EXPECTED: Farm created with code FRM-ULA-01, area = 120.50 ha';
    RAISE NOTICE '  ACTUAL:   Farm ID = %', v_farm_id;

    IF v_farm_id IS NOT NULL THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL';
    END IF;

    -- =========================================================================
    -- ADIM 2: FIELD (PARSEL TANIMI)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    INSERT INTO fields (
        tenant_id, company_id, farm_id, field_code, field_name,
        area_hectares, soil_type, irrigation_type, tree_count, planting_year, status
    ) VALUES (
        v_tenant_id, v_company_id, v_farm_id, 'PAR-01', 'Ayn Vaha Parseli - Batı Blok',
        25.00, 'SANDY_LOAM', 'DRIP', 1250, 2018, 'ACTIVE'
    ) RETURNING id INTO v_field_id;

    RAISE NOTICE 'TEST 2: Field / Parsel Creation';
    RAISE NOTICE '  EXPECTED: Field created with code PAR-01, trees = 1250';
    RAISE NOTICE '  ACTUAL:   Field ID = %', v_field_id;

    IF v_field_id IS NOT NULL THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL';
    END IF;

    -- =========================================================================
    -- ADIM 3: CROP MASTER (MAHSUL / HURMA ÇEŞİDİ)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    INSERT INTO crops (
        tenant_id, crop_code, crop_name, variety, grade, growing_season, item_id
    ) VALUES (
        v_tenant_id, 'CRP-AJWA-PREM', 'HURMA', 'Ajwa', 'PREMIUM', '2026-AUTUMN', v_item_id
    ) RETURNING id INTO v_crop_id;

    RAISE NOTICE 'TEST 3: Crop Master Creation';
    RAISE NOTICE '  EXPECTED: Crop variety = Ajwa, grade = PREMIUM';
    RAISE NOTICE '  ACTUAL:   Crop ID = %', v_crop_id;

    IF v_crop_id IS NOT NULL THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL';
    END IF;

    -- =========================================================================
    -- ADIM 4: HARVEST EXECUTION (HASAT VE OTOMATİK LOT ÜRETİMİ)
    -- FARM -> FIELD -> CROP -> HARVEST -> LOT -> STOCK
    -- =========================================================================
    v_test_count := v_test_count + 1;
    v_harvest_res := process_farm_harvest_atomic(
        p_tenant_id => v_tenant_id,
        p_company_id => v_company_a,
        p_farm_id => v_farm_id,
        p_field_id => v_field_id,
        p_crop_id => v_crop_id,
        p_harvest_number => 'HRV-2026-001',
        p_harvest_date => '2026-09-06'::DATE,
        p_quantity => 2500.000, -- 2,500 Kg hasat
        p_uom => 'Kg',
        p_warehouse_id => v_wh_id,
        p_quality_grade => 'GRADE_A',
        p_humidity_percentage => 17.50,
        p_sugar_brix => 70.00,
        p_notes => '2026 yılı Ajwa ilk hasat toplama',
        p_user_id => v_user_admin
    );

    v_harvest_id := (v_harvest_res->>'harvest_id')::UUID;
    v_lot_id := (v_harvest_res->>'lot_id')::UUID;
    v_lot_num := v_harvest_res->>'lot_number';

    RAISE NOTICE 'TEST 4: Atomic Harvest Operation & Lot Generation';
    RAISE NOTICE '  EXPECTED: success = true, lot_number format LOT-HRV-FRM-ULA-01-PAR-01-20260906-01';
    RAISE NOTICE '  ACTUAL:   success = %, lot_number = %', (v_harvest_res->>'success'), v_lot_num;

    IF (v_harvest_res->>'success')::BOOLEAN = TRUE AND v_lot_num LIKE 'LOT-HRV-%' THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL';
    END IF;

    -- =========================================================================
    -- ADIM 5: TRACEABILITY LINK (İzlenebilirlik Doğrulaması)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    DECLARE
        v_linked_farm_id UUID;
        v_linked_field_id UUID;
        v_linked_harvest_id UUID;
    BEGIN
        SELECT farm_id, field_id, harvest_id INTO v_linked_farm_id, v_linked_field_id, v_linked_harvest_id
        FROM item_lots
        WHERE id = v_lot_id;

        RAISE NOTICE 'TEST 5: Deep Lot Traceability Verification';
        RAISE NOTICE '  EXPECTED: farm_id = %, field_id = %, harvest_id = %', v_farm_id, v_field_id, v_harvest_id;
        RAISE NOTICE '  ACTUAL:   farm_id = %, field_id = %, harvest_id = %', v_linked_farm_id, v_linked_field_id, v_linked_harvest_id;

        IF v_linked_farm_id = v_farm_id AND v_linked_field_id = v_field_id AND v_linked_harvest_id = v_harvest_id THEN
            v_pass_count := v_pass_count + 1;
            RAISE NOTICE '  RESULT:   PASS';
        ELSE
            RAISE EXCEPTION '  RESULT:   FAIL (İzlenebilirlik yabancı anahtar bağlantıları hatalı!)';
        END IF;
    END;

    -- =========================================================================
    -- ADIM 6: INVENTORY STOCK INCREASE (Envanter Stok Artışı)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    SELECT current_quantity INTO v_current_stock
    FROM view_current_stock
    WHERE warehouse_id = v_wh_id AND item_id = v_item_id;

    RAISE NOTICE 'TEST 6: Harvest Stock Ledger Integration (PRODUCTION / IN)';
    RAISE NOTICE '  EXPECTED: current_stock = 2500.000 Kg';
    RAISE NOTICE '  ACTUAL:   current_stock = % Kg', v_current_stock;

    IF v_current_stock = 2500.000 THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL (Stok defterine hasat girişi yansımadı!)';
    END IF;

    -- =========================================================================
    -- ADIM 7: ZERO/NEGATIVE QUANTITY CHECK (Hatalı Miktar Engeli)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    v_exception_caught := FALSE;

    BEGIN
        PERFORM process_farm_harvest_atomic(
            p_tenant_id => v_tenant_id,
            p_company_id => v_company_a,
            p_farm_id => v_farm_id,
            p_field_id => v_field_id,
            p_crop_id => v_crop_id,
            p_harvest_number => 'HRV-FAIL-01',
            p_harvest_date => CURRENT_DATE,
            p_quantity => -50.000, -- Negatif hasat!
            p_uom => 'Kg',
            p_warehouse_id => v_wh_id
        );
    EXCEPTION WHEN OTHERS THEN
        v_exception_caught := TRUE;
    END;

    RAISE NOTICE 'TEST 7: Negative Harvest Quantity Rejection';
    RAISE NOTICE '  EXPECTED: Exception (GEÇERSİZ MİKTAR)';
    RAISE NOTICE '  ACTUAL:   Exception caught = %', v_exception_caught;

    IF v_exception_caught THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL (Negatif hasat kaydedilebildi!)';
    END IF;

    -- =========================================================================
    -- TEST RAPORU
    -- =========================================================================
    RAISE NOTICE '====================================================================';
    RAISE NOTICE '=== FAZ 16 TEST SONUÇLARI: % / % TEST BAŞARIYLA GEÇTİ (PASS)     ===', v_pass_count, v_test_count;
    RAISE NOTICE '====================================================================';

    -- Temizlik (Test verilerini temizle)
    DELETE FROM audit_logs WHERE tenant_id = v_tenant_id;
    DELETE FROM stock_ledger_entries WHERE tenant_id = v_tenant_id;
    DELETE FROM harvests WHERE tenant_id = v_tenant_id;
    DELETE FROM item_lots WHERE tenant_id = v_tenant_id;
    DELETE FROM fields WHERE tenant_id = v_tenant_id;
    DELETE FROM farms WHERE tenant_id = v_tenant_id;
    DELETE FROM crops WHERE tenant_id = v_tenant_id;
    DELETE FROM items WHERE tenant_id = v_tenant_id;
    DELETE FROM parties WHERE tenant_id = v_tenant_id;
    DELETE FROM warehouses WHERE tenant_id = v_tenant_id;
    DELETE FROM companies WHERE tenant_id = v_tenant_id;
    DELETE FROM tenant_users WHERE tenant_id = v_tenant_id;
    DELETE FROM public.users WHERE id = v_user_admin;
    DELETE FROM tenants WHERE id = v_tenant_id;

    RAISE NOTICE '=== TEST VERİLERİ BAŞARIYLA TEMİZLENDİ ===';
END $$;
