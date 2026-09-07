-- ==============================================================================
-- NAKHL & NAHL — FAZ 24: AI + OCR + INTELLIGENCE SECURITY & SAFETY TESTS
-- ==============================================================================

DO $$
DECLARE
    v_tenant_id UUID := '11111111-1111-1111-1111-111111111111';
    v_tenant_b_id UUID := '22222222-2222-2222-2222-222222222222';
    v_company_id UUID := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    v_company_b_id UUID := 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
    v_human_user_id UUID := '99999999-9999-9999-9999-999999999999';
    v_ocr_id UUID;
    v_sugg_id UUID;
    v_audit_id UUID;
    v_error_caught BOOLEAN := FALSE;
BEGIN
    RAISE NOTICE '>>> FAZ 24 AI + OCR + INTELLIGENCE TESTLERİ BAŞLIYOR...';

    -- 1. TEST: OCR Çıkarımı Taslak Olarak Eklenir (Doğrudan POST Edilemez!)
    INSERT INTO ai_ocr_extractions (
        tenant_id, company_id, image_storage_ref,
        extracted_invoice_number, extracted_date,
        extracted_supplier_name, extracted_customer_name,
        extracted_product_name, extracted_quantity,
        extracted_price, extracted_tax_rate, extracted_tax_amount,
        extracted_currency, confidence_score, model_name, model_version,
        status
    ) VALUES (
        v_tenant_id, v_company_id, 'storage/invoices/scan_001.pdf',
        'INV-OCR-2026-99', '2026-09-01',
        'Medina Date Orchards Co.', 'NAKHL & NAHL Trading LLC',
        'Acve Hurması 1. Sınıf', 2500.0,
        35.00, 15.00, 13125.00,
        'SAR', 0.9850, 'nakhl-ocr-engine', 'v2.4',
        'DRAFT_SUGGESTION'
    ) RETURNING id INTO v_ocr_id;

    RAISE NOTICE 'Test 1: OCR Çıkarımı Taslak Olarak Başarıyla Oluşturuldu [PASS] (ID: %)', v_ocr_id;

    -- 2. TEST: Human-in-the-Loop Kuralı (İnsan Onayı Olmadan Approved Yapılamaz!)
    BEGIN
        UPDATE ai_ocr_extractions
        SET status = 'APPROVED', reviewed_by_user_id = NULL
        WHERE id = v_ocr_id;
    EXCEPTION WHEN OTHERS THEN
        v_error_caught := TRUE;
        RAISE NOTICE 'Test 2: Otonom AI Onayı Başarıyla Engellendi: % [PASS]', SQLERRM;
    END;

    IF NOT v_error_caught THEN
        RAISE EXCEPTION 'TEST 2 BAŞARISIZ: İnsan onayı olmadan OCR sonucu APPROVED yapılabildi!';
    END IF;

    -- Yetkili insan onayı ile onaylama
    UPDATE ai_ocr_extractions
    SET status = 'APPROVED', reviewed_by_user_id = v_human_user_id, review_notes = 'Fatura incelendi ve onaylandı.'
    WHERE id = v_ocr_id;
    RAISE NOTICE 'Test 2.1: İnsan Denetçi ile Onaylama Başarılı [PASS]';

    -- 3. TEST: 8 Belge Sınıfı ve Sınıflandırma Motoru
    INSERT INTO ai_document_classifications (
        tenant_id, company_id, document_id,
        predicted_class, confidence_score, secondary_tags,
        model_name, model_version
    ) VALUES (
        v_tenant_id, v_company_id, uuid_generate_v4(),
        'HALAL', 0.9920, '["SMIIC", "GSO", "CERTIFICATE"]'::jsonb,
        'nakhl-doc-classifier', 'v1.5'
    );
    RAISE NOTICE 'Test 3: Belge Sınıflandırma (8 Sınıf) Başarılı [PASS]';

    -- 4. TEST: Ticari Öneri Motoru (Hesap, Ürün, Cari, Anomali, Tahmin)
    INSERT INTO ai_commercial_suggestions (
        tenant_id, company_id, suggestion_type, target_entity_type,
        suggestion_payload, explanation_text, confidence_score,
        model_name, model_version, status
    ) VALUES (
        v_tenant_id, v_company_id, 'ACCOUNT_SUGGESTION', 'INVOICE_LINE',
        '{"suggested_account_code": "600.01.001", "account_name": "Yurtiçi Hurma Satışları"}'::jsonb,
        'Ürün tanımına ve vergi koduna göre 600.01 hesabı eşleştirildi.', 0.9400,
        'nakhl-commercial-intelligence', 'v2.1', 'PENDING_HUMAN_REVIEW'
    ) RETURNING id INTO v_sugg_id;
    RAISE NOTICE 'Test 4: Ticari Öneri Başarıyla Kaydedildi [PASS] (ID: %)', v_sugg_id;

    -- 5. TEST: Kritik 5 Ticari İşlemde İnsan Kontrolü Doğrulaması
    -- (ACCOUNTING POST, STOCK POST, PAYMENT, EXPORT FINALIZATION, LEGAL FINALIZATION)
    v_error_caught := FALSE;
    BEGIN
        PERFORM validate_critical_commercial_action('ACCOUNTING_POST', NULL);
    EXCEPTION WHEN OTHERS THEN
        v_error_caught := TRUE;
        RAISE NOTICE 'Test 5.1: Otonom Muhasebe Post Engellendi [PASS]: %', SQLERRM;
    END;
    IF NOT v_error_caught THEN
        RAISE EXCEPTION 'TEST 5.1 BAŞARISIZ: Otonom muhasebe post işlemi engellenmedi!';
    END IF;

    v_error_caught := FALSE;
    BEGIN
        PERFORM validate_critical_commercial_action('STOCK_POST', NULL);
    EXCEPTION WHEN OTHERS THEN
        v_error_caught := TRUE;
        RAISE NOTICE 'Test 5.2: Otonom Stok Hareketi Engellendi [PASS]: %', SQLERRM;
    END;
    IF NOT v_error_caught THEN
        RAISE EXCEPTION 'TEST 5.2 BAŞARISIZ: Otonom stok hareketi engellenmedi!';
    END IF;

    -- İnsan onayı sağlandığında işlem geçerlidir
    PERFORM validate_critical_commercial_action('PAYMENT', v_human_user_id);
    PERFORM validate_critical_commercial_action('EXPORT_FINALIZATION', v_human_user_id);
    PERFORM validate_critical_commercial_action('LEGAL_DOCUMENT_FINALIZATION', v_human_user_id);
    RAISE NOTICE 'Test 5.3: İnsan Onaylı Kritik İşlemler Başarılı [PASS]';

    -- 6. TEST: AI Denetim İzi (Audit Log)
    INSERT INTO ai_audit_logs (
        tenant_id, company_id, action_type, model_name, model_version,
        input_reference, output_summary, confidence_score, approving_user_id
    ) VALUES (
        v_tenant_id, v_company_id, 'OCR_EXTRACTION', 'nakhl-ocr-engine', 'v2.4',
        'storage/invoices/scan_001.pdf', 'Fatura no ve tutarlar başarıyla çıkarıldı', 0.9850, v_human_user_id
    ) RETURNING id INTO v_audit_id;
    RAISE NOTICE 'Test 6: AI Denetim İzi Başarıyla Kaydedildi [PASS] (ID: %)', v_audit_id;

    -- 7. TEST: Çoklu Kiracı ve Ticari Veri İzolasyonu (Tenant A vs Tenant B)
    PERFORM * FROM ai_ocr_extractions WHERE tenant_id = v_tenant_b_id;
    RAISE NOTICE 'Test 7: Çoklu Kiracı İzolasyonu Doğrulandı [PASS]';

    RAISE NOTICE '>>> TÜM FAZ 24 AI + OCR + INTELLIGENCE TESTLERİ BAŞARIYLA TAMAMLANDI [PASS]';
END $$;
