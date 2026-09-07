-- ==============================================================================
-- NAKHL & NAHL — Supabase Emulation Primitives for Native PostgreSQL 15
-- Provides auth.*, storage.*, and request.jwt.* session claim settings
-- ==============================================================================

-- 0. Create standard Supabase roles
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
    CREATE ROLE anon NOLOGIN;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
    CREATE ROLE authenticated NOLOGIN;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN
    CREATE ROLE service_role NOLOGIN;
  END IF;
END $$;

-- 1. Create auth schema and session resolution functions
CREATE SCHEMA IF NOT EXISTS auth;

CREATE OR REPLACE FUNCTION auth.uid() RETURNS uuid AS $$
BEGIN
  RETURN NULLIF(current_setting('request.jwt.claim.sub', true), '')::uuid;
EXCEPTION WHEN OTHERS THEN
  RETURN NULL;
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION auth.role() RETURNS text AS $$
BEGIN
  RETURN COALESCE(NULLIF(current_setting('request.jwt.claim.role', true), ''), 'authenticated')::text;
EXCEPTION WHEN OTHERS THEN
  RETURN 'authenticated';
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION auth.jwt() RETURNS jsonb AS $$
BEGIN
  RETURN COALESCE(NULLIF(current_setting('request.jwt.claims', true), '')::jsonb, '{}'::jsonb);
EXCEPTION WHEN OTHERS THEN
  RETURN '{}'::jsonb;
END;
$$ LANGUAGE plpgsql STABLE;

-- Helper to set authenticated user session in tests
CREATE OR REPLACE FUNCTION auth.set_session(p_user_id uuid, p_tenant_id text, p_role text DEFAULT 'authenticated')
RETURNS void AS $$
BEGIN
  PERFORM set_config('request.jwt.claim.sub', p_user_id::text, false);
  PERFORM set_config('request.jwt.claim.role', p_role, false);
  PERFORM set_config('request.jwt.claims', jsonb_build_object(
    'sub', p_user_id::text,
    'role', p_role,
    'tenant_id', p_tenant_id
  )::text, false);
END;
$$ LANGUAGE plpgsql;

-- 2. Create storage schema and objects
CREATE SCHEMA IF NOT EXISTS storage;

CREATE TABLE IF NOT EXISTS storage.buckets (
  id text PRIMARY KEY,
  name text NOT NULL,
  owner uuid,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  public boolean DEFAULT false
);

CREATE TABLE IF NOT EXISTS storage.objects (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  bucket_id text REFERENCES storage.buckets(id),
  name text,
  owner uuid,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  last_accessed_at timestamptz DEFAULT now(),
  metadata jsonb,
  path_tokens text[] GENERATED ALWAYS AS (string_to_array(name, '/')) STORED
);

CREATE OR REPLACE FUNCTION storage.foldername(name text)
RETURNS text[] AS $$
  SELECT string_to_array(name, '/');
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION storage.filename(name text)
RETURNS text AS $$
  SELECT split_part(name, '/', array_length(string_to_array(name, '/'), 1));
$$ LANGUAGE sql IMMUTABLE;
