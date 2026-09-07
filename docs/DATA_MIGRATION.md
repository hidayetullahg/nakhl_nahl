# NAKHL & NAHL — Standalone Commercial Data Migration Engine

## 1. Architectural Philosophy: The Staging Buffer Principle

To prevent data corruption, broken foreign keys, or partial writes in multi-tenant production databases, external files are **never written directly to production ERP tables** (`parties`, `items`, `journal_entries`, etc.).

Instead, the process follows a 5-step staging pipeline:

```
[External File: Excel/CSV/JSON/Logo/Mikro] 
                   │
                   ▼
       1. Checksum & Staging Buffer
         (public.data_migration_jobs & public.data_migration_staging)
                   │
                   ▼
       2. Column Auto-Mapping
         (Turkish & International ERP Dictionary)
                   │
                   ▼
       3. Traffic-Light Validation
         (🟢 GREEN / 🟡 YELLOW / 🔴 RED)
                   │
                   ▼
       4. Interactive User Review & Preview
         (User inspects parsed records & warnings)
                   │
                   ▼
       5. Atomic Ingestion & Rollback Window
         (Target tables updated inside transactional boundary)
```

## 2. Supported Source Systems & Formats

1. **Excel & CSV (`EXCEL`, `CSV`)**: Standard spreadsheet files with auto-delimiter detection (`,`, `;`, `\t`).
2. **Logo Tiger / Go3 (`LOGO`)**: Native XML/CSV cari and item export files.
3. **Mikro ERP (`MIKRO`)**: Standard stock and party ledger tables.
4. **Netsis Entegre (`NETSIS`)**: Entity cards and opening balances.
5. **Paraşüt Bulut (`PARASUT`)**: Cloud export CSVs.
6. **SAP & Odoo (`SAP`, `ODOO`)**: JSON and tabular exports.

## 3. Intelligent Column Auto-Mapping Dictionary

The mapping engine normalizes heterogeneous naming conventions into standardized NAKHL & NAHL schemas:

- **Customer / Supplier**:
  - `code`: `cari_kod`, `kod`, `hesap_kodu`, `id`
  - `name`: `cari_unvan`, `unvan`, `ad`, `title`, `name`
  - `tax_number`: `vergi_no`, `vkn`, `tckn`, `tax_id`
  - `phone`: `telefon`, `gsm`, `tel`, `phone`
  - `email`: `eposta`, `email`, `mail`
  - `opening_balance`: `bakiye`, `borc_bakiye`, `alacak_bakiye`
- **Products & Stock**:
  - `sku`: `barkod`, `stok_kodu`, `sku`, `code`
  - `name`: `urun_adi`, `stok_adi`, `ad`, `name`
  - `unit`: `birim`, `unit` (defaults to 'ADET')
  - `price`: `fiyat`, `satis_fiyati`, `price`
  - `quantity`: `miktar`, `stok_miktari`, `quantity`

## 4. Traffic Light Validation Rules

- 🟢 **GREEN (Ready)**: All required fields present, types valid, ready for immediate import.
- 🟡 **YELLOW (Warning)**: Optional fields missing (e.g. missing tax number or phone). Can be imported safely.
- 🔴 **RED (Critical Error)**: Mandatory fields absent (e.g. blank name or code). Row is blocked from ingestion until fixed.

## 5. Rollback Mechanism

Every ingestion is tagged with a unique `batch_id` and `job_id`. In case of user error, clicking **"Aktarımı Geri Al (Rollback)"** immediately flags the job as `ROLLED_BACK` and cleanses staging references without affecting previously existing records.
