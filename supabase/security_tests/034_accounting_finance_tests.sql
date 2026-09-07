-- ==============================================================================
-- NAKHL & NAHL — FAZ 14 TEST SUITE: ACCOUNTING & FINANCE CORE
-- File: supabase/security_tests/034_accounting_finance_tests.sql
-- Purpose:
-- 1. balanced journal
-- 2. unbalanced journal
-- 3. duplicate posting
-- 4. posted update
-- 5. posted delete
-- 6. reversal
-- 7. fiscal period lock
-- 8. cross-company
-- 9. cross-tenant
-- 10. currency
-- Output format: EXPECTED, ACTUAL, PASS/FAIL
-- ==============================================================================

DO $$
DECLARE
    v_tenant_a UUID;
    v_tenant_b UUID;
    v_company_a1 UUID;
    v_company_a2 UUID;
    v_company_b1 UUID;
    v_user_a UUID;
    v_user_b UUID;
    v_role_admin UUID;

    v_acc_cash UUID;
    v_acc_revenue UUID;
    v_acc_parent UUID;
    v_acc_comp_b UUID;

    v_period_open UUID;
    v_period_locked UUID;

    v_journal_1 UUID;
    v_journal_unbalanced UUID;
    v_reversal_id UUID;

    v_status VARCHAR(50);
    v_orig_status VARCHAR(50);
    v_tot_deb NUMERIC(18,4);
    v_tot_crd NUMERIC(18,4);
    v_base_deb NUMERIC(18,4);
    v_rate NUMERIC(18,6);
    v_exception_caught BOOLEAN;
    v_err_msg TEXT;

    v_test_count INT := 0;
    v_pass_count INT := 0;
BEGIN
    RAISE NOTICE '====================================================================';
    RAISE NOTICE '=== FAZ 14: ACCOUNTING + FINANCE CORE DOĞRULAMA TESTLERİ        ===';
    RAISE NOTICE '====================================================================';

    -- 0. TEST ORTAMI KURULUMU
    SELECT id INTO v_role_admin FROM roles WHERE code = 'TENANT_ADMIN' AND tenant_id IS NULL LIMIT 1;

    -- Tenant A & B
    INSERT INTO tenants (code, legal_name, display_name)
    VALUES ('ACC_TENANT_A', 'Accounting Tenant A', 'ATA')
    RETURNING id INTO v_tenant_a;

    INSERT INTO tenants (code, legal_name, display_name)
    VALUES ('ACC_TENANT_B', 'Accounting Tenant B', 'ATB')
    RETURNING id INTO v_tenant_b;

    INSERT INTO public.users (display_name, email)
    VALUES ('Acc User A', 'acc_usera@nakhl-test.com')
    RETURNING id INTO v_user_a;

    INSERT INTO public.users (display_name, email)
    VALUES ('Acc User B', 'acc_userb@nakhl-test.com')
    RETURNING id INTO v_user_b;

    INSERT INTO tenant_users (tenant_id, user_id, role_id, status)
    VALUES (v_tenant_a, v_user_a, v_role_admin, 'ACTIVE');

    INSERT INTO tenant_users (tenant_id, user_id, role_id, status)
    VALUES (v_tenant_b, v_user_b, v_role_admin, 'ACTIVE');

    -- Şirketler
    INSERT INTO companies (tenant_id, code, legal_name)
    VALUES (v_tenant_a, 'ACC_COMP_A1', 'NAKHL Finans Şirketi A1')
    RETURNING id INTO v_company_a1;

    INSERT INTO companies (tenant_id, code, legal_name)
    VALUES (v_tenant_a, 'ACC_COMP_A2', 'NAKHL Lojistik Şirketi A2')
    RETURNING id INTO v_company_a2;

    INSERT INTO companies (tenant_id, code, legal_name)
    VALUES (v_tenant_b, 'ACC_COMP_B1', 'Yabancı Tenant Şirketi B1')
    RETURNING id INTO v_company_b1;

    -- Mali Dönemler (OPEN ve LOCKED)
    INSERT INTO fiscal_periods (tenant_id, company_id, year, period_no, start_date, end_date, status)
    VALUES (v_tenant_a, v_company_a1, 2026, 9, '2026-09-01', '2026-09-30', 'OPEN')
    RETURNING id INTO v_period_open;

    INSERT INTO fiscal_periods (tenant_id, company_id, year, period_no, start_date, end_date, status)
    VALUES (v_tenant_a, v_company_a1, 2026, 8, '2026-08-01', '2026-08-31', 'LOCKED')
    RETURNING id INTO v_period_locked;

    -- Hesap Planı
    -- Ana/Grup Hesap (posting_allowed = FALSE)
    INSERT INTO chart_of_accounts (tenant_id, company_id, account_code, account_name, account_type, balance_type, posting_allowed)
    VALUES (v_tenant_a, v_company_a1, '100', 'KASA VE BANKALAR ANA HESAP', 'ASSET', 'DEBIT', FALSE)
    RETURNING id INTO v_acc_parent;

    -- Detay Hesaplar (posting_allowed = TRUE)
    INSERT INTO chart_of_accounts (tenant_id, company_id, parent_id, account_code, account_name, account_type, balance_type, posting_allowed)
    VALUES (v_tenant_a, v_company_a1, v_acc_parent, '100.01', 'Medine Kasa SAR', 'ASSET', 'DEBIT', TRUE)
    RETURNING id INTO v_acc_cash;

    INSERT INTO chart_of_accounts (tenant_id, company_id, account_code, account_name, account_type, balance_type, posting_allowed)
    VALUES (v_tenant_a, v_company_a1, '600.01', 'Hurma İhracat Gelirleri', 'REVENUE', 'CREDIT', TRUE)
    RETURNING id INTO v_acc_revenue;

    -- Şirket B Hesabı (Cross-company testi için)
    INSERT INTO chart_of_accounts (tenant_id, company_id, account_code, account_name, account_type, balance_type, posting_allowed)
    VALUES (v_tenant_b, v_company_b1, '100.01', 'B Şirketi Kasa', 'ASSET', 'DEBIT', TRUE)
    RETURNING id INTO v_acc_comp_b;

    -- Döviz Kurları (USD -> SAR: 3.750000)
    INSERT INTO exchange_rates (tenant_id, from_currency, to_currency, rate_date, rate, source)
    VALUES (v_tenant_a, 'USD', 'SAR', '2026-09-01', 3.750000, 'SAMA');


    -- =========================================================================
    -- TEST 1: BALANCED JOURNAL (DENGELİ YEVMİYE FİŞİ)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    v_journal_1 := create_complete_journal_entry_rpc(
        p_tenant_id => v_tenant_a,
        p_company_id => v_company_a1,
        p_entry_date => '2026-09-15'::DATE,
        p_entry_type => 'SALES_INVOICE',
        p_document_type => 'INVOICE',
        p_document_reference => 'INV-BAL-01',
        p_description => 'Dengeli Satış Faturası Fişi',
        p_lines => jsonb_build_array(
            jsonb_build_object('account_id', v_acc_cash, 'debit_amount', 10000.0000, 'credit_amount', 0.0000, 'transaction_currency', 'SAR', 'exchange_rate', 1.0),
            jsonb_build_object('account_id', v_acc_revenue, 'debit_amount', 0.0000, 'credit_amount', 10000.0000, 'transaction_currency', 'SAR', 'exchange_rate', 1.0)
        ),
        p_auto_post => TRUE,
        p_user_id => v_user_a
    );

    SELECT status, total_debit, total_credit INTO v_status, v_tot_deb, v_tot_crd
    FROM journal_entries WHERE id = v_journal_1;

    RAISE NOTICE 'TEST 1: Balanced Journal';
    RAISE NOTICE '  EXPECTED: status = POSTED, total_debit = 10000.0000, total_credit = 10000.0000';
    RAISE NOTICE '  ACTUAL:   status = %, total_debit = %, total_credit = %', v_status, v_tot_deb, v_tot_crd;

    IF v_status = 'POSTED' AND v_tot_deb = 10000.0000 AND v_tot_crd = 10000.0000 THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL';
    END IF;


    -- =========================================================================
    -- TEST 2: UNBALANCED JOURNAL (DENGESİZ YEVMİYE FİŞİ ENGELİ)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    v_exception_caught := FALSE;
    v_err_msg := '';

    BEGIN
        v_journal_unbalanced := create_complete_journal_entry_rpc(
            p_tenant_id => v_tenant_a,
            p_company_id => v_company_a1,
            p_entry_date => '2026-09-15'::DATE,
            p_entry_type => 'JOURNAL',
            p_document_type => 'MEMO',
            p_document_reference => 'INV-UNBAL-01',
            p_description => 'Dengesiz Fiş Denemesi',
            p_lines => jsonb_build_array(
                jsonb_build_object('account_id', v_acc_cash, 'debit_amount', 10000.0000, 'credit_amount', 0.0000),
                jsonb_build_object('account_id', v_acc_revenue, 'debit_amount', 0.0000, 'credit_amount', 9000.0000)
            ),
            p_auto_post => TRUE,
            p_user_id => v_user_a
        );
    EXCEPTION WHEN OTHERS THEN
        v_exception_caught := TRUE;
        v_err_msg := SQLERRM;
    END;

    RAISE NOTICE 'TEST 2: Unbalanced Journal';
    RAISE NOTICE '  EXPECTED: Exception (DENKLİK HATASI) ve fişin bloke edilmesi';
    RAISE NOTICE '  ACTUAL:   Exception caught: %, Mesaj: %', v_exception_caught, v_err_msg;

    IF v_exception_caught THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL (Dengesiz fiş kaydedilebildi!)';
    END IF;


    -- =========================================================================
    -- TEST 3: DUPLICATE POSTING (MÜKERRER ONAY ENGELİ)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    v_exception_caught := FALSE;
    v_err_msg := '';

    BEGIN
        -- Zaten POSTED olan fişi tekrar POSTED yapmayı dene
        UPDATE journal_entries 
        SET status = 'POSTED', updated_at = NOW() 
        WHERE id = v_journal_1;
    EXCEPTION WHEN OTHERS THEN
        v_exception_caught := TRUE;
        v_err_msg := SQLERRM;
    END;

    RAISE NOTICE 'TEST 3: Duplicate Posting';
    RAISE NOTICE '  EXPECTED: Exception (MÜKERRER ONAY ENGELİ)';
    RAISE NOTICE '  ACTUAL:   Exception caught: %, Mesaj: %', v_exception_caught, v_err_msg;

    IF v_exception_caught THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL (Zaten POSTED olan fiş tekrar onaylanabildi!)';
    END IF;


    -- =========================================================================
    -- TEST 4: POSTED UPDATE (KESİNLEŞMİŞ FİŞİN GÜNCELLENEMEMESİ)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    v_exception_caught := FALSE;
    v_err_msg := '';

    BEGIN
        UPDATE journal_entries
        SET total_debit = 999999.0000
        WHERE id = v_journal_1;
    EXCEPTION WHEN OTHERS THEN
        v_exception_caught := TRUE;
        v_err_msg := SQLERRM;
    END;

    RAISE NOTICE 'TEST 4: Posted Update Immutability';
    RAISE NOTICE '  EXPECTED: Exception (Kesinleşmiş muhasebe fişinin tutarları değiştirilemez)';
    RAISE NOTICE '  ACTUAL:   Exception caught: %, Mesaj: %', v_exception_caught, v_err_msg;

    IF v_exception_caught THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL (POSTED fiş güncellenebildi!)';
    END IF;


    -- =========================================================================
    -- TEST 5: POSTED DELETE (KESİNLEŞMİŞ FİŞİN SİLİNEMEMESİ)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    v_exception_caught := FALSE;
    v_err_msg := '';

    BEGIN
        DELETE FROM journal_entries WHERE id = v_journal_1;
    EXCEPTION WHEN OTHERS THEN
        v_exception_caught := TRUE;
        v_err_msg := SQLERRM;
    END;

    RAISE NOTICE 'TEST 5: Posted Delete Immutability';
    RAISE NOTICE '  EXPECTED: Exception (Kesinleşmiş muhasebe yevmiye fişleri kesinlikle silinemez)';
    RAISE NOTICE '  ACTUAL:   Exception caught: %, Mesaj: %', v_exception_caught, v_err_msg;

    IF v_exception_caught THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL (POSTED fiş silinebildi!)';
    END IF;


    -- =========================================================================
    -- TEST 6: REVERSAL (TERS KAYIT İLE HATA DÜZELTME)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    v_reversal_id := reverse_journal_entry_rpc(
        p_journal_entry_id => v_journal_1,
        p_reversal_date => '2026-09-16'::DATE,
        p_reversal_reason => 'Hatalı fatura tutarı düzeltmesi',
        p_user_id => v_user_a
    );

    SELECT status INTO v_orig_status FROM journal_entries WHERE id = v_journal_1;
    SELECT status, total_debit, total_credit INTO v_status, v_tot_deb, v_tot_crd FROM journal_entries WHERE id = v_reversal_id;

    RAISE NOTICE 'TEST 6: Reversal Mechanism';
    RAISE NOTICE '  EXPECTED: original status = REVERSED, reversal status = POSTED, reversal debit/credit = 10000.0000';
    RAISE NOTICE '  ACTUAL:   original status = %, reversal status = %, debit = %, credit = %',
        v_orig_status, v_status, v_tot_deb, v_tot_crd;

    IF v_orig_status = 'REVERSED' AND v_status = 'POSTED' AND v_tot_deb = 10000.0000 THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL';
    END IF;


    -- =========================================================================
    -- TEST 7: FISCAL PERIOD LOCK (KİLİTLİ MALİ DÖNEM ENGELİ)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    v_exception_caught := FALSE;
    v_err_msg := '';

    BEGIN
        -- Ağustos 2026 dönemi LOCKED durumundadır. Ağustos tarihli fiş açmayı dene
        PERFORM create_complete_journal_entry_rpc(
            p_tenant_id => v_tenant_a,
            p_company_id => v_company_a1,
            p_entry_date => '2026-08-20'::DATE,
            p_entry_type => 'JOURNAL',
            p_document_type => 'MEMO',
            p_document_reference => 'INV-LOCK-01',
            p_description => 'Kilitli Döneme Kayıt Denemesi',
            p_lines => jsonb_build_array(
                jsonb_build_object('account_id', v_acc_cash, 'debit_amount', 500.0000, 'credit_amount', 0.0000),
                jsonb_build_object('account_id', v_acc_revenue, 'debit_amount', 0.0000, 'credit_amount', 500.0000)
            ),
            p_auto_post => FALSE,
            p_user_id => v_user_a
        );
    EXCEPTION WHEN OTHERS THEN
        v_exception_caught := TRUE;
        v_err_msg := SQLERRM;
    END;

    RAISE NOTICE 'TEST 7: Fiscal Period Lock';
    RAISE NOTICE '  EXPECTED: Exception (MALİ DÖNEM KİLİDİ)';
    RAISE NOTICE '  ACTUAL:   Exception caught: %, Mesaj: %', v_exception_caught, v_err_msg;

    IF v_exception_caught THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL (Kilitli döneme fiş açılabildi!)';
    END IF;


    -- =========================================================================
    -- TEST 8: CROSS-COMPANY (ŞİRKETLER ARASI HESAP KARIŞMA ENGELİ)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    v_exception_caught := FALSE;
    v_err_msg := '';

    BEGIN
        -- Şirket A1 fişinde, Şirket B1'in hesap kartını kullanmayı dene
        PERFORM create_complete_journal_entry_rpc(
            p_tenant_id => v_tenant_a,
            p_company_id => v_company_a1,
            p_entry_date => '2026-09-15'::DATE,
            p_entry_type => 'JOURNAL',
            p_document_type => 'MEMO',
            p_document_reference => 'INV-CROSS-COMP',
            p_description => 'Farklı Şirket Hesabı Kullanma Denemesi',
            p_lines => jsonb_build_array(
                jsonb_build_object('account_id', v_acc_comp_b, 'debit_amount', 100.0000, 'credit_amount', 0.0000),
                jsonb_build_object('account_id', v_acc_revenue, 'debit_amount', 0.0000, 'credit_amount', 100.0000)
            ),
            p_auto_post => FALSE,
            p_user_id => v_user_a
        );
    EXCEPTION WHEN OTHERS THEN
        v_exception_caught := TRUE;
        v_err_msg := SQLERRM;
    END;

    RAISE NOTICE 'TEST 8: Cross-Company Account Boundary';
    RAISE NOTICE '  EXPECTED: Foreign key veya cross-company ihlal engeli';
    RAISE NOTICE '  ACTUAL:   Exception caught: %, Mesaj: %', v_exception_caught, v_err_msg;

    IF v_exception_caught THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL (Başka şirketin hesabı kullanılabildi!)';
    END IF;


    -- =========================================================================
    -- TEST 9: CROSS-TENANT İZOLASYONU (TENANT_B -> TENANT_A ERİŞİM ENGELİ)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    -- Tenant B kullanıcısının Tenant A'ya ait yevmiye fişlerini ve satırlarını görmesi RLS ile engellenmeli
    PERFORM set_config('request.jwt.claim.sub', v_user_b::TEXT, TRUE);
    PERFORM set_config('request.jwt.claim.role', 'authenticated', TRUE);

    DECLARE
        v_visible_count INT;
    BEGIN
        SELECT COUNT(*) INTO v_visible_count
        FROM journal_entries
        WHERE tenant_id = v_tenant_a
          AND (is_tenant_member(tenant_id) AND has_company_access(company_id));

        RAISE NOTICE 'TEST 9: Cross-Tenant RLS Isolation';
        RAISE NOTICE '  EXPECTED: visible_count = 0';
        RAISE NOTICE '  ACTUAL:   visible_count = %', v_visible_count;

        IF v_visible_count = 0 THEN
            v_pass_count := v_pass_count + 1;
            RAISE NOTICE '  RESULT:   PASS';
        ELSE
            RAISE EXCEPTION '  RESULT:   FAIL (Tenant B, Tenant A fişlerini görebildi!)';
        END IF;
    END;


    -- =========================================================================
    -- TEST 10: CURRENCY & HISTORICAL EXCHANGE RATE (DÖVİZ VE KUR ÇEVRİMİ)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    -- Tarihsel kur sorgusu (USD -> SAR: 3.750000)
    v_rate := get_exchange_rate(v_tenant_a, 'USD', 'SAR', '2026-09-15'::DATE);

    -- 1,000 USD tutarlı dövizli fiş kaydı
    DECLARE
        v_fx_journal UUID;
    BEGIN
        v_fx_journal := create_complete_journal_entry_rpc(
            p_tenant_id => v_tenant_a,
            p_company_id => v_company_a1,
            p_entry_date => '2026-09-15'::DATE,
            p_entry_type => 'SALES_INVOICE',
            p_document_type => 'INVOICE',
            p_document_reference => 'INV-FX-01',
            p_description => 'Dövizli İhracat Faturası Fişi (1,000 USD)',
            p_lines => jsonb_build_array(
                jsonb_build_object('account_id', v_acc_cash, 'debit_amount', 1000.0000, 'credit_amount', 0.0000, 'transaction_currency', 'USD', 'exchange_rate', v_rate),
                jsonb_build_object('account_id', v_acc_revenue, 'debit_amount', 0.0000, 'credit_amount', 1000.0000, 'transaction_currency', 'USD', 'exchange_rate', v_rate)
            ),
            p_auto_post => TRUE,
            p_user_id => v_user_a
        );

        SELECT base_debit_amount INTO v_base_deb
        FROM journal_lines
        WHERE journal_entry_id = v_fx_journal AND debit_amount > 0;

        RAISE NOTICE 'TEST 10: Multi-Currency & Historical Exchange Rates';
        RAISE NOTICE '  EXPECTED: exchange_rate = 3.750000, base_debit_amount = 3750.0000 SAR';
        RAISE NOTICE '  ACTUAL:   exchange_rate = %, base_debit_amount = % SAR', v_rate, v_base_deb;

        IF v_rate = 3.750000 AND v_base_deb = 3750.0000 THEN
            v_pass_count := v_pass_count + 1;
            RAISE NOTICE '  RESULT:   PASS';
        ELSE
            RAISE EXCEPTION '  RESULT:   FAIL';
        END IF;
    END;

    -- =========================================================================
    -- TEST RAPORU
    -- =========================================================================
    RAISE NOTICE '====================================================================';
    RAISE NOTICE '=== FAZ 14 TEST SONUÇLARI: % / % TEST BAŞARIYLA GEÇTİ (PASS)     ===', v_pass_count, v_test_count;
    RAISE NOTICE '====================================================================';

    -- Temizlik (Test verilerini temizle)
    ALTER TABLE audit_logs DISABLE TRIGGER trg_prevent_audit_log_modification;
    ALTER TABLE journal_entries DISABLE TRIGGER trg_prevent_posted_journal_modification;
    ALTER TABLE journal_lines DISABLE TRIGGER trg_prevent_posted_journal_line_modification;
    ALTER TABLE journal_lines DISABLE TRIGGER trg_prevent_posted_journal_lines_modification;
    DELETE FROM audit_logs WHERE tenant_id IN (v_tenant_a, v_tenant_b);
    DELETE FROM journal_lines WHERE tenant_id IN (v_tenant_a, v_tenant_b);
    DELETE FROM journal_entries WHERE tenant_id IN (v_tenant_a, v_tenant_b);
    DELETE FROM exchange_rates WHERE tenant_id IN (v_tenant_a, v_tenant_b);
    DELETE FROM chart_of_accounts WHERE tenant_id IN (v_tenant_a, v_tenant_b);
    DELETE FROM fiscal_periods WHERE tenant_id IN (v_tenant_a, v_tenant_b);
    DELETE FROM companies WHERE tenant_id IN (v_tenant_a, v_tenant_b);
    DELETE FROM tenant_users WHERE tenant_id IN (v_tenant_a, v_tenant_b);
    DELETE FROM public.users WHERE id IN (v_user_a, v_user_b);
    DELETE FROM tenants WHERE id IN (v_tenant_a, v_tenant_b);
    ALTER TABLE audit_logs ENABLE TRIGGER trg_prevent_audit_log_modification;
    ALTER TABLE journal_entries ENABLE TRIGGER trg_prevent_posted_journal_modification;
    ALTER TABLE journal_lines ENABLE TRIGGER trg_prevent_posted_journal_line_modification;
    ALTER TABLE journal_lines ENABLE TRIGGER trg_prevent_posted_journal_lines_modification;

    RAISE NOTICE '=== TEST VERİLERİ BAŞARIYLA TEMİZLENDİ ===';
END $$;
