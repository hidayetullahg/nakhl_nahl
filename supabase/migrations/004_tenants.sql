-- ==============================================================================
-- NAKHL & NAHL — CORE DATABASE BUILD v1.0
-- Migration: 004_tenants.sql
-- Purpose: Kiracılar (Tenants) ve kiracı abonelikleri (tenant_subscriptions).
-- ==============================================================================

CREATE TABLE IF NOT EXISTS tenants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(50) NOT NULL UNIQUE,
    legal_name VARCHAR(255) NOT NULL,
    display_name VARCHAR(150) NOT NULL,
    country_code VARCHAR(5) NOT NULL DEFAULT 'SA',
    default_currency_code VARCHAR(5) NOT NULL DEFAULT 'SAR',
    default_language_code VARCHAR(5) NOT NULL DEFAULT 'ar',
    default_script_code VARCHAR(5) NOT NULL DEFAULT 'Arab',
    timezone VARCHAR(50) NOT NULL DEFAULT 'Asia/Riyadh',
    status entity_status NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS tenant_subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    plan_id UUID NOT NULL REFERENCES saas_plans(id),
    status subscription_status NOT NULL DEFAULT 'ACTIVE',
    start_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    end_at TIMESTAMPTZ,
    billing_cycle VARCHAR(20) NOT NULL DEFAULT 'MONTHLY', -- MONTHLY, YEARLY
    external_customer_id VARCHAR(100),
    external_subscription_id VARCHAR(100),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
