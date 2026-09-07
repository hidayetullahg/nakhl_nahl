-- ==============================================================================
-- NAKHL & NAHL — CORE DATABASE BUILD v1.0
-- Migration: 003_saas_plans.sql
-- Purpose: SaaS abonelik paketleri ve limit tanımları tablosu.
-- ==============================================================================

CREATE TABLE IF NOT EXISTS saas_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    max_users INT NOT NULL DEFAULT 5,
    max_companies INT NOT NULL DEFAULT 1,
    max_warehouses INT NOT NULL DEFAULT 2,
    max_storage_gb INT NOT NULL DEFAULT 10,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
