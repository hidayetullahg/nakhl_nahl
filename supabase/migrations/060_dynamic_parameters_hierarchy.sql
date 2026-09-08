-- ============================================================
-- 060: Hiyerarşik Dinamik Parametre Yönetimi
-- NAKHL & NAHL Global Enterprise ERP
-- USER -> WAREHOUSE -> BUSINESS_UNIT -> BRANCH -> COMPANY -> TENANT -> COUNTRY -> GLOBAL
-- ============================================================

CREATE TABLE IF NOT EXISTS public.parameter_definitions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(100) NOT NULL UNIQUE,
    name VARCHAR(200) NOT NULL,
    domain VARCHAR(50) NOT NULL, -- accounting, inventory, trade, tax, etc.
    data_type VARCHAR(20) NOT NULL DEFAULT 'string', -- string, number, boolean, json, list
    default_value TEXT,
    allowed_values JSONB,
    description TEXT,
    is_required BOOLEAN NOT NULL DEFAULT false,
    is_active BOOLEAN NOT NULL DEFAULT true,
    effective_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.parameter_scoped_values (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parameter_code VARCHAR(100) NOT NULL REFERENCES public.parameter_definitions(code) ON DELETE CASCADE,
    scope VARCHAR(30) NOT NULL, -- 'user', 'warehouse', 'business_unit', 'branch', 'company', 'tenant', 'country', 'global'
    scope_id VARCHAR(100) NOT NULL, -- ID of the target scope entity or 'global'
    value TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_param_scope UNIQUE (parameter_code, scope, scope_id)
);

CREATE INDEX IF NOT EXISTS idx_param_code ON public.parameter_scoped_values(parameter_code);
CREATE INDEX IF NOT EXISTS idx_param_scope ON public.parameter_scoped_values(scope, scope_id);

ALTER TABLE public.parameter_definitions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parameter_scoped_values ENABLE ROW LEVEL SECURITY;

CREATE POLICY p_read_param_defs ON public.parameter_definitions FOR SELECT USING (true);
CREATE POLICY p_write_param_defs ON public.parameter_definitions FOR ALL USING (true);
CREATE POLICY p_param_scoped_values ON public.parameter_scoped_values FOR ALL USING (true);
