-- ==============================================================================
-- NAKHL & NAHL — MIGRATION 042: LEGISLATION & TAX ENGINE BOUNDED CONTEXT (FAZ 22)
-- Purpose:
-- 1. legislations: Mevzuat master tablosu (ülke, yetki alanı, versiyon, kaynak)
-- 2. tax_rules: Vergi kuralları motoru (oran, ülke, yetki, geçerlilik tarihi, şirket, ürün, işlem tipi)
-- 3. calculate_transaction_tax: Satış, satınalma ve ihracat için merkezi vergi hesaplama RPC'si
-- 4. Tarihsel vergi hesaplama desteği (Mevzuat değişiklikleri geçmiş hesapları bozmaz)
-- 5. RLS Politikaları ve İndeksler
-- ==============================================================================

-- 1. MEVZUAT MASTER TABLOSU (LEGISLATIONS MASTER)
CREATE TABLE IF NOT EXISTS legislations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    country_code VARCHAR(10) NOT NULL, -- TR, SA, AE, DE, GB, US, CN, EU
    jurisdiction VARCHAR(100) NOT NULL DEFAULT 'NATIONAL', -- NATIONAL, SA-ZATCA, TR-GIB, AE-FTA, DE-FINANZAMT
    legislation_code VARCHAR(100) NOT NULL, -- KDV_3065, ZATCA_VAT_2020, UAE_VAT_2018
    title VARCHAR(255) NOT NULL,
    effective_from DATE NOT NULL,
    effective_to DATE, -- NULL ise halen yürürlükte
    version VARCHAR(20) NOT NULL DEFAULT '1.0',
    source_reference TEXT, -- Resmi Gazete Sayı/Tarih, Kanun No, Bakanlık Genelgesi
    status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE' 
        CHECK (status IN ('DRAFT', 'ACTIVE', 'SUPERSEDED', 'REPEALED')),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_legislation_version UNIQUE (country_code, jurisdiction, legislation_code, version)
);

-- 2. GELİŞMİŞ VERGİ KURALLARI MOTORU (TAX RULES ENGINE)
CREATE TABLE IF NOT EXISTS tax_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    legislation_id UUID REFERENCES legislations(id) ON DELETE SET NULL,
    rule_code VARCHAR(100) NOT NULL,
    rule_name VARCHAR(150) NOT NULL,
    tax_type VARCHAR(50) NOT NULL DEFAULT 'VAT' 
        CHECK (tax_type IN ('VAT', 'GST', 'WITHHOLDING', 'EXPORT_ZERO', 'CUSTOMS', 'EXCISE')),
    rate NUMERIC(7,4) NOT NULL, -- 15.0000 = %15, 1.0000 = %1, 0.0000 = %0
    country_code VARCHAR(10) NOT NULL,
    jurisdiction VARCHAR(100) NOT NULL DEFAULT 'NATIONAL',
    effective_from DATE NOT NULL,
    effective_to DATE, -- Tarihsel hesaplama için üst sınır
    product_category_id UUID REFERENCES product_categories(id) ON DELETE SET NULL,
    item_id UUID REFERENCES items(id) ON DELETE SET NULL,
    transaction_type VARCHAR(50) NOT NULL DEFAULT 'ALL' 
        CHECK (transaction_type IN ('SALES', 'PURCHASE', 'EXPORT', 'IMPORT', 'ALL')),
    is_reverse_charge BOOLEAN NOT NULL DEFAULT FALSE,
    is_recoverable BOOLEAN NOT NULL DEFAULT TRUE,
    priority INT NOT NULL DEFAULT 100, -- Daha yüksek sayı = daha öncelikli kural (Item spesifik kurallar genel kuralları ezer)
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_tax_rule_company_code UNIQUE (company_id, rule_code, effective_from)
);

-- 3. MERKEZİ VERGİ HESAPLAMA RPC MOTORU (CENTRALIZED TAX CALCULATION ENGINE)
-- UI içinde dağınık tax hesaplama bırakmaz.
-- Tarihsel vergi kuralını (effective_from <= date AND (effective_to IS NULL OR effective_to >= date)) dinamik çözer.
CREATE OR REPLACE FUNCTION calculate_transaction_tax(
    p_tenant_id UUID,
    p_company_id UUID,
    p_transaction_type VARCHAR, -- 'SALES', 'PURCHASE', 'EXPORT', 'IMPORT'
    p_country_code VARCHAR,
    p_transaction_date DATE,
    p_base_amount NUMERIC(15,2),
    p_item_id UUID DEFAULT NULL,
    p_jurisdiction VARCHAR DEFAULT 'NATIONAL'
)
RETURNS TABLE (
    rule_id UUID,
    rule_code VARCHAR,
    tax_type VARCHAR,
    rate NUMERIC,
    tax_amount NUMERIC,
    total_amount NUMERIC,
    is_reverse_charge BOOLEAN,
    is_recoverable BOOLEAN,
    legislation_code VARCHAR,
    legislation_version VARCHAR
) AS $$
DECLARE
    v_rec RECORD;
    v_calc_tax NUMERIC(15,2);
    v_calc_total NUMERIC(15,2);
BEGIN
    -- En uygun vergi kuralını önceliğe (priority DESC) göre seç
    SELECT 
        tr.id,
        tr.rule_code,
        tr.tax_type,
        tr.rate,
        tr.is_reverse_charge,
        tr.is_recoverable,
        l.legislation_code,
        l.version AS leg_version
    INTO v_rec
    FROM tax_rules tr
    LEFT JOIN legislations l ON l.id = tr.legislation_id
    WHERE tr.tenant_id = p_tenant_id
      AND tr.company_id = p_company_id
      AND tr.country_code = p_country_code
      AND (tr.jurisdiction = p_jurisdiction OR tr.jurisdiction = 'NATIONAL')
      AND (tr.transaction_type = p_transaction_type OR tr.transaction_type = 'ALL')
      AND (tr.item_id IS NULL OR tr.item_id = p_item_id)
      AND tr.effective_from <= p_transaction_date
      AND (tr.effective_to IS NULL OR tr.effective_to >= p_transaction_date)
      AND tr.is_active = TRUE
    ORDER BY 
        CASE WHEN tr.item_id = p_item_id THEN 1000 ELSE 0 END DESC,
        CASE WHEN tr.transaction_type = p_transaction_type THEN 500 ELSE 0 END DESC,
        tr.priority DESC,
        tr.effective_from DESC
    LIMIT 1;

    -- Eğer hiçbir kural bulunamazsa varsayılan %0 (veya ihracat muafiyeti)
    IF v_rec.id IS NULL THEN
        RETURN QUERY SELECT 
            NULL::UUID,
            'DEFAULT_ZERO'::VARCHAR,
            'VAT'::VARCHAR,
            0.0000::NUMERIC,
            0.00::NUMERIC,
            p_base_amount::NUMERIC,
            FALSE::BOOLEAN,
            TRUE::BOOLEAN,
            'STANDARD'::VARCHAR,
            '1.0'::VARCHAR;
        RETURN;
    END IF;

    -- Vergi tutarını hesapla
    v_calc_tax := ROUND(p_base_amount * (v_rec.rate / 100.0), 2);
    v_calc_total := p_base_amount + v_calc_tax;

    RETURN QUERY SELECT 
        v_rec.id,
        v_rec.rule_code,
        v_rec.tax_type,
        v_rec.rate,
        v_calc_tax,
        v_calc_total,
        v_rec.is_reverse_charge,
        v_rec.is_recoverable,
        COALESCE(v_rec.legislation_code, 'STANDARD'),
        COALESCE(v_rec.leg_version, '1.0');
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;


-- 4. İNDEKSLER
CREATE INDEX IF NOT EXISTS idx_legislations_country ON legislations(country_code, jurisdiction, status);
CREATE INDEX IF NOT EXISTS idx_tax_rules_lookup ON tax_rules(tenant_id, company_id, country_code, transaction_type, effective_from, effective_to);
CREATE INDEX IF NOT EXISTS idx_tax_rules_item ON tax_rules(item_id) WHERE item_id IS NOT NULL;


-- 5. ROW LEVEL SECURITY (RLS)
ALTER TABLE legislations ENABLE ROW LEVEL SECURITY;
ALTER TABLE tax_rules ENABLE ROW LEVEL SECURITY;

ALTER TABLE legislations FORCE ROW LEVEL SECURITY;
ALTER TABLE tax_rules FORCE ROW LEVEL SECURITY;

-- Politikalar: legislations (Kiracı ve şirket bazlı erişim)
DROP POLICY IF EXISTS "legislations_select" ON legislations;
CREATE POLICY "legislations_select" ON legislations
    FOR SELECT USING (is_tenant_member(tenant_id));

DROP POLICY IF EXISTS "legislations_manage" ON legislations;
CREATE POLICY "legislations_manage" ON legislations
    FOR ALL USING (is_tenant_member(tenant_id))
    WITH CHECK (is_tenant_member(tenant_id));

-- Politikalar: tax_rules
DROP POLICY IF EXISTS "tax_rules_select" ON tax_rules;
CREATE POLICY "tax_rules_select" ON tax_rules
    FOR SELECT USING (is_tenant_member(tenant_id) AND has_company_access(company_id));

DROP POLICY IF EXISTS "tax_rules_manage" ON tax_rules;
CREATE POLICY "tax_rules_manage" ON tax_rules
    FOR ALL USING (is_tenant_member(tenant_id) AND has_company_access(company_id))
    WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(company_id));
