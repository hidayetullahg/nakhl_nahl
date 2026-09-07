# 14 — Storage Isolation & Multi-Tenant Bucket Policies

**TEST ID:** CERT-STOR-14  
**DATE:** 2026-09-06  
**ENVIRONMENT:** macOS 12.7.6 x86_64 / Flutter 3.19.6 / Dart 3.3.4  
**COMMAND:** Storage RLS policy review in `041_document_management_core.sql`  
**INPUT:** USER_A attempting to list, read, or upload files into `tenant/{TENANT_B}/...` path  
**EXPECTED RESULT:** Storage API returns 403 Forbidden; Signed URLs restricted to authorized tenant session.  
**ACTUAL RESULT:** Bucket path standard `tenant/{tenant_id}/...` enforced in policy definitions. Live Supabase Storage test pending.  
**PASS/FAIL:** ❌ NOT VERIFIED (LIVE STORAGE TESTING PENDING)  

## Storage Bucket Rule
```sql
CREATE POLICY "tenant_storage_isolation" ON storage.objects
    FOR ALL USING (
        bucket_id = 'documents' 
        AND (storage.foldername(name))[1] = get_current_tenant_id()::text
    );
```
