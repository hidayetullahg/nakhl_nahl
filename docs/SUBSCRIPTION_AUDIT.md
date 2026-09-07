# NAKHL & NAHL — Subscription Plans & Backend Entitlement Audit

## 1. SaaS Tiers & Entitlements Matrix
Defined in `003_saas_plans.sql` and enforced across backend RPCs:

| Tier Code | Plan Name | Max Users | Max Companies | Max Storage | Advanced Modules |
| :--- | :--- | :---: | :---: | :---: | :--- |
| **DEMO** | Demo Trial | 2 | 1 | 1 GB | Basic Accounting, 14-day expiry |
| **BASIC** | Basic ERP | 5 | 1 | 5 GB | Core Accounting & Inventory |
| **PRO** | Pro ERP | 25 | 3 | 50 GB | Multi-branch, POS, Advanced Logistics |
| **ENTERPRISE** | Global Enterprise | 9,999 | 999 | 1 TB+ | Full Suite, Intercompany, AI, Traceability |

---

## 2. Subscription Lifecycle State Machine
```
   [ TRIAL ] ──(Expiry)──> [ EXPIRED ] ──> [ READ_ONLY ]
       │
   (Payment)
       ▼
   [ ACTIVE ] ──(Payment Failed)──> [ PAST_DUE ] ──> [ GRACE_PERIOD (7 days) ]
       │                                                    │
       ▼                                                    ▼
   [ CANCELED ] ◄───────────────────────────────────── [ SUSPENDED ]
```

### Behavioral Safeguards:
- **No Automatic Data Deletion:** Canceling or suspending a subscription freezes write operations without deleting historical fiscal or stock ledgers.
- **Backend Enforcement:** Quota checks are performed at the database RPC boundary before entity creation (`check_tenant_user_quota()`, `check_tenant_company_quota()`).
