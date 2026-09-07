-- ==============================================================================
-- NAKHL & NAHL — FAZ 25: POS / OPERATIONAL SALES BOUNDED CONTEXT
-- Point of Sale, Payment Abstraction, Atomic Posting, Offline Replay Protection & Receipts
-- ==============================================================================

-- 1. POS TERMINALLERİ
CREATE TABLE IF NOT EXISTS pos_terminals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    warehouse_id UUID NOT NULL REFERENCES warehouses(id) ON DELETE RESTRICT,
    terminal_code VARCHAR(50) NOT NULL,
    name VARCHAR(100) NOT NULL,
    device_identifier VARCHAR(100),
    status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'SUSPENDED', 'OFFLINE')),
    ip_address VARCHAR(50),
    last_synced_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_pos_terminal_company UNIQUE (company_id, terminal_code)
);

-- 2. POS KASA VARDİYALARI (Sessions)
CREATE TABLE IF NOT EXISTS pos_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    terminal_id UUID NOT NULL REFERENCES pos_terminals(id) ON DELETE RESTRICT,
    cashier_user_id UUID NOT NULL REFERENCES public.users(id),
    opened_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    closed_at TIMESTAMPTZ,
    opening_cash_balance NUMERIC(18,4) NOT NULL DEFAULT 0.0000,
    closing_cash_balance NUMERIC(18,4),
    status VARCHAR(50) NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'CLOSED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. POS SATIŞLARI (POS Sales Master)
-- OFFLINE REPLAY PROTECTION: client_transaction_id UNIQUE kısıtı ile mükerrer fiş/işlem engellenir!
CREATE TABLE IF NOT EXISTS pos_sales (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    terminal_id UUID REFERENCES pos_terminals(id) ON DELETE SET NULL,
    session_id UUID REFERENCES pos_sessions(id) ON DELETE SET NULL,
    
    receipt_number VARCHAR(100) NOT NULL,
    client_transaction_id VARCHAR(100) NOT NULL, -- Çevrimdışı tekil işlem ID'si (Idempotency Key)
    transaction_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    customer_party_id UUID REFERENCES parties(id) ON DELETE SET NULL,
    warehouse_id UUID NOT NULL REFERENCES warehouses(id) ON DELETE RESTRICT,
    
    currency VARCHAR(5) NOT NULL DEFAULT 'SAR',
    subtotal NUMERIC(18,4) NOT NULL DEFAULT 0.0000,
    tax_rate NUMERIC(5,2) NOT NULL DEFAULT 15.00,
    tax_amount NUMERIC(18,4) NOT NULL DEFAULT 0.0000,
    discount_amount NUMERIC(18,4) NOT NULL DEFAULT 0.0000,
    grand_total NUMERIC(18,4) NOT NULL DEFAULT 0.0000,
    
    status VARCHAR(50) NOT NULL DEFAULT 'COMPLETED' CHECK (status IN ('COMPLETED', 'REFUNDED', 'VOID')),
    
    -- Muhasebe & Belge Entegrasyonu
    journal_entry_id UUID REFERENCES journal_entries(id) ON DELETE SET NULL,
    zatca_qr_code TEXT,
    notes TEXT,
    
    offline_created_at TIMESTAMPTZ,
    created_by UUID REFERENCES public.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CONSTRAINT uq_pos_sale_client_tx UNIQUE (company_id, client_transaction_id)
);

-- 4. POS SATIŞ KALEMLERİ
CREATE TABLE IF NOT EXISTS pos_sale_lines (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    pos_sale_id UUID NOT NULL REFERENCES pos_sales(id) ON DELETE CASCADE,
    item_id UUID NOT NULL REFERENCES items(id) ON DELETE RESTRICT,
    lot_id UUID REFERENCES item_lots(id) ON DELETE SET NULL,
    line_number INT NOT NULL DEFAULT 1,
    quantity NUMERIC(15,3) NOT NULL,
    uom VARCHAR(20) NOT NULL DEFAULT 'Kg',
    unit_price NUMERIC(18,4) NOT NULL,
    discount_amount NUMERIC(18,4) NOT NULL DEFAULT 0.0000,
    tax_rate NUMERIC(5,2) NOT NULL DEFAULT 15.00,
    tax_amount NUMERIC(18,4) NOT NULL DEFAULT 0.0000,
    total_amount NUMERIC(18,4) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. POS ÖDEMELERİ (Payment Method Abstraction)
CREATE TABLE IF NOT EXISTS pos_payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    pos_sale_id UUID NOT NULL REFERENCES pos_sales(id) ON DELETE CASCADE,
    payment_method VARCHAR(50) NOT NULL CHECK (payment_method IN ('CASH', 'CREDIT_CARD', 'MADA_DEBIT', 'BANK_TRANSFER', 'LOYALTY_POINTS')),
    amount NUMERIC(18,4) NOT NULL,
    currency VARCHAR(5) NOT NULL DEFAULT 'SAR',
    reference_code VARCHAR(100),
    payment_status VARCHAR(50) NOT NULL DEFAULT 'COMPLETED' CHECK (payment_status IN ('COMPLETED', 'REFUNDED')),
    cash_bank_account_id UUID REFERENCES cash_bank_accounts(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==============================================================================
-- 6. ATOMİK POS SATIŞ VE MUHASEBE / STOK İŞLEMİ (execute_pos_sale_transaction)
-- PRODUCT -> SALE -> PAYMENT -> STOCK MOVEMENT -> JOURNAL
-- ==============================================================================
CREATE OR REPLACE FUNCTION execute_pos_sale_transaction(
    p_tenant_id UUID,
    p_company_id UUID,
    p_terminal_id UUID,
    p_session_id UUID,
    p_client_transaction_id VARCHAR(100),
    p_warehouse_id UUID,
    p_customer_party_id UUID,
    p_lines JSONB, -- [ {"item_id": "...", "lot_id": "...", "quantity": 2, "unit_price": 40.0, "tax_rate": 15.0} ]
    p_payments JSONB, -- [ {"payment_method": "CASH", "amount": 92.0, "reference_code": "..."} ]
    p_currency VARCHAR(5) DEFAULT 'SAR',
    p_user_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_existing_sale RECORD;
    v_pos_sale_id UUID;
    v_receipt_number VARCHAR(100);
    v_subtotal NUMERIC(18,4) := 0.0000;
    v_tax_total NUMERIC(18,4) := 0.0000;
    v_grand_total NUMERIC(18,4) := 0.0000;
    v_payment_total NUMERIC(18,4) := 0.0000;
    
    v_line RECORD;
    v_pay RECORD;
    v_line_number INT := 1;
    v_line_subtotal NUMERIC(18,4);
    v_line_tax NUMERIC(18,4);
    v_line_total NUMERIC(18,4);
    
    -- Muhasebe Hesapları
    v_journal_id UUID;
    v_entry_number VARCHAR(100);
    v_acc_cash_id UUID;
    v_acc_bank_id UUID;
    v_acc_sales_id UUID;
    v_acc_vat_id UUID;
    v_current_year INT := EXTRACT(YEAR FROM CURRENT_DATE)::INT;
    v_zatca_qr TEXT;
BEGIN
    -- 1. ADIM: REPLAY / DUPLICATE PROTECTION (Çevrimdışı Tekrar Koruma)
    SELECT * INTO v_existing_sale 
    FROM pos_sales 
    WHERE company_id = p_company_id AND client_transaction_id = p_client_transaction_id;

    IF FOUND THEN
        -- Zaten işlenmiş; mükerrer işlem yapma, mevcut sonucu güvenle dön!
        RETURN jsonb_build_object(
            'success', true,
            'is_replay', true,
            'pos_sale_id', v_existing_sale.id,
            'receipt_number', v_existing_sale.receipt_number,
            'grand_total', v_existing_sale.grand_total,
            'message', 'Mevcut POS satışı bulundu (Replay koruması etkin).'
        );
    END IF;

    -- 2. ADIM: KALEMLERİ HESAPLA
    FOR v_line IN SELECT * FROM jsonb_to_recordset(p_lines) AS x(
        item_id UUID, lot_id UUID, quantity NUMERIC, unit_price NUMERIC, tax_rate NUMERIC
    ) LOOP
        v_line_subtotal := ROUND(v_line.quantity * v_line.unit_price, 4);
        v_line_tax := ROUND(v_line_subtotal * (COALESCE(v_line.tax_rate, 15.00) / 100.00), 4);
        v_line_total := v_line_subtotal + v_line_tax;

        v_subtotal := v_subtotal + v_line_subtotal;
        v_tax_total := v_tax_total + v_line_tax;
        v_grand_total := v_grand_total + v_line_total;
    END LOOP;

    -- Ödemeleri doğrula
    FOR v_pay IN SELECT * FROM jsonb_to_recordset(p_payments) AS y(
        payment_method VARCHAR, amount NUMERIC, reference_code VARCHAR
    ) LOOP
        v_payment_total := v_payment_total + v_pay.amount;
    END LOOP;

    IF v_payment_total < v_grand_total THEN
        RAISE EXCEPTION 'ÖDEME EKSİK: Genel toplam (%), alınan ödemeden (%) fazla olamaz!', v_grand_total, v_payment_total;
    END IF;

    -- Fiş No Üretimi
    v_receipt_number := 'REC-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || LPAD(FLOOR(RANDOM() * 100000)::TEXT, 5, '0');
    v_zatca_qr := 'ZATCA-QR:' || v_receipt_number || ':' || v_grand_total::TEXT || ':' || v_tax_total::TEXT;

    -- 3. ADIM: POS SALE MASTER INSERT
    INSERT INTO pos_sales (
        tenant_id, company_id, terminal_id, session_id,
        receipt_number, client_transaction_id, transaction_date,
        customer_party_id, warehouse_id, currency,
        subtotal, tax_rate, tax_amount, grand_total,
        status, zatca_qr_code, created_by
    ) VALUES (
        p_tenant_id, p_company_id, p_terminal_id, p_session_id,
        v_receipt_number, p_client_transaction_id, NOW(),
        p_customer_party_id, p_warehouse_id, p_currency,
        v_subtotal, 15.00, v_tax_total, v_grand_total,
        'COMPLETED', v_zatca_qr, p_user_id
    ) RETURNING id INTO v_pos_sale_id;

    -- 4. ADIM: SATIŞ KALEMLERİ VE STOK ÇIKIŞI (STOCK MOVEMENT: OUT)
    FOR v_line IN SELECT * FROM jsonb_to_recordset(p_lines) AS x(
        item_id UUID, lot_id UUID, quantity NUMERIC, unit_price NUMERIC, tax_rate NUMERIC
    ) LOOP
        v_line_subtotal := ROUND(v_line.quantity * v_line.unit_price, 4);
        v_line_tax := ROUND(v_line_subtotal * (COALESCE(v_line.tax_rate, 15.00) / 100.00), 4);
        v_line_total := v_line_subtotal + v_line_tax;

        INSERT INTO pos_sale_lines (
            tenant_id, company_id, pos_sale_id,
            item_id, lot_id, line_number,
            quantity, unit_price, tax_rate, tax_amount, total_amount
        ) VALUES (
            p_tenant_id, p_company_id, v_pos_sale_id,
            v_line.item_id, v_line.lot_id, v_line_number,
            v_line.quantity, v_line.unit_price, COALESCE(v_line.tax_rate, 15.00), v_line_tax, v_line_total
        );

        -- STOK HAREKETİ KAYDI (INVENTORY LEDGER)
        INSERT INTO stock_ledger (
            tenant_id, company_id, warehouse_id, item_id,
            movement_type, quantity, unit_cost, total_cost,
            direction, reference_type, reference_id, created_by
        ) VALUES (
            p_tenant_id, p_company_id, p_warehouse_id, v_line.item_id,
            'POS_SALE', v_line.quantity, v_line.unit_price, v_line_subtotal,
            'OUT', 'POS_SALE', v_pos_sale_id, p_user_id
        );

        v_line_number := v_line_number + 1;
    END LOOP;

    -- 5. ADIM: ÖDEMELERİN KAYDI
    FOR v_pay IN SELECT * FROM jsonb_to_recordset(p_payments) AS y(
        payment_method VARCHAR, amount NUMERIC, reference_code VARCHAR
    ) LOOP
        INSERT INTO pos_payments (
            tenant_id, company_id, pos_sale_id,
            payment_method, amount, currency, reference_code
        ) VALUES (
            p_tenant_id, p_company_id, v_pos_sale_id,
            v_pay.payment_method, v_pay.amount, p_currency, v_pay.reference_code
        );
    END LOOP;

    -- 6. ADIM: ÇİFT TARAFLI YEVMİYE KAYDI (JOURNAL ENTRY ATOMİC POST)
    -- Hesapları Çöz
    SELECT id INTO v_acc_cash_id FROM chart_of_accounts WHERE company_id = p_company_id AND account_code = '100' LIMIT 1;
    IF v_acc_cash_id IS NULL THEN
        INSERT INTO chart_of_accounts (tenant_id, company_id, account_code, account_name, account_type, balance_type, currency_code, posting_allowed)
        VALUES (p_tenant_id, p_company_id, '100', 'Kasa Hesabı', 'ASSET', 'DEBIT', p_currency, TRUE) RETURNING id INTO v_acc_cash_id;
    END IF;

    SELECT id INTO v_acc_bank_id FROM chart_of_accounts WHERE company_id = p_company_id AND account_code = '102' LIMIT 1;
    IF v_acc_bank_id IS NULL THEN
        INSERT INTO chart_of_accounts (tenant_id, company_id, account_code, account_name, account_type, balance_type, currency_code, posting_allowed)
        VALUES (p_tenant_id, p_company_id, '102', 'Banka / Kart Hesabı', 'ASSET', 'DEBIT', p_currency, TRUE) RETURNING id INTO v_acc_bank_id;
    END IF;

    SELECT id INTO v_acc_sales_id FROM chart_of_accounts WHERE company_id = p_company_id AND account_code = '600' LIMIT 1;
    IF v_acc_sales_id IS NULL THEN
        INSERT INTO chart_of_accounts (tenant_id, company_id, account_code, account_name, account_type, balance_type, currency_code, posting_allowed)
        VALUES (p_tenant_id, p_company_id, '600', 'Yurtiçi Hurma Satışları', 'REVENUE', 'CREDIT', p_currency, TRUE) RETURNING id INTO v_acc_sales_id;
    END IF;

    SELECT id INTO v_acc_vat_id FROM chart_of_accounts WHERE company_id = p_company_id AND account_code = '391' LIMIT 1;
    IF v_acc_vat_id IS NULL THEN
        INSERT INTO chart_of_accounts (tenant_id, company_id, account_code, account_name, account_type, balance_type, currency_code, posting_allowed)
        VALUES (p_tenant_id, p_company_id, '391', 'Hesaplanan KDV', 'LIABILITY', 'CREDIT', p_currency, TRUE) RETURNING id INTO v_acc_vat_id;
    END IF;

    v_entry_number := 'JRN-POS-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || LPAD(FLOOR(RANDOM() * 100000)::TEXT, 5, '0');

    INSERT INTO journal_entries (
        tenant_id, company_id, entry_number, entry_date,
        currency, exchange_rate, total_debit, total_credit,
        status, entry_type, source_document_type, source_document_id,
        description, created_by
    ) VALUES (
        p_tenant_id, p_company_id, v_entry_number, CURRENT_DATE,
        p_currency, 1.0, v_grand_total, v_grand_total,
        'POSTED', 'POS_SALE', 'POS_SALE', v_pos_sale_id,
        'POS Satış Fişi: ' || v_receipt_number, p_user_id
    ) RETURNING id INTO v_journal_id;

    -- Yevmiye Borç Satırı (Ödeme Yöntemine Göre Kasa / Banka)
    FOR v_pay IN SELECT * FROM jsonb_to_recordset(p_payments) AS y(
        payment_method VARCHAR, amount NUMERIC
    ) LOOP
        INSERT INTO journal_lines (
            tenant_id, company_id, entry_id, line_number,
            account_id, debit_amount, credit_amount, description
        ) VALUES (
            p_tenant_id, p_company_id, v_journal_id, 1,
            CASE WHEN v_pay.payment_method = 'CASH' THEN v_acc_cash_id ELSE v_acc_bank_id END,
            v_pay.amount, 0.0000, 'POS Tahsilatı (' || v_pay.payment_method || ')'
        );
    END LOOP;

    -- Yevmiye Alacak Satırı 1: Satış Geliri (Net Tutar)
    INSERT INTO journal_lines (
        tenant_id, company_id, entry_id, line_number,
        account_id, debit_amount, credit_amount, description
    ) VALUES (
        p_tenant_id, p_company_id, v_journal_id, 2,
        v_acc_sales_id, 0.0000, v_subtotal, 'POS Satış Hasılatı'
    );

    -- Yevmiye Alacak Satırı 2: KDV (Tax)
    IF v_tax_total > 0 THEN
        INSERT INTO journal_lines (
            tenant_id, company_id, entry_id, line_number,
            account_id, debit_amount, credit_amount, description
        ) VALUES (
            p_tenant_id, p_company_id, v_journal_id, 3,
            v_acc_vat_id, 0.0000, v_tax_total, 'POS Satış KDV'
        );
    END IF;

    -- Satış kaydına journal_id bağla
    UPDATE pos_sales SET journal_entry_id = v_journal_id WHERE id = v_pos_sale_id;

    RETURN jsonb_build_object(
        'success', true,
        'is_replay', false,
        'pos_sale_id', v_pos_sale_id,
        'receipt_number', v_receipt_number,
        'journal_entry_id', v_journal_id,
        'subtotal', v_subtotal,
        'tax_amount', v_tax_total,
        'grand_total', v_grand_total,
        'zatca_qr', v_zatca_qr
    );
END;
$$;

-- ==============================================================================
-- 7. ATOMİK POS İADE VE TERS KAYIT İŞLEMİ (execute_pos_refund_transaction)
-- REFUND -> STOCK REVERSAL -> REVERSAL JOURNAL
-- ==============================================================================
CREATE OR REPLACE FUNCTION execute_pos_refund_transaction(
    p_pos_sale_id UUID,
    p_refund_reason TEXT DEFAULT 'Müşteri Talebi',
    p_user_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_sale RECORD;
    v_line RECORD;
    v_pay RECORD;
    v_reverse_journal_id UUID;
    v_entry_number VARCHAR(100);
    v_acc_cash_id UUID;
    v_acc_bank_id UUID;
    v_acc_returns_id UUID;
    v_acc_vat_id UUID;
BEGIN
    SELECT * INTO v_sale FROM pos_sales WHERE id = p_pos_sale_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'POS satışı bulunamadı: %', p_pos_sale_id;
    END IF;

    IF v_sale.status = 'REFUNDED' THEN
        RAISE EXCEPTION 'Bu POS satışı zaten iade edilmiştir!';
    END IF;

    -- 1. STOK İADESİ (STOCK MOVEMENT: IN)
    FOR v_line IN SELECT * FROM pos_sale_lines WHERE pos_sale_id = p_pos_sale_id LOOP
        INSERT INTO stock_ledger (
            tenant_id, company_id, warehouse_id, item_id,
            movement_type, quantity, unit_cost, total_cost,
            direction, reference_type, reference_id, created_by
        ) VALUES (
            v_sale.tenant_id, v_sale.company_id, v_sale.warehouse_id, v_line.item_id,
            'POS_REFUND', v_line.quantity, v_line.unit_price, (v_line.quantity * v_line.unit_price),
            'IN', 'POS_REFUND', v_sale.id, p_user_id
        );
    END LOOP;

    -- 2. TERS YEVMİYE KAYDI (REFUND JOURNAL)
    SELECT id INTO v_acc_cash_id FROM chart_of_accounts WHERE company_id = v_sale.company_id AND account_code = '100' LIMIT 1;
    SELECT id INTO v_acc_bank_id FROM chart_of_accounts WHERE company_id = v_sale.company_id AND account_code = '102' LIMIT 1;
    
    SELECT id INTO v_acc_returns_id FROM chart_of_accounts WHERE company_id = v_sale.company_id AND account_code = '610' LIMIT 1;
    IF v_acc_returns_id IS NULL THEN
        INSERT INTO chart_of_accounts (tenant_id, company_id, account_code, account_name, account_type, balance_type, currency_code, posting_allowed)
        VALUES (v_sale.tenant_id, v_sale.company_id, '610', 'Satıştan İadeler', 'EXPENSE', 'DEBIT', v_sale.currency, TRUE) RETURNING id INTO v_acc_returns_id;
    END IF;

    SELECT id INTO v_acc_vat_id FROM chart_of_accounts WHERE company_id = v_sale.company_id AND account_code = '391' LIMIT 1;

    v_entry_number := 'JRN-REF-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || LPAD(FLOOR(RANDOM() * 100000)::TEXT, 5, '0');

    INSERT INTO journal_entries (
        tenant_id, company_id, entry_number, entry_date,
        currency, exchange_rate, total_debit, total_credit,
        status, entry_type, source_document_type, source_document_id,
        description, created_by
    ) VALUES (
        v_sale.tenant_id, v_sale.company_id, v_entry_number, CURRENT_DATE,
        v_sale.currency, 1.0, v_sale.grand_total, v_sale.grand_total,
        'POSTED', 'POS_REFUND', 'POS_SALE', v_sale.id,
        'POS Satış İadesi: ' || v_sale.receipt_number || ' - ' || p_refund_reason, p_user_id
    ) RETURNING id INTO v_reverse_journal_id;

    -- Borç Satırı: Satıştan İadeler (Net Tutar)
    INSERT INTO journal_lines (
        tenant_id, company_id, entry_id, line_number,
        account_id, debit_amount, credit_amount, description
    ) VALUES (
        v_sale.tenant_id, v_sale.company_id, v_reverse_journal_id, 1,
        v_acc_returns_id, v_sale.subtotal, 0.0000, 'Satış İade Borcu'
    );

    -- Borç Satırı: KDV İadesi
    IF v_sale.tax_amount > 0 THEN
        INSERT INTO journal_lines (
            tenant_id, company_id, entry_id, line_number,
            account_id, debit_amount, credit_amount, description
        ) VALUES (
            v_sale.tenant_id, v_sale.company_id, v_reverse_journal_id, 2,
            v_acc_vat_id, v_sale.tax_amount, 0.0000, 'KDV Düzeltme Borcu'
        );
    END IF;

    -- Alacak Satırı: Kasa / Banka İade Çıkışı
    INSERT INTO journal_lines (
        tenant_id, company_id, entry_id, line_number,
        account_id, debit_amount, credit_amount, description
    ) VALUES (
        v_sale.tenant_id, v_sale.company_id, v_reverse_journal_id, 3,
        v_acc_cash_id, 0.0000, v_sale.grand_total, 'Nakit/Kart İade Çıkışı'
    );

    -- 3. SATIŞ VE ÖDEMELERİ GÜNCELLE
    UPDATE pos_sales 
    SET status = 'REFUNDED', notes = COALESCE(notes, '') || ' [İADE EDİLDİ: ' || p_refund_reason || ']'
    WHERE id = p_pos_sale_id;

    UPDATE pos_payments 
    SET payment_status = 'REFUNDED' 
    WHERE pos_sale_id = p_pos_sale_id;

    RETURN jsonb_build_object(
        'success', true,
        'pos_sale_id', p_pos_sale_id,
        'status', 'REFUNDED',
        'reverse_journal_id', v_reverse_journal_id,
        'refund_amount', v_sale.grand_total
    );
END;
$$;

-- ==============================================================================
-- 8. İNDEKSLER VE ROW LEVEL SECURITY (RLS)
-- ==============================================================================
CREATE INDEX IF NOT EXISTS idx_pos_sales_lookup 
    ON pos_sales (tenant_id, company_id, receipt_number, transaction_date);

CREATE INDEX IF NOT EXISTS idx_pos_sale_lines_sale 
    ON pos_sale_lines (pos_sale_id, item_id);

CREATE INDEX IF NOT EXISTS idx_pos_payments_sale 
    ON pos_payments (pos_sale_id, payment_method);

ALTER TABLE pos_terminals ENABLE ROW LEVEL SECURITY;
ALTER TABLE pos_terminals FORCE ROW LEVEL SECURITY;

ALTER TABLE pos_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE pos_sessions FORCE ROW LEVEL SECURITY;

ALTER TABLE pos_sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE pos_sales FORCE ROW LEVEL SECURITY;

ALTER TABLE pos_sale_lines ENABLE ROW LEVEL SECURITY;
ALTER TABLE pos_sale_lines FORCE ROW LEVEL SECURITY;

ALTER TABLE pos_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE pos_payments FORCE ROW LEVEL SECURITY;

-- Politikalar
DROP POLICY IF EXISTS "pos_terminals_access" ON pos_terminals;
CREATE POLICY "pos_terminals_access" ON pos_terminals
    FOR ALL TO authenticated
    USING (is_tenant_member(tenant_id) AND has_company_access(auth.uid(), company_id))
    WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(auth.uid(), company_id));

DROP POLICY IF EXISTS "pos_sessions_access" ON pos_sessions;
CREATE POLICY "pos_sessions_access" ON pos_sessions
    FOR ALL TO authenticated
    USING (is_tenant_member(tenant_id) AND has_company_access(auth.uid(), company_id))
    WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(auth.uid(), company_id));

DROP POLICY IF EXISTS "pos_sales_access" ON pos_sales;
CREATE POLICY "pos_sales_access" ON pos_sales
    FOR ALL TO authenticated
    USING (is_tenant_member(tenant_id) AND has_company_access(auth.uid(), company_id))
    WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(auth.uid(), company_id));

DROP POLICY IF EXISTS "pos_sale_lines_access" ON pos_sale_lines;
CREATE POLICY "pos_sale_lines_access" ON pos_sale_lines
    FOR ALL TO authenticated
    USING (is_tenant_member(tenant_id) AND has_company_access(auth.uid(), company_id))
    WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(auth.uid(), company_id));

DROP POLICY IF EXISTS "pos_payments_access" ON pos_payments;
CREATE POLICY "pos_payments_access" ON pos_payments
    FOR ALL TO authenticated
    USING (is_tenant_member(tenant_id) AND has_company_access(auth.uid(), company_id))
    WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(auth.uid(), company_id));
