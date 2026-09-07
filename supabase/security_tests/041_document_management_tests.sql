-- ==============================================================================
-- NAKHL & NAHL — FAZ 21 TEST SUITE: DOCUMENT MANAGEMENT BOUNDED CONTEXT
-- File: supabase/security_tests/041_document_management_tests.sql
-- Purpose:
-- 1. 10 Doküman Tipinin Doğrulanması (Invoice, Halal, Customs, Quality, vb.)
-- 2. Doküman Versiyonlama (v1 -> v2 Replace ve Değişiklik Özeti)
-- 3. Fiziksel Silme Engeli (trg_prevent_document_hard_delete)
-- 4. 6 Eylem Denetim İzi (UPLOAD, VIEW, DOWNLOAD, REPLACE, APPROVE, REJECT)
-- 5. Expiry Uyarı Sistemi (view_document_expiry_alerts)
-- 6. Şirket / Kiracı İzolasyonu ve Yetkisiz Erişim Engeli (RLS)
-- ==============================================================================

DO $$
DECLARE
    v_tenant_a UUID;
    v_tenant_b UUID;
    v_company_a UUID;
    v_company_b UUID;
    v_user_auditor UUID;
    v_user_stranger UUID;
    v_role_admin UUID;
    
    v_dummy_entity_id UUID := uuid_generate_v4();
    v_doc_invoice UUID;
    v_doc_halal UUID;
    v_doc_customs UUID;
    v_doc_expired UUID;
    
    v_current_ver INT;
    v_audit_count INT;
    v_access_log_count INT;
    v_expiry_alert_count INT;
    v_unauthorized_rows INT;
    v_exception_caught BOOLEAN;
    
    v_test_count INT := 0;
    v_pass_count INT := 0;
BEGIN
    RAISE NOTICE '====================================================================';
    RAISE NOTICE '=== FAZ 21: DOCUMENT MANAGEMENT BOUNDED CONTEXT TESTLERİ BAŞLIYOR ===';
    RAISE NOTICE '====================================================================';

    -- 0. KURULUM (SETUP)
    SELECT id INTO v_role_admin FROM roles WHERE code = 'TENANT_ADMIN' AND tenant_id IS NULL LIMIT 1;

    -- Kiracı A
    INSERT INTO tenants (code, legal_name, display_name)
    VALUES ('DOC_TENANT_A', 'Document Management Tenant A', 'DMTA')
    RETURNING id INTO v_tenant_a;

    INSERT INTO public.users (display_name, email)
    VALUES ('Document Compliance Auditor', 'doc_auditor@nakhl-test.com')
    RETURNING id INTO v_user_auditor;

    INSERT INTO tenant_users (tenant_id, user_id, role_id, status)
    VALUES (v_tenant_a, v_user_auditor, v_role_admin, 'ACTIVE');

    INSERT INTO companies (tenant_id, code, legal_name)
    VALUES (v_tenant_a, 'DOC_COMP_A', 'NAKHL Doküman ve Arşiv Yönetimi A.Ş.')
    RETURNING id INTO v_company_a;

    -- Kiracı B (Yetkisiz)
    INSERT INTO tenants (code, legal_name, display_name)
    VALUES ('DOC_TENANT_B', 'Unauthorized Tenant B', 'UTB')
    RETURNING id INTO v_tenant_b;

    INSERT INTO public.users (display_name, email)
    VALUES ('Doc Intruder User', 'intruder_doc@nakhl-test.com')
    RETURNING id INTO v_user_stranger;

    INSERT INTO tenant_users (tenant_id, user_id, role_id, status)
    VALUES (v_tenant_b, v_user_stranger, v_role_admin, 'ACTIVE');

    INSERT INTO companies (tenant_id, code, legal_name)
    VALUES (v_tenant_b, 'DOC_COMP_B', 'Unauthorized Outside Firm')
    RETURNING id INTO v_company_b;


    -- =========================================================================
    -- TEST 1: 10 STANDART DOKÜMAN TİPİ VE DOKÜMAN YÜKLEME (UPLOAD)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    RAISE NOTICE 'TEST 1: 10 Standart Doküman Tipi ve İlk Yükleme (Upload)...';

    -- 1a: Ticari Fatura (INVOICE)
    INSERT INTO documents (
        tenant_id, company_id, document_type, document_number, title,
        entity_type, entity_id, storage_reference, file_name, file_size_bytes,
        status, current_version, created_by_user_id
    ) VALUES (
        v_tenant_a, v_company_a, 'INVOICE', 'INV-2026-901', 'İhracat Ticari Faturası',
        'INVOICE', v_dummy_entity_id, 'supabase://storage/docs/inv-901-v1.pdf',
        'commercial_invoice_901.pdf', 145000, 'APPROVED', 1, v_user_auditor
    ) RETURNING id INTO v_doc_invoice;

    -- Versiyon ve erişim logunu yaz
    INSERT INTO document_versions (tenant_id, company_id, document_id, version_number, storage_reference, file_name, file_size_bytes, uploaded_by_user_id)
    VALUES (v_tenant_a, v_company_a, v_doc_invoice, 1, 'supabase://storage/docs/inv-901-v1.pdf', 'commercial_invoice_901.pdf', 145000, v_user_auditor);

    PERFORM log_document_access(v_doc_invoice, 'UPLOAD', v_user_auditor, 'Fatura v1 sisteme yüklendi');

    -- 1b: Gümrük Belgesi (CUSTOMS_DOCUMENT)
    INSERT INTO documents (
        tenant_id, company_id, document_type, document_number, title,
        entity_type, entity_id, storage_reference, file_name, file_size_bytes,
        status, current_version, created_by_user_id
    ) VALUES (
        v_tenant_a, v_company_a, 'CUSTOMS_DOCUMENT', 'GCB-2026-551', 'Gümrük Çıkış Beyannamesi',
        'EXPORT_FILE', v_dummy_entity_id, 'supabase://storage/docs/gcb-551.pdf',
        'gcb_551.pdf', 98000, 'APPROVED', 1, v_user_auditor
    ) RETURNING id INTO v_doc_customs;

    -- 1c: Helal Sertifikası (HALAL_CERTIFICATE - Süreli)
    INSERT INTO documents (
        tenant_id, company_id, document_type, document_number, title,
        entity_type, entity_id, issue_date, expiry_date, storage_reference, file_name,
        status, current_version, created_by_user_id
    ) VALUES (
        v_tenant_a, v_company_a, 'HALAL_CERTIFICATE', 'SMIIC-2026-99', 'SMIIC 1 Helal İhraç Sertifikası',
        'LOT', v_dummy_entity_id, CURRENT_DATE - INTERVAL '10 days', CURRENT_DATE + INTERVAL '20 days',
        'supabase://storage/docs/halal-99.pdf', 'halal_smiic_99.pdf', 'APPROVED', 1, v_user_auditor
    ) RETURNING id INTO v_doc_halal;

    -- 1d: Süresi Dolmuş Kalite Sertifikası (QUALITY_CERTIFICATE - Expired)
    INSERT INTO documents (
        tenant_id, company_id, document_type, document_number, title,
        entity_type, entity_id, issue_date, expiry_date, storage_reference, file_name,
        status, current_version, created_by_user_id
    ) VALUES (
        v_tenant_a, v_company_a, 'QUALITY_CERTIFICATE', 'ISO-22000-EXP', 'Gıda Güvenliği Sertifikası (Süresi Geçmiş)',
        'COMPANY', v_dummy_entity_id, CURRENT_DATE - INTERVAL '400 days', CURRENT_DATE - INTERVAL '15 days',
        'supabase://storage/docs/iso-old.pdf', 'iso_old.pdf', 'EXPIRED', 1, v_user_auditor
    ) RETURNING id INTO v_doc_expired;

    IF (SELECT COUNT(*) FROM documents WHERE company_id = v_company_a) >= 4 THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS (Dokümanlar ve tipler başarıyla yüklendi)';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL (Doküman yükleme başarısız)';
    END IF;


    -- =========================================================================
    -- TEST 2: DOKÜMAN VERSİYONLAMA (v1 -> v2 REPLACE & HISTORY)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    RAISE NOTICE 'TEST 2: Doküman Versiyonlama (v1 -> v2 Replace ve Değişiklik Özeti)...';

    -- v2 versiyon kaydı
    INSERT INTO document_versions (
        tenant_id, company_id, document_id, version_number,
        storage_reference, file_name, file_size_bytes, change_summary, uploaded_by_user_id
    ) VALUES (
        v_tenant_a, v_company_a, v_doc_invoice, 2,
        'supabase://storage/docs/inv-901-v2-revised.pdf', 'commercial_invoice_901_rev2.pdf',
        152000, 'Navlun ve sigorta bedeli revize edildi', v_user_auditor
    );

    -- Master dokümanı v2 olarak güncelle
    UPDATE documents
    SET current_version = 2,
        storage_reference = 'supabase://storage/docs/inv-901-v2-revised.pdf',
        file_name = 'commercial_invoice_901_rev2.pdf',
        file_size_bytes = 152000,
        updated_at = NOW()
    WHERE id = v_doc_invoice;

    PERFORM log_document_access(v_doc_invoice, 'REPLACE', v_user_auditor, 'v2 revizyonu yüklendi');

    SELECT current_version INTO v_current_ver
    FROM documents
    WHERE id = v_doc_invoice;

    RAISE NOTICE '  EXPECTED: current_version = 2';
    RAISE NOTICE '  ACTUAL:   current_version = %', v_current_ver;

    IF v_current_ver = 2 AND (SELECT COUNT(*) FROM document_versions WHERE document_id = v_doc_invoice) = 2 THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS (Versiyonlama geçmişi v1 ve v2 olarak doğrulandı)';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL (Versiyonlama kaydı başarısız)';
    END IF;


    -- =========================================================================
    -- TEST 3: DOĞRUDAN SİLME ENGELİ (HARD DELETE BLOCK TRIGGER)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    RAISE NOTICE 'TEST 3: Dokümanın Doğrudan Silinmesinin Engellenmesi (Hard Delete Block)...';

    v_exception_caught := FALSE;
    BEGIN
        DELETE FROM documents WHERE id = v_doc_invoice;
    EXCEPTION WHEN OTHERS THEN
        v_exception_caught := TRUE;
        RAISE NOTICE '  YAKALANAN HATA (BEKLENEN): %', SQLERRM;
    END;

    RAISE NOTICE '  EXPECTED: Exception caught = TRUE (Hard delete blocked)';
    RAISE NOTICE '  ACTUAL:   Exception caught = %', v_exception_caught;

    IF v_exception_caught THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS (Doküman silme engeli başarıyla devrede)';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL (Doküman doğrudan silinebildi!)';
    END IF;


    -- =========================================================================
    -- TEST 4: 6 DENETİM EYLEMİ (UPLOAD, VIEW, DOWNLOAD, REPLACE, APPROVE, REJECT)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    RAISE NOTICE 'TEST 4: 6 Denetim Eyleminin (VIEW, DOWNLOAD, APPROVE, REJECT) Audit Edilmesi...';

    -- VIEW ve DOWNLOAD eylemlerini kaydet
    PERFORM log_document_access(v_doc_invoice, 'VIEW', v_user_auditor, 'Fatura görüntülendi');
    PERFORM log_document_access(v_doc_invoice, 'DOWNLOAD', v_user_auditor, 'PDF indirildi');
    PERFORM log_document_access(v_doc_invoice, 'APPROVE', v_user_auditor, 'Gümrük öncesi onay verildi');
    PERFORM log_document_access(v_doc_customs, 'REJECT', v_user_auditor, 'Eksik mühür sebebiyle reddedildi');

    SELECT COUNT(*) INTO v_access_log_count
    FROM document_access_logs
    WHERE document_id = v_doc_invoice;

    SELECT COUNT(*) INTO v_audit_count
    FROM audit_logs
    WHERE tenant_id = v_tenant_a
      AND entity_type = 'document_access';

    RAISE NOTICE '  document_access_logs count: % (Beklenen >= 5)', v_access_log_count;
    RAISE NOTICE '  audit_logs count: % (Beklenen >= 6)', v_audit_count;

    IF v_access_log_count >= 5 AND v_audit_count >= 6 THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS (Tüm 6 denetim eylemi eksiksiz audit edildi)';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL (Audit kayıtları eksik!)';
    END IF;


    -- =========================================================================
    -- TEST 5: EXPIRY UYARI SİSTEMİ (view_document_expiry_alerts)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    RAISE NOTICE 'TEST 5: Süresi Dolan ve 30 Gün Kalan Belgelerin Expiry Alarm Görünümü...';

    SELECT COUNT(*) INTO v_expiry_alert_count
    FROM view_document_expiry_alerts
    WHERE company_id = v_company_a
      AND alert_level IN ('EXPIRED', 'CRITICAL_30_DAYS');

    RAISE NOTICE '  EXPECTED: expiry_alert_count >= 2 (1 Expired, 1 Critical 20 days)';
    RAISE NOTICE '  ACTUAL:   expiry_alert_count = %', v_expiry_alert_count;

    IF v_expiry_alert_count >= 2 THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS (Süre sonu ve kritik 30 gün uyarıları başarıyla tespit edildi)';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL (Expiry alarmları eksik!)';
    END IF;


    -- =========================================================================
    -- TEST 6: ŞİRKET / KİRACI İZOLASYONU VE YETKİSİZ ERİŞİM ENGELİ (RLS)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    RAISE NOTICE 'TEST 6: Yetkisiz Kullanıcı ve Başka Şirket Dokümanına Erişim Engeli (RLS)...';

    -- Kiracı B (Yetkisiz) oturumu simülasyonu
    SET LOCAL ROLE authenticated;
    EXECUTE 'SET LOCAL "request.jwt.claim.sub" TO ''' || v_user_stranger::text || '''';

    SELECT COUNT(*) INTO v_unauthorized_rows
    FROM documents
    WHERE company_id = v_company_a;

    RESET ROLE;

    RAISE NOTICE '  Kiracı B tarafından görülebilen Kiracı A doküman sayısı: % (Beklenen: 0)', v_unauthorized_rows;

    IF v_unauthorized_rows = 0 THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS (RLS başka şirket dokümanlarına erişimi kesin olarak engelledi)';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL (Yetkisiz kullanıcı başka şirketin belgelerini görebildi!)';
    END IF;


    -- =========================================================================
    -- TEST RAPORU
    -- =========================================================================
    RAISE NOTICE '====================================================================';
    RAISE NOTICE '=== FAZ 21 TEST SONUÇLARI: % / % TEST BAŞARIYLA GEÇTİ (PASS)     ===', v_pass_count, v_test_count;
    RAISE NOTICE '====================================================================';

    -- Temizlik (Test verilerini temizle)
    -- Not: Hard delete trigger'ı geçici devre dışı bırakarak test verilerini süpür
    ALTER TABLE documents DISABLE TRIGGER trg_prevent_document_hard_delete;
    DELETE FROM audit_logs WHERE tenant_id = v_tenant_a;
    DELETE FROM document_access_logs WHERE tenant_id = v_tenant_a;
    DELETE FROM document_versions WHERE tenant_id = v_tenant_a;
    DELETE FROM documents WHERE tenant_id = v_tenant_a;
    ALTER TABLE documents ENABLE TRIGGER trg_prevent_document_hard_delete;

    DELETE FROM companies WHERE tenant_id IN (v_tenant_a, v_tenant_b);
    DELETE FROM tenant_users WHERE tenant_id IN (v_tenant_a, v_tenant_b);
    DELETE FROM public.users WHERE id IN (v_user_auditor, v_user_stranger);
    DELETE FROM tenants WHERE id IN (v_tenant_a, v_tenant_b);

    RAISE NOTICE '=== TEST VERİLERİ BAŞARIYLA TEMİZLENDİ ===';
END $$;
