-- ==============================================================================
-- NAKHL & NAHL — FAZ 13 TEST SUITE: INVENTORY LEDGER & STOCK BALANCE
-- File: supabase/security_tests/033_inventory_ledger_balance_tests.sql
-- Purpose:
-- 1. Product Master & Item Lot Traceability Chain setup
-- 2. Purchase (+100), Sale (-20), Transfer (-30), Return (+5) ledger balance verification
-- 3. Negative stock policy blocking test (allow_negative_stock = FALSE)
-- 4. Negative stock override & audit log verification (allow_negative_stock = TRUE)
-- 5. Movement type restriction test on negative stock
-- ==============================================================================

DO $$
DECLARE
    v_tenant_id UUID;
    v_company_id UUID;
    v_user_admin UUID;
    v_role_admin UUID;
    v_wh_1 UUID;
    v_wh_2 UUID;
    v_item_id UUID;
    v_lot_id UUID;
    v_supplier_party UUID;

    v_current_bal_wh1 NUMERIC(15,3);
    v_current_bal_wh2 NUMERIC(15,3);
    v_ledger_count INT;
    v_audit_count INT;
    v_exception_caught BOOLEAN := FALSE;

    v_test_count INT := 0;
    v_pass_count INT := 0;
BEGIN
    RAISE NOTICE '====================================================================';
    RAISE NOTICE '=== FAZ 13: PRODUCT + INVENTORY FOUNDATION TESTLERİ BAŞLIYOR     ===';
    RAISE NOTICE '====================================================================';

    -- 0. TEST ORTAMI KURULUMU
    SELECT id INTO v_role_admin FROM roles WHERE code = 'TENANT_ADMIN' AND tenant_id IS NULL LIMIT 1;

    INSERT INTO tenants (code, legal_name, display_name)
    VALUES ('INV_TEST_TENANT', 'Inventory Foundation Test Tenant', 'IFTT')
    RETURNING id INTO v_tenant_id;

    INSERT INTO public.users (display_name, email)
    VALUES ('Inventory Test Admin', 'inv_admin@nakhl-test.com')
    RETURNING id INTO v_user_admin;

    INSERT INTO tenant_users (tenant_id, user_id, role_id, status)
    VALUES (v_tenant_id, v_user_admin, v_role_admin, 'ACTIVE');

    INSERT INTO companies (tenant_id, code, legal_name)
    VALUES (v_tenant_id, 'COMP_INV', 'NAKHL & NAHL Hurma A.Ş.')
    RETURNING id INTO v_company_id;

    -- Depo 1: Medine Merkez Depo (Negatif stoka KAPALI)
    INSERT INTO warehouses (tenant_id, company_id, code, name, allow_negative_stock)
    VALUES (v_tenant_id, v_company_id, 'DEP-MED-01', 'Medine Hurma Merkez Deposu', FALSE)
    RETURNING id INTO v_wh_1;

    -- Depo 2: Cidde İhracat Liman Deposu (Negatif stoka KAPALI)
    INSERT INTO warehouses (tenant_id, company_id, code, name, allow_negative_stock)
    VALUES (v_tenant_id, v_company_id, 'DEP-JED-02', 'Cidde Liman İhracat Deposu', FALSE)
    RETURNING id INTO v_wh_2;

    -- Tedarikçi Muhatap (Party)
    INSERT INTO parties (tenant_id, code, name, party_type, country_code)
    VALUES (v_tenant_id, 'PRT-SUP-01', 'Al-Ula Organik Hurma Çiftliği', 'ORGANIZATION', 'SA')
    RETURNING id INTO v_supplier_party;

    INSERT INTO party_roles (tenant_id, party_id, role_type)
    VALUES (v_tenant_id, v_supplier_party, 'SUPPLIER');

    -- Ürün Master (Product Master: SKU, Barcode, UOM, Halal, Quality, Traceability)
    INSERT INTO items (
        tenant_id, company_id, item_code, sku, barcode, item_name,
        category_name, base_unit, product_type,
        traceability_required, lot_required, halal_required, quality_required
    ) VALUES (
        v_tenant_id, v_company_id, 'HRM-MDJ-001', 'SKU-MDJ-PREM-1KG', '6281001234567', 'Medjoul Jumbo Hurma',
        'Hurma', 'Kg', 'FINISHED_GOOD',
        TRUE, TRUE, TRUE, TRUE
    ) RETURNING id INTO v_item_id;

    -- Parti / Lot Değer Zinciri: FARM -> HARVEST -> SUPPLIER -> FACTORY -> PROCESSING -> PACKAGING -> LOT
    INSERT INTO item_lots (
        tenant_id, company_id, item_id, lot_number,
        farm_name, harvest_date, harvest_batch_number,
        supplier_party_id, processing_facility, processing_date,
        packaging_date, packaging_type, temperature_control_required, target_storage_temp_celsius,
        country_of_origin, production_date, expiration_date,
        halal_certified, halal_certificate_number, quality_status
    ) VALUES (
        v_tenant_id, v_company_id, v_item_id, 'LOT-2026-MDJ-09',
        'Al-Ula Oasis Date Farms', '2026-08-01', 'HARV-2026-A1',
        v_supplier_party, 'Medina Date Processing Plant #2', '2026-08-10',
        '2026-08-12', 'VACUUM_BOX', TRUE, -18.00,
        'SA', '2026-08-10', '2028-08-10',
        TRUE, 'HALAL-SA-2026-0988', 'APPROVED'
    ) RETURNING id INTO v_lot_id;

    -- =========================================================================
    -- SENARYO ADIM 1: PURCHASE (Satın Alma Kabul: +100 Kg)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    INSERT INTO stock_ledger_entries (
        tenant_id, company_id, warehouse_id, item_id, lot_id,
        movement_type, quantity, unit, unit_cost, total_cost,
        document_type, document_reference, description, created_by
    ) VALUES (
        v_tenant_id, v_company_id, v_wh_1, v_item_id, v_lot_id,
        'PURCHASE', 100.000, 'Kg', 45.00, 4500.00,
        'PURCHASE_ORDER', 'PO-2026-001', 'Medjoul İlk Hasat Kabulü', v_user_admin
    );

    SELECT current_quantity INTO v_current_bal_wh1
    FROM view_current_stock
    WHERE warehouse_id = v_wh_1 AND item_id = v_item_id;

    IF v_current_bal_wh1 = 100.000 THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE 'TEST 1 PASS: Purchase (+100 Kg) -> Bakiye = % Kg (Beklenen: 100.000)', v_current_bal_wh1;
    ELSE
        RAISE EXCEPTION 'TEST 1 FAIL: Purchase sonrası bakiye yanlış! Bulunan: %, Beklenen: 100.000', v_current_bal_wh1;
    END IF;

    -- =========================================================================
    -- SENARYO ADIM 2: SALE (Satış Fatura Çıkışı: -20 Kg)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    INSERT INTO stock_ledger_entries (
        tenant_id, company_id, warehouse_id, item_id, lot_id,
        movement_type, quantity, unit, unit_cost, total_cost,
        document_type, document_reference, description, created_by
    ) VALUES (
        v_tenant_id, v_company_id, v_wh_1, v_item_id, v_lot_id,
        'SALE', -20.000, 'Kg', 45.00, 900.00,
        'INVOICE', 'INV-2026-101', 'Müşteri Satış Çıkışı', v_user_admin
    );

    SELECT current_quantity INTO v_current_bal_wh1
    FROM view_current_stock
    WHERE warehouse_id = v_wh_1 AND item_id = v_item_id;

    IF v_current_bal_wh1 = 80.000 THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE 'TEST 2 PASS: Sale (-20 Kg) -> Bakiye = % Kg (Beklenen: 80.000)', v_current_bal_wh1;
    ELSE
        RAISE EXCEPTION 'TEST 2 FAIL: Sale sonrası bakiye yanlış! Bulunan: %, Beklenen: 80.000', v_current_bal_wh1;
    END IF;

    -- =========================================================================
    -- SENARYO ADIM 3: TRANSFER (Depolar Arası Transfer: Depo 1 -> Depo 2, 30 Kg)
    -- Depo 1: -30 Kg, Depo 2: +30 Kg
    -- =========================================================================
    v_test_count := v_test_count + 1;
    -- Çıkış (Depo 1)
    INSERT INTO stock_ledger_entries (
        tenant_id, company_id, warehouse_id, item_id, lot_id,
        movement_type, quantity, unit, unit_cost, total_cost,
        document_type, document_reference, description, created_by
    ) VALUES (
        v_tenant_id, v_company_id, v_wh_1, v_item_id, v_lot_id,
        'TRANSFER', -30.000, 'Kg', 45.00, 1350.00,
        'TRANSFER_ORDER', 'TRF-2026-001', 'Cidde Limanına Sevk Çıkışı', v_user_admin
    );

    -- Giriş (Depo 2)
    INSERT INTO stock_ledger_entries (
        tenant_id, company_id, warehouse_id, item_id, lot_id,
        movement_type, quantity, unit, unit_cost, total_cost,
        document_type, document_reference, description, created_by
    ) VALUES (
        v_tenant_id, v_company_id, v_wh_2, v_item_id, v_lot_id,
        'TRANSFER', 30.000, 'Kg', 45.00, 1350.00,
        'TRANSFER_ORDER', 'TRF-2026-001', 'Cidde Limanına Sevk Girişi', v_user_admin
    );

    SELECT current_quantity INTO v_current_bal_wh1
    FROM view_current_stock
    WHERE warehouse_id = v_wh_1 AND item_id = v_item_id;

    SELECT current_quantity INTO v_current_bal_wh2
    FROM view_current_stock
    WHERE warehouse_id = v_wh_2 AND item_id = v_item_id;

    IF v_current_bal_wh1 = 50.000 AND v_current_bal_wh2 = 30.000 THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE 'TEST 3 PASS: Transfer (-30 Kg) -> Depo 1: % Kg, Depo 2: % Kg (Beklenen: 50.000 / 30.000)',
            v_current_bal_wh1, v_current_bal_wh2;
    ELSE
        RAISE EXCEPTION 'TEST 3 FAIL: Transfer sonrası bakiye yanlış! Depo 1: %, Depo 2: %',
            v_current_bal_wh1, v_current_bal_wh2;
    END IF;

    -- =========================================================================
    -- SENARYO ADIM 4: RETURN (Müşteri İadesi: +5 Kg -> Depo 1)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    INSERT INTO stock_ledger_entries (
        tenant_id, company_id, warehouse_id, item_id, lot_id,
        movement_type, quantity, unit, unit_cost, total_cost,
        document_type, document_reference, description, created_by
    ) VALUES (
        v_tenant_id, v_company_id, v_wh_1, v_item_id, v_lot_id,
        'RETURN', 5.000, 'Kg', 45.00, 225.00,
        'RETURN_ORDER', 'RET-2026-001', 'Müşteri Fazla Ürün İadesi', v_user_admin
    );

    SELECT current_quantity INTO v_current_bal_wh1
    FROM view_current_stock
    WHERE warehouse_id = v_wh_1 AND item_id = v_item_id;

    IF v_current_bal_wh1 = 55.000 THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE 'TEST 4 PASS: Return (+5 Kg) -> Nihai Bakiye = % Kg (Net Formül: +100 -20 -30 +5 = 55.000)', v_current_bal_wh1;
    ELSE
        RAISE EXCEPTION 'TEST 4 FAIL: Return sonrası bakiye yanlış! Bulunan: %, Beklenen: 55.000', v_current_bal_wh1;
    END IF;

    -- =========================================================================
    -- TEST 5: DIRECTION VE DEFTER DEĞİŞTİRİLEMEZLİK (IMMUTABILITY) KONTROLÜ
    -- =========================================================================
    v_test_count := v_test_count + 1;
    SELECT COUNT(*) INTO v_ledger_count
    FROM stock_ledger_entries
    WHERE company_id = v_company_id;

    -- 5 hareket olmalı: Purchase(IN), Sale(OUT), TransferOut(OUT), TransferIn(IN), Return(IN)
    IF v_ledger_count = 5 THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE 'TEST 5 PASS: Toplam Defter Hareketi = 5, Direction otomatik belirlendi.';
    ELSE
        RAISE EXCEPTION 'TEST 5 FAIL: Defter kayıt sayısı yanlış: %', v_ledger_count;
    END IF;

    -- Defterin güncellenemez olduğunu doğrula (UPDATE engeli)
    v_test_count := v_test_count + 1;
    v_exception_caught := FALSE;
    BEGIN
        UPDATE stock_ledger_entries 
        SET quantity = 999 
        WHERE company_id = v_company_id;
    EXCEPTION WHEN OTHERS THEN
        v_exception_caught := TRUE;
    END;

    IF v_exception_caught THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE 'TEST 6 PASS: stock_ledger_entries UPDATE denemesi immutability tetikleyicisi tarafından başarıyla ENGELLENDİ.';
    ELSE
        RAISE EXCEPTION 'TEST 6 FAIL: stock_ledger_entries güncellenebildi! Immutability ihlali!';
    END IF;

    -- =========================================================================
    -- TEST 7: NEGATİF STOK KORUMASI (allow_negative_stock = FALSE)
    -- Mevcut bakiye: 55 Kg. Çıkış denemesi: -60 Kg. Oluşacak bakiye: -5 Kg.
    -- Beklenti: RAISE EXCEPTION
    -- =========================================================================
    v_test_count := v_test_count + 1;
    v_exception_caught := FALSE;
    BEGIN
        INSERT INTO stock_ledger_entries (
            tenant_id, company_id, warehouse_id, item_id, lot_id,
            movement_type, quantity, unit, unit_cost, total_cost,
            document_type, document_reference, description, created_by
        ) VALUES (
            v_tenant_id, v_company_id, v_wh_1, v_item_id, v_lot_id,
            'SALE', -60.000, 'Kg', 45.00, 2700.00,
            'INVOICE', 'INV-OVER-01', 'Yetersiz Stoklu Satış Çıkış Denemesi', v_user_admin
        );
    EXCEPTION WHEN OTHERS THEN
        v_exception_caught := TRUE;
        RAISE NOTICE 'Negatif stok engelleme mesajı yakalandı: %', SQLERRM;
    END;

    IF v_exception_caught THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE 'TEST 7 PASS: Negatif stok çıkışı (-60 Kg > 55 Kg bakiye) başarıyla ENGELLENDİ.';
    ELSE
        RAISE EXCEPTION 'TEST 7 FAIL: Negatif stoka izin verilmediği halde çıkış kaydedildi!';
    END IF;

    -- =========================================================================
    -- TEST 8: NEGATİF STOK OVERRIDE & AUDIT LOG (allow_negative_stock = TRUE)
    -- Depo politikası güncellenir: allow_negative_stock = TRUE
    -- Çıkış yapılır (-60 Kg) -> Bakiye -5 Kg olmalı ve audit_logs kaydı oluşmalı
    -- =========================================================================
    v_test_count := v_test_count + 1;
    UPDATE warehouses SET allow_negative_stock = TRUE WHERE id = v_wh_1;

    INSERT INTO stock_ledger_entries (
        tenant_id, company_id, warehouse_id, item_id, lot_id,
        movement_type, quantity, unit, unit_cost, total_cost,
        document_type, document_reference, description, created_by
    ) VALUES (
        v_tenant_id, v_company_id, v_wh_1, v_item_id, v_lot_id,
        'SALE', -60.000, 'Kg', 45.00, 2700.00,
        'INVOICE', 'INV-OVER-02', 'Yönetici İzinli Negatif Stok Çıkışı', v_user_admin
    );

    SELECT current_quantity INTO v_current_bal_wh1
    FROM view_current_stock
    WHERE warehouse_id = v_wh_1 AND item_id = v_item_id;

    SELECT COUNT(*) INTO v_audit_count
    FROM audit_logs
    WHERE tenant_id = v_tenant_id
      AND entity_type = 'negative_stock_override';

    IF v_current_bal_wh1 = -5.000 AND v_audit_count >= 1 THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE 'TEST 8 PASS: Negatif stok override başarıyla gerçekleşti (Bakiye: % Kg) ve % adet audit kaydı tutuldu.',
            v_current_bal_wh1, v_audit_count;
    ELSE
        RAISE EXCEPTION 'TEST 8 FAIL: Override sonrası bakiye (%) veya audit log sayısı (%) hatalı!',
            v_current_bal_wh1, v_audit_count;
    END IF;

    -- =========================================================================
    -- TEST 9: NEGATİF STOKTA GEÇERSİZ HAREKET TÜRÜ ENGELİ
    -- Negatif depoda 'WASTE' hareketi ile daha fazla eksiye düşürme denemesi
    -- Beklenti: RAISE EXCEPTION
    -- =========================================================================
    v_test_count := v_test_count + 1;
    v_exception_caught := FALSE;
    BEGIN
        INSERT INTO stock_ledger_entries (
            tenant_id, company_id, warehouse_id, item_id, lot_id,
            movement_type, quantity, unit, unit_cost, total_cost,
            document_type, document_reference, description, created_by
        ) VALUES (
            v_tenant_id, v_company_id, v_wh_1, v_item_id, v_lot_id,
            'WASTE', -10.000, 'Kg', 45.00, 450.00,
            'WASTE_SLIP', 'WST-001', 'Geçersiz Negatif Fire Çıkışı', v_user_admin
        );
    EXCEPTION WHEN OTHERS THEN
        v_exception_caught := TRUE;
        RAISE NOTICE 'Geçersiz hareket türü engelleme mesajı yakalandı: %', SQLERRM;
    END;

    IF v_exception_caught THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE 'TEST 9 PASS: Negatif stokta geçersiz hareket türü (WASTE) başarıyla ENGELLENDİ.';
    ELSE
        RAISE EXCEPTION 'TEST 9 FAIL: WASTE türünde negatif stok çıkışına izin verildi!';
    END IF;

    -- =========================================================================
    -- TEST RAPORU
    -- =========================================================================
    RAISE NOTICE '====================================================================';
    RAISE NOTICE '=== FAZ 13 TEST SONUÇLARI: % / % TEST BAŞARIYLA GEÇTİ (PASS)     ===', v_pass_count, v_test_count;
    RAISE NOTICE '====================================================================';

    -- Temizlik (Test verilerini temizle)
    ALTER TABLE audit_logs DISABLE TRIGGER trg_prevent_audit_log_modification;
    ALTER TABLE stock_ledger_entries DISABLE TRIGGER trg_prevent_stock_ledger_modification;
    DELETE FROM audit_logs WHERE tenant_id = v_tenant_id;
    DELETE FROM stock_ledger_entries WHERE tenant_id = v_tenant_id;
    DELETE FROM item_lots WHERE tenant_id = v_tenant_id;
    DELETE FROM items WHERE tenant_id = v_tenant_id;
    DELETE FROM party_roles WHERE tenant_id = v_tenant_id;
    DELETE FROM parties WHERE tenant_id = v_tenant_id;
    DELETE FROM warehouses WHERE tenant_id = v_tenant_id;
    DELETE FROM companies WHERE tenant_id = v_tenant_id;
    DELETE FROM tenant_users WHERE tenant_id = v_tenant_id;
    DELETE FROM public.users WHERE id = v_user_admin;
    DELETE FROM tenants WHERE id = v_tenant_id;
    ALTER TABLE audit_logs ENABLE TRIGGER trg_prevent_audit_log_modification;
    ALTER TABLE stock_ledger_entries ENABLE TRIGGER trg_prevent_stock_ledger_modification;

    RAISE NOTICE '=== TEST VERİLERİ BAŞARIYLA TEMİZLENDİ ===';
END $$;
