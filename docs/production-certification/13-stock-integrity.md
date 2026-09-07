# 13 — Stock Ledger Integrity & Formula Validation

**TEST ID:** CERT-STK-13  
**DATE:** 2026-09-06  
**ENVIRONMENT:** macOS 12.7.6 x86_64 / Flutter 3.19.6 / Dart 3.3.4  
**COMMAND:** `flutter test test/inventory_ledger_balance_test.dart` & AST audit of `024_inventory_ledger.sql`  
**INPUT:** Movement Sequence: Opening(+100) -> Receipt(+50) -> Sale(-30) -> Transfer(-20) -> Return(+5)  
**EXPECTED RESULT:** Final Stock = 105; Negative stock rejected (if configured); Posted ledger records immutable.  
**ACTUAL RESULT:** Dart unit test suite passes (+95). SQL append-only ledger pattern validated. Live DB transaction test pending.  
**PASS/FAIL:** ⚠️ CONDITIONAL PASS (DOMAIN LOGIC PASS / LIVE DB PENDING)  

## Stock Reconciliation Formula
$$\text{Final Balance} = 100 + 50 - 30 - 20 + 5 = 105$$
Direct updates to historical `stock_ledger_entries` are blocked by database trigger. All adjustments require compensatory transactions.
