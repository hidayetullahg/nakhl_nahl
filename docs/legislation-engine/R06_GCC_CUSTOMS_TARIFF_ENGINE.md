# R06 — GCC GÜMRÜK TARİFE MOTORU TASARIMI
## GCC Common External Tariff (CET) Engine

**Rapor No:** R06  
**Versiyon:** 1.0  
**Tarih:** 2026-09-07  
**Durum:** ONAY BEKLİYOR  
**Resmi Kaynak:** https://zatca.gov.sa/en/RulesRegulations/Pages/rules.aspx (Gümrük Bölümü)

---

## 1. Yasal Dayanak

| Düzenleme | Yürürlük | Kapsam |
|---|---|---|
| GCC Common Customs Law | 2003 (revize 2024) | GCC üye devletleri arasında birleşik gümrük |
| GCC Common External Tariff (CET) | 2003 | SA, BAE, Kuveyt, Bahreyn, Katar, Umman ortak tarife |
| SA Customs Law (Royal Decree M/41) | 2017 | SA spesifik gümrük kuralları |
| ZATCA Entegre Gümrük Tarifesi | Sürekli güncellenen | SA'ya özel tarife bildirgesi (HS kodu bazlı) |

> ⚠️ **HUKUKİ UYARI**: Gümrük tarifesi sınıflandırması uzman gerektiren bir süreçtir. HS kodunun yanlış sınıflandırılması gümrük cezasına yol açabilir. Bu motor referans amaçlıdır; resmi gümrük müşaviri onayı zorunludur.

---

## 2. GCC CET Yapısı

### 2.1 Temel Oran Kategorileri

| Kategori | Oran | Örnekler |
|---|---|---|
| Serbest (Tarife Dışı) | %0 | Ham tarım ürünleri, çoğu ilaç |
| Düşük Tarife | %5 | Çoğu sanayi girdisi, hammadde |
| Standart Tarife | %5 | GCC CET genel oranı |
| Yüksek Tarife | %10-20 | İşlenmiş gıda, tekstil |
| Koruyucu Tarife | %25+ | Yerel endüstriyi koruma |
| Yasak/Kısıtlı | PROHIBITED | Silahlar, bazı kimyasallar |

> **GCC CET'te en yaygın oran %5'tir.** SA bazı kategorilerde istisna uygulamaktadır.

---

### 2.2 SA Spesifik Muafiyetler

| Kategori | HS Kodu Aralığı | SA Oranı | GCC CET Oranı |
|---|---|---|---|
| Temel gıdalar (buğday, pirinç, şeker) | 1001-1701 (kısmi) | %0 | %5 |
| İlaç ürünleri | 3004 | %0 | %0 |
| Tıbbi cihazlar | 9018-9022 | %0-5 | %5 |
| Petrokimya hammadde | 2901-2942 | %0-6 | %5 |
| Alkol ve alkollü içkiler | 2203-2208 | YASAK | %0-200+ |

---

## 3. Yeni Veritabanı Yapısı

### 3.1 `gcc_tariff_codes` Tablosu

```sql
CREATE TABLE IF NOT EXISTS gcc_tariff_codes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- HS Kod hiyerarşisi
    hs_chapter VARCHAR(2) NOT NULL,       -- 01-99 (Bölüm)
    hs_heading VARCHAR(4) NOT NULL,       -- 0101-9999 (Başlık)
    hs_subheading VARCHAR(6) NOT NULL,    -- 010101-999999 (Alt Başlık, 6 basamak)
    hs_national VARCHAR(8),              -- SA ulusal tarife kodu (8 basamak)
    
    -- Tanım
    description_en TEXT NOT NULL,
    description_ar TEXT,
    description_tr TEXT,
    
    -- Tarife oranları
    gcc_cet_rate NUMERIC(7,4) NOT NULL,          -- GCC ortak dış tarife %
    sa_specific_rate NUMERIC(7,4),               -- SA spesifik oran (farklıysa)
    effective_rate NUMERIC(7,4) GENERATED ALWAYS AS
        (COALESCE(sa_specific_rate, gcc_cet_rate)) STORED,
    
    -- Ek vergiler
    excise_applicable BOOLEAN DEFAULT FALSE,
    excise_rate NUMERIC(7,4),
    
    -- Kısıtlamalar
    import_status VARCHAR(30) DEFAULT 'ALLOWED'
        CHECK (import_status IN ('ALLOWED','RESTRICTED','PROHIBITED','LICENSE_REQUIRED')),
    restriction_notes TEXT,
    
    -- Geçerlilik
    effective_from DATE NOT NULL,
    effective_to DATE,
    
    -- Kaynak
    source_url TEXT NOT NULL
        DEFAULT 'https://zatca.gov.sa/en/RulesRegulations/Pages/rules.aspx',
    uncertainty_level VARCHAR(20) DEFAULT 'CERTAIN'
        CHECK (uncertainty_level IN ('CERTAIN','UNCERTAIN','UNKNOWN')),
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT uq_hs_code UNIQUE (hs_subheading, effective_from)
);

-- Arama indeksleri
CREATE INDEX idx_gcc_tariff_hs ON gcc_tariff_codes(hs_subheading, effective_from, effective_to);
CREATE INDEX idx_gcc_tariff_chapter ON gcc_tariff_codes(hs_chapter, hs_heading);
CREATE INDEX idx_gcc_tariff_description ON gcc_tariff_codes USING gin(to_tsvector('english', description_en));
```

### 3.2 `tariff_exemptions` Tablosu

```sql
CREATE TABLE IF NOT EXISTS tariff_exemptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    hs_code VARCHAR(8) NOT NULL,
    exemption_type VARCHAR(50) NOT NULL
        CHECK (exemption_type IN ('FULL','PARTIAL','CONDITIONAL')),
    exemption_basis TEXT NOT NULL,         -- 'Royal Decree', 'Free Trade Agreement', 'Diplomatic'
    exemption_rate NUMERIC(7,4),           -- Muaf oran (tam muaf = 0.0)
    conditions TEXT,
    requires_documentation BOOLEAN DEFAULT TRUE,
    required_documents JSONB,
    effective_from DATE NOT NULL,
    effective_to DATE,
    source_url TEXT
);
```

---

## 4. Gümrük Hesaplama RPC

```sql
CREATE OR REPLACE FUNCTION calculate_customs_duty(
    p_tenant_id UUID,
    p_company_id UUID,
    p_hs_code VARCHAR(8),
    p_cif_value NUMERIC(15,2),     -- Cost + Insurance + Freight
    p_import_date DATE,
    p_origin_country VARCHAR(3),   -- ISO 3166-1 alpha-3
    p_has_exemption BOOLEAN DEFAULT FALSE,
    p_exemption_basis TEXT DEFAULT NULL
)
RETURNS TABLE (
    hs_code VARCHAR,
    description_en TEXT,
    gcc_cet_rate NUMERIC,
    sa_specific_rate NUMERIC,
    effective_rate NUMERIC,
    customs_duty NUMERIC,
    excise_applicable BOOLEAN,
    excise_amount NUMERIC,
    vat_base NUMERIC,              -- CIF + Customs + Excise
    vat_amount NUMERIC,
    total_landed_cost NUMERIC,
    import_status VARCHAR,
    uncertainty_level VARCHAR,
    disclaimer TEXT
) ...
```

### Örnek Hesaplama Akışı

```
Ürün: Akıllı telefon (HS 8517.13)
CIF Değer: 1,000 SAR

GCC CET Oranı:     %5   → Gümrük: 50 SAR
Excise:            %0   → ÖTV: 0 SAR
KDV Matrahı:       1,050 SAR (CIF + Gümrük)
KDV (%15):         157.50 SAR
───────────────────────────────────────
Toplam İthalat Maliyeti: 1,207.50 SAR
```

---

## 5. SA Ürün Takip Sistemi — İthalat Uyum Kontrolleri

### 5.1 Halal Sertifikası Gerektiren Ürünler

| HS Kodu | Ürün | Zorunlu Belge |
|---|---|---|
| 0201-0210 | Et ve et ürünleri | Halal sertifikası |
| 1601-1602 | İşlenmiş et | Halal sertifikası |
| 2106 | Gıda preparatları | Halal içerik beyanı |

**Bağlantı**: Mevcut `038_halal_compliance_core.sql` ile entegrasyon → `halal_compliance_requirements` tablosuna bağlanacak.

### 5.2 Zorunlu Standart Uyumluluğu (SASO)

Bazı ürünler için SASO (Saudi Standards, Metrology and Quality Organization) sertifikası zorunludur:
- Elektrikli ev aletleri
- Oyuncaklar
- İnşaat malzemeleri

---

## 6. Dart Servis Katmanı

```dart
class GccTariffService {
  /// HS kodu arama (6-8 basamak)
  Future<TariffLookupResult?> lookupTariff({
    required String hsCode,
    required DateTime importDate,
  }) async { ... }

  /// İthalat toplam maliyet hesabı
  Future<ImportCostCalculation> calculateImportCost({
    required String hsCode,
    required double cifValue,
    required DateTime importDate,
    String originCountry = 'UNKNOWN',
    bool hasExemption = false,
  }) async { ... }

  /// HS kodu arama (metin ile)
  Future<List<TariffCode>> searchByDescription(String query) async { ... }
}
```

---

## 7. Test Vakaları

| Test | Girdi | Beklenen Çıktı |
|---|---|---|
| Akıllı telefon (HS 8517.13) | CIF: 1,000 SAR | Gümrük: 50, KDV: 157.50, Toplam: 1,207.50 SAR |
| İlaç (HS 3004) | CIF: 500 SAR | Gümrük: 0, KDV: 75, Toplam: 575 SAR |
| Alkol (HS 2203) | Herhangi | PROHIBITED — işlem engellendi |
| Bilinmeyen HS kodu | '9999.99' | UNKNOWN — tarife bulunamadı |
| Geçmiş tarihli ithalat | 2020-01-01 | O tarihteki etkin tarife oranı |

---

*Resmi Kaynak: GCC Common External Tariff, ZATCA Integrated Customs Tariff*  
*https://zatca.gov.sa/en/RulesRegulations/Pages/rules.aspx*
