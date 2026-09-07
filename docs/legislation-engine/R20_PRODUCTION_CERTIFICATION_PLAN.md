# R20 — ÜRETİM SERTİFİKASYON PLANI
## Production Certification Plan — Legislation Engine

**Rapor No:** R20  
**Versiyon:** 1.0  
**Tarih:** 2026-09-07  
**Durum:** ONAY BEKLİYOR  

---

## 1. Sertifikasyon Süreci Genel Bakış

Bu belge, Mevzuat Motoru'nun üretime alınabilmesi için geçmesi gereken kriterleri tanımlar.

> **Mevcut Üretim Durumu**: `FINAL_PRODUCTION_CERTIFICATION.md` → Ticari SaaS altyapısı sertifikalı.  
> **Bu Rapor**: Mevzuat Motoru ek sertifikasyon kriterleri.

---

## 2. Sertifikasyon Kapıları (Production Gates)

### Kapı 1 — Veritabanı Migrasyonu

| Kontrol | Durum | Kriter |
|---|---|---|
| 054 migrasyonu başarılı | ⬜ BEKLIYOR | `supabase db push` hatasız |
| 055 migrasyonu başarılı | ⬜ BEKLIYOR | SA/TR kural seed eksiksiz |
| 056 migrasyonu başarılı | ⬜ BEKLIYOR | Zekât tabloları ve RPC |
| 057 migrasyonu başarılı | ⬜ BEKLIYOR | v2 RPC'ler |
| Mevcut 53 migrasyon etkilenmedi | ⬜ BEKLIYOR | Rollback testi |
| Cross-tenant izolasyon testleri | ⬜ BEKLIYOR | 3 PostgreSQL testi PASS |

### Kapı 2 — Fonksiyonel Testler

| Kontrol | Durum | Kriter |
|---|---|---|
| `flutter test` — Toplam ≥195 test | ⬜ BEKLIYOR | 0 başarısız |
| SA KDV %15 hesaplama | ⬜ BEKLIYOR | Doğru sonuç + disclaimer |
| SA KDV %0 ihracat | ⬜ BEKLIYOR | Doğru sonuç |
| TR KDV %18→%20 versiyonlama | ⬜ BEKLIYOR | Tarih bazlı doğru |
| Zekât hesaplama 5 senaryo | ⬜ BEKLIYOR | Matematiksel doğruluk |
| GCC Gümrük tarife arama | ⬜ BEKLIYOR | HS kodu çalışıyor |
| Stopaj vergisi DTAA | ⬜ BEKLIYOR | Oranlar doğru |
| UNKNOWN durumu tetiklenme | ⬜ BEKLIYOR | Tahmin üretmiyor |
| INAPPLICABLE durumu (alkol) | ⬜ BEKLIYOR | İşlem engelleniyor |
| Disclaimer her yanıtta var | ⬜ BEKLIYOR | Boş değil |

### Kapı 3 — Statik Analiz ve Derleme

| Kontrol | Durum | Kriter |
|---|---|---|
| `flutter analyze` | ⬜ BEKLIYOR | 0 issue |
| `flutter build web --release` | ⬜ BEKLIYOR | Başarılı, uyarısız |
| Dart null safety uyumu | ⬜ BEKLIYOR | 0 null error |

### Kapı 4 — Güvenlik Denetimi

| Kontrol | Durum | Kriter |
|---|---|---|
| Tüm yeni tablolarda RLS ENABLED | ⬜ BEKLIYOR | 0 istisna |
| Tüm yeni tablolarda FORCE RLS | ⬜ BEKLIYOR | 0 istisna |
| SECURITY DEFINER + search_path | ⬜ BEKLIYOR | Tüm yeni RPC'lerde |
| Platform admin guard (tarife güncellemesi) | ⬜ BEKLIYOR | Yetkisiz kullanıcı reddedilir |
| Zekât verisi tenant izolasyonu | ⬜ BEKLIYOR | Cross-tenant erişim sıfır |

### Kapı 5 — Hukuki Uyarı Doğrulaması

| Kontrol | Durum | Kriter |
|---|---|---|
| Her vergi hesaplaması yanıtında disclaimer | ⬜ BEKLIYOR | `disclaimer IS NOT NULL` |
| Her UNKNOWN yanıtında resmi kaynak linki | ⬜ BEKLIYOR | ZATCA/GİB URL mevcut |
| Alkol kategori engeli UI'da görünür | ⬜ BEKLIYOR | Mesaj açıkça gösteriliyor |
| "Bu hesaplama hukuki tavsiye değildir" metni | ⬜ BEKLIYOR | Her sonuç sayfasında |

### Kapı 6 — Ticari Modül Entegrasyonu

| Kontrol | Durum | Kriter |
|---|---|---|
| SA_LEGISLATION modülü katalogda | ⬜ BEKLIYOR | `module_catalog_service.dart` güncellendi |
| SA_ZAKAT modülü katalogda | ⬜ BEKLIYOR | Fiyatlandırma doğru |
| COMPLIANCE_CENTER katalogda | ⬜ BEKLIYOR | Bağımlılık kuralları doğru |
| Modül entitlement RPC çalışıyor | ⬜ BEKLIYOR | `has_active_module` yeni modüller için |

---

## 3. Sertifikasyon Koşturma Komutları

```bash
# Adım 1: Migrasyonları uygula
supabase db push

# Adım 2: Tüm testleri koştur
flutter test --coverage
# Beklenen: ≥195 PASS, 0 FAIL

# Adım 3: Statik analiz
flutter analyze --no-fatal-infos
# Beklenen: 0 issue

# Adım 4: Web release derlemesi
flutter build web --release
# Beklenen: Exit code 0

# Adım 5: Belirli kural testleri
flutter test test/legislation/legislation_engine_test.dart -v

# Adım 6: PostgreSQL güvenlik testleri (Supabase üzerinde)
supabase db test --path supabase/security_tests/057_legislation_engine_tests.sql
```

---

## 4. Belge Güncelleme Listesi

Sertifikasyon tamamlandığında güncellenecek belgeler:

| Belge | Güncelleme İçeriği |
|---|---|
| `docs/FINAL_PRODUCTION_CERTIFICATION.md` | Mevzuat Motoru sertifikasyon bölümü eklenir |
| `docs/ZATCA_INTEGRATION.md` | Phase 2 PIH hash zinciri, ECDSA imzalama |
| `docs/MODULE_CATALOG.md` | SA_LEGISLATION, SA_ZAKAT, COMPLIANCE_CENTER modülleri |
| `docs/legislation-engine/` | Bu dizindeki tüm R01-R20 raporları ONAYLANDI statüsüne güncellenir |
| `README.md` | Mevzuat Motoru özellik listesi eklenir |

---

## 5. Kısmi Üretim Aktivasyonu

Mevzuat Motoru bütün bir bütün olarak değil, katman katman üretime alınabilir:

| Faz | Kapsam | Ön Koşul |
|---|---|---|
| Faz A | SA KDV + TR KDV kuralları (seed data) | 054-055 migrasyon |
| Faz B | Uyum Kontrol Raporu | Faz A |
| Faz C | GCC Gümrük Tarifesi | Faz A |
| Faz D | Zekât Hesaplama | Faz A + 056 migrasyon |
| Faz E | Stopaj Vergisi | Faz A |
| Faz F | e-Fatura PIH Hash Zinciri | ZATCA Production CSID |

---

## 6. Bilinen Kısıtlamalar (Production Gates CONDITIONAL)

| Kısıtlama | Durum | Geçici Çözüm |
|---|---|---|
| ZATCA Production CSID gerekli (e-Fatura) | CONDITIONAL | Sandbox/Simulation'da tam çalışıyor |
| 1445H Nisap değeri altın fiyatına bağlı | Yıllık güncelleme | Platform admin tarafından güncellenir |
| GCC CET tam ürün listesi (HS8 düzeyi) | Kısmi | En yaygın HS kodları seeded, diğerleri UNKNOWN |
| DTAA anlaşma detayları (tüm ülkeler) | Kısmi | Türkiye, Almanya, Hindistan, Çin seeded |

---

## 7. Mevzuat Motoru Sertifikasyon Özeti

Bu 20 rapor tamamlandıktan ve kullanıcı onayı alındıktan sonra:

```
✅ R01 — Vizyon ve Kapsam
✅ R02 — Mevcut Altyapı Analizi
✅ R03 — SA KDV Kural Motoru
✅ R04 — SA ÖTV Kural Motoru
✅ R05 — Zekât Hesaplama Motoru
✅ R06 — GCC Gümrük Tarife Motoru
✅ R07 — Stopaj Vergisi ve Transfer Fiyatlandırması
✅ R08 — e-Fatura (Fatoora) Derinleştirme
✅ R09 — Kural Versiyonlama ve Tarihsel Çözümleme
✅ R10 — Kaynak Referans ve UNKNOWN Durumu
✅ R11 — Uyum Kontrol Raporu RPC
✅ R12 — Türkiye GİB Entegrasyonu
✅ R13 — Veritabanı Migrasyon Tasarımı (054-057)
✅ R14 — Dart/Flutter Servis Katmanı
✅ R15 — UI/UX Mevzuat Ekranları
✅ R16 — Güvenlik ve RLS
✅ R17 — Test Stratejisi
✅ R18 — Resmi Kaynak Referanslar
✅ R19 — Ticari Paketleme
✅ R20 — Üretim Sertifikasyon Planı

→ UYGULAMA AŞAMASINA HAZIR
```

Uygulama aşaması başladığında:
1. `054_legislation_engine_foundation.sql` migrasyonu yazılır ve uygulanır
2. `055_sa_legislation_rules.sql` yazılır
3. `056_zakat_engine.sql` yazılır
4. `057_compliance_and_tax_v2.sql` yazılır
5. Dart servis katmanı kodlanır
6. UI ekranları kodlanır
7. Testler yazılır ve koşturulur
8. `FINAL_PRODUCTION_CERTIFICATION.md` güncellenir

---

*Bu rapor NAKHL & NAHL Mevzuat Motoru Tasarım Serisi'nin son raporu (R20/20) ve uygulama geçişinin başlangıç noktasıdır.*  
*KANIT YOKSA PASS YOK — Tüm tasarım kararları R01-R19 boyunca mevcut kod referansları veya resmi mevzuat kaynakları ile desteklenmiştir.*
