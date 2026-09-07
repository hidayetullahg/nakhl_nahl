# NAKHL & NAHL — Enterprise Backup & Disaster Recovery Architecture

## 1. Automated Backup Architecture
The NAKHL&NAHL backup pipeline guarantees zero-plaintext exposure and strict lifecycle management:

```
PRIMARY DATABASE (PostgreSQL / Supabase)
  │
  ▼
AUTOMATED EXTRACTION (pg_dump / Migration Tarball)
  │
  ▼
ENCRYPTION (OpenSSL AES-256-CBC with SHA-256 Key Derivation)
  │
  ▼
CHECKSUM GENERATION (SHA-256 Hash Stored in .sha256 Manifest)
  │
  ▼
OFF-SITE SECURE REPOSITORY (Encrypted Cloud Storage Bucket)
  │
  ▼
RETENTION ENFORCEMENT (30-Day Automated Pruning)
```

---

## 2. Backup Delivery & Email Security Policy (Section 19)
- **Zero Raw Attachment Rule:** Large database dumps are **never** attached to outbound customer or administrator emails.
- **Secure Link Dispatch:** Emails contain only:
  - Backup Timestamp & Unique ID
  - SHA-256 Checksum
  - Expiring, time-limited, signed download URL (15-minute TTL)
  - Failure/Success Alert Notification payload.

---

## 3. Disaster Recovery (DR) Scenarios & Playbooks (Section 21)
1. **Primary Database Failure:** Failover to read-replica within 60 seconds; promote replica via Supabase HA.
2. **Storage Volume Failure:** Point-in-time recovery via multi-region S3/GCS bucket mirroring.
3. **Application Service Crash:** Blue/green container redeployment within 3 minutes.
4. **Cloud / Regional Outage:** Restore encrypted backup onto alternate region database.
5. **Accidental Deletion / Tampering:** WAL Point-in-time recovery (PITR) up to the exact minute prior to incident.
6. **Credential Leak / Compromise:** Immediate revocation of all active JWT sessions and rotation of service keys.
7. **Force Majeure / Infrastructure Loss:** Recovery procedures governed under the Legal & Technical Responsibility Framework.

---

## 4. Contractual & Legal Disclaimer (Section 20 & 37)
> [!IMPORTANT]
> **Legal Notice:** Teknik yedekleme ve kurtarma sistemleri en yüksek sektör standartlarına göre yapılandırılmış olmakla birlikte; veri sahipliği, üçüncü taraf altyapı kesintileri, mücbir sebepler ve yasal sorumluluk sınırları yerel mevzuat (KVKK / GDPR / KSA PDPL) çerçevesinde yetkili hukuk müşaviri tarafından incelenerek sözleşmeye bağlanmalıdır.
