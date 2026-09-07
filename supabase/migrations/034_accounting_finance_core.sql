-- ==============================================================================
-- NAKHL & NAHL — MIGRATION 034: ACCOUNTING & FINANCE CORE (FAZ 14)
-- Purpose:
-- 1. chart_of_accounts: posting_allowed (Özet/Detay hesap ayrımı), hiyerarşi ve kontroller
-- 2. fiscal_periods: OPEN, CLOSED, LOCKED durumları ve kilitli dönem kontrolü
-- 3. journal_entries & lines: DRAFT -> VALIDATED -> POSTED iş akışı, mutlak denklik
-- 4. Single-Transaction Atomic RPC: create_complete_journal_entry_rpc
-- 5. Reversal RPC: reverse_journal_entry_rpc (Hata durumunda ters kayıt)
-- 6. exchange_rates: Tarihsel döviz kurları ve çoklu para birimi desteği
-- 7. Audit Logging: CREATE, UPDATE, POST, REVERSE, APPROVE işlemleri
-- ==============================================================================

-- 1. HESAP PLANI (CHART OF ACCOUNTS) GELİŞTİRMELERİ
ALTER TABLE chart_of_accounts ADD COLUMN IF NOT EXISTS posting_allowed BOOLEAN NOT NULL DEFAULT TRUE;
CREATE INDEX IF NOT EXISTS idx_coa_posting_allowed ON chart_of_accounts(company_id, posting_allowed);

-- Ana/Grup hesaplara (posting_allowed = FALSE) yevmiye kaydı girilmesini engelleyen tetikleyici
CREATE OR REPLACE FUNCTION check_account_posting_allowed()
RETURNS TRIGGER AS $$
DECLARE
    v_posting_allowed BOOLEAN;
    v_account_code VARCHAR(50);
BEGIN
    SELECT posting_allowed, account_code INTO v_posting_allowed, v_account_code
    FROM chart_of_accounts
    WHERE id = NEW.account_id;

    IF v_posting_allowed = FALSE THEN
        RAISE EXCEPTION 'HESAP KAYIT ENGELİ: "%" kodlu hesap bir ana/özet hesap olup doğrudan yevmiye kaydı (posting) kabul etmez! Alt detay hesap seçiniz.',
            v_account_code;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS trg_check_account_posting_allowed ON journal_lines;
CREATE TRIGGER trg_check_account_posting_allowed
BEFORE INSERT OR UPDATE OF account_id ON journal_lines
FOR EACH ROW EXECUTE FUNCTION check_account_posting_allowed();


-- 2. MALİ DÖNEMLER (FISCAL PERIODS: OPEN, CLOSED, LOCKED)
ALTER TABLE fiscal_periods ADD COLUMN IF NOT EXISTS status VARCHAR(20) NOT NULL DEFAULT 'OPEN';

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_fiscal_period_status'
    ) THEN
        ALTER TABLE fiscal_periods 
        ADD CONSTRAINT chk_fiscal_period_status 
        CHECK (status IN ('OPEN', 'CLOSED', 'LOCKED'));
    END IF;
END $$;

-- Yevmiye fişi işlem tarihinin açık bir mali döneme ait olduğunu denetleyen fonksiyon
CREATE OR REPLACE FUNCTION check_fiscal_period_status()
RETURNS TRIGGER AS $$
DECLARE
    v_period_status VARCHAR(20);
    v_period_no INT;
    v_year INT;
BEGIN
    -- Tarihe denk gelen mali dönemi bul
    SELECT status, period_no, year INTO v_period_status, v_period_no, v_year
    FROM fiscal_periods
    WHERE company_id = NEW.company_id
      AND NEW.entry_date BETWEEN start_date AND end_date
    LIMIT 1;

    -- Eğer bir mali dönem tanımlanmışsa ve durumu OPEN değilse kaydı bloke et
    IF v_period_status IS NOT NULL AND v_period_status != 'OPEN' THEN
        RAISE EXCEPTION 'MALİ DÖNEM KİLİDİ: "%" işlem tarihi %/.% mali dönemine denk gelmektedir ve bu dönem "%" durumundadır. Kapalı veya kilitli dönemlere yevmiye kaydı girilemez/kesinleştirilemez!',
            NEW.entry_date, v_year, v_period_no, v_period_status;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS trg_check_fiscal_period_status ON journal_entries;
CREATE TRIGGER trg_check_fiscal_period_status
BEFORE INSERT OR UPDATE OF entry_date, status ON journal_entries
FOR EACH ROW EXECUTE FUNCTION check_fiscal_period_status();


-- 3. TARİHSEL DÖVİZ KURLARI (EXCHANGE RATES)
CREATE TABLE IF NOT EXISTS exchange_rates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    from_currency VARCHAR(5) NOT NULL,
    to_currency VARCHAR(5) NOT NULL,
    rate_date DATE NOT NULL,
    rate NUMERIC(18,6) NOT NULL,
    source VARCHAR(50) DEFAULT 'CENTRAL_BANK', -- SAMA, TCMB, REUTERS, MANUAL
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_exchange_rate UNIQUE (tenant_id, from_currency, to_currency, rate_date)
);

CREATE INDEX IF NOT EXISTS idx_exchange_rates_lookup ON exchange_rates(tenant_id, from_currency, to_currency, rate_date DESC);

-- Tarihsel kur sorgulama yardımcı fonksiyonu
CREATE OR REPLACE FUNCTION get_exchange_rate(
    p_tenant_id UUID,
    p_from_currency VARCHAR(5),
    p_to_currency VARCHAR(5),
    p_rate_date DATE
) RETURNS NUMERIC(18,6) AS $$
DECLARE
    v_rate NUMERIC(18,6);
BEGIN
    IF p_from_currency = p_to_currency THEN
        RETURN 1.000000;
    END IF;

    -- Belirtilen tarihteki veya o tarihten önceki en güncel kuru al
    SELECT rate INTO v_rate
    FROM exchange_rates
    WHERE tenant_id = p_tenant_id
      AND from_currency = p_from_currency
      AND to_currency = p_to_currency
      AND rate_date <= p_rate_date
    ORDER BY rate_date DESC
    LIMIT 1;

    RETURN COALESCE(v_rate, 1.000000);
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- Raporlama dövizi alanları journal_lines tablosuna eklenir
ALTER TABLE journal_lines ADD COLUMN IF NOT EXISTS reporting_currency VARCHAR(5) DEFAULT 'USD';
ALTER TABLE journal_lines ADD COLUMN IF NOT EXISTS reporting_debit_amount NUMERIC(18,4) DEFAULT 0.0000;
ALTER TABLE journal_lines ADD COLUMN IF NOT EXISTS reporting_credit_amount NUMERIC(18,4) DEFAULT 0.0000;


-- 4. YEVMİYE İŞ AKIŞI VE TEKRARLI ONAYLAMA ENGELİ
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_journal_entries_status'
    ) THEN
        ALTER TABLE journal_entries 
        ADD CONSTRAINT chk_journal_entries_status 
        CHECK (status IN ('DRAFT', 'VALIDATED', 'POSTED', 'LOCKED', 'REVERSED'));
    END IF;
END $$;

-- Kesinleştirme ve denklik doğrulama tetikleyicisi
CREATE OR REPLACE FUNCTION validate_journal_entry_posting()
RETURNS TRIGGER AS $$
DECLARE
    v_sum_debit NUMERIC(18,4);
    v_sum_credit NUMERIC(18,4);
    v_line_count INT;
BEGIN
    -- Durum POSTED yapılıyorsa:
    IF NEW.status = 'POSTED' THEN
        -- Zaten POSTED veya LOCKED ise tekrar POST edilemez (Duplicate posting engeli)
        IF OLD.status = 'POSTED' OR OLD.status = 'LOCKED' THEN
            RAISE EXCEPTION 'MÜKERRER ONAY ENGELİ: Bu yevmiye fişi zaten kesinleştirilmiştir (POSTED/LOCKED)!';
        END IF;

        -- Satırların kümülatif toplamını kontrol et
        SELECT 
            COALESCE(SUM(debit_amount), 0),
            COALESCE(SUM(credit_amount), 0),
            COUNT(*)
        INTO v_sum_debit, v_sum_credit, v_line_count
        FROM journal_lines
        WHERE journal_entry_id = NEW.id;

        IF v_line_count = 0 THEN
            RAISE EXCEPTION 'BOŞ FİŞ ENGELİ: Yevmiye fişinde hiçbir satır bulunmamaktadır!';
        END IF;

        IF v_sum_debit != v_sum_credit THEN
            RAISE EXCEPTION 'DENKLİK BOZUK: Yevmiye fişi satırları dengesiz! Toplam Borç: %, Toplam Alacak: %',
                v_sum_debit, v_sum_credit;
        END IF;

        IF v_sum_debit <= 0 THEN
            RAISE EXCEPTION 'SIFIR TUTAR ENGELİ: Yevmiye fişi toplam tutarı 0 veya negatif olamaz!';
        END IF;

        -- Başlık toplamlarını güncelle
        NEW.total_debit := v_sum_debit;
        NEW.total_credit := v_sum_credit;
        NEW.posted_at := COALESCE(NEW.posted_at, NOW());
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS trg_validate_journal_entry_posting ON journal_entries;
CREATE TRIGGER trg_validate_journal_entry_posting
BEFORE UPDATE OF status ON journal_entries
FOR EACH ROW EXECUTE FUNCTION validate_journal_entry_posting();


-- 5. ATOMİK TEK TRANSACTION'DA YEVMİYE FİŞİ ÜRETİMİ (RPC)
-- Yarım fiş oluşumunu engelleyen tek transaction fonksiyonu
CREATE OR REPLACE FUNCTION create_complete_journal_entry_rpc(
    p_tenant_id UUID,
    p_company_id UUID,
    p_entry_date DATE,
    p_entry_type VARCHAR(50),
    p_document_type VARCHAR(50),
    p_document_reference VARCHAR(100),
    p_description TEXT,
    p_lines JSONB,
    p_auto_post BOOLEAN DEFAULT FALSE,
    p_user_id UUID DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    v_journal_id UUID;
    v_line JSONB;
    v_line_no INT := 1;
    v_total_debit NUMERIC(18,4) := 0.0000;
    v_total_credit NUMERIC(18,4) := 0.0000;
    v_line_debit NUMERIC(18,4);
    v_line_credit NUMERIC(18,4);
    v_account_id UUID;
    v_party_id UUID;
    v_currency VARCHAR(5);
    v_rate NUMERIC(18,6);
    v_line_desc VARCHAR(255);
BEGIN
    -- 1. Satırların geçerliliğini ve toplam tutarlarını hesapla
    FOR v_line IN SELECT * FROM jsonb_array_elements(p_lines)
    LOOP
        v_line_debit := COALESCE((v_line->>'debit_amount')::NUMERIC, 0.0000);
        v_line_credit := COALESCE((v_line->>'credit_amount')::NUMERIC, 0.0000);
        v_total_debit := v_total_debit + v_line_debit;
        v_total_credit := v_total_credit + v_line_credit;
    END LOOP;

    -- Eğer otomatik onay istenmişse denklik kontrolü
    IF p_auto_post = TRUE THEN
        IF v_total_debit != v_total_credit THEN
            RAISE EXCEPTION 'DENKLİK HATASI: Fiş onaylanamaz! Toplam Borç (%) != Toplam Alacak (%)',
                v_total_debit, v_total_credit;
        END IF;
        IF v_total_debit <= 0 THEN
            RAISE EXCEPTION 'TUTAR HATASI: Fiş toplamı 0 veya negatif olamaz!';
        END IF;
    END IF;

    -- 2. Yevmiye Fişi Başlığı (DRAFT veya POSTED)
    INSERT INTO journal_entries (
        tenant_id,
        company_id,
        entry_date,
        entry_type,
        document_type,
        document_reference,
        description,
        total_debit,
        total_credit,
        status,
        posted_at,
        posted_by,
        created_at
    ) VALUES (
        p_tenant_id,
        p_company_id,
        p_entry_date,
        p_entry_type,
        p_document_type,
        p_document_reference,
        p_description,
        v_total_debit,
        v_total_credit,
        'DRAFT',
        NULL,
        NULL,
        NOW()
    ) RETURNING id INTO v_journal_id;

    -- 3. Yevmiye Satırları (journal_lines)
    FOR v_line IN SELECT * FROM jsonb_array_elements(p_lines)
    LOOP
        v_account_id := (v_line->>'account_id')::UUID;

        -- Şirket ve Tenant hesap izolasyon doğrulaması (Cross-Company Guard)
        IF NOT EXISTS (
            SELECT 1 FROM chart_of_accounts 
            WHERE id = v_account_id 
              AND tenant_id = p_tenant_id 
              AND company_id = p_company_id
        ) THEN
            RAISE EXCEPTION 'CROSS-COMPANY HESAP İHLALİ: "%" hesap kartı "%" şirketine veya bu tenanta ait değildir!',
                v_account_id, p_company_id;
        END IF;

        v_party_id := NULLIF(v_line->>'party_id', '')::UUID;
        v_line_debit := COALESCE((v_line->>'debit_amount')::NUMERIC, 0.0000);
        v_line_credit := COALESCE((v_line->>'credit_amount')::NUMERIC, 0.0000);
        v_currency := COALESCE(v_line->>'transaction_currency', 'SAR');
        v_rate := COALESCE((v_line->>'exchange_rate')::NUMERIC, 1.000000);
        v_line_desc := COALESCE(v_line->>'description', p_description);

        INSERT INTO journal_lines (
            tenant_id,
            company_id,
            journal_entry_id,
            account_id,
            party_id,
            line_number,
            description,
            debit_amount,
            credit_amount,
            transaction_currency,
            exchange_rate,
            base_debit_amount,
            base_credit_amount,
            created_at
        ) VALUES (
            p_tenant_id,
            p_company_id,
            v_journal_id,
            v_account_id,
            v_party_id,
            v_line_no,
            v_line_desc,
            v_line_debit,
            v_line_credit,
            v_currency,
            v_rate,
            ROUND(v_line_debit * v_rate, 4),
            ROUND(v_line_credit * v_rate, 4),
            NOW()
        );

        v_line_no := v_line_no + 1;
    END LOOP;

    -- 3.1. Otomatik Onay (p_auto_post)
    IF p_auto_post THEN
        UPDATE journal_entries
        SET status = 'POSTED',
            posted_at = NOW(),
            posted_by = p_user_id,
            updated_at = NOW()
        WHERE id = v_journal_id;
    END IF;

    -- 4. Audit Log Kaydı (CREATE / POST)
    INSERT INTO audit_logs (
        tenant_id,
        user_id,
        company_id,
        action,
        entity_type,
        entity_id,
        new_data
    ) VALUES (
        p_tenant_id,
        p_user_id,
        p_company_id,
        (CASE WHEN p_auto_post THEN 'POST' ELSE 'CREATE' END)::audit_action_enum,
        'journal_entry',
        v_journal_id,
        jsonb_build_object(
            'entry_id', v_journal_id,
            'entry_type', p_entry_type,
            'entry_date', p_entry_date,
            'total_debit', v_total_debit,
            'total_credit', v_total_credit,
            'status', CASE WHEN p_auto_post THEN 'POSTED' ELSE 'DRAFT' END,
            'line_count', (v_line_no - 1)
        )
    );

    RETURN v_journal_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;


-- 6. TERS KAYIT MEKANİZMASI (REVERSAL RPC)
-- Hatalı kesinleşmiş fişler için ters kayıt üretir ve orijinal fişi REVERSED yapar
CREATE OR REPLACE FUNCTION reverse_journal_entry_rpc(
    p_journal_entry_id UUID,
    p_reversal_date DATE,
    p_reversal_reason TEXT,
    p_user_id UUID DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    v_orig journal_entries%ROWTYPE;
    v_reversal_id UUID;
    v_line RECORD;
    v_line_no INT := 1;
BEGIN
    -- Orijinal fişi kilitle ve kontrol et
    SELECT * INTO v_orig
    FROM journal_entries
    WHERE id = p_journal_entry_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'FİŞ BULUNAMADI: "%" ID numaralı yevmiye fişi mevcut değil!', p_journal_entry_id;
    END IF;

    IF v_orig.status != 'POSTED' AND v_orig.status != 'LOCKED' THEN
        RAISE EXCEPTION 'TERS KAYIT HATASI: Yalnızca kesinleşmiş (POSTED/LOCKED) fişlerin ters kaydı alınabilir! Mevcut Durum: %', v_orig.status;
    END IF;

    -- 1. Ters Kayıt Fiş Başlığı (Ters Borç/Alacak toplamları ile)
    INSERT INTO journal_entries (
        tenant_id,
        company_id,
        entry_date,
        entry_type,
        document_type,
        document_reference,
        description,
        total_debit,
        total_credit,
        status,
        posted_at,
        posted_by,
        is_reversal,
        reversed_entry_id,
        created_at
    ) VALUES (
        v_orig.tenant_id,
        v_orig.company_id,
        p_reversal_date,
        v_orig.entry_type,
        v_orig.document_type,
        COALESCE(v_orig.document_reference, '') || '-REV',
        'TERS KAYIT (REVERSAL): ' || v_orig.description || ' [Gerekçe: ' || p_reversal_reason || ']',
        v_orig.total_credit, -- Borç ve alacak takas edilir
        v_orig.total_debit,
        'DRAFT',
        NULL,
        NULL,
        TRUE,
        v_orig.id,
        NOW()
    ) RETURNING id INTO v_reversal_id;

    -- 2. Orijinal fişin satırlarını ters çevirerek (Borç -> Alacak, Alacak -> Borç) yeni satırlar oluştur
    FOR v_line IN 
        SELECT * FROM journal_lines 
        WHERE journal_entry_id = v_orig.id 
        ORDER BY line_number
    LOOP
        INSERT INTO journal_lines (
            tenant_id,
            company_id,
            journal_entry_id,
            account_id,
            party_id,
            line_number,
            description,
            debit_amount,
            credit_amount,
            transaction_currency,
            exchange_rate,
            base_debit_amount,
            base_credit_amount,
            created_at
        ) VALUES (
            v_orig.tenant_id,
            v_orig.company_id,
            v_reversal_id,
            v_line.account_id,
            v_line.party_id,
            v_line_no,
            'Ters Kayıt Satırı: ' || COALESCE(v_line.description, ''),
            v_line.credit_amount, -- Borç ile alacak yer değiştirir
            v_line.debit_amount,
            v_line.transaction_currency,
            v_line.exchange_rate,
            v_line.base_credit_amount,
            v_line.base_debit_amount,
            NOW()
        );
        v_line_no := v_line_no + 1;
    END LOOP;

    -- 2.1. Ters kayıt fişini kesinleştir (POSTED)
    UPDATE journal_entries
    SET status = 'POSTED',
        posted_at = NOW(),
        posted_by = p_user_id,
        updated_at = NOW()
    WHERE id = v_reversal_id;

    -- 3. Orijinal fişin durumunu REVERSED yap
    UPDATE journal_entries
    SET status = 'REVERSED',
        updated_at = NOW()
    WHERE id = v_orig.id;

    -- 4. Audit Log Kaydı (REVERSE)
    INSERT INTO audit_logs (
        tenant_id,
        user_id,
        company_id,
        action,
        entity_type,
        entity_id,
        new_data
    ) VALUES (
        v_orig.tenant_id,
        p_user_id,
        v_orig.company_id,
        'REVERSE'::audit_action_enum,
        'journal_entry',
        v_orig.id,
        jsonb_build_object(
            'original_entry_id', v_orig.id,
            'reversal_entry_id', v_reversal_id,
            'reversal_date', p_reversal_date,
            'reason', p_reversal_reason,
            'amount', v_orig.total_debit
        )
    );

    RETURN v_reversal_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;


-- 7. GENEL YEVMİYE AUDIT LOG TETİKLEYİCİSİ
CREATE OR REPLACE FUNCTION audit_journal_entries_activity()
RETURNS TRIGGER AS $$
DECLARE
    v_action audit_action_enum;
BEGIN
    IF TG_OP = 'INSERT' THEN
        v_action := 'CREATE';
    ELSIF TG_OP = 'UPDATE' THEN
        IF OLD.status != 'POSTED' AND NEW.status = 'POSTED' THEN
            v_action := 'POST';
        ELSIF OLD.status != 'REVERSED' AND NEW.status = 'REVERSED' THEN
            v_action := 'REVERSE';
        ELSIF OLD.status != 'VALIDATED' AND NEW.status = 'VALIDATED' THEN
            v_action := 'APPROVE';
        ELSE
            v_action := 'UPDATE';
        END IF;
    END IF;

    -- Audit log yazımı
    INSERT INTO audit_logs (
        tenant_id,
        user_id,
        company_id,
        action,
        entity_type,
        entity_id,
        old_data,
        new_data
    ) VALUES (
        NEW.tenant_id,
        COALESCE(NEW.posted_by, auth.uid()),
        NEW.company_id,
        v_action,
        'journal_entry',
        NEW.id,
        CASE WHEN TG_OP = 'UPDATE' THEN jsonb_build_object('status', OLD.status, 'total_debit', OLD.total_debit) ELSE NULL END,
        jsonb_build_object('status', NEW.status, 'total_debit', NEW.total_debit, 'entry_date', NEW.entry_date)
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS trg_audit_journal_entries_activity ON journal_entries;
CREATE TRIGGER trg_audit_journal_entries_activity
AFTER INSERT OR UPDATE ON journal_entries
FOR EACH ROW EXECUTE FUNCTION audit_journal_entries_activity();

-- 8. RLS GÜNCELLEMELERİ (EXCHANGE RATES)
ALTER TABLE exchange_rates ENABLE ROW LEVEL SECURITY;
ALTER TABLE exchange_rates FORCE ROW LEVEL SECURITY;

CREATE POLICY "exchange_rates_select" ON exchange_rates
    FOR SELECT USING (is_tenant_member(tenant_id));

CREATE POLICY "exchange_rates_manage" ON exchange_rates
    FOR ALL USING (is_tenant_admin(tenant_id))
    WITH CHECK (is_tenant_admin(tenant_id));
