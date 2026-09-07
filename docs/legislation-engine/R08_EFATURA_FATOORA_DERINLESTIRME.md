# R08 — E-FATURA (FATOORA) DERİNLEŞTİRME
## ZATCA Phase 2 E-Invoice Engine — Üretim Hazırlığı

**Rapor No:** R08  
**Versiyon:** 1.0  
**Tarih:** 2026-09-07  
**Durum:** ONAY BEKLİYOR  
**Resmi Kaynak:** https://zatca.gov.sa/en/E-Invoicing/Pages/default.aspx

---

## 1. Mevcut Durum (R02'den)

`lib/services/zatca_adapter.dart` (194 satır) halihazırda şunları sağlıyor:
- ✅ TLV Base64 QR kod üretimi (Tag 1-5)
- ✅ UBL 2.1 XML iskelet üretimi
- ✅ Sandbox/Simulation/Production ortam yönetimi
- ✅ B2B Clearance / B2C Reporting ayrımı
- ✅ CSID zorunluluğu Production modunda

**Eksikler** (Bu raporda tasarlananlar):
- ❌ Hash zinciri doğrulaması (PIH — Previous Invoice Hash)
- ❌ ECDSA imzalama (X.509 sertifika ile)
- ❌ Debit/Credit Note sıra kontrolü
- ❌ Fatura format uyum kontrolü (pre-submission validation)
- ❌ ÖTV satır notasyonu faturada
- ❌ Zekât/GCC Tarife bağlantısı
- ❌ Çoklu e-posta ile fatura gönderimi (PEPPOL/EDI hazırlığı)

---

## 2. ZATCA Phase 2 — Zorunlu Alanlar Kontrol Listesi

### 2.1 Standart Vergi Faturası (B2B) Zorunlu Alanlar

| Alan | UBL Yolu | Örnek | Durum |
|---|---|---|---|
| Fatura UUID | `cbc:UUID` | `550e8400-e29b-41d4-a716-446655440000` | ✅ |
| Fatura Numarası | `cbc:ID` | `INV-SA-2026-00001` | ✅ |
| Önceki Fatura Hash (PIH) | `cac:AdditionalDocumentReference` | SHA256 hash | ❌ Eksik |
| Satıcı Adı | `AccountingSupplierParty` | `NAKHL & NAHL` | ✅ |
| Satıcı VAT No. | `CompanyID` (15 haneli) | `300000000000003` | ✅ |
| Alıcı Adı | `AccountingCustomerParty` | `Gulf Retailer` | ✅ |
| Alıcı VAT No. | B2B'de zorunlu | `311111111111113` | ✅ |
| Fatura Tarihi | `cbc:IssueDate` | `2026-09-07` | ✅ |
| Fatura Saati | `cbc:IssueTime` | `10:30:00` | ✅ |
| Fatura Tipi Kodu | `cbc:InvoiceTypeCode` | `388` (B2B Standard) | ✅ |
| Döviz Kodu | `cbc:DocumentCurrencyCode` | `SAR` | ✅ |
| KDV Toplam | `cac:TaxTotal` | `157.50` | ⚠️ İyileştirme |
| KDV Detay (Satır) | Her satır için `TaxSubtotal` | Muafiyet kodu ile | ❌ Eksik |
| Ödeme Vadesi | `cac:PaymentMeans` | | ❌ Eksik |
| Mal/Hizmet Açıklaması | `cac:InvoiceLine/cbc:Description` | | ⚠️ İyileştirme |
| HS Kodu (Varsa) | `cac:CommodityClassification` | `8517.13` | ❌ Eksik |
| ÖTV Satırı | `cac:TaxCategory` (Excise) | | ❌ Eksik |

### 2.2 Basitleştirilmiş Fatura (B2C) Ek Gereksinim

| Alan | Açıklama |
|---|---|
| QR Kod | Tag 1-5 TLV Base64 ✅ |
| QR Ek Taglar (Phase 2) | Tag 6 (XML Hash), Tag 7 (ECDSA İmza), Tag 8 (Public Key) ❌ |

---

## 3. Previous Invoice Hash (PIH) Zinciri

### 3.1 Kavram

ZATCA Phase 2, ardışık fatura bütünlüğü için kriptografik zincir gerektirir:

```
Fatura N → SHA256(Fatura N XML) = Hash N
Fatura N+1 → PIH = Hash N (önceki fatura hash'i)
```

Eğer zincir kırılırsa ZATCA Clearance reddeder.

### 3.2 Veritabanı Desteği

```sql
ALTER TABLE sales_invoices ADD COLUMN IF NOT EXISTS
    zatca_invoice_hash TEXT,          -- Bu faturanın SHA256 hash'i
    zatca_previous_invoice_hash TEXT, -- Önceki faturanın hash'i (PIH)
    zatca_invoice_counter INT,        -- Monoton artan sayaç
    zatca_clearance_status VARCHAR(30) DEFAULT 'PENDING'
        CHECK (zatca_clearance_status IN ('PENDING','CLEARED','REPORTED','REJECTED','EXEMPT')),
    zatca_clearance_response JSONB,   -- ZATCA API yanıtı
    zatca_submission_at TIMESTAMPTZ;
```

### 3.3 Hash Zinciri Doğrulama Fonksiyonu

```sql
CREATE OR REPLACE FUNCTION get_last_invoice_hash(
    p_company_id UUID,
    p_invoice_type VARCHAR  -- 'STANDARD' or 'SIMPLIFIED'
)
RETURNS TEXT AS $$
    SELECT zatca_invoice_hash
    FROM sales_invoices
    WHERE company_id = p_company_id
      AND invoice_category = p_invoice_type
      AND zatca_clearance_status IN ('CLEARED','REPORTED')
    ORDER BY zatca_invoice_counter DESC
    LIMIT 1;
$$ LANGUAGE sql STABLE SECURITY DEFINER;
```

---

## 4. ECDSA İmzalama Mimarisi

### 4.1 Güvenli Anahtar Yönetimi

Production ortamında özel anahtar (Private Key) **asla** istemci tarafında saklanmaz.

```
[Flutter Web/Mobile]
      ↓ HTTPS
[Supabase Edge Function: /zatca-sign]
      ↓ Secure vault
[X.509 Certificate + Private Key — Supabase Secret]
      ↓
[Signed XML + QR (Tag 6,7,8)]
      ↓
[ZATCA Fatoora API]
```

### 4.2 Supabase Edge Function — `zatca-sign`

```typescript
// supabase/functions/zatca-sign/index.ts
import { createClient } from '@supabase/supabase-js'
import { SignJWT } from 'jose'

Deno.serve(async (req) => {
  const { invoiceXml, invoiceHash, tenantId } = await req.json()
  
  // Sertifika ve anahtarı Supabase Secret'tan al
  const cert = Deno.env.get('ZATCA_CERT_PEM')
  const privateKey = Deno.env.get('ZATCA_PRIVATE_KEY_PEM')
  
  // ECDSA SHA-256 imzala
  const signature = await sign(invoiceXml, privateKey)
  
  // ZATCA API'ye gönder
  const response = await fetch(zatcaEndpoint, {
    method: 'POST',
    headers: { 'Authorization': `Basic ${btoa(`${csid}:${ccsid}`)}` },
    body: JSON.stringify({ invoiceHash, signature, invoice: btoa(invoiceXml) })
  })
  
  return new Response(JSON.stringify(await response.json()))
})
```

---

## 5. Dart Adapter Genişletmesi

```dart
class ZatcaPhase2AdapterV2 extends ZatcaPhase2Adapter {
  
  /// Önceki fatura hash'ini al
  Future<String> getPreviousInvoiceHash(String companyId) async { ... }
  
  /// Fatura ön doğrulama (submission öncesi)
  Future<ZatcaValidationReport> validateInvoice(ZatcaInvoicePayload payload) async { ... }
  
  /// Güvenli imzalama (Edge Function üzerinden)
  Future<ZatcaResult> submitWithSignature({
    required ZatcaInvoicePayload payload,
    required ZatcaInvoiceType invoiceType,
  }) async { ... }
  
  /// QR Tag 6-8 genişletilmiş format
  static String generateExtendedTlvQr({
    required String sellerName,
    required String vatNumber,
    required DateTime timestamp,
    required double invoiceTotal,
    required double vatTotal,
    String? xmlHash,       // Tag 6
    String? ecdsaSignature, // Tag 7
    String? publicKey,     // Tag 8
  }) { ... }
}
```

---

## 6. Test Vakaları

| Test | Beklenen Sonuç |
|---|---|
| İlk fatura (PIH = NULL → ZATCA özel değer) | Clearance OK |
| İkinci fatura (doğru PIH) | Clearance OK |
| İkinci fatura (yanlış PIH) | ZATCA Rejection |
| B2B fatura, alıcı VAT no. eksik | Validation Error |
| B2C fatura, QR Tag 1-5 | Reporting OK |
| ÖTV içeren fatura | Excise satırı dahil, Clearance OK |
| Production'da CSID yokken gönderim | `StateError` fırlatır |

---

*Resmi Kaynak: ZATCA Fatoora e-Invoice System — https://zatca.gov.sa/en/E-Invoicing/Pages/default.aspx*
