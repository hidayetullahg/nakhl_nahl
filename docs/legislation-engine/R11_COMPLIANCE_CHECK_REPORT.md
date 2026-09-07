# R11 — UYUM KONTROL RAPORU RPC TASARIMI
## Compliance Check Report Engine

**Rapor No:** R11  
**Versiyon:** 1.0  
**Tarih:** 2026-09-07  
**Durum:** ONAY BEKLİYOR  

---

## 1. Uyum Kontrol Motoru Nedir?

Mevzuat motorunun en kritik çıktısı tek bir API çağrısıyla şirkete özel uyum durumu raporudur.

Kullanıcı "Şirketimizin uyum durumu nedir?" diye sorduğunda sistem:
1. Hangi ülkelerde faaliyet gösterdiğini saptar
2. Her faaliyet için geçerli mevzuatları bulur  
3. Her mevzuat için zorunlu gereksinimleri kontrol eder
4. Eksik veya riskli durumları kırmızı/sarı/yeşil ile işaretler
5. Aksiyon maddelerini öncelik sırasıyla listeler

---

## 2. Uyum Kontrol Alanları

### 2.1 SA Operasyonları İçin Kontrol Listesi

| Kategori | Kontrol | Kaynak |
|---|---|---|
| **KDV** | KDV kayıt numarası var mı? | ZATCA |
| **KDV** | Aylık/çeyreklik KDV beyanı yapıldı mı? | ZATCA |
| **e-Fatura** | ZATCA Phase 2 CSID mevcut mu? | ZATCA Fatoora |
| **e-Fatura** | Son 30 günde reddedilen fatura var mı? | ZATCA API |
| **Zekât** | Zekât beyanı yapıldı mı? (SA sahipli şirketler) | ZATCA |
| **ÖTV** | ÖTV'ye tabi ürün var, kayıt mevcut mu? | ZATCA |
| **Gümrük** | HS kodu tanımlı ürün var mı? | ZATCA |
| **Transfer Fiyatlandırması** | İlişkili taraf eşiği aşıldı mı? | ZATCA |
| **Stopaj** | Yabancı ödemeler stopaj hesabı yapıldı mı? | ZATCA |

### 2.2 TR Operasyonları İçin Kontrol Listesi

| Kategori | Kontrol | Kaynak |
|---|---|---|
| **KDV** | KDV mükellefiyet kaydı | GİB |
| **e-Fatura** | GİB e-Fatura/e-Arşiv Fatura mükellef kaydı | GİB |
| **e-Fatura** | Son 30 günde XSLT uyum hatası var mı? | GİB |
| **Muhasebe** | Hesap planı TEKDÜZEN uyumlu mu? | GİB |
| **Stopaj** | Personel stopaj beyanı güncel mi? | GİB |

---

## 3. `compliance_check_rules` Tablosu (YENİ)

```sql
CREATE TABLE IF NOT EXISTS compliance_check_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Kural tanımı
    check_code VARCHAR(100) NOT NULL UNIQUE,   -- 'SA_VAT_REGISTRATION', 'SA_ZATCA_CSID'
    check_category VARCHAR(50) NOT NULL,       -- VAT, EINVOICE, ZAKAT, CUSTOMS, EXCISE, WITHHOLDING, TRANSFER_PRICING
    country_code VARCHAR(3) NOT NULL,
    jurisdiction VARCHAR(100) NOT NULL DEFAULT 'NATIONAL',
    
    -- Açıklamalar
    title_en TEXT NOT NULL,
    title_ar TEXT,
    title_tr TEXT,
    description_en TEXT,
    
    -- Bağlantılar
    legislation_id UUID REFERENCES legislations(id),
    authority_id UUID REFERENCES legal_authorities(id),
    source_url TEXT,
    
    -- Önem
    severity VARCHAR(20) NOT NULL DEFAULT 'WARNING'
        CHECK (severity IN ('CRITICAL','WARNING','INFO')),
    is_mandatory BOOLEAN DEFAULT TRUE,
    
    -- Geçerlilik
    effective_from DATE NOT NULL,
    effective_to DATE,
    
    -- Koşul (Hangi durumlarda uygulanır)
    applies_to_resident BOOLEAN DEFAULT TRUE,
    applies_to_non_resident BOOLEAN DEFAULT FALSE,
    applies_to_individual BOOLEAN DEFAULT FALSE,
    applies_to_company BOOLEAN DEFAULT TRUE,
    min_annual_revenue NUMERIC(15,2),           -- Eşik değeri (varsa)
    
    -- Aksiyon
    remediation_steps JSONB,                   -- Düzeltme adımları
    estimated_penalty TEXT,                    -- Uyumsuzluk cezası tahmini
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Örnek kayıtlar
INSERT INTO compliance_check_rules (check_code, check_category, country_code, title_en, severity, source_url) VALUES
  ('SA_VAT_REGISTRATION',    'VAT',       'SAU', 'VAT Registration with ZATCA',              'CRITICAL', 'https://zatca.gov.sa'),
  ('SA_ZATCA_PHASE2_CSID',   'EINVOICE',  'SAU', 'ZATCA Phase 2 CSID Provisioning',          'CRITICAL', 'https://zatca.gov.sa/en/E-Invoicing/'),
  ('SA_VAT_RETURN_FILING',   'VAT',       'SAU', 'Monthly/Quarterly VAT Return Filing',      'CRITICAL', 'https://zatca.gov.sa'),
  ('SA_ZAKAT_ANNUAL',        'ZAKAT',     'SAU', 'Annual Zakat Assessment and Payment',      'CRITICAL', 'https://zatca.gov.sa'),
  ('SA_EXCISE_REGISTRATION', 'EXCISE',    'SAU', 'Excise Tax Registration (if applicable)',  'WARNING',  'https://zatca.gov.sa'),
  ('SA_TP_CBCR',             'TRANSFER_PRICING', 'SAU', 'Country-by-Country Report (≥100M SAR)', 'CRITICAL', 'https://zatca.gov.sa'),
  ('TR_EINVOICE_MUKELLEF',   'EINVOICE',  'TUR', 'GIB e-Fatura Mükellef Kaydı',             'CRITICAL', 'https://ebelge.gib.gov.tr');
```

---

## 4. Uyum Durumu Değerlendirme RPC

```sql
CREATE OR REPLACE FUNCTION assess_company_compliance(
    p_tenant_id UUID,
    p_company_id UUID,
    p_assessment_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
    check_code VARCHAR,
    check_category VARCHAR,
    country_code VARCHAR,
    title TEXT,
    severity VARCHAR,
    status VARCHAR,           -- COMPLIANT / NON_COMPLIANT / UNKNOWN / PENDING
    status_detail TEXT,
    source_url TEXT,
    remediation_steps JSONB,
    estimated_penalty TEXT,
    disclaimer TEXT
) AS $$
DECLARE
    v_company RECORD;
    v_country VARCHAR(3);
BEGIN
    -- Şirket bilgilerini al
    SELECT c.country_code, c.vat_number, c.zatca_csid
    INTO v_company
    FROM companies c
    WHERE c.id = p_company_id AND c.tenant_id = p_tenant_id;
    
    v_country := COALESCE(v_company.country_code, 'SAU');
    
    -- Ülkeye özel kontrolleri yap
    RETURN QUERY
    SELECT 
        ccr.check_code,
        ccr.check_category,
        ccr.country_code,
        ccr.title_en::TEXT,
        ccr.severity,
        CASE
            WHEN ccr.check_code = 'SA_VAT_REGISTRATION' AND v_company.vat_number IS NOT NULL THEN 'COMPLIANT'
            WHEN ccr.check_code = 'SA_ZATCA_PHASE2_CSID' AND v_company.zatca_csid IS NOT NULL THEN 'COMPLIANT'
            WHEN ccr.check_code = 'SA_ZATCA_PHASE2_CSID' AND v_company.zatca_csid IS NULL THEN 'NON_COMPLIANT'
            ELSE 'UNKNOWN'
        END::VARCHAR,
        CASE
            WHEN ccr.check_code = 'SA_VAT_REGISTRATION' AND v_company.vat_number IS NULL 
                THEN 'VAT registration number not found in system'
            WHEN ccr.check_code = 'SA_ZATCA_PHASE2_CSID' AND v_company.zatca_csid IS NULL 
                THEN 'ZATCA Phase 2 CSID not provisioned — e-invoicing not allowed'
            ELSE 'Status requires manual verification'
        END::TEXT,
        ccr.source_url,
        ccr.remediation_steps,
        ccr.estimated_penalty,
        'Bu rapor bilgi amaçlıdır ve hukuki danışmanlık teşkil etmez.'::TEXT
    FROM compliance_check_rules ccr
    WHERE ccr.country_code = v_country
      AND ccr.effective_from <= p_assessment_date
      AND (ccr.effective_to IS NULL OR ccr.effective_to >= p_assessment_date)
    ORDER BY 
        CASE ccr.severity WHEN 'CRITICAL' THEN 1 WHEN 'WARNING' THEN 2 ELSE 3 END,
        ccr.check_category;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;
```

---

## 5. Dart Servis Katmanı

```dart
class ComplianceCheckService {
  
  Future<ComplianceReport> assessCompliance({
    required String companyId,
    DateTime? assessmentDate,
  }) async {
    final results = await _supabase.rpc(
      'assess_company_compliance',
      params: {
        'p_tenant_id': _tenantId,
        'p_company_id': companyId,
        'p_assessment_date': (assessmentDate ?? DateTime.now()).toIso8601String().substring(0, 10),
      }
    );
    
    return ComplianceReport.fromJson(results);
  }
}

class ComplianceReport {
  final List<ComplianceCheckResult> checks;
  final int criticalCount;
  final int warningCount;
  final int compliantCount;
  final String overallStatus;  // GREEN / YELLOW / RED
  
  String get overallStatus {
    if (criticalCount > 0) return 'RED';
    if (warningCount > 0) return 'YELLOW';
    return 'GREEN';
  }
}
```

---

## 6. UI — Uyum Durumu Dashboard Widget

```
┌─────────────────────────────────────────┐
│  🔴 Uyum Durumu: KRİTİK                 │
│                                         │
│  ✅ VAT Kaydı                TAMAM      │
│  🔴 ZATCA Phase 2 CSID       EKSİK      │
│  ⚠️  Zekât Beyanı           KONTROL ET  │
│  ✅ Stopaj Vergisi           TAMAM      │
│  ❓ Transfer Fiyatlandırması BILINMIYOR  │
│                                         │
│  [Detaylı Rapor]  [Danışman Bul]        │
└─────────────────────────────────────────┘
```

---

## 7. Test Vakaları

| Test | Şirket Durumu | Beklenen Çıktı |
|---|---|---|
| SA şirketi, VAT var, CSID var | Full setup | GREEN |
| SA şirketi, VAT var, CSID yok | Kısmi setup | RED (CRITICAL: CSID) |
| SA şirketi, hiç setup yok | Boş profil | RED (çoklu CRITICAL) |
| TR şirketi | TR operasyonu | TR kontrolleri çalışır |

---

*Bu rapor R03-R07 kural motorları ve R10 UNKNOWN mekanizması üzerine inşa edilmiştir.*
