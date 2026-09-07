-- ==============================================================================
-- NAKHL & NAHL — CORE DATABASE BUILD v1.0
-- Migration: 011_warehouses.sql
-- Purpose: Depolar tablosu (Sıcaklık, helal ve kalite kontrollü).
-- ==============================================================================

CREATE TABLE IF NOT EXISTS warehouses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    branch_id UUID REFERENCES branches(id) ON DELETE SET NULL,
    business_unit_id UUID REFERENCES business_units(id) ON DELETE SET NULL,
    code VARCHAR(50) NOT NULL,
    name VARCHAR(150) NOT NULL,
    warehouse_type warehouse_type_enum NOT NULL DEFAULT 'RAW_MATERIAL',
    address TEXT,
    country_code VARCHAR(5) NOT NULL DEFAULT 'SA',
    temperature_controlled BOOLEAN NOT NULL DEFAULT FALSE,
    min_temperature_celsius NUMERIC(5,2),
    max_temperature_celsius NUMERIC(5,2),
    halal_controlled BOOLEAN NOT NULL DEFAULT TRUE,
    quality_controlled BOOLEAN NOT NULL DEFAULT TRUE,
    status entity_status NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_warehouse_company_code UNIQUE (company_id, code)
);
