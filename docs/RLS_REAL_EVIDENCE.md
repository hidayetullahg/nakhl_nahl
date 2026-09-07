# NAKHL & NAHL — PostgreSQL Row Level Security (RLS) Evidence

## Executive Summary
This document provides empirical evidence of Row Level Security (RLS) enforcement across all 104 public schema tables in the NAKHL & NAHL database architecture.

---

## RLS Enforcement Rules
1. **Schema-Wide Forcing**: RLS is not merely enabled; it is **FORCED** (`ALTER TABLE ... FORCE ROW LEVEL SECURITY`), ensuring table owners (e.g. `postgres` role) are also bounded by policies unless explicitly assuming `service_role`.
2. **Tenant ID Verification**: All tenant-owned tables enforce `tenant_id = (auth.jwt() ->> 'tenant_id')::uuid` in both `USING` (read/delete) and `WITH CHECK` (create/update) clauses.
3. **Multi-Company Gating**: Company-level records (bank accounts, warehouses, branches) invoke the `has_company_access(company_id)` function.
4. **Service Role Separation**: Only administrative seed and migration maintenance routines can bypass RLS via dedicated backend microservices.

---

## Schema Coverage Statistics
* **Total Tables Audited**: 104
* **Total RLS Enabled**: 104 (100%)
* **Total RLS Forced**: 104 (100%)
* **Total Security Policies**: 175
* **Security Definer Functions**: 13 (All audited for `SET search_path = public`)

---

## Artifact References
* **Inspection SQL**: `test/evidence/rls_inventory.sql`
* **Full Inventory Log**: `test/evidence/rls_inventory.txt`
* **Security Definer Log**: `test/evidence/security_definer_audit.log`
* **Integrity Hash**: Verified in `test/evidence/SHA256SUMS.txt`
