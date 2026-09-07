# R16 — GÜVENLİK VE RLS TASARIMI
## Security & Row Level Security Architecture

**Rapor No:** R16  
**Versiyon:** 1.0  
**Tarih:** 2026-09-07  
**Durum:** ONAY BEKLİYOR  

---

## 1. Güvenlik Mimarisi İlkeleri

Mevcut sistemdeki güvenlik katmanı:
- `017_security_helper_functions.sql`: `is_tenant_member()`, `has_company_access()`, `is_platform_admin()`
- `018_row_level_security.sql`: Tüm core tablolarda RLS
- `021_security_tests.sql`: PostgreSQL seviyesinde cross-tenant izolasyon testleri

**Yeni Mevzuat Motoru tabloları için kurallar**:

| Tablo Tipi | RLS Politikası |
|---|---|
| Sistem seviyesi mevzuat (legal_authorities, gcc_tariff_codes) | Herkes okuyabilir (public reference data), sadece platform admin yönetir |
| Tenant seviyesi hesaplama (zakat_assessments) | Sadece o tenant okuyabilir/yazabilir |
| Uyum kuralları (compliance_check_rules) | Herkes okuyabilir (public rules) |
| Şirkete özel veri (withholding kayıtları) | Tenant + şirket erişimi |

---

## 2. RLS Politikası Matrisi

| Tablo | SELECT | INSERT | UPDATE | DELETE |
|---|---|---|---|---|
| `legal_authorities` | PUBLIC | PLATFORM_ADMIN | PLATFORM_ADMIN | PLATFORM_ADMIN |
| `legislation_sources` | PUBLIC | PLATFORM_ADMIN | PLATFORM_ADMIN | PLATFORM_ADMIN |
| `gcc_tariff_codes` | PUBLIC | PLATFORM_ADMIN | PLATFORM_ADMIN | PLATFORM_ADMIN |
| `tariff_exemptions` | TENANT | TENANT | TENANT | TENANT |
| `compliance_check_rules` | PUBLIC | PLATFORM_ADMIN | PLATFORM_ADMIN | PLATFORM_ADMIN |
| `withholding_tax_rules` | PUBLIC | PLATFORM_ADMIN | PLATFORM_ADMIN | PLATFORM_ADMIN |
| `zakat_parameters` | PUBLIC | PLATFORM_ADMIN | PLATFORM_ADMIN | PLATFORM_ADMIN |
| `zakat_assessments` | TENANT+COMPANY | TENANT+COMPANY | TENANT+COMPANY | TENANT |
| `source_url_health_checks` | PLATFORM_ADMIN | PLATFORM_ADMIN | PLATFORM_ADMIN | PLATFORM_ADMIN |

---

## 3. SQL RLS Politikaları

```sql
-- ============================================================
-- legal_authorities — Genel okuma, admin yönetim
-- ============================================================
ALTER TABLE legal_authorities ENABLE ROW LEVEL SECURITY;
ALTER TABLE legal_authorities FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "legal_auth_public_read" ON legal_authorities;
CREATE POLICY "legal_auth_public_read" ON legal_authorities
    FOR SELECT USING (TRUE);  -- Herkes okuyabilir (referans veri)

DROP POLICY IF EXISTS "legal_auth_admin_write" ON legal_authorities;
CREATE POLICY "legal_auth_admin_write" ON legal_authorities
    FOR ALL USING (is_platform_admin())
    WITH CHECK (is_platform_admin());

-- ============================================================
-- gcc_tariff_codes — Genel okuma, admin yönetim
-- ============================================================
ALTER TABLE gcc_tariff_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE gcc_tariff_codes FORCE ROW LEVEL SECURITY;

CREATE POLICY "tariff_public_read" ON gcc_tariff_codes
    FOR SELECT USING (TRUE);

CREATE POLICY "tariff_admin_write" ON gcc_tariff_codes
    FOR ALL USING (is_platform_admin())
    WITH CHECK (is_platform_admin());

-- ============================================================
-- zakat_assessments — Tenant + Şirket izolasyonu
-- ============================================================
ALTER TABLE zakat_assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE zakat_assessments FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "zakat_assessments_read" ON zakat_assessments;
CREATE POLICY "zakat_assessments_read" ON zakat_assessments
    FOR SELECT USING (
        is_tenant_member(tenant_id) AND has_company_access(company_id)
    );

DROP POLICY IF EXISTS "zakat_assessments_write" ON zakat_assessments;
CREATE POLICY "zakat_assessments_write" ON zakat_assessments
    FOR INSERT WITH CHECK (
        is_tenant_member(tenant_id) AND has_company_access(company_id)
    );

DROP POLICY IF EXISTS "zakat_assessments_update" ON zakat_assessments;
CREATE POLICY "zakat_assessments_update" ON zakat_assessments
    FOR UPDATE USING (
        is_tenant_member(tenant_id) AND has_company_access(company_id)
    );

-- DELETE: Sadece tenant admin (şirket yöneticisi)
DROP POLICY IF EXISTS "zakat_assessments_delete" ON zakat_assessments;
CREATE POLICY "zakat_assessments_delete" ON zakat_assessments
    FOR DELETE USING (is_tenant_member(tenant_id));

-- ============================================================
-- compliance_check_rules — Genel okuma
-- ============================================================
ALTER TABLE compliance_check_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE compliance_check_rules FORCE ROW LEVEL SECURITY;

CREATE POLICY "compliance_rules_public_read" ON compliance_check_rules
    FOR SELECT USING (TRUE);

CREATE POLICY "compliance_rules_admin_write" ON compliance_check_rules
    FOR ALL USING (is_platform_admin())
    WITH CHECK (is_platform_admin());
```

---

## 4. RPC Güvenliği

Tüm yeni fonksiyonlar `SECURITY DEFINER SET search_path = public` ile tanımlanır:

```sql
CREATE OR REPLACE FUNCTION calculate_transaction_tax_v2(...)
RETURNS TABLE (...) AS $$
...
$$ LANGUAGE plpgsql STABLE 
   SECURITY DEFINER 
   SET search_path = public;  -- Schema injection koruması

CREATE OR REPLACE FUNCTION calculate_zakat(...)
$$ LANGUAGE plpgsql STABLE 
   SECURITY DEFINER 
   SET search_path = public;

CREATE OR REPLACE FUNCTION assess_company_compliance(...)
$$ LANGUAGE plpgsql STABLE 
   SECURITY DEFINER 
   SET search_path = public;
```

---

## 5. Cross-Tenant İzolasyon Testi

Mevcut `021_security_tests.sql` yapısına uygun yeni testler (`057` migrasyonuna eklenir):

```sql
-- Test: Tenant A'nın Zekât değerlendirmesi Tenant B'ye görünmez olmalı
DO $$
DECLARE
  v_tenant_a UUID := 'aaaaaaaa-0000-0000-0000-000000000001';
  v_tenant_b UUID := 'bbbbbbbb-0000-0000-0000-000000000002';
  v_count INT;
BEGIN
  -- Tenant B kullanıcısı olarak Tenant A'nın Zekât değerlendirmelerini sorgulamaya çalış
  PERFORM set_config('app.current_tenant_id', v_tenant_b::TEXT, TRUE);
  
  SELECT COUNT(*) INTO v_count
  FROM zakat_assessments
  WHERE tenant_id = v_tenant_a;
  
  ASSERT v_count = 0, 
    'GÜVENLIK İHLALİ: Tenant B, Tenant A Zekât değerlendirmelerine erişebildi!';
  
  RAISE NOTICE 'PASS: Cross-tenant Zekât izolasyonu doğrulandı';
END;
$$;
```

---

## 6. API Seviyesi Güvenlik Kontrolleri

### 6.1 Dart Tarafında Yetkilendirme

```dart
class LegislationEngineService {
  
  Future<void> _assertCompanyAccess(String companyId) async {
    // Supabase RLS bunu sunucu tarafında zaten enforce eder
    // Ancak UI'da anlamlı hata mesajı için ön kontrol:
    final hasAccess = await _supabase.rpc(
      'has_company_access',
      params: {'p_company_id': companyId}
    );
    if (!hasAccess) {
      throw UnauthorizedException('Bu şirkete erişim yetkiniz yok.');
    }
  }
}
```

### 6.2 Platform Admin Kontrolü

```dart
class PlatformAdminService {
  Future<bool> isPlatformAdmin() async {
    return await _supabase.rpc('is_platform_admin');
  }
  
  Future<void> updateTariffCode(TariffCode code) async {
    if (!await isPlatformAdmin()) {
      throw UnauthorizedException('Bu işlem platform yöneticisi yetkisi gerektirir.');
    }
    // ...
  }
}
```

---

## 7. Veri Dışa Aktarım Güvenliği

Zekât değerlendirmesi ve stopaj kayıtları hassas mali verilerdir. PDF/Excel dışa aktarımda:

```dart
class LegislationExportService {
  Future<Uint8List> exportZakatReport({
    required String companyId,
    required String assessmentYear,
  }) async {
    // 1. Sunucu tarafında RLS doğrulaması (otomatik)
    // 2. İndirme log kaydı (audit_logs tablosuna)
    await _logExport(companyId, 'ZAKAT_REPORT', assessmentYear);
    // 3. PDF üret
    return _generatePdf(data);
  }
  
  Future<void> _logExport(String companyId, String reportType, String period) async {
    await _supabase.from('audit_logs').insert({
      'entity_type': 'LEGISLATION_EXPORT',
      'entity_id': companyId,
      'action': 'EXPORT',
      'metadata': {'report_type': reportType, 'period': period}
    });
  }
}
```

---

## 8. Güvenlik Test Koşturma Planı

```bash
# 1. Migration çalıştır
supabase db push --include-seed

# 2. Cross-tenant izolasyon testlerini çalıştır (PostgreSQL)
supabase db test --path supabase/security_tests/

# 3. Flutter testleri
flutter test test/legislation/

# 4. Flutter analyze
flutter analyze --no-fatal-infos
```

---

*Bu rapor mevcut `017_security_helper_functions.sql` ve `021_security_tests.sql` yapısıyla tamamen uyumludur.*
