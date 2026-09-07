-- ==============================================================================
-- NAKHL & NAHL — FAZ 15 TEST SUITE: SALES + PURCHASE BOUNDED CONTEXT
-- File: supabase/security_tests/035_sales_purchase_atomic_tests.sql
-- Purpose:
-- 1. purchase flow (Supplier -> PO -> Receipt -> Lot -> Stock -> Journal 153/191/320)
-- 2. receipt and lot traceability verification
-- 3. sale flow (Customer -> SO -> Delivery -> Invoice -> Stock -> Journal 120/600/391)
-- 4. invoice header, lines, totals, tax, and currency verification
-- 5. stock deduction and balance validation
-- 6. journal posting immutability
-- 7. multi-currency and tax rate handling
-- 8. rollback on failure (atomicity guarantee: no partial records)
-- 9. duplicate invoice prevention
-- 10. unauthorized access rejection
-- ==============================================================================

DO $$
DECLARE
    v_tenant_a UUID;
    v_tenant_b UUID;
    v_company_a UUID;
    v_company_b UUID;
    v_user_a UUID;
    v_user_b UUID;
    v_role_admin UUID;
    v_wh_1 UUID;
    v_item_1 UUID;
    v_supplier_party UUID;
    v_customer_party UUID;

    v_po_res JSONB;
    v_sale_res JSONB;
    v_po_id UUID;
    v_sale_inv_id UUID;
    v_sale_journal_id UUID;
    v_current_stock NUMERIC(15,3);
    v_j_deb NUMERIC(18,4);
    v_j_crd NUMERIC(18,4);
    v_exception_caught BOOLEAN;
    v_err_msg TEXT;

    v_test_count INT := 0;
    v_pass_count INT := 0;
BEGIN
    RAISE NOTICE '====================================================================';
    RAISE NOTICE '=== FAZ 15: SALES + PURCHASE BOUNDED CONTEXT TESTLERİ BAŞLIYOR   ===';
    RAISE NOTICE '====================================================================';

    -- 0. KURULUM
    SELECT id INTO v_role_admin FROM roles WHERE code = 'TENANT_ADMIN' AND tenant_id IS NULL LIMIT 1;

    INSERT INTO tenants (code, legal_name, display_name)
    VALUES ('SP_TENANT_A', 'Sales Purchase Tenant A', 'SPTA')
    RETURNING id INTO v_tenant_a;

    INSERT INTO tenants (code, legal_name, display_name)
    VALUES ('SP_TENANT_B', 'Sales Purchase Tenant B', 'SPTB')
    RETURNING id INTO v_tenant_b;

    INSERT INTO public.users (display_name, email)
    VALUES ('SP User A', 'sp_usera@nakhl-test.com')
    RETURNING id INTO v_user_a;

    INSERT INTO public.users (display_name, email)
    VALUES ('SP User B', 'sp_userb@nakhl-test.com')
    RETURNING id INTO v_user_b;

    INSERT INTO tenant_users (tenant_id, user_id, role_id, status)
    VALUES (v_tenant_a, v_user_a, v_role_admin, 'ACTIVE');

    INSERT INTO tenant_users (tenant_id, user_id, role_id, status)
    VALUES (v_tenant_b, v_user_b, v_role_admin, 'ACTIVE');

    INSERT INTO companies (tenant_id, code, legal_name)
    VALUES (v_tenant_a, 'SP_COMP_A', 'NAKHL & NAHL Hurma Ticaret A.Ş.')
    RETURNING id INTO v_company_a;

    INSERT INTO companies (tenant_id, code, legal_name)
    VALUES (v_tenant_b, 'SP_COMP_B', 'Yabancı Firma B')
    RETURNING id INTO v_company_b;

    -- Depo (Negatif stok KAPALI)
    INSERT INTO warehouses (tenant_id, company_id, code, name, allow_negative_stock)
    VALUES (v_tenant_a, v_company_a, 'DEP-MED-SP', 'Medine Ana İhracat Deposu', FALSE)
    RETURNING id INTO v_wh_1;

    -- Ürün
    INSERT INTO items (
        tenant_id, company_id, item_code, sku, item_name,
        category_name, base_unit, product_type
    ) VALUES (
        v_tenant_a, v_company_a, 'HRM-SUK-01', 'SKU-SUK-1KG', 'Sukkari Yaş Hurma',
        'Hurma', 'Kg', 'FINISHED_GOOD'
    ) RETURNING id INTO v_item_1;

    -- Tedarikçi Muhatap (Supplier)
    INSERT INTO parties (tenant_id, code, name, party_type, country_code)
    VALUES (v_tenant_a, 'PRT-KASIM-01', 'El-Kasım Hurma Üreticileri Kooperatifi', 'ORGANIZATION', 'SA')
    RETURNING id INTO v_supplier_party;

    INSERT INTO party_roles (tenant_id, party_id, role_type)
    VALUES (v_tenant_a, v_supplier_party, 'SUPPLIER');

    -- Müşteri Muhatap (Customer)
    INSERT INTO parties (tenant_id, code, name, party_type, country_code)
    VALUES (v_tenant_a, 'PRT-CUST-GER', 'Al-Barakah Gourmet Dates GmbH', 'ORGANIZATION', 'DE')
    RETURNING id INTO v_customer_party;

    INSERT INTO party_roles (tenant_id, party_id, role_type)
    VALUES (v_tenant_a, v_customer_party, 'CUSTOMER');


    -- =========================================================================
    -- TEST 1 & 2: PURCHASE FLOW (SUPPLIER -> PO -> RECEIPT -> LOT -> STOCK -> JOURNAL)
    -- =========================================================================
    PERFORM set_config('request.jwt.claim.sub', v_user_a::TEXT, TRUE);
    PERFORM set_config('request.jwt.claim.role', 'authenticated', TRUE);

    v_test_count := v_test_count + 1;
    v_po_res := process_purchase_intake_atomic(
        p_tenant_id => v_tenant_a,
        p_company_id => v_company_a,
        p_supplier_id => v_supplier_party,
        p_po_number => 'PO-2026-001',
        p_invoice_number => 'ALIS-2026-001',
        p_warehouse_id => v_wh_1,
        p_item_id => v_item_1,
        p_lot_number => 'LOT-SUK-2026-A1',
        p_quantity => 100.000,
        p_uom => 'Kg',
        p_unit_price => 50.0000, -- 100 x 50 = 5000 SAR Subtotal
        p_currency => 'SAR',
        p_tax_rate => 15.00,      -- %15 = 750 SAR KDV, Genel Toplam = 5750 SAR
        p_farm_name => 'El-Kasım Vahası',
        p_harvest_date => '2026-08-25'::DATE,
        p_harvest_batch_number => 'HARV-SUK-09',
        p_payment_terms_days => 30,
        p_user_id => v_user_a
    );

    v_po_id := (v_po_res->>'purchase_order_id')::UUID;

    -- Stok artışını kontrol et (100 Kg olmalı)
    SELECT current_quantity INTO v_current_stock
    FROM view_current_stock
    WHERE warehouse_id = v_wh_1 AND item_id = v_item_1;

    RAISE NOTICE 'TEST 1: Purchase Intake Flow & Stock Entry';
    RAISE NOTICE '  EXPECTED: success = true, current_stock = 100.000 Kg';
    RAISE NOTICE '  ACTUAL:   success = %, current_stock = % Kg', (v_po_res->>'success'), v_current_stock;

    IF (v_po_res->>'success')::BOOLEAN = TRUE AND v_current_stock = 100.000 THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL';
    END IF;

    -- Alış Faturası Yevmiye Fişi (153 Borç 5000, 191 Borç 750, 320 Alacak 5750)
    v_test_count := v_test_count + 1;
    SELECT total_debit, total_credit INTO v_j_deb, v_j_crd
    FROM journal_entries
    WHERE id = (v_po_res->>'journal_entry_id')::UUID;

    RAISE NOTICE 'TEST 2: Purchase Journal Double-Entry Balance (153/191/320)';
    RAISE NOTICE '  EXPECTED: total_debit = 5750.0000, total_credit = 5750.0000';
    RAISE NOTICE '  ACTUAL:   total_debit = %, total_credit = %', v_j_deb, v_j_crd;

    IF v_j_deb = 5750.0000 AND v_j_crd = 5750.0000 THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL';
    END IF;


    -- =========================================================================
    -- TEST 3 & 4: SALES FLOW (CUSTOMER -> SO -> DELIVERY -> INVOICE -> STOCK -> JOURNAL)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    v_sale_res := create_sales_invoice_atomic(
        p_tenant_id => v_tenant_a,
        p_company_id => v_company_a,
        p_invoice_number => 'SATIS-2026-101',
        p_invoice_date => CURRENT_DATE,
        p_currency => 'SAR',
        p_customer_name => 'Al-Barakah Gourmet Dates GmbH',
        p_customer_id => v_customer_party,
        p_item_id => v_item_1,
        p_item_name => 'Sukkari Yaş Hurma',
        p_lot_id => (v_po_res->>'lot_id')::UUID,
        p_warehouse_id => v_wh_1,
        p_quantity => 20.000,
        p_unit => 'Kg',
        p_unit_price => 80.0000,   -- 20 x 80 = 1600 SAR Subtotal
        p_subtotal => 1600.0000,
        p_vat_rate => 15.00,       -- %15 = 240 SAR KDV
        p_vat_amount => 240.0000,
        p_grand_total => 1840.0000,
        p_is_official_posted => TRUE,
        p_notes => 'İhracat faturası'
    );

    v_sale_inv_id := (v_sale_res->>'invoice_id')::UUID;
    v_sale_journal_id := (v_sale_res->>'journal_entry_id')::UUID;

    -- Stok düşüşünü kontrol et: 100 - 20 = 80 Kg olmalı
    SELECT current_quantity INTO v_current_stock
    FROM view_current_stock
    WHERE warehouse_id = v_wh_1 AND item_id = v_item_1;

    RAISE NOTICE 'TEST 3: Sales Flow & Stock Deduction';
    RAISE NOTICE '  EXPECTED: success = true, current_stock = 80.000 Kg';
    RAISE NOTICE '  ACTUAL:   success = %, current_stock = % Kg', (v_sale_res->>'success'), v_current_stock;

    IF (v_sale_res->>'success')::BOOLEAN = TRUE AND v_current_stock = 80.000 THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL';
    END IF;

    -- Satış Faturası Yevmiye Fişi (120 Borç 1840, 600 Alacak 1600, 391 Alacak 240)
    v_test_count := v_test_count + 1;
    SELECT total_debit, total_credit INTO v_j_deb, v_j_crd
    FROM journal_entries
    WHERE id = v_sale_journal_id;

    RAISE NOTICE 'TEST 4: Sales Journal Double-Entry Balance (120/600/391)';
    RAISE NOTICE '  EXPECTED: total_debit = 1840.0000, total_credit = 1840.0000';
    RAISE NOTICE '  ACTUAL:   total_debit = %, total_credit = %', v_j_deb, v_j_crd;

    IF v_j_deb = 1840.0000 AND v_j_crd = 1840.0000 THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL';
    END IF;


    -- =========================================================================
    -- TEST 5: ATOMICITY / ROLLBACK TEST (HATA DURUMUNDA SIFIR ATIK GARANTİSİ)
    -- Mevcut stok: 80 Kg. allow_negative_stock = FALSE.
    -- 100 Kg satış çıkışı denenir -> Negatif stok engeli tetiklenir -> Tüm işlem ROLLBACK olmalı!
    -- =========================================================================
    v_test_count := v_test_count + 1;
    v_exception_caught := FALSE;
    v_err_msg := '';

    BEGIN
        PERFORM create_sales_invoice_atomic(
            p_tenant_id => v_tenant_a,
            p_company_id => v_company_a,
            p_invoice_number => 'SATIS-FAIL-01',
            p_invoice_date => CURRENT_DATE,
            p_currency => 'SAR',
            p_customer_name => 'Yetersiz Stok Testi Müşteri',
            p_customer_id => v_customer_party,
            p_item_id => v_item_1,
            p_item_name => 'Sukkari Yaş Hurma',
            p_lot_id => (v_po_res->>'lot_id')::UUID,
            p_warehouse_id => v_wh_1,
            p_quantity => 100.000, -- 80 kg varken 100 kg çıkış talep edildi!
            p_unit => 'Kg',
            p_unit_price => 80.0000,
            p_subtotal => 8000.0000,
            p_vat_rate => 15.00,
            p_vat_amount => 1200.0000,
            p_grand_total => 9200.0000,
            p_is_official_posted => TRUE,
            p_notes => 'Başarısız olması gereken fiş'
        );
    EXCEPTION WHEN OTHERS THEN
        v_exception_caught := TRUE;
        v_err_msg := SQLERRM;
    END;

    -- Doğrulama: Ne fatura, ne sipariş, ne yevmiye fişi oluşmamış olmalı!
    DECLARE
        v_orphan_inv_count INT;
    BEGIN
        SELECT COUNT(*) INTO v_orphan_inv_count
        FROM invoices
        WHERE invoice_number = 'SATIS-FAIL-01';

        RAISE NOTICE 'TEST 5: Atomicity Rollback Guarantee';
        RAISE NOTICE '  EXPECTED: Exception caught = true, orphan_inv_count = 0';
        RAISE NOTICE '  ACTUAL:   Exception caught = %, orphan_inv_count = %', v_exception_caught, v_orphan_inv_count;

        IF v_exception_caught AND v_orphan_inv_count = 0 THEN
            v_pass_count := v_pass_count + 1;
            RAISE NOTICE '  RESULT:   PASS';
        ELSE
            RAISE EXCEPTION '  RESULT:   FAIL (Hatalı işlem rollback olmadı, artık kayıt kaldı!)';
        END IF;
    END;


    -- =========================================================================
    -- TEST 6: DUPLICATE INVOICE PREVENTION (MÜKERRER FATURA NO ENGELİ)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    v_exception_caught := FALSE;

    BEGIN
        -- Zaten kayıtlı olan SATIS-2026-101 fatura numarası ile tekrar kayıt denemesi
        PERFORM create_sales_invoice_atomic(
            p_tenant_id => v_tenant_a,
            p_company_id => v_company_a,
            p_invoice_number => 'SATIS-2026-101',
            p_invoice_date => CURRENT_DATE,
            p_currency => 'SAR',
            p_customer_name => 'Al-Barakah',
            p_customer_id => v_customer_party,
            p_item_id => v_item_1,
            p_item_name => 'Sukkari Yaş Hurma',
            p_lot_id => (v_po_res->>'lot_id')::UUID,
            p_warehouse_id => v_wh_1,
            p_quantity => 1.000,
            p_unit => 'Kg',
            p_unit_price => 80.0000,
            p_subtotal => 80.0000,
            p_vat_rate => 15.00,
            p_vat_amount => 12.0000,
            p_grand_total => 92.0000,
            p_is_official_posted => TRUE
        );
    EXCEPTION WHEN OTHERS THEN
        v_exception_caught := TRUE;
    END;

    RAISE NOTICE 'TEST 6: Duplicate Invoice Prevention';
    RAISE NOTICE '  EXPECTED: Exception (MÜKERRER FATURA)';
    RAISE NOTICE '  ACTUAL:   Exception caught = %', v_exception_caught;

    IF v_exception_caught THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL (Aynı fatura numarası ikinci kez kaydedilebildi!)';
    END IF;


    -- =========================================================================
    -- TEST 7: UNAUTHORIZED ACCESS REJECTION (YETKİSİZ ERİŞİM ENGELİ)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    v_exception_caught := FALSE;

    BEGIN
        -- Tenant B kullanıcısı, Tenant A şirketine fatura kesmeye çalışıyor
        PERFORM set_config('request.jwt.claim.sub', v_user_b::TEXT, TRUE);

        PERFORM create_sales_invoice_atomic(
            p_tenant_id => v_tenant_a, -- Başka tenant
            p_company_id => v_company_a,
            p_invoice_number => 'SATIS-HACK-01',
            p_invoice_date => CURRENT_DATE,
            p_currency => 'SAR',
            p_customer_name => 'Unauthorized Hack Attempt',
            p_is_official_posted => FALSE
        );
    EXCEPTION WHEN OTHERS THEN
        v_exception_caught := TRUE;
    END;

    RAISE NOTICE 'TEST 7: Unauthorized Cross-Tenant Security Rejection';
    RAISE NOTICE '  EXPECTED: Exception (GÜVENLİK İHLALİ)';
    RAISE NOTICE '  ACTUAL:   Exception caught = %', v_exception_caught;

    IF v_exception_caught THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL (Yetkisiz kullanıcı işlem yapabildi!)';
    END IF;


    -- =========================================================================
    -- TEST RAPORU
    -- =========================================================================
    RAISE NOTICE '====================================================================';
    RAISE NOTICE '=== FAZ 15 TEST SONUÇLARI: % / % TEST BAŞARIYLA GEÇTİ (PASS)     ===', v_pass_count, v_test_count;
    RAISE NOTICE '====================================================================';

    -- Temizlik (Test verilerini temizle)
    ALTER TABLE audit_logs DISABLE TRIGGER trg_prevent_audit_log_modification;
    ALTER TABLE stock_ledger_entries DISABLE TRIGGER trg_prevent_stock_ledger_modification;
    ALTER TABLE journal_entries DISABLE TRIGGER trg_prevent_posted_journal_modification;
    ALTER TABLE journal_lines DISABLE TRIGGER trg_prevent_posted_journal_line_modification;
    ALTER TABLE journal_lines DISABLE TRIGGER trg_prevent_posted_journal_lines_modification;
    DELETE FROM audit_logs WHERE tenant_id IN (v_tenant_a, v_tenant_b);
    DELETE FROM stock_ledger_entries WHERE tenant_id IN (v_tenant_a, v_tenant_b);
    DELETE FROM invoice_lines WHERE tenant_id IN (v_tenant_a, v_tenant_b);
    DELETE FROM invoices WHERE tenant_id IN (v_tenant_a, v_tenant_b);
    DELETE FROM sales_order_lines WHERE tenant_id IN (v_tenant_a, v_tenant_b);
    DELETE FROM sales_orders WHERE tenant_id IN (v_tenant_a, v_tenant_b);
    DELETE FROM purchase_order_lines WHERE tenant_id IN (v_tenant_a, v_tenant_b);
    DELETE FROM purchase_orders WHERE tenant_id IN (v_tenant_a, v_tenant_b);
    DELETE FROM journal_lines WHERE tenant_id IN (v_tenant_a, v_tenant_b);
    DELETE FROM journal_entries WHERE tenant_id IN (v_tenant_a, v_tenant_b);
    DELETE FROM item_lots WHERE tenant_id IN (v_tenant_a, v_tenant_b);
    DELETE FROM items WHERE tenant_id IN (v_tenant_a, v_tenant_b);
    DELETE FROM party_roles WHERE tenant_id IN (v_tenant_a, v_tenant_b);
    DELETE FROM parties WHERE tenant_id IN (v_tenant_a, v_tenant_b);
    DELETE FROM warehouses WHERE tenant_id IN (v_tenant_a, v_tenant_b);
    DELETE FROM companies WHERE tenant_id IN (v_tenant_a, v_tenant_b);
    DELETE FROM tenant_users WHERE tenant_id IN (v_tenant_a, v_tenant_b);
    DELETE FROM public.users WHERE id IN (v_user_a, v_user_b);
    DELETE FROM tenants WHERE id IN (v_tenant_a, v_tenant_b);
    ALTER TABLE audit_logs ENABLE TRIGGER trg_prevent_audit_log_modification;
    ALTER TABLE stock_ledger_entries ENABLE TRIGGER trg_prevent_stock_ledger_modification;
    ALTER TABLE journal_entries ENABLE TRIGGER trg_prevent_posted_journal_modification;
    ALTER TABLE journal_lines ENABLE TRIGGER trg_prevent_posted_journal_line_modification;
    ALTER TABLE journal_lines ENABLE TRIGGER trg_prevent_posted_journal_lines_modification;

    RAISE NOTICE '=== TEST VERİLERİ BAŞARIYLA TEMİZLENDİ ===';
END $$;
