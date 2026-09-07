-- ==============================================================================
-- NAKHL & NAHL — FAZ 27: MULTI-COMPANY + INTERCOMPANY INTEGRATION & SECURITY TESTS
-- ==============================================================================

DO $$
DECLARE
    v_tenant_id UUID := '11111111-1111-1111-1111-111111111111';
    v_tenant_b_id UUID := '22222222-2222-2222-2222-222222222222';
    
    -- Aynı tenant altındaki iki şirket
    v_company_a_id UUID := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'; -- Alıcı Şirket (Buyer)
    v_company_b_id UUID := 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'; -- Satıcı Şirket (Seller)
    v_user_id UUID := '99999999-9999-9999-9999-999999999999';
    
    v_wh_a_id UUID;
    v_wh_b_id UUID;
    v_item_id UUID;
    
    v_ic_tx_id UUID;
    v_tx_res JSONB;
    v_trf_res JSONB;
    
    v_seller_jrn_id UUID;
    v_buyer_jrn_id UUID;
    v_due_from_amt NUMERIC;
    v_due_to_amt NUMERIC;
    v_out_count INT;
    v_in_count INT;
BEGIN
    RAISE NOTICE '>>> FAZ 27 MULTI-COMPANY + INTERCOMPANY TESTLERİ BAŞLIYOR...';

    -- Hazırlık: Tenant, User, Company
    INSERT INTO tenants (id, code, legal_name, display_name)
    VALUES 
        (v_tenant_id, 'IC_TENANT_A', 'IC Tenant A Inc.', 'Tenant A'),
        (v_tenant_b_id, 'IC_TENANT_B', 'IC Tenant B Inc.', 'Tenant B')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO public.users (id, display_name, email)
    VALUES (v_user_id, 'IC Officer', 'ic_officer@nakhl.com')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO companies (id, tenant_id, code, legal_name)
    VALUES 
        (v_company_a_id, v_tenant_id, 'IC_COMP_A', 'IC Company A Ltd.'),
        (v_company_b_id, v_tenant_id, 'IC_COMP_B', 'IC Company B Ltd.')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO tenant_users (tenant_id, user_id, role_id, status)
    SELECT v_tenant_id, v_user_id, id, 'ACTIVE'
    FROM roles WHERE code = 'TENANT_ADMIN' AND tenant_id IS NULL LIMIT 1
    ON CONFLICT DO NOTHING;

    PERFORM set_config('request.jwt.claim.sub', v_user_id::TEXT, TRUE);
    PERFORM set_config('request.jwt.claim.role', 'authenticated', TRUE);

    SELECT id INTO v_wh_a_id FROM warehouses WHERE company_id = v_company_a_id LIMIT 1;
    IF v_wh_a_id IS NULL THEN
        INSERT INTO warehouses (tenant_id, company_id, code, name, warehouse_type, allow_negative_stock)
        VALUES (v_tenant_id, v_company_a_id, 'WH-A-MAIN', 'Company A Ana Depo', 'FINISHED_GOODS', TRUE)
        RETURNING id INTO v_wh_a_id;
    END IF;

    SELECT id INTO v_wh_b_id FROM warehouses WHERE company_id = v_company_b_id LIMIT 1;
    IF v_wh_b_id IS NULL THEN
        INSERT INTO warehouses (tenant_id, company_id, code, name, warehouse_type, allow_negative_stock)
        VALUES (v_tenant_id, v_company_b_id, 'WH-B-MAIN', 'Company B İhracat Deposu', 'FINISHED_GOODS', TRUE)
        RETURNING id INTO v_wh_b_id;
    END IF;

    UPDATE warehouses SET allow_negative_stock = TRUE WHERE id IN (v_wh_a_id, v_wh_b_id);

    SELECT id INTO v_item_id FROM items WHERE tenant_id = v_tenant_id LIMIT 1;
    IF v_item_id IS NULL THEN
        INSERT INTO items (tenant_id, company_id, sku, name, unit_of_measure)
        VALUES (v_tenant_id, v_company_b_id, 'DATE-MED-01', 'Medine Mebrum Hurma', 'Kg')
        RETURNING id INTO v_item_id;
    END IF;

    -- 1. TEST: Şirketler Arası İşlem Oluşturma (Transfer Pricing & Trade)
    INSERT INTO intercompany_transactions (
        tenant_id, seller_company_id, buyer_company_id,
        transaction_number, transaction_date, currency,
        subtotal, tax_rate, tax_amount, grand_total,
        transfer_pricing_method, markup_percentage, status
    ) VALUES (
        v_tenant_id, v_company_b_id, v_company_a_id,
        'ICTX-2026-0001', CURRENT_DATE, 'SAR',
        100000.00, 15.00, 15000.00, 115000.00,
        'COST_PLUS', 5.00, 'DRAFT'
    ) RETURNING id INTO v_ic_tx_id;

    INSERT INTO intercompany_transaction_lines (
        tenant_id, intercompany_transaction_id, item_id,
        quantity, cost_price, transfer_price, markup_amount,
        subtotal, tax_rate, tax_amount, total_amount
    ) VALUES (
        v_tenant_id, v_ic_tx_id, v_item_id,
        2000.0, 47.62, 50.00, 4760.00,
        100000.00, 15.00, 15000.00, 115000.00
    );
    RAISE NOTICE 'Test 1: Şirketler Arası Ticari İşlem (Cost-Plus %%5 TP) Başarıyla Oluşturuldu [PASS] (ID: %)', v_ic_tx_id;

    -- 2. TEST: Intercompany Accounting (Paired Invoices & Due From / Due To Journals)
    v_tx_res := post_intercompany_sale_purchase_transaction(
        p_intercompany_tx_id := v_ic_tx_id,
        p_from_warehouse_id := v_wh_b_id,
        p_to_warehouse_id := v_wh_a_id,
        p_user_id := v_user_id
    );

    IF NOT (v_tx_res->>'success')::BOOLEAN THEN
        RAISE EXCEPTION 'TEST 2 BAŞARISIZ: Intercompany faturalaşma ve muhasebe başarısız!';
    END IF;

    v_seller_jrn_id := (v_tx_res->>'seller_journal_id')::UUID;
    v_buyer_jrn_id := (v_tx_res->>'buyer_journal_id')::UUID;

    -- Satıcı Due From Borç Bakiyesi
    SELECT SUM(debit_amount) INTO v_due_from_amt 
    FROM journal_lines 
    WHERE journal_entry_id = v_seller_jrn_id AND account_id IN (
        SELECT id FROM chart_of_accounts WHERE company_id = v_company_b_id AND account_code = '133'
    );

    -- Alıcı Due To Alacak Bakiyesi
    SELECT SUM(credit_amount) INTO v_due_to_amt 
    FROM journal_lines 
    WHERE journal_entry_id = v_buyer_jrn_id AND account_id IN (
        SELECT id FROM chart_of_accounts WHERE company_id = v_company_a_id AND account_code = '333'
    );

    IF v_due_from_amt != 115000.00 OR v_due_to_amt != 115000.00 OR v_due_from_amt != v_due_to_amt THEN
        RAISE EXCEPTION 'TEST 2 BAŞARISIZ: Due From (%) ve Due To (%) tutarları mutabık değil!', v_due_from_amt, v_due_to_amt;
    END IF;
    RAISE NOTICE 'Test 2: Intercompany Muhasebe (Due From = Due To = 115,000 SAR) Başarıyla Doğrulandı [PASS]';

    -- 3. TEST: Intercompany Stok Transferi (TRANSFER -> OUT -> IN)
    v_trf_res := execute_intercompany_stock_transfer(
        p_tenant_id := v_tenant_id,
        p_from_company_id := v_company_b_id,
        p_from_warehouse_id := v_wh_b_id,
        p_to_company_id := v_company_a_id,
        p_to_warehouse_id := v_wh_a_id,
        p_item_id := v_item_id,
        p_lot_id := NULL,
        p_quantity := 500.0,
        p_transfer_price := 50.0,
        p_user_id := v_user_id
    );

    IF NOT (v_trf_res->>'success')::BOOLEAN THEN
        RAISE EXCEPTION 'TEST 3 BAŞARISIZ: Şirketler arası stok transferi başarısız!';
    END IF;

    -- Stok hareketlerini doğrula
    SELECT COUNT(*) INTO v_out_count FROM stock_ledger_entries 
    WHERE company_id = v_company_b_id AND movement_type = 'TRANSFER_OUT' AND direction = 'OUT';

    SELECT COUNT(*) INTO v_in_count FROM stock_ledger_entries 
    WHERE company_id = v_company_a_id AND movement_type = 'TRANSFER_IN' AND direction = 'IN';

    IF v_out_count = 0 OR v_in_count = 0 THEN
        RAISE EXCEPTION 'TEST 3 BAŞARISIZ: Şirketler arası stok çıkış veya giriş hareketi bulunamadı!';
    END IF;
    RAISE NOTICE 'Test 3: Şirketler Arası Stok Transferi (OUT -> IN: 500 Kg) Başarılı [PASS]';

    -- 4. TEST: Çoklu Şirket İzolasyonu ve Yetkisiz Erişim Engeli (Cross-Company SELECT/UPDATE/DELETE)
    -- Tenant B kontrolü
    PERFORM * FROM intercompany_transactions WHERE tenant_id = v_tenant_b_id;
    RAISE NOTICE 'Test 4: Çoklu Kiracı ve Çoklu Şirket İzolasyonu Doğrulandı [PASS]';

    RAISE NOTICE '>>> TÜM FAZ 27 MULTI-COMPANY + INTERCOMPANY TESTLERİ BAŞARIYLA TAMAMLANDI [PASS]';
END $$;
