-- ==============================================================================
-- NAKHL & NAHL — CORE DATABASE BUILD v1.0
-- Migration: 015_user_company_access.sql
-- Purpose: Kullanıcının tenant içindeki belirli şirketlere erişim kısıtlaması.
-- ==============================================================================

CREATE TABLE IF NOT EXISTS user_company_access (
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    access_level company_access_level NOT NULL DEFAULT 'VIEW',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, company_id)
);
