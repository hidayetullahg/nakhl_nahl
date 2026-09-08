-- ============================================================
-- 062: AI Gateway, Providers, Safe Tools & Audit Logs
-- NAKHL & NAHL Global Enterprise ERP
-- Multi-Tenant Security & Isolation
-- ============================================================

-- 1. AI Sağlayıcı Yapılandırmaları (API Keys never in client, managed per tenant/system)
CREATE TABLE IF NOT EXISTS public.ai_provider_configs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES public.tenants(id) ON DELETE CASCADE,
    provider_id VARCHAR(50) NOT NULL, -- 'openai', 'gemini', 'claude', 'deepseek', 'qwen', 'local_ai'
    is_active BOOLEAN NOT NULL DEFAULT true,
    is_default BOOLEAN NOT NULL DEFAULT false,
    priority INT NOT NULL DEFAULT 10,
    model_name VARCHAR(100) NOT NULL,
    temperature NUMERIC(3, 2) DEFAULT 0.2,
    max_tokens INT DEFAULT 4096,
    supports_tools BOOLEAN NOT NULL DEFAULT true,
    supports_vision BOOLEAN NOT NULL DEFAULT false,
    supports_rag BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_tenant_provider UNIQUE (tenant_id, provider_id)
);

-- 2. AI Kullanım ve Maliyet / Kota Takibi
CREATE TABLE IF NOT EXISTS public.ai_usage_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES public.tenants(id) ON DELETE CASCADE,
    user_id UUID,
    provider_id VARCHAR(50) NOT NULL,
    model VARCHAR(100) NOT NULL,
    task_type VARCHAR(50) NOT NULL,
    prompt_tokens INT NOT NULL DEFAULT 0,
    completion_tokens INT NOT NULL DEFAULT 0,
    total_tokens INT NOT NULL DEFAULT 0,
    estimated_cost_usd NUMERIC(10, 6) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ai_usage_tenant ON public.ai_usage_metrics(tenant_id, created_at);

-- 3. AI Güvenlik ve Eylem Denetim Kaydı (Audit Log)
CREATE TABLE IF NOT EXISTS public.ai_action_audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES public.tenants(id) ON DELETE CASCADE,
    user_id UUID,
    action_type VARCHAR(100) NOT NULL, -- 'tool_execution', 'draft_created', 'guidance_requested'
    tool_name VARCHAR(100),
    parameters JSONB,
    result_summary TEXT,
    is_success BOOLEAN NOT NULL DEFAULT true,
    error_message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ai_audit_tenant ON public.ai_action_audit_logs(tenant_id, created_at);

ALTER TABLE public.ai_provider_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_usage_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_action_audit_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY p_ai_prov_config ON public.ai_provider_configs FOR ALL USING (true);
CREATE POLICY p_ai_usage ON public.ai_usage_metrics FOR ALL USING (true);
CREATE POLICY p_ai_audit ON public.ai_action_audit_logs FOR ALL USING (true);
