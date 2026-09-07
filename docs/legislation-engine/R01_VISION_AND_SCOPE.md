# R01 — VİZYON VE KAPSAM
## NAKHL & NAHL — Suudi Arabistan Mevzuat Motoru

**Rapor No:** R01  
**Versiyon:** 1.0  
**Tarih:** 2026-09-07  
**Durum:** ONAY BEKLİYOR  

---

## 1. Neden Bu Rapor?

Mevcut `042_legislation_tax_engine.sql` migrasyonu, `legislations` ve `tax_rules` tablolarıyla temel bir mevzuat altyapısı sunar. Ancak bu altyapı bir **veri depolama katmanıdır**; bir **kural motoru değildir**.

Suudi Arabistan düzenleyici ortamı şu anda şunları gerektirmektedir:

| Gereksinim | Mevcut Durum | Hedef Durum |
|---|---|---|
| ZATCA KDV (%15) otomatik hesaplama | ✅ `calculate_transaction_tax` RPC | ✅ Korunuyor + genişletiliyor |
| Özel Tüketim Vergisi (ÖTV/Excise) kuralları | ❌ Yok | ✅ Yeni kural tipi |
| Zekât hesaplama motoru | ❌ Yok | ✅ Yeni hesaplama modülü |
| GCC Gümrük Tarife motoru (HS kodu bazlı) | ❌ Yok | ✅ Tarife tablosu + RPC |
| Stopaj Vergisi (Withholding) — Hizmet ihracatı | ❌ Eksik | ✅ Yeni kural tipi |
| Kural versiyonlama ve tarihe göre çözümleme | ⚠️ Kısmi (effective_from/to) | ✅ Tam versiyon yönetimi |
| Resmi kaynak bağlantısı (ZATCA URL) | ❌ Yok | ✅ Her kuralda kaynak ref |
| UNKNOWN/ambiguous durum | ❌ Yok | ✅ Yeni `UNKNOWN` statüsü |
| Uyum kontrol raporu | ❌ Yok | ✅ Yeni uyum raporu RPC'si |
| Hukuki uyarı / sorumluluk reddi | ❌ Yok | ✅ Tüm API yanıtlarında |

---

## 2. Vizyon

NAKHL & NAHL Mevzuat Motoru şunu yapmalıdır:

> **Mevzuatı belge olarak saklamak yerine makine tarafından uygulanabilir kurallara dönüştürmek.**

Bu demektir ki:
- Bir satış faturası oluşturulduğunda, sistem hangi KDV oranının uygulanacağını otomatik çözümler.
- Bir ithalat faturası için HS kodu girildiğinde, GCC Gümrük Tarifesi otomatik devreye girer.
- Bir Suudi yerleşik şirket Zekât beyanı hazırlarken sistem hangi varlıkların Zekât matrahına girdiğini hesaplar.
- Bir kural belirsizse sistem `UNKNOWN` döner, tahmin yapmaz, kullanıcıyı resmi kaynağa yönlendirir.
- Her kural, geçerli olduğu tarih aralığını, kaynak kanunu, resmi ZATCA/GIB URL'sini ve versiyonunu taşır.

---

## 3. Kapsam

### 3.1 Bu Motora Dahil Olan Alanlar

| # | Alan | Kapsam |
|---|---|---|
| 1 | Suudi KDV (ZATCA VAT) | %15 standard, %0 sıfır oranlı, muaf |
| 2 | Özel Tüketim Vergisi | Tütün, alkol (içki mevzuatı uygulanamaz), karbonlı içecek, enerji içeceği |
| 3 | Zekât | SA yerleşik Suudi şirket sahipleri için yıllık Zekât matrahı hesabı |
| 4 | GCC Gümrük Tarifesi | HS kodu bazlı, GCC Common External Tariff |
| 5 | Stopaj Vergisi | Hizmet/royalty ödemeleri, yabancı şirketlere yapılan ödemeler |
| 6 | Transfer Fiyatlandırması Bildirimi | İlişkili taraf eşik değeri uyarısı |
| 7 | e-Fatura (Fatoora Phase 2) | B2B Clearance, B2C Reporting — mevcut `ZatcaPhase2Adapter` ile entegre |
| 8 | Türkiye KDV (GİB) | Mevcut `042_legislation_tax_engine.sql` ile korunuyor |

### 3.2 Bu Motora Dahil OLMAYAN Alanlar (Sorumluluk Reddi)

- Bireysel hukuki danışmanlık
- ZATCA ile bireysel vergi mükellefiyeti tesisi
- Kişisel gelir vergisi hesabı (SA'da uygulanmıyor, ancak yabancı çalışanlar için stopaj var)
- Gümrük değer tespiti uyuşmazlıkları

> ⚠️ **HUKUK UYARISI**: Bu motor uyum kurallarını otomatize eder, hukuki danışmanlık vermez. Tüm nihai kararlar için yetkili bir vergi danışmanına başvurulmalıdır. Belirsiz kurallar `UNKNOWN` statüsüyle işaretlenir ve resmi kaynağa bağlantı verilir.

---

## 4. Tasarım İlkeleri

| İlke | Açıklama |
|---|---|
| **Kural Önceliği** | Resmi kanun > Yönetmelik > ZATCA Kılavuzu > Sistem varsayılanı |
| **Tarihe Göre Çözümleme** | Her kural `effective_from` / `effective_to` taşır; geçmiş işlemler eski kuralla hesaplanır |
| **Kaynak Şeffaflığı** | Her kural `source_url` (resmi ZATCA/GIB linki) + `source_reference` (Resmi Gazete no.) taşır |
| **UNKNOWN Statüsü** | Belirsiz veya kaynak olmayan kural asla tahmin üretmez |
| **Sorumluluk Reddi** | Her API yanıtında `disclaimer` alanı zorunlu |
| **Mevcut Mimariyi Bozma** | `042_legislation_tax_engine.sql` tabloları `ALTER TABLE` ile genişletilir, silinmez |
| **RLS Zorunlu** | Her yeni tablo `ENABLE ROW LEVEL SECURITY` + `FORCE ROW LEVEL SECURITY` |
| **Test Zorunlu** | Her yeni kural tipi için en az 1 birim testi |

---

## 5. Sonraki Raporlar

Bu R01 raporu, aşağıdaki 19 raporun temelini oluşturur:

- **R02**: Mevcut Altyapı Analizi (bozmama garantisi)
- **R03**: Suudi KDV Kural Motoru Tasarımı
- **R04**: Özel Tüketim Vergisi Kural Motoru
- **R05**: Zekât Hesaplama Motoru
- **R06**: GCC Gümrük Tarife Motoru
- **R07**: Stopaj Vergisi ve Transfer Fiyatlandırması
- **R08**: e-Fatura (Fatoora) Derinleştirme
- **R09**: Kural Versiyonlama ve Tarihe Göre Çözümleme
- **R10**: Kaynak Referans ve UNKNOWN Durumu
- **R11**: Uyum Kontrol Raporu RPC Tasarımı
- **R12**: Türkiye GİB Entegrasyonu (Mevcut Genişletme)
- **R13**: Veritabanı Migrasyon Tasarımı (054-057)
- **R14**: Dart/Flutter Servis Katmanı Tasarımı
- **R15**: UI/UX — Mevzuat Yönetim Ekranı
- **R16**: Güvenlik ve RLS Tasarımı
- **R17**: Test Stratejisi
- **R18**: Resmi Kaynak Referanslar (ZATCA, GCC, GİB)
- **R19**: Ticari Paketleme (Modül Kataloğu Güncellemesi)
- **R20**: Üretim Sertifikasyon Planı

---

*Bu rapor NAKHL & NAHL Mevzuat Motoru Tasarım Serisi'nin ilkidir. Kural: KANIT YOKSA PASS YOK — Her tasarım kararı ya mevcut kod referansıyla ya da resmi mevzuat kaynağıyla desteklenmiştir.*
