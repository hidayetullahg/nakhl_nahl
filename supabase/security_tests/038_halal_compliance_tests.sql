-- ==============================================================================
-- NAKHL & NAHL — FAZ 18 TEST SUITE: HALAL COMPLIANCE BOUNDED CONTEXT
-- File: supabase/security_tests/038_halal_compliance_tests.sql
-- Purpose:
-- 1. Halal Master (Certification Body, Certificate, Scope, Validity)
-- 2. Expiry Enforcement: Süresi dolan sertifikaların VALID/ACTIVE olarak reddedilmesi
-- 3. Product & Lot Halal Traceability
-- 4. Supplier Halal Compliance
-- 5. Facility & Process-Step Halal Certification
-- 6. Shipment Halal Documents Linking
-- 7. AI Advisory vs Human Final Decision Enforcement
-- 8. Certificate Change Audit Logging (audit_logs)
-- ==============================================================================

DO $$
DECLARE
    v_tenant_id UUID;
    v_company_id UUID;
    v_user_auditor UUID;
    v_role_admin UUID;
    v_party_supplier UUID;
    v_party_customer UUID;
    v_unit_id UUID;
    v_item_id UUID;
    v_lot_id UUID;
    v_body_gimdes UUID;
    v_cert_valid UUID;
    v_cert_expired UUID;
    v_sales_order_id UUID;
    v_advisory_id UUID;
    
    v_is_valid BOOLEAN;
    v_audit_count INT;
    v_exception_caught BOOLEAN;
    v_test_count INT := 0;
    v_pass_count INT := 0;
BEGIN
    RAISE NOTICE '====================================================================';
    RAISE NOTICE '=== FAZ 18: HALAL COMPLIANCE BOUNDED CONTEXT TESTLERİ BAŞLIYOR   ===';
    RAISE NOTICE '====================================================================';

    -- 0. KURULUM (SETUP)
    SELECT id INTO v_role_admin FROM roles WHERE code = 'TENANT_ADMIN' AND tenant_id IS NULL LIMIT 1;

    INSERT INTO tenants (code, legal_name, display_name)
    VALUES ('HALAL_TENANT', 'Halal Compliance Tenant', 'HCT')
    RETURNING id INTO v_tenant_id;

    INSERT INTO public.users (display_name, email)
    VALUES ('Halal Lead Auditor', 'halal_auditor@nakhl-test.com')
    RETURNING id INTO v_user_auditor;

    INSERT INTO tenant_users (tenant_id, user_id, role_id, status)
    VALUES (v_tenant_id, v_user_auditor, v_role_admin, 'ACTIVE');

    INSERT INTO companies (tenant_id, code, legal_name)
    VALUES (v_tenant_id, 'HL_COMP', 'NAKHL Helal Gıda ve Hurma A.Ş.')
    RETURNING id INTO v_company_id;

    -- Tesis / İşletme Birimi (Business Unit)
    INSERT INTO business_units (tenant_id, company_id, code, name, unit_type)
    VALUES (v_tenant_id, v_company_id, 'BU-FAC-01', 'Medine Hurma İşleme ve Paketleme Tesisi', 'PROCESSING_PLANT')
    RETURNING id INTO v_unit_id;

    -- Tedarikçi Partisi
    INSERT INTO parties (tenant_id, party_type, legal_name, trade_name)
    VALUES (v_tenant_id, 'SUPPLIER', 'Medine Organik Çiftçiler Birliği', 'Medina Organic Suppliers')
    RETURNING id INTO v_party_supplier;

    -- Müşteri Partisi
    INSERT INTO parties (tenant_id, party_type, legal_name, trade_name)
    VALUES (v_tenant_id, 'CUSTOMER', 'El-Bereke Global Gıda İthalat A.Ş.', 'El-Bereke Global')
    RETURNING id INTO v_party_customer;

    -- Ürün Master (Halal Required = TRUE)
    INSERT INTO items (
        tenant_id, company_id, item_code, sku, item_name,
        category_name, base_unit, product_type, halal_required, halal_scope_notes
    ) VALUES (
        v_tenant_id, v_company_id, 'HL-AJW-01', 'SKU-AJWA-1KG', 'Acve Medine Hurması (Özel Seçim)',
        'Hurma', 'Kg', 'FINISHED_GOOD', TRUE, 'OIC/SMIIC 1:2019 standardı kapsamında helal sertifikalı'
    ) RETURNING id INTO v_item_id;

    -- Belgelendirme Kuruluşu
    SELECT id INTO v_body_gimdes FROM halal_certification_bodies WHERE code = 'GIMDES' LIMIT 1;
    IF v_body_gimdes IS NULL THEN
        INSERT INTO halal_certification_bodies (code, name, country_code)
        VALUES ('GIMDES', 'GİMDES Helal Gıda Denetleme ve Sertifikalama', 'TR')
        RETURNING id INTO v_body_gimdes;
    END IF;


    -- =========================================================================
    -- TEST 1: GEÇERLİ HELAL SERTİFİKASI OLUŞTURMA & KAPSAM
    -- =========================================================================
    v_test_count := v_test_count + 1;
    RAISE NOTICE 'TEST 1: Geçerli Helal Sertifikası ve Kapsam Oluşturma...';

    INSERT INTO halal_certificates (
        tenant_id, company_id, body_id, certificate_number, standard_reference,
        issue_date, expiry_date, status, scope_description, notes
    ) VALUES (
        v_tenant_id, v_company_id, v_body_gimdes, 'CERT-GIMDES-2026-001', 'OIC/SMIIC 1:2019',
        CURRENT_DATE - INTERVAL '30 days', CURRENT_DATE + INTERVAL '335 days', 'VALID',
        'Acve, Mebrûm ve Sugai Hurmaları İşleme, Paketleme ve İhracatı', 'Yıllık gözetim denetimi tamamlandı'
    ) RETURNING id INTO v_cert_valid;

    v_is_valid := is_halal_certificate_valid(v_cert_valid);

    RAISE NOTICE '  EXPECTED: is_halal_certificate_valid = TRUE';
    RAISE NOTICE '  ACTUAL:   is_halal_certificate_valid = %', v_is_valid;

    IF v_is_valid = TRUE THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL (Geçerli sertifika doğrulanamadı!)';
    END IF;


    -- =========================================================================
    -- TEST 2: EXPIRY KURALI — SÜRESİ DOLAN SERTİFİKALARI VALID KABUL ETMEME
    -- =========================================================================
    v_test_count := v_test_count + 1;
    RAISE NOTICE 'TEST 2: Süresi Dolan Sertifikanın VALID/ACTIVE Olarak Kaydedilmesinin Engellenmesi...';

    v_exception_caught := FALSE;
    BEGIN
        INSERT INTO halal_certificates (
            tenant_id, company_id, body_id, certificate_number, standard_reference,
            issue_date, expiry_date, status, scope_description
        ) VALUES (
            v_tenant_id, v_company_id, v_body_gimdes, 'CERT-EXPIRED-999', 'OIC/SMIIC 1:2019',
            CURRENT_DATE - INTERVAL '400 days', CURRENT_DATE - INTERVAL '35 days', 'VALID',
            'Süresi dolmuş sertifika denemesi'
        ) RETURNING id INTO v_cert_expired;
    EXCEPTION WHEN OTHERS THEN
        v_exception_caught := TRUE;
        RAISE NOTICE '  YAKALANAN HATA (BEKLENEN): %', SQLERRM;
    END;

    RAISE NOTICE '  EXPECTED: Exception caught = TRUE (Süresi dolan sertifika VALID kabul edilemez)';
    RAISE NOTICE '  ACTUAL:   Exception caught = %', v_exception_caught;

    IF v_exception_caught THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL (Süresi dolmuş sertifika VALID olarak eklenebildi!)';
    END IF;


    -- =========================================================================
    -- TEST 3: PARTİ/LOT BAZLI HELAL İZLENEBİLİRLİĞİ (LOT TRACEABILITY)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    RAISE NOTICE 'TEST 3: Parti / Lot Bazlı Helal İzlenebilirliği...';

    INSERT INTO item_lots (
        tenant_id, company_id, item_id, lot_number,
        initial_quantity, remaining_quantity,
        halal_certified, halal_certificate_id, halal_compliance_status,
        farm_name, harvest_date
    ) VALUES (
        v_tenant_id, v_company_id, v_item_id, 'LOT-HL-2026-001',
        5000, 5000,
        TRUE, v_cert_valid, 'COMPLIANT',
        'Al-Ula Medine Çiftliği', CURRENT_DATE - INTERVAL '15 days'
    ) RETURNING id INTO v_lot_id;

    -- Kontrol
    IF EXISTS (
        SELECT 1 FROM item_lots
        WHERE id = v_lot_id 
          AND halal_certificate_id = v_cert_valid
          AND halal_compliance_status = 'COMPLIANT'
    ) THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS (Lot başarıyla helal sertifikasına bağlandı ve izlenebilir)';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL (Lot helal izlenebilirlik bağlantısı kurulamadı)';
    END IF;


    -- =========================================================================
    -- TEST 4: TEDARİKÇİ HELAL UYGUNLUK (SUPPLIER HALAL COMPLIANCE)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    RAISE NOTICE 'TEST 4: Tedarikçi Helal Uygunluk Kaydı...';

    INSERT INTO supplier_halal_compliance (
        tenant_id, company_id, supplier_party_id, certificate_id,
        compliance_status, audit_date, valid_until, notes
    ) VALUES (
        v_tenant_id, v_company_id, v_party_supplier, v_cert_valid,
        'COMPLIANT', CURRENT_DATE - INTERVAL '20 days', CURRENT_DATE + INTERVAL '300 days',
        'Tedarikçi yerinde SMIIC denetimi başarıyla tamamlandı'
    );

    IF EXISTS (
        SELECT 1 FROM supplier_halal_compliance
        WHERE supplier_party_id = v_party_supplier
          AND compliance_status = 'COMPLIANT'
    ) THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS (Tedarikçi helal uygunluğu doğrulandı)';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL (Tedarikçi helal uygunluğu bulunamadı)';
    END IF;


    -- =========================================================================
    -- TEST 5: TESİS & PROSES ADIMI HELAL SERTİFİKASYONU
    -- =========================================================================
    v_test_count := v_test_count + 1;
    RAISE NOTICE 'TEST 5: Tesis ve Proses Adımlarının Helal Uygunluğu...';

    INSERT INTO facility_halal_certifications (
        tenant_id, company_id, business_unit_id, certificate_id,
        process_step, is_halal_certified, inspector_name, notes
    ) VALUES 
        (v_tenant_id, v_company_id, v_unit_id, v_cert_valid, 'SORTING', TRUE, 'Müh. Ahmet Yılmaz', 'Optik boylama hattı temizlendi'),
        (v_tenant_id, v_company_id, v_unit_id, v_cert_valid, 'WASHING', TRUE, 'Müh. Ahmet Yılmaz', 'Arıtılmış ozonlu helal su hattı'),
        (v_tenant_id, v_company_id, v_unit_id, v_cert_valid, 'PACKAGING', TRUE, 'Müh. Ahmet Yılmaz', 'Gıda temasına uygun vakumlu paketleme');

    IF (SELECT COUNT(*) FROM facility_halal_certifications WHERE business_unit_id = v_unit_id) = 3 THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS (3 proses adımı da helal sertifikalı olarak doğrulandı)';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL (Tesis proses adımları eksik veya doğrulanamadı)';
    END IF;


    -- =========================================================================
    -- TEST 6: SEVKİYAT İÇİN HELAL BELGELERİNİN İLİŞKİLENDİRİLMESİ
    -- =========================================================================
    v_test_count := v_test_count + 1;
    RAISE NOTICE 'TEST 6: Sevkiyat İçin Gerekli Helal Belgelerinin İlişkilendirilmesi...';

    -- Sipariş oluştur
    INSERT INTO sales_orders (
        tenant_id, company_id, order_number, customer_party_id,
        order_date, total_amount, currency
    ) VALUES (
        v_tenant_id, v_company_id, 'SO-EXP-2026-001', v_party_customer,
        CURRENT_DATE, 75000.00, 'USD'
    ) RETURNING id INTO v_sales_order_id;

    -- Sevkiyat Helal Belgeleri
    INSERT INTO shipment_halal_documents (
        tenant_id, company_id, sales_order_id, certificate_id,
        document_type, document_number, document_url
    ) VALUES 
        (v_tenant_id, v_company_id, v_sales_order_id, v_cert_valid, 'BATCH_HALAL_CERTIFICATE', 'BATCH-HL-2026-981', 'https://docs.nakhl.com/halal/batch-981.pdf'),
        (v_tenant_id, v_company_id, v_sales_order_id, v_cert_valid, 'SMIIC_EXPORT_PERMIT', 'EXP-SMIIC-2026-44', 'https://docs.nakhl.com/halal/smiic-44.pdf');

    IF (SELECT COUNT(*) FROM shipment_halal_documents WHERE sales_order_id = v_sales_order_id) = 2 THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS (Sevkiyat helal ihracat belgeleri başarıyla bağlandı)';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL (Sevkiyat helal belgeleri eksik)';
    END IF;


    -- =========================================================================
    -- TEST 7: AI ÖNERİ/UYARI & İNSAN NİHAİ KARARI KURALI
    -- =========================================================================
    v_test_count := v_test_count + 1;
    RAISE NOTICE 'TEST 7: AI Öneri Kaydı & İnsan Nihai Karar Kuralının Denetlenmesi...';

    -- AI öneri üretir (human_decision varsayılan PENDING)
    INSERT INTO halal_ai_advisories (
        tenant_id, company_id, target_type, target_id,
        risk_score, ai_recommendation_text, ai_flags
    ) VALUES (
        v_tenant_id, v_company_id, 'LOT', v_lot_id,
        12.50, 'Parti sertifikası ve tedarikçi uygunluğu günceldir. Kritik risk tespit edilmedi. Onay önerilir.',
        '[{"code": "TEMP_NORMAL", "severity": "INFO"}]'::jsonb
    ) RETURNING id INTO v_advisory_id;

    -- 7a: AI'nın tek başına onay vermesi (human_reviewer_user_id OLMADAN) engellenmeli!
    v_exception_caught := FALSE;
    BEGIN
        UPDATE halal_ai_advisories
        SET human_decision = 'APPROVED',
            human_reviewer_user_id = NULL
        WHERE id = v_advisory_id;
    EXCEPTION WHEN OTHERS THEN
        v_exception_caught := TRUE;
        RAISE NOTICE '  YAKALANAN HATA (BEKLENEN): %', SQLERRM;
    END;

    IF NOT v_exception_caught THEN
        RAISE EXCEPTION '  RESULT:   FAIL (AI insan denetçi olmadan onay verebildi!)';
    END IF;

    -- 7b: Yetkili insan denetçi onay verdiğinde işlem başarılı olmalı
    UPDATE halal_ai_advisories
    SET human_decision = 'APPROVED',
        human_reviewer_user_id = v_user_auditor,
        human_decision_notes = 'GİMDES sertifikası ve SMIIC 1 standartları kontrol edilerek ihracat partisi onaylandı.'
    WHERE id = v_advisory_id;

    IF EXISTS (
        SELECT 1 FROM halal_ai_advisories
        WHERE id = v_advisory_id
          AND human_decision = 'APPROVED'
          AND human_reviewer_user_id = v_user_auditor
          AND decided_at IS NOT NULL
    ) THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS (AI önerisi sonrası insan denetçi nihai kararı zorunluluğu doğrulandı)';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL (İnsan denetçi onayı kaydedilemedi)';
    END IF;


    -- =========================================================================
    -- TEST 8: SERTİFİKA DEĞİŞİKLİKLERİNİN AUDIT LOGGING KONTROLÜ
    -- =========================================================================
    v_test_count := v_test_count + 1;
    RAISE NOTICE 'TEST 8: Sertifika Değişikliklerinin audit_logs İçerisinde Denetlenmesi...';

    -- Sertifikayı güncelle (örn: status değiştir)
    UPDATE halal_certificates
    SET notes = 'Periyodik denetim notu güncellendi'
    WHERE id = v_cert_valid;

    SELECT COUNT(*) INTO v_audit_count
    FROM audit_logs
    WHERE tenant_id = v_tenant_id 
      AND entity_type = 'halal_certificate';

    RAISE NOTICE '  EXPECTED: audit_count >= 2 (INSERT + UPDATE)';
    RAISE NOTICE '  ACTUAL:   audit_count = %', v_audit_count;

    IF v_audit_count >= 2 THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL (Helal sertifika audit kayıtları bulunamadı!)';
    END IF;


    -- =========================================================================
    -- TEST RAPORU
    -- =========================================================================
    RAISE NOTICE '====================================================================';
    RAISE NOTICE '=== FAZ 18 TEST SONUÇLARI: % / % TEST BAŞARIYLA GEÇTİ (PASS)     ===', v_pass_count, v_test_count;
    RAISE NOTICE '====================================================================';

    -- Temizlik (Test verilerini temizle)
    DELETE FROM audit_logs WHERE tenant_id = v_tenant_id;
    DELETE FROM halal_ai_advisories WHERE tenant_id = v_tenant_id;
    DELETE FROM shipment_halal_documents WHERE tenant_id = v_tenant_id;
    DELETE FROM sales_orders WHERE tenant_id = v_tenant_id;
    DELETE FROM facility_halal_certifications WHERE tenant_id = v_tenant_id;
    DELETE FROM supplier_halal_compliance WHERE tenant_id = v_tenant_id;
    DELETE FROM item_lots WHERE tenant_id = v_tenant_id;
    DELETE FROM items WHERE tenant_id = v_tenant_id;
    DELETE FROM halal_certificates WHERE tenant_id = v_tenant_id;
    DELETE FROM business_units WHERE tenant_id = v_tenant_id;
    DELETE FROM parties WHERE tenant_id = v_tenant_id;
    DELETE FROM companies WHERE tenant_id = v_tenant_id;
    DELETE FROM tenant_users WHERE tenant_id = v_tenant_id;
    DELETE FROM public.users WHERE id = v_user_auditor;
    DELETE FROM tenants WHERE id = v_tenant_id;

    RAISE NOTICE '=== TEST VERİLERİ BAŞARIYLA TEMİZLENDİ ===';
END $$;
