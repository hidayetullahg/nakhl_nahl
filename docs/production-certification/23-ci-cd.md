# 23 — CI/CD Pipeline & GitHub Actions Verification

**TEST ID:** CERT-CICD-23  
**DATE:** 2026-09-06  
**ENVIRONMENT:** macOS 12.7.6 x86_64 / Flutter 3.19.6 / Dart 3.3.4  
**COMMAND:** Workflow audit of `.github/workflows/ci.yml` and `deploy.yml`  
**INPUT:** GitHub Actions configuration  
**EXPECTED RESULT:** Automated static analysis, testing, and production web builds using GitHub Secrets.  
**ACTUAL RESULT:** Workflow defines `analyze`, `test`, `build-web` jobs with `--dart-define` secret injection.  
**PASS/FAIL:** ✅ PASS  

## Verified Pipeline Steps
1. **Static Analysis Job:** Runs `flutter analyze --no-pub`.
2. **Test Job:** Runs `flutter test --coverage` and uploads `coverage/lcov.info`.
3. **Build Web Job:** Triggers on `main` and `develop` branches:
   ```yaml
   flutter build web --release \
     --dart-define=APP_ENV=${{ github.ref == 'refs/heads/main' && 'prod' || 'staging' }} \
     --dart-define=SUPABASE_URL=${{ secrets.SUPABASE_URL }} \
     --dart-define=SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }}
   ```
