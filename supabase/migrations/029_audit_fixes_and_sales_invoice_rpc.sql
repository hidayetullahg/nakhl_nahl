-- ==============================================================================
-- NAKHL & NAHL — MIGRATION 029: AUDIT FIXES & ATOMIC SALES INVOICE RPC
-- Purpose: 
-- 1. journal_lines üzerinde POSTED ebeveyn yevmiye kilidi (Immutability trigger)
-- 2. shipment_containers üzerinde mükerrer konteyner kısıtı (UNIQUE constraint)
-- 3. create_sales_invoice_atomic: Fatura Başlığı + Yevmiye Satırları (120/600/391) + Stok Hareketi tek transaction
-- ==============================================================================

-- 1. journal_lines Immutability Trigger
CREATE OR REPLACE FUNCTION prevent_posted_journal_line_modification()
RETURNS TRIGGER AS $$
DECLARE
    v_status VARCHAR(50);
BEGIN
    SELECT status INTO v_status
    FROM journal_entries
    WHERE id = COALESCE(OLD.journal_entry_id, NEW.journal_entry_id);

    IF v_status = 'POSTED' OR v_status = 'LOCKED' THEN
        RAISE EXCEPTION 'Kesinleşmiş (POSTED/LOCKED) bir yevmiye fişine ait satırlar üzerinde ekleme, silme veya güncelleme yapılamaz!';
    END IF;

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

DROP TRIGGER IF EXISTS trg_prevent_posted_journal_line_modification ON journal_lines;
CREATE TRIGGER trg_prevent_posted_journal_line_modification
BEFORE INSERT OR UPDATE OR DELETE ON journal_lines
FOR EACH ROW EXECUTE FUNCTION prevent_posted_journal_line_modification();


-- 2. shipment_containers UNIQUE Constraint
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'uq_container_shipment'
    ) THEN
        ALTER TABLE shipment_containers
        ADD CONSTRAINT uq_container_shipment UNIQUE (shipment_id, container_number);
    END IF;
END $$;


-- 3. Atomic Sales Invoice Creation RPC (Stored Procedure)
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
    v_status VARCHAR(50);
    v_account_120_id UUID;
    v_account_600_id UUID;
    v_account_391_id UUID;
    v_current_stock NUMERIC(15,3);
    v_target_warehouse_id UUID;
BEGIN
    -- A. Güvenlik ve Yetki Doğrulaması
    IF NOT is_tenant_member(p_tenant_id) THEN
        RAISE EXCEPTION 'Güvenlik İhlali: Aktif kullanıcı bu tenant''a üye değildir! (Tenant: %)', p_tenant_id;
    END IF;

    IF NOT has_company_access(p_company_id) THEN
        RAISE EXCEPTION 'Güvenlik İhlali: Aktif kullanıcının bu şirkete işlem yetkisi yoktur! (Şirket: %)', p_company_id;
    END IF;

    v_user_id := get_current_user_id();
    v_status := CASE WHEN p_is_official_posted THEN 'POSTED' ELSE 'DRAFT' END;

    -- B. Depo Belirleme ve Stok Kontrolü
    IF p_warehouse_id IS NOT NULL THEN
        v_target_warehouse_id := p_warehouse_id;
    ELSE
        SELECT id INTO v_target_warehouse_id
        FROM warehouses
        WHERE company_id = p_company_id AND status = 'ACTIVE'
        LIMIT 1;
    END IF;

    IF p_is_official_posted AND p_item_id IS NOT NULL AND p_quantity > 0 THEN
        IF v_target_warehouse_id IS NOT NULL THEN
            SELECT COALESCE(SUM(quantity), 0) INTO v_current_stock
            FROM stock_ledger_entries
            WHERE tenant_id = p_tenant_id
              AND company_id = p_company_id
              AND item_id = p_item_id
              AND warehouse_id = v_target_warehouse_id;

            IF v_current_stock < p_quantity THEN
                RAISE NOTICE 'Uyarı: Yetersiz stok bakiyesi! Mevcut: %, Talep: %', v_current_stock, p_quantity;
            END IF;
        END IF;
    END IF;

    -- C. Hesap Planından Gerekli Hesapları Bul veya Oluştur
    -- 120: Alıcılar (ASSET, DEBIT)
    SELECT id INTO v_account_120_id
    FROM chart_of_accounts
    WHERE company_id = p_company_id AND account_code = '120'
    LIMIT 1;

    IF v_account_120_id IS NULL THEN
        INSERT INTO chart_of_accounts (tenant_id, company_id, account_code, account_name, account_type, balance_type, currency_code)
        VALUES (p_tenant_id, p_company_id, '120', 'Alıcılar (Müşteriler)', 'ASSET', 'DEBIT', p_currency)
        RETURNING id INTO v_account_120_id;
    END IF;

    -- 600: Yurtiçi Satışlar (REVENUE, CREDIT)
    SELECT id INTO v_account_600_id
    FROM chart_of_accounts
    WHERE company_id = p_company_id AND account_code = '600'
    LIMIT 1;

    IF v_account_600_id IS NULL THEN
        INSERT INTO chart_of_accounts (tenant_id, company_id, account_code, account_name, account_type, balance_type, currency_code)
        VALUES (p_tenant_id, p_company_id, '600', 'Yurtiçi Hurma Satış Gelirleri', 'REVENUE', 'CREDIT', p_currency)
        RETURNING id INTO v_account_600_id;
    END IF;

    -- 391: Hesaplanan KDV (LIABILITY, CREDIT)
    IF p_vat_amount > 0 THEN
        SELECT id INTO v_account_391_id
        FROM chart_of_accounts
        WHERE company_id = p_company_id AND account_code = '391'
        LIMIT 1;

        IF v_account_391_id IS NULL THEN
            INSERT INTO chart_of_accounts (tenant_id, company_id, account_code, account_name, account_type, balance_type, currency_code)
            VALUES (p_tenant_id, p_company_id, '391', 'Hesaplanan KDV (%15)', 'LIABILITY', 'CREDIT', p_currency)
            RETURNING id INTO v_account_391_id;
        END IF;
    END IF;

    -- D. 1. Aşama: Yevmiye Fişi Başlığı (journal_entries)
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
        posted_by
    ) VALUES (
        p_tenant_id,
        p_company_id,
        p_invoice_date,
        'SALES_INVOICE',
        'ZATCA_INVOICE',
        p_invoice_number,
        CONCAT('Satış Faturası: ', p_invoice_number, ' — ', p_customer_name, ' (', v_status, ')'),
        p_grand_total,
        p_grand_total,
        v_status,
        CASE WHEN p_is_official_posted THEN NOW() ELSE NULL END,
        v_user_id
    ) RETURNING id INTO v_journal_entry_id;

    -- E. 2. Aşama: Yevmiye Fişi Satırları (journal_lines — Çift Taraflı Kayıt)
    -- Satır 1: 120 Alıcılar Hesabı (BORÇ)
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
        base_debit_amount,
        base_credit_amount
    ) VALUES (
        p_tenant_id,
        p_company_id,
        v_journal_entry_id,
        v_account_120_id,
        p_customer_id,
        1,
        CONCAT('Satış Alacağı — ', p_customer_name),
        p_grand_total,
        0.0000,
        p_currency,
        p_grand_total,
        0.0000
    );

    -- Satır 2: 600 Satış Geliri Hesabı (ALACAK)
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
        base_debit_amount,
        base_credit_amount
    ) VALUES (
        p_tenant_id,
        p_company_id,
        v_journal_entry_id,
        v_account_600_id,
        p_customer_id,
        2,
        CONCAT('Hurma Satış Geliri — ', COALESCE(p_item_name, 'Standart Hurma')),
        0.0000,
        p_subtotal,
        p_currency,
        0.0000,
        p_subtotal
    );

    -- Satır 3: 391 Hesaplanan KDV Hesabı (ALACAK - Varsa)
    IF p_vat_amount > 0 AND v_account_391_id IS NOT NULL THEN
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
            base_debit_amount,
            base_credit_amount
        ) VALUES (
            p_tenant_id,
            p_company_id,
            v_journal_entry_id,
            v_account_391_id,
            p_customer_id,
            3,
            CONCAT('Hesaplanan KDV %', p_vat_rate),
            0.0000,
            p_vat_amount,
            p_currency,
            0.0000,
            p_vat_amount
        );
    END IF;

    -- F. 3. Aşama: Stok Çıkış Defteri (stock_ledger_entries — Yalnızca Onaylı ise)
    IF p_is_official_posted AND p_item_id IS NOT NULL AND p_quantity > 0 AND v_target_warehouse_id IS NOT NULL THEN
        INSERT INTO stock_ledger_entries (
            tenant_id,
            company_id,
            warehouse_id,
            item_id,
            lot_id,
            movement_type,
            quantity,
            unit,
            unit_cost,
            total_cost,
            document_type,
            document_reference,
            description,
            created_by
        ) VALUES (
            p_tenant_id,
            p_company_id,
            v_target_warehouse_id,
            p_item_id,
            p_lot_id,
            'SALES_ISSUE',
            -p_quantity,
            p_unit,
            p_unit_price,
            p_subtotal,
            'INVOICE',
            p_invoice_number,
            CONCAT('Satış Faturası Stok Çıkışı: ', p_invoice_number),
            v_user_id
        );
    END IF;

    -- G. 4. Aşama: Denetim İzi (audit_logs)
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
        v_user_id,
        p_company_id,
        'CREATE',
        'sales_invoices',
        v_journal_entry_id,
        jsonb_build_object(
            'invoice_number', p_invoice_number,
            'customer_name', p_customer_name,
            'grand_total', p_grand_total,
            'status', v_status
        )
    );

    RETURN jsonb_build_object(
        'success', true,
        'journal_entry_id', v_journal_entry_id,
        'invoice_number', p_invoice_number,
        'status', v_status,
        'grand_total', p_grand_total
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
