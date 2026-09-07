-- ==============================================================================
-- NAKHL & NAHL — MIGRATION 037: QUALITY MANAGEMENT BOUNDED CONTEXT (FAZ 17)
-- Purpose:
-- 1. quality_specifications & quality_parameters (Kalite Şartname ve Parametreleri)
-- 2. quality_inspections & quality_inspection_samples (Muayene ve Örneklem Kayıtları)
-- 3. trg_sync_lot_quality_status: Muayene sonucu ile lot durumunun (QUARANTINE/APPROVED) senkronizasyonu
-- 4. trg_prevent_quarantine_lot_issue: Karantinadaki veya reddedilen lotun satış/sevk engeli
-- 5. view_lot_traceability_quality: LOT -> WAREHOUSE -> PROCESS -> SHIPMENT kalite izlenebilirlik görünümü
-- 6. Audit Logging ve RLS
-- ==============================================================================

-- 1. KALİTE ŞARTNAMELERİ (QUALITY SPECIFICATIONS)
CREATE TABLE IF NOT EXISTS quality_specifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    item_id UUID REFERENCES items(id) ON DELETE CASCADE,
    spec_code VARCHAR(50) NOT NULL,
    spec_name VARCHAR(150) NOT NULL,
    version VARCHAR(20) NOT NULL DEFAULT '1.0',
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_spec_company_code UNIQUE (company_id, spec_code)
);

-- 2. KALİTE TEST PARAMETRELERİ (QUALITY PARAMETERS)
CREATE TABLE IF NOT EXISTS quality_parameters (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    specification_id UUID NOT NULL REFERENCES quality_specifications(id) ON DELETE CASCADE,
    parameter_code VARCHAR(50) NOT NULL,
    parameter_name VARCHAR(150) NOT NULL,
    parameter_type VARCHAR(50) NOT NULL DEFAULT 'NUMERIC', -- NUMERIC, BOOLEAN, TEXT
    minimum_value NUMERIC(12,4),
    maximum_value NUMERIC(12,4),
    target_value NUMERIC(12,4),
    uom VARCHAR(20) NOT NULL DEFAULT '%', -- %, Brix, g, count/kg, ppb, °C
    is_critical BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_param_spec_code UNIQUE (specification_id, parameter_code)
);

-- 3. KALİTE MUAYENE KAYITLARI (QUALITY INSPECTIONS)
CREATE TABLE IF NOT EXISTS quality_inspections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    inspection_number VARCHAR(100) NOT NULL,
    inspection_type VARCHAR(50) NOT NULL, 
    -- INCOMING (Giriş/Hasat Kabul), IN_PROCESS (Boylama/İşleme), 
    -- FINAL (Son Kontrol), WAREHOUSE (Depo Rutin), SHIPMENT (Sevkiyat Öncesi)
    
    item_id UUID NOT NULL REFERENCES items(id) ON DELETE RESTRICT,
    lot_id UUID NOT NULL REFERENCES item_lots(id) ON DELETE RESTRICT,
    warehouse_id UUID REFERENCES warehouses(id) ON DELETE SET NULL,
    specification_id UUID REFERENCES quality_specifications(id) ON DELETE SET NULL,
    
    inspection_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    inspector_user_id UUID REFERENCES public.users(id),
    
    result VARCHAR(50) NOT NULL, -- PASS, FAIL, CONDITIONAL, QUARANTINE
    action_taken TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_inspection_company_number UNIQUE (company_id, inspection_number)
);

-- 4. KALİTE MUAYENE NUMUNE / ÖRNEKLEM SONUÇLARI
CREATE TABLE IF NOT EXISTS quality_inspection_samples (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    inspection_id UUID NOT NULL REFERENCES quality_inspections(id) ON DELETE CASCADE,
    parameter_id UUID NOT NULL REFERENCES quality_parameters(id) ON DELETE RESTRICT,
    sample_number INT NOT NULL DEFAULT 1,
    measured_value NUMERIC(12,4),
    text_value TEXT,
    result VARCHAR(20) NOT NULL DEFAULT 'PASS', -- PASS, FAIL
    remarks TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- 5. LOT DURUMUNU MUAYENE SONUCUYLA GÜNCELLEYEN TETİKLEYİCİ
CREATE OR REPLACE FUNCTION sync_lot_quality_status()
RETURNS TRIGGER AS $$
DECLARE
    v_new_lot_status VARCHAR(50);
BEGIN
    -- Muayene sonucuna göre lot durumu belirlenir
    IF NEW.result = 'FAIL' OR NEW.result = 'QUARANTINE' THEN
        v_new_lot_status := 'QUARANTINE';
    ELSIF NEW.result = 'CONDITIONAL' THEN
        v_new_lot_status := 'HOLD';
    ELSIF NEW.result = 'PASS' THEN
        v_new_lot_status := 'APPROVED';
    ELSE
        v_new_lot_status := 'HOLD';
    END IF;

    -- item_lots tablosunu güncelle
    UPDATE item_lots
    SET quality_status = v_new_lot_status,
        updated_at = NOW()
    WHERE id = NEW.lot_id;

    -- Denetim Günlüğü (Audit Log)
    INSERT INTO audit_logs (
        tenant_id, user_id, company_id, action, entity_type, entity_id, new_data
    ) VALUES (
        NEW.tenant_id, NEW.inspector_user_id, NEW.company_id, 'CREATE', 'quality_inspection', NEW.id,
        jsonb_build_object(
            'inspection_number', NEW.inspection_number,
            'inspection_type', NEW.inspection_type,
            'lot_id', NEW.lot_id,
            'result', NEW.result,
            'updated_lot_status', v_new_lot_status,
            'inspection_date', NEW.inspection_date
        )
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS trg_sync_lot_quality_status ON quality_inspections;
CREATE TRIGGER trg_sync_lot_quality_status
AFTER INSERT OR UPDATE OF result ON quality_inspections
FOR EACH ROW EXECUTE FUNCTION sync_lot_quality_status();


-- 6. KARANTİNADAKİ VEYA REDDEDİLEN LOTLARIN ÇIKIŞ ENGELİ
CREATE OR REPLACE FUNCTION prevent_quarantine_lot_issue()
RETURNS TRIGGER AS $$
DECLARE
    v_lot_status VARCHAR(50);
    v_lot_number VARCHAR(100);
BEGIN
    -- Yalnızca çıkış (negatif miktar) hareketlerinde denetlenir
    IF NEW.quantity < 0 AND NEW.lot_id IS NOT NULL THEN
        SELECT quality_status, lot_number INTO v_lot_status, v_lot_number
        FROM item_lots
        WHERE id = NEW.lot_id;

        IF v_lot_status IN ('QUARANTINE', 'REJECTED', 'HOLD') THEN
            RAISE EXCEPTION 'KARANTİNA ÇIKIŞ ENGELİ: "%" numaralı parti/lot şu anda "%" durumundadır! Karantinada, beklemede veya reddedilmiş partilerin satış veya sevkiyat çıkışı kesinlikle yapılamaz.',
                v_lot_number, v_lot_status;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS trg_prevent_quarantine_lot_issue ON stock_ledger_entries;
CREATE TRIGGER trg_prevent_quarantine_lot_issue
BEFORE INSERT ON stock_ledger_entries
FOR EACH ROW EXECUTE FUNCTION prevent_quarantine_lot_issue();


-- 7. KALİTE İZLENEBİLİRLİK GÖRÜNÜMÜ (LOT -> WAREHOUSE -> PROCESS -> SHIPMENT)
CREATE OR REPLACE VIEW view_lot_traceability_quality AS
SELECT 
    l.id AS lot_id,
    l.lot_number,
    l.quality_status AS current_lot_quality_status,
    l.farm_name,
    l.harvest_date,
    l.temperature_control_required,
    l.target_storage_temp_celsius,
    i.item_code,
    i.item_name,
    qi.id AS inspection_id,
    qi.inspection_number,
    qi.inspection_type,
    qi.inspection_date,
    qi.result AS inspection_result,
    qi.warehouse_id,
    w.name AS warehouse_name,
    qi.action_taken,
    qi.notes AS inspection_notes
FROM item_lots l
JOIN items i ON i.id = l.item_id
LEFT JOIN quality_inspections qi ON qi.lot_id = l.id
LEFT JOIN warehouses w ON w.id = qi.warehouse_id;


-- 8. RLS POLİTİKALARI
ALTER TABLE quality_specifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE quality_parameters ENABLE ROW LEVEL SECURITY;
ALTER TABLE quality_inspections ENABLE ROW LEVEL SECURITY;
ALTER TABLE quality_inspection_samples ENABLE ROW LEVEL SECURITY;

ALTER TABLE quality_specifications FORCE ROW LEVEL SECURITY;
ALTER TABLE quality_parameters FORCE ROW LEVEL SECURITY;
ALTER TABLE quality_inspections FORCE ROW LEVEL SECURITY;
ALTER TABLE quality_inspection_samples FORCE ROW LEVEL SECURITY;

CREATE POLICY "quality_specifications_select" ON quality_specifications
    FOR SELECT USING (is_tenant_member(tenant_id) AND has_company_access(company_id));

CREATE POLICY "quality_specifications_manage" ON quality_specifications
    FOR ALL USING (is_tenant_member(tenant_id) AND has_company_access(company_id))
    WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(company_id));

CREATE POLICY "quality_parameters_select" ON quality_parameters
    FOR SELECT USING (is_tenant_member(tenant_id));

CREATE POLICY "quality_parameters_manage" ON quality_parameters
    FOR ALL USING (is_tenant_admin(tenant_id))
    WITH CHECK (is_tenant_admin(tenant_id));

CREATE POLICY "quality_inspections_select" ON quality_inspections
    FOR SELECT USING (is_tenant_member(tenant_id) AND has_company_access(company_id));

CREATE POLICY "quality_inspections_manage" ON quality_inspections
    FOR ALL USING (is_tenant_member(tenant_id) AND has_company_access(company_id))
    WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(company_id));

CREATE POLICY "quality_samples_select" ON quality_inspection_samples
    FOR SELECT USING (is_tenant_member(tenant_id));

CREATE POLICY "quality_samples_manage" ON quality_inspection_samples
    FOR ALL USING (is_tenant_member(tenant_id))
    WITH CHECK (is_tenant_member(tenant_id));

CREATE INDEX IF NOT EXISTS idx_quality_inspections_lot ON quality_inspections(lot_id);
CREATE INDEX IF NOT EXISTS idx_quality_inspections_type ON quality_inspections(inspection_type);
CREATE INDEX IF NOT EXISTS idx_quality_spec_item ON quality_specifications(item_id);
