-- ==============================================================================
-- NAKHL & NAHL — Deterministic Multi-Tenant Seed & Test Fixture Dataset
-- Complies with Sections 4, 7, 8, 9 & 54
-- ==============================================================================

-- 1. SAAS PLANS
INSERT INTO saas_plans (id, code, name, description, max_users, max_companies, max_storage_bytes, is_active)
VALUES 
    ('00000000-0000-0000-0000-000000000001', 'DEMO', 'Demo Plan', 'Time and quota restricted trial tier', 2, 1, 1073741824, TRUE),
    ('00000000-0000-0000-0000-000000000002', 'BASIC', 'Basic ERP', 'Standard accounting and inventory tier', 5, 1, 5368709120, TRUE),
    ('00000000-0000-0000-0000-000000000003', 'PRO', 'Pro ERP', 'Multi-branch commercial tier', 25, 3, 53687091200, TRUE),
    ('00000000-0000-0000-0000-000000000004', 'ENTERPRISE', 'Enterprise Global', 'Unlimited multi-company global ERP', 9999, 999, 1099511627776, TRUE)
ON CONFLICT (id) DO NOTHING;

-- 2. TENANTS (TENANT A & TENANT B)
INSERT INTO tenants (id, name, code, plan_id, status, subscription_expires_at, is_active)
VALUES
    ('a0000000-0000-0000-0000-000000000001', 'Tenant A — Medine Hurma Ltd', 'TENANT_A', '00000000-0000-0000-0000-000000000003', 'ACTIVE', NOW() + INTERVAL '1 year', TRUE),
    ('b0000000-0000-0000-0000-000000000002', 'Tenant B — Riyad Palm Trading Co', 'TENANT_B', '00000000-0000-0000-0000-000000000003', 'ACTIVE', NOW() + INTERVAL '1 year', TRUE)
ON CONFLICT (id) DO NOTHING;

-- 3. USERS (USER A & USER B)
INSERT INTO users (id, auth_user_id, email, full_name, is_active)
VALUES
    ('a1111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', 'user_a@tenant-a.com', 'Ahmet Demir (Tenant A Admin)', TRUE),
    ('b2222222-2222-2222-2222-222222222222', 'b2222222-2222-2222-2222-222222222222', 'user_b@tenant-b.com', 'Bader Al-Saud (Tenant B Admin)', TRUE)
ON CONFLICT (id) DO NOTHING;

-- 4. TENANT USER MEMBERSHIPS
INSERT INTO tenant_users (id, tenant_id, user_id, role, is_active)
VALUES
    ('a1111111-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'a1111111-1111-1111-1111-111111111111', 'TENANT_ADMIN', TRUE),
    ('b2222222-0000-0000-0000-000000000002', 'b0000000-0000-0000-0000-000000000002', 'b2222222-2222-2222-2222-222222222222', 'TENANT_ADMIN', TRUE)
ON CONFLICT (id) DO NOTHING;

-- 5. COMPANIES
INSERT INTO companies (id, tenant_id, name, tax_number, currency_code, is_active)
VALUES
    ('a1000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'Medine Hurma Ticaret A.Ş.', '1234567890', 'SAR', TRUE),
    ('b2000000-0000-0000-0000-000000000002', 'b0000000-0000-0000-0000-000000000002', 'Riyadh Date Logistics LLC', '9876543210', 'SAR', TRUE)
ON CONFLICT (id) DO NOTHING;

-- 6. USER COMPANY ACCESS
INSERT INTO user_company_access (id, tenant_id, user_id, company_id, access_level)
VALUES
    ('a1010101-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'a1111111-1111-1111-1111-111111111111', 'a1000000-0000-0000-0000-000000000001', 'ADMIN'),
    ('b2020202-0000-0000-0000-000000000002', 'b0000000-0000-0000-0000-000000000002', 'b2222222-2222-2222-2222-222222222222', 'b2000000-0000-0000-0000-000000000002', 'ADMIN')
ON CONFLICT (id) DO NOTHING;

-- 7. PARTIES (CARİLER)
INSERT INTO parties (id, tenant_id, company_id, party_type, code, name, is_active)
VALUES
    ('a3000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001', 'CUSTOMER', 'CAR-A01', 'Tenant A Customer — Al-Madina Market', TRUE),
    ('b3000000-0000-0000-0000-000000000002', 'b0000000-0000-0000-0000-000000000002', 'b2000000-0000-0000-0000-000000000002', 'CUSTOMER', 'CAR-B01', 'Tenant B Customer — Gulf Retail Group', TRUE)
ON CONFLICT (id) DO NOTHING;

-- 8. WAREHOUSES & ITEMS
INSERT INTO warehouses (id, tenant_id, company_id, code, name, is_active)
VALUES
    ('a4000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001', 'WH-A01', 'Medine Ana Depo (Soğuk Hava)', TRUE),
    ('b4000000-0000-0000-0000-000000000002', 'b0000000-0000-0000-0000-000000000002', 'b2000000-0000-0000-0000-000000000002', 'WH-B01', 'Riyad Merkez Antrepo', TRUE)
ON CONFLICT (id) DO NOTHING;

INSERT INTO items (id, tenant_id, company_id, code, name, unit_of_measure, is_active)
VALUES
    ('a5000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001', 'ITM-AJWA', 'Acve Hurması 1. Kalite', 'KG', TRUE),
    ('b5000000-0000-0000-0000-000000000002', 'b0000000-0000-0000-0000-000000000002', 'b2000000-0000-0000-0000-000000000002', 'ITM-SUKKARI', 'Sükkari Hurması Premium', 'KG', TRUE)
ON CONFLICT (id) DO NOTHING;
