# NAKHL & NAHL — Payment System & Gateway Abstraction

## 1. Overview & Dual Flow Architecture

NAKHL & NAHL supports two primary transaction pipelines for SaaS module activation:

1. **Credit / Debit Card (Instant Gateway Activation)**
   - Instant verification via standard payment tokenization.
   - Immediate emission of `ACTIVE` entitlement in `commercial_tenant_subscriptions`.
   - Automated invoice and receipt record generation.

2. **Bank Wire Transfer / EFT / Dekont (Manual Verification Flow)**
   - Display of corporate IBAN, beneficiary title (`AppBrandConfig.current.companyLegalName`), and unique reference code.
   - User inputs transfer reference code or uploads payment receipt.
   - Order stored in `commercial_payment_orders` with status `PENDING`.
   - Real-time notification routed to Platform Admin portal (`PlatformAdminScreen`).
   - Platform owner inspects bank statement, clicks **"Onayla & Aktif Et"**, atomically provisioning tenant modules.

## 2. Security & Backend Entitlement Enforcement

To prevent client-side entitlement spoofing:
- Module entitlement checks do not rely on local boolean flags.
- PostgreSQL database function `public.has_active_module(p_tenant_id UUID, p_module_code VARCHAR)` verifies timestamp validity against server-side time.
- Cross-tenant payment access is strictly prohibited by Row Level Security:
  ```sql
  CREATE POLICY "com_orders_tenant_isolation" ON public.commercial_payment_orders
  FOR ALL USING (is_tenant_member(tenant_id));
  ```
