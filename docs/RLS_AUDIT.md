# NAKHL & NAHL — Row Level Security (RLS) Complete Audit

## RLS Summary Statistics
- **Total Tables in Schema:** 104
- **Tables with RLS Enabled:** 104 (100%)
- **Tables with RLS Forced:** 104 (100% via Migration 050 & 051)
- **Explicit RLS Policies:** 175
- **Unprotected Tenant Tables:** 0

---

## 1. Automated Schema-Wide RLS Enforcement
In `050_production_security_hardening.sql`, an automated PL/pgSQL block dynamically iterates through all user tables in `public` schema and executes:
```sql
ALTER TABLE public.<table_name> ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.<table_name> FORCE ROW LEVEL SECURITY;
```
This guarantees that even table owners cannot bypass RLS restrictions during normal application queries.

---

## 2. Policy Matrix by Domain
- **Multi-Tenant Core:** `tenants`, `companies`, `branches`, `departments`, `warehouses` check `tenant_id = get_current_tenant_id()`.
- **User Company Access:** `user_company_access` checks caller tenant admin role or caller user ID.
- **Financial & Accounting:** `journal_entries`, `journal_lines`, `invoices`, `invoice_lines` enforce `has_company_access(company_id)`.
- **Inventory & Traceability:** `items`, `item_lots`, `stock_ledger_entries`, `harvest_logs` check `tenant_id = get_current_tenant_id()`.
- **Storage & Media:** Storage bucket `documents` checks folder path prefix `tenant/{tenant_id}/...`.
