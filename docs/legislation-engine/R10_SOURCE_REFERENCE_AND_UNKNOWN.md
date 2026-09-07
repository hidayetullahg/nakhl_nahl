# R10 — KAYNAK REFERANS VE UNKNOWN DURUMU
## Source Transparency & UNKNOWN Status Design

**Rapor No:** R10  
**Versiyon:** 1.0  
**Tarih:** 2026-09-07  
**Durum:** ONAY BEKLİYOR  

---

## 1. Temel Prensip

> **"KANIT YOKSA PASS YOK"** — Bu motor hiçbir zaman tahmin üretmez. Eğer bir kural belirsizse, kaynak yoksa veya durum tartışmalıysa sistem `UNKNOWN` döner ve resmi kaynağa yönlendirir.

---

## 2. Belirsizlik Seviyeleri (Uncertainty Levels)

| Seviye | Kod | Açıklama | Sistem Davranışı |
|---|---|---|---|
| **Kesin** | `CERTAIN` | Resmi kanun/yönetmelikte açıkça belirtilmiş | Hesaplama normal devam eder |
| **Belirsiz** | `UNCERTAIN` | Yorum gerektiren veya tartışmalı kural | Hesaplama yapılır, uyarı gösterilir |
| **Bilinmiyor** | `UNKNOWN` | Kaynak bulunamamış veya çelişkili kaynaklar | Hesaplama yapılmaz, danışman önerilir |
| **Uygulanamaz** | `INAPPLICABLE` | Bu ülkede/durumda uygulanmaz (örn. SA'da alkol ÖTV) | İşlem engellenir, açıklama gösterilir |

---

## 3. `legal_authorities` Tablosu (YENİ)

Her mevzuatın hangi otoriteden geldiğini takip eder.

```sql
CREATE TABLE IF NOT EXISTS legal_authorities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    authority_code VARCHAR(50) NOT NULL UNIQUE,  -- ZATCA, GIB, GAZT, FTA, GCC_CG
    authority_name_en VARCHAR(200) NOT NULL,
    authority_name_ar VARCHAR(200),
    authority_name_tr VARCHAR(200),
    country_code VARCHAR(3) NOT NULL,             -- SA, TR, AE, KW, BH, QA, OM
    jurisdiction_type VARCHAR(50) NOT NULL,       -- TAX, CUSTOMS, ZAKAT, HALAL, STANDARDS
    official_website TEXT NOT NULL,
    regulations_url TEXT,                         -- Mevzuat ana sayfası
    api_endpoint TEXT,                            -- API varsa (ZATCA, GİB)
    contact_email TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Seed data — Temel otoriteler
INSERT INTO legal_authorities (authority_code, authority_name_en, country_code, jurisdiction_type, official_website, regulations_url)
VALUES
  ('ZATCA',   'Zakat, Tax and Customs Authority',       'SAU', 'TAX',     'https://zatca.gov.sa',                              'https://zatca.gov.sa/en/RulesRegulations/Pages/rules.aspx'),
  ('GIB',     'Revenue Administration of Türkiye',      'TUR', 'TAX',     'https://gib.gov.tr',                                'https://www.gib.gov.tr/mevzuat'),
  ('GCC_CG',  'GCC Common Customs Authority',           'SAU', 'CUSTOMS', 'https://gcc-sg.org',                                'https://gcc-sg.org/en/customs'),
  ('SASO',    'Saudi Standards, Metrology and Quality', 'SAU', 'STANDARDS','https://saso.gov.sa',                              'https://saso.gov.sa/en/standards'),
  ('FTA',     'Federal Tax Authority (UAE)',             'ARE', 'TAX',     'https://tax.gov.ae',                                'https://tax.gov.ae/en/legislation'),
  ('SFDA',    'Saudi Food and Drug Authority',          'SAU', 'HALAL',   'https://sfda.gov.sa',                               'https://sfda.gov.sa/en/regulations');
```

---

## 4. `legislation_sources` Tablosu (YENİ)

Her kural için resmi kaynak belgesi kayıtları.

```sql
CREATE TABLE IF NOT EXISTS legislation_sources (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    legislation_id UUID REFERENCES legislations(id) ON DELETE CASCADE,
    authority_id UUID REFERENCES legal_authorities(id),
    
    -- Kaynak bilgileri
    source_type VARCHAR(50) NOT NULL
        CHECK (source_type IN ('ROYAL_DECREE','MINISTERIAL_RESOLUTION','CIRCULAR','GUIDELINE','FAQ','COURT_RULING','TREATY')),
    source_code VARCHAR(200),      -- 'Royal Decree M/113', 'Ministerial Resolution 1146'
    source_date DATE,
    title_en TEXT NOT NULL,
    title_ar TEXT,
    title_tr TEXT,
    
    -- Erişim
    url TEXT NOT NULL,             -- Direkt link
    url_verified_at DATE,          -- URL'nin son kontrol tarihi
    url_is_active BOOLEAN DEFAULT TRUE,
    page_number VARCHAR(50),       -- Sayfa/madde referansı
    article_reference VARCHAR(100),-- 'Article 7', 'Section 3.2'
    
    -- Güvenilirlik
    reliability_tier INT NOT NULL DEFAULT 1
        CHECK (reliability_tier BETWEEN 1 AND 5),
        -- 1 = Resmi kanun (en güvenilir)
        -- 2 = Yönetmelik
        -- 3 = Resmi kılavuz
        -- 4 = SSS/Duyuru
        -- 5 = Üçüncü taraf yorum (en az güvenilir)
    is_primary_source BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 5. UNKNOWN Durum İşlem Akışı

### 5.1 Tetikleyici Koşullar

`UNKNOWN` statüsü şu durumlarda tetiklenir:

1. Kural kodu `UNKNOWN` uncertainty_level ile kayıtlı
2. HS kodu `gcc_tariff_codes` tablosunda bulunamıyor
3. DTAA anlaşması var ama treaty_rate `NULL` (henüz sisteme girilmemiş)
4. İşlem tipi mevcut kural kategorileriyle eşleşmiyor
5. `calculate_transaction_tax_v2` hiçbir kural bulamıyor

### 5.2 UNKNOWN Yanıt Yapısı

```dart
class TaxCalculationResult {
  final String? ruleCode;
  final double? rate;
  final double? taxAmount;
  final double? totalAmount;
  final UncertaintyLevel uncertaintyLevel;
  final String? sourceUrl;
  final String? sourceReference;
  final String disclaimer;
  final List<String> actionItems;    // Kullanıcının yapması gerekenler
  final List<RelatedRule>? alternatives; // Benzer kurallar (öneri)
  
  bool get isCalculated => uncertaintyLevel != UncertaintyLevel.unknown 
                        && uncertaintyLevel != UncertaintyLevel.inapplicable;
}
```

### 5.3 UI'da UNKNOWN Gösterimi

```dart
Widget buildTaxResultCard(TaxCalculationResult result) {
  if (!result.isCalculated) {
    return UnknownRuleCard(
      icon: Icons.help_outline,
      color: Colors.orange,
      title: 'Vergi Kuralı Belirlenemedi',
      message: 'Bu işlem için uygulanabilir bir vergi kuralı bulunamadı.',
      actionItems: result.actionItems,
      officialSourceUrl: result.sourceUrl,
      disclaimer: result.disclaimer,
    );
  }
  // ... normal hesaplama gösterimi
}
```

---

## 6. Zorunlu Disclaimer Metinleri

Her API yanıtında `disclaimer` alanı bulunur:

```dart
class LegislationDisclaimer {
  static const String standard = '''
Bu hesaplama bilgi amaçlıdır ve hukuki danışmanlık teşkil etmez. 
Vergi yükümlülükleriniz için ZATCA onaylı bir vergi danışmanına başvurmanız tavsiye edilir.
Resmi bilgi için: https://zatca.gov.sa
''';

  static const String uncertain = '''
Bu kural yoruma açık olup uygulanması tartışmalı olabilir.
ZATCA veya yetkili bir danışmanla teyit etmenizi şiddetle tavsiye ederiz.
''';

  static const String unknown = '''
Bu işlem için geçerli bir vergi kuralı sisteme tanımlanmamıştır.
Lütfen bir ZATCA onaylı vergi danışmanına başvurunuz.
Resmi başvuru: https://zatca.gov.sa
''';

  static const String inapplicable = '''
Bu işlem kategorisi Suudi Arabistan mevzuatı kapsamında uygulanamaz.
İslam hukuku veya ulusal yasal kısıtlamalar nedeniyle bu işlem yapılamaz.
''';
}
```

---

## 7. URL Doğrulama Mekanizması

Kaynak URL'lerin aktif kalmasını sağlamak için:

```sql
CREATE TABLE IF NOT EXISTS source_url_health_checks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    legislation_source_id UUID REFERENCES legislation_sources(id),
    check_date DATE NOT NULL DEFAULT CURRENT_DATE,
    http_status_code INT,
    is_accessible BOOLEAN,
    redirect_url TEXT,
    check_method VARCHAR(20) DEFAULT 'MANUAL',  -- MANUAL veya AUTO (edge function)
    notes TEXT
);
```

**Politika**: URL'ler 90 günden uzun süredir kontrol edilmemişse sistem `⚠️ Kaynak URL güncelleme gerekebilir` uyarısı gösterir.

---

## 8. `ALTER TABLE legislations` Genişletme

```sql
ALTER TABLE legislations ADD COLUMN IF NOT EXISTS
    authority_id UUID REFERENCES legal_authorities(id),
    source_url TEXT,
    applicability_scope VARCHAR(100),   -- B2B, B2C, BOTH, RESIDENT_ONLY, NON_RESIDENT
    uncertainty_level VARCHAR(20) DEFAULT 'CERTAIN'
        CHECK (uncertainty_level IN ('CERTAIN','UNCERTAIN','UNKNOWN','INAPPLICABLE')),
    disclaimer TEXT,
    requires_professional_advice BOOLEAN DEFAULT FALSE,
    last_reviewed_at DATE;
```

---

*Bu rapor "KANIT YOKSA PASS YOK" ilkesinin teknik implementasyonunu tasarlamaktadır.*
