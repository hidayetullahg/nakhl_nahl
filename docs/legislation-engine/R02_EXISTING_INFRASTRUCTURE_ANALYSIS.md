# R02 — MEVCUT ALTYAPI ANALİZİ
## Bozmama Garantisi ve Entegrasyon Haritası

**Rapor No:** R02  
**Versiyon:** 1.0  
**Tarih:** 2026-09-07  
**Durum:** ONAY BEKLİYOR  

---

## 1. Mevcut Durum — Tablo Envanteri

### 1.1 `legislations` Tablosu (042_legislation_tax_engine.sql)

```sql
CREATE TABLE IF NOT EXISTS legislations (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    country_code VARCHAR(10) NOT NULL,    -- TR, SA, AE
    jurisdiction VARCHAR(100) NOT NULL,  -- NATIONAL, SA-ZATCA, TR-GIB
    legislation_code VARCHAR(100) NOT NULL,
    title VARCHAR(255) NOT NULL,
    effective_from DATE NOT NULL,
    effective_to DATE,                   -- NULL = halen yürürlükte
    version VARCHAR(20) NOT NULL,
    source_reference TEXT,               -- Resmi Gazete no.
    status VARCHAR(50) CHECK (status IN ('DRAFT','ACTIVE','SUPERSEDED','REPEALED')),
    notes TEXT,
    ...
);
```

**Değerlendirme**: Bu tablo temel yapıyı sağlıyor. Eksikler:
- `source_url` sütunu yok (resmi ZATCA/GİB URL linki)
- `authority_code` yok (ZATCA, GIB, GAZT, FTA)
- `applicability_scope` yok (resident/non-resident, B2B/B2C)
- `disclaimer` yok

**Karar**: `ALTER TABLE legislations ADD COLUMN ...` ile genişletilecek, tablo silinmeyecek.

---

### 1.2 `tax_rules` Tablosu (042_legislation_tax_engine.sql)

```sql
CREATE TABLE IF NOT EXISTS tax_rules (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL,
    company_id UUID NOT NULL,
    legislation_id UUID REFERENCES legislations(id),
    rule_code VARCHAR(100) NOT NULL,
    tax_type VARCHAR(50) CHECK (tax_type IN ('VAT','GST','WITHHOLDING','EXPORT_ZERO','CUSTOMS','EXCISE')),
    rate NUMERIC(7,4) NOT NULL,
    country_code VARCHAR(10) NOT NULL,
    jurisdiction VARCHAR(100) NOT NULL,
    effective_from DATE NOT NULL,
    effective_to DATE,
    product_category_id UUID,
    item_id UUID,
    transaction_type VARCHAR(50) CHECK (... 'SALES','PURCHASE','EXPORT','IMPORT','ALL'),
    is_reverse_charge BOOLEAN,
    is_recoverable BOOLEAN,
    priority INT,
    is_active BOOLEAN,
    ...
);
```

**Değerlendirme**: Kural yapısı sağlam. Eksikler:
- `hs_code` yok (Gümrük Tarife kodu — HS 6/8 basamak)
- `min_threshold` / `max_threshold` yok (Zekât hesabında nisap eşiği)
- `calculation_basis` yok (ad_valorem / specific / compound)
- `source_url` yok
- `uncertainty_level` yok (CERTAIN / UNCERTAIN / UNKNOWN)
- `requires_professional_advice` yok

**Karar**: `ALTER TABLE tax_rules ADD COLUMN ...` ile genişletilecek.

---

### 1.3 `calculate_transaction_tax` RPC (042_legislation_tax_engine.sql)

Mevcut fonksiyon:
- En yüksek öncelikli kurala göre tek vergi satırı döner
- `SALES`, `PURCHASE`, `EXPORT`, `IMPORT` işlem tiplerini destekler
- Tarihsel hesaplama yapar (`effective_from <= date`)
- Hiç kural bulunamazsa `DEFAULT_ZERO` döner

**Eksikler**:
- `ZAKAT`, `EXCISE`, `CUSTOMS` işlem tipleri eksik
- Çoklu vergi katmanı desteği yok (VAT + Excise aynı anda)
- `source_url` ve `disclaimer` dönmüyor
- HS kodu parametresi yok

**Karar**: `calculate_transaction_tax_v2` olarak yeni versiyon oluşturulacak, mevcut fonksiyon `DEPRECATED` edilecek ama silinmeyecek (geriye uyumluluk).

---

### 1.4 `ZatcaPhase2Adapter` (lib/services/zatca_adapter.dart)

Mevcut durum:
- TLV QR Kod üretimi ✅
- UBL 2.1 XML üretimi ✅
- Sandbox/Simulation/Production ortamları ✅
- B2B Clearance / B2C Reporting ayrımı ✅
- CSID zorunluluğu Production için ✅

**Eksikler**:
- `ZatcaComplianceChecker` sınıfı yok (invoice formatı kontrol)
- Debit/Credit note sequence kontrolü yok
- Hash zinciri doğrulaması yok (PIH — Previous Invoice Hash)
- Zekât/ÖTV fatura notasyonu yok

**Karar**: `ZatcaPhase2Adapter` sınıfı genişletilecek.

---

## 2. Migrasyon Güvenliği

Mevcut 53 migrasyon dosyası. Yeni motoru tasarlarken:

| Kural | Açıklama |
|---|---|
| Mevcut tabloları DROP etme | Hiçbir mevcut tablo kaldırılmaz |
| Mevcut sütunları kaldırma | Hiçbir mevcut sütun silinmez |
| `042_legislation_tax_engine.sql` dokunma | Bu dosya değiştirilmez |
| Yeni migrasyonlar `054+` | 054, 055, 056, 057 olarak eklenir |
| `ALTER TABLE` ile genişletme | Mevcut tablolara sütun eklenir |
| Mevcut RLS bozulmamalı | Her `ALTER TABLE` sonrası RLS politikaları kontrol edilir |

---

## 3. Servis Katmanı Haritası

| Mevcut Servis | İlgililik | Aksiyon |
|---|---|---|
| `zatca_adapter.dart` | ✅ Doğrudan ilgili | Genişletilecek |
| `einvoice_adapter.dart` | ✅ TR GİB e-Fatura | Korunuyor |
| `opening_balance_service.dart` | ⚠️ Zekât açılış bakiyesi | Referans alınacak |
| `raporlama_servisi.dart` | ⚠️ Vergi raporları | Genişletilecek |
| `mobil_entegrasyon_servisi.dart` | ℹ️ Entegrasyon hub | Bağımsız |

---

## 4. Etkilenen Ekranlar

| Ekran | Etki | Aksiyon |
|---|---|---|
| Satış Faturası oluşturma | KDV + ÖTV otomatik hesap | `calculate_transaction_tax_v2` entegre |
| İthalat faturası | GCC Gümrük Tarifesi | Yeni HS kodu seçici widget |
| Yıllık Zekât raporu | Zekât hesaplama motoru | Yeni ekran |
| Mevzuat Yönetimi | Kural listesi, ekleme, versiyon | Yeni ekran |
| Dashboard | Uyum durumu özeti | Yeni widget |

---

## 5. Bağımlılık Haritası

```
legislations (042)
    └── tax_rules (042)
            └── calculate_transaction_tax (042) [DEPRECATED → v2]
                    └── calculate_transaction_tax_v2 (054) [YENİ]

legal_authorities (054) [YENİ]
    └── legislations (042) [ALTER TABLE — yeni sütunlar]
            └── tax_rules (042) [ALTER TABLE — yeni sütunlar]
                    └── compliance_check_rules (055) [YENİ]
                            └── zakat_calculation_engine (056) [YENİ]

gcc_tariff_codes (055) [YENİ]
    └── tax_rules.hs_code bağlantısı
```

---

*Bu rapor mevcut altyapıyı bozmama garantisi üzerine kurulmuştur. KANIT: `042_legislation_tax_engine.sql` satır 12-57 ve `zatca_adapter.dart` satır 54-193 incelenerek hazırlanmıştır.*
