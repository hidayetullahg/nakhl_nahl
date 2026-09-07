# 24 — Performance, Indexing & High-Scale Multi-Tenancy

**TEST ID:** CERT-PERF-24  
**DATE:** 2026-09-06  
**ENVIRONMENT:** macOS 12.7.6 x86_64 / Flutter 3.19.6 / Dart 3.3.4  
**COMMAND:** Index audit of `019_indexes_and_constraints.sql`, `049_performance_and_scale_hardening.sql`, and `051_master_directive_hardening.sql`  
**INPUT:** Query patterns for 100, 1,000, 10,000, and 50,000+ tenants  
**EXPECTED RESULT:** All tenant and company queries backed by composite indexes; pagination enforced; partitioning architecture specified.  
**ACTUAL RESULT:** Composite B-tree indexes exist for `(tenant_id, company_id, ...)`. Pagination enforced in RPCs.  
**PASS/FAIL:** ✅ PASS (ARCHITECTURE & INDEXES VERIFIED)  

## Key Indexing Features
- `idx_invoices_tenant_company_date`: B-Tree composite index on `(tenant_id, company_id, invoice_date DESC)`.
- `idx_stock_ledger_tenant_item`: Composite index on `(tenant_id, item_id, created_at DESC)`.
- `idx_journal_entries_tenant_company_date`: Composite index on `(tenant_id, company_id, entry_date DESC)`.
- **Partitioning Strategy:** For > 10,000 tenants, `stock_ledger_entries` and `journal_entries` are designed for Declarative Range Partitioning by `entry_date` (quarterly).
