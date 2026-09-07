# R05 — ZEKÂT HESAPLAMA MOTORU TASARIMI
## Saudi Arabia Zakat Calculation Engine

**Rapor No:** R05  
**Versiyon:** 1.0  
**Tarih:** 2026-09-07  
**Durum:** ONAY BEKLİYOR  
**Resmi Kaynak:** https://zatca.gov.sa/en/RulesRegulations/Pages/rules.aspx (1445H Zekât Yönetmeliği)

---

## 1. Yasal Dayanak

| Düzenleme | Yürürlük | Kapsam |
|---|---|---|
| 1445H Zekât Uygulama Yönetmeliği | 2024-01-01 (1445H yılıyla başlayan mali yıllar) | SA yerleşik Suudi sahipli şirketler |
| Royal Decree No. M/1 (Zekât Kanunu) | Tarihi | Temel yükümlülük |
| ZATCA Zekât Değerlendirme Rehberi 2024 | 2024-01-01 | Güncel hesaplama parametreleri |

> ⚠️ **KRİTİK UYARI**: Zekât hesaplama, her şirketin özgün mali tablolarına, sahiplik yapısına ve iş kolu kategorisine bağlıdır. Bu motor bir ön hesaplama/tahmin aracıdır. Resmi Zekât beyanı için ZATCA onaylı vergi danışmanı zorunludur.

> ⚠️ **KAPSAM SINIRI**: Bu motor **yalnızca SA yerleşik şirketlerde Suudi/GCC vatandaşı hissedarlara ait hisse oranı** için Zekât hesaplar. Yabancı hissedarlara ait pay gelir vergisine tabidir (Stopaj Vergisi — R07'de ele alınmıştır).

---

## 2. Zekât Matrahı Bileşenleri

### 2.1 Zekât Matrahı = Öz Kaynaklar + Uzun Vadeli Borçlar − Sabit Varlıklar − Uzun Vadeli Yatırımlar

```
Zekât Matrahı =
  (Ödenmiş Sermaye)
  + (Yedekler + Dağıtılmamış Kârlar)
  + (Uzun Vadeli Borçlar — işletme sermayesi için kullanılan kısım)
  − (Net Sabit Varlıklar — binalar, makine, ekipman)
  − (Uzun Vadeli Stratejik Yatırımlar — iştirakler)
  + (Net Dönen Varlıklar — stok + alacaklar − kısa vadeli borçlar)
```

**Sistematik Hesaplama Yöntemi** (1445H Yönetmeliği):

| Kalem | Artı (+) / Eksi (−) |
|---|---|
| Ödenmiş Sermaye | + |
| Yasal Yedekler | + |
| Olağanüstü Yedekler | + |
| Önceki Yıl Kârı (dağıtılmamış) | + |
| Cari Yıl Net Kârı | + |
| Uzun Vadeli Borçlar (≥1 yıl) | + |
| Maddi Duran Varlıklar (net defter değeri) | − |
| Maddi Olmayan Duran Varlıklar | − |
| Uzun Vadeli Yatırımlar (SA'da lisanslı şirket) | − |
| Verilen Uzun Vadeli Avanslar | − |

---

## 3. Zekât Oranı

```
Zekât Oranı: %2.5
Nisap (2024 itibarıyla): Yaklaşık 85 gram altın değeri = ~18,400 SAR
(Nisap altında kalan küçük işletmeler Zekât'tan muaf)
```

```
Zekât Tutarı = Zekât Matrahı × %2.5
```

> ⚠️ **UNCERTAINTY**: Nisap değeri altın fiyatına bağlıdır ve her yıl ZATCA tarafından güncellenir. Motor `nisab_threshold_sar` parametresini veritabanından okuyacak, hardcode etmeyecek.

---

## 4. Yeni Veritabanı Yapısı

### 4.1 `zakat_parameters` Tablosu

```sql
CREATE TABLE IF NOT EXISTS zakat_parameters (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    hijri_year VARCHAR(10) NOT NULL,           -- '1445', '1446', '1447'
    gregorian_year_start INT NOT NULL,         -- 2024
    gregorian_year_end INT NOT NULL,           -- 2025
    nisab_threshold_sar NUMERIC(15,2) NOT NULL, -- Altın nisabı SAR cinsinden
    zakat_rate NUMERIC(7,4) NOT NULL DEFAULT 2.5000,
    gold_price_per_gram_sar NUMERIC(10,2),    -- Hesaplama başvurusu
    legislation_reference TEXT,
    source_url TEXT NOT NULL,
    effective_from DATE NOT NULL,
    effective_to DATE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 4.2 `zakat_assessments` Tablosu

```sql
CREATE TABLE IF NOT EXISTS zakat_assessments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    company_id UUID NOT NULL REFERENCES companies(id),
    assessment_year VARCHAR(10) NOT NULL,      -- '1445H' veya '2024'
    assessment_date DATE NOT NULL,
    
    -- Matrah bileşenleri
    paid_capital NUMERIC(15,2) NOT NULL DEFAULT 0,
    legal_reserves NUMERIC(15,2) NOT NULL DEFAULT 0,
    retained_earnings NUMERIC(15,2) NOT NULL DEFAULT 0,
    current_year_profit NUMERIC(15,2) NOT NULL DEFAULT 0,
    long_term_debt NUMERIC(15,2) NOT NULL DEFAULT 0,
    fixed_assets_net NUMERIC(15,2) NOT NULL DEFAULT 0,
    intangible_assets NUMERIC(15,2) NOT NULL DEFAULT 0,
    long_term_investments NUMERIC(15,2) NOT NULL DEFAULT 0,
    long_term_advances NUMERIC(15,2) NOT NULL DEFAULT 0,
    
    -- Hesaplama sonuçları
    zakat_base NUMERIC(15,2),                 -- Hesaplanan matrah
    saudi_ownership_ratio NUMERIC(5,4),        -- Suudi hisse oranı (0.0-1.0)
    zakat_liable_base NUMERIC(15,2),          -- Suudi hisseye düşen matrah
    zakat_rate NUMERIC(7,4) DEFAULT 2.5000,
    zakat_amount NUMERIC(15,2),               -- Ödenecek Zekât
    
    -- Eşik kontrolü
    nisab_threshold_sar NUMERIC(15,2),
    is_below_nisab BOOLEAN DEFAULT FALSE,
    
    -- Uyum durumu
    status VARCHAR(30) DEFAULT 'DRAFT'
        CHECK (status IN ('DRAFT','CALCULATED','SUBMITTED_TO_ZATCA','PAID','DISPUTED')),
    disclaimer TEXT NOT NULL DEFAULT 'Bu hesaplama ön tahminden ibarettir. Resmi Zekât beyanı için ZATCA onaylı danışman gereklidir.',
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 5. Zekât Hesaplama RPC

```sql
CREATE OR REPLACE FUNCTION calculate_zakat(
    p_tenant_id UUID,
    p_company_id UUID,
    p_assessment_year VARCHAR,
    p_paid_capital NUMERIC,
    p_legal_reserves NUMERIC,
    p_retained_earnings NUMERIC,
    p_current_year_profit NUMERIC,
    p_long_term_debt NUMERIC,
    p_fixed_assets_net NUMERIC,
    p_intangible_assets NUMERIC,
    p_long_term_investments NUMERIC,
    p_long_term_advances NUMERIC,
    p_saudi_ownership_ratio NUMERIC  -- 0.0 to 1.0
)
RETURNS TABLE (
    zakat_base NUMERIC,
    zakat_liable_base NUMERIC,
    zakat_amount NUMERIC,
    is_below_nisab BOOLEAN,
    nisab_threshold_sar NUMERIC,
    uncertainty_level VARCHAR,
    disclaimer TEXT,
    source_url TEXT
) AS $$
...
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;
```

---

## 6. Hisse Oranı Mantığı

ZATCA kuralına göre:
- **Suudi + GCC hissedarlar**: Zekât'a tabi
- **Yabancı hissedarlar**: Gelir vergisine tabi (stopaj)
- **Karma yapı**: Oransal hesaplama

```
Zekât Yükümlülüğü = Zekât Matrahı × Suudi Hisse Oranı × %2.5
Gelir Vergisi Yükümlülüğü = Matrah × Yabancı Hisse Oranı × Gelir Vergisi Oranı
```

---

## 7. Test Vakaları

| Test | Girdi | Beklenen Çıktı |
|---|---|---|
| Tam Suudi sahipli şirket, matrah 1M SAR | Saudi ratio: 1.0 | Zekât: 25,000 SAR |
| %50 Suudi / %50 yabancı, matrah 1M SAR | Saudi ratio: 0.5 | Zekât: 12,500 SAR |
| Nisap altında (matrah 15,000 SAR) | < nisab threshold | is_below_nisab: true, zakat: 0 |
| Negatif matrah | Hesaplama yok | UNKNOWN + danışman önerisi |

---

## 8. Dart Servis Katmanı

Yeni `ZakatCalculationService` sınıfı:

```dart
class ZakatCalculationService {
  Future<ZakatAssessmentResult> calculateZakat({
    required String companyId,
    required String assessmentYear,
    required ZakatBalanceSheet balanceSheet,
    required double saudiOwnershipRatio,
  }) async { ... }
  
  Future<List<ZakatParameter>> getZakatParameters(String hijriYear) async { ... }
  
  Future<void> saveAssessment(ZakatAssessmentResult result) async { ... }
}
```

---

*Resmi Kaynak: ZATCA Zekât Kuralları — https://zatca.gov.sa/en/RulesRegulations/Pages/rules.aspx*  
*1445H Zekât Uygulama Yönetmeliği — 2024-01-01 yürürlük tarihli*
