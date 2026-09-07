-- ==============================================================================
-- NAKHL & NAHL — CORE DATABASE BUILD v1.0
-- Migration: 012_warehouse_locations.sql
-- Purpose: Depo içi fiziksel lokasyonlar (Koridor, Raf, Kat, Palet/Göz).
-- ==============================================================================

CREATE TABLE IF NOT EXISTS warehouse_locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    warehouse_id UUID NOT NULL REFERENCES warehouses(id) ON DELETE CASCADE,
    parent_location_id UUID REFERENCES warehouse_locations(id) ON DELETE SET NULL,
    code VARCHAR(50) NOT NULL,
    name VARCHAR(150) NOT NULL,
    location_type VARCHAR(50) NOT NULL DEFAULT 'SHELF', -- AISLE, RACK, SHELF, BIN, PALLET_SPOT
    capacity NUMERIC(15,3),
    unit_of_measure VARCHAR(20) DEFAULT 'Kg',
    status entity_status NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_location_warehouse_code UNIQUE (warehouse_id, code)
);
