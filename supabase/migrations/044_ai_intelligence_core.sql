-- ==============================================================================
-- NAKHL & NAHL — FAZ 24: AI + OCR + INTELLIGENCE BOUNDED CONTEXT
-- Intelligent Document Processing, Classification, Suggestions & Human-in-the-Loop
-- ==============================================================================

-- 1. AI OCR EXTRACTIONS (Faturalar ve Ticari Belgeler İçin Taslak Çıkarım Motoru)
-- KURAL: OCR sonucu doğrudan POST edilemez! Her zaman DRAFT_SUGGESTION olarak başlar.
CREATE TABLE IF NOT EXISTS ai_ocr_extractions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    document_id UUID REFERENCES documents(id) ON DELETE SET NULL,
    image_storage_ref TEXT,
    
    -- Çıkarılan Alanlar (Öneri)
    extracted_invoice_number VARCHAR(100),
    extracted_date DATE,
    extracted_supplier_name VARCHAR(255),
    extracted_customer_name VARCHAR(255),
    extracted_product_name VARCHAR(255),
    extracted_quantity NUMERIC(15,3),
    extracted_price NUMERIC(18,4),
    extracted_tax_rate NUMERIC(5,2),
    extracted_tax_amount NUMERIC(18,4),
    extracted_currency VARCHAR(5) DEFAULT 'SAR',
    raw_ocr_payload JSONB DEFAULT '{}'::jsonb,
    
    -- AI Metrikleri & Denetim
    confidence_score NUMERIC(5,4) NOT NULL DEFAULT 0.0000,
    model_name VARCHAR(100) NOT NULL DEFAULT 'nakhl-ocr-engine',
    model_version VARCHAR(50) NOT NULL DEFAULT 'v2.4',
    
    -- İnsan Onay Durumu (Human-In-The-Loop)
    status VARCHAR(50) NOT NULL DEFAULT 'DRAFT_SUGGESTION' 
        CHECK (status IN ('DRAFT_SUGGESTION', 'APPROVED', 'REJECTED', 'MODIFIED')),
    reviewed_by_user_id UUID REFERENCES public.users(id),
    review_notes TEXT,
    reviewed_at TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. AI DOCUMENT CLASSIFICATIONS (8 Standart Belge Sınıfı)
CREATE TABLE IF NOT EXISTS ai_document_classifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    
    -- Sınıflandırma (8 Sınıf)
    predicted_class VARCHAR(50) NOT NULL 
        CHECK (predicted_class IN ('INVOICE', 'PACKING_LIST', 'CERTIFICATE', 'CUSTOMS', 'TRANSPORT', 'QUALITY', 'HALAL', 'OTHER')),
    confidence_score NUMERIC(5,4) NOT NULL DEFAULT 0.0000,
    secondary_tags JSONB DEFAULT '[]'::jsonb,
    
    -- Model Bilgisi
    model_name VARCHAR(100) NOT NULL DEFAULT 'nakhl-doc-classifier',
    model_version VARCHAR(50) NOT NULL DEFAULT 'v1.5',
    
    -- İnsan Doğrulaması
    verified_by_user_id UUID REFERENCES public.users(id),
    verified_class VARCHAR(50) 
        CHECK (verified_class IN ('INVOICE', 'PACKING_LIST', 'CERTIFICATE', 'CUSTOMS', 'TRANSPORT', 'QUALITY', 'HALAL', 'OTHER')),
    verified_at TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. AI COMMERCIAL SUGGESTIONS (Hesap, Ürün, Cari Eşleme, Anomali ve Tahmin)
CREATE TABLE IF NOT EXISTS ai_commercial_suggestions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    
    suggestion_type VARCHAR(50) NOT NULL 
        CHECK (suggestion_type IN ('ACCOUNT_SUGGESTION', 'PRODUCT_MATCHING', 'PARTY_MATCHING', 'ANOMALY_SUGGESTION', 'FORECAST')),
    target_entity_type VARCHAR(50) NOT NULL, -- INVOICE_LINE, ITEM, PARTY, INVENTORY, HARVEST
    target_entity_id UUID,
    
    -- Öneri İçeriği & Açıklaması
    suggestion_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    explanation_text TEXT,
    confidence_score NUMERIC(5,4) NOT NULL DEFAULT 0.0000,
    
    -- Model Bilgisi
    model_name VARCHAR(100) NOT NULL DEFAULT 'nakhl-commercial-intelligence',
    model_version VARCHAR(50) NOT NULL DEFAULT 'v2.1',
    
    -- İnsan Onayı (Human-in-the-Loop)
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING_HUMAN_REVIEW'
        CHECK (status IN ('PENDING_HUMAN_REVIEW', 'APPROVED', 'REJECTED', 'APPLIED')),
    human_reviewer_user_id UUID REFERENCES public.users(id),
    reviewer_decision_notes TEXT,
    reviewed_at TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. AI AUDIT LOGS (Kapsamlı AI Karar ve İşlem İzleme Tablosu)
CREATE TABLE IF NOT EXISTS ai_audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    action_type VARCHAR(100) NOT NULL, -- OCR_EXTRACTION, CLASSIFICATION, SUGGESTION_APPROVAL, ANOMALY_FLAGGED
    model_name VARCHAR(100) NOT NULL,
    model_version VARCHAR(50) NOT NULL,
    input_reference TEXT,
    output_summary TEXT,
    output_payload JSONB DEFAULT '{}'::jsonb,
    confidence_score NUMERIC(5,4),
    approving_user_id UUID REFERENCES public.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==============================================================================
-- 5. HUMAN-IN-THE-LOOP KORUMA TETİKLEYİCİSİ (Strict Safety Enforcement)
-- Kritik 5 ticari işlem asla insan onayı olmadan gerçekleşemez:
--   1. ACCOUNTING POST
--   2. STOCK POST
--   3. PAYMENT
--   4. EXPORT FINALIZATION
--   5. LEGAL DOCUMENT FINALIZATION
-- ==============================================================================

CREATE OR REPLACE FUNCTION enforce_ai_human_in_the_loop()
RETURNS TRIGGER AS $$
BEGIN
    -- 1. OCR Extractions Koruma
    IF TG_TABLE_NAME = 'ai_ocr_extractions' THEN
        IF NEW.status IN ('APPROVED', 'MODIFIED') AND NEW.reviewed_by_user_id IS NULL THEN
            RAISE EXCEPTION 'GÜVENLİK İHLALİ: OCR sonucu insan onayı olmadan (reviewed_by_user_id) onaylanamaz veya ticari kayda dönüştürülemez!';
        END IF;
        IF NEW.status IN ('APPROVED', 'MODIFIED') AND NEW.reviewed_at IS NULL THEN
            NEW.reviewed_at := NOW();
        END IF;
    END IF;

    -- 2. Commercial Suggestions Koruma
    IF TG_TABLE_NAME = 'ai_commercial_suggestions' THEN
        IF NEW.status IN ('APPROVED', 'APPLIED') AND NEW.human_reviewer_user_id IS NULL THEN
            RAISE EXCEPTION 'GÜVENLİK İHLALİ: Ticari öneri (hesap/stok/muhasebe) insan onayı olmadan (human_reviewer_user_id) uygulanamaz!';
        END IF;
        IF NEW.status IN ('APPROVED', 'APPLIED') AND NEW.reviewed_at IS NULL THEN
            NEW.reviewed_at := NOW();
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_enforce_ocr_human_review ON ai_ocr_extractions;
CREATE TRIGGER trg_enforce_ocr_human_review
BEFORE INSERT OR UPDATE OF status, reviewed_by_user_id ON ai_ocr_extractions
FOR EACH ROW EXECUTE FUNCTION enforce_ai_human_in_the_loop();

DROP TRIGGER IF EXISTS trg_enforce_suggestions_human_review ON ai_commercial_suggestions;
CREATE TRIGGER trg_enforce_suggestions_human_review
BEFORE INSERT OR UPDATE OF status, human_reviewer_user_id ON ai_commercial_suggestions
FOR EACH ROW EXECUTE FUNCTION enforce_ai_human_in_the_loop();

-- Kritik İşlemler Denetim Fonksiyonu (Post, Stock, Payment, Export, Legal)
CREATE OR REPLACE FUNCTION validate_critical_commercial_action(
    p_action_type VARCHAR(100),
    p_human_user_id UUID,
    p_action_notes TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- İnsan kontrolü doğrulama
    IF p_action_type IN (
        'ACCOUNTING_POST',
        'STOCK_POST',
        'PAYMENT',
        'EXPORT_FINALIZATION',
        'LEGAL_DOCUMENT_FINALIZATION'
    ) THEN
        IF p_human_user_id IS NULL THEN
            RAISE EXCEPTION 'KRİTİK TİCARİ İŞLEM ENGELLENDİ: (%) işlemi otonom AI tarafından yürütülemez! İnsan onayı (human_user_id) zorunludur.',
                p_action_type;
        END IF;
    END IF;

    RETURN TRUE;
END;
$$;

-- ==============================================================================
-- 6. PERFORMANS İNDEKSLERİ
-- ==============================================================================
CREATE INDEX IF NOT EXISTS idx_ai_ocr_tenant_company 
    ON ai_ocr_extractions (tenant_id, company_id, status);

CREATE INDEX IF NOT EXISTS idx_ai_classifications_doc 
    ON ai_document_classifications (tenant_id, company_id, document_id, predicted_class);

CREATE INDEX IF NOT EXISTS idx_ai_suggestions_status 
    ON ai_commercial_suggestions (tenant_id, company_id, suggestion_type, status);

CREATE INDEX IF NOT EXISTS idx_ai_audit_logs_action 
    ON ai_audit_logs (tenant_id, company_id, action_type, created_at DESC);

-- ==============================================================================
-- 7. ROW LEVEL SECURITY (Çoklu Kiracı ve Ticari Veri İzolasyonu)
-- ==============================================================================
ALTER TABLE ai_ocr_extractions ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_ocr_extractions FORCE ROW LEVEL SECURITY;

ALTER TABLE ai_document_classifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_document_classifications FORCE ROW LEVEL SECURITY;

ALTER TABLE ai_commercial_suggestions ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_commercial_suggestions FORCE ROW LEVEL SECURITY;

ALTER TABLE ai_audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_audit_logs FORCE ROW LEVEL SECURITY;

-- Politikalar: ai_ocr_extractions
DROP POLICY IF EXISTS "ai_ocr_extractions_select" ON ai_ocr_extractions;
CREATE POLICY "ai_ocr_extractions_select" ON ai_ocr_extractions
    FOR SELECT TO authenticated
    USING (is_tenant_member(tenant_id) AND has_company_access(auth.uid(), company_id));

DROP POLICY IF EXISTS "ai_ocr_extractions_manage" ON ai_ocr_extractions;
CREATE POLICY "ai_ocr_extractions_manage" ON ai_ocr_extractions
    FOR ALL TO authenticated
    USING (is_tenant_member(tenant_id) AND has_company_access(auth.uid(), company_id))
    WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(auth.uid(), company_id));

-- Politikalar: ai_document_classifications
DROP POLICY IF EXISTS "ai_document_classifications_select" ON ai_document_classifications;
CREATE POLICY "ai_document_classifications_select" ON ai_document_classifications
    FOR SELECT TO authenticated
    USING (is_tenant_member(tenant_id) AND has_company_access(auth.uid(), company_id));

DROP POLICY IF EXISTS "ai_document_classifications_manage" ON ai_document_classifications;
CREATE POLICY "ai_document_classifications_manage" ON ai_document_classifications
    FOR ALL TO authenticated
    USING (is_tenant_member(tenant_id) AND has_company_access(auth.uid(), company_id))
    WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(auth.uid(), company_id));

-- Politikalar: ai_commercial_suggestions
DROP POLICY IF EXISTS "ai_commercial_suggestions_select" ON ai_commercial_suggestions;
CREATE POLICY "ai_commercial_suggestions_select" ON ai_commercial_suggestions
    FOR SELECT TO authenticated
    USING (is_tenant_member(tenant_id) AND has_company_access(auth.uid(), company_id));

DROP POLICY IF EXISTS "ai_commercial_suggestions_manage" ON ai_commercial_suggestions;
CREATE POLICY "ai_commercial_suggestions_manage" ON ai_commercial_suggestions
    FOR ALL TO authenticated
    USING (is_tenant_member(tenant_id) AND has_company_access(auth.uid(), company_id))
    WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(auth.uid(), company_id));

-- Politikalar: ai_audit_logs
DROP POLICY IF EXISTS "ai_audit_logs_select" ON ai_audit_logs;
CREATE POLICY "ai_audit_logs_select" ON ai_audit_logs
    FOR SELECT TO authenticated
    USING (is_tenant_member(tenant_id) AND has_company_access(auth.uid(), company_id));

DROP POLICY IF EXISTS "ai_audit_logs_insert" ON ai_audit_logs;
CREATE POLICY "ai_audit_logs_insert" ON ai_audit_logs
    FOR INSERT TO authenticated
    WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(auth.uid(), company_id));
