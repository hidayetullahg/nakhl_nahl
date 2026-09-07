# NAKHL & NAHL — Multi-Tenant Data Isolation Architecture

## Core Architectural Principle
**"TENANT A ≠ TENANT B — ZERO TOLERANCE FOR CROSS-TENANT DATA LEAKAGE"**

In NAKHL&NAHL, whether there are 10, 1,000, or 50,000 corporate tenants hosted on the platform, no tenant is ever capable of viewing, modifying, or accessing another tenant's records across any layer of the architecture:

```
[ FLUTTER CLIENT / DART APP ]
        │
        ▼ (JWT Bearer Token: auth.uid())
[ SUPABASE GATEWAY / POSTGREST ]
        │
        ▼
[ SECURITY DEFINER CONTEXT RESOLUTION ]
  - is_tenant_member(p_tenant_id)
  - has_company_access(p_company_id)
        │
        ▼
[ POSTGRESQL ROW LEVEL SECURITY (RLS) ]
  - Filtered WHERE clauses automatically injected
  - FORCE ROW LEVEL SECURITY ensures no bypass
        │
        ▼
[ ISOLATED DATASET RETURNED ]
```

---

## 1. Domain Coverage Matrix
Every business entity is strictly tenant-scoped:
- **Parties (Cari):** `parties.tenant_id`
- **Inventory & Stock:** `stock_ledger_entries.tenant_id`, `items.tenant_id`, `item_lots.tenant_id`
- **Invoices & Billing:** `invoices.tenant_id`, `invoice_lines.tenant_id`
- **Accounting & General Ledger:** `journal_entries.tenant_id`, `journal_lines.tenant_id`
- **Documents & Files:** `documents.tenant_id`, `storage.objects` path `tenant/{tenant_id}/...`
- **Audit Logs:** `audit_logs.tenant_id`
- **Realtime Broadcasts:** Channel `tenant:{tenant_id}`

---

## 2. Adversarial Penetration Test Vectors
The SQL penetration test suite in `supabase/security_tests/030_comprehensive_security_test_suite.sql` defines formal test scenarios against:
1. Cross-Tenant SELECT attacks.
2. Cross-Tenant INSERT / UPDATE / DELETE spoofing.
3. RPC parameter injection.
4. Unprovisioned authenticated user containment.
5. Multi-company boundary enforcement within a single tenant.
