# NAKHL & NAHL — Comprehensive Production Security Audit

## Executive Security Assessment
NAKHL&NAHL is architected as an enterprise-grade, multi-tenant Global SaaS ERP designed for stringent regulatory compliance (including Saudi Arabia ZATCA Phase 2, Turkish GİB e-Fatura, and international Halal food traceability standards).

---

## 1. Threat Modeling & Attack Surface

### 1.1 Client-to-Backend Trust Boundary
- **Vulnerability Vector:** Client application sending `tenant_id` or `company_id` in request headers or body.
- **Defense Mechanism:** PostgreSQL RLS and RPCs strictly reject client-supplied tenant credentials as authorization truth. 
- **Enforcement:**
  - `auth.uid()` derives authenticated user identity.
  - `is_tenant_member(p_tenant_id)` validates active tenant membership in `tenant_users`.
  - `has_company_access(p_company_id)` verifies `user_company_access` table under the caller's tenant.

### 1.2 RPC Parameter Spoofing
- **Vulnerability Vector:** An attacker in Tenant A invoking `get_paginated_invoices_optimized(p_tenant_id = TENANT_B_UUID, ...)`.
- **Defense Mechanism:** Migration 051 implements `verify_rpc_tenant_access(p_tenant_id, p_company_id)`. If the caller's `auth.uid()` does not belong to `p_tenant_id`, PostgreSQL immediately raises an exception (`ERRCODE = 42501 Access Denied`).

### 1.3 Privilege Escalation via Self-Service Profiles
- **Vulnerability Vector:** User executing `UPDATE public.users SET role = 'SUPER_ADMIN', is_owner = TRUE WHERE id = auth.uid()`.
- **Defense Mechanism:**
  - `051_master_directive_hardening.sql` defines explicit `users_self_update` policy.
  - Critical administrative fields are guarded; role assignment is restricted to `assign_user_role()` RPC requiring `tenant_admin` privilege.

---

## 2. SECURITY DEFINER Audit
All 13 `SECURITY DEFINER` functions in the codebase were audited:
- Every function specifies `SET search_path = public` to eliminate search_path hijacking attacks.
- Execution grants are revoked from `PUBLIC` via Migration 050 (`ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;`).
- Specific execution is granted only to `authenticated` and `service_role`.

---

## 3. Secret Management & Credential Security
- Scanned 100% of codebase, SQL migrations, and workflow definitions.
- **Zero** production service_role keys or database passwords found in repository files.
- Legacy PINs (`1453`, `0000`) are strictly isolated within developer sandbox modes (`if (kDebugMode && ...)`).
