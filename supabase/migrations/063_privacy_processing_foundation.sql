-- ============================================================================
-- 063: Privacy processing foundation (KVKK / GDPR / PDPL)
-- Templates are editable by compliance administrators. Legal approval remains
-- the responsibility of the tenant's legal or compliance advisor.
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.privacy_notice_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    country_code VARCHAR(2) NOT NULL REFERENCES public.countries(code),
    framework_code VARCHAR(20) NOT NULL, -- KVKK, GDPR, PDPL
    title VARCHAR(200) NOT NULL,
    body TEXT NOT NULL,
    version VARCHAR(50) NOT NULL,
    legal_approval_status VARCHAR(30) NOT NULL DEFAULT 'PENDING',
    legal_approved_at TIMESTAMPTZ,
    legal_approved_by UUID,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_privacy_notice_version
        UNIQUE (tenant_id, country_code, framework_code, version)
);

CREATE TABLE IF NOT EXISTS public.person_privacy_processing (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    subject_type VARCHAR(30) NOT NULL, -- PARTY, PARTY_CONTACT, EMPLOYEE, CRM_NOTE
    subject_id UUID NOT NULL,
    legal_basis VARCHAR(40) NOT NULL, -- CONTRACT_NECESSITY, EXPLICIT_CONSENT
    notice_template_id UUID REFERENCES public.privacy_notice_templates(id),
    notice_informed_at TIMESTAMPTZ NOT NULL,
    consent_given BOOLEAN NOT NULL DEFAULT FALSE,
    consent_given_at TIMESTAMPTZ,
    retention_ends_at TIMESTAMPTZ NOT NULL,
    recorded_by UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT ck_privacy_legal_basis CHECK (
        legal_basis IN ('CONTRACT_NECESSITY', 'EXPLICIT_CONSENT')
    ),
    CONSTRAINT ck_privacy_consent_consistency CHECK (
        (legal_basis = 'EXPLICIT_CONSENT' AND consent_given AND consent_given_at IS NOT NULL)
        OR (legal_basis = 'CONTRACT_NECESSITY' AND NOT consent_given AND consent_given_at IS NULL)
    )
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_privacy_processing_subject_basis
    ON public.person_privacy_processing(tenant_id, subject_type, subject_id, legal_basis);

CREATE TABLE IF NOT EXISTS public.data_subject_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    subject_type VARCHAR(30) NOT NULL,
    subject_id UUID NOT NULL,
    request_type VARCHAR(30) NOT NULL, -- ACCESS, RECTIFICATION, ERASURE
    status VARCHAR(30) NOT NULL DEFAULT 'RECEIVED',
    requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    resolved_at TIMESTAMPTZ,
    requested_by UUID,
    resolved_by UUID,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_privacy_processing_subject
    ON public.person_privacy_processing(tenant_id, subject_type, subject_id);
CREATE INDEX IF NOT EXISTS idx_data_subject_requests_subject
    ON public.data_subject_requests(tenant_id, subject_type, subject_id);

ALTER TABLE public.cariler
    ADD COLUMN IF NOT EXISTS privacy_legal_basis VARCHAR(40),
    ADD COLUMN IF NOT EXISTS privacy_notice_informed_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS privacy_consent_given BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS privacy_consent_given_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS privacy_retention_ends_at TIMESTAMPTZ;

ALTER TABLE public.privacy_notice_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.privacy_notice_templates FORCE ROW LEVEL SECURITY;
ALTER TABLE public.person_privacy_processing ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.person_privacy_processing FORCE ROW LEVEL SECURITY;
ALTER TABLE public.data_subject_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.data_subject_requests FORCE ROW LEVEL SECURITY;

CREATE POLICY privacy_notice_templates_tenant ON public.privacy_notice_templates
    FOR ALL USING (is_tenant_member(tenant_id))
    WITH CHECK (is_tenant_member(tenant_id));
CREATE POLICY person_privacy_processing_tenant ON public.person_privacy_processing
    FOR ALL USING (is_tenant_member(tenant_id))
    WITH CHECK (is_tenant_member(tenant_id));
CREATE POLICY data_subject_requests_tenant ON public.data_subject_requests
    FOR ALL USING (is_tenant_member(tenant_id))
    WITH CHECK (is_tenant_member(tenant_id));

-- Every new personal-data-bearing cari record must carry a completed
-- processing record. This prevents bypassing the UI through direct API calls.
CREATE OR REPLACE FUNCTION public.require_cari_privacy_processing()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.privacy_legal_basis NOT IN ('CONTRACT_NECESSITY', 'EXPLICIT_CONSENT')
       OR NEW.privacy_notice_informed_at IS NULL
       OR NEW.privacy_retention_ends_at IS NULL
       OR NEW.privacy_retention_ends_at <= NOW()
       OR (NEW.privacy_legal_basis = 'EXPLICIT_CONSENT'
           AND (NOT NEW.privacy_consent_given OR NEW.privacy_consent_given_at IS NULL))
       OR (NEW.privacy_legal_basis = 'CONTRACT_NECESSITY'
           AND (NEW.privacy_consent_given OR NEW.privacy_consent_given_at IS NOT NULL)) THEN
        RAISE EXCEPTION 'PRIVACY_PROCESSING_REQUIRED: cari kaydı için geçerli aydınlatma/işleme kaydı zorunludur';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_z_require_cari_privacy_processing ON public.cariler;
CREATE TRIGGER trg_z_require_cari_privacy_processing
    BEFORE INSERT OR UPDATE ON public.cariler
    FOR EACH ROW EXECUTE FUNCTION public.require_cari_privacy_processing();