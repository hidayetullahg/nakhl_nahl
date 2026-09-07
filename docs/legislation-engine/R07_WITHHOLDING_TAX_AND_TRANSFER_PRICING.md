# R07 — STOPAJ VERGİSİ VE TRANSFER FİYATLANDIRMASI
## Withholding Tax & Transfer Pricing Engine

**Rapor No:** R07  
**Versiyon:** 1.0  
**Tarih:** 2026-09-07  
**Durum:** ONAY BEKLİYOR  
**Resmi Kaynak:** https://zatca.gov.sa/en/RulesRegulations/Pages/rules.aspx

---

## 1. Yasal Dayanak

| Düzenleme | Yürürlük | Kapsam |
|---|---|---|
| SA Gelir Vergisi Yönetmeliği | 2004 (son revize 2024) | Yabancı kişi/kuruma yapılan ödemeler |
| Çifte Vergilendirmeyi Önleme Anlaşmaları (DTAA) | Ülkeye göre değişir | Anlaşma oranı CET oranının altında olabilir |
| Transfer Fiyatlandırması Yönetmeliği (Ministerial Resolution 1146) | 2019 | İlişkili taraf işlem eşikleri |

> ⚠️ **HUKUKİ UYARI**: Stopaj vergisi oranları çifte vergilendirme anlaşmasına, ödeme tipine ve alıcının ülkesine göre değişir. Bu motor başlangıç noktası sağlar; kesin oran için ZATCA onaylı danışman gereklidir.

---

## 2. Stopaj Vergisi Oranları

### 2.1 SA'dan Yabancı Alıcıya Yapılan Ödemeler — Genel Oranlar

| Ödeme Tipi | Genel Oran | Notlar |
|---|---|---|
| Hizmet bedeli (Teknik, Yönetim, Danışmanlık) | %20 | En yüksek kategori |
| Royalty / Lisans | %15 | Fikri mülkiyet |
| Faiz ödemeleri | %5 | Bankacılık işlemleri hariç |
| Sigorta/Reasürans primleri | %5 | |
| Uluslararası taşımacılık | %5 | Kaptan/kargo bedeli |
| Temettü | %0 | SA'da stopaj yok (genel kural) |
| Kiralama bedeli | %15 | |
| Diğer hizmetler | %15 | Genel kategori |

### 2.2 DTAA Anlaşma Oranları (Örnekler)

| Ülke | Anlaşma Oranı (Hizmet) | Anlaşma Oranı (Royalty) |
|---|---|---|
| Türkiye | %10 | %10 |
| Almanya | %15 | %15 |
| Fransa | %15 | %15 |
| Hindistan | %15 | %10 |
| Çin | %10 | %10 |
| Anlaşmasız ülkeler | %20 (genel oran) | %15 |

> **Önemli**: DTAA oranları genel oranın altında olabilir; sistem her iki oranı da hesaplayıp düşük olanı önerir, ancak `UNCERTAIN` flag atar — çünkü DTAA uygulaması ayrıca form/belge gerektirebilir.

---

## 3. Yeni Veritabanı Yapısı

### 3.1 `withholding_tax_rules` Tablosu

```sql
CREATE TABLE IF NOT EXISTS withholding_tax_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Kural tanımı
    rule_code VARCHAR(100) NOT NULL,
    payment_type VARCHAR(100) NOT NULL,   -- SERVICE, ROYALTY, INTEREST, RENT, INSURANCE, TRANSPORT
    
    -- Alıcı ülke
    recipient_country_code VARCHAR(3),    -- NULL = tüm ülkeler (genel kural)
    treaty_exists BOOLEAN DEFAULT FALSE,
    treaty_name TEXT,
    treaty_effective_from DATE,
    
    -- Oranlar
    general_rate NUMERIC(7,4) NOT NULL,          -- Anlaşmasız/genel oran
    treaty_rate NUMERIC(7,4),                    -- DTAA oranı (varsa)
    effective_rate NUMERIC(7,4) GENERATED ALWAYS AS
        (LEAST(general_rate, COALESCE(treaty_rate, general_rate))) STORED,
    
    -- Geçerlilik
    effective_from DATE NOT NULL,
    effective_to DATE,
    
    -- Uyum
    requires_form VARCHAR(100),              -- Zorunlu form (W-8BEN vb.)
    requires_residence_certificate BOOLEAN DEFAULT FALSE,
    
    -- Kaynak
    source_url TEXT,
    uncertainty_level VARCHAR(20) DEFAULT 'CERTAIN',
    disclaimer TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 4. Transfer Fiyatlandırması Eşik Kontrolü

### 4.1 Bildirim Eşikleri (2024 itibarıyla)

```
İlişkili taraf işlem toplamı ≥ 100M SAR/yıl → Ülke Bazlı Raporlama (CbCR) zorunlu
İlişkili taraf işlem toplamı ≥ 6M SAR/yıl → Ana Dosya (Master File) zorunlu
Her ilişkili taraf işlemi → Yerel Dosya (Local File) zorunlu
```

### 4.2 `transfer_pricing_thresholds` Tablosu

```sql
CREATE TABLE IF NOT EXISTS transfer_pricing_thresholds (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    threshold_type VARCHAR(50) NOT NULL,    -- CBCR, MASTER_FILE, LOCAL_FILE
    annual_amount_sar NUMERIC(15,2) NOT NULL,
    requirement TEXT NOT NULL,
    effective_from DATE NOT NULL,
    effective_to DATE,
    source_url TEXT,
    uncertainty_level VARCHAR(20) DEFAULT 'CERTAIN'
);
```

### 4.3 Uyum Uyarısı Mantığı

```dart
class TransferPricingChecker {
  /// İlişkili taraf işlem toplamını kontrol et
  Future<TransferPricingAlert?> checkThreshold({
    required String companyId,
    required String fiscalYear,
  }) async {
    final total = await _getRelatedPartyTotal(companyId, fiscalYear);
    
    if (total >= 100_000_000) {
      return TransferPricingAlert(
        level: AlertLevel.critical,
        requirement: 'Country-by-Country Reporting (CbCR) zorunlu',
        deadline: '...',
        sourceUrl: 'https://zatca.gov.sa/...',
      );
    }
    if (total >= 6_000_000) {
      return TransferPricingAlert(
        level: AlertLevel.warning,
        requirement: 'Master File (Ana Dosya) zorunlu',
      );
    }
    return null;
  }
}
```

---

## 5. Stopaj Vergisi Hesaplama RPC

```sql
CREATE OR REPLACE FUNCTION calculate_withholding_tax(
    p_tenant_id UUID,
    p_company_id UUID,
    p_payment_type VARCHAR,           -- SERVICE, ROYALTY, INTEREST, RENT
    p_recipient_country_code VARCHAR,
    p_payment_amount NUMERIC(15,2),
    p_payment_date DATE,
    p_has_treaty_certificate BOOLEAN DEFAULT FALSE
)
RETURNS TABLE (
    payment_type VARCHAR,
    recipient_country VARCHAR,
    general_rate NUMERIC,
    treaty_rate NUMERIC,
    applicable_rate NUMERIC,
    withholding_amount NUMERIC,
    net_payment NUMERIC,
    treaty_exists BOOLEAN,
    requires_certificate BOOLEAN,
    uncertainty_level VARCHAR,
    disclaimer TEXT,
    source_url TEXT
) ...
```

### Örnek Hesaplama

```
Türkiye'deki danışmana yapılan hizmet bedeli: 500,000 SAR

DTAA mevcut (SA-TR): Hizmet oranı %10
Genel oran: %20
Uygulanacak oran: %10 (DTAA — Sertifika ile)

Stopaj Tutarı: 50,000 SAR
Net Ödeme: 450,000 SAR

[UNCERTAIN]: DTAA uygulaması için İkamet Belgesi gereklidir.
Belge olmadan genel oran (%20 = 100,000 SAR) uygulanır.
```

---

## 6. Test Vakaları

| Test | Girdi | Beklenen Çıktı |
|---|---|---|
| TR'ye hizmet bedeli, DTAA var, sertifika var | 500K SAR | Stopaj: 50K SAR (%10), CERTAIN |
| TR'ye hizmet bedeli, DTAA var, sertifika yok | 500K SAR | Stopaj: 100K SAR (%20), UNCERTAIN |
| Anlaşmasız ülkeye royalty | 100K SAR | Stopaj: 15K SAR (%15), CERTAIN |
| Temettü ödemesi | Herhangi | Stopaj: 0 SAR, CERTAIN |
| İlişkili taraf toplamı 150M SAR | Yıllık | CbCR ZORUNLU — Critical Alert |

---

*Resmi Kaynak: SA Gelir Vergisi, ZATCA DTAA Listesi*  
*https://zatca.gov.sa/en/RulesRegulations/Pages/rules.aspx*
