# R18 — RESMİ KAYNAK REFERANSLAR
## Official Source References — ZATCA, GCC, GİB

**Rapor No:** R18  
**Versiyon:** 1.0  
**Tarih:** 2026-09-07  
**Durum:** ONAY BEKLİYOR  

---

## 1. Suudi Arabistan — ZATCA Kaynakları

### 1.1 Ana Mevzuat Merkezi

| Kaynak | URL | Güvenilirlik |
|---|---|---|
| ZATCA Ana Mevzuat Sayfası | https://zatca.gov.sa/en/RulesRegulations/Pages/rules.aspx | ⭐⭐⭐⭐⭐ |
| ZATCA VAT Mevzuatı | https://zatca.gov.sa/en/RulesRegulations/VAT/Pages/default1.aspx | ⭐⭐⭐⭐⭐ |
| ZATCA Excise Tax | https://zatca.gov.sa/en/RulesRegulations/excise/Pages/default.aspx | ⭐⭐⭐⭐⭐ |
| ZATCA Customs | https://zatca.gov.sa/en/RulesRegulations/Customs/Pages/default.aspx | ⭐⭐⭐⭐⭐ |
| ZATCA Zekât (Zakat) | https://zatca.gov.sa/en/RulesRegulations/Zakat/Pages/default.aspx | ⭐⭐⭐⭐⭐ |

### 1.2 e-Fatura (Fatoora)

| Kaynak | URL | Güvenilirlik |
|---|---|---|
| Fatoora Genel | https://zatca.gov.sa/en/E-Invoicing/Pages/default.aspx | ⭐⭐⭐⭐⭐ |
| Phase 2 Teknik Rehber | https://zatca.gov.sa/en/E-Invoicing/Introduction/Guidelines/Pages/default.aspx | ⭐⭐⭐⭐⭐ |
| UBL 2.1 Şema | https://zatca.gov.sa/en/E-Invoicing/Introduction/Guidelines/Documents/ZATCA_Electronic_Invoice_XML_Implementation_Standard.pdf | ⭐⭐⭐⭐⭐ |
| API Sandbox | https://developer.zatca.gov.sa | ⭐⭐⭐⭐⭐ |

### 1.3 Temel Kanunlar ve Belgeler

| Belge | Kod | Yürürlük |
|---|---|---|
| KDV Kanunu | Royal Decree M/113 | 2018-01-01 |
| KDV Uygulama Yönetmeliği | Cabinet Decision 2882 | 2018-01-01 |
| KDV Oranı Artışı | Cabinet Decision 2048 | 2020-07-01 |
| Özel Tüketim Vergisi Kanunu | Royal Decree M/52 | 2017-06-10 |
| 1445H Zekât Uygulama Yönetmeliği | Ministerial Resolution 1149 | 2024-01-01 |
| Transfer Fiyatlandırması | Ministerial Resolution 1146 | 2019-01-01 |

---

## 2. GCC Kaynakları

### 2.1 GCC Gümrük

| Kaynak | URL | Güvenilirlik |
|---|---|---|
| GCC Ortak Gümrük Kanunu | https://gcc-sg.org/en/customs | ⭐⭐⭐⭐⭐ |
| GCC Ortak Dış Tarife (CET) | https://gcc-sg.org/en/customs/tariff | ⭐⭐⭐⭐⭐ |
| SA Entegre Gümrük Tarifesi | https://zatca.gov.sa/en/RulesRegulations/Customs/ | ⭐⭐⭐⭐⭐ |

### 2.2 GCC Halal

| Kaynak | URL | Güvenilirlik |
|---|---|---|
| GSO Halal Standartları | https://gso.org.sa | ⭐⭐⭐⭐ |
| SFDA Gıda Mevzuatı | https://sfda.gov.sa/en/regulations | ⭐⭐⭐⭐⭐ |

---

## 3. Türkiye — GİB Kaynakları

### 3.1 Ana Mevzuat

| Kaynak | URL | Güvenilirlik |
|---|---|---|
| GİB Mevzuat | https://www.gib.gov.tr/mevzuat | ⭐⭐⭐⭐⭐ |
| KDV Kanunu | https://www.gib.gov.tr/sites/default/files/fileadmin/user_upload/Mevzuat_Erozya/3065_sayili_KDV_Kanunu.pdf | ⭐⭐⭐⭐⭐ |
| e-Fatura Mevzuatı | https://www.gib.gov.tr/e-fatura-uygulamasi | ⭐⭐⭐⭐⭐ |
| e-Belge Portal | https://ebelge.gib.gov.tr | ⭐⭐⭐⭐⭐ |
| KDV Genel Uygulama Tebliği | RG: 26.04.2014/28983 | ⭐⭐⭐⭐⭐ |

### 3.2 KDV Oran Değişikliği Kaynağı

| Belge | Tarih | URL |
|---|---|---|
| KDV Artışı (%18→%20, %8→%10) | Temmuz 2023 | https://www.resmigazete.gov.tr |
| Cumhurbaşkanlığı Kararnamesi 7346 | 2023-07-07 | https://www.resmigazete.gov.tr |

---

## 4. Kaynak Değerlendirme Sistemi

### 4.1 Güvenilirlik Sıralaması

| Tier | Tür | Sistem Puanı | Örnek |
|---|---|---|---|
| 1 | Resmi kanun / Royal Decree | ⭐⭐⭐⭐⭐ | Royal Decree M/113 |
| 2 | Yönetmelik / Regulation | ⭐⭐⭐⭐ | KDV Uygulama Yönetmeliği |
| 3 | Resmi Kılavuz / Guideline | ⭐⭐⭐ | ZATCA VAT Guide |
| 4 | SSS / FAQ | ⭐⭐ | ZATCA FAQ Sayfası |
| 5 | Üçüncü Taraf Yorum | ⭐ | Big4 Vergi Bülteni |

**Kural**: Tier 5 kaynaklar `uncertainty_level: UNCERTAIN` ile işaretlenir. Sistem hiçbir zaman sadece üçüncü taraf yoruma dayanarak `CERTAIN` vermez.

---

## 5. Kaynak Güncelleme Protokolü

ZATCA mevzuatı sık güncellenir. Sistem şu protokolü izler:

1. **90 günlük kontrol**: Her URL 90 günde bir manuel veya otomatik doğrulanır
2. **Değişiklik bildirimi**: Güncelleme tespit edildiğinde platform admin uyarılır
3. **Kural otomatik DRAFT'a çekilmez**: Güncellenmiş kaynak sistemde yeni versiyon olarak eklenir
4. **Eski versiyon `SUPERSEDED` olur**: Tarih bazlı çözümleme kesintisiz devam eder

---

## 6. Sisteme Eklenecek Seed Kaynakları

`055_sa_legislation_rules.sql` içinde şu kayıtlar oluşturulacak:

```sql
-- ZATCA VAT Legislation Source
INSERT INTO legislation_sources (legislation_id, authority_id, source_type, source_code, title_en, url, reliability_tier, is_primary_source)
SELECT 
  l.id,
  a.id,
  'ROYAL_DECREE',
  'Royal Decree M/113',
  'Value Added Tax Law — Saudi Arabia',
  'https://zatca.gov.sa/en/RulesRegulations/VAT/Pages/default1.aspx',
  1,
  TRUE
FROM legislations l, legal_authorities a
WHERE l.legislation_code = 'ZATCA_VAT_2020'
  AND a.authority_code = 'ZATCA';

-- GCC CET Source
INSERT INTO legislation_sources (...)
VALUES (
  ...,
  'LAW', 'GCC Common Customs Law 2003',
  'GCC Common External Tariff',
  'https://gcc-sg.org/en/customs/tariff',
  1, TRUE
);

-- TR KDV Artışı (2023)
INSERT INTO legislation_sources (...)
VALUES (
  ...,
  'MINISTERIAL_RESOLUTION',
  'Cumhurbaşkanlığı Kararnamesi 7346',
  'KDV Oranı Değişikliği 2023',
  'https://www.resmigazete.gov.tr',
  1, TRUE
);
```

---

## 7. URL Doğrulama Takvimi

| Kaynak | Son Kontrol | Sıradaki Kontrol | Sorumlu |
|---|---|---|---|
| ZATCA VAT | 2026-09-07 | 2026-12-07 | Platform Admin |
| GCC CET | 2026-09-07 | 2026-12-07 | Platform Admin |
| GİB Mevzuat | 2026-09-07 | 2026-12-07 | Platform Admin |
| ZATCA Fatoora API | 2026-09-07 | 2026-10-07 | Otomatik ping |

---

*Bu rapor tüm raporlarda (R03-R12) referans verilen kaynak listesini konsolide eder. "KANIT YOKSA PASS YOK" ilkesinin kaynak katmanıdır.*
