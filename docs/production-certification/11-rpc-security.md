# 11 — RPC Penetration Test & Parameter Spoofing Audit

**TEST ID:** CERT-RPC-11  
**DATE:** 2026-09-06  
**ENVIRONMENT:** macOS 12.7.6 x86_64 / Flutter 3.19.6 / Dart 3.3.4  
**COMMAND:** AST Audit & RPC Guardrail Verification (`051_master_directive_hardening.sql`)  
**INPUT:** USER_A invoking financial RPCs (`create_sales_invoice_atomic`, `get_paginated_invoices_optimized`) with `p_tenant_id = TENANT_B`  
**EXPECTED RESULT:** Execution halted with SQL exception `42501 (Access Denied)`.  
**ACTUAL RESULT:** Verified in SQL definition via `verify_rpc_tenant_access()`. Live DB test pending.  
**PASS/FAIL:** ❌ NOT VERIFIED (LIVE DB PEN-TEST PENDING)  

## RPC Defense Implementation
```sql
CREATE OR REPLACE FUNCTION get_paginated_invoices_optimized(
    p_tenant_id UUID,
    p_company_id UUID, ...
) ... AS $$
BEGIN
    PERFORM verify_rpc_tenant_access(p_tenant_id, p_company_id);
    -- Proceed with query
END;
$$;
```
The RPC cannot be executed by spoofing client parameters because `verify_rpc_tenant_access()` checks the caller's actual session membership.
