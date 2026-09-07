-- ==============================================================================
-- NAKHL & NAHL — FAZ 23: REPORTING + ANALYTICS BOUNDED CONTEXT
-- Enterprise Reporting Engine, Aggregation Views, and Dashboard Analytics
-- ==============================================================================

-- 0. NAKİT VE BANKA HESAPLARI TABLOSU (Gerekiyorsa Oluştur)
CREATE TABLE IF NOT EXISTS cash_bank_accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    account_name VARCHAR(150) NOT NULL,
    account_type VARCHAR(50) NOT NULL DEFAULT 'BANK', -- CASH, BANK, POS
    bank_name VARCHAR(150),
    iban VARCHAR(50),
    currency VARCHAR(5) NOT NULL DEFAULT 'SAR',
    current_balance NUMERIC(18,4) NOT NULL DEFAULT 0.0000,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 1. YÜKSEK PERFORMANS İNDEKSLERİ (Aggregation & Reporting Indexes)
CREATE INDEX IF NOT EXISTS idx_invoices_report_sales
    ON invoices (tenant_id, company_id, invoice_type, invoice_date, status)
    WHERE invoice_type = 'SALES';

CREATE INDEX IF NOT EXISTS idx_invoices_report_purchase
    ON invoices (tenant_id, company_id, invoice_type, invoice_date, status)
    WHERE invoice_type = 'PURCHASE';

CREATE INDEX IF NOT EXISTS idx_stock_ledger_report
    ON stock_ledger_entries (tenant_id, company_id, item_id, warehouse_id, movement_type, created_at);

CREATE INDEX IF NOT EXISTS idx_quality_inspections_report
    ON quality_inspections (tenant_id, company_id, result, inspection_type, inspection_date);

CREATE INDEX IF NOT EXISTS idx_halal_certs_report
    ON halal_certificates (tenant_id, company_id, status, expiry_date);

CREATE INDEX IF NOT EXISTS idx_export_files_report
    ON export_files (tenant_id, company_id, status, destination_country_code, created_at);

CREATE INDEX IF NOT EXISTS idx_transport_orders_report
    ON transport_orders (tenant_id, company_id, status, created_at);

CREATE INDEX IF NOT EXISTS idx_cold_chain_temp_report
    ON cold_chain_temperature_logs (tenant_id, company_id, is_breached, recorded_at);

-- ==============================================================================
-- 2. YÖNETİCİ VE OPERASYONEL ANALİTİK GÖRÜNÜMLERİ (REPORTING VIEWS)
-- Row Level Security uyumlu (security_invoker = true) raporlama view'ları.
-- ==============================================================================

-- Rapor 1: Satış Raporu (Sales Report)
CREATE OR REPLACE VIEW view_report_sales WITH (security_invoker = true) AS
SELECT 
    i.tenant_id,
    i.company_id,
    c.legal_name AS company_name,
    i.invoice_number,
    i.invoice_date,
    p.legal_name AS customer_name,
    p.country_code AS customer_country,
    i.currency,
    i.subtotal AS net_sales,
    i.tax_amount AS tax_sales,
    i.grand_total AS gross_sales,
    i.status,
    i.payment_terms_days,
    i.created_at
FROM invoices i
JOIN companies c ON i.company_id = c.id
LEFT JOIN parties p ON i.party_id = p.id
WHERE i.invoice_type = 'SALES';

-- Rapor 2: Satın Alma Raporu (Purchase Report)
CREATE OR REPLACE VIEW view_report_purchase WITH (security_invoker = true) AS
SELECT 
    i.tenant_id,
    i.company_id,
    c.legal_name AS company_name,
    i.invoice_number,
    i.invoice_date,
    p.legal_name AS supplier_name,
    p.country_code AS supplier_country,
    i.currency,
    i.subtotal AS net_purchase,
    i.tax_amount AS tax_purchase,
    i.grand_total AS gross_purchase,
    i.status,
    i.created_at
FROM invoices i
JOIN companies c ON i.company_id = c.id
LEFT JOIN parties p ON i.party_id = p.id
WHERE i.invoice_type = 'PURCHASE';

-- Rapor 3: Envanter Bakiye ve Değerleme Raporu (Inventory Valuation Report)
CREATE OR REPLACE VIEW view_report_inventory WITH (security_invoker = true) AS
SELECT 
    v.tenant_id,
    v.company_id,
    c.legal_name AS company_name,
    w.name AS warehouse_name,
    w.code AS warehouse_code,
    i.item_code AS item_sku,
    i.item_name AS item_name,
    v.unit AS unit_of_measure,
    v.current_quantity,
    ROUND(v.current_quantity * 25.00, 2) AS estimated_valuation_sar
FROM view_current_stock v
JOIN companies c ON v.company_id = c.id
JOIN warehouses w ON v.warehouse_id = w.id
JOIN items i ON v.item_id = i.id;

-- Rapor 4: Stok Hareketleri Raporu (Stock Movement Audit Report)
CREATE OR REPLACE VIEW view_report_stock_movement WITH (security_invoker = true) AS
SELECT 
    sl.tenant_id,
    sl.company_id,
    c.legal_name AS company_name,
    sl.movement_type,
    CASE WHEN sl.quantity >= 0 THEN 'IN' ELSE 'OUT' END AS direction,
    w.name AS warehouse_name,
    i.item_code AS item_sku,
    i.item_name AS item_name,
    sl.quantity,
    sl.unit_cost,
    sl.total_cost,
    sl.document_type AS reference_type,
    sl.document_reference AS reference_id,
    sl.created_at AS movement_timestamp
FROM stock_ledger_entries sl
JOIN companies c ON sl.company_id = c.id
LEFT JOIN warehouses w ON sl.warehouse_id = w.id
LEFT JOIN items i ON sl.item_id = i.id;

-- Rapor 5: Uçtan Uca Lot İzlenebilirlik Raporu (Lot Traceability Report)
CREATE OR REPLACE VIEW view_report_lot_traceability WITH (security_invoker = true) AS
SELECT 
    l.tenant_id,
    l.company_id,
    c.legal_name AS company_name,
    l.lot_number,
    i.item_name AS item_name,
    l.production_date AS harvest_date,
    l.expiration_date AS expiry_date,
    l.quality_status AS lot_status,
    COALESCE((
        SELECT qi.result 
        FROM quality_inspections qi 
        WHERE qi.lot_id = l.id 
        ORDER BY qi.inspection_date DESC LIMIT 1
    ), 'NOT_INSPECTED') AS latest_quality_result,
    COALESCE((
        SELECT hlc.compliance_status 
        FROM halal_lot_compliance hlc 
        WHERE hlc.lot_id = l.id 
        LIMIT 1
    ), 'PENDING_AUDIT') AS halal_compliance_status
FROM item_lots l
JOIN companies c ON l.company_id = c.id
JOIN items i ON l.item_id = i.id;

-- Rapor 6: Müşteri Analiz Raporu (Customer Report)
CREATE OR REPLACE VIEW view_report_customer WITH (security_invoker = true) AS
SELECT 
    p.tenant_id,
    i.company_id,
    p.id AS customer_id,
    p.legal_name AS customer_name,
    p.country_code,
    p.tax_number,
    COUNT(i.id) AS total_orders_count,
    COALESCE(SUM(i.subtotal), 0.00) AS total_net_revenue,
    COALESCE(SUM(i.grand_total), 0.00) AS total_gross_revenue,
    i.currency
FROM parties p
JOIN invoices i ON p.id = i.party_id AND i.invoice_type = 'SALES'
GROUP BY p.tenant_id, i.company_id, p.id, p.legal_name, p.country_code, p.tax_number, i.currency;

-- Rapor 7: Tedarikçi Analiz Raporu (Supplier Report)
CREATE OR REPLACE VIEW view_report_supplier WITH (security_invoker = true) AS
SELECT 
    p.tenant_id,
    i.company_id,
    p.id AS supplier_id,
    p.legal_name AS supplier_name,
    p.country_code,
    p.tax_number,
    COUNT(i.id) AS total_purchases_count,
    COALESCE(SUM(i.subtotal), 0.00) AS total_net_spend,
    COALESCE(SUM(i.grand_total), 0.00) AS total_gross_spend,
    i.currency
FROM parties p
JOIN invoices i ON p.id = i.party_id AND i.invoice_type = 'PURCHASE'
GROUP BY p.tenant_id, i.company_id, p.id, p.legal_name, p.country_code, p.tax_number, i.currency;

-- Rapor 8: Muhasebe Mizan & Bilanço Raporu (Accounting Trial Balance Report)
CREATE OR REPLACE VIEW view_report_accounting WITH (security_invoker = true) AS
SELECT 
    a.tenant_id,
    a.company_id,
    c.legal_name AS company_name,
    a.account_code,
    a.account_name,
    a.account_type,
    COALESCE(SUM(jl.debit_amount), 0.00) AS total_debit,
    COALESCE(SUM(jl.credit_amount), 0.00) AS total_credit,
    CASE 
        WHEN a.account_type IN ('ASSET', 'EXPENSE') THEN 
            COALESCE(SUM(jl.debit_amount), 0.00) - COALESCE(SUM(jl.credit_amount), 0.00)
        ELSE 
            COALESCE(SUM(jl.credit_amount), 0.00) - COALESCE(SUM(jl.debit_amount), 0.00)
    END AS net_balance
FROM chart_of_accounts a
JOIN companies c ON a.company_id = c.id
LEFT JOIN journal_lines jl ON a.id = jl.account_id
LEFT JOIN journal_entries je ON jl.journal_entry_id = je.id AND je.status = 'POSTED'
GROUP BY a.tenant_id, a.company_id, c.legal_name, a.account_code, a.account_name, a.account_type;

-- Rapor 9: Nakit ve Finans Raporu (Cash & Finance Liquidity Report)
CREATE OR REPLACE VIEW view_report_cash_finance WITH (security_invoker = true) AS
SELECT 
    cba.tenant_id,
    cba.company_id,
    c.legal_name AS company_name,
    cba.account_name,
    cba.account_type, -- CASH, BANK, POS
    cba.bank_name,
    cba.iban,
    cba.currency,
    cba.current_balance,
    cba.is_active
FROM cash_bank_accounts cba
JOIN companies c ON cba.company_id = c.id;

-- Rapor 10: İhracat Operasyonları Raporu (Export Trade Report)
CREATE OR REPLACE VIEW view_report_export WITH (security_invoker = true) AS
SELECT 
    ef.tenant_id,
    ef.company_id,
    c.legal_name AS company_name,
    ef.export_number,
    ef.destination_country_code AS destination_country,
    ef.incoterm,
    ef.currency_code AS currency,
    ef.fob_value AS fob_amount,
    ef.cif_value AS cif_amount,
    ef.status AS export_status,
    COALESCE(cd.status, 'NOT_DECLARED') AS customs_status,
    (SELECT COUNT(*) FROM export_containers ec WHERE ec.export_file_id = ef.id) AS container_count,
    ef.created_at
FROM export_files ef
JOIN companies c ON ef.company_id = c.id
LEFT JOIN customs_declarations cd ON cd.export_file_id = ef.id;

-- Rapor 11: Sevkiyat ve Lojistik Raporu (Shipment & Logistics Report)
CREATE OR REPLACE VIEW view_report_shipment WITH (security_invoker = true) AS
SELECT 
    s.tenant_id,
    s.company_id,
    c.legal_name AS company_name,
    s.shipment_number,
    s.carrier_company AS carrier_name,
    s.status AS shipment_status,
    (
        SELECT COUNT(*) 
        FROM cold_chain_temperature_logs cce 
        WHERE cce.company_id = s.company_id AND cce.is_breached = TRUE
    ) AS cold_chain_alerts_count,
    s.created_at
FROM shipments s
JOIN companies c ON s.company_id = c.id;

-- Rapor 12: Kalite Kontrol Raporu (Quality Management Report)
CREATE OR REPLACE VIEW view_report_quality WITH (security_invoker = true) AS
SELECT 
    qi.tenant_id,
    qi.company_id,
    c.legal_name AS company_name,
    qi.inspection_type,
    COUNT(*) AS total_inspections,
    COUNT(*) FILTER (WHERE qi.result = 'PASS') AS pass_count,
    COUNT(*) FILTER (WHERE qi.result = 'FAIL') AS fail_count,
    COUNT(*) FILTER (WHERE qi.result = 'CONDITIONAL') AS conditional_count,
    COUNT(*) FILTER (WHERE qi.result = 'QUARANTINE') AS quarantine_count,
    ROUND(
        (COUNT(*) FILTER (WHERE qi.result = 'PASS')::NUMERIC / NULLIF(COUNT(*), 0)) * 100.0, 
        2
    ) AS pass_percentage
FROM quality_inspections qi
JOIN companies c ON qi.company_id = c.id
GROUP BY qi.tenant_id, qi.company_id, c.legal_name, qi.inspection_type;

-- Rapor 13: Helal Uygunluk Raporu (Halal Compliance Report)
CREATE OR REPLACE VIEW view_report_halal WITH (security_invoker = true) AS
SELECT 
    hc.tenant_id,
    hc.company_id,
    c.legal_name AS company_name,
    COALESCE(hcb.name, 'UNKNOWN') AS certification_body,
    COUNT(hc.id) AS total_certificates_count,
    COUNT(hc.id) FILTER (WHERE hc.status = 'ACTIVE' AND hc.expiry_date >= CURRENT_DATE) AS valid_certificates_count,
    COUNT(hc.id) FILTER (WHERE hc.status != 'ACTIVE' OR hc.expiry_date < CURRENT_DATE) AS expired_or_invalid_count,
    (
        SELECT COUNT(*) 
        FROM halal_lot_compliance hlc 
        WHERE hlc.company_id = hc.company_id AND hlc.compliance_status = 'COMPLIANT'
    ) AS certified_lots_count
FROM halal_certificates hc
JOIN companies c ON hc.company_id = c.id
LEFT JOIN halal_certification_bodies hcb ON hc.body_id = hcb.id
GROUP BY hc.tenant_id, hc.company_id, c.legal_name, hcb.name;

-- ==============================================================================
-- 3. N+1 SORGULARI ÖNLEYEN MERKEZİ DASHBOARD AGGREGATION RPC
-- ==============================================================================
CREATE OR REPLACE FUNCTION get_executive_dashboard_summary(
    p_tenant_id UUID,
    p_company_id UUID,
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_start DATE := COALESCE(p_start_date, CURRENT_DATE - INTERVAL '30 days');
    v_end DATE := COALESCE(p_end_date, CURRENT_DATE);
    v_result JSONB;
BEGIN
    -- Güvenlik doğrulaması: tenant ve company erişimi kontrolü
    IF auth.uid() IS NOT NULL THEN
        IF NOT has_company_access(auth.uid(), p_company_id) THEN
            RAISE EXCEPTION 'YETKİSİZ ERİŞİM: Belirtilen şirket için rapor alma yetkiniz bulunmamaktadır!';
        END IF;
    END IF;

    SELECT jsonb_build_object(
        'generated_at', NOW(),
        'period_start', v_start,
        'period_end', v_end,
        'company_id', p_company_id,
        'tenant_id', p_tenant_id,

        -- 1. Satış Özeti
        'sales_summary', (
            SELECT jsonb_build_object(
                'total_orders', COUNT(*),
                'net_sales', COALESCE(SUM(subtotal), 0.00),
                'tax_sales', COALESCE(SUM(tax_amount), 0.00),
                'gross_sales', COALESCE(SUM(grand_total), 0.00),
                'currency', COALESCE(MAX(currency), 'SAR')
            )
            FROM invoices
            WHERE tenant_id = p_tenant_id 
              AND company_id = p_company_id 
              AND invoice_type = 'SALES'
              AND invoice_date BETWEEN v_start AND v_end
              AND status != 'CANCELLED'
        ),

        -- 2. Satın Alma Özeti
        'purchase_summary', (
            SELECT jsonb_build_object(
                'total_orders', COUNT(*),
                'net_purchase', COALESCE(SUM(subtotal), 0.00),
                'tax_purchase', COALESCE(SUM(tax_amount), 0.00),
                'gross_purchase', COALESCE(SUM(grand_total), 0.00),
                'currency', COALESCE(MAX(currency), 'SAR')
            )
            FROM invoices
            WHERE tenant_id = p_tenant_id 
              AND company_id = p_company_id 
              AND invoice_type = 'PURCHASE'
              AND invoice_date BETWEEN v_start AND v_end
              AND status != 'CANCELLED'
        ),

        -- 3. Envanter Özeti
        'inventory_summary', (
            SELECT jsonb_build_object(
                'total_sku_count', COUNT(DISTINCT item_id),
                'total_quantity_on_hand', COALESCE(SUM(current_quantity), 0.00),
                'estimated_valuation_sar', COALESCE(SUM(current_quantity * 25.00), 0.00)
            )
            FROM view_current_stock
            WHERE tenant_id = p_tenant_id AND company_id = p_company_id
        ),

        -- 4. Kalite Özeti
        'quality_summary', (
            SELECT jsonb_build_object(
                'total_inspections', COUNT(*),
                'pass_count', COUNT(*) FILTER (WHERE result = 'PASS'),
                'fail_count', COUNT(*) FILTER (WHERE result = 'FAIL'),
                'quarantine_count', COUNT(*) FILTER (WHERE result = 'QUARANTINE'),
                'pass_rate', ROUND((COUNT(*) FILTER (WHERE result = 'PASS')::NUMERIC / NULLIF(COUNT(*), 0)) * 100.0, 2)
            )
            FROM quality_inspections
            WHERE tenant_id = p_tenant_id AND company_id = p_company_id
              AND inspection_date::DATE BETWEEN v_start AND v_end
        ),

        -- 5. Helal Uygunluk Özeti
        'halal_summary', (
            SELECT jsonb_build_object(
                'active_certificates', COUNT(*) FILTER (WHERE status = 'ACTIVE' AND expiry_date >= CURRENT_DATE),
                'expiring_in_30_days', COUNT(*) FILTER (WHERE status = 'ACTIVE' AND expiry_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '30 days'),
                'expired_certificates', COUNT(*) FILTER (WHERE status != 'ACTIVE' OR expiry_date < CURRENT_DATE)
            )
            FROM halal_certificates
            WHERE tenant_id = p_tenant_id AND company_id = p_company_id
        ),

        -- 6. İhracat ve Lojistik Özeti
        'trade_and_logistics_summary', (
            SELECT jsonb_build_object(
                'active_export_files', (
                    SELECT COUNT(*) FROM export_files 
                    WHERE tenant_id = p_tenant_id AND company_id = p_company_id AND status != 'DELIVERED'
                ),
                'in_transit_shipments', (
                    SELECT COUNT(*) FROM shipments 
                    WHERE tenant_id = p_tenant_id AND company_id = p_company_id AND status IN ('IN_TRANSIT', 'PREPARING')
                ),
                'cold_chain_alerts', (
                    SELECT COUNT(*) FROM cold_chain_temperature_logs 
                    WHERE tenant_id = p_tenant_id AND company_id = p_company_id AND is_breached = TRUE
                )
            )
        ),

        -- 7. Likidite ve Kasa/Banka Özeti
        'finance_summary', (
            SELECT jsonb_build_object(
                'total_cash_and_bank_sar', COALESCE(SUM(current_balance), 0.00),
                'active_accounts_count', COUNT(*)
            )
            FROM cash_bank_accounts
            WHERE tenant_id = p_tenant_id AND company_id = p_company_id AND is_active = TRUE
        )
    ) INTO v_result;

    RETURN v_result;
END;
$$;
