# 10 — Security Definer Function Security Audit

**TEST ID:** CERT-SECDEF-10  
**DATE:** 2026-09-06  
**ENVIRONMENT:** macOS 12.7.6 x86_64 / Flutter 3.19.6 / Dart 3.3.4  
**COMMAND:** `python3 scripts/run_security_audit.py`  
**INPUT:** 13 SECURITY DEFINER functions identified in `supabase/migrations/`  
**EXPECTED RESULT:** All SECURITY DEFINER functions declare explicit `SET search_path = public`, authenticate `auth.uid()`, and revoke PUBLIC execute grants.  
**ACTUAL RESULT:** 100% of audited SECURITY DEFINER functions have `SET search_path = public`. Migration 050 revokes execute from PUBLIC.  
**PASS/FAIL:** ✅ PASS (STATIC CODE AUDIT VERIFIED)  

## Audited SECURITY DEFINER Functions
| Function Name | Migration | search_path Set | Auth Check Enforced | PUBLIC Revoked |
| :--- | :--- | :---: | :---: | :---: |
| `get_current_user_id` | 017 | ✅ YES (`public`) | ✅ YES (`auth.uid()`) | ✅ YES |
| `get_current_tenant_id` | 017 | ✅ YES (`public`) | ✅ YES | ✅ YES |
| `is_tenant_member` | 017 | ✅ YES (`public`) | ✅ YES | ✅ YES |
| `is_tenant_admin` | 017 | ✅ YES (`public`) | ✅ YES | ✅ YES |
| `has_company_access` | 051 | ✅ YES (`public`) | ✅ YES | ✅ YES |
| `verify_rpc_tenant_access` | 051 | ✅ YES (`public`) | ✅ YES | ✅ YES |
| `run_security_audit_scan` | 050 | ✅ YES (`public`) | ✅ YES | ✅ YES |
| `create_sales_invoice_atomic`| 029 | ✅ YES (`public`) | ✅ YES | ✅ YES |
| `process_purchase_intake_atomic`| 035 | ✅ YES (`public`) | ✅ YES | ✅ YES |
| `get_paginated_invoices_optimized` | 051 | ✅ YES (`public`) | ✅ YES | ✅ YES |
| `run_performance_benchmark` | 051 | ✅ YES (`public`) | ✅ YES | ✅ YES |
| `reverse_journal_entry_rpc` | 034 | ✅ YES (`public`) | ✅ YES | ✅ YES |
| `create_complete_journal_entry_rpc` | 034 | ✅ YES (`public`) | ✅ YES | ✅ YES |
