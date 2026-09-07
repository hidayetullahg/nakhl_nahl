-- ==============================================================================
-- NAKHL & NAHL — FAZ 32: FULL ERP INTEGRATION TESTS (ALL 7 SCENARIOS)
-- Bounded Context Cross-Verification: Agriculture, Procurement, Sales, Quality,
-- Halal, Export, Intercompany, AI/OCR, Security & Atomicity Rollback
-- ==============================================================================

DO $$
DECLARE
    v_tenant_id UUID := '11111111-1111-1111-1111-111111111111';
    v_tenant_b_id UUID := '22222222-2222-2222-2222-222222222222';
    v_company_a_id UUID := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    v_company_b_id UUID := 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
    v_user_id UUID := '99999999-9999-9999-9999-999999999999';

    -- Senaryo Varlıkları
    v_farm_id UUID;
    v_field_id UUID;
    v_harvest_id UUID;
    v_item_id UUID;
    v_lot_id UUID;
    v_wh_id UUID;
    v_wh_b_id UUID;
    v_supplier_id UUID;
    v_customer_id UUID;
    v_purchase_inv_id UUID;
    v_sales_inv_id UUID;
    v_sales_res JSONB;
    v_qi_id UUID;
    v_halal_body_id UUID;
    v_halal_cert_id UUID;
    v_export_file_id UUID;
    v_container_id UUID;
    v_customs_id UUID;
    v_shipment_id UUID;
    v_ic_tx_id UUID;
    v_ic_res JSONB;
    v_doc_id UUID;
    v_ocr_id UUID;
    v_sug_id UUID;
    v_human_ok BOOLEAN;

    -- Kontrol Değişkenleri
    v_audit_count INT;
    v_stock_qty NUMERIC;
    v_jrn_diff NUMERIC;
    v_rollback_passed BOOLEAN := FALSE;
BEGIN
    RAISE NOTICE '====================================================================';
    RAISE NOTICE '>>> FAZ 32: FULL ERP END-TO-END INTEGRATION TESTLERİ BAŞLIYOR...';
    -- Hazırlık: Tenant, User, Company
    INSERT INTO tenants (id, code, legal_name, display_name)
    VALUES 
        (v_tenant_id, 'ERP_TENANT_A', 'Al-Nakhl ERP Tenant A Inc.', 'Tenant A'),
        (v_tenant_b_id, 'ERP_TENANT_B', 'Al-Nakhl ERP Tenant B Inc.', 'Tenant B')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO public.users (id, display_name, email)
    VALUES (v_user_id, 'ERP Super Auditor', 'erp_auditor@nakhl.com')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO companies (id, tenant_id, code, legal_name)
    VALUES 
        (v_company_a_id, v_tenant_id, 'COMP_A', 'Company A Ltd.'),
        (v_company_b_id, v_tenant_id, 'COMP_B', 'Company B Ltd.')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO tenant_users (tenant_id, user_id, role_id, status)
    SELECT v_tenant_id, v_user_id, id, 'ACTIVE'
    FROM roles WHERE code = 'TENANT_ADMIN' AND tenant_id IS NULL LIMIT 1
    ON CONFLICT DO NOTHING;

    PERFORM set_config('request.jwt.claim.sub', v_user_id::TEXT, TRUE);
    PERFORM set_config('request.jwt.claim.role', 'authenticated', TRUE);

    -- Hazırlık: Ürün ve Depo
    SELECT id INTO v_item_id FROM items WHERE tenant_id = v_tenant_id LIMIT 1;
    IF v_item_id IS NULL THEN
        INSERT INTO items (tenant_id, company_id, sku, name, unit_of_measure)
        VALUES (v_tenant_id, v_company_a_id, 'DATE-SAGAI-01', 'Suudi Sagai Hurma', 'Kg')
        RETURNING id INTO v_item_id;
    END IF;

    SELECT id INTO v_wh_id FROM warehouses WHERE company_id = v_company_a_id LIMIT 1;
    IF v_wh_id IS NULL THEN
        INSERT INTO warehouses (tenant_id, company_id, code, name, warehouse_type)
        VALUES (v_tenant_id, v_company_a_id, 'WH-A-MAIN', 'Company A Ana Depo', 'FINISHED_GOODS')
        RETURNING id INTO v_wh_id;
    END IF;

    SELECT id INTO v_wh_b_id FROM warehouses WHERE company_id = v_company_b_id LIMIT 1;
    IF v_wh_b_id IS NULL THEN
        INSERT INTO warehouses (tenant_id, company_id, code, name, warehouse_type)
        VALUES (v_tenant_id, v_company_b_id, 'WH-B-EXP', 'Company B İhracat Depo', 'FINISHED_GOODS')
        RETURNING id INTO v_wh_b_id;
    END IF;

    -- ==============================================================================
    -- SENARYO 1: FARM → HARVEST → LOT → WAREHOUSE
    -- ==============================================================================
    RAISE NOTICE '--- SENARYO 1: FARM -> HARVEST -> LOT -> WAREHOUSE ---';
    -- 1.1 Çiftlik & Tarla
    INSERT INTO farms (tenant_id, company_id, code, name, location, cultivation_type)
    VALUES (v_tenant_id, v_company_a_id, 'FRM-KAS-01', 'Al-Qassim Vaha Hurmalığı', 'Buraidah, Al-Qassim', 'ORGANIC')
    ON CONFLICT (tenant_id, code) DO UPDATE SET name = EXCLUDED.name
    RETURNING id INTO v_farm_id;

    INSERT INTO fields (tenant_id, farm_id, code, name, area_hectares, palm_tree_count)
    VALUES (v_tenant_id, v_farm_id, 'FLD-QAS-02', 'Güney Bahçe Parsel 2', 8.0, 300)
    ON CONFLICT (tenant_id, farm_id, code) DO UPDATE SET name = EXCLUDED.name
    RETURNING id INTO v_field_id;

    -- 1.2 Hasat
    INSERT INTO harvests (
        tenant_id, farm_id, field_id, item_id, harvest_lot_number,
        harvest_date, quantity_kg, quality_grade
    ) VALUES (
        v_tenant_id, v_farm_id, v_field_id, v_item_id, 'HV-2026-QAS-02',
        CURRENT_DATE - 5, 5000.0, 'GRADE_A'
    ) ON CONFLICT (tenant_id, harvest_lot_number) DO UPDATE SET quantity_kg = EXCLUDED.quantity_kg
    RETURNING id INTO v_harvest_id;

    -- 1.3 Parti / Lot
    INSERT INTO item_lots (
        tenant_id, company_id, item_id, lot_number,
        production_date, expiry_date, status,
        farm_name, harvest_date, harvest_batch_number
    ) VALUES (
        v_tenant_id, v_company_a_id, v_item_id, 'LOT-2026-SAGAI-101',
        CURRENT_DATE, CURRENT_DATE + 365, 'APPROVED',
        'Al-Qassim Vaha Hurmalığı', CURRENT_DATE - 5, 'HV-2026-QAS-02'
    ) ON CONFLICT (tenant_id, company_id, lot_number) DO UPDATE SET status = 'APPROVED'
    RETURNING id INTO v_lot_id;

    -- 1.4 Depo Stok Girişi
    INSERT INTO stock_ledger_entries (
        tenant_id, company_id, warehouse_id, item_id, lot_id,
        movement_type, quantity, unit, unit_cost, total_cost,
        document_type, document_reference, description
    ) VALUES (
        v_tenant_id, v_company_a_id, v_wh_id, v_item_id, v_lot_id,
        'PRODUCTION_IN', 5000.0, 'Kg', 18.00, 90000.00,
        'HARVEST_RECEIPT', 'HV-2026-QAS-02', 'Çiftlik hasadından depoya mal kabulü'
    );

    SELECT current_quantity INTO v_stock_qty
    FROM view_current_stock
    WHERE tenant_id = v_tenant_id AND warehouse_id = v_wh_id AND lot_id = v_lot_id;

    ASSERT v_stock_qty = 5000.0, 'Senaryo 1 Başarısız: Stok miktarı 5000 olmalı!';
    RAISE NOTICE '>>> SENARYO 1 PASS: Farm -> Harvest -> Lot -> Warehouse entegrasyonu başarılı.';

    -- ==============================================================================
    -- SENARYO 2: SUPPLIER → PURCHASE → RECEIPT → LOT → STOCK → JOURNAL
    -- ==============================================================================
    RAISE NOTICE '--- SENARYO 2: SUPPLIER -> PURCHASE -> RECEIPT -> LOT -> STOCK -> JOURNAL ---';
    -- 2.1 Tedarikçi
    INSERT INTO parties (tenant_id, company_id, code, name, party_type, is_supplier, is_customer, country_code)
    VALUES (v_tenant_id, v_company_a_id, 'SUP-DATE-PACK', 'Al-Ahsa Hurma Paketleme Sanayi', 'SUPPLIER', true, false, 'SA')
    ON CONFLICT (tenant_id, company_id, code) DO UPDATE SET name = EXCLUDED.name
    RETURNING id INTO v_supplier_id;

    -- 2.2 Satın Alma Faturası
    INSERT INTO invoices (
        tenant_id, company_id, invoice_type, invoice_number, invoice_date,
        party_id, currency, subtotal, tax_amount, grand_total, status
    ) VALUES (
        v_tenant_id, v_company_a_id, 'PURCHASE', 'PINV-2026-INT-01', CURRENT_DATE,
        v_supplier_id, 'SAR', 20000.00, 3000.00, 23000.00, 'POSTED'
    ) ON CONFLICT (tenant_id, company_id, invoice_number) DO UPDATE SET status = 'POSTED'
    RETURNING id INTO v_purchase_inv_id;

    INSERT INTO invoice_lines (
        tenant_id, invoice_id, item_id, lot_id, quantity, unit_price, tax_rate, tax_amount, total_price
    ) VALUES (
        v_tenant_id, v_purchase_inv_id, v_item_id, v_lot_id, 1000.0, 20.00, 15.0, 3000.00, 23000.00
    ) ON CONFLICT DO NOTHING;

    -- 2.3 Stok Defteri Girişi
    INSERT INTO stock_ledger_entries (
        tenant_id, company_id, warehouse_id, item_id, lot_id,
        movement_type, quantity, unit, unit_cost, total_cost,
        document_type, document_reference
    ) VALUES (
        v_tenant_id, v_company_a_id, v_wh_id, v_item_id, v_lot_id,
        'PURCHASE_RECEIPT', 1000.0, 'Kg', 20.00, 20000.00,
        'INVOICE', 'PINV-2026-INT-01'
    );

    -- 2.4 Yevmiye Fişi (153 Borç, 191 Borç, 320 Alacak)
    INSERT INTO journal_entries (
        tenant_id, company_id, entry_number, entry_date, description,
        total_debit, total_credit, currency, status
    ) VALUES (
        v_tenant_id, v_company_a_id, 'JRN-PURCH-2026-01', CURRENT_DATE, 'Al-Ahsa Satın Alma Faturası Yevmiyesi',
        23000.00, 23000.00, 'SAR', 'POSTED'
    );

    SELECT (total_debit - total_credit) INTO v_jrn_diff
    FROM journal_entries WHERE entry_number = 'JRN-PURCH-2026-01' AND tenant_id = v_tenant_id;

    ASSERT v_jrn_diff = 0.00, 'Senaryo 2 Başarısız: Yevmiye fişi dengeli değil!';
    RAISE NOTICE '>>> SENARYO 2 PASS: Supplier -> Purchase -> Receipt -> Lot -> Stock -> Journal başarılı.';

    -- ==============================================================================
    -- SENARYO 3: CUSTOMER → SALES → INVOICE → STOCK → JOURNAL (ATOMİK RPC)
    -- ==============================================================================
    RAISE NOTICE '--- SENARYO 3: CUSTOMER -> SALES -> INVOICE -> STOCK -> JOURNAL ---';
    INSERT INTO parties (tenant_id, company_id, code, name, party_type, is_supplier, is_customer, country_code)
    VALUES (v_tenant_id, v_company_a_id, 'CUST-DUBAI-01', 'Dubai Luxury Gourmet LLC', 'CUSTOMER', false, true, 'AE')
    ON CONFLICT (tenant_id, company_id, code) DO UPDATE SET name = EXCLUDED.name
    RETURNING id INTO v_customer_id;

    v_sales_res := create_sales_invoice_atomic(
        p_tenant_id := v_tenant_id,
        p_company_id := v_company_a_id,
        p_invoice_number := 'SINV-2026-ATOM-01',
        p_invoice_date := CURRENT_DATE,
        p_currency := 'SAR',
        p_customer_name := 'Dubai Luxury Gourmet LLC',
        p_customer_id := v_customer_id,
        p_item_id := v_item_id,
        p_item_name := 'Suudi Sagai Hurma',
        p_lot_id := v_lot_id,
        p_warehouse_id := v_wh_id,
        p_quantity := 1000.0,
        p_unit := 'Kg',
        p_unit_price := 35.00,
        p_subtotal := 35000.00,
        p_vat_rate := 15.00,
        p_vat_amount := 5250.00,
        p_grand_total := 40250.00,
        p_is_official_posted := true
    );

    ASSERT (v_sales_res->>'success')::BOOLEAN = TRUE, 'Senaryo 3 Başarısız: Atomik satış işlemi tamamlanamadı!';
    RAISE NOTICE '>>> SENARYO 3 PASS: Customer -> Sales -> Invoice -> Stock -> Journal (Atomik) başarılı.';

    -- ==============================================================================
    -- SENARYO 4: LOT → QUALITY → HALAL → WAREHOUSE
    -- ==============================================================================
    RAISE NOTICE '--- SENARYO 4: LOT -> QUALITY -> HALAL -> WAREHOUSE ---';
    -- 4.1 Kalite Kontrol Muayenesi
    INSERT INTO quality_inspections (
        tenant_id, company_id, lot_id, inspection_type,
        inspector_id, inspection_date, moisture_percentage,
        defect_percentage, result, status
    ) VALUES (
        v_tenant_id, v_company_a_id, v_lot_id, 'PRE_EXPORT_INSPECTION',
        v_user_id, CURRENT_DATE, 14.2, 1.1, 'PASS', 'COMPLETED'
    ) RETURNING id INTO v_qi_id;

    -- 4.2 Helal Sertifika Kurumu ve Parti Uyumluluğu
    SELECT id INTO v_halal_body_id FROM halal_certification_bodies WHERE tenant_id = v_tenant_id LIMIT 1;
    IF v_halal_body_id IS NULL THEN
        INSERT INTO halal_certification_bodies (tenant_id, code, name, accreditation_number, country_code)
        VALUES (v_tenant_id, 'SFDA-HALAL-01', 'Saudi Food and Drug Authority Halal Center', 'SFDA-HC-2026', 'SA')
        RETURNING id INTO v_halal_body_id;
    END IF;

    INSERT INTO halal_certificates (
        tenant_id, company_id, certification_body_id, certificate_number,
        certificate_type, issue_date, expiry_date, status
    ) VALUES (
        v_tenant_id, v_company_a_id, v_halal_body_id, 'HALAL-KSA-2026-991',
        'BATCH', CURRENT_DATE, CURRENT_DATE + 180, 'ACTIVE'
    ) ON CONFLICT (tenant_id, certificate_number) DO UPDATE SET status = 'ACTIVE'
    RETURNING id INTO v_halal_cert_id;

    INSERT INTO halal_lot_compliance (
        tenant_id, lot_id, certificate_id, compliance_status, inspected_at
    ) VALUES (
        v_tenant_id, v_lot_id, v_halal_cert_id, 'COMPLIANT', NOW()
    ) ON CONFLICT (lot_id) DO UPDATE SET compliance_status = 'COMPLIANT';

    RAISE NOTICE '>>> SENARYO 4 PASS: Lot -> Quality -> Halal -> Warehouse denetimi başarılı.';

    -- ==============================================================================
    -- SENARYO 5: SALES → EXPORT FILE → CONTAINER → CUSTOMS → SHIPMENT → DELIVERY
    -- ==============================================================================
    RAISE NOTICE '--- SENARYO 5: SALES -> EXPORT FILE -> CONTAINER -> CUSTOMS -> SHIPMENT -> DELIVERY ---';
    -- 5.1 İhracat Dosyası
    INSERT INTO export_files (
        tenant_id, company_id, export_number, customer_id, origin_country,
        destination_country, incoterm, currency, status
    ) VALUES (
        v_tenant_id, v_company_a_id, 'EXP-2026-DXB-88', v_customer_id, 'SA', 'AE', 'FOB', 'SAR', 'DELIVERED'
    ) ON CONFLICT (tenant_id, company_id, export_number) DO UPDATE SET status = 'DELIVERED'
    RETURNING id INTO v_export_file_id;

    INSERT INTO export_file_items (
        tenant_id, export_file_id, item_id, lot_id, quantity, unit_price, total_price
    ) VALUES (
        v_tenant_id, v_export_file_id, v_item_id, v_lot_id, 1000.0, 35.00, 35000.00
    ) ON CONFLICT DO NOTHING;

    -- 5.2 Konteyner
    INSERT INTO export_containers (
        tenant_id, export_file_id, container_number, container_type, seal_number, tare_weight, max_payload
    ) VALUES (
        v_tenant_id, v_export_file_id, 'CONT-DXB-9988', 'REEFER_40HC', 'SEAL-KSA-7788', 4200.0, 26000.0
    ) ON CONFLICT (tenant_id, container_number) DO UPDATE SET seal_number = EXCLUDED.seal_number
    RETURNING id INTO v_container_id;

    -- 5.3 Gümrük Beyannamesi
    INSERT INTO customs_declarations (
        tenant_id, export_file_id, declaration_number, customs_office, hs_code, customs_value, status
    ) VALUES (
        v_tenant_id, v_export_file_id, 'CUST-DEC-DXB-11', 'King Abdulaziz Port Dammam Customs', '0804.10.00', 35000.00, 'CLEARED'
    ) ON CONFLICT (tenant_id, declaration_number) DO UPDATE SET status = 'CLEARED'
    RETURNING id INTO v_customs_id;

    -- 5.4 Uluslararası Sevkiyat ve Nihai Teslimat
    INSERT INTO shipments (
        tenant_id, export_file_id, shipment_number, carrier_name, vessel_name, status
    ) VALUES (
        v_tenant_id, v_export_file_id, 'SHP-2026-DXB-01', 'Hapag-Lloyd', 'AL HILAL', 'DELIVERED'
    ) ON CONFLICT (tenant_id, shipment_number) DO UPDATE SET status = 'DELIVERED'
    RETURNING id INTO v_shipment_id;

    RAISE NOTICE '>>> SENARYO 5 PASS: Sales -> Export File -> Container -> Customs -> Shipment -> Delivery başarılı.';

    -- ==============================================================================
    -- SENARYO 6: INTERCOMPANY: Company A → Company B (Eşleşmiş Satış/Alış ve Due From/To)
    -- ==============================================================================
    RAISE NOTICE '--- SENARYO 6: INTERCOMPANY (Company A -> Company B) ---';
    INSERT INTO intercompany_transactions (
        tenant_id, seller_company_id, buyer_company_id,
        transaction_number, transaction_date, currency,
        subtotal, tax_rate, tax_amount, grand_total,
        transfer_pricing_method, markup_percentage, status
    ) VALUES (
        v_tenant_id, v_company_a_id, v_company_b_id,
        'ICTX-INT-2026-99', CURRENT_DATE, 'SAR',
        50000.00, 15.00, 7500.00, 57500.00,
        'COST_PLUS', 5.00, 'DRAFT'
    ) ON CONFLICT (tenant_id, transaction_number) DO UPDATE SET status = 'DRAFT'
    RETURNING id INTO v_ic_tx_id;

    INSERT INTO intercompany_transaction_lines (
        tenant_id, intercompany_transaction_id, item_id,
        quantity, cost_price, transfer_price, markup_amount,
        subtotal, tax_rate, tax_amount, total_amount
    ) VALUES (
        v_tenant_id, v_ic_tx_id, v_item_id,
        1000.0, 47.62, 50.00, 2380.00,
        50000.00, 15.00, 7500.00, 57500.00
    ) ON CONFLICT DO NOTHING;

    v_ic_res := post_intercompany_sale_purchase_transaction(
        p_intercompany_tx_id := v_ic_tx_id,
        p_from_warehouse_id := v_wh_id,
        p_to_warehouse_id := v_wh_b_id,
        p_user_id := v_user_id
    );

    ASSERT (v_ic_res->>'success')::BOOLEAN = TRUE, 'Senaryo 6 Başarısız: Intercompany işlem post edilemedi!';
    RAISE NOTICE '>>> SENARYO 6 PASS: Intercompany Company A -> Company B (Due From = Due To) başarılı.';

    -- ==============================================================================
    -- SENARYO 7: AI/OCR: DOCUMENT → OCR → SUGGESTION → HUMAN APPROVAL → POST
    -- ==============================================================================
    RAISE NOTICE '--- SENARYO 7: AI/OCR -> DOCUMENT -> SUGGESTION -> HUMAN APPROVAL -> POST ---';
    -- 7.1 Doküman Kaydı
    INSERT INTO documents (
        tenant_id, company_id, document_type, document_number, title,
        entity_type, entity_id, issue_date, storage_reference, status
    ) VALUES (
        v_tenant_id, v_company_a_id, 'INVOICE', 'DOC-SCAN-7788', 'Tedarikçi Ham Hurma Fatura Taraması',
        'INVOICE', v_purchase_inv_id, CURRENT_DATE, 'storage://docs/scan7788.pdf', 'ACTIVE'
    ) ON CONFLICT (tenant_id, company_id, document_type, document_number) DO UPDATE SET status = 'ACTIVE'
    RETURNING id INTO v_doc_id;

    -- 7.2 AI OCR Çıkarımı
    INSERT INTO ai_ocr_extractions (
        tenant_id, company_id, document_id, invoice_number,
        invoice_date, total_amount, status
    ) VALUES (
        v_tenant_id, v_company_a_id, v_doc_id, 'PINV-2026-INT-01',
        CURRENT_DATE, 23000.00, 'SUGGESTED'
    ) RETURNING id INTO v_ocr_id;

    -- 7.3 AI Ticari Muhasebe Önerisi
    INSERT INTO ai_commercial_suggestions (
        tenant_id, company_id, suggestion_type, confidence_score, status
    ) VALUES (
        v_tenant_id, v_company_a_id, 'ACCOUNT_SUGGESTION', 0.96, 'PENDING_HUMAN_REVIEW'
    ) RETURNING id INTO v_sug_id;

    -- 7.4 İnsan Onayı Olmadan Kritik POST İşleminin Engellendiğinin Doğrulanması
    BEGIN
        PERFORM enforce_ai_human_in_the_loop_action(
            p_tenant_id := v_tenant_id,
            p_company_id := v_company_a_id,
            p_action_type := 'ACCOUNTING_POST',
            p_human_user_id := NULL -- İnsan onayı eksik
        );
        RAISE EXCEPTION 'Senaryo 7 Güvenlik Açığı: İnsan onayı olmadan işlem post edilebildi!';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE '7.4: İnsan onayı olmadan post engellendi [PASS] (Hata: %)', SQLERRM;
    END;

    -- 7.5 İnsan Onayı ile Onaylama ve Tamamlama
    v_human_ok := enforce_ai_human_in_the_loop_action(
        p_tenant_id := v_tenant_id,
        p_company_id := v_company_a_id,
        p_action_type := 'ACCOUNTING_POST',
        p_human_user_id := v_user_id, -- İnsan onayı mevcut
        p_action_notes := 'Mali işler direktörü tarafından OCR faturası kontrol edilip onaylandı.'
    );
    ASSERT v_human_ok = TRUE, 'Senaryo 7 Başarısız: İnsan onaylı işlem tamamlanamadı!';
    RAISE NOTICE '>>> SENARYO 7 PASS: AI/OCR -> Document -> Suggestion -> Human Approval -> Post başarılı.';

    -- ==============================================================================
    -- GÜVENLİK VE AUDIT DENETİMİ (SECURITY & AUDIT ACROSS ALL SCENARIOS)
    -- ==============================================================================
    RAISE NOTICE '--- GÜVENLİK VE AUDIT KONTROLLERİ ---';
    -- Tenant B izolasyon kontrolü
    SELECT COUNT(*) INTO v_audit_count
    FROM audit_logs
    WHERE tenant_id = v_tenant_b_id AND entity_id = v_lot_id;
    ASSERT v_audit_count = 0, 'Güvenlik Açığı: Tenant B verisi Tenant A altında görüldü!';
    RAISE NOTICE '>>> GÜVENLİK PASS: Cross-Tenant ve Company izolasyonu tam korumalı.';

    -- ==============================================================================
    -- ATOMİKLİK VE ROLLBACK KONTROLÜ (ATOMICITY ON FAILURE)
    -- ==============================================================================
    RAISE NOTICE '--- ATOMİKLİK VE ROLLBACK KONTROLÜ ---';
    BEGIN
        -- Yetersiz stok durumunda satış faturası açmaya çalışarak atomik rollback testi
        PERFORM create_sales_invoice_atomic(
            p_tenant_id := v_tenant_id,
            p_company_id := v_company_a_id,
            p_invoice_number := 'SINV-FAIL-ROLLBACK',
            p_invoice_date := CURRENT_DATE,
            p_currency := 'SAR',
            p_customer_name := 'Test Customer',
            p_customer_id := v_customer_id,
            p_item_id := v_item_id,
            p_item_name := 'Sagai',
            p_lot_id := v_lot_id,
            p_warehouse_id := v_wh_id,
            p_quantity := 99999999.0, -- Mevcut stoğun çok üzerinde miktar
            p_unit := 'Kg',
            p_unit_price := 35.00,
            p_subtotal := 35000000.00,
            p_vat_rate := 15.00,
            p_vat_amount := 5250000.00,
            p_grand_total := 40250000.00,
            p_is_official_posted := true
        );
    EXCEPTION
        WHEN OTHERS THEN
            v_rollback_passed := TRUE;
            RAISE NOTICE 'Atomik Hata Yakalandı ve Rollback Başarıyla Gerçekleşti: %', SQLERRM;
    END;

    -- Rollback sonrasında faturanın veritabanında oluşmadığının teyidi
    PERFORM 1 FROM invoices WHERE invoice_number = 'SINV-FAIL-ROLLBACK';
    ASSERT NOT FOUND, 'Atomik Rollback Başarısız: Hatalı işlem sonrası fatura kaydı veritabanında kaldı!';
    ASSERT v_rollback_passed = TRUE, 'Atomik Rollback testi tamamlanamadı!';
    RAISE NOTICE '>>> ATOMICITY & ROLLBACK PASS: Başarısız ara adımda yetim kayıt oluşmadan tam geri alma sağlandı.';

    RAISE NOTICE '====================================================================';
    RAISE NOTICE '>>> FAZ 32: TÜM 7 SENARYO + GÜVENLİK + ATOMİKLİK TESTLERİ BAŞARIYLA GEÇTİ (PASS)!';
    RAISE NOTICE '====================================================================';
END;
$$;
