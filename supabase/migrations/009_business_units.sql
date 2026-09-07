-- ==============================================================================
-- NAKHL & NAHL — CORE DATABASE BUILD v1.0
-- Migration: 009_business_units.sql
-- Purpose: İşletme birimleri, tesisler, çiftlikler ve operasyon merkezleri.
-- ==============================================================================

CREATE TABLE IF NOT EXISTS business_units (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    branch_id UUID REFERENCES branches(id) ON DELETE SET NULL,
    parent_id UUID REFERENCES business_units(id) ON DELETE SET NULL,
    code VARCHAR(50) NOT NULL,
    name VARCHAR(150) NOT NULL,
    unit_type VARCHAR(50) NOT NULL DEFAULT 'PLANT', -- FARM, PLANT, PACKAGING_CENTER, REGIONAL_OFFICE
    status entity_status NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_business_unit_company_code UNIQUE (company_id, code)
);
