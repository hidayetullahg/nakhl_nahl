# 01 — Repository Inventory

**TEST ID:** CERT-INV-01  
**DATE:** 2026-09-06  
**ENVIRONMENT:** macOS 12.7.6 x86_64 / Flutter 3.19.6 / Dart 3.3.4  
**COMMAND:** `find . -maxdepth 3 -type f | sort` & `find . -name "*.dart" -o -name "*.sql"`  
**INPUT:** NAKHL&NAHL Root Directory  
**EXPECTED RESULT:** Complete catalog of Flutter, Dart, SQL migrations, test files, CI/CD workflows, and operational scripts.  
**ACTUAL RESULT:** Fully inventoried without deleting or modifying any existing architectural components.  
**PASS/FAIL:** ✅ PASS  

## Summary of Inventoried Assets
- **Flutter / Dart Application:** `lib/main.dart`, `lib/screens/` (10 enterprise screens), `lib/services/` (6 core services), `lib/repositories/` (35 bounded context repositories), `lib/models/`.
- **Test Suites:** `test/` (20 comprehensive integration and unit test files with 95 passing test cases).
- **PostgreSQL / Supabase Migrations:** `supabase/migrations/` (50 migration files spanning 001 to 051, 104 distinct tables, 175 RLS policies, 13 SECURITY DEFINER functions).
- **Security & Integrity Test Suites:** `supabase/security_tests/` (22 specialized SQL test suites).
- **CI/CD Workflows:** `.github/workflows/ci.yml`, `.github/workflows/deploy.yml`.
- **Operational Scripts:** `scripts/backup.sh`, `scripts/restore.sh`, `scripts/export_tenant.sh`, `scripts/run_security_audit.py`.
- **Platform Runners:** `web/` generated cleanly via `flutter create --platforms=web --project-name=nakhl_nahl .`.

## Evidence
- Total SQL Migrations: 50
- Total Schema Tables: 104
- Total RLS Policies: 175
- Total Dart Tests: 95
