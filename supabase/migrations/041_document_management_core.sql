-- ==============================================================================
-- NAKHL & NAHL — MIGRATION 041: DOCUMENT MANAGEMENT BOUNDED CONTEXT (FAZ 21)
-- Purpose:
-- 1. documents: Kurumsal doküman master tablosu (10 doküman tipi, entity bağı, storage ref)
-- 2. document_versions: Doküman versiyon geçmişi (v1, v2, v3)
-- 3. trg_prevent_document_hard_delete: Fiziksel silme engeli
-- 4. document_access_logs: 6 denetim eylemi (UPLOAD, VIEW, DOWNLOAD, REPLACE, APPROVE, REJECT)
-- 5. view_document_expiry_alerts: Süreli belgeler için erken uyarı ve süre sonu tespiti
-- 6. RLS Politikaları ve İndeksler
-- ==============================================================================

-- 1. DOKÜMAN MASTER TABLOSU (DOCUMENTS MASTER)
CREATE TABLE IF NOT EXISTS documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    document_type VARCHAR(50) NOT NULL CHECK (document_type IN (
        'INVOICE',
        'PACKING_LIST',
        'CERTIFICATE',
        'CUSTOMS_DOCUMENT',
        'TRANSPORT_DOCUMENT',
        'HALAL_CERTIFICATE',
        'QUALITY_CERTIFICATE',
        'PURCHASE_DOCUMENT',
        'SALES_DOCUMENT',
        'LEGAL_DOCUMENT'
    )),
    document_number VARCHAR(100) NOT NULL,
    title VARCHAR(200) NOT NULL,
    entity_type VARCHAR(100) NOT NULL, -- INVOICE, LOT, EXPORT_FILE, SHIPMENT, PARTY, QUALITY_INSPECTION, COMPANY
    entity_id UUID NOT NULL,
    issue_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expiry_date DATE,
    status VARCHAR(50) NOT NULL DEFAULT 'DRAFT' CHECK (status IN (
        'DRAFT',
        'PENDING_APPROVAL',
        'APPROVED',
        'REJECTED',
        'EXPIRED',
        'ARCHIVED'
    )),
    storage_reference TEXT NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_size_bytes BIGINT NOT NULL DEFAULT 0,
    mime_type VARCHAR(100) NOT NULL DEFAULT 'application/pdf',
    current_version INT NOT NULL DEFAULT 1,
    is_latest BOOLEAN NOT NULL DEFAULT TRUE,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_by_user_id UUID REFERENCES public.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_doc_company_type_number UNIQUE (company_id, document_type, document_number)
);

-- 2. DOKÜMAN VERSİYONLARI (DOCUMENT VERSIONS & HISTORY)
CREATE TABLE IF NOT EXISTS document_versions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    version_number INT NOT NULL,
    storage_reference TEXT NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_size_bytes BIGINT NOT NULL DEFAULT 0,
    mime_type VARCHAR(100) NOT NULL DEFAULT 'application/pdf',
    change_summary TEXT,
    uploaded_by_user_id UUID REFERENCES public.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_document_version UNIQUE (document_id, version_number)
);

-- 3. DOKÜMAN DOĞRUDAN SİLME ENGELİ (HARD DELETE BLOCK TRIGGER)
CREATE OR REPLACE FUNCTION prevent_document_hard_delete()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'DOKÜMAN SİLME ENGELİ: Kurumsal dokümanlar sistemden doğrudan silinemez! Bunun yerine durum "ARCHIVED" yapılmalı veya "REPLACE" işlemi ile yeni versiyon yüklenmelidir.';
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_prevent_document_hard_delete ON documents;
CREATE TRIGGER trg_prevent_document_hard_delete
BEFORE DELETE ON documents
FOR EACH ROW EXECUTE FUNCTION prevent_document_hard_delete();


-- 4. DOKÜMAN ERİŞİM VE DENETİM İZİ (DOCUMENT ACCESS & AUDIT LOGS)
CREATE TABLE IF NOT EXISTS document_access_logs (
    id BIGSERIAL PRIMARY KEY,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.users(id),
    action VARCHAR(50) NOT NULL CHECK (action IN (
        'UPLOAD',
        'VIEW',
        'DOWNLOAD',
        'REPLACE',
        'APPROVE',
        'REJECT'
    )),
    version_number INT NOT NULL DEFAULT 1,
    ip_address INET,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Doküman Erişim Denetim Fonksiyonu (Audit Logger)
CREATE OR REPLACE FUNCTION log_document_access(
    p_doc_id UUID,
    p_action VARCHAR,
    p_user_id UUID,
    p_notes TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_tenant UUID;
    v_company UUID;
    v_version INT;
    v_log_id BIGINT;
BEGIN
    SELECT tenant_id, company_id, current_version 
    INTO v_tenant, v_company, v_version
    FROM documents 
    WHERE id = p_doc_id;

    IF v_tenant IS NULL THEN
        RAISE EXCEPTION 'Doküman bulunamadı: %', p_doc_id;
    END IF;

    -- document_access_logs tablosuna kaydet
    INSERT INTO document_access_logs (
        tenant_id, company_id, document_id, user_id, action, version_number, notes
    ) VALUES (
        v_tenant, v_company, p_doc_id, p_user_id, p_action, v_version, p_notes
    ) RETURNING id INTO v_log_id;

    -- audit_logs ana güvenlik tablosuna da kaydet
    INSERT INTO audit_logs (
        tenant_id, company_id, user_id, action, entity_type, entity_id, new_data
    ) VALUES (
        v_tenant, v_company, p_user_id, 'CREATE', 'document_access', p_doc_id,
        jsonb_build_object(
            'document_id', p_doc_id,
            'action', p_action,
            'version_number', v_version,
            'notes', p_notes,
            'access_log_id', v_log_id
        )
    );

    RETURN p_doc_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;


-- 5. SÜRELİ BELGELER İÇİN EXPIRY UYARI GÖRÜNÜMÜ
CREATE OR REPLACE VIEW view_document_expiry_alerts AS
SELECT 
    d.id AS document_id,
    d.tenant_id,
    d.company_id,
    d.document_type,
    d.document_number,
    d.title,
    d.entity_type,
    d.entity_id,
    d.issue_date,
    d.expiry_date,
    d.status,
    d.current_version,
    CURRENT_DATE AS evaluation_date,
    (d.expiry_date - CURRENT_DATE) AS days_remaining,
    CASE 
        WHEN d.expiry_date < CURRENT_DATE THEN 'EXPIRED'
        WHEN d.expiry_date <= CURRENT_DATE + INTERVAL '30 days' THEN 'CRITICAL_30_DAYS'
        WHEN d.expiry_date <= CURRENT_DATE + INTERVAL '60 days' THEN 'WARNING_60_DAYS'
        ELSE 'VALID'
    END AS alert_level
FROM documents d
WHERE d.expiry_date IS NOT NULL 
  AND d.status <> 'ARCHIVED';


-- 6. İNDEKSLER
CREATE INDEX IF NOT EXISTS idx_documents_company_type ON documents(company_id, document_type);
CREATE INDEX IF NOT EXISTS idx_documents_entity ON documents(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_documents_expiry ON documents(expiry_date) WHERE expiry_date IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_document_versions_doc ON document_versions(document_id, version_number);
CREATE INDEX IF NOT EXISTS idx_document_access_doc_act ON document_access_logs(document_id, action);


-- 7. ROW LEVEL SECURITY (RLS)
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE document_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE document_access_logs ENABLE ROW LEVEL SECURITY;

ALTER TABLE documents FORCE ROW LEVEL SECURITY;
ALTER TABLE document_versions FORCE ROW LEVEL SECURITY;
ALTER TABLE document_access_logs FORCE ROW LEVEL SECURITY;

-- Politikalar: documents
DROP POLICY IF EXISTS "documents_select" ON documents;
CREATE POLICY "documents_select" ON documents
    FOR SELECT USING (is_tenant_member(tenant_id) AND has_company_access(company_id));

DROP POLICY IF EXISTS "documents_manage" ON documents;
CREATE POLICY "documents_manage" ON documents
    FOR ALL USING (is_tenant_member(tenant_id) AND has_company_access(company_id))
    WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(company_id));

-- Politikalar: document_versions
DROP POLICY IF EXISTS "document_versions_select" ON document_versions;
CREATE POLICY "document_versions_select" ON document_versions
    FOR SELECT USING (is_tenant_member(tenant_id) AND has_company_access(company_id));

DROP POLICY IF EXISTS "document_versions_manage" ON document_versions;
CREATE POLICY "document_versions_manage" ON document_versions
    FOR ALL USING (is_tenant_member(tenant_id) AND has_company_access(company_id))
    WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(company_id));

-- Politikalar: document_access_logs
DROP POLICY IF EXISTS "document_access_logs_select" ON document_access_logs;
CREATE POLICY "document_access_logs_select" ON document_access_logs
    FOR SELECT USING (is_tenant_member(tenant_id) AND has_company_access(company_id));

DROP POLICY IF EXISTS "document_access_logs_insert" ON document_access_logs;
CREATE POLICY "document_access_logs_insert" ON document_access_logs
    FOR INSERT WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(company_id));
