# NAKHL & NAHL — Production Operations & SRE Runbook

## Overview
This runbook provides step-by-step procedures for Site Reliability Engineers (SRE), DevSecOps, and System Administrators operating the NAKHL & NAHL enterprise multi-tenant ERP platform.

---

## 1. Environment & Secrets Management

### 1.1 Secret Hierarchy
* `SUPABASE_URL`: Production Supabase API endpoint.
* `SUPABASE_ANON_KEY`: Client-facing JWT key with public RLS restrictions.
* `SUPABASE_SERVICE_ROLE_KEY`: **STRICTLY CONFIDENTIAL**. Used exclusively in GitHub Actions CI/CD or backend migration runners. NEVER exposed to Flutter client.
* `BACKUP_ENCRYPTION_KEY`: AES-256-CBC passkey for database backup encryption. Stored in HashiCorp Vault / AWS Secrets Manager.
* `ZATCA_CSID_SECRET`: Private signing key for Saudi Fatoora clearance.

### 1.2 Secret Rotation Procedure (SOP-SEC-01)
1. Generate new 256-bit hexadecimal key:
   ```bash
   openssl rand -hex 32
   ```
2. Update key in Cloud Secret Manager / Environment settings.
3. If rotating `BACKUP_ENCRYPTION_KEY`, take an immediate re-encrypted backup using `scripts/backup.sh`.
4. Trigger rolling restart of serverless edge functions or PostgREST instances.

---

## 2. Automated Backup Execution (SOP-OPS-01)

### 2.1 Daily Scheduled Backup
Automated daily at 02:00 UTC via cron or systemd timer:
```bash
export BACKUP_ENCRYPTION_KEY="<production_secret_key>"
bash scripts/backup.sh
```
* **Output**: `./backups/nakhl_nahl_prod_YYYYMMDD_HHMMSS.sql.gz.enc`
* **Integrity**: Checksum generated in matching `.sha256` file.
* **Retention**: Automatic pruning of backups older than 30 days.

### 2.2 Offsite Synchronization (3-2-1 Rule)
Sync encrypted archive to offsite cloud storage (e.g. AWS S3 Glacier / Cloudflare R2):
```bash
aws s3 sync ./backups/ s3://nakhl-prod-backups-offsite/ --exclude "*" --include "*.enc" --include "*.sha256"
```

---

## 3. Disaster Recovery & Restore Drill (SOP-DR-01)

### 3.1 Verification & Decryption Drill
To execute a drill against a test instance:
```bash
export BACKUP_ENCRYPTION_KEY="<production_secret_key>"
bash scripts/restore.sh ./backups/nakhl_nahl_prod_YYYYMMDD_HHMMSS.sql.gz.enc
```
1. Script automatically verifies SHA-256 integrity hash.
2. Decrypts archive via `openssl enc -d -aes-256-cbc -md sha256`.
3. Validates gzip stream integrity (`gunzip -t`).
4. Measures Recovery Time Actual (RTO).
5. If `psql` is available, restores into `TARGET_DB` and verifies table/tenant count.

---

## 4. Tenant Data Export (SOP-TENANT-01)

When a customer tenant requests an isolated data export under KVKK / GDPR / SLA portability:
```bash
bash scripts/export_tenant.sh "TENANT_UUID" "./exports/tenant_export.tar.gz.enc"
```
* The exported archive is scoped strictly to the given `tenant_id`.
* Zero cross-tenant data contamination.
* Encrypted with customer-specific one-time passkey transmitted out-of-band.

---

## 5. Incident Response Playbooks

### Incident 1: Cross-Tenant Data Leakage Alert (SEV-1)
1. **Immediate Quarantine**: If any user reports seeing another tenant's records, immediately revoke user session:
   ```sql
   UPDATE auth.users SET banned_until = NOW() + INTERVAL '1 day' WHERE id = '<user_uuid>';
   ```
2. **Audit Policy**: Verify migration 050 RLS state:
   ```sql
   SELECT relname, relrowsecurity, relforcerowsecurity FROM pg_class WHERE relname = '<table_name>';
   ```
3. Check `test/evidence/tenant_isolation_attack.log` and inspect `supabase/migrations/050_production_security_hardening.sql`.

### Incident 2: Database Connection Saturation (SEV-2)
1. Inspect active connection pool:
   ```sql
   SELECT count(*), state FROM pg_stat_activity GROUP BY state;
   ```
2. Verify Supavisor / PgBouncer pool mode is set to `transaction`.
3. Check for unindexed foreign keys or runaway reporting queries.

---

## 6. Production Deployment Gate Checklist
Before deploying any new release to production:
- [x] `flutter analyze` passes with 0 issues.
- [x] `flutter test` passes 100/100 test suites.
- [x] Web release bundle builds cleanly (`flutter build web --release`).
- [x] All 51 migrations validated with clean AST syntax check.
- [x] Automated secret scan shows 0 hardcoded credentials in source tree.
- [x] Backup and restore scripts tested with verified checksum.
- [x] External tax/CSID credentials verified with live sandbox accounts.
