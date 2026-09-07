-- ==============================================================================
-- NAKHL & NAHL — MIGRATION 023: ÇİFT TARAFLI MUHASEBE (GENERAL LEDGER)
-- Purpose: Hesap Planı, Mali Dönemler, Yevmiye Fişleri ve Yevmiye Satırları
-- ==============================================================================

-- 1. Mali Dönemler (Fiscal Periods)
CREATE TABLE IF NOT EXISTS fiscal_periods (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    year INT NOT NULL,
    period_no INT NOT NULL, -- 1-12
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_closed BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_fiscal_period UNIQUE (company_id, year, period_no)
);

-- 2. Hesap Planı (Chart of Accounts)
CREATE TABLE IF NOT EXISTS chart_of_accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    parent_id UUID REFERENCES chart_of_accounts(id) ON DELETE RESTRICT,
    account_code VARCHAR(50) NOT NULL,
    account_name VARCHAR(255) NOT NULL,
    account_type VARCHAR(50) NOT NULL, -- ASSET, LIABILITY, EQUITY, REVENUE, EXPENSE
    balance_type VARCHAR(10) NOT NULL DEFAULT 'DEBIT', -- DEBIT, CREDIT
    currency_code VARCHAR(5) NOT NULL DEFAULT 'SAR',
    allow_reconciliation BOOLEAN NOT NULL DEFAULT TRUE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_account_company_code UNIQUE (company_id, account_code)
);

-- 3. Yevmiye Fişleri (Journal Entries)
CREATE TABLE IF NOT EXISTS journal_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    fiscal_period_id UUID REFERENCES fiscal_periods(id),
    entry_number BIGSERIAL,
    entry_date DATE NOT NULL DEFAULT CURRENT_DATE,
    entry_type VARCHAR(50) NOT NULL DEFAULT 'JOURNAL', -- JOURNAL, SALES_INVOICE, PURCHASE_INVOICE, PAYMENT, COLLECTION, CLOSING
    document_type VARCHAR(50), -- ZATCA_INVOICE, GIB_INVOICE, BANK_RECEIPT
    document_reference VARCHAR(100),
    description TEXT,
    total_debit NUMERIC(18,4) NOT NULL DEFAULT 0.0000,
    total_credit NUMERIC(18,4) NOT NULL DEFAULT 0.0000,
    status VARCHAR(50) NOT NULL DEFAULT 'DRAFT', -- DRAFT, POSTED, LOCKED, REVERSED
    posted_at TIMESTAMPTZ,
    posted_by UUID REFERENCES public.users(id),
    is_reversal BOOLEAN NOT NULL DEFAULT FALSE,
    reversed_entry_id UUID REFERENCES journal_entries(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_journal_entry_balance CHECK (status != 'POSTED' OR total_debit = total_credit)
);

-- 4. Yevmiye Satırları (Journal Lines)
CREATE TABLE IF NOT EXISTS journal_lines (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    journal_entry_id UUID NOT NULL REFERENCES journal_entries(id) ON DELETE CASCADE,
    account_id UUID NOT NULL REFERENCES chart_of_accounts(id),
    party_id UUID,
    line_number INT NOT NULL,
    description VARCHAR(255),
    debit_amount NUMERIC(18,4) NOT NULL DEFAULT 0.0000,
    credit_amount NUMERIC(18,4) NOT NULL DEFAULT 0.0000,
    transaction_currency VARCHAR(5) NOT NULL DEFAULT 'SAR',
    exchange_rate NUMERIC(12,6) NOT NULL DEFAULT 1.000000,
    base_debit_amount NUMERIC(18,4) NOT NULL DEFAULT 0.0000,
    base_credit_amount NUMERIC(18,4) NOT NULL DEFAULT 0.0000,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. Kesinleşmiş (POSTED) Fişlerin Değiştirilemezlik (Immutability) Tetikleyicisi
CREATE OR REPLACE FUNCTION prevent_posted_journal_modification()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.status = 'POSTED' OR OLD.status = 'LOCKED' THEN
        IF TG_OP = 'DELETE' THEN
            RAISE EXCEPTION 'Kesinleşmiş (POSTED) muhasebe yevmiye fişleri kesinlikle silinemez! Hatalar için ters kayıt (reversal) oluşturulmalıdır.';
        END IF;
        IF TG_OP = 'UPDATE' AND NEW.status != 'REVERSED' AND (
            OLD.total_debit != NEW.total_debit OR 
            OLD.total_credit != NEW.total_credit OR 
            OLD.entry_date != NEW.entry_date
        ) THEN
            RAISE EXCEPTION 'Kesinleşmiş (POSTED) muhasebe fişinin tutarları veya tarihi değiştirilemez!';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_prevent_posted_journal_modification ON journal_entries;
CREATE TRIGGER trg_prevent_posted_journal_modification
BEFORE UPDATE OR DELETE ON journal_entries
FOR EACH ROW EXECUTE FUNCTION prevent_posted_journal_modification();

-- 6. RLS Aktifleştirme
ALTER TABLE fiscal_periods ENABLE ROW LEVEL SECURITY;
ALTER TABLE chart_of_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE journal_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE journal_lines ENABLE ROW LEVEL SECURITY;

ALTER TABLE fiscal_periods FORCE ROW LEVEL SECURITY;
ALTER TABLE chart_of_accounts FORCE ROW LEVEL SECURITY;
ALTER TABLE journal_entries FORCE ROW LEVEL SECURITY;
ALTER TABLE journal_lines FORCE ROW LEVEL SECURITY;

-- 7. RLS Politikaları
CREATE POLICY "fiscal_periods_select" ON fiscal_periods
    FOR SELECT USING (is_tenant_member(tenant_id) AND has_company_access(company_id));

CREATE POLICY "chart_of_accounts_select" ON chart_of_accounts
    FOR SELECT USING (is_tenant_member(tenant_id) AND has_company_access(company_id));

CREATE POLICY "chart_of_accounts_manage" ON chart_of_accounts
    FOR ALL USING (is_tenant_admin(tenant_id))
    WITH CHECK (is_tenant_admin(tenant_id));

CREATE POLICY "journal_entries_select" ON journal_entries
    FOR SELECT USING (is_tenant_member(tenant_id) AND has_company_access(company_id));

CREATE POLICY "journal_entries_insert" ON journal_entries
    FOR INSERT WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(company_id));

CREATE POLICY "journal_entries_update" ON journal_entries
    FOR UPDATE USING (is_tenant_member(tenant_id) AND has_company_access(company_id))
    WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(company_id));

CREATE POLICY "journal_lines_select" ON journal_lines
    FOR SELECT USING (is_tenant_member(tenant_id) AND has_company_access(company_id));

CREATE POLICY "journal_lines_manage" ON journal_lines
    FOR ALL USING (is_tenant_member(tenant_id) AND has_company_access(company_id))
    WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(company_id));

-- 8. İndeksler
CREATE INDEX IF NOT EXISTS idx_journal_entries_tenant_comp ON journal_entries(tenant_id, company_id);
CREATE INDEX IF NOT EXISTS idx_journal_entries_date ON journal_entries(entry_date DESC);
CREATE INDEX IF NOT EXISTS idx_journal_lines_entry_id ON journal_lines(journal_entry_id);
CREATE INDEX IF NOT EXISTS idx_journal_lines_account_id ON journal_lines(account_id);
CREATE INDEX IF NOT EXISTS idx_journal_lines_party_id ON journal_lines(party_id);
CREATE INDEX IF NOT EXISTS idx_coa_company_code ON chart_of_accounts(company_id, account_code);
