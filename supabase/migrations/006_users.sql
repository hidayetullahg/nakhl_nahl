-- ==============================================================================
-- NAKHL & NAHL — CORE DATABASE BUILD v1.0
-- Migration: 006_users.sql
-- Purpose: Public kullanıcı tablosu ve Supabase auth.users ilişkisi.
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    auth_user_id UUID UNIQUE, -- Supabase auth.users(id) ile ilişkilendirilir (eğer Supabase auth açıksa)
    display_name VARCHAR(150) NOT NULL,
    email citext NOT NULL UNIQUE,
    phone VARCHAR(50),
    preferred_language_code VARCHAR(5) NOT NULL DEFAULT 'tr',
    preferred_script_code VARCHAR(5) NOT NULL DEFAULT 'Latn',
    timezone VARCHAR(50) NOT NULL DEFAULT 'UTC',
    status entity_status NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
