# NAKHL & NAHL — SaaS Commercial Model & Architecture Specification

## 1. Executive Summary & Brand Decoupling (White-Label Architecture)

NAKHL & NAHL is designed as a brand-independent, white-label, multi-tenant enterprise resource planning (ERP) platform. The core codebase contains zero hardcoded commitments to domain names, company legal names, or trade brands.

All commercial branding properties are managed exclusively through `AppBrandConfig` (`lib/core/config/app_brand_config.dart`) and can be overridden dynamically at build or deployment time via `--dart-define` flags:

```bash
flutter build web --release \
  --dart-define=BRAND_PRODUCT_NAME="NAKHL & NAHL" \
  --dart-define=BRAND_SHORT_NAME="NAKHL" \
  --dart-define=BRAND_COMPANY_NAME="NAKHL & NAHL Global Technology Ltd." \
  --dart-define=BRAND_PRIMARY_DOMAIN="beeofdate.com" \
  --dart-define=BRAND_SUPPORT_EMAIL="support@beeofdate.com" \
  --dart-define=BRAND_SALES_EMAIL="sales@beeofdate.com"
```

## 2. 18 Modular Sellable Items Matrix

The platform monetizes through 18 discrete commercial modules divided into Core, Operations, Compliance, Migration, Professional Services, and Advanced Analytics:

| Module Code | Module Name | Category | Type | Default SAR / mo | Default TRY / mo | Dependencies |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `MOD_CORE` | Temel ERP & Multi-Tenant | CORE | Core | **Free (0.00)** | **Free (0.00)** | None |
| `MOD_ACCOUNTING` | Genel Muhasebe & Finans | FINANCE | Standard | 150.00 | 1,250.00 | `MOD_CORE` |
| `MOD_INVENTORY` | Stok & Depo Yönetimi | OPERATIONS | Standard | 120.00 | 1,000.00 | `MOD_CORE` |
| `MOD_SALES` | Satış & Müşteri İlişkileri | OPERATIONS | Standard | 100.00 | 850.00 | `MOD_INVENTORY` |
| `MOD_PURCHASE` | Satın Alma & Tedarikçi | OPERATIONS | Standard | 100.00 | 850.00 | `MOD_INVENTORY` |
| `MOD_POS` | Hızlı Satış POS & Perakende | RETAIL | Standard | 80.00 | 700.00 | `MOD_CORE` |
| `MOD_EINVOICE_TR` | Türkiye E-Fatura & GİB | COMPLIANCE | Addon | 100.00 | 750.00 | `MOD_ACCOUNTING` |
| `MOD_ZATCA_SA` | Suudi Arabistan ZATCA Faz-2 | COMPLIANCE | Addon | 150.00 | 1,250.00 | `MOD_ACCOUNTING` |
| `MOD_DATA_MIGRATION`| Veri Aktarımı & Geçiş Sihirbazı | MIGRATION | One-off / Addon | 500.00 | 4,000.00 | None |
| `MOD_INITIAL_SETUP` | İlk Kurulum & Danışmanlık | SERVICE | Professional | 1,000.00 | 8,000.00 | None |
| `MOD_TRAINING` | Kullanıcı & Personel Eğitimi | SERVICE | Professional | 800.00 | 6,500.00 | None |
| `MOD_REPORTING_ADV` | Gelişmiş Raporlama & BI Analitik| ANALYTICS | Standard | 100.00 | 850.00 | None |
| `MOD_AI_OCR` | Yapay Zekâ & Akıllı Belge OCR | AI | Addon | 150.00 | 1,250.00 | None |
| `MOD_LOGISTICS_EXPORT`| Uluslararası İhracat & Lojistik | GLOBAL | Standard | 120.00 | 1,000.00 | `MOD_INVENTORY` |
| `MOD_AGRICULTURE` | Tarım & Hurma Bahçesi Yönetimi| SPECIAL | Specialized | 100.00 | 800.00 | None |
| `MOD_DOC_MANAGEMENT` | Doküman Yönetimi & Arşivleme | STORAGE | Standard | 80.00 | 650.00 | None |
| `MOD_INTERCOMPANY` | Grup Şirketleri & Konsolidasyon| ENTERPRISE | Enterprise | 200.00 | 1,700.00 | None |
| `MOD_API_INTEGRATION`| Açık API & Webhook Entegrasyonu | DEVELOPER | Developer | 150.00 | 1,200.00 | None |

## 3. Subscription Lifecycle State Machine

1. **`TRIAL` (14 Days)**: Full module access granted without payment method. Auto-downgrades to expired if unpurchased.
2. **`ACTIVE` (30 or 365 Days)**: Unrestricted module entitlement. 20% discount on yearly billing cycle.
3. **`GRACE` (7 Days Post-Expiration)**: When period ends without payment, tenant receives urgent renewal banner but retains access for 7 grace days.
4. **`EXPIRED` (Read-Only Mode)**: Module access locked. **Crucial Rule:** Tenant data is NEVER deleted. Ledgers and records remain completely readable/exportable.
5. **`SUSPENDED` / `CANCELLED`**: Administrative suspension state.

## 4. Multi-Currency Engine

- Base billing supported in **SAR**, **TRY**, **USD**, and **EUR**.
- Instant currency toggle in `ModuleStoreScreen`.
- Database pricing lookup in `commercial_module_pricing` with fallback to localized rates.
