# NAKHL & NAHL — Multi-Tenant Subscription & Lifecycle System

## 1. Subscription States & Rules

```
 ┌─────────┐      14 Days       ┌──────────┐
 │  TRIAL  │ ─────────────────> │ EXPIRED  │ (If unpurchased)
 └─────────┘                    └──────────┘
      │                              ▲
      │ Payment                      │ 7 Days Grace Over
      ▼                              │
 ┌─────────┐   Term (30/365d)   ┌──────────┐
 │ ACTIVE  │ ─────────────────> │  GRACE   │ (Payment due notice)
 └─────────┘                    └──────────┘
```

## 2. Universal Access Rules

1. **`MOD_CORE` (Always Free & Unconditionally Active)**:
   - Contains tenant onboarding, multi-company switcher, user roles, security audits, and foundational dashboards.
   - `has_active_module(tenant_id, 'MOD_CORE')` unconditionally returns `TRUE`.
2. **Read-Only Data Retention Guarantee**:
   - When a tenant's subscription expires, **no customer records, accounting ledgers, invoices, or stock logs are deleted**.
   - The user interface enters read-only inspection mode with a clear renewal banner.
3. **Grace Period Protection (7 Days)**:
   - Temporary bank transfer delays or weekend payment processing do not abruptly disrupt warehouse or cashier operations.
   - Modules function normally with a subtle "Ödeme Gecikmesi" badge during the 7-day grace window.

## 3. Database Schema Verification

- Subscriptions table: `commercial_tenant_subscriptions`
- Unique constraint: `(tenant_id, module_code)`
- RLS Policy: `is_tenant_member(tenant_id)`
- Verified by Live Test Suite: `054_commercial_and_migration_security_tests.sql`
