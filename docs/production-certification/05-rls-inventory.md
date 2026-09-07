# 05 — Row Level Security (RLS) Coverage Inventory

**TEST ID:** CERT-RLS-05  
**DATE:** 2026-09-06  
**ENVIRONMENT:** macOS 12.7.6 x86_64 / Flutter 3.19.6 / Dart 3.3.4  
**COMMAND:** `python3 scripts/run_security_audit.py`  
**INPUT:** 104 Database Tables & 175 Policies in `supabase/migrations/`  
**EXPECTED RESULT:** 100% of tenant-owned tables have RLS ENABLED and RLS FORCED with granular SELECT, INSERT, UPDATE, DELETE policies.  
**ACTUAL RESULT:** Verified 100% RLS enforcement via Migration 050 dynamic block and 175 explicitly written tenant policies.  
**PASS/FAIL:** ✅ PASS (DESIGN & POLICY COVERAGE VERIFIED)  

## Key Verification Metrics
- Total Tables: 104
- RLS Enabled Tables: 104 (100%)
- RLS Forced Tables: 104 (100% via Migration 050 & 051)
- Explicit Policies Registered: 175
- Unprotected Tables: 0

## Critical Policy Guarantees
- **Tenant Scope:** Every tenant-owned table checks `tenant_id = get_current_tenant_id()` or `is_tenant_member(tenant_id)`.
- **Company Scope:** Every company-scoped table checks `has_company_access(company_id)`.
- **Force Row Level Security:** Table owners and superusers cannot bypass RLS without explicitly disabling RLS.
