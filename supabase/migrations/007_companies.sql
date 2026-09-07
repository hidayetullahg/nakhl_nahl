-- ==============================================================================
-- NAKHL & NAHL — CORE DATABASE BUILD v1.0
-- Migration: 007_companies.sql
-- Purpose: Tenant'a bağlı tüzel şirketler tablosu.
-- ==============================================================================

CREATE TABLE IF NOT EXISTS companies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    code VARCHAR(50) NOT NULL,
    legal_name VARCHAR(255) NOT NULL,
    trade_name VARCHAR(150),
    tax_number VARCHAR(50),
    registration_number VARCHAR(50),
    country_code VARCHAR(5) NOT NULL DEFAULT 'SA',
    currency_code VARCHAR(5) NOT NULL DEFAULT 'SAR',
    timezone VARCHAR(50) NOT NULL DEFAULT 'Asia/Riyadh',
    status entity_status NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_company_tenant_code UNIQUE (tenant_id, code)
);
