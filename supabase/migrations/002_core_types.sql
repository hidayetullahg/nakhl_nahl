-- ==============================================================================
-- NAKHL & NAHL — CORE DATABASE BUILD v1.0
-- Migration: 002_core_types.sql
-- Purpose: Genel sistem durumları ve temel enum tiplerini tanımlar.
-- ==============================================================================

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'entity_status') THEN
        CREATE TYPE entity_status AS ENUM ('ACTIVE', 'PASSIVE', 'SUSPENDED', 'ARCHIVED');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'subscription_status') THEN
        CREATE TYPE subscription_status AS ENUM ('TRIAL', 'ACTIVE', 'PAST_DUE', 'CANCELED', 'EXPIRED');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'membership_status') THEN
        CREATE TYPE membership_status AS ENUM ('INVITED', 'ACTIVE', 'SUSPENDED', 'TERMINATED');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'company_access_level') THEN
        CREATE TYPE company_access_level AS ENUM ('VIEW', 'OPERATE', 'MANAGE', 'ADMIN');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'warehouse_type_enum') THEN
        CREATE TYPE warehouse_type_enum AS ENUM (
            'RAW_MATERIAL',
            'FINISHED_GOODS',
            'COLD_STORAGE',
            'FREEZER',
            'PACKAGING',
            'QUARANTINE',
            'WASTE',
            'TRANSIT',
            'BONDED'
        );
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'audit_action_enum') THEN
        CREATE TYPE audit_action_enum AS ENUM (
            'CREATE',
            'UPDATE',
            'DELETE',
            'POST',
            'APPROVE',
            'REJECT',
            'REVERSE',
            'LOGIN',
            'LOGOUT',
            'EXPORT',
            'IMPORT'
        );
    END IF;
END $$;
