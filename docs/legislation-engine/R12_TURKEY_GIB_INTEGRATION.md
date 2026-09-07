# R12 — TÜRKİYE GİB ENTEGRASYONU GENİŞLETME
## Turkey GIB Integration — Existing System Enhancement

**Rapor No:** R12  
**Versiyon:** 1.0  
**Tarih:** 2026-09-07  
**Durum:** ONAY BEKLİYOR  
**Resmi Kaynak:** https://www.gib.gov.tr/mevzuat

---

## 1. Mevcut Durum

`lib/services/einvoice_adapter.dart` (11,890 bayt) halihazırda şunları sağlıyor:
- GİB e-Fatura entegrasyonu (UBL-TR 1.2)
- e-Arşiv Fatura
- Fatura imzalama (mali mühür)
- Test/Üretim ortamı yönetimi

`042_legislation_tax_engine.sql`:
- `tax_type` enum: `'VAT'` (TR KDV için de geçerli)
- `country_code: 'TR'`, `jurisdiction: 'TR-GIB'` destekli

**Kural**: Mevcut altyapı korunur. Bu rapor sadece eksik alanları tanımlar ve Mevzuat Motoru kapsamında nasıl entegre edileceğini tasarlar.

---

## 2. TR Vergi Mevzuatı — Mevcut Eksikler

### 2.1 TR KDV Kural Seti

| Kural | Kod | Oran | Durum |
|---|---|---|---|
| Genel KDV | TR_VAT_STANDARD | %20 (2023'ten itibaren) | ❌ Seed data yok |
| İndirimli KDV (Gıda, ilaç) | TR_VAT_REDUCED_10 | %10 | ❌ Seed data yok |
| Düşük KDV (Temel gıda) | TR_VAT_SUPER_REDUCED | %1 | ❌ Seed data yok |
| KDV İstisnası (İhracat) | TR_VAT_EXPORT_EXEMPT | %0 | ❌ Seed data yok |
| Tevkifat (stopaj KDV) | TR_VAT_TEVKIFAT | %50-%100 | ❌ Yok |

> **Kritik Not**: Türkiye KDV oranları 2023'te değişti (Genel: %18 → %20, İndirimli: %8 → %10). Versiyonlama (R09) bu senaryoyu doğru ele almalı.

### 2.2 TR e-Fatura Mevzuat Gereksinimleri

| Gereksinim | Mevcut | Eksik |
|---|---|---|
| GİB UBL-TR 1.2 şema uyumu | ✅ | |
| Mali Mühür (UATP) entegrasyonu | ✅ | |
| e-İrsaliye (Dispatch Note) | ❌ | Yeni modül |
| e-Müstahsil (Agricultural) | ❌ | Yeni modül |
| e-Serbest Meslek Makbuzu | ❌ | Yeni modül |
| e-Bilet (e-Ticket) | ❌ | Scope dışı |
| KDV iade talep formu bağlantısı | ❌ | Yeni |

---

## 3. TR KDV Geçmişi — Versiyonlama Gereksinimleri

```sql
-- TR KDV tarihsel kayıtlar (seed data olarak 054 migrasyonuna eklenecek)

-- Genel KDV oranları
-- 2005-2023: %18
-- 2023-07-10 sonrası: %20

-- İndirimli KDV
-- 2005-2023: %8  
-- 2023-07-10 sonrası: %10

-- Örnek kural kaydı
INSERT INTO tax_rules (rule_code, rate, effective_from, effective_to, country_code, jurisdiction)
VALUES
  ('TR_VAT_STANDARD_18', 18.0000, '2005-01-01', '2023-07-09', 'TR', 'TR-GIB'),
  ('TR_VAT_STANDARD_20', 20.0000, '2023-07-10', NULL,         'TR', 'TR-GIB'),
  ('TR_VAT_REDUCED_8',   8.0000,  '2005-01-01', '2023-07-09', 'TR', 'TR-GIB'),
  ('TR_VAT_REDUCED_10',  10.0000, '2023-07-10', NULL,         'TR', 'TR-GIB');
```

---

## 4. TR Mevzuat Otorite Kaydı

```sql
-- R10'daki legal_authorities tablosuna eklenecek kayıt
INSERT INTO legal_authorities (authority_code, authority_name_en, authority_name_tr, country_code, jurisdiction_type, official_website, regulations_url)
VALUES
  ('GIB',   'Revenue Administration of Turkey', 'Gelir İdaresi Başkanlığı',
   'TUR', 'TAX', 'https://gib.gov.tr', 'https://www.gib.gov.tr/mevzuat'),
  
  ('HAZINE', 'Ministry of Treasury and Finance', 'Hazine ve Maliye Bakanlığı',
   'TUR', 'TAX', 'https://hmb.gov.tr', 'https://www.hmb.gov.tr/mevzuat'),
  
  ('TUIK',  'Turkish Statistical Institute', 'Türkiye İstatistik Kurumu',
   'TUR', 'STANDARDS', 'https://tuik.gov.tr', NULL);
```

---

## 5. TR e-İrsaliye Tasarımı (Kapsam Dahili)

e-İrsaliye, mal sevkiyatı için GİB zorunluluğu olan bir belgedir.

### 5.1 Yeni Tablo

```sql
ALTER TABLE logistics_orders ADD COLUMN IF NOT EXISTS
    eirsaliye_uuid UUID,
    eirsaliye_number VARCHAR(50),
    eirsaliye_status VARCHAR(30) DEFAULT 'DRAFT'
        CHECK (eirsaliye_status IN ('DRAFT','SUBMITTED','ACCEPTED','REJECTED','CANCELLED')),
    eirsaliye_xml TEXT,
    eirsaliye_submitted_at TIMESTAMPTZ,
    eirsaliye_gib_response JSONB;
```

### 5.2 Dart Servisi

```dart
class EIrsaliyeService {
  /// GİB UBL-TR 1.2 e-İrsaliye XML üretimi
  String generateEIrsaliyeXml(LogisticsOrder order) { ... }
  
  /// GİB'e gönderim
  Future<EIrsaliyeResult> submit(String orderId) async { ... }
  
  /// Durum sorgulama
  Future<EIrsaliyeStatus> queryStatus(String uuid) async { ... }
}
```

---

## 6. TR Muhasebe Hesap Planı Uyumluluk Kontrolü

`compliance_check_rules` tablosuna TR kontrolleri:

```sql
INSERT INTO compliance_check_rules (check_code, check_category, country_code, title_tr, severity, source_url)
VALUES
  ('TR_VAT_MUKELLEF',     'VAT',      'TUR', 'KDV Mükellefiyeti Kaydı',         'CRITICAL', 'https://gib.gov.tr'),
  ('TR_EINVOICE_MUKELLEF', 'EINVOICE', 'TUR', 'e-Fatura Mükellef Kaydı (GİB)',   'CRITICAL', 'https://ebelge.gib.gov.tr'),
  ('TR_EIRSALIYE_MUKELLEF','EINVOICE', 'TUR', 'e-İrsaliye Mükellef Kaydı (GİB)', 'WARNING',  'https://ebelge.gib.gov.tr'),
  ('TR_STOPAJ_MUHTASAR',  'WITHHOLDING','TUR','Aylık Muhtasar ve Prim Beyannamesi','CRITICAL','https://gib.gov.tr'),
  ('TR_KDV_BEYANNAME',    'VAT',      'TUR', 'Aylık KDV Beyannamesi',            'CRITICAL', 'https://gib.gov.tr'),
  ('TR_TEVKIFAT',         'VAT',      'TUR', 'KDV Tevkifatı (Varsa)',            'WARNING',  'https://gib.gov.tr');
```

---

## 7. Test Vakaları

| Test | Tarih | Beklenen KDV Oranı |
|---|---|---|
| TR'de genel satış, 2022 | 2022-03-01 | %18 |
| TR'de genel satış, 2024 | 2024-06-15 | %20 |
| TR'den ihracat | Herhangi | %0 (İhracat İstisnası) |
| Gıda ürünü satışı, 2022 | 2022-08-01 | %8 |
| Gıda ürünü satışı, 2024 | 2024-02-01 | %10 |
| Temel gıda (pirinç, ekmek) | Herhangi | %1 |

---

*Resmi Kaynak: GİB Mevzuat — https://www.gib.gov.tr/mevzuat*  
*Bu rapor mevcut `einvoice_adapter.dart` ve `042_legislation_tax_engine.sql` ile tutarlıdır.*
