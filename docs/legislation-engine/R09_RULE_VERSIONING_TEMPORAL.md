# R09 — KURAL VERSİYONLAMA VE TARİHE GÖRE ÇÖZÜMLEME
## Rule Versioning & Temporal Resolution Engine

**Rapor No:** R09  
**Versiyon:** 1.0  
**Tarih:** 2026-09-07  
**Durum:** ONAY BEKLİYOR  

---

## 1. Problem: Neden Versiyonlama Kritik?

Vergi mevzuatı değişir. NAKHL & NAHL'da şu senaryolar gerçek dünyada oluşabilir:

| Senaryo | Hatalı Yaklaşım | Doğru Yaklaşım |
|---|---|---|
| SA KDV 2018'de %5, 2020'de %15 oldu | Tüm eski faturalara %15 uygulandı | Her fatura kendi tarihindeki kuralla hesaplanır |
| Excise ürün eklendi 2022'de | Geçmişe dönük uygulama | Sadece 2022 sonrası |
| GCC Tarife oranı düştü | Yanlış gümrük hesabı | Her ithalat kendi tarihindeki tarife |
| Türkiye KDV indirim/değişiklik | Muhasebe karmaşası | Otomatik tarihsel çözümleme |

**Temel Prensip**: "Her vergi hesaplaması, işlem tarihindeki geçerli kuralla yapılır. Geçmiş işlemler asla yeniden hesaplanmaz."

---

## 2. Mevcut Mekanizma (042 Migrasyonu)

```sql
-- Mevcut: effective_from <= p_transaction_date AND (effective_to IS NULL OR effective_to >= p_transaction_date)
SELECT ...
FROM tax_rules tr
WHERE tr.effective_from <= p_transaction_date
  AND (tr.effective_to IS NULL OR tr.effective_to >= p_transaction_date)
ORDER BY tr.effective_from DESC
LIMIT 1;
```

Bu mekanizma **doğru** çalışıyor. Genişletme gereken noktalar:

1. **Versiyon çakışması** — Aynı kural kodu için iki aktif versiyon varsa (hata durumu) nasıl davranılacak?
2. **Supersession zinciri** — Eski kural `SUPERSEDED` işaretlendiğinde yeni kurala otomatik geçiş
3. **Geçiş dönemi kuralları** — Bazı ülkeler geçiş dönemi için özel oranlar uygular
4. **Gelecek kurallar** — Henüz yürürlüğe girmemiş (`DRAFT`) kuralları göster ama uygulatma

---

## 3. Kural Yaşam Döngüsü

```
DRAFT ──► ACTIVE ──► SUPERSEDED ──► ARCHIVED
           │
           └──► REPEALED (İptal)
```

| Durum | Açıklama | Hesaplamada Kullanılır mı? |
|---|---|---|
| `DRAFT` | Taslak, onay bekliyor | ❌ Hayır |
| `ACTIVE` | Geçerli kural | ✅ Evet (tarih aralığında) |
| `SUPERSEDED` | Yenisiyle değiştirildi | ✅ Evet (kendi tarihi için) |
| `REPEALED` | Tamamen iptal | ✅ Evet (kendi tarihi için) |
| `ARCHIVED` | Sistem dışı | ❌ Hayır |

---

## 4. Supersession Zinciri

Yeni sütunlar `legislations` tablosuna eklenecek:

```sql
ALTER TABLE legislations ADD COLUMN IF NOT EXISTS
    supersedes_id UUID REFERENCES legislations(id),   -- Hangi kuralın yerine geçti
    superseded_by_id UUID REFERENCES legislations(id); -- Hangi kural tarafından değiştirildi
```

Yeni sütunlar `tax_rules` tablosuna:

```sql
ALTER TABLE tax_rules ADD COLUMN IF NOT EXISTS
    supersedes_rule_id UUID REFERENCES tax_rules(id),
    superseded_by_rule_id UUID REFERENCES tax_rules(id),
    transition_period_days INT DEFAULT 0,    -- Geçiş süresi (gün)
    transition_rate NUMERIC(7,4),            -- Geçiş dönemi özel oranı (varsa)
    announcement_date DATE,                  -- Duyuru tarihi (effective_from öncesi)
    source_url TEXT,
    change_summary TEXT;                     -- Bu versiyonun özet değişiklikleri
```

---

## 5. Temporal Resolution Algorithm

### 5.1 Algoritma (Öncelik Sırası)

```
1. Geçerli ülke + yetki alanı filtrelemesi
2. İşlem tarihine göre: effective_from <= tarih AND (effective_to IS NULL OR effective_to >= tarih)
3. Durum filtresi: status IN ('ACTIVE', 'SUPERSEDED', 'REPEALED')  [DRAFT hariç]
4. Ürün/kategori spesifik kural varsa önce al (priority yüksek)
5. İşlem tipi spesifik kural varsa önce al
6. effective_from DESC sırayla en son yürürlüğe giren al
```

### 5.2 Çakışma Tespit Fonksiyonu

```sql
CREATE OR REPLACE FUNCTION detect_rule_conflicts(
    p_company_id UUID,
    p_rule_code VARCHAR,
    p_effective_from DATE,
    p_effective_to DATE DEFAULT NULL
)
RETURNS TABLE (
    conflict_rule_id UUID,
    conflict_rule_code VARCHAR,
    conflict_from DATE,
    conflict_to DATE,
    conflict_type VARCHAR  -- 'OVERLAP', 'DUPLICATE', 'GAP'
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        tr.id,
        tr.rule_code,
        tr.effective_from,
        tr.effective_to,
        CASE
            WHEN tr.effective_from <= COALESCE(p_effective_to, '9999-12-31'::DATE)
             AND COALESCE(tr.effective_to, '9999-12-31'::DATE) >= p_effective_from
            THEN 'OVERLAP'
            ELSE 'GAP'
        END::VARCHAR
    FROM tax_rules tr
    WHERE tr.company_id = p_company_id
      AND tr.rule_code = p_rule_code
      AND tr.is_active = TRUE;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;
```

---

## 6. Tarihsel Hesaplama Test Senaryoları

### Senaryo 1: SA KDV Oran Değişimi

```
Kural 1: SA_VAT_STANDARD (effective_from: 2018-01-01, effective_to: 2020-06-30, rate: 5.00)
Kural 2: SA_VAT_STANDARD (effective_from: 2020-07-01, effective_to: NULL, rate: 15.00)

Test A: İşlem tarihi 2019-03-15 → %5 KDV uygulanır ✅
Test B: İşlem tarihi 2020-09-01 → %15 KDV uygulanır ✅
Test C: İşlem tarihi 2020-06-30 → %5 KDV uygulanır (son gün önceki kural) ✅
Test D: İşlem tarihi 2020-07-01 → %15 KDV uygulanır (yeni kuralın ilk günü) ✅
```

### Senaryo 2: GCC Tarife Güncelleme

```
Tarife 1: HS 8517.13 (effective_from: 2020-01-01, rate: 5.0)
Tarife 2: HS 8517.13 (effective_from: 2024-01-01, rate: 3.0)

Test: İthalat tarihi 2023-06-01 → %5 gümrük ✅
Test: İthalat tarihi 2024-03-15 → %3 gümrük ✅
```

---

## 7. "Gelecek Kural" Gösterimi

Dashboard'da mevzuat değişikliği uyarısı:

```dart
class LegislationChangeAlert {
  final String ruleCode;
  final DateTime announcementDate;
  final DateTime effectiveDate;
  final double currentRate;
  final double newRate;
  final String sourceUrl;
  
  String get daysUntilChange =>
    effectiveDate.difference(DateTime.now()).inDays.toString();
}
```

UI'da: **"⚠️ SA KDV oranı 45 gün sonra değişecek. [Detaylar]"**

---

## 8. Migrasyon Güvenlik Garantisi

Bu raporda önerilen `ALTER TABLE` komutları:
- Mevcut satırları etkilemez
- Mevcut `UNIQUE` kısıtları bozulmaz  
- Mevcut RLS politikaları çalışmaya devam eder
- `calculate_transaction_tax` (eski RPC) değişmez, `v2` ayrı eklenir

---

*Bu rapor R02 (Altyapı Analizi) ve R03-R07 (Kural Motor raporları) ile tutarlıdır.*
