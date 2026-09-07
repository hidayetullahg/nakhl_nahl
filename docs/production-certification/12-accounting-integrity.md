# 12 — Double-Entry Accounting Ledger Integrity

**TEST ID:** CERT-ACC-12  
**DATE:** 2026-09-06  
**ENVIRONMENT:** macOS 12.7.6 x86_64 / Flutter 3.19.6 / Dart 3.3.4  
**COMMAND:** `flutter test test/accounting_finance_test.dart` & SQL constraint audit of `023_double_entry_accounting.sql`  
**INPUT:** Balanced journal ($100 Debit / $100 Credit) vs Unbalanced journal ($100 Debit / $90 Credit)  
**EXPECTED RESULT:** Balanced journals accepted; Unbalanced journals rejected; Posted entries immutable; Reversals balanced.  
**ACTUAL RESULT:** Dart domain models pass (95/95). SQL triggers `trg_check_journal_balance` enforce `SUM(debit) = SUM(credit)`. Live SQL transaction test pending.  
**PASS/FAIL:** ⚠️ CONDITIONAL PASS (DOMAIN LOGIC PASS / LIVE DB PENDING)  

## Invariants Enforced
1. **Mathematical Equality:** `SUM(debit) == SUM(credit)` strictly validated before posting.
2. **Append-Only Immutability:** Updating or deleting a `POSTED` journal entry throws an exception.
3. **Audit Trail:** Corrections must be executed via `reverse_journal_entry_rpc()`, generating mirror-image offset entries.
