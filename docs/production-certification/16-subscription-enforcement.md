# 16 — Subscription Plans & Backend Entitlement Enforcement

**TEST ID:** CERT-SUB-16  
**DATE:** 2026-09-06  
**ENVIRONMENT:** macOS 12.7.6 x86_64 / Flutter 3.19.6 / Dart 3.3.4  
**COMMAND:** Audit of `003_saas_plans.sql` and `005_tenant_modules.sql`  
**INPUT:** DEMO / BASIC / PRO / ENTERPRISE tier callers requesting restricted RPCs  
**EXPECTED RESULT:** Backend database-level check rejects feature access when tier quota or module entitlement is absent.  
**ACTUAL RESULT:** Saas plans table defines quotas (`max_users`, `max_companies`, `max_invoices`, `max_storage`). Module guards enforce authorization. Live DB test pending.  
**PASS/FAIL:** ⚠️ CONDITIONAL PASS (SCHEMA DESIGN VERIFIED / LIVE DB PENDING)  

## Supported Plans & Entitlements
| Plan | Max Users | Max Companies | Max Storage | Advanced Modules (AI, Halal, Traceability) |
| :--- | :---: | :---: | :---: | :---: |
| **DEMO** | 2 | 1 | 1 GB | Restricted (Read-Only on expiry) |
| **BASIC** | 5 | 1 | 5 GB | Core Accounting & Inventory |
| **PRO** | 25 | 3 | 50 GB | Full ERP, Multi-Branch, POS |
| **ENTERPRISE** | Unlimited | Unlimited | 1 TB+ | Full Suite, Intercompany, AI, Traceability |
