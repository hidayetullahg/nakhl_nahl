-- ==============================================================================
-- NAKHL & NAHL — CORE DATABASE BUILD v1.0
-- Migration: 018_row_level_security.sql
-- Purpose: Bütün Core tablolarda RLS etkinleştirme ve yetkilendirme politikaları.
-- ==============================================================================

-- 1. Tablolarda RLS Aktifleştirme
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenant_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenant_modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE business_units ENABLE ROW LEVEL SECURITY;
ALTER TABLE departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE warehouses ENABLE ROW LEVEL SECURITY;
ALTER TABLE warehouse_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenant_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_company_access ENABLE ROW LEVEL SECURITY;
ALTER TABLE roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE role_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- 2. TENANTS Politikaları
CREATE POLICY "tenants_select_member" ON tenants
    FOR SELECT USING (is_tenant_member(id));

CREATE POLICY "tenants_update_admin" ON tenants
    FOR UPDATE USING (is_tenant_admin(id))
    WITH CHECK (is_tenant_admin(id));

-- 3. TENANT_MODULES Politikaları
CREATE POLICY "tenant_modules_select" ON tenant_modules
    FOR SELECT USING (is_tenant_member(tenant_id));

CREATE POLICY "tenant_modules_manage_admin" ON tenant_modules
    FOR ALL USING (is_tenant_admin(tenant_id))
    WITH CHECK (is_tenant_admin(tenant_id));

-- 4. COMPANIES Politikaları
CREATE POLICY "companies_select" ON companies
    FOR SELECT USING (has_company_access(id));

CREATE POLICY "companies_insert_admin" ON companies
    FOR INSERT WITH CHECK (is_tenant_admin(tenant_id));

CREATE POLICY "companies_update_admin" ON companies
    FOR UPDATE USING (is_tenant_admin(tenant_id))
    WITH CHECK (is_tenant_admin(tenant_id));

CREATE POLICY "companies_delete_admin" ON companies
    FOR DELETE USING (is_tenant_admin(tenant_id));

-- 5. BRANCHES Politikaları
CREATE POLICY "branches_select" ON branches
    FOR SELECT USING (has_company_access(company_id));

CREATE POLICY "branches_manage_admin" ON branches
    FOR ALL USING (is_tenant_admin(tenant_id))
    WITH CHECK (is_tenant_admin(tenant_id));

-- 6. BUSINESS_UNITS Politikaları
CREATE POLICY "business_units_select" ON business_units
    FOR SELECT USING (has_company_access(company_id));

CREATE POLICY "business_units_manage_admin" ON business_units
    FOR ALL USING (is_tenant_admin(tenant_id))
    WITH CHECK (is_tenant_admin(tenant_id));

-- 7. DEPARTMENTS Politikaları
CREATE POLICY "departments_select" ON departments
    FOR SELECT USING (has_company_access(company_id));

CREATE POLICY "departments_manage_admin" ON departments
    FOR ALL USING (is_tenant_admin(tenant_id))
    WITH CHECK (is_tenant_admin(tenant_id));

-- 8. WAREHOUSES Politikaları
CREATE POLICY "warehouses_select" ON warehouses
    FOR SELECT USING (has_company_access(company_id));

CREATE POLICY "warehouses_insert" ON warehouses
    FOR INSERT WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(company_id));

CREATE POLICY "warehouses_update" ON warehouses
    FOR UPDATE USING (is_tenant_member(tenant_id) AND has_company_access(company_id))
    WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(company_id));

CREATE POLICY "warehouses_delete_admin" ON warehouses
    FOR DELETE USING (is_tenant_admin(tenant_id));

-- 9. WAREHOUSE_LOCATIONS Politikaları
CREATE POLICY "warehouse_locations_select" ON warehouse_locations
    FOR SELECT USING (is_tenant_member(tenant_id));

CREATE POLICY "warehouse_locations_manage" ON warehouse_locations
    FOR ALL USING (is_tenant_member(tenant_id))
    WITH CHECK (is_tenant_member(tenant_id));

-- 10. TENANT_USERS Politikaları
CREATE POLICY "tenant_users_select" ON tenant_users
    FOR SELECT USING (is_tenant_member(tenant_id));

CREATE POLICY "tenant_users_manage_admin" ON tenant_users
    FOR ALL USING (is_tenant_admin(tenant_id))
    WITH CHECK (is_tenant_admin(tenant_id));

-- 11. USER_COMPANY_ACCESS Politikaları
CREATE POLICY "user_company_access_select" ON user_company_access
    FOR SELECT USING (is_tenant_member(tenant_id));

CREATE POLICY "user_company_access_manage_admin" ON user_company_access
    FOR ALL USING (is_tenant_admin(tenant_id))
    WITH CHECK (is_tenant_admin(tenant_id));

-- 12. AUDIT_LOGS Politikaları (Append-Only)
CREATE POLICY "audit_logs_select_admin" ON audit_logs
    FOR SELECT USING (tenant_id IS NOT NULL AND is_tenant_admin(tenant_id));

CREATE POLICY "audit_logs_insert" ON audit_logs
    FOR INSERT WITH CHECK (tenant_id IS NULL OR is_tenant_member(tenant_id));
