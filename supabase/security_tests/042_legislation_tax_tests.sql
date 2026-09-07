-- ==============================================================================
-- NAKHL & NAHL — FAZ 22 TEST SUITE: LEGISLATION & TAX ENGINE BOUNDED CONTEXT
-- File: supabase/security_tests/042_legislation_tax_tests.sql
-- Purpose:
-- 1. Mevzuat Master ve Versiyonlama (Legislations)
-- 2. Satış (Sales) Standart Vergi Oranı Hesaplama
-- 3. Satın Alma (Purchase) Stopaj ve İndirilebilir Vergi Hesaplama
-- 4. İhracat (Export Zero-Rated %0) Kuralı Hesaplama
-- 5. Tarihsel Vergi Hesaplama (Historical Tax Calculation - 2019 vs Günümüz)
-- 6. Ürün ve Şirket Önceliklendirme (Priority Kuralı)
-- 7. Çok Kiracılı Güvenlik ve Yetkisiz Erişim Engeli (RLS)
-- ==============================================================================

DO $$
DECLARE
    v_tenant_a UUID;
    v_tenant_b UUID;
    v_company_a UUID;
    v_company_b UUID;
    v_user_admin UUID;
    v_user_stranger UUID;
    v_role_admin UUID;
    v_item_id UUID;
    
    v_leg_zatca UUID;
    v_leg_gib UUID;
    v_rule_sa_5 UUID;
    v_rule_sa_15 UUID;
    v_rule_sa_exp UUID;
    v_rule_tr_pur UUID;
    v_rule_tr_item UUID;
    
    v_calc_res RECORD;
    v_unauthorized_count INT;
    v_test_count INT := 0;
    v_pass_count INT := 0;
BEGIN
    RAISE NOTICE '====================================================================';
    RAISE NOTICE '=== FAZ 22: LEGISLATION + TAX ENGINE TESTLERİ BAŞLIYOR           ===';
    RAISE NOTICE '====================================================================';

    -- 0. KURULUM (SETUP)
    SELECT id INTO v_role_admin FROM roles WHERE code = 'TENANT_ADMIN' AND tenant_id IS NULL LIMIT 1;

    -- Kiracı A
    INSERT INTO tenants (code, legal_name, display_name)
    VALUES ('TAX_TENANT_A', 'Tax Engine Tenant A', 'TETA')
    RETURNING id INTO v_tenant_a;

    INSERT INTO public.users (display_name, email)
    VALUES ('Tax Legal Director', 'tax_director@nakhl-test.com')
    RETURNING id INTO v_user_admin;

    INSERT INTO tenant_users (tenant_id, user_id, role_id, status)
    VALUES (v_tenant_a, v_user_admin, v_role_admin, 'ACTIVE');

    INSERT INTO companies (tenant_id, code, legal_name)
    VALUES (v_tenant_a, 'TAX_COMP_A', 'NAKHL Global Tarım ve Dış Ticaret A.Ş.')
    RETURNING id INTO v_company_a;

    -- Kiracı B (Yetkisiz)
    INSERT INTO tenants (code, legal_name, display_name)
    VALUES ('TAX_TENANT_B', 'Unauthorized Tenant B', 'UTB')
    RETURNING id INTO v_tenant_b;

    INSERT INTO public.users (display_name, email)
    VALUES ('Tax Intruder', 'intruder_tax@nakhl-test.com')
    RETURNING id INTO v_user_stranger;

    INSERT INTO tenant_users (tenant_id, user_id, role_id, status)
    VALUES (v_tenant_b, v_user_stranger, v_role_admin, 'ACTIVE');

    INSERT INTO companies (tenant_id, code, legal_name)
    VALUES (v_tenant_b, 'TAX_COMP_B', 'Unauthorized Company B')
    RETURNING id INTO v_company_b;

    -- Test Ürünü (Acve Hurması)
    INSERT INTO items (
        tenant_id, company_id, item_code, sku, item_name,
        category_name, base_unit, product_type
    ) VALUES (
        v_tenant_a, v_company_a, 'TAX-AJW-01', 'SKU-TAX-AJW-1KG', 'Acve Medine Hurması',
        'Hurma', 'Kg', 'FINISHED_GOOD'
    ) RETURNING id INTO v_item_id;


    -- =========================================================================
    -- TEST 1: MEVZUAT MASTER VE VERSİYONLAMA (LEGISLATIONS)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    RAISE NOTICE 'TEST 1: Mevzuat Master ve Versiyonlama Kayıtları...';

    -- Suudi Arabistan ZATCA KDV Mevzuatı
    INSERT INTO legislations (
        tenant_id, country_code, jurisdiction, legislation_code, title,
        effective_from, version, source_reference, status
    ) VALUES (
        v_tenant_a, 'SA', 'SA-ZATCA', 'ZATCA_VAT_2020', 'Zakat, Tax and Customs Authority VAT Law',
        '2020-07-01', '2.0', 'Umm Al-Qura Royal Decree No. A/638', 'ACTIVE'
    ) RETURNING id INTO v_leg_zatca;

    -- Türkiye GİB 3065 Sayılı KDV Kanunu
    INSERT INTO legislations (
        tenant_id, country_code, jurisdiction, legislation_code, title,
        effective_from, version, source_reference, status
    ) VALUES (
        v_tenant_a, 'TR', 'TR-GIB', 'KDV_KANUNU_3065', '3065 Sayılı Katma Değer Vergisi Kanunu',
        '1985-01-01', '2023.1', 'Resmi Gazete Sayı: 18563', 'ACTIVE'
    ) RETURNING id INTO v_leg_gib;

    IF v_leg_zatca IS NOT NULL AND v_leg_gib IS NOT NULL THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS (ZATCA ve GİB mevzuatları versiyonlarıyla kaydedildi)';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL (Mevzuat kaydı başarısız)';
    END IF;


    -- =========================================================================
    -- TEST 2: VERGİ KURALLARI TANIMLAMA (TARİHSEL, GÜNCEL, İHRACAT, SATINALMA)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    RAISE NOTICE 'TEST 2: Vergi Kurallarının Tanımlanması (Tarihsel %5, Güncel %15, İhracat %0)...';

    -- 2a: Tarihsel Suudi KDV'si (%5, 2018 ile 2020 arası)
    INSERT INTO tax_rules (
        tenant_id, company_id, legislation_id, rule_code, rule_name,
        tax_type, rate, country_code, jurisdiction, effective_from, effective_to,
        transaction_type, priority
    ) VALUES (
        v_tenant_a, v_company_a, v_leg_zatca, 'SA_SALES_VAT_5', 'KSA 2018-2020 Eski KDV Oranı',
        'VAT', 5.0000, 'SA', 'SA-ZATCA', '2018-01-01', '2020-06-30',
        'SALES', 100
    ) RETURNING id INTO v_rule_sa_5;

    -- 2b: Güncel Suudi KDV'si (%15, 2020-07-01 sonrasından bugüne)
    INSERT INTO tax_rules (
        tenant_id, company_id, legislation_id, rule_code, rule_name,
        tax_type, rate, country_code, jurisdiction, effective_from, effective_to,
        transaction_type, priority
    ) VALUES (
        v_tenant_a, v_company_a, v_leg_zatca, 'SA_SALES_VAT_15', 'KSA Güncel Standart KDV Oranı',
        'VAT', 15.0000, 'SA', 'SA-ZATCA', '2020-07-01', NULL,
        'SALES', 100
    ) RETURNING id INTO v_rule_sa_15;

    -- 2c: İhracat İstisnası (Export Zero-Rated %0)
    INSERT INTO tax_rules (
        tenant_id, company_id, legislation_id, rule_code, rule_name,
        tax_type, rate, country_code, jurisdiction, effective_from, effective_to,
        transaction_type, priority
    ) VALUES (
        v_tenant_a, v_company_a, v_leg_zatca, 'SA_EXPORT_ZERO', 'KSA İhracat KDV İstisnası (%0 Zero-Rated)',
        'EXPORT_ZERO', 0.0000, 'SA', 'SA-ZATCA', '2018-01-01', NULL,
        'EXPORT', 200
    ) RETURNING id INTO v_rule_sa_exp;

    -- 2d: Satınalma Tevkifatı / Stopaj (Purchase Withholding %2)
    INSERT INTO tax_rules (
        tenant_id, company_id, legislation_id, rule_code, rule_name,
        tax_type, rate, country_code, jurisdiction, effective_from, effective_to,
        transaction_type, priority
    ) VALUES (
        v_tenant_a, v_company_a, v_leg_gib, 'TR_PURCHASE_WH_2', 'Türkiye Çiftçi Müstahsil Stopajı',
        'WITHHOLDING', 2.0000, 'TR', 'TR-GIB', '2020-01-01', NULL,
        'PURCHASE', 100
    ) RETURNING id INTO v_rule_tr_pur;

    -- 2e: Ürün Öncelikli Kural (Hurma Toptan Satış %1 KDV)
    INSERT INTO tax_rules (
        tenant_id, company_id, legislation_id, rule_code, rule_name,
        tax_type, rate, country_code, jurisdiction, effective_from, effective_to,
        item_id, transaction_type, priority
    ) VALUES (
        v_tenant_a, v_company_a, v_leg_gib, 'TR_DATES_AGRI_1', 'Türkiye Toptan Hurma Teslim KDV',
        'VAT', 1.0000, 'TR', 'TR-GIB', '2020-01-01', NULL,
        v_item_id, 'SALES', 300
    ) RETURNING id INTO v_rule_tr_item;

    IF (SELECT COUNT(*) FROM tax_rules WHERE company_id = v_company_a) = 5 THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS (5 farklı vergi kuralı başarıyla tanımlandı)';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL (Vergi kuralları eksik)';
    END IF;


    -- =========================================================================
    -- TEST 3: GÜNCEL SATIŞ VERGİSİ HESAPLAMA (ZATCA GÜNCEL %15)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    RAISE NOTICE 'TEST 3: Güncel Satış KDV Hesaplama (ZATCA %15)...';

    SELECT * INTO v_calc_res
    FROM calculate_transaction_tax(
        v_tenant_a, v_company_a, 'SALES', 'SA', CURRENT_DATE, 10000.00, NULL, 'SA-ZATCA'
    );

    RAISE NOTICE '  EXPECTED: rate=15.00, tax_amount=1500.00, total=11500.00';
    RAISE NOTICE '  ACTUAL:   rate=%, tax_amount=%, total=%',
        v_calc_res.rate, v_calc_res.tax_amount, v_calc_res.total_amount;

    IF v_calc_res.rate = 15.0000 AND v_calc_res.tax_amount = 1500.00 AND v_calc_res.total_amount = 11500.00 THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL (Güncel KDV hesaplaması hatalı!)';
    END IF;


    -- =========================================================================
    -- TEST 4: TARİHSEL VERGİ HESAPLAMA (HISTORICAL TAX CALCULATION - 2019 YILI)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    RAISE NOTICE 'TEST 4: Tarihsel Hesaplama (2019-05-15 Tarihli Eski Fatura İçin %%5 Kuralı)...';

    SELECT * INTO v_calc_res
    FROM calculate_transaction_tax(
        v_tenant_a, v_company_a, 'SALES', 'SA', '2019-05-15'::date, 10000.00, NULL, 'SA-ZATCA'
    );

    RAISE NOTICE '  EXPECTED: rule=SA_SALES_VAT_5, rate=5.00, tax_amount=500.00, total=10500.00';
    RAISE NOTICE '  ACTUAL:   rule=%, rate=%, tax_amount=%, total=%',
        v_calc_res.rule_code, v_calc_res.rate, v_calc_res.tax_amount, v_calc_res.total_amount;

    IF v_calc_res.rule_code = 'SA_SALES_VAT_5' AND v_calc_res.rate = 5.0000 AND v_calc_res.tax_amount = 500.00 THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS (Tarihsel vergi kuralı başarıyla çözüldü, geçmiş hesap bozulmadı)';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL (Tarihsel vergi hesaplama hatalı!)';
    END IF;


    -- =========================================================================
    -- TEST 5: İHRACAT VERGİ İSTİSNASI (EXPORT ZERO-RATED %0)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    RAISE NOTICE 'TEST 5: İhracat KDV İstisnası (Export Zero-Rated %%0)...';

    SELECT * INTO v_calc_res
    FROM calculate_transaction_tax(
        v_tenant_a, v_company_a, 'EXPORT', 'SA', CURRENT_DATE, 50000.00, NULL, 'SA-ZATCA'
    );

    RAISE NOTICE '  EXPECTED: rate=0.00, tax_amount=0.00, total=50000.00';
    RAISE NOTICE '  ACTUAL:   rule=%, rate=%, tax_amount=%, total=%',
        v_calc_res.rule_code, v_calc_res.rate, v_calc_res.tax_amount, v_calc_res.total_amount;

    IF v_calc_res.rate = 0.0000 AND v_calc_res.tax_amount = 0.00 AND v_calc_res.total_amount = 50000.00 THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS (İhracat vergi istisnası doğrulandı)';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL (İhracat vergi hesaplaması hatalı!)';
    END IF;


    -- =========================================================================
    -- TEST 6: ÜRÜN ÖNCELİKLİ VERGİ KURALI (ITEM SPECIFIC PRIORITY)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    RAISE NOTICE 'TEST 6: Ürüne Özel Vergi Kuralı Önceliği (Acve Hurması %%1 KDV)...';

    SELECT * INTO v_calc_res
    FROM calculate_transaction_tax(
        v_tenant_a, v_company_a, 'SALES', 'TR', CURRENT_DATE, 20000.00, v_item_id, 'TR-GIB'
    );

    RAISE NOTICE '  EXPECTED: rule=TR_DATES_AGRI_1, rate=1.00, tax_amount=200.00, total=20200.00';
    RAISE NOTICE '  ACTUAL:   rule=%, rate=%, tax_amount=%, total=%',
        v_calc_res.rule_code, v_calc_res.rate, v_calc_res.tax_amount, v_calc_res.total_amount;

    IF v_calc_res.rule_code = 'TR_DATES_AGRI_1' AND v_calc_res.rate = 1.0000 AND v_calc_res.tax_amount = 200.00 THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS (Ürüne özel vergi kuralı genel kuralları başarıyla ezdi)';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL (Ürün vergi kuralı önceliği başarısız!)';
    END IF;


    -- =========================================================================
    -- TEST 7: ÇOK KİRACILI GÜVENLİK VE İZOLASYON (RLS)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    RAISE NOTICE 'TEST 7: Yetkisiz Kiracı Vergi Kurallarına Erişim Engeli (RLS)...';

    -- Kiracı B oturumu simülasyonu
    SET LOCAL ROLE authenticated;
    EXECUTE 'SET LOCAL "request.jwt.claim.sub" TO ''' || v_user_stranger::text || '''';

    SELECT COUNT(*) INTO v_unauthorized_count
    FROM tax_rules
    WHERE company_id = v_company_a;

    RESET ROLE;

    RAISE NOTICE '  Kiracı B tarafından görülebilen Kiracı A vergi kuralı: % (Beklenen: 0)', v_unauthorized_count;

    IF v_unauthorized_count = 0 THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS (RLS başka şirketin vergi kurallarına erişimi kesin olarak engelledi)';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL (Yetkisiz kullanıcı vergi kurallarına erişebildi!)';
    END IF;


    -- =========================================================================
    -- TEST RAPORU
    -- =========================================================================
    RAISE NOTICE '====================================================================';
    RAISE NOTICE '=== FAZ 22 TEST SONUÇLARI: % / % TEST BAŞARIYLA GEÇTİ (PASS)     ===', v_pass_count, v_test_count;
    RAISE NOTICE '====================================================================';

    -- Temizlik (Test verilerini temizle)
    DELETE FROM tax_rules WHERE tenant_id = v_tenant_a;
    DELETE FROM legislations WHERE tenant_id = v_tenant_a;
    DELETE FROM items WHERE tenant_id = v_tenant_a;
    DELETE FROM companies WHERE tenant_id IN (v_company_a, v_company_b);
    DELETE FROM tenant_users WHERE tenant_id IN (v_tenant_a, v_tenant_b);
    DELETE FROM public.users WHERE id IN (v_user_admin, v_user_stranger);
    DELETE FROM tenants WHERE id IN (v_tenant_a, v_tenant_b);

    RAISE NOTICE '=== TEST VERİLERİ BAŞARIYLA TEMİZLENDİ ===';
END $$;
