# 08 — Auth Provisioning & Unassociated User Isolation

**TEST ID:** CERT-AUTH-08  
**DATE:** 2026-09-06  
**ENVIRONMENT:** macOS 12.7.6 x86_64 / Flutter 3.19.6 / Dart 3.3.4  
**COMMAND:** `supabase/security_tests/030_comprehensive_security_test_suite.sql` Section 2  
**INPUT:** Valid Supabase Auth User with zero records in `tenant_users` and `user_company_access`  
**EXPECTED RESULT:** User is AUTHENTICATED but NOT PROVISIONED. All ERP queries return empty sets; RPC calls throw `28000/42501`.  
**ACTUAL RESULT:** Policy logic in Migration 018 and 051 enforces strict membership check. Live test pending DB provisioning.  
**PASS/FAIL:** ❌ NOT VERIFIED (LIVE DB EXECUTION PENDING)  

## Architectural Safeguard
```sql
-- Migration 051 verify_rpc_tenant_access()
IF get_current_user_id() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '28000';
END IF;
IF NOT is_tenant_member(p_tenant_id) THEN
    RAISE EXCEPTION 'Access Denied: Caller is not an active member of tenant %', p_tenant_id USING ERRCODE = '42501';
END IF;
```
New users are never given implicit default tenant access or global admin privileges.
