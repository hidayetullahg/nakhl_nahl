-- ==============================================================================
-- NAKHL & NAHL — MIGRATION 038: HALAL COMPLIANCE BOUNDED CONTEXT (FAZ 18)
-- Purpose:
-- 1. halal_certificates: Scope, Status validation & Expired Certificate blocking trigger
-- 2. is_halal_certificate_valid(): Expiry-aware validation function
-- 3. items & item_lots: Halal requirement and lot traceability links
-- 4. supplier_halal_compliance: Supplier halal status tracking
-- 5. facility_halal_certifications: Facility and process-step certification tracking
-- 6. shipment_halal_documents: Export/Shipment halal certificate and permit associations
-- 7. halal_ai_advisories: AI recommendation/risk advisories with enforced Human Decision
-- 8. trg_audit_halal_certificates: Audit logging for all halal certificate mutations
-- ==============================================================================

-- 1. HALAL CERTIFICATES SCHEMA EXTENSIONS
ALTER TABLE halal_certificates ADD COLUMN IF NOT EXISTS scope_description TEXT;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_halal_certificates_status'
    ) THEN
        ALTER TABLE halal_certificates 
        ADD CONSTRAINT chk_halal_certificates_status 
        CHECK (status IN ('VALID', 'ACTIVE', 'EXPIRED', 'REVOKED', 'SUSPENDED', 'UNDER_RENEWAL'));
    END IF;
END $$;

-- Süresi Dolan Sertifikaların Asla VALID/ACTIVE Olarak Kaydedilememesi Tetikleyicisi
CREATE OR REPLACE FUNCTION enforce_halal_certificate_expiry()
RETURNS TRIGGER AS $$
BEGIN
    -- Geçerlilik bitiş tarihi bugünden önceyse, VALID veya ACTIVE olamaz
    IF NEW.expiry_date < CURRENT_DATE AND NEW.status IN ('VALID', 'ACTIVE') THEN
        RAISE EXCEPTION 'SÜRESİ DOLMUŞ SERTİFİKA ENGELİ: Geçerlilik tarihi (%) geçmiş olan % numaralı helal sertifikası VALID veya ACTIVE olarak kabul edilemez! Durum EXPIRED veya SUSPENDED olmalıdır.',
            NEW.expiry_date, NEW.certificate_number;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_enforce_halal_certificate_expiry ON halal_certificates;
CREATE TRIGGER trg_enforce_halal_certificate_expiry
BEFORE INSERT OR UPDATE OF expiry_date, status ON halal_certificates
FOR EACH ROW EXECUTE FUNCTION enforce_halal_certificate_expiry();


-- Sertifikanın geçerlilik durumunu tek noktadan doğrulayan fonksiyon
CREATE OR REPLACE FUNCTION is_halal_certificate_valid(p_cert_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_is_valid BOOLEAN;
BEGIN
    SELECT (status IN ('VALID', 'ACTIVE') AND expiry_date >= CURRENT_DATE)
    INTO v_is_valid
    FROM halal_certificates
    WHERE id = p_cert_id;

    RETURN COALESCE(v_is_valid, FALSE);
END;
$$ LANGUAGE plpgsql STABLE;


-- 2. PRODUCT & LOT BAZLI HELAL UYGUNLUK & İZLENEBİLİRLİK
ALTER TABLE items ADD COLUMN IF NOT EXISTS halal_required BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE items ADD COLUMN IF NOT EXISTS halal_scope_notes TEXT;

ALTER TABLE item_lots ADD COLUMN IF NOT EXISTS halal_certificate_id UUID REFERENCES halal_certificates(id) ON DELETE SET NULL;
ALTER TABLE item_lots ADD COLUMN IF NOT EXISTS halal_compliance_status VARCHAR(50) DEFAULT 'PENDING';

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_item_lots_halal_status'
    ) THEN
        ALTER TABLE item_lots 
        ADD CONSTRAINT chk_item_lots_halal_status 
        CHECK (halal_compliance_status IN ('COMPLIANT', 'NON_COMPLIANT', 'EXEMPT', 'PENDING', 'EXPIRED'));
    END IF;
END $$;

CREATE OR REPLACE VIEW halal_lot_compliance AS
SELECT 
    id,
    tenant_id,
    company_id,
    id AS lot_id,
    halal_certificate_id AS certificate_id,
    halal_compliance_status AS compliance_status,
    created_at,
    created_at AS updated_at
FROM item_lots;

-- 3. TEDARİKÇİ HELAL UYGUNLUK (SUPPLIER HALAL COMPLIANCE)
CREATE TABLE IF NOT EXISTS supplier_halal_compliance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    supplier_party_id UUID NOT NULL REFERENCES parties(id) ON DELETE CASCADE,
    certificate_id UUID REFERENCES halal_certificates(id) ON DELETE SET NULL,
    compliance_status VARCHAR(50) NOT NULL DEFAULT 'COMPLIANT',
    audit_date DATE,
    valid_until DATE NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_supplier_halal_status CHECK (compliance_status IN ('COMPLIANT', 'NON_COMPLIANT', 'EXPIRED', 'PENDING_AUDIT')),
    CONSTRAINT uq_supplier_party_cert UNIQUE (supplier_party_id, certificate_id)
);


-- 4. TESİS VE PROSES HELAL SERTİFİKALANDIRMA (FACILITY & PROCESS COMPLIANCE)
CREATE TABLE IF NOT EXISTS facility_halal_certifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    business_unit_id UUID NOT NULL REFERENCES business_units(id) ON DELETE CASCADE,
    certificate_id UUID NOT NULL REFERENCES halal_certificates(id) ON DELETE CASCADE,
    process_step VARCHAR(100) NOT NULL, -- ALL, SORTING, WASHING, FUMIGATION, DRYING, PITTING, PACKAGING, STORAGE
    is_halal_certified BOOLEAN NOT NULL DEFAULT TRUE,
    verified_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    inspector_name VARCHAR(150),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_facility_process_cert UNIQUE (business_unit_id, certificate_id, process_step)
);


-- 5. SEVKİYAT HELAL BELGELERİ (SHIPMENT HALAL DOCUMENTS)
CREATE TABLE IF NOT EXISTS shipment_halal_documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    sales_order_id UUID REFERENCES sales_orders(id) ON DELETE SET NULL,
    certificate_id UUID NOT NULL REFERENCES halal_certificates(id) ON DELETE CASCADE,
    document_type VARCHAR(50) NOT NULL, -- BATCH_HALAL_CERTIFICATE, SMIIC_EXPORT_PERMIT, CERTIFICATE_OF_ANALYSIS, HALAL_DECLARATION
    document_number VARCHAR(100) NOT NULL,
    issued_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    document_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_shipment_doc_type CHECK (document_type IN ('BATCH_HALAL_CERTIFICATE', 'SMIIC_EXPORT_PERMIT', 'CERTIFICATE_OF_ANALYSIS', 'HALAL_DECLARATION'))
);


-- 6. AI ÖNERİ / UYARI & İNSAN NİHAİ KARARI (AI ADVISORIES & HUMAN DECISION)
CREATE TABLE IF NOT EXISTS halal_ai_advisories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    target_type VARCHAR(50) NOT NULL CHECK (target_type IN ('LOT', 'PRODUCT', 'SUPPLIER', 'PROCESS', 'SHIPMENT')),
    target_id UUID NOT NULL,
    risk_score NUMERIC(5,2) NOT NULL DEFAULT 0.0, -- 0.00 ile 100.00 arası risk skoru
    ai_recommendation_text TEXT NOT NULL,
    ai_flags JSONB DEFAULT '[]'::jsonb,
    
    -- Nihai İnsan Kararı: AI asla nihai karar veremez!
    human_decision VARCHAR(50) NOT NULL DEFAULT 'PENDING' CHECK (human_decision IN ('PENDING', 'APPROVED', 'REJECTED', 'CONDITIONAL')),
    human_reviewer_user_id UUID REFERENCES public.users(id),
    human_decision_notes TEXT,
    decided_at TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- AI Karar Kuralı Tetikleyicisi:
-- Nihai karar (APPROVED/REJECTED/CONDITIONAL) verilirken yetkili insan denetçi zorunludur!
CREATE OR REPLACE FUNCTION enforce_halal_human_decision()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.human_decision IN ('APPROVED', 'REJECTED', 'CONDITIONAL') THEN
        IF NEW.human_reviewer_user_id IS NULL THEN
            RAISE EXCEPTION 'HALAL NİHAİ KARAR KURALI: Helal uygunluk nihai kararı (%) yalnızca yetkili bir insan denetçi tarafından verilebilir (human_reviewer_user_id zorunludur)! AI otonom onay veremez.',
                NEW.human_decision;
        END IF;
        
        IF NEW.decided_at IS NULL THEN
            NEW.decided_at := NOW();
        END IF;
    ELSIF NEW.human_decision = 'PENDING' THEN
        NEW.decided_at := NULL;
    END IF;

    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_enforce_halal_human_decision ON halal_ai_advisories;
CREATE TRIGGER trg_enforce_halal_human_decision
BEFORE INSERT OR UPDATE OF human_decision, human_reviewer_user_id ON halal_ai_advisories
FOR EACH ROW EXECUTE FUNCTION enforce_halal_human_decision();


-- 7. AUDIT LOGGING: SERTİFİKA DEĞİŞİKLİKLERİNİ DENETLE
CREATE OR REPLACE FUNCTION audit_halal_certificates()
RETURNS TRIGGER AS $$
DECLARE
    v_action audit_action_enum;
    v_tenant UUID;
    v_company UUID;
    v_id UUID;
    v_old JSONB := NULL;
    v_new JSONB := NULL;
BEGIN
    IF TG_OP = 'INSERT' THEN
        v_action := 'CREATE';
        v_tenant := NEW.tenant_id;
        v_company := NEW.company_id;
        v_id := NEW.id;
        v_new := to_jsonb(NEW);
    ELSIF TG_OP = 'UPDATE' THEN
        v_action := 'UPDATE';
        v_tenant := NEW.tenant_id;
        v_company := NEW.company_id;
        v_id := NEW.id;
        v_old := to_jsonb(OLD);
        v_new := to_jsonb(NEW);
    ELSIF TG_OP = 'DELETE' THEN
        v_action := 'DELETE';
        v_tenant := OLD.tenant_id;
        v_company := OLD.company_id;
        v_id := OLD.id;
        v_old := to_jsonb(OLD);
    END IF;

    INSERT INTO audit_logs (
        tenant_id,
        company_id,
        action,
        entity_type,
        entity_id,
        old_data,
        new_data
    ) VALUES (
        v_tenant,
        v_company,
        v_action,
        'halal_certificate',
        v_id,
        v_old,
        v_new
    );

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS trg_audit_halal_certificates ON halal_certificates;
CREATE TRIGGER trg_audit_halal_certificates
AFTER INSERT OR UPDATE OR DELETE ON halal_certificates
FOR EACH ROW EXECUTE FUNCTION audit_halal_certificates();


-- 8. İNDEKSLER
CREATE INDEX IF NOT EXISTS idx_supplier_halal_status ON supplier_halal_compliance(supplier_party_id, compliance_status);
CREATE INDEX IF NOT EXISTS idx_facility_halal_unit ON facility_halal_certifications(business_unit_id, process_step);
CREATE INDEX IF NOT EXISTS idx_shipment_halal_so ON shipment_halal_documents(sales_order_id);
CREATE INDEX IF NOT EXISTS idx_halal_ai_target ON halal_ai_advisories(target_type, target_id, human_decision);
CREATE INDEX IF NOT EXISTS idx_item_lots_halal_cert ON item_lots(halal_certificate_id);


-- 9. ROW LEVEL SECURITY (RLS)
ALTER TABLE supplier_halal_compliance ENABLE ROW LEVEL SECURITY;
ALTER TABLE facility_halal_certifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE shipment_halal_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE halal_ai_advisories ENABLE ROW LEVEL SECURITY;

ALTER TABLE supplier_halal_compliance FORCE ROW LEVEL SECURITY;
ALTER TABLE facility_halal_certifications FORCE ROW LEVEL SECURITY;
ALTER TABLE shipment_halal_documents FORCE ROW LEVEL SECURITY;
ALTER TABLE halal_ai_advisories FORCE ROW LEVEL SECURITY;

-- Politikalar: supplier_halal_compliance
DROP POLICY IF EXISTS "supplier_halal_select" ON supplier_halal_compliance;
CREATE POLICY "supplier_halal_select" ON supplier_halal_compliance
    FOR SELECT USING (is_tenant_member(tenant_id) AND has_company_access(company_id));

DROP POLICY IF EXISTS "supplier_halal_manage" ON supplier_halal_compliance;
CREATE POLICY "supplier_halal_manage" ON supplier_halal_compliance
    FOR ALL USING (is_tenant_member(tenant_id) AND has_company_access(company_id))
    WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(company_id));

-- Politikalar: facility_halal_certifications
DROP POLICY IF EXISTS "facility_halal_select" ON facility_halal_certifications;
CREATE POLICY "facility_halal_select" ON facility_halal_certifications
    FOR SELECT USING (is_tenant_member(tenant_id) AND has_company_access(company_id));

DROP POLICY IF EXISTS "facility_halal_manage" ON facility_halal_certifications;
CREATE POLICY "facility_halal_manage" ON facility_halal_certifications
    FOR ALL USING (is_tenant_member(tenant_id) AND has_company_access(company_id))
    WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(company_id));

-- Politikalar: shipment_halal_documents
DROP POLICY IF EXISTS "shipment_halal_select" ON shipment_halal_documents;
CREATE POLICY "shipment_halal_select" ON shipment_halal_documents
    FOR SELECT USING (is_tenant_member(tenant_id) AND has_company_access(company_id));

DROP POLICY IF EXISTS "shipment_halal_manage" ON shipment_halal_documents;
CREATE POLICY "shipment_halal_manage" ON shipment_halal_documents
    FOR ALL USING (is_tenant_member(tenant_id) AND has_company_access(company_id))
    WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(company_id));

-- Politikalar: halal_ai_advisories
DROP POLICY IF EXISTS "halal_ai_advisories_select" ON halal_ai_advisories;
CREATE POLICY "halal_ai_advisories_select" ON halal_ai_advisories
    FOR SELECT USING (is_tenant_member(tenant_id) AND has_company_access(company_id));

DROP POLICY IF EXISTS "halal_ai_advisories_manage" ON halal_ai_advisories;
CREATE POLICY "halal_ai_advisories_manage" ON halal_ai_advisories
    FOR ALL USING (is_tenant_member(tenant_id) AND has_company_access(company_id))
    WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(company_id));
