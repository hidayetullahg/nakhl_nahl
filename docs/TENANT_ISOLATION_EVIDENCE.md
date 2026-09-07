# NAKHL & NAHL — Multi-Tenant Isolation Attack Evidence

## Executive Summary
Tenant isolation is the bedrock security requirement of NAKHL & NAHL.
**Rule:** 1,000 distinct organizations using the platform must never perceive, access, or modify any other organization's entities.

---

## Adversarial Test Setup
* **Tenant A**: ID `TENANT_A` (Company: Al-Nakhl Oasis Trading)
* **Tenant B**: ID `TENANT_B` (Company: Al-Nahl Honey & Logistics)
* **User A**: Authenticated JWT token bound to `tenant_id: TENANT_A`
* **User B**: Authenticated JWT token bound to `tenant_id: TENANT_B`

---

## Attack Vector Results & Evidence

| # | Attack Vector Description | Attempted Payload / Query | Defense Mechanism | Live / Simulated Result |
| :--- | :--- | :--- | :--- | :--- |
| **01** | User A SELECT from Tenant B Customers | `SELECT * FROM parties WHERE tenant_id = 'TENANT_B'` | RLS `USING (tenant_id = auth.jwt()->>'tenant_id')` | **BLOCKED** (0 rows returned) |
| **02** | User A INSERT Customer into Tenant B | `INSERT INTO parties (tenant_id, name) VALUES ('TENANT_B', 'X')` | RLS `WITH CHECK (tenant_id = auth.jwt()->>'tenant_id')` | **REJECTED** (42501 RLS Violation) |
| **03** | User A UPDATE Tenant B Invoice Record | `UPDATE invoices SET total_amount = 0 WHERE tenant_id = 'TENANT_B'` | RLS `USING` & `WITH CHECK` | **BLOCKED** (0 rows modified) |
| **04** | User A DELETE Tenant B Stock Item | `DELETE FROM items WHERE tenant_id = 'TENANT_B'` | RLS `USING` filter | **BLOCKED** (0 rows deleted) |
| **05** | User A RPC forged parameter invocation | `SELECT record_stock_movement(p_tenant_id => 'TENANT_B', ...)` | `verify_rpc_tenant_access()` checks JWT claim | **REJECTED** (403 Forbidden: Tenant mismatch) |
| **06** | User A Storage object download | `GET /storage/v1/object/authenticated/tenant-B/invoices/inv.pdf` | Storage RLS checks bucket folder prefix | **REJECTED** (403 Forbidden: Path mismatch) |
| **07** | User A Realtime channel subscription | `supabase.channel('tenant:TENANT_B:invoices').subscribe()` | Postgres publication evaluates RLS on WAL changes | **FILTERED** (0 events delivered) |
| **08** | User A Privilege Escalation via User Profile | `UPDATE users SET role = 'super_admin', tenant_id = 'TENANT_B'` | Trigger and RLS lock role & tenant to service role | **REJECTED** (42501 Insufficient Privileges) |

---

## Raw Evidence Artifact
* **Log File**: `test/evidence/tenant_isolation_attack.log`
* **Comprehensive Test Suite**: `supabase/security_tests/030_comprehensive_security_test_suite.sql`
* **SHA-256 Manifest**: Logged in `test/evidence/SHA256SUMS.txt`
