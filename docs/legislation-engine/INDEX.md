# NAKHL & NAHL — Suudi Arabistan Mevzuat Motoru
## Mimari Tasarım Raporu Serisi (R01-R20)

**Oluşturulma Tarihi:** 2026-09-07  
**Toplam Rapor:** 20  
**Durum:** ONAY BEKLİYOR — Kullanıcı onayı sonrası uygulama başlar  

---

## Rapor Dizini

| # | Rapor | Dosya | Kapsam |
|---|---|---|---|
| R01 | [Vizyon ve Kapsam](./R01_VISION_AND_SCOPE.md) | R01_VISION_AND_SCOPE.md | Neden, Ne, Nasıl |
| R02 | [Mevcut Altyapı Analizi](./R02_EXISTING_INFRASTRUCTURE_ANALYSIS.md) | R02_EXISTING_INFRASTRUCTURE_ANALYSIS.md | 042 migrasyonu, ZatcaAdapter, bozmama garantisi |
| R03 | [SA KDV Kural Motoru](./R03_SA_VAT_RULE_ENGINE.md) | R03_SA_VAT_RULE_ENGINE.md | %15 standart, %0 ihracat, muafiyetler, reverse charge |
| R04 | [SA ÖTV Kural Motoru](./R04_SA_EXCISE_TAX_ENGINE.md) | R04_SA_EXCISE_TAX_ENGINE.md | Tütün %100, Karbonlı %50, Enerji %100, Alkol INAPPLICABLE |
| R05 | [Zekât Hesaplama Motoru](./R05_ZAKAT_CALCULATION_ENGINE.md) | R05_ZAKAT_CALCULATION_ENGINE.md | 1445H Yönetmeliği, nisap eşiği, hissedarlık oranı |
| R06 | [GCC Gümrük Tarife Motoru](./R06_GCC_CUSTOMS_TARIFF_ENGINE.md) | R06_GCC_CUSTOMS_TARIFF_ENGINE.md | HS kodu, CET %5, ithalat maliyet hesabı |
| R07 | [Stopaj Vergisi ve Transfer Fiyatlandırması](./R07_WITHHOLDING_TAX_AND_TRANSFER_PRICING.md) | R07_WITHHOLDING_TAX_AND_TRANSFER_PRICING.md | DTAA oranları, CbCR eşiği |
| R08 | [e-Fatura (Fatoora) Derinleştirme](./R08_EFATURA_FATOORA_DERINLESTIRME.md) | R08_EFATURA_FATOORA_DERINLESTIRME.md | PIH hash zinciri, ECDSA, QR Tag 6-8 |
| R09 | [Kural Versiyonlama ve Tarihsel Çözümleme](./R09_RULE_VERSIONING_TEMPORAL.md) | R09_RULE_VERSIONING_TEMPORAL.md | effective_from/to, DRAFT→ACTIVE→SUPERSEDED, çakışma tespiti |
| R10 | [Kaynak Referans ve UNKNOWN Durumu](./R10_SOURCE_REFERENCE_AND_UNKNOWN.md) | R10_SOURCE_REFERENCE_AND_UNKNOWN.md | legal_authorities, legislation_sources, disclaimer |
| R11 | [Uyum Kontrol Raporu RPC](./R11_COMPLIANCE_CHECK_REPORT.md) | R11_COMPLIANCE_CHECK_REPORT.md | assess_company_compliance, trafik ışığı |
| R12 | [Türkiye GİB Entegrasyonu](./R12_TURKEY_GIB_INTEGRATION.md) | R12_TURKEY_GIB_INTEGRATION.md | TR KDV %18→%20, e-İrsaliye, uyum kontrolleri |
| R13 | [Veritabanı Migrasyon Tasarımı](./R13_DATABASE_MIGRATION_DESIGN.md) | R13_DATABASE_MIGRATION_DESIGN.md | 054-057 migrasyonları, ALTER TABLE, rollback planı |
| R14 | [Dart/Flutter Servis Katmanı](./R14_DART_SERVICE_LAYER.md) | R14_DART_SERVICE_LAYER.md | LegislationEngineService, ZakatCalculation, GccTariff |
| R15 | [UI/UX Mevzuat Ekranları](./R15_UI_UX_LEGISLATION_SCREENS.md) | R15_UI_UX_LEGISLATION_SCREENS.md | Dashboard, Uyum, KDV Arama, Tarife, Zekât ekranları |
| R16 | [Güvenlik ve RLS](./R16_SECURITY_AND_RLS.md) | R16_SECURITY_AND_RLS.md | RLS matrisi, cross-tenant izolasyon, audit |
| R17 | [Test Stratejisi](./R17_TEST_STRATEGY.md) | R17_TEST_STRATEGY.md | 195+ test hedefi, PostgreSQL + Dart test koşumu |
| R18 | [Resmi Kaynak Referanslar](./R18_OFFICIAL_SOURCE_REFERENCES.md) | R18_OFFICIAL_SOURCE_REFERENCES.md | ZATCA, GCC, GİB resmi URL'leri, güvenilirlik derecelendirmesi |
| R19 | [Ticari Paketleme](./R19_COMMERCIAL_PACKAGING.md) | R19_COMMERCIAL_PACKAGING.md | SA_LEGISLATION, SA_ZAKAT, COMPLIANCE_CENTER modülleri |
| R20 | [Üretim Sertifikasyon Planı](./R20_PRODUCTION_CERTIFICATION_PLAN.md) | R20_PRODUCTION_CERTIFICATION_PLAN.md | 6 sertifikasyon kapısı, koşturma komutları |

---

## Temel Tasarım Kararları

| Karar | Seçim | Gerekçe |
|---|---|---|
| Mevcut 042 tabloları | ALTER TABLE (silme yok) | Bozmama garantisi |
| UNKNOWN durumu | Hesaplama yok, kaynak göster | "Tahmin değil, şeffaflık" |
| Disclaimer | Her API yanıtında zorunlu | Hukuki sorumluluk |
| Tarife başvurusu | public reference data (herkes okur) | Reusability |
| Zekât izolasyonu | Tenant + Company RLS | Hassas mali veri |
| e-Fatura imzalama | Supabase Edge Function | Private key istemcide olmaz |
| Test hedefi | ≥195 test, %100 pass | KANIT YOKSA PASS YOK |

---

## Sonraki Adım

Tüm raporlar incelendikten sonra:

1. **ONAY**: Uygulama başlar → 054 migrasyonu yazılır ve uygulanır
2. **REVIZYON**: Belirtilen raporlar güncellenir, yeniden onay istenir
3. **KAPSAM DEĞİŞİKLİĞİ**: İlgili raporlar güncellenir

---

*Bu seri NAKHL & NAHL Suudi Arabistan Mevzuat Motoru için tam mimari tasarım belgesidir.*  
*Tüm kararlar resmi mevzuat kaynakları veya mevcut kaynak kod referanslarıyla desteklenmiştir.*
