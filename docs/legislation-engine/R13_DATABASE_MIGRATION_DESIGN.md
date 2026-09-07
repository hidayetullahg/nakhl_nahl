# R13 — VERİTABANI MİGRASYON TASARIMI
## Database Migration Plan (054 → 057)

**Rapor No:** R13  
**Versiyon:** 1.0  
**Tarih:** 2026-09-07  
**Durum:** ONAY BEKLİYOR  

---

## 1. Migrasyon Stratejisi

### 1.1 Temel Kural

> **"Mevcut 53 migrasyon dosyasına dokunulmaz. Yeni migrasyonlar 054'ten başlar."**

Mevcut `042_legislation_tax_engine.sql` tabloları `ALTER TABLE` ile genişletilir. Hiçbir tablo kaldırılmaz.

### 1.2 Migrasyon Haritası

| Migrasyon | Dosya | İçerik |
|---|---|---|
| 054 | `054_legislation_engine_foundation.sql` | `legal_authorities`, `legislation_sources`, `ALTER TABLE legislations`, `ALTER TABLE tax_rules`, `legal_authorities` seed |
| 055 | `055_sa_legislation_rules.sql` | `gcc_tariff_codes`, `tariff_exemptions`, `withholding_tax_rules`, `compliance_check_rules`, SA + TR seed data |
| 056 | `056_zakat_engine.sql` | `zakat_parameters`, `zakat_assessments`, `source_url_health_checks`, `calculate_zakat` RPC |
| 057 | `057_compliance_and_tax_v2.sql` | `calculate_transaction_tax_v2` RPC, `assess_company_compliance` RPC, `detect_rule_conflicts` fonksiyonu |

---

## 2. Migrasyon 054 — Temel Genişletme

```sql
-- ============================================================
-- MIGRATION 054: LEGISLATION ENGINE FOUNDATION
-- Mevzuat motoru temel altyapısı (mevcut 042'yi bozmadan)
-- ============================================================

-- 1. LEGAL AUTHORITIES (Resmi Mevzuat Otoriteleri)
CREATE TABLE IF NOT EXISTS legal_authorities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    authority_code VARCHAR(50) NOT NULL UNIQUE,
    authority_name_en VARCHAR(200) NOT NULL,
    authority_name_ar VARCHAR(200),
    authority_name_tr VARCHAR(200),
    country_code VARCHAR(3) NOT NULL,
    jurisdiction_type VARCHAR(50) NOT NULL
        CHECK (jurisdiction_type IN ('TAX','CUSTOMS','ZAKAT','HALAL','STANDARDS','TRADE')),
    official_website TEXT NOT NULL,
    regulations_url TEXT,
    api_endpoint TEXT,
    contact_email TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. LEGISLATION SOURCES (Kaynak Belgeler)
CREATE TABLE IF NOT EXISTS legislation_sources (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    legislation_id UUID REFERENCES legislations(id) ON DELETE CASCADE,
    authority_id UUID REFERENCES legal_authorities(id),
    source_type VARCHAR(50) NOT NULL
        CHECK (source_type IN ('ROYAL_DECREE','MINISTERIAL_RESOLUTION','CIRCULAR',
                               'GUIDELINE','FAQ','COURT_RULING','TREATY','LAW')),
    source_code VARCHAR(200),
    source_date DATE,
    title_en TEXT NOT NULL,
    title_ar TEXT,
    title_tr TEXT,
    url TEXT NOT NULL,
    url_verified_at DATE,
    url_is_active BOOLEAN DEFAULT TRUE,
    page_number VARCHAR(50),
    article_reference VARCHAR(100),
    reliability_tier INT NOT NULL DEFAULT 2
        CHECK (reliability_tier BETWEEN 1 AND 5),
    is_primary_source BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. MEVCUT TABLOLARI GENIŞLET (ALTER TABLE — silme yok)

-- legislations tablosuna yeni sütunlar
ALTER TABLE legislations
    ADD COLUMN IF NOT EXISTS authority_id UUID REFERENCES legal_authorities(id),
    ADD COLUMN IF NOT EXISTS source_url TEXT,
    ADD COLUMN IF NOT EXISTS applicability_scope VARCHAR(100) DEFAULT 'ALL'
        CHECK (applicability_scope IN ('ALL','B2B','B2C','RESIDENT_ONLY','NON_RESIDENT','INDIVIDUAL','COMPANY')),
    ADD COLUMN IF NOT EXISTS uncertainty_level VARCHAR(20) DEFAULT 'CERTAIN'
        CHECK (uncertainty_level IN ('CERTAIN','UNCERTAIN','UNKNOWN','INAPPLICABLE')),
    ADD COLUMN IF NOT EXISTS disclaimer TEXT,
    ADD COLUMN IF NOT EXISTS requires_professional_advice BOOLEAN DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS supersedes_id UUID REFERENCES legislations(id),
    ADD COLUMN IF NOT EXISTS superseded_by_id UUID REFERENCES legislations(id),
    ADD COLUMN IF NOT EXISTS announcement_date DATE,
    ADD COLUMN IF NOT EXISTS last_reviewed_at DATE;

-- tax_rules tablosuna yeni sütunlar
ALTER TABLE tax_rules
    ADD COLUMN IF NOT EXISTS hs_code VARCHAR(20),
    ADD COLUMN IF NOT EXISTS calculation_basis VARCHAR(30) DEFAULT 'AD_VALOREM'
        CHECK (calculation_basis IN ('AD_VALOREM','SPECIFIC','COMPOUND')),
    ADD COLUMN IF NOT EXISTS specific_amount_per_unit NUMERIC(15,4),
    ADD COLUMN IF NOT EXISTS uncertainty_level VARCHAR(20) DEFAULT 'CERTAIN'
        CHECK (uncertainty_level IN ('CERTAIN','UNCERTAIN','UNKNOWN','INAPPLICABLE')),
    ADD COLUMN IF NOT EXISTS requires_professional_advice BOOLEAN DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS source_url TEXT,
    ADD COLUMN IF NOT EXISTS inapplicability_reason TEXT,
    ADD COLUMN IF NOT EXISTS supersedes_rule_id UUID REFERENCES tax_rules(id),
    ADD COLUMN IF NOT EXISTS superseded_by_rule_id UUID REFERENCES tax_rules(id),
    ADD COLUMN IF NOT EXISTS transition_period_days INT DEFAULT 0,
    ADD COLUMN IF NOT EXISTS transition_rate NUMERIC(7,4),
    ADD COLUMN IF NOT EXISTS announcement_date DATE,
    ADD COLUMN IF NOT EXISTS change_summary TEXT;

-- companies tablosuna ZATCA alanları
ALTER TABLE companies
    ADD COLUMN IF NOT EXISTS zatca_vat_number VARCHAR(20),
    ADD COLUMN IF NOT EXISTS zatca_csid TEXT,
    ADD COLUMN IF NOT EXISTS zatca_production_csid TEXT,
    ADD COLUMN IF NOT EXISTS zatca_invoice_counter INT DEFAULT 0,
    ADD COLUMN IF NOT EXISTS zatca_last_invoice_hash TEXT;

-- 4. İNDEKSLER
CREATE INDEX IF NOT EXISTS idx_legal_authorities_code ON legal_authorities(authority_code, country_code);
CREATE INDEX IF NOT EXISTS idx_legislation_sources_leg ON legislation_sources(legislation_id, reliability_tier);
CREATE INDEX IF NOT EXISTS idx_tax_rules_hs ON tax_rules(hs_code) WHERE hs_code IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_tax_rules_uncertainty ON tax_rules(uncertainty_level);

-- 5. RLS
ALTER TABLE legal_authorities ENABLE ROW LEVEL SECURITY;
ALTER TABLE legislation_sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE legal_authorities FORCE ROW LEVEL SECURITY;
ALTER TABLE legislation_sources FORCE ROW LEVEL SECURITY;

-- legal_authorities herkese okunabilir (sistem seviyesi veri)
CREATE POLICY "legal_authorities_public_read" ON legal_authorities
    FOR SELECT USING (TRUE);
CREATE POLICY "legal_authorities_admin_manage" ON legal_authorities
    FOR ALL USING (is_platform_admin());

-- legislation_sources tenant üyelerine okunabilir
CREATE POLICY "legislation_sources_read" ON legislation_sources
    FOR SELECT USING (TRUE);  -- Public referans veri

-- 6. SEED DATA — Resmi Otoriteler
INSERT INTO legal_authorities (authority_code, authority_name_en, authority_name_ar, authority_name_tr, country_code, jurisdiction_type, official_website, regulations_url)
VALUES
  ('ZATCA',  'Zakat, Tax and Customs Authority',        'هيئة الزكاة والضريبة والجمارك', 'Zekât, Vergi ve Gümrük İdaresi', 'SAU', 'TAX',     'https://zatca.gov.sa', 'https://zatca.gov.sa/en/RulesRegulations/Pages/rules.aspx'),
  ('GIB',    'Revenue Administration of Turkey',        NULL, 'Gelir İdaresi Başkanlığı',    'TUR', 'TAX',     'https://gib.gov.tr',   'https://www.gib.gov.tr/mevzuat'),
  ('GCC_CG', 'GCC Customs Cooperation',                 'التعاون الجمركي لدول الخليج', NULL,  'SAU', 'CUSTOMS', 'https://gcc-sg.org',   'https://gcc-sg.org/en/customs'),
  ('SASO',   'Saudi Standards Organization',            'الهيئة السعودية للمواصفات',  NULL,  'SAU', 'STANDARDS','https://saso.gov.sa', NULL),
  ('FTA',    'UAE Federal Tax Authority',               'الهيئة الاتحادية للضرائب',   NULL,  'ARE', 'TAX',     'https://tax.gov.ae',   'https://tax.gov.ae/en/legislation'),
  ('HAZINE', 'Turkish Ministry of Treasury and Finance', NULL, 'Hazine ve Maliye Bakanlığı', 'TUR', 'TAX',    'https://hmb.gov.tr',   'https://www.hmb.gov.tr/mevzuat')
ON CONFLICT (authority_code) DO NOTHING;
```

---

## 3. Migrasyon 055 — SA/TR Kural Seed

```sql
-- ============================================================
-- MIGRATION 055: SA & TR LEGISLATION RULES + TARIFF ENGINE
-- ============================================================

-- gcc_tariff_codes, tariff_exemptions, withholding_tax_rules
-- compliance_check_rules + seed data
-- SA KDV, ÖTV, TR KDV kuralları seed verisi

[R03, R04, R06, R07, R11, R12 raporlarındaki CREATE TABLE ve INSERT komutları]
```

---

## 4. Migrasyon 056 — Zekât Motoru

```sql
-- ============================================================
-- MIGRATION 056: ZAKAT CALCULATION ENGINE
-- ============================================================

-- zakat_parameters, zakat_assessments, source_url_health_checks
-- calculate_zakat RPC

[R05 raporundaki CREATE TABLE ve CREATE FUNCTION komutları]
```

---

## 5. Migrasyon 057 — v2 RPC'ler

```sql
-- ============================================================
-- MIGRATION 057: TAX ENGINE V2 + COMPLIANCE ASSESSMENT
-- ============================================================

-- calculate_transaction_tax_v2 (mevcut v1 korunuyor — DEPRECATED ama silinmiyor)
-- assess_company_compliance RPC
-- detect_rule_conflicts fonksiyonu

[R11 raporundaki CREATE FUNCTION komutları]
```

---

## 6. Güvenlik Kontrol Listesi

Her migrasyonda doğrulanacak:

- [ ] Tüm yeni tablolarda `ENABLE ROW LEVEL SECURITY`
- [ ] Tüm yeni tablolarda `FORCE ROW LEVEL SECURITY`
- [ ] Cross-tenant erişim testi (`is_tenant_member`, `has_company_access`)
- [ ] `SECURITY DEFINER SET search_path = public` her yeni fonksiyonda
- [ ] Mevcut 021 security testleri hala geçiyor
- [ ] `flutter test` — 145+ test pass (yeni testler eklenir)

---

## 7. Rollback Planı

```sql
-- Herhangi bir migrasyon hata verirse güvenli geri alma:

-- 054 rollback:
DROP TABLE IF EXISTS legislation_sources;
DROP TABLE IF EXISTS legal_authorities;
-- ALTER TABLE DROP COLUMN (yeni sütunlar)

-- 055 rollback:
DROP TABLE IF EXISTS gcc_tariff_codes;
DROP TABLE IF EXISTS tariff_exemptions;
DROP TABLE IF EXISTS withholding_tax_rules;
DROP TABLE IF EXISTS compliance_check_rules;

-- 056 rollback:
DROP TABLE IF EXISTS zakat_assessments;
DROP TABLE IF EXISTS zakat_parameters;
DROP TABLE IF EXISTS source_url_health_checks;

-- 057 rollback:
DROP FUNCTION IF EXISTS calculate_transaction_tax_v2;
DROP FUNCTION IF EXISTS assess_company_compliance;
DROP FUNCTION IF EXISTS detect_rule_conflicts;

-- NOT: Mevcut 042 tabloları (legislations, tax_rules) asla silinmez
```

---

*Bu rapor R01 vizyon, R02 altyapı analizi ve R03-R12 kural motor raporları temelinde hazırlanmıştır.*
