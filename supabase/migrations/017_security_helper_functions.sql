-- ==============================================================================
-- NAKHL & NAHL — CORE DATABASE BUILD v1.0
-- Migration: 017_security_helper_functions.sql
-- Purpose: RLS için güvenli yardımcı fonksiyonlar (SECURITY DEFINER + search_path).
-- ==============================================================================

-- 1. Mevcut aktif auth kullanıcısının public.users(id) karşılığını döndürür
CREATE OR REPLACE FUNCTION get_current_user_id()
RETURNS UUID AS $$
DECLARE
    v_user_id UUID;
BEGIN
    SELECT id INTO v_user_id
    FROM public.users
    WHERE auth_user_id = auth.uid() OR id = auth.uid()
    LIMIT 1;

    RETURN v_user_id;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- 2. Kullanıcının belirli bir tenant'a aktif üye olup olmadığını doğrular
CREATE OR REPLACE FUNCTION is_tenant_member(p_tenant_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_user_id UUID;
BEGIN
    v_user_id := get_current_user_id();
    IF v_user_id IS NULL THEN
        RETURN FALSE;
    END IF;

    RETURN EXISTS (
        SELECT 1
        FROM tenant_users
        WHERE tenant_id = p_tenant_id
          AND user_id = v_user_id
          AND status = 'ACTIVE'
    );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- 3. Kullanıcının belirli bir tenant'ta ADMIN rolüne sahip olup olmadığını doğrular
CREATE OR REPLACE FUNCTION is_tenant_admin(p_tenant_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_user_id UUID;
BEGIN
    v_user_id := get_current_user_id();
    IF v_user_id IS NULL THEN
        RETURN FALSE;
    END IF;

    RETURN EXISTS (
        SELECT 1
        FROM tenant_users tu
        JOIN roles r ON r.id = tu.role_id
        WHERE tu.tenant_id = p_tenant_id
          AND tu.user_id = v_user_id
          AND tu.status = 'ACTIVE'
          AND (r.code = 'TENANT_ADMIN' OR r.code = 'SUPER_ADMIN')
    );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- 4. Kullanıcının belirli bir şirkete erişim hakkı olup olmadığını kontrol eder
CREATE OR REPLACE FUNCTION has_company_access(p_company_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_user_id UUID;
    v_tenant_id UUID;
BEGIN
    v_user_id := get_current_user_id();
    IF v_user_id IS NULL THEN
        RETURN FALSE;
    END IF;

    SELECT tenant_id INTO v_tenant_id
    FROM companies
    WHERE id = p_company_id;

    IF v_tenant_id IS NULL THEN
        RETURN FALSE;
    END IF;

    -- Eğer kullanıcı tenant admin ise şirkete otomatik tam erişimi vardır
    IF is_tenant_admin(v_tenant_id) THEN
        RETURN TRUE;
    END IF;

    -- Aksi halde user_company_access kaydı aranır
    RETURN EXISTS (
        SELECT 1
        FROM user_company_access
        WHERE company_id = p_company_id
          AND user_id = v_user_id
    );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- Overload for (user_id, company_id) signature
CREATE OR REPLACE FUNCTION has_company_access(p_user_id UUID, p_company_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN has_company_access(p_company_id);
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- 5. Kullanıcının belirli bir izin koduna (Örn: 'INVENTORY.POST') sahip olup olmadığını doğrular
CREATE OR REPLACE FUNCTION has_permission(p_tenant_id UUID, p_permission_code VARCHAR)
RETURNS BOOLEAN AS $$
DECLARE
    v_user_id UUID;
BEGIN
    v_user_id := get_current_user_id();
    IF v_user_id IS NULL THEN
        RETURN FALSE;
    END IF;

    RETURN EXISTS (
        SELECT 1
        FROM tenant_users tu
        JOIN role_permissions rp ON rp.role_id = tu.role_id
        JOIN permissions p ON p.id = rp.permission_id
        WHERE tu.tenant_id = p_tenant_id
          AND tu.user_id = v_user_id
          AND tu.status = 'ACTIVE'
          AND p.code = p_permission_code
    );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;
