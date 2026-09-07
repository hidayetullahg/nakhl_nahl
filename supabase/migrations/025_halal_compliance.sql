-- ==============================================================================
-- NAKHL & NAHL — MIGRATION 025: HELAL UYGUNLUK VE KALİTE YÖNETİMİ
-- Purpose: Helal sertifikaları, kuruluşlar, ürün/parti kapsamı, denetimler ve DÖF
-- ==============================================================================

-- 1. Helal Belgelendirme Kuruluşları (Halal Certification Bodies)
CREATE TABLE IF NOT EXISTS halal_certification_bodies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL, -- GİMDES, SASO, JAKIM, SMIIC, ESMA
    country_code VARCHAR(5) NOT NULL,
    accreditation_details TEXT,
    website VARCHAR(150),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Helal Sertifikaları (Halal Certificates)
CREATE TABLE IF NOT EXISTS halal_certificates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    body_id UUID NOT NULL REFERENCES halal_certification_bodies(id),
    certificate_number VARCHAR(100) NOT NULL,
    standard_reference VARCHAR(100) DEFAULT 'OIC/SMIIC 1:2019',
    issue_date DATE NOT NULL,
    expiry_date DATE NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE', -- ACTIVE, EXPIRED, SUSPENDED, UNDER_RENEWAL
    document_url TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_halal_cert_company UNIQUE (company_id, certificate_number)
);

-- 3. Helal Sertifika Kapsamı (Halal Scope Items & Facilities)
CREATE TABLE IF NOT EXISTS halal_scope_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    certificate_id UUID NOT NULL REFERENCES halal_certificates(id) ON DELETE CASCADE,
    item_id UUID NOT NULL REFERENCES items(id) ON DELETE CASCADE,
    business_unit_id UUID REFERENCES business_units(id) ON DELETE SET NULL, -- Tesis / İşletme
    lot_restriction VARCHAR(100), -- Yalnızca belirli bir lot için kısıt varsa
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_halal_scope UNIQUE (certificate_id, item_id, business_unit_id)
);

-- 4. Helal Denetimleri ve Uygunsuzluklar (Halal Audits & CAPA)
CREATE TABLE IF NOT EXISTS halal_audits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    certificate_id UUID REFERENCES halal_certificates(id) ON DELETE SET NULL,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    business_unit_id UUID REFERENCES business_units(id) ON DELETE SET NULL,
    audit_date DATE NOT NULL,
    lead_auditor VARCHAR(150) NOT NULL,
    audit_type VARCHAR(50) NOT NULL DEFAULT 'ANNUAL_SURVEILLANCE', -- INITIAL, ANNUAL_SURVEILLANCE, UNANNOUNCED, INTERNAL
    result VARCHAR(50) NOT NULL DEFAULT 'PASSED', -- PASSED, CONDITIONAL, FAILED
    non_conformities TEXT,
    capa_plan TEXT, -- Düzeltici / Önleyici Faaliyet
    capa_deadline DATE,
    is_capa_closed BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. Başlangıç Helal Kuruluşları Seed Verisi
INSERT INTO halal_certification_bodies (code, name, country_code, accreditation_details)
VALUES 
    ('GIMDES', 'GİMDES Helal Gıda Denetleme ve Sertifikalama', 'TR', 'WHC (World Halal Council) Akredite'),
    ('SASO', 'Saudi Standards, Metrology and Quality Organization', 'SA', 'KSA Resmi Helal Otoritesi'),
    ('JAKIM', 'Department of Islamic Development Malaysia', 'MY', 'Küresel Referans Akreditasyon'),
    ('SMIIC', 'Standards and Metrology Institute for Islamic Countries', 'TR', 'İslam İşbirliği Teşkilatı Enstitüsü')
ON CONFLICT (code) DO NOTHING;

-- 6. RLS Aktifleştirme
ALTER TABLE halal_certificates ENABLE ROW LEVEL SECURITY;
ALTER TABLE halal_scope_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE halal_audits ENABLE ROW LEVEL SECURITY;

ALTER TABLE halal_certificates FORCE ROW LEVEL SECURITY;
ALTER TABLE halal_scope_items FORCE ROW LEVEL SECURITY;
ALTER TABLE halal_audits FORCE ROW LEVEL SECURITY;

-- 7. RLS Politikaları
CREATE POLICY "halal_certificates_select" ON halal_certificates
    FOR SELECT USING (is_tenant_member(tenant_id) AND has_company_access(company_id));

CREATE POLICY "halal_certificates_manage" ON halal_certificates
    FOR ALL USING (is_tenant_member(tenant_id) AND has_company_access(company_id))
    WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(company_id));

CREATE POLICY "halal_scope_select" ON halal_scope_items
    FOR SELECT USING (is_tenant_member(tenant_id));

CREATE POLICY "halal_scope_manage" ON halal_scope_items
    FOR ALL USING (is_tenant_member(tenant_id))
    WITH CHECK (is_tenant_member(tenant_id));

CREATE POLICY "halal_audits_select" ON halal_audits
    FOR SELECT USING (is_tenant_member(tenant_id) AND has_company_access(company_id));

CREATE POLICY "halal_audits_manage" ON halal_audits
    FOR ALL USING (is_tenant_member(tenant_id) AND has_company_access(company_id))
    WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(company_id));

-- 8. İndeksler
CREATE INDEX IF NOT EXISTS idx_halal_cert_company ON halal_certificates(company_id, status);
CREATE INDEX IF NOT EXISTS idx_halal_scope_item ON halal_scope_items(item_id);
CREATE INDEX IF NOT EXISTS idx_halal_audits_date ON halal_audits(audit_date DESC);
