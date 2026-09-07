# 09 — Privilege Escalation & Profile Tampering Tests

**TEST ID:** CERT-ROLE-09  
**DATE:** 2026-09-06  
**ENVIRONMENT:** macOS 12.7.6 x86_64 / Flutter 3.19.6 / Dart 3.3.4  
**COMMAND:** Policy analysis of `public.users` in `051_master_directive_hardening.sql`  
**INPUT:** Standard USER attempting to UPDATE `role = 'SUPER_ADMIN'`, `is_owner = TRUE`, or change `tenant_id`  
**EXPECTED RESULT:** REJECTED by RLS UPDATE policy or database trigger.  
**ACTUAL RESULT:** Policies `users_self_update` and column immutability triggers restrict modifications. Live DB test pending.  
**PASS/FAIL:** ❌ NOT VERIFIED (LIVE DB EXECUTION PENDING)  

## Policy Definition
```sql
CREATE POLICY "users_self_update" ON public.users
    FOR UPDATE USING (auth_user_id = auth.uid() OR id = auth.uid())
    WITH CHECK (auth_user_id = auth.uid() OR id = auth.uid());
```
In conjunction with `013_roles_and_permissions.sql`, role assignment is restricted to `tenant_admin` via dedicated RPC `assign_user_role()`.
