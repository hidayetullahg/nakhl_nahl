# NAKHL & NAHL — Stock Ledger & Inventory Integrity

## 1. Append-Only Inventory Ledger
Inventory balances in NAKHL&NAHL are never updated by in-place mutation of a single mutable balance column. All stock changes are recorded as chronological journal entries in `stock_ledger_entries`:

$$\text{Current Balance} = \text{Opening} + \sum \text{Receipts} - \sum \text{Sales} \pm \sum \text{Transfers} + \sum \text{Returns}$$

---

## 2. Tested Reconciliation Scenario
Verified in `test/inventory_ledger_balance_test.dart`:
- **Opening Balance:** +100
- **Purchase Receipt:** +50
- **Sales Delivery:** -30
- **Warehouse Transfer Out:** -20
- **Customer Return:** +5
- **Expected Final Balance:** 105

```
Result: 100 + 50 - 30 - 20 + 5 = 105 (Reconciliation Equality Confirmed)
```

---

## 3. Negative Stock Policy
- System enforces strict zero-negative-stock validation on non-backorderable items.
- Historical stock ledger rows are immutable. Corrections must be booked via `ADJUSTMENT` movement entries.
