-- ==============================================================================
-- NAKHL & NAHL — FAZ 27: MULTI-COMPANY + INTERCOMPANY BOUNDED CONTEXT
-- Intercompany Trade, Paired Invoices, Due From/To Journals & Cross-Company Isolation
-- ==============================================================================

-- 1. ŞİRKETLER ARASI TİCARET SÖZLEŞMELERİ VE TRANSFER FİYATLANDIRMASI
CREATE TABLE IF NOT EXISTS intercompany_agreements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    seller_company_id UUID NOT NULL REFERENCES companies(id) ON DELETE RESTRICT,
    buyer_company_id UUID NOT NULL REFERENCES companies(id) ON DELETE RESTRICT,
    agreement_code VARCHAR(100) NOT NULL,
    title VARCHAR(255) NOT NULL,
    currency VARCHAR(5) NOT NULL DEFAULT 'SAR',
    
    -- Transfer Fiyatlandırması (Transfer Pricing)
    transfer_pricing_method VARCHAR(50) NOT NULL DEFAULT 'ARM_LENGTH'
        CHECK (transfer_pricing_method IN ('ARM_LENGTH', 'COST_PLUS', 'RESALE_MINUS', 'PROFIT_SPLIT', 'TNMM')),
    markup_percentage NUMERIC(5,2) NOT NULL DEFAULT 5.00, -- Örn: Maliyet + %5 Kar Marjı
    arm_length_benchmark_price NUMERIC(18,4),
    tax_treaty_jurisdiction VARCHAR(50),
    documentation_reference VARCHAR(255),
    
    effective_from DATE NOT NULL DEFAULT CURRENT_DATE,
    effective_to DATE,
    status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'SUSPENDED', 'EXPIRED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_intercompany_pair UNIQUE (seller_company_id, buyer_company_id, agreement_code)
);

-- 2. ŞİRKETLER ARASI TİCARİ İŞLEMLER (Intercompany Transactions)
CREATE TABLE IF NOT EXISTS intercompany_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    agreement_id UUID REFERENCES intercompany_agreements(id) ON DELETE SET NULL,
    seller_company_id UUID NOT NULL REFERENCES companies(id) ON DELETE RESTRICT,
    buyer_company_id UUID NOT NULL REFERENCES companies(id) ON DELETE RESTRICT,
    
    transaction_number VARCHAR(100) NOT NULL,
    transaction_date DATE NOT NULL DEFAULT CURRENT_DATE,
    currency VARCHAR(5) NOT NULL DEFAULT 'SAR',
    
    subtotal NUMERIC(18,4) NOT NULL DEFAULT 0.0000,
    tax_rate NUMERIC(5,2) NOT NULL DEFAULT 15.00,
    tax_amount NUMERIC(18,4) NOT NULL DEFAULT 0.0000,
    grand_total NUMERIC(18,4) NOT NULL DEFAULT 0.0000,
    
    -- Transfer Fiyatlandırması Detayları
    transfer_pricing_method VARCHAR(50) NOT NULL DEFAULT 'ARM_LENGTH'
        CHECK (transfer_pricing_method IN ('ARM_LENGTH', 'COST_PLUS', 'RESALE_MINUS', 'PROFIT_SPLIT', 'TNMM')),
    markup_percentage NUMERIC(5,2) DEFAULT 5.00,
    documentation_reference VARCHAR(255),
    
    -- Eşleştirilmiş Çift Fatura (Paired Invoices: Sale & Purchase)
    seller_invoice_id UUID REFERENCES invoices(id) ON DELETE SET NULL,
    buyer_invoice_id UUID REFERENCES invoices(id) ON DELETE SET NULL,
    
    -- Eşleştirilmiş Çift Yevmiye (Due From & Due To Journals)
    seller_journal_id UUID REFERENCES journal_entries(id) ON DELETE SET NULL,
    buyer_journal_id UUID REFERENCES journal_entries(id) ON DELETE SET NULL,
    
    status VARCHAR(50) NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'APPROVED', 'POSTED', 'CANCELLED')),
    notes TEXT,
    created_by UUID REFERENCES public.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_intercompany_tx_num UNIQUE (tenant_id, transaction_number)
);

-- 3. ŞİRKETLER ARASI İŞLEM KALEMLERİ
CREATE TABLE IF NOT EXISTS intercompany_transaction_lines (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    intercompany_transaction_id UUID NOT NULL REFERENCES intercompany_transactions(id) ON DELETE CASCADE,
    item_id UUID NOT NULL REFERENCES items(id) ON DELETE RESTRICT,
    lot_id UUID REFERENCES item_lots(id) ON DELETE SET NULL,
    line_number INT NOT NULL DEFAULT 1,
    quantity NUMERIC(15,3) NOT NULL,
    uom VARCHAR(20) NOT NULL DEFAULT 'Kg',
    cost_price NUMERIC(18,4) NOT NULL,
    transfer_price NUMERIC(18,4) NOT NULL,
    markup_amount NUMERIC(18,4) NOT NULL DEFAULT 0.0000,
    subtotal NUMERIC(18,4) NOT NULL,
    tax_rate NUMERIC(5,2) NOT NULL DEFAULT 15.00,
    tax_amount NUMERIC(18,4) NOT NULL DEFAULT 0.0000,
    total_amount NUMERIC(18,4) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. ŞİRKETLER ARASI MAL TRANSFERLERİ (Intercompany Stock Transfers)
-- TRANSFER -> OUT (Satıcı Deposu) -> IN (Alıcı Deposu)
CREATE TABLE IF NOT EXISTS intercompany_stock_transfers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    transfer_number VARCHAR(100) NOT NULL,
    from_company_id UUID NOT NULL REFERENCES companies(id) ON DELETE RESTRICT,
    from_warehouse_id UUID NOT NULL REFERENCES warehouses(id) ON DELETE RESTRICT,
    to_company_id UUID NOT NULL REFERENCES companies(id) ON DELETE RESTRICT,
    to_warehouse_id UUID NOT NULL REFERENCES warehouses(id) ON DELETE RESTRICT,
    item_id UUID NOT NULL REFERENCES items(id) ON DELETE RESTRICT,
    lot_id UUID REFERENCES item_lots(id) ON DELETE SET NULL,
    quantity NUMERIC(15,3) NOT NULL,
    uom VARCHAR(20) NOT NULL DEFAULT 'Kg',
    transfer_price NUMERIC(18,4) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'IN_TRANSIT' CHECK (status IN ('IN_TRANSIT', 'RECEIVED', 'CANCELLED')),
    shipped_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    received_at TIMESTAMPTZ,
    intercompany_transaction_id UUID REFERENCES intercompany_transactions(id) ON DELETE SET NULL,
    created_by UUID REFERENCES public.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_intercompany_transfer_num UNIQUE (tenant_id, transfer_number)
);

-- ==============================================================================
-- 5. ATOMİK ŞİRKETLER ARASI FATURALAŞMA VE MUHASEBE RPC'Sİ
-- Company B Satış Faturası <---> Company A Satın Alma Faturası
-- Company B Due From (Alacak) <---> Company A Due To (Borç)
-- ==============================================================================
CREATE OR REPLACE FUNCTION post_intercompany_sale_purchase_transaction(
    p_intercompany_tx_id UUID,
    p_from_warehouse_id UUID,
    p_to_warehouse_id UUID,
    p_user_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_tx RECORD;
    v_seller_inv_id UUID;
    v_buyer_inv_id UUID;
    v_seller_jrn_id UUID;
    v_buyer_jrn_id UUID;
    
    -- Cari Hesaplar
    v_seller_party_id UUID; -- Alıcı şirketin satıcı sistemindeki müşteri kaydı
    v_buyer_party_id UUID;  -- Satıcı şirketin alıcı sistemindeki tedarikçi kaydı
    
    -- Muhasebe Hesapları (Due From / Due To)
    v_acc_due_from_id UUID; -- 133 Bağlı Ortaklıklardan Alacaklar
    v_acc_sales_id UUID;    -- 600 Grup Satışları
    v_acc_vat_out_id UUID;  -- 391 Hesaplanan KDV
    
    v_acc_inventory_id UUID;-- 153 Ticari Mallar
    v_acc_vat_in_id UUID;   -- 191 İndirilecek KDV
    v_acc_due_to_id UUID;   -- 333 Bağlı Ortaklıklara Borçlar
    
    v_entry_num_seller VARCHAR(100);
    v_entry_num_buyer VARCHAR(100);
    v_line RECORD;
BEGIN
    SELECT * INTO v_tx FROM intercompany_transactions WHERE id = p_intercompany_tx_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Şirketler arası işlem bulunamadı: %', p_intercompany_tx_id;
    END IF;

    IF v_tx.status = 'POSTED' THEN
        RAISE EXCEPTION 'Bu işlem zaten muhasebeleştirilmiş ve kesinleştirilmiştir!';
    END IF;

    -- 1. ADIM: CARİ KARTLARI ÇÖZ / OLUŞTUR
    -- Satıcı şirket için Alıcı şirketi müşteri olarak bağla
    SELECT id INTO v_seller_party_id FROM parties 
    WHERE tenant_id = v_tx.tenant_id AND party_type IN ('CUSTOMER', 'BOTH') AND country_code = 'SA' LIMIT 1;

    -- Alıcı şirket için Satıcı şirketi tedarikçi olarak bağla
    SELECT id INTO v_buyer_party_id FROM parties 
    WHERE tenant_id = v_tx.tenant_id AND party_type IN ('SUPPLIER', 'BOTH') AND country_code = 'SA' LIMIT 1;

    -- 2. ADIM: EŞLEŞMİŞ SATIŞ VE SATIN ALMA FATURALARI (PAIRED INVOICES)
    -- Satıcı Şirket (Company B) Satış Faturası
    INSERT INTO invoices (
        tenant_id, company_id, invoice_type, invoice_number,
        party_id, warehouse_id, invoice_date, currency,
        subtotal, tax_rate, tax_amount, grand_total, status, created_by
    ) VALUES (
        v_tx.tenant_id, v_tx.seller_company_id, 'SALES', 'INV-IC-SALE-' || v_tx.transaction_number,
        v_seller_party_id, p_from_warehouse_id, v_tx.transaction_date, v_tx.currency,
        v_tx.subtotal, v_tx.tax_rate, v_tx.tax_amount, v_tx.grand_total, 'POSTED', p_user_id
    ) RETURNING id INTO v_seller_inv_id;

    -- Alıcı Şirket (Company A) Satın Alma Faturası
    INSERT INTO invoices (
        tenant_id, company_id, invoice_type, invoice_number,
        party_id, warehouse_id, invoice_date, currency,
        subtotal, tax_rate, tax_amount, grand_total, status, created_by
    ) VALUES (
        v_tx.tenant_id, v_tx.buyer_company_id, 'PURCHASE', 'PINV-IC-PURCH-' || v_tx.transaction_number,
        v_buyer_party_id, p_to_warehouse_id, v_tx.transaction_date, v_tx.currency,
        v_tx.subtotal, v_tx.tax_rate, v_tx.tax_amount, v_tx.grand_total, 'POSTED', p_user_id
    ) RETURNING id INTO v_buyer_inv_id;

    -- 3. ADIM: HESAP PLANINI ÇÖZ VE HAZIRLA
    -- Satıcı Şirket Hesapları
    SELECT id INTO v_acc_due_from_id FROM chart_of_accounts 
    WHERE company_id = v_tx.seller_company_id AND account_code = '133' LIMIT 1;
    IF v_acc_due_from_id IS NULL THEN
        INSERT INTO chart_of_accounts (tenant_id, company_id, account_code, account_name, account_type, balance_type, currency_code, posting_allowed)
        VALUES (v_tx.tenant_id, v_tx.seller_company_id, '133', 'Bağlı Ortaklıklardan Alacaklar (Due From)', 'ASSET', 'DEBIT', v_tx.currency, TRUE)
        RETURNING id INTO v_acc_due_from_id;
    END IF;

    SELECT id INTO v_acc_sales_id FROM chart_of_accounts 
    WHERE company_id = v_tx.seller_company_id AND account_code = '600' LIMIT 1;
    IF v_acc_sales_id IS NULL THEN
        INSERT INTO chart_of_accounts (tenant_id, company_id, account_code, account_name, account_type, balance_type, currency_code, posting_allowed)
        VALUES (v_tx.tenant_id, v_tx.seller_company_id, '600', 'Şirketler Arası Satış Gelirleri', 'REVENUE', 'CREDIT', v_tx.currency, TRUE)
        RETURNING id INTO v_acc_sales_id;
    END IF;

    SELECT id INTO v_acc_vat_out_id FROM chart_of_accounts 
    WHERE company_id = v_tx.seller_company_id AND account_code = '391' LIMIT 1;
    IF v_acc_vat_out_id IS NULL THEN
        INSERT INTO chart_of_accounts (tenant_id, company_id, account_code, account_name, account_type, balance_type, currency_code, posting_allowed)
        VALUES (v_tx.tenant_id, v_tx.seller_company_id, '391', 'Hesaplanan KDV', 'LIABILITY', 'CREDIT', v_tx.currency, TRUE)
        RETURNING id INTO v_acc_vat_out_id;
    END IF;

    -- Alıcı Şirket Hesapları
    SELECT id INTO v_acc_inventory_id FROM chart_of_accounts 
    WHERE company_id = v_tx.buyer_company_id AND account_code = '153' LIMIT 1;
    IF v_acc_inventory_id IS NULL THEN
        INSERT INTO chart_of_accounts (tenant_id, company_id, account_code, account_name, account_type, balance_type, currency_code, posting_allowed)
        VALUES (v_tx.tenant_id, v_tx.buyer_company_id, '153', 'Ticari Mallar (Envanter)', 'ASSET', 'DEBIT', v_tx.currency, TRUE)
        RETURNING id INTO v_acc_inventory_id;
    END IF;

    SELECT id INTO v_acc_vat_in_id FROM chart_of_accounts 
    WHERE company_id = v_tx.buyer_company_id AND account_code = '191' LIMIT 1;
    IF v_acc_vat_in_id IS NULL THEN
        INSERT INTO chart_of_accounts (tenant_id, company_id, account_code, account_name, account_type, balance_type, currency_code, posting_allowed)
        VALUES (v_tx.tenant_id, v_tx.buyer_company_id, '191', 'İndirilecek KDV', 'ASSET', 'DEBIT', v_tx.currency, TRUE)
        RETURNING id INTO v_acc_vat_in_id;
    END IF;

    SELECT id INTO v_acc_due_to_id FROM chart_of_accounts 
    WHERE company_id = v_tx.buyer_company_id AND account_code = '333' LIMIT 1;
    IF v_acc_due_to_id IS NULL THEN
        INSERT INTO chart_of_accounts (tenant_id, company_id, account_code, account_name, account_type, balance_type, currency_code, posting_allowed)
        VALUES (v_tx.tenant_id, v_tx.buyer_company_id, '333', 'Bağlı Ortaklıklara Borçlar (Due To)', 'LIABILITY', 'CREDIT', v_tx.currency, TRUE)
        RETURNING id INTO v_acc_due_to_id;
    END IF;

    -- 4. ADIM: SATICI YEVMİYE KAYDI (SELLER DUE FROM JOURNAL)
    INSERT INTO journal_entries (
        tenant_id, company_id, entry_date,
        total_debit, total_credit,
        status, entry_type, document_type, document_reference,
        description
    ) VALUES (
        v_tx.tenant_id, v_tx.seller_company_id, v_tx.transaction_date,
        v_tx.grand_total, v_tx.grand_total,
        'DRAFT', 'INTERCOMPANY_SALE', 'INVOICE', 'INV-IC-SALE-' || v_tx.transaction_number,
        'Şirketler Arası Satış: ' || v_tx.transaction_number
    ) RETURNING id INTO v_seller_jrn_id;

    -- Borç: 133 Due From
    INSERT INTO journal_lines (tenant_id, company_id, journal_entry_id, line_number, account_id, debit_amount, credit_amount, description, transaction_currency, exchange_rate, base_debit_amount, base_credit_amount)
    VALUES (v_tx.tenant_id, v_tx.seller_company_id, v_seller_jrn_id, 1, v_acc_due_from_id, v_tx.grand_total, 0.0000, 'Due From Alıcı Şirket', v_tx.currency, 1.0, v_tx.grand_total, 0.0000);

    -- Alacak: 600 Satış Hasılatı
    INSERT INTO journal_lines (tenant_id, company_id, journal_entry_id, line_number, account_id, debit_amount, credit_amount, description, transaction_currency, exchange_rate, base_debit_amount, base_credit_amount)
    VALUES (v_tx.tenant_id, v_tx.seller_company_id, v_seller_jrn_id, 2, v_acc_sales_id, 0.0000, v_tx.subtotal, 'Şirketler Arası Satış Hasılatı', v_tx.currency, 1.0, 0.0000, v_tx.subtotal);

    -- Alacak: 391 KDV
    IF v_tx.tax_amount > 0 THEN
        INSERT INTO journal_lines (tenant_id, company_id, journal_entry_id, line_number, account_id, debit_amount, credit_amount, description, transaction_currency, exchange_rate, base_debit_amount, base_credit_amount)
        VALUES (v_tx.tenant_id, v_tx.seller_company_id, v_seller_jrn_id, 3, v_acc_vat_out_id, 0.0000, v_tx.tax_amount, 'Satış KDV', v_tx.currency, 1.0, 0.0000, v_tx.tax_amount);
    END IF;

    UPDATE journal_entries SET status = 'POSTED', posted_at = NOW(), posted_by = p_user_id WHERE id = v_seller_jrn_id;

    -- 5. ADIM: ALICI YEVMİYE KAYDI (BUYER DUE TO JOURNAL)
    INSERT INTO journal_entries (
        tenant_id, company_id, entry_date,
        total_debit, total_credit,
        status, entry_type, document_type, document_reference,
        description
    ) VALUES (
        v_tx.tenant_id, v_tx.buyer_company_id, v_tx.transaction_date,
        v_tx.grand_total, v_tx.grand_total,
        'DRAFT', 'INTERCOMPANY_PURCHASE', 'INVOICE', 'PINV-IC-PURCH-' || v_tx.transaction_number,
        'Şirketler Arası Satın Alma: ' || v_tx.transaction_number
    ) RETURNING id INTO v_buyer_jrn_id;

    -- Borç: 153 Ticari Mallar
    INSERT INTO journal_lines (tenant_id, company_id, journal_entry_id, line_number, account_id, debit_amount, credit_amount, description, transaction_currency, exchange_rate, base_debit_amount, base_credit_amount)
    VALUES (v_tx.tenant_id, v_tx.buyer_company_id, v_buyer_jrn_id, 1, v_acc_inventory_id, v_tx.subtotal, 0.0000, 'Şirketler Arası Envanter Alımı', v_tx.currency, 1.0, v_tx.subtotal, 0.0000);

    -- Borç: 191 İndirilecek KDV
    IF v_tx.tax_amount > 0 THEN
        INSERT INTO journal_lines (tenant_id, company_id, journal_entry_id, line_number, account_id, debit_amount, credit_amount, description, transaction_currency, exchange_rate, base_debit_amount, base_credit_amount)
        VALUES (v_tx.tenant_id, v_tx.buyer_company_id, v_buyer_jrn_id, 2, v_acc_vat_in_id, v_tx.tax_amount, 0.0000, 'Alış KDV', v_tx.currency, 1.0, v_tx.tax_amount, 0.0000);
    END IF;

    -- Alacak: 333 Due To
    INSERT INTO journal_lines (tenant_id, company_id, journal_entry_id, line_number, account_id, debit_amount, credit_amount, description, transaction_currency, exchange_rate, base_debit_amount, base_credit_amount)
    VALUES (v_tx.tenant_id, v_tx.buyer_company_id, v_buyer_jrn_id, 3, v_acc_due_to_id, 0.0000, v_tx.grand_total, 'Due To Satıcı Şirket', v_tx.currency, 1.0, 0.0000, v_tx.grand_total);

    UPDATE journal_entries SET status = 'POSTED', posted_at = NOW(), posted_by = p_user_id WHERE id = v_buyer_jrn_id;

    -- 6. ADIM: İŞLEM VE FATURA KAYITLARINI BAĞLA
    UPDATE intercompany_transactions SET
        seller_invoice_id = v_seller_inv_id,
        buyer_invoice_id = v_buyer_inv_id,
        seller_journal_id = v_seller_jrn_id,
        buyer_journal_id = v_buyer_jrn_id,
        status = 'POSTED',
        updated_at = NOW()
    WHERE id = p_intercompany_tx_id;

    RETURN jsonb_build_object(
        'success', true,
        'intercompany_tx_id', p_intercompany_tx_id,
        'seller_invoice_id', v_seller_inv_id,
        'buyer_invoice_id', v_buyer_inv_id,
        'seller_journal_id', v_seller_jrn_id,
        'buyer_journal_id', v_buyer_jrn_id,
        'due_from_amount', v_tx.grand_total,
        'due_to_amount', v_tx.grand_total,
        'is_reconciled', true
    );
END;
$$;

-- ==============================================================================
-- 6. ATOMİK ŞİRKETLER ARASI STOK TRANSFERİ RPC'Sİ
-- TRANSFER -> OUT (from_company) -> IN (to_company)
-- ==============================================================================
CREATE OR REPLACE FUNCTION execute_intercompany_stock_transfer(
    p_tenant_id UUID,
    p_from_company_id UUID,
    p_from_warehouse_id UUID,
    p_to_company_id UUID,
    p_to_warehouse_id UUID,
    p_item_id UUID,
    p_lot_id UUID,
    p_quantity NUMERIC,
    p_transfer_price NUMERIC,
    p_user_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_transfer_id UUID;
    v_transfer_num VARCHAR(100);
BEGIN
    v_transfer_num := 'TRF-IC-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || LPAD(FLOOR(RANDOM() * 100000)::TEXT, 5, '0');

    -- 1. Transfer Master Kaydı
    INSERT INTO intercompany_stock_transfers (
        tenant_id, transfer_number, from_company_id, from_warehouse_id,
        to_company_id, to_warehouse_id, item_id, lot_id,
        quantity, transfer_price, status, shipped_at, received_at, created_by
    ) VALUES (
        p_tenant_id, v_transfer_num, p_from_company_id, p_from_warehouse_id,
        p_to_company_id, p_to_warehouse_id, p_item_id, p_lot_id,
        p_quantity, p_transfer_price, 'RECEIVED', NOW(), NOW(), p_user_id
    ) RETURNING id INTO v_transfer_id;

    -- 2. Çıkış Hareketi (OUT - from_company)
    INSERT INTO stock_ledger_entries (
        tenant_id, company_id, warehouse_id, item_id, lot_id,
        movement_type, quantity, unit, unit_cost, total_cost,
        direction, document_type, document_reference, created_by
    ) VALUES (
        p_tenant_id, p_from_company_id, p_from_warehouse_id, p_item_id, p_lot_id,
        'TRANSFER_OUT', -p_quantity, 'Kg', p_transfer_price, (-p_quantity * p_transfer_price),
        'OUT', 'INTERCOMPANY_TRANSFER', v_transfer_num, p_user_id
    );

    -- 3. Giriş Hareketi (IN - to_company)
    INSERT INTO stock_ledger_entries (
        tenant_id, company_id, warehouse_id, item_id, lot_id,
        movement_type, quantity, unit, unit_cost, total_cost,
        direction, document_type, document_reference, created_by
    ) VALUES (
        p_tenant_id, p_to_company_id, p_to_warehouse_id, p_item_id, p_lot_id,
        'TRANSFER_IN', p_quantity, 'Kg', p_transfer_price, (p_quantity * p_transfer_price),
        'IN', 'INTERCOMPANY_TRANSFER', v_transfer_num, p_user_id
    );

    RETURN jsonb_build_object(
        'success', true,
        'transfer_id', v_transfer_id,
        'transfer_number', v_transfer_num,
        'quantity', p_quantity,
        'status', 'RECEIVED'
    );
END;
$$;

-- ==============================================================================
-- 7. İNDEKSLER VE ROW LEVEL SECURITY (RLS)
-- Şirket İzolasyonu: Company B kullanıcısı Company A verisini yetkisi yoksa göremez!
-- ==============================================================================
CREATE INDEX IF NOT EXISTS idx_ic_tx_companies 
    ON intercompany_transactions (tenant_id, seller_company_id, buyer_company_id, status);

CREATE INDEX IF NOT EXISTS idx_ic_stock_transfer_parties 
    ON intercompany_stock_transfers (tenant_id, from_company_id, to_company_id, status);

ALTER TABLE intercompany_agreements ENABLE ROW LEVEL SECURITY;
ALTER TABLE intercompany_agreements FORCE ROW LEVEL SECURITY;

ALTER TABLE intercompany_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE intercompany_transactions FORCE ROW LEVEL SECURITY;

ALTER TABLE intercompany_transaction_lines ENABLE ROW LEVEL SECURITY;
ALTER TABLE intercompany_transaction_lines FORCE ROW LEVEL SECURITY;

ALTER TABLE intercompany_stock_transfers ENABLE ROW LEVEL SECURITY;
ALTER TABLE intercompany_stock_transfers FORCE ROW LEVEL SECURITY;

-- Politikalar: intercompany_agreements (Her iki şirketten birine erişimi olan görebilir)
DROP POLICY IF EXISTS "ic_agreements_access" ON intercompany_agreements;
CREATE POLICY "ic_agreements_access" ON intercompany_agreements
    FOR ALL TO authenticated
    USING (
        is_tenant_member(tenant_id) AND 
        (has_company_access(auth.uid(), seller_company_id) OR has_company_access(auth.uid(), buyer_company_id))
    )
    WITH CHECK (
        is_tenant_member(tenant_id) AND 
        (has_company_access(auth.uid(), seller_company_id) OR has_company_access(auth.uid(), buyer_company_id))
    );

-- Politikalar: intercompany_transactions
DROP POLICY IF EXISTS "ic_transactions_access" ON intercompany_transactions;
CREATE POLICY "ic_transactions_access" ON intercompany_transactions
    FOR ALL TO authenticated
    USING (
        is_tenant_member(tenant_id) AND 
        (has_company_access(auth.uid(), seller_company_id) OR has_company_access(auth.uid(), buyer_company_id))
    )
    WITH CHECK (
        is_tenant_member(tenant_id) AND 
        (has_company_access(auth.uid(), seller_company_id) OR has_company_access(auth.uid(), buyer_company_id))
    );

-- Politikalar: intercompany_transaction_lines
DROP POLICY IF EXISTS "ic_transaction_lines_access" ON intercompany_transaction_lines;
CREATE POLICY "ic_transaction_lines_access" ON intercompany_transaction_lines
    FOR ALL TO authenticated
    USING (
        is_tenant_member(tenant_id) AND EXISTS (
            SELECT 1 FROM intercompany_transactions it
            WHERE it.id = intercompany_transaction_lines.intercompany_transaction_id
              AND (has_company_access(auth.uid(), it.seller_company_id) OR has_company_access(auth.uid(), it.buyer_company_id))
        )
    )
    WITH CHECK (
        is_tenant_member(tenant_id) AND EXISTS (
            SELECT 1 FROM intercompany_transactions it
            WHERE it.id = intercompany_transaction_lines.intercompany_transaction_id
              AND (has_company_access(auth.uid(), it.seller_company_id) OR has_company_access(auth.uid(), it.buyer_company_id))
        )
    );

-- Politikalar: intercompany_stock_transfers
DROP POLICY IF EXISTS "ic_transfers_access" ON intercompany_stock_transfers;
CREATE POLICY "ic_transfers_access" ON intercompany_stock_transfers
    FOR ALL TO authenticated
    USING (
        is_tenant_member(tenant_id) AND 
        (has_company_access(auth.uid(), from_company_id) OR has_company_access(auth.uid(), to_company_id))
    )
    WITH CHECK (
        is_tenant_member(tenant_id) AND 
        (has_company_access(auth.uid(), from_company_id) OR has_company_access(auth.uid(), to_company_id))
    );
