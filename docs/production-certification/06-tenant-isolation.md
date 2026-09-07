# 06 — Multi-Tenant Architecture & Data Isolation Model

**TEST ID:** CERT-TENANT-06  
**DATE:** 2026-09-06  
**ENVIRONMENT:** macOS 12.7.6 x86_64 / Flutter 3.19.6 / Dart 3.3.4  
**COMMAND:** Architecture verification of `018_row_level_security.sql` and `051_master_directive_hardening.sql`  
**INPUT:** Security helper functions `is_tenant_member()`, `has_company_access()`, `get_current_tenant_id()`  
**EXPECTED RESULT:** Database-enforced isolation where client-provided `tenant_id` cannot be spoofed.  
**ACTUAL RESULT:** Architectural model fully enforced at the PostgreSQL RLS & RPC boundary.  
**PASS/FAIL:** ✅ PASS (ARCHITECTURE VERIFIED)  

## Security Pipeline
```
USER (JWT auth.uid())
  │
  ▼
SUPABASE AUTH (Validates Token Signature & Expiry)
  │
  ▼
SECURITY DEFINER HELPERS:
  - is_tenant_member(tenant_id) -> verifies tenant_users table
  - has_company_access(company_id) -> verifies user_company_access
  │
  ▼
POSTGRESQL ROW LEVEL SECURITY (RLS)
  │
  ▼
DATABASE ENGINE (Filtered Result Set / Zero Leakage)
```

## Security Rule
- Client claims for `tenant_id` or `company_id` are **never** trusted as authorization credentials.
- All access is validated against internal PostgreSQL tables (`tenant_users`, `user_company_access`) indexed on `auth.uid()`.
