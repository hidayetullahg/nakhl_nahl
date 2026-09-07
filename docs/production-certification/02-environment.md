# 02 — Tool & Environment Inventory

**TEST ID:** CERT-ENV-02  
**DATE:** 2026-09-06  
**ENVIRONMENT:** macOS 12.7.6 x86_64 / Flutter 3.19.6 / Dart 3.3.4  
**COMMAND:** `which flutter dart docker node npm psql supabase brew git`  
**INPUT:** System PATH and installed toolchains  
**EXPECTED RESULT:** All required runtime tools verified or remediation documented.  
**ACTUAL RESULT:** Flutter, Dart, Brew, Git, Python verified; Docker, Node, Supabase CLI, psql absent from host.  
**PASS/FAIL:** ⚠️ CONDITIONAL PASS  

## Tool Status Matrix
| Tool | Present | Version / Path | Status |
| :--- | :---: | :--- | :--- |
| **Flutter** | YES | 3.19.6 • `/Users/gulbahargokturk/development/flutter/bin/flutter` | ✅ VERIFIED |
| **Dart** | YES | 3.3.4 • `/Users/gulbahargokturk/development/flutter/bin/dart` | ✅ VERIFIED |
| **Git** | YES | 2.37.1 • `/usr/bin/git` | ✅ VERIFIED |
| **Python** | YES | 3.9.6 • `/usr/bin/python3` | ✅ VERIFIED |
| **Homebrew** | YES | 6.0.22 • `/usr/local/bin/brew` | ✅ VERIFIED |
| **Docker** | NO | Not found | ❌ MISSING |
| **Node / npm** | NO | Not found | ❌ MISSING |
| **psql / PostgreSQL** | NO | Not found | ❌ MISSING |
| **Supabase CLI** | NO | Not found | ❌ MISSING |

## Missing Tool Remediation Guide
1. **PostgreSQL / psql**:
   - *Why Needed:* Required for live migration execution and database-side RLS transaction penetration testing.
   - *How to Install:* Install Postgres.app or modern pre-compiled package, or run PostgreSQL in Docker.
   - *Post-Install Test:* `psql -U postgres -c "SELECT version();"`.
2. **Docker Desktop**:
   - *Why Needed:* Required for running local Supabase emulator (`supabase start`).
   - *How to Install:* Download Docker Desktop for Mac (Intel x86_64) from docker.com.
   - *Post-Install Test:* `docker run --rm hello-world`.
3. **Supabase CLI**:
   - *Why Needed:* Automates local Supabase migration and test suites.
   - *How to Install:* `brew install supabase/tap/supabase` (requires Docker running).
   - *Post-Install Test:* `supabase status`.
