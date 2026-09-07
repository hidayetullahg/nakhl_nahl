# R04 — ÖZEL TÜKETİM VERGİSİ (ÖTV / EXCISE TAX) KURAL MOTORU
## Saudi Arabia Excise Tax Engine

**Rapor No:** R04  
**Versiyon:** 1.0  
**Tarih:** 2026-09-07  
**Durum:** ONAY BEKLİYOR  
**Resmi Kaynak:** https://zatca.gov.sa/en/RulesRegulations/Pages/rules.aspx

---

## 1. Yasal Dayanak

| Düzenleme | Yürürlük | Kapsam |
|---|---|---|
| Özel Tüketim Vergisi Kanunu (Royal Decree M/52) | 2017-06-10 | SA ÖTV temel kanunu |
| GCC Birleşik ÖTV Çerçeve Anlaşması | 2017-01-01 | GCC üyelerini bağlayan çerçeve |
| ZATCA ÖTV Uygulama Tebliğleri (2020-2024) | Çeşitli | Ürün listeleri ve oran güncellemeleri |

> ⚠️ **HUKUKİ UYARI**: Alkol içeren ürünler İslam hukuku uyarınca SA'da yasaklıdır; bu kategorideki kurallar `INAPPLICABLE_ISLAMIC_LAW` statüsü alır. Sistem bu kategoriler için hiçbir hesaplama üretmez.

---

## 2. ÖTV Ürün Kategorileri ve Oranlar

### 2.1 Tütün ve Tütün Ürünleri — %100

```
rule_code: SA_EXCISE_TOBACCO_100
tax_type: EXCISE
rate: 100.0000
calculation_basis: AD_VALOREM
effective_from: 2017-06-10
effective_to: NULL
country_code: SA
jurisdiction: SA-ZATCA
uncertainty_level: CERTAIN
source_url: https://zatca.gov.sa/en/RulesRegulations/Pages/rules.aspx
```

**Kapsadığı ürünler** (HS kodları ile):
| Ürün | HS Kodu | Oran |
|---|---|---|
| Sigara | 2402.20 | %100 |
| Puro | 2402.10 | %100 |
| Nargile tütünü (Tütün içerenler) | 2403.11 | %100 |
| İsıtılmış tütün ürünleri (IQOS vb.) | 2403.99 | %100 |
| Elektronik sigara (Nikotin içeren) | 2404.11 | %100 |

---

### 2.2 Karbonlı İçecekler (Gazlı İçecekler) — %50

```
rule_code: SA_EXCISE_CARBONATED_50
tax_type: EXCISE
rate: 50.0000
calculation_basis: AD_VALOREM
effective_from: 2017-06-10
```

**Kapsadığı ürünler**:
| Ürün | HS Kodu | Oran |
|---|---|---|
| Karbonatlı meşrubat (kola, limonata) | 2202.10 | %50 |
| Karbonatlı meyve suyu | 2202.91 | %50 |

**Kapsam DIŞI** (EXEMPT):
- Sade maden suyu (karbonatlı, aromasız) — `SA_EXCISE_CARBONATED_EXEMPT_MINERAL`
- Tıbbi amaçlı karbonlı içecekler (reçeteli)

---

### 2.3 Enerji İçecekleri — %100

```
rule_code: SA_EXCISE_ENERGY_DRINK_100
tax_type: EXCISE
rate: 100.0000
calculation_basis: AD_VALOREM
effective_from: 2017-06-10
```

**Kapsadığı ürünler**:
| Ürün | HS Kodu | Oran |
|---|---|---|
| Enerji içecekleri (kafein + taurin) | 2202.99 | %100 |
| "Enerji Shot" konsantreleri | 2202.99 | %100 |

**Belirsizlik Durumu**: Bazı sporcu içecekleri için enerji içeceği sınıflandırması tartışmalıdır. Bu ürünler için `uncertainty_level: UNCERTAIN` atanacak ve resmi ZATCA karar talebi önerilecek.

---

### 2.4 Alkol — UYGULANAMAZ (İslam Hukuku)

```
rule_code: SA_EXCISE_ALCOHOL_INAPPLICABLE
tax_type: EXCISE
rate: NULL
status: INAPPLICABLE_ISLAMIC_LAW
uncertainty_level: INAPPLICABLE
note: "Alcohol is prohibited under Islamic law in Saudi Arabia. No tax calculation applicable."
```

> 🚫 **TASARIM KARARI**: Motor bu kategori için hiçbir zaman vergi hesaplamaz. Kullanıcı UI'da bu kategoriyi seçerse açıklayıcı mesaj gösterilir ve form engellenir.

---

## 3. ÖTV + KDV Birleşik Hesaplama

Önemli kural: SA'da ÖTV, KDV matrahına dahildir.

**Örnek — Karbonlı İçecek 100 SAR CIF değerinde**:
```
Mal değeri:          100.00 SAR
ÖTV (%50):            50.00 SAR
KDV matrahı:         150.00 SAR  (ÖTV dahil)
KDV (%15 × 150):      22.50 SAR
───────────────────────────────
TOPLAM:              172.50 SAR
```

`calculate_transaction_tax_v2` bu birleşik hesaplamayı `additional_taxes JSONB` alanıyla destekleyecek:

```json
{
  "primary_tax": {
    "rule_code": "SA_VAT_STANDARD_15",
    "rate": 15.0,
    "base": 150.00,
    "amount": 22.50
  },
  "additional_taxes": [
    {
      "rule_code": "SA_EXCISE_CARBONATED_50",
      "rate": 50.0,
      "base": 100.00,
      "amount": 50.00
    }
  ],
  "total_tax": 72.50,
  "grand_total": 172.50
}
```

---

## 4. ÖTV Fatura Gereksinimleri (ZATCA)

ÖTV'ye tabi ürünler içeren ZATCA faturasında zorunlu alanlar:

| Alan | Örnek Değer |
|---|---|
| Excise Product Code | `TOBACCO_CIGARETTE` |
| HS Code | `2402.20` |
| Excise Rate | `100%` |
| Excise Amount | Açıkça gösterilmeli |
| Excise Registration Number | Üreticinin ÖTV kayıt no. |

---

## 5. Yeni Sütunlar — `tax_rules` ALTER TABLE

```sql
ALTER TABLE tax_rules ADD COLUMN IF NOT EXISTS
    hs_code VARCHAR(20),                    -- HS Tarife Kodu (6-8 basamak)
    calculation_basis VARCHAR(30)           -- AD_VALOREM / SPECIFIC / COMPOUND
        CHECK (calculation_basis IN ('AD_VALOREM','SPECIFIC','COMPOUND')),
    specific_amount_per_unit NUMERIC(15,4), -- Spesifik vergi (kg/lt başına SAR)
    uncertainty_level VARCHAR(20)           -- CERTAIN / UNCERTAIN / UNKNOWN / INAPPLICABLE
        CHECK (uncertainty_level IN ('CERTAIN','UNCERTAIN','UNKNOWN','INAPPLICABLE')),
    requires_professional_advice BOOLEAN NOT NULL DEFAULT FALSE,
    source_url TEXT,
    inapplicability_reason TEXT;            -- İslam hukuku vb. için açıklama
```

---

## 6. Test Vakaları

| Test | Beklenen Sonuç |
|---|---|
| Sigara kutusu (100 SAR) | ÖTV 100 SAR + KDV 30 SAR = Toplam 230 SAR |
| Kola (100 SAR) | ÖTV 50 SAR + KDV 22.5 SAR = Toplam 172.5 SAR |
| Enerji içeceği (100 SAR) | ÖTV 100 SAR + KDV 30 SAR = Toplam 230 SAR |
| Alkol kategorisi seçimi | INAPPLICABLE — hesaplama engellendi |
| Bilinmeyen enerji içeceği | UNCERTAIN — danışman önerisi |

---

*Resmi Kaynak: ZATCA Excise Tax — https://zatca.gov.sa/en/RulesRegulations/Pages/rules.aspx*
