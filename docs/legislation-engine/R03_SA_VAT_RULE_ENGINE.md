# R03 — SUUDİ ARABİSTAN KDV KURAL MOTORU TASARIMI
## ZATCA VAT Engine — Tam Kural Seti

**Rapor No:** R03  
**Versiyon:** 1.0  
**Tarih:** 2026-09-07  
**Durum:** ONAY BEKLİYOR  
**Resmi Kaynak:** https://zatca.gov.sa/en/RulesRegulations/VAT/Pages/default1.aspx

---

## 1. Yasal Dayanak

| Düzenleme | Yürürlük | Kapsam |
|---|---|---|
| KDV Kanunu (Royal Decree M/113) | 2018-01-01 | SA KDV'nin temel yasal dayanağı |
| KDV Uygulama Yönetmeliği | 2018-01-01 | Oran, muafiyet, iade kuralları |
| ZATCA KDV Rehberi 2024 | 2024-01-01 | Güncel uygulama notları |
| 1445H Zekât ve Vergi Uygulama Yönetmeliği | 2024-01-01 | Zekât + VAT birleşik kurallar |

> ⚠️ **HUKUKİ UYARI**: Bu rapor uyum motoru tasarımı içindir, hukuki danışmanlık vermez. Nihai kararlar için yetkili bir ZATCA onaylı danışmana başvurun.

---

## 2. SA KDV Kural Sınıflandırması

### 2.1 Standart Oran — %15

```
rule_code: SA_VAT_STANDARD_15
tax_type: VAT
rate: 15.0000
effective_from: 2020-07-01   (2018-2020 arası %5'ten %15'e artırıldı)
effective_to: NULL
country_code: SA
jurisdiction: SA-ZATCA
source_url: https://zatca.gov.sa/en/RulesRegulations/VAT/
transaction_type: ALL
is_reverse_charge: FALSE
```

**Kapsadığı işlemler**:
- Çoğu mal ve hizmet satışı
- İhraç edilen ancak SA içinde teslim edilen mallar
- Dijital hizmetler (yabancı tedarikçiden SA alıcıya)
- Gayrimenkul (sınırlı muafiyetler dışında)

---

### 2.2 Sıfır Oranlı İşlemler — %0

```
rule_code: SA_VAT_ZERO_EXPORT
tax_type: VAT
rate: 0.0000
effective_from: 2018-01-01
country_code: SA
jurisdiction: SA-ZATCA
transaction_type: EXPORT
source_url: https://zatca.gov.sa/en/RulesRegulations/VAT/
```

**Kapsadığı işlemler**:
- SA'dan ihracat (fiziksel mal)
- Uluslararası taşımacılık hizmetleri
- Diplomatik muafiyetler
- GCC üye devletlere ihracat (geçici sıfır oran — kalıcı olmayabilir, `UNCERTAIN` flag)

---

### 2.3 KDV'den Muaf İşlemler

```
rule_code: SA_VAT_EXEMPT_FINANCIAL
tax_type: VAT
rate: 0.0000
effective_from: 2018-01-01
uncertainty_level: CERTAIN
```

**Muaf işlem kategorileri**:

| Kategori | Kural Kodu |
|---|---|
| Finansal hizmetler (ücret bazlı olanlar muaf değil) | SA_VAT_EXEMPT_FINANCIAL |
| Hayat sigortası | SA_VAT_EXEMPT_LIFE_INSURANCE |
| Konut amaçlı kira (ilk teslim hariç) | SA_VAT_EXEMPT_RESIDENTIAL_RENT |
| Tıbbi hizmetler (temel sağlık) | SA_VAT_EXEMPT_MEDICAL |
| Eğitim hizmetleri (lisanslı) | SA_VAT_EXEMPT_EDUCATION |
| Yerel yolcu taşımacılığı (bazı istisnalar) | SA_VAT_EXEMPT_LOCAL_TRANSPORT |

> 🔴 **UNKNOWN Durumu**: Karma kullanımlı gayrimenkul (ticari + konut) muafiyeti belirsiz durumlarda `uncertainty_level: UNKNOWN` ile işaretlenecek. Sistem tahmin üretmez, resmi kaynağa yönlendirir.

---

### 2.4 Reverse Charge (Tersine Yükleme)

```
rule_code: SA_VAT_REVERSE_CHARGE_IMPORT_SERVICES
tax_type: VAT
rate: 15.0000
is_reverse_charge: TRUE
transaction_type: IMPORT
```

**Kapsam**: SA'ya giren yabancı kaynaklı hizmetler — SA'lı alıcı KDV'yi beyan eder ve öder.

---

## 3. Fatura Tipleri — ZATCA Kategorisi

| Fatura Tipi | ZATCA Kodu | İşlem Yöntemi |
|---|---|---|
| Standart Vergi Faturası | 388 | B2B Clearance (anlık onay) |
| Basitleştirilmiş Vergi Faturası | 381 | B2C Reporting (24 saat içinde) |
| Alacak Dekontu | 381/CR | Standart/Basitleştirilmiş bağlı |
| Borç Dekontu | 381/DR | Standart/Basitleştirilmiş bağlı |

---

## 4. Önerilen Kural Kayıtları — Seed Data

Migrasyon `055_sa_vat_rules_seed.sql` içinde şu kayıtlar oluşturulacak:

```sql
-- 1. SA KDV Standart %15
INSERT INTO tax_rules (tenant_id, company_id, legislation_id, rule_code, ...)
VALUES (
  SYSTEM_TENANT,
  NULL,  -- Şirket bağımsız sistem kuralı
  (SELECT id FROM legislations WHERE legislation_code = 'ZATCA_VAT_2020'),
  'SA_VAT_STANDARD_15',
  'VAT', 15.0000, 'SA', 'SA-ZATCA',
  '2020-07-01', NULL, 'ALL',
  FALSE, TRUE, 1000,
  'https://zatca.gov.sa/en/RulesRegulations/VAT/',
  'Royal Decree M/113 — Art. 7',
  'CERTAIN'
);

-- 2. SA KDV Sıfır — İhracat
INSERT INTO tax_rules (...) VALUES (
  ..., 'SA_VAT_ZERO_EXPORT', 'VAT', 0.0000, 'SA', 'SA-ZATCA',
  '2018-01-01', NULL, 'EXPORT',
  FALSE, TRUE, 900,
  'https://zatca.gov.sa/en/RulesRegulations/VAT/',
  'Royal Decree M/113 — Art. 33',
  'CERTAIN'
);
```

---

## 5. `calculate_transaction_tax_v2` Çıktı Genişletmesi

Mevcut `calculate_transaction_tax` fonksiyonu şunları döner:
`rule_id, rule_code, tax_type, rate, tax_amount, total_amount, is_reverse_charge, is_recoverable, legislation_code, legislation_version`

**Yeni v2 fonksiyonu ek olarak şunları döner**:

```sql
source_url          VARCHAR,    -- Resmi ZATCA/GİB link
source_reference    VARCHAR,    -- Kanun maddesi referansı
uncertainty_level   VARCHAR,    -- CERTAIN / UNCERTAIN / UNKNOWN
disclaimer          TEXT,       -- Zorunlu hukuki uyarı metni
calculation_basis   VARCHAR,    -- AD_VALOREM / SPECIFIC / COMPOUND
additional_taxes    JSONB       -- Eş zamanlı ÖTV vb. için
```

---

## 6. Test Vakaları

| Test | Beklenen Sonuç |
|---|---|
| SA'da B2B satış, tarih 2020-08-01 | %15 KDV, SA_VAT_STANDARD_15, CERTAIN |
| SA'dan ihracat, tarih 2021-03-15 | %0 KDV, SA_VAT_ZERO_EXPORT, CERTAIN |
| SA'ya gelen dijital hizmet, tarih 2022-01-01 | %15 Reverse Charge |
| Tıbbi ürün satışı | SA_VAT_EXEMPT_MEDICAL, %0, CERTAIN |
| Bilinmeyen kategori | DEFAULT_ZERO veya UNKNOWN |

---

*Resmi Kaynak: ZATCA VAT Rules — https://www.zatca.gov.sa/en/RulesRegulations/VAT/Pages/default1.aspx*  
*Bu rapor R01 (Vizyon) ve R02 (Altyapı Analizi) üzerine inşa edilmiştir.*
