# NAKHL & NAHL — Double-Entry Accounting Ledger Integrity

## 1. Accounting Invariants & Mathematical Rules

### Rule 1: The Balanced Journal Equation
For every transaction posted to the General Ledger:
$$\sum_{i=1}^{n} \text{Debit}_i = \sum_{j=1}^{m} \text{Credit}_j$$
- **Trigger Check:** `trg_check_journal_balance` in `023_double_entry_accounting.sql` executes before status transition to `POSTED`.
- **Result:** An unbalanced entry (e.g. Debit $100, Credit $90) throws a SQL exception and aborts the entire transaction.

### Rule 2: Immutability of Posted Journals
- Once a journal entry is marked `POSTED`, direct `UPDATE` or `DELETE` statements on `journal_entries` and `journal_lines` are blocked by database triggers.
- **Audit Requirement:** All corrections must be initiated via `reverse_journal_entry_rpc()`, creating an offsetting reversal voucher.

---

## 2. Test Verification Matrix
| Test Case | Scenario | Expected | Status |
| :--- | :--- | :--- | :---: |
| **ACC-01** | Balanced Journal (Debit: $1000 / Credit: $1000) | ACCEPTED | ✅ PASS |
| **ACC-02** | Unbalanced Journal (Debit: $1000 / Credit: $900) | REJECTED | ✅ PASS |
| **ACC-03** | Update Posted Journal Line | REJECTED | ✅ PASS |
| **ACC-04** | Delete Posted Journal Line | REJECTED | ✅ PASS |
| **ACC-05** | Reverse Posted Journal Entry | ACCEPTED (Reversed) | ✅ PASS |
