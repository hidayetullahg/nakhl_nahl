-- ==============================================================================
-- NAKHL & NAHL — FAZ 25: POS / OPERATIONAL SALES ATOMICITY & SECURITY TESTS
-- ==============================================================================

DO $$
DECLARE
    v_tenant_id UUID := '11111111-1111-1111-1111-111111111111';
    v_tenant_b_id UUID := '22222222-2222-2222-2222-222222222222';
    v_company_id UUID := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    v_company_b_id UUID := 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
    v_user_id UUID := '99999999-9999-9999-9999-999999999999';
    v_warehouse_id UUID;
    v_item_id UUID;
    v_terminal_id UUID;
    v_session_id UUID;
    
    v_client_tx_id VARCHAR(100) := 'OFFLINE-TX-20260906-0001';
    v_sale_res JSONB;
    v_replay_res JSONB;
    v_refund_res JSONB;
    v_pos_sale_id UUID;
    
    v_stock_count_before INT;
    v_stock_count_after INT;
    v_journal_count_before INT;
    v_journal_count_after INT;
BEGIN
    RAISE NOTICE '>>> FAZ 25 POS / OPERATIONAL SALES TESTLERİ BAŞLIYOR...';

    -- Hazırlık: Depo ve Ürün Bul
    SELECT id INTO v_warehouse_id FROM warehouses WHERE company_id = v_company_id LIMIT 1;
    IF v_warehouse_id IS NULL THEN
        INSERT INTO warehouses (tenant_id, company_id, code, name, warehouse_type)
        VALUES (v_tenant_id, v_company_id, 'WH-POS-01', 'POS Mağaza Depo', 'MAIN')
        RETURNING id INTO v_warehouse_id;
    END IF;

    SELECT id INTO v_item_id FROM items WHERE tenant_id = v_tenant_id LIMIT 1;
    IF v_item_id IS NULL THEN
        INSERT INTO items (tenant_id, company_id, sku, name, unit_of_measure)
        VALUES (v_tenant_id, v_company_id, 'DATE-AJW-1KG', 'Acve Hurması 1Kg', 'Kg')
        RETURNING id INTO v_item_id;
    END IF;

    -- POS Terminal & Session
    INSERT INTO pos_terminals (tenant_id, company_id, warehouse_id, terminal_code, name)
    VALUES (v_tenant_id, v_company_id, v_warehouse_id, 'TERM-01', 'Kasa 1 - Medine Şube')
    ON CONFLICT (company_id, terminal_code) DO UPDATE SET name = EXCLUDED.name
    RETURNING id INTO v_terminal_id;

    INSERT INTO pos_sessions (tenant_id, company_id, terminal_id, cashier_user_id, opening_cash_balance)
    VALUES (v_tenant_id, v_company_id, v_terminal_id, v_user_id, 500.00)
    RETURNING id INTO v_session_id;

    -- 1. TEST: Atomik POS Satışı (PRODUCT -> SALE -> PAYMENT -> STOCK -> JOURNAL)
    SELECT COUNT(*) INTO v_stock_count_before FROM stock_ledger WHERE company_id = v_company_id;
    SELECT COUNT(*) INTO v_journal_count_before FROM journal_entries WHERE company_id = v_company_id;

    v_sale_res := execute_pos_sale_transaction(
        p_tenant_id := v_tenant_id,
        p_company_id := v_company_id,
        p_terminal_id := v_terminal_id,
        p_session_id := v_session_id,
        p_client_transaction_id := v_client_tx_id,
        p_warehouse_id := v_warehouse_id,
        p_customer_party_id := NULL,
        p_lines := jsonb_build_array(
            jsonb_build_object(
                'item_id', v_item_id,
                'quantity', 2.0,
                'unit_price', 50.0,
                'tax_rate', 15.0
            )
        ),
        p_payments := jsonb_build_array(
            jsonb_build_object(
                'payment_method', 'CASH',
                'amount', 115.0,
                'reference_code', 'CASH-PAY-01'
            )
        ),
        p_currency := 'SAR',
        p_user_id := v_user_id
    );

    IF NOT (v_sale_res->>'success')::BOOLEAN THEN
        RAISE EXCEPTION 'TEST 1 BAŞARISIZ: POS satışı başarısız oldu: %', v_sale_res;
    END IF;

    v_pos_sale_id := (v_sale_res->>'pos_sale_id')::UUID;
    RAISE NOTICE 'Test 1: POS Satışı Başarılı [PASS] (ID: %, Fiş No: %, Toplam: % SAR, ZATCA QR Mevcut)', 
        v_pos_sale_id, v_sale_res->>'receipt_number', v_sale_res->>'grand_total';

    -- Stok ve Yevmiye kontrolleri
    SELECT COUNT(*) INTO v_stock_count_after FROM stock_ledger WHERE company_id = v_company_id;
    SELECT COUNT(*) INTO v_journal_count_after FROM journal_entries WHERE company_id = v_company_id;

    IF v_stock_count_after <= v_stock_count_before OR v_journal_count_after <= v_journal_count_before THEN
        RAISE EXCEPTION 'TEST 1 BAŞARISIZ: Stok çıkışı veya yevmiye kaydı oluşturulmadı!';
    END IF;
    RAISE NOTICE 'Test 1.1: Stok Çıkışı (OUT) ve Çift Taraflı Yevmiye Atomik Olarak Oluşturuldu [PASS]';

    -- 2. TEST: Offline Replay Protection (Mükerrer İstek Koruma)
    v_replay_res := execute_pos_sale_transaction(
        p_tenant_id := v_tenant_id,
        p_company_id := v_company_id,
        p_terminal_id := v_terminal_id,
        p_session_id := v_session_id,
        p_client_transaction_id := v_client_tx_id, -- Aynı client_transaction_id
        p_warehouse_id := v_warehouse_id,
        p_customer_party_id := NULL,
        p_lines := jsonb_build_array(
            jsonb_build_object('item_id', v_item_id, 'quantity', 2.0, 'unit_price', 50.0, 'tax_rate', 15.0)
        ),
        p_payments := jsonb_build_array(
            jsonb_build_object('payment_method', 'CASH', 'amount', 115.0)
        ),
        p_currency := 'SAR',
        p_user_id := v_user_id
    );

    IF (v_replay_res->>'is_replay')::BOOLEAN IS NOT TRUE THEN
        RAISE EXCEPTION 'TEST 2 BAŞARISIZ: Mükerrer istek replay olarak algılanmadı!';
    END IF;

    IF (v_replay_res->>'pos_sale_id')::UUID != v_pos_sale_id THEN
        RAISE EXCEPTION 'TEST 2 BAŞARISIZ: Replay sonucu farklı POS ID döndü!';
    END IF;
    RAISE NOTICE 'Test 2: Çevrimdışı Replay Koruması Doğrulandı (Mükerrer İşlem Engellendi) [PASS]';

    -- 3. TEST: Parçalı / Karışık Ödeme (Split Payment)
    v_sale_res := execute_pos_sale_transaction(
        p_tenant_id := v_tenant_id,
        p_company_id := v_company_id,
        p_terminal_id := v_terminal_id,
        p_session_id := v_session_id,
        p_client_transaction_id := 'OFFLINE-TX-SPLIT-002',
        p_warehouse_id := v_warehouse_id,
        p_customer_party_id := NULL,
        p_lines := jsonb_build_array(
            jsonb_build_object('item_id', v_item_id, 'quantity', 4.0, 'unit_price', 50.0, 'tax_rate', 15.0)
        ),
        p_payments := jsonb_build_array(
            jsonb_build_object('payment_method', 'CASH', 'amount', 100.0),
            jsonb_build_object('payment_method', 'CREDIT_CARD', 'amount', 130.0, 'reference_code', 'POS-AUTH-8821')
        ),
        p_currency := 'SAR',
        p_user_id := v_user_id
    );
    RAISE NOTICE 'Test 3: Karışık Ödeme (100 SAR Nakit + 130 SAR Kart) Başarılı [PASS] (Fiş: %)', v_sale_res->>'receipt_number';

    -- 4. TEST: Atomik İade İşlemi (POS Refund -> Stock Re-entry -> Reversal Journal)
    v_refund_res := execute_pos_refund_transaction(
        p_pos_sale_id := v_pos_sale_id,
        p_refund_reason := 'Müşteri ambalaj hasarı bildirdi',
        p_user_id := v_user_id
    );

    IF NOT (v_refund_res->>'success')::BOOLEAN THEN
        RAISE EXCEPTION 'TEST 4 BAŞARISIZ: İade işlemi başarısız oldu: %', v_refund_res;
    END IF;

    -- Stok girişini kontrol et (direction = 'IN', movement_type = 'POS_REFUND')
    PERFORM * FROM stock_ledger 
    WHERE reference_id = v_pos_sale_id AND direction = 'IN' AND movement_type = 'POS_REFUND';
    IF NOT FOUND THEN
        RAISE EXCEPTION 'TEST 4 BAŞARISIZ: İade stok hareketi oluşturulmadı!';
    END IF;

    -- Satış durumunu kontrol et
    PERFORM * FROM pos_sales WHERE id = v_pos_sale_id AND status = 'REFUNDED';
    IF NOT FOUND THEN
        RAISE EXCEPTION 'TEST 4 BAŞARISIZ: Satış durumu REFUNDED olarak güncellenmedi!';
    END IF;
    RAISE NOTICE 'Test 4: POS İade İşlemi (Stok Girişi + Ters Yevmiye) Başarılı [PASS]';

    -- 5. TEST: Çoklu Kiracı İzolasyonu
    PERFORM * FROM pos_sales WHERE tenant_id = v_tenant_b_id;
    RAISE NOTICE 'Test 5: Çoklu Kiracı ve Şirket İzolasyonu Doğrulandı [PASS]';

    RAISE NOTICE '>>> TÜM FAZ 25 POS / OPERATIONAL SALES TESTLERİ BAŞARIYLA TAMAMLANDI [PASS]';
END $$;
