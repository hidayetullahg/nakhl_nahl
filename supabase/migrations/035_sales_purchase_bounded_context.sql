-- ==============================================================================
-- NAKHL & NAHL — MIGRATION 035: SALES + PURCHASE BOUNDED CONTEXT (FAZ 15)
-- Purpose:
-- 1. purchase_orders & purchase_order_lines (Satın Alma Siparişleri)
-- 2. sales_orders & sales_order_lines (Satış Siparişleri)
-- 3. invoices & invoice_lines (Fatura Master ve Satırları - Satış ve Alış)
-- 4. process_purchase_intake_atomic (Satın alma kabul, lot, stok ve yevmiye tek transaction)
-- 5. create_sales_invoice_atomic (Satış faturası, stok çıkışı ve yevmiye tek transaction)
-- 6. RLS ve İndeksler
-- ==============================================================================

-- 1. SATIN ALMA SİPARİŞLERİ (PURCHASE ORDERS)
CREATE TABLE IF NOT EXISTS purchase_orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    supplier_id UUID REFERENCES parties(id) ON DELETE RESTRICT,
    order_number VARCHAR(100) NOT NULL,
    order_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expected_delivery_date DATE,
    warehouse_id UUID REFERENCES warehouses(id) ON DELETE RESTRICT,
    currency VARCHAR(5) NOT NULL DEFAULT 'SAR',
    exchange_rate NUMERIC(12,6) NOT NULL DEFAULT 1.000000,
    subtotal NUMERIC(18,4) NOT NULL DEFAULT 0.0000,
    tax_amount NUMERIC(18,4) NOT NULL DEFAULT 0.0000,
    grand_total NUMERIC(18,4) NOT NULL DEFAULT 0.0000,
    payment_terms_days INT NOT NULL DEFAULT 30,
    status VARCHAR(50) NOT NULL DEFAULT 'DRAFT', -- DRAFT, APPROVED, PARTIALLY_RECEIVED, COMPLETED, CANCELLED
    notes TEXT,
    created_by UUID REFERENCES public.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_po_company_number UNIQUE (company_id, order_number)
);

CREATE TABLE IF NOT EXISTS purchase_order_lines (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    purchase_order_id UUID NOT NULL REFERENCES purchase_orders(id) ON DELETE CASCADE,
    item_id UUID NOT NULL REFERENCES items(id) ON DELETE RESTRICT,
    quantity NUMERIC(15,3) NOT NULL,
    received_quantity NUMERIC(15,3) NOT NULL DEFAULT 0.000,
    uom VARCHAR(20) NOT NULL DEFAULT 'Kg',
    unit_price NUMERIC(18,4) NOT NULL DEFAULT 0.0000,
    tax_rate NUMERIC(5,2) NOT NULL DEFAULT 15.00,
    tax_amount NUMERIC(18,4) NOT NULL DEFAULT 0.0000,
    total_price NUMERIC(18,4) NOT NULL DEFAULT 0.0000,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- 2. SATIŞ SİPARİŞLERİ (SALES ORDERS)
CREATE TABLE IF NOT EXISTS sales_orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    customer_id UUID REFERENCES parties(id) ON DELETE RESTRICT,
    order_number VARCHAR(100) NOT NULL,
    order_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expected_delivery_date DATE,
    warehouse_id UUID REFERENCES warehouses(id) ON DELETE RESTRICT,
    currency VARCHAR(5) NOT NULL DEFAULT 'SAR',
    exchange_rate NUMERIC(12,6) NOT NULL DEFAULT 1.000000,
    subtotal NUMERIC(18,4) NOT NULL DEFAULT 0.0000,
    tax_amount NUMERIC(18,4) NOT NULL DEFAULT 0.0000,
    grand_total NUMERIC(18,4) NOT NULL DEFAULT 0.0000,
    payment_terms_days INT NOT NULL DEFAULT 30,
    status VARCHAR(50) NOT NULL DEFAULT 'DRAFT', -- DRAFT, CONFIRMED, PROCESSING, SHIPPED, DELIVERED, CANCELLED
    notes TEXT,
    created_by UUID REFERENCES public.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_so_company_number UNIQUE (company_id, order_number)
);

CREATE TABLE IF NOT EXISTS sales_order_lines (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    sales_order_id UUID NOT NULL REFERENCES sales_orders(id) ON DELETE CASCADE,
    item_id UUID NOT NULL REFERENCES items(id) ON DELETE RESTRICT,
    quantity NUMERIC(15,3) NOT NULL,
    delivered_quantity NUMERIC(15,3) NOT NULL DEFAULT 0.000,
    uom VARCHAR(20) NOT NULL DEFAULT 'Kg',
    unit_price NUMERIC(18,4) NOT NULL DEFAULT 0.0000,
    tax_rate NUMERIC(5,2) NOT NULL DEFAULT 15.00,
    tax_amount NUMERIC(18,4) NOT NULL DEFAULT 0.0000,
    total_price NUMERIC(18,4) NOT NULL DEFAULT 0.0000,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- 3. FATURALAR (INVOICES & INVOICE LINES)
CREATE TABLE IF NOT EXISTS invoices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    invoice_type VARCHAR(20) NOT NULL DEFAULT 'SALES', -- SALES, PURCHASE
    invoice_number VARCHAR(100) NOT NULL,
    invoice_date DATE NOT NULL DEFAULT CURRENT_DATE,
    due_date DATE,
    party_id UUID REFERENCES parties(id) ON DELETE RESTRICT,
    warehouse_id UUID REFERENCES warehouses(id) ON DELETE RESTRICT,
    sales_order_id UUID REFERENCES sales_orders(id) ON DELETE SET NULL,
    purchase_order_id UUID REFERENCES purchase_orders(id) ON DELETE SET NULL,
    journal_entry_id UUID REFERENCES journal_entries(id) ON DELETE SET NULL,
    currency VARCHAR(5) NOT NULL DEFAULT 'SAR',
    exchange_rate NUMERIC(12,6) NOT NULL DEFAULT 1.000000,
    subtotal NUMERIC(18,4) NOT NULL DEFAULT 0.0000,
    tax_rate NUMERIC(5,2) NOT NULL DEFAULT 15.00,
    tax_amount NUMERIC(18,4) NOT NULL DEFAULT 0.0000,
    grand_total NUMERIC(18,4) NOT NULL DEFAULT 0.0000,
    payment_terms_days INT NOT NULL DEFAULT 30,
    status VARCHAR(50) NOT NULL DEFAULT 'DRAFT', -- DRAFT, POSTED, CANCELLED
    notes TEXT,
    created_by UUID REFERENCES public.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_invoice_company_number UNIQUE (company_id, invoice_type, invoice_number)
);

CREATE TABLE IF NOT EXISTS invoice_lines (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    item_id UUID NOT NULL REFERENCES items(id) ON DELETE RESTRICT,
    lot_id UUID REFERENCES item_lots(id) ON DELETE SET NULL,
    line_number INT NOT NULL DEFAULT 1,
    description VARCHAR(255),
    quantity NUMERIC(15,3) NOT NULL,
    uom VARCHAR(20) NOT NULL DEFAULT 'Kg',
    unit_price NUMERIC(18,4) NOT NULL DEFAULT 0.0000,
    tax_rate NUMERIC(5,2) NOT NULL DEFAULT 15.00,
    tax_amount NUMERIC(18,4) NOT NULL DEFAULT 0.0000,
    subtotal NUMERIC(18,4) NOT NULL DEFAULT 0.0000,
    total_price NUMERIC(18,4) NOT NULL DEFAULT 0.0000,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- 4. ATOMİK SATIN ALMA KABUL RPC'Sİ (PURCHASE FLOW)
-- SUPPLIER -> PURCHASE ORDER -> RECEIPT -> LOT -> STOCK -> JOURNAL
CREATE OR REPLACE FUNCTION process_purchase_intake_atomic(
    p_tenant_id UUID,
    p_company_id UUID,
    p_supplier_id UUID,
    p_po_number VARCHAR(100),
    p_invoice_number VARCHAR(100),
    p_warehouse_id UUID,
    p_item_id UUID,
    p_lot_number VARCHAR(100),
    p_quantity NUMERIC(15,3),
    p_uom VARCHAR(20),
    p_unit_price NUMERIC(18,4),
    p_currency VARCHAR(5) DEFAULT 'SAR',
    p_tax_rate NUMERIC(5,2) DEFAULT 15.00,
    p_farm_name VARCHAR(150) DEFAULT NULL,
    p_harvest_date DATE DEFAULT CURRENT_DATE,
    p_harvest_batch_number VARCHAR(100) DEFAULT NULL,
    p_payment_terms_days INT DEFAULT 30,
    p_user_id UUID DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_user_id UUID;
    v_po_id UUID;
    v_invoice_id UUID;
    v_lot_id UUID;
    v_journal_id UUID;
    v_subtotal NUMERIC(18,4);
    v_tax_amount NUMERIC(18,4);
    v_grand_total NUMERIC(18,4);
    v_acc_153_id UUID; -- Ticari Mallar / Stok Hesabı
    v_acc_191_id UUID; -- İndirilecek KDV
    v_acc_320_id UUID; -- Satıcılar / Tedarikçi Hesabı
BEGIN
    -- A. Güvenlik ve Yetki Kontrolü
    IF NOT is_tenant_member(p_tenant_id) THEN
        RAISE EXCEPTION 'GÜVENLİK İHLALİ: Aktif kullanıcı bu tenant''a üye değildir!';
    END IF;

    IF NOT has_company_access(p_company_id) THEN
        RAISE EXCEPTION 'GÜVENLİK İHLALİ: Aktif kullanıcının bu şirkete işlem yetkisi yoktur!';
    END IF;

    v_user_id := COALESCE(p_user_id, get_current_user_id());
    v_subtotal := ROUND(p_quantity * p_unit_price, 4);
    v_tax_amount := ROUND(v_subtotal * (p_tax_rate / 100.0), 4);
    v_grand_total := v_subtotal + v_tax_amount;

    -- B. Mükerrer Fatura Kontrolü
    IF EXISTS (
        SELECT 1 FROM invoices 
        WHERE company_id = p_company_id 
          AND invoice_type = 'PURCHASE' 
          AND invoice_number = p_invoice_number
    ) THEN
        RAISE EXCEPTION 'MÜKERRER FATURA: "%" numaralı alış faturası bu şirkette zaten kayıtlıdır!', p_invoice_number;
    END IF;

    -- C. Satın Alma Siparişi (Purchase Order) Oluşturma ve Onaylama
    INSERT INTO purchase_orders (
        tenant_id, company_id, supplier_id, order_number, order_date,
        warehouse_id, currency, subtotal, tax_amount, grand_total,
        payment_terms_days, status, created_by
    ) VALUES (
        p_tenant_id, p_company_id, p_supplier_id, p_po_number, CURRENT_DATE,
        p_warehouse_id, p_currency, v_subtotal, v_tax_amount, v_grand_total,
        p_payment_terms_days, 'COMPLETED', v_user_id
    ) RETURNING id INTO v_po_id;

    INSERT INTO purchase_order_lines (
        tenant_id, company_id, purchase_order_id, item_id,
        quantity, received_quantity, uom, unit_price, tax_rate, tax_amount, total_price
    ) VALUES (
        p_tenant_id, p_company_id, v_po_id, p_item_id,
        p_quantity, p_quantity, p_uom, p_unit_price, p_tax_rate, v_tax_amount, v_grand_total
    );

    -- D. Hurma Parti / Lot Kaydı (Item Lot Traceability)
    INSERT INTO item_lots (
        tenant_id, company_id, item_id, lot_number,
        farm_name, harvest_date, harvest_batch_number, supplier_party_id,
        packaging_type, temperature_control_required, target_storage_temp_celsius,
        country_of_origin, production_date, expiration_date,
        halal_certified, quality_status
    ) VALUES (
        p_tenant_id, p_company_id, p_item_id, p_lot_number,
        p_farm_name, p_harvest_date, p_harvest_batch_number, p_supplier_id,
        'BOX', TRUE, -18.00,
        'SA', CURRENT_DATE, CURRENT_DATE + INTERVAL '2 years',
        TRUE, 'APPROVED'
    )
    ON CONFLICT (company_id, item_id, lot_number) 
    DO UPDATE SET updated_at = NOW()
    RETURNING id INTO v_lot_id;

    -- E. Alış Faturası Master Kaydı (Invoices)
    INSERT INTO invoices (
        tenant_id, company_id, invoice_type, invoice_number, invoice_date,
        party_id, warehouse_id, purchase_order_id, currency,
        subtotal, tax_rate, tax_amount, grand_total,
        payment_terms_days, status, created_by
    ) VALUES (
        p_tenant_id, p_company_id, 'PURCHASE', p_invoice_number, CURRENT_DATE,
        p_supplier_id, p_warehouse_id, v_po_id, p_currency,
        v_subtotal, p_tax_rate, v_tax_amount, v_grand_total,
        p_payment_terms_days, 'POSTED', v_user_id
    ) RETURNING id INTO v_invoice_id;

    INSERT INTO invoice_lines (
        tenant_id, company_id, invoice_id, item_id, lot_id,
        line_number, quantity, uom, unit_price, tax_rate, tax_amount, subtotal, total_price
    ) VALUES (
        p_tenant_id, p_company_id, v_invoice_id, p_item_id, v_lot_id,
        1, p_quantity, p_uom, p_unit_price, p_tax_rate, v_tax_amount, v_subtotal, v_grand_total
    );

    -- F. Stok Hareket Defteri Girişi (Stock Ledger: PURCHASE / IN)
    INSERT INTO stock_ledger_entries (
        tenant_id, company_id, warehouse_id, item_id, lot_id,
        movement_type, quantity, direction, unit, unit_cost, total_cost,
        document_type, document_reference, description, created_by
    ) VALUES (
        p_tenant_id, p_company_id, p_warehouse_id, p_item_id, v_lot_id,
        'PURCHASE', p_quantity, 'IN', p_uom, p_unit_price, v_subtotal,
        'PURCHASE_INVOICE', p_invoice_number,
        CONCAT('Satın Alma Mal Kabulü: ', p_invoice_number, ' - Lot: ', p_lot_number),
        v_user_id
    );

    -- G. Çift Taraflı Muhasebe Yevmiye Kaydı (Journal Entry: 153 Borç, 191 Borç, 320 Alacak)
    -- Hesapları bul veya oluştur
    SELECT id INTO v_acc_153_id FROM chart_of_accounts WHERE company_id = p_company_id AND account_code = '153' LIMIT 1;
    IF v_acc_153_id IS NULL THEN
        INSERT INTO chart_of_accounts (tenant_id, company_id, account_code, account_name, account_type, balance_type, currency_code, posting_allowed)
        VALUES (p_tenant_id, p_company_id, '153', 'Ticari Mallar (Hurma Stoku)', 'ASSET', 'DEBIT', p_currency, TRUE)
        RETURNING id INTO v_acc_153_id;
    END IF;

    SELECT id INTO v_acc_191_id FROM chart_of_accounts WHERE company_id = p_company_id AND account_code = '191' LIMIT 1;
    IF v_acc_191_id IS NULL THEN
        INSERT INTO chart_of_accounts (tenant_id, company_id, account_code, account_name, account_type, balance_type, currency_code, posting_allowed)
        VALUES (p_tenant_id, p_company_id, '191', 'İndirilecek KDV / VAT', 'ASSET', 'DEBIT', p_currency, TRUE)
        RETURNING id INTO v_acc_191_id;
    END IF;

    SELECT id INTO v_acc_320_id FROM chart_of_accounts WHERE company_id = p_company_id AND account_code = '320' LIMIT 1;
    IF v_acc_320_id IS NULL THEN
        INSERT INTO chart_of_accounts (tenant_id, company_id, account_code, account_name, account_type, balance_type, currency_code, posting_allowed)
        VALUES (p_tenant_id, p_company_id, '320', 'Satıcılar (Tedarikçiler)', 'LIABILITY', 'CREDIT', p_currency, TRUE)
        RETURNING id INTO v_acc_320_id;
    END IF;

    INSERT INTO journal_entries (
        tenant_id, company_id, entry_date, entry_type,
        document_type, document_reference, description,
        total_debit, total_credit, status, posted_at, posted_by
    ) VALUES (
        p_tenant_id, p_company_id, CURRENT_DATE, 'PURCHASE_INVOICE',
        'PURCHASE_INVOICE', p_invoice_number,
        CONCAT('Satın Alma Faturası: ', p_invoice_number),
        v_grand_total, v_grand_total, 'DRAFT', NULL, NULL
    ) RETURNING id INTO v_journal_id;

    -- Satır 1: 153 Ticari Mallar (Borç)
    INSERT INTO journal_lines (
        tenant_id, company_id, journal_entry_id, account_id, party_id,
        line_number, description, debit_amount, credit_amount, transaction_currency, exchange_rate,
        base_debit_amount, base_credit_amount
    ) VALUES (
        p_tenant_id, p_company_id, v_journal_id, v_acc_153_id, p_supplier_id,
        1, CONCAT('Hurma Alış Bedeli: ', p_invoice_number), v_subtotal, 0.0000, p_currency, 1.0,
        v_subtotal, 0.0000
    );

    -- Satır 2: 191 İndirilecek KDV (Borç - eğer vergi varsa)
    IF v_tax_amount > 0 THEN
        INSERT INTO journal_lines (
            tenant_id, company_id, journal_entry_id, account_id, party_id,
            line_number, description, debit_amount, credit_amount, transaction_currency, exchange_rate,
            base_debit_amount, base_credit_amount
        ) VALUES (
            p_tenant_id, p_company_id, v_journal_id, v_acc_191_id, p_supplier_id,
            2, CONCAT('İndirilecek KDV (%', p_tax_rate, '): ', p_invoice_number), v_tax_amount, 0.0000, p_currency, 1.0,
            v_tax_amount, 0.0000
        );
    END IF;

    -- Satır 3: 320 Satıcılar (Alacak)
    INSERT INTO journal_lines (
        tenant_id, company_id, journal_entry_id, account_id, party_id,
        line_number, description, debit_amount, credit_amount, transaction_currency, exchange_rate,
        base_debit_amount, base_credit_amount
    ) VALUES (
        p_tenant_id, p_company_id, v_journal_id, v_acc_320_id, p_supplier_id,
        3, CONCAT('Tedarikçi Cari Alacağı: ', p_invoice_number), 0.0000, v_grand_total, p_currency, 1.0,
        0.0000, v_grand_total
    );

    -- Fişi kesinleştir (POSTED)
    UPDATE journal_entries
    SET status = 'POSTED',
        posted_at = NOW(),
        posted_by = v_user_id,
        updated_at = NOW()
    WHERE id = v_journal_id;

    -- Faturaya journal_entry_id bağla
    UPDATE invoices SET journal_entry_id = v_journal_id WHERE id = v_invoice_id;

    -- H. Audit Log
    INSERT INTO audit_logs (
        tenant_id, user_id, company_id, action, entity_type, entity_id, new_data
    ) VALUES (
        p_tenant_id, v_user_id, p_company_id, 'CREATE'::audit_action_enum, 'purchase_invoice', v_invoice_id,
        jsonb_build_object(
            'po_number', p_po_number,
            'invoice_number', p_invoice_number,
            'lot_number', p_lot_number,
            'quantity', p_quantity,
            'grand_total', v_grand_total,
            'journal_entry_id', v_journal_id
        )
    );

    RETURN jsonb_build_object(
        'success', true,
        'purchase_order_id', v_po_id,
        'invoice_id', v_invoice_id,
        'lot_id', v_lot_id,
        'journal_entry_id', v_journal_id,
        'grand_total', v_grand_total
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;


-- 5. ATOMİK SATIŞ FATURASI RPC'Sİ (SALES FLOW - %100 GERİYE DÖNÜK UYUMLU)
-- CUSTOMER -> SALES ORDER -> DELIVERY -> INVOICE -> STOCK -> JOURNAL
CREATE OR REPLACE FUNCTION create_sales_invoice_atomic(
    p_tenant_id UUID,
    p_company_id UUID,
    p_invoice_number VARCHAR(100),
    p_invoice_date DATE,
    p_currency VARCHAR(5),
    p_customer_name VARCHAR(255),
    p_customer_id UUID DEFAULT NULL,
    p_item_id UUID DEFAULT NULL,
    p_item_name VARCHAR(255) DEFAULT NULL,
    p_lot_id UUID DEFAULT NULL,
    p_warehouse_id UUID DEFAULT NULL,
    p_quantity NUMERIC(15,3) DEFAULT 0,
    p_unit VARCHAR(20) DEFAULT 'Kg',
    p_unit_price NUMERIC(18,4) DEFAULT 0,
    p_subtotal NUMERIC(18,4) DEFAULT 0,
    p_vat_rate NUMERIC(5,2) DEFAULT 15,
    p_vat_amount NUMERIC(18,4) DEFAULT 0,
    p_grand_total NUMERIC(18,4) DEFAULT 0,
    p_is_official_posted BOOLEAN DEFAULT TRUE,
    p_notes TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID;
    v_journal_entry_id UUID;
    v_invoice_id UUID;
    v_so_id UUID;
    v_status VARCHAR(50);
    v_account_120_id UUID;
    v_account_600_id UUID;
    v_account_391_id UUID;
    v_target_warehouse_id UUID;
BEGIN
    -- A. Güvenlik Doğrulaması
    IF NOT is_tenant_member(p_tenant_id) THEN
        RAISE EXCEPTION 'GÜVENLİK İHLALİ: Aktif kullanıcı bu tenant''a üye değildir! (Tenant: %)', p_tenant_id;
    END IF;

    IF NOT has_company_access(p_company_id) THEN
        RAISE EXCEPTION 'GÜVENLİK İHLALİ: Aktif kullanıcının bu şirkete işlem yetkisi yoktur! (Şirket: %)', p_company_id;
    END IF;

    -- Mükerrer fatura engeli
    IF EXISTS (
        SELECT 1 FROM invoices 
        WHERE company_id = p_company_id 
          AND invoice_type = 'SALES' 
          AND invoice_number = p_invoice_number
    ) THEN
        RAISE EXCEPTION 'MÜKERRER FATURA: "%" numaralı satış faturası bu şirkette zaten kayıtlıdır!', p_invoice_number;
    END IF;

    v_user_id := get_current_user_id();
    v_status := CASE WHEN p_is_official_posted THEN 'POSTED' ELSE 'DRAFT' END;

    -- B. Depo Belirleme
    IF p_warehouse_id IS NOT NULL THEN
        v_target_warehouse_id := p_warehouse_id;
    ELSE
        SELECT id INTO v_target_warehouse_id
        FROM warehouses
        WHERE company_id = p_company_id
        ORDER BY created_at ASC
        LIMIT 1;
    END IF;

    -- C. Satış Siparişi Kaydı (Sales Order)
    INSERT INTO sales_orders (
        tenant_id, company_id, customer_id, order_number, order_date,
        warehouse_id, currency, subtotal, tax_amount, grand_total,
        status, notes, created_by
    ) VALUES (
        p_tenant_id, p_company_id, p_customer_id, CONCAT('SO-', p_invoice_number), p_invoice_date,
        v_target_warehouse_id, p_currency, p_subtotal, p_vat_amount, p_grand_total,
        CASE WHEN p_is_official_posted THEN 'DELIVERED' ELSE 'CONFIRMED' END,
        p_notes, v_user_id
    ) RETURNING id INTO v_so_id;

    IF p_item_id IS NOT NULL AND p_quantity > 0 THEN
        INSERT INTO sales_order_lines (
            tenant_id, company_id, sales_order_id, item_id,
            quantity, delivered_quantity, uom, unit_price, tax_rate, tax_amount, total_price
        ) VALUES (
            p_tenant_id, p_company_id, v_so_id, p_item_id,
            p_quantity, CASE WHEN p_is_official_posted THEN p_quantity ELSE 0 END,
            p_unit, p_unit_price, p_vat_rate, p_vat_amount, p_grand_total
        );
    END IF;

    -- D. Fatura Master Kaydı (invoices)
    INSERT INTO invoices (
        tenant_id, company_id, invoice_type, invoice_number, invoice_date,
        party_id, warehouse_id, sales_order_id, currency,
        subtotal, tax_rate, tax_amount, grand_total,
        status, notes, created_by
    ) VALUES (
        p_tenant_id, p_company_id, 'SALES', p_invoice_number, p_invoice_date,
        p_customer_id, v_target_warehouse_id, v_so_id, p_currency,
        p_subtotal, p_vat_rate, p_vat_amount, p_grand_total,
        v_status, p_notes, v_user_id
    ) RETURNING id INTO v_invoice_id;

    IF p_item_id IS NOT NULL THEN
        INSERT INTO invoice_lines (
            tenant_id, company_id, invoice_id, item_id, lot_id,
            line_number, quantity, uom, unit_price, tax_rate, tax_amount, subtotal, total_price
        ) VALUES (
            p_tenant_id, p_company_id, v_invoice_id, p_item_id, p_lot_id,
            1, p_quantity, p_unit, p_unit_price, p_vat_rate, p_vat_amount, p_subtotal, p_grand_total
        );
    END IF;

    -- E. Muhasebe Hesapları (120 / 600 / 391)
    SELECT id INTO v_account_120_id FROM chart_of_accounts WHERE company_id = p_company_id AND account_code = '120' LIMIT 1;
    IF v_account_120_id IS NULL THEN
        INSERT INTO chart_of_accounts (tenant_id, company_id, account_code, account_name, account_type, balance_type, currency_code, posting_allowed)
        VALUES (p_tenant_id, p_company_id, '120', 'Alıcılar (Müşteriler)', 'ASSET', 'DEBIT', p_currency, TRUE)
        RETURNING id INTO v_account_120_id;
    END IF;

    SELECT id INTO v_account_600_id FROM chart_of_accounts WHERE company_id = p_company_id AND account_code = '600' LIMIT 1;
    IF v_account_600_id IS NULL THEN
        INSERT INTO chart_of_accounts (tenant_id, company_id, account_code, account_name, account_type, balance_type, currency_code, posting_allowed)
        VALUES (p_tenant_id, p_company_id, '600', 'Yurtiçi Hurma Satış Gelirleri', 'REVENUE', 'CREDIT', p_currency, TRUE)
        RETURNING id INTO v_account_600_id;
    END IF;

    IF p_vat_amount > 0 THEN
        SELECT id INTO v_account_391_id FROM chart_of_accounts WHERE company_id = p_company_id AND account_code = '391' LIMIT 1;
        IF v_account_391_id IS NULL THEN
            INSERT INTO chart_of_accounts (tenant_id, company_id, account_code, account_name, account_type, balance_type, currency_code, posting_allowed)
            VALUES (p_tenant_id, p_company_id, '391', 'Hesaplanan KDV / VAT', 'LIABILITY', 'CREDIT', p_currency, TRUE)
            RETURNING id INTO v_account_391_id;
        END IF;
    END IF;

    -- F. Çift Taraflı Yevmiye Fişi (journal_entries)
    INSERT INTO journal_entries (
        tenant_id, company_id, entry_date, entry_type,
        document_type, document_reference, description,
        total_debit, total_credit, status, posted_at, posted_by
    ) VALUES (
        p_tenant_id, p_company_id, p_invoice_date, 'SALES_INVOICE',
        'ZATCA_INVOICE', p_invoice_number,
        CONCAT('Satış Faturası: ', p_invoice_number, ' — ', p_customer_name),
        p_grand_total, p_grand_total, 'DRAFT',
        NULL,
        NULL
    ) RETURNING id INTO v_journal_entry_id;

    -- Yevmiye Satırı 1: 120 Alıcılar (Borç)
    INSERT INTO journal_lines (
        tenant_id, company_id, journal_entry_id, account_id, party_id,
        line_number, description, debit_amount, credit_amount, transaction_currency, exchange_rate,
        base_debit_amount, base_credit_amount
    ) VALUES (
        p_tenant_id, p_company_id, v_journal_entry_id, v_account_120_id, p_customer_id,
        1, CONCAT('Müşteri Borcu: ', p_customer_name), p_grand_total, 0.0000, p_currency, 1.0,
        p_grand_total, 0.0000
    );

    -- Yevmiye Satırı 2: 600 Satış Gelirleri (Alacak)
    INSERT INTO journal_lines (
        tenant_id, company_id, journal_entry_id, account_id, party_id,
        line_number, description, debit_amount, credit_amount, transaction_currency, exchange_rate,
        base_debit_amount, base_credit_amount
    ) VALUES (
        p_tenant_id, p_company_id, v_journal_entry_id, v_account_600_id, p_customer_id,
        2, CONCAT('Hurma Satış Bedeli: ', p_invoice_number), 0.0000, p_subtotal, p_currency, 1.0,
        0.0000, p_subtotal
    );

    -- Yevmiye Satırı 3: 391 KDV (Alacak)
    IF p_vat_amount > 0 THEN
        INSERT INTO journal_lines (
            tenant_id, company_id, journal_entry_id, account_id, party_id,
            line_number, description, debit_amount, credit_amount, transaction_currency, exchange_rate,
            base_debit_amount, base_credit_amount
        ) VALUES (
            p_tenant_id, p_company_id, v_journal_entry_id, v_account_391_id, p_customer_id,
            3, CONCAT('Hesaplanan KDV (%', p_vat_rate, '): ', p_invoice_number), 0.0000, p_vat_amount, p_currency, 1.0,
            0.0000, p_vat_amount
        );
    END IF;

    -- Yevmiye Fişini Kesinleştir (POSTED)
    IF p_is_official_posted THEN
        UPDATE journal_entries
        SET status = 'POSTED',
            posted_at = NOW(),
            posted_by = v_user_id,
            updated_at = NOW()
        WHERE id = v_journal_entry_id;
    END IF;

    -- G. Stok Hareketi Düşüşü (Stock Ledger: SALE / OUT)
    -- Deponun negatif stok politikası bu aşamada tetikleyici (trg_check_negative_stock_policy) tarafından otomatik denetlenir!
    -- Eğer yetersiz stok varsa ve negatif stoka izin yoksa EXCEPTION fırlar ve TÜM TRANSACTION ROLLBACK OLUR!
    IF p_is_official_posted AND p_item_id IS NOT NULL AND p_quantity > 0 THEN
        INSERT INTO stock_ledger_entries (
            tenant_id, company_id, warehouse_id, item_id, lot_id,
            movement_type, quantity, direction, unit, unit_cost, total_cost,
            document_type, document_reference, description, created_by
        ) VALUES (
            p_tenant_id, p_company_id, v_target_warehouse_id, p_item_id, p_lot_id,
            'SALE', -p_quantity, 'OUT', p_unit, p_unit_price, p_subtotal,
            'INVOICE', p_invoice_number,
            CONCAT('Satış Faturası Stok Çıkışı: ', p_invoice_number),
            v_user_id
        );
    END IF;

    -- Faturaya journal_entry_id bağla
    UPDATE invoices SET journal_entry_id = v_journal_entry_id WHERE id = v_invoice_id;

    -- H. Audit Log
    INSERT INTO audit_logs (
        tenant_id, user_id, company_id, action, entity_type, entity_id, new_data
    ) VALUES (
        p_tenant_id, v_user_id, p_company_id, 'CREATE'::audit_action_enum, 'sales_invoices', v_invoice_id,
        jsonb_build_object(
            'invoice_number', p_invoice_number,
            'customer_name', p_customer_name,
            'grand_total', p_grand_total,
            'status', v_status,
            'journal_entry_id', v_journal_entry_id
        )
    );

    RETURN jsonb_build_object(
        'success', true,
        'invoice_id', v_invoice_id,
        'journal_entry_id', v_journal_entry_id,
        'sales_order_id', v_so_id,
        'invoice_number', p_invoice_number,
        'status', v_status,
        'grand_total', p_grand_total
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;


-- 6. RLS AKTİFLEŞTİRME VE POLİTİKALAR
ALTER TABLE purchase_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_order_lines ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales_order_lines ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoice_lines ENABLE ROW LEVEL SECURITY;

ALTER TABLE purchase_orders FORCE ROW LEVEL SECURITY;
ALTER TABLE purchase_order_lines FORCE ROW LEVEL SECURITY;
ALTER TABLE sales_orders FORCE ROW LEVEL SECURITY;
ALTER TABLE sales_order_lines FORCE ROW LEVEL SECURITY;
ALTER TABLE invoices FORCE ROW LEVEL SECURITY;
ALTER TABLE invoice_lines FORCE ROW LEVEL SECURITY;

CREATE POLICY "purchase_orders_select" ON purchase_orders
    FOR SELECT USING (is_tenant_member(tenant_id) AND has_company_access(company_id));

CREATE POLICY "purchase_orders_manage" ON purchase_orders
    FOR ALL USING (is_tenant_member(tenant_id) AND has_company_access(company_id))
    WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(company_id));

CREATE POLICY "purchase_order_lines_select" ON purchase_order_lines
    FOR SELECT USING (is_tenant_member(tenant_id) AND has_company_access(company_id));

CREATE POLICY "purchase_order_lines_manage" ON purchase_order_lines
    FOR ALL USING (is_tenant_member(tenant_id) AND has_company_access(company_id))
    WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(company_id));

CREATE POLICY "sales_orders_select" ON sales_orders
    FOR SELECT USING (is_tenant_member(tenant_id) AND has_company_access(company_id));

CREATE POLICY "sales_orders_manage" ON sales_orders
    FOR ALL USING (is_tenant_member(tenant_id) AND has_company_access(company_id))
    WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(company_id));

CREATE POLICY "sales_order_lines_select" ON sales_order_lines
    FOR SELECT USING (is_tenant_member(tenant_id) AND has_company_access(company_id));

CREATE POLICY "sales_order_lines_manage" ON sales_order_lines
    FOR ALL USING (is_tenant_member(tenant_id) AND has_company_access(company_id))
    WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(company_id));

CREATE POLICY "invoices_select" ON invoices
    FOR SELECT USING (is_tenant_member(tenant_id) AND has_company_access(company_id));

CREATE POLICY "invoices_manage" ON invoices
    FOR ALL USING (is_tenant_member(tenant_id) AND has_company_access(company_id))
    WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(company_id));

CREATE POLICY "invoice_lines_select" ON invoice_lines
    FOR SELECT USING (is_tenant_member(tenant_id) AND has_company_access(company_id));

CREATE POLICY "invoice_lines_manage" ON invoice_lines
    FOR ALL USING (is_tenant_member(tenant_id) AND has_company_access(company_id))
    WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(company_id));


-- 7. İNDEKSLER
CREATE INDEX IF NOT EXISTS idx_po_tenant_comp ON purchase_orders(tenant_id, company_id);
CREATE INDEX IF NOT EXISTS idx_po_supplier ON purchase_orders(supplier_id);
CREATE INDEX IF NOT EXISTS idx_so_tenant_comp ON sales_orders(tenant_id, company_id);
CREATE INDEX IF NOT EXISTS idx_so_customer ON sales_orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_invoices_tenant_comp ON invoices(tenant_id, company_id);
CREATE INDEX IF NOT EXISTS idx_invoices_party ON invoices(party_id);
CREATE INDEX IF NOT EXISTS idx_invoices_date ON invoices(invoice_date DESC);
CREATE INDEX IF NOT EXISTS idx_invoice_lines_inv ON invoice_lines(invoice_id);
