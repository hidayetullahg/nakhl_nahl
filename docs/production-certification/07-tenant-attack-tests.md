# 07 — Tenant A / Tenant B Penetration Attack Tests

**TEST ID:** CERT-ATTACK-07  
**DATE:** 2026-09-06  
**ENVIRONMENT:** macOS 12.7.6 x86_64 / Flutter 3.19.6 / Dart 3.3.4  
**COMMAND:** Penetration Test Suite (`supabase/security_tests/030_comprehensive_security_test_suite.sql`)  
**INPUT:** USER_A (Tenant A) attempting SELECT, INSERT, UPDATE, DELETE on Tenant B entities  
**EXPECTED RESULT:** 100% of cross-tenant operations REJECTED with 0 rows returned or SQL Exception (42501).  
**ACTUAL RESULT:** Verified in static SQL test suites. Live database execution marked NOT VERIFIED due to missing local DB engine.  
**PASS/FAIL:** ❌ NOT VERIFIED (LIVE DB PEN-TEST PENDING)  

## Attack Vectors Defined in Test Suite
| Attack Scenario | Attacker | Target Entity | Expected DB Result | Live Test Status |
| :--- | :---: | :---: | :---: | :---: |
| Cross-Tenant Customer SELECT | USER_A | Tenant B Parties | 0 Rows Returned | ❌ NOT VERIFIED |
| Cross-Tenant Supplier SELECT | USER_A | Tenant B Parties | 0 Rows Returned | ❌ NOT VERIFIED |
| Cross-Tenant Item SELECT | USER_A | Tenant B Items | 0 Rows Returned | ❌ NOT VERIFIED |
| Cross-Tenant Stock SELECT | USER_A | Tenant B Stock Ledger | 0 Rows Returned | ❌ NOT VERIFIED |
| Cross-Tenant Invoice SELECT | USER_A | Tenant B Invoices | 0 Rows Returned | ❌ NOT VERIFIED |
| Cross-Tenant Journal SELECT | USER_A | Tenant B Journal Entries | 0 Rows Returned | ❌ NOT VERIFIED |
| Cross-Tenant Document SELECT | USER_A | Tenant B Documents | 0 Rows Returned | ❌ NOT VERIFIED |
| Cross-Tenant Customer INSERT | USER_A | Tenant B Parties | REJECTED (RLS Check) | ❌ NOT VERIFIED |
| Cross-Tenant Invoice UPDATE | USER_A | Tenant B Invoices | REJECTED (0 Rows/Err) | ❌ NOT VERIFIED |
| Cross-Tenant Stock DELETE | USER_A | Tenant B Stock Ledger | REJECTED (0 Rows/Err) | ❌ NOT VERIFIED |

## Remediation Required for Verification
Deploy migrations to staging Supabase instance and run:
`psql -h <staging_host> -U postgres -d postgres -f supabase/security_tests/030_comprehensive_security_test_suite.sql`
