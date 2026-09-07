# R19 — TİCARİ PAKETLEME VE MODÜL KATALOĞU GÜNCELLEMESİ
## Commercial Packaging — Legislation Module Integration

**Rapor No:** R19  
**Versiyon:** 1.0  
**Tarih:** 2026-09-07  
**Durum:** ONAY BEKLİYOR  

---

## 1. Mevcut Modül Kataloğu Durumu

`lib/services/billing/module_catalog_service.dart` ve `docs/MODULE_CATALOG.md` dosyalarında 18 ticari modül tanımlanmış.

**Bu raporun amacı**: Mevzuat Motoru kapsamındaki yeni modülleri mevcut kataloğa entegre etmek ve fiyatlandırma paketlerini güncellemek.

---

## 2. Mevzuat Motorundan Çıkan Yeni Modüller

### 2.1 SA Vergi ve Mevzuat Modülü (SA_LEGISLATION)

```dart
ProductModule(
  code: 'SA_LEGISLATION',
  name: 'Suudi Arabistan Vergi ve Mevzuat Motoru',
  nameEn: 'Saudi Arabia Tax & Legislation Engine',
  nameAr: 'محرك الضرائب والتشريعات السعودية',
  category: ModuleCategory.compliance,
  tier: ModuleTier.enterprise,
  
  features: [
    'ZATCA KDV kuralları (%15, %0, muafiyetler)',
    'Özel Tüketim Vergisi (ÖTV) kuralları',
    'GCC Gümrük Tarife motoru (HS kodu bazlı)',
    'Stopaj vergisi hesaplama (DTAA ile)',
    'Transfer fiyatlandırması uyarısı',
    'Tarihsel kural versiyonlama',
    'Uyum kontrol raporu',
    'Resmi ZATCA kaynak bağlantıları',
  ],
  
  dependencies: ['BASE', 'ACCOUNTING', 'SA_ZATCA'],
  
  pricing: ModulePricing(
    monthlyPriceSar: 499,
    yearlyPriceSar: 4_990,   // 2 ay bedava
    setupFeeSar: 1_500,
    currency: 'SAR',
  ),
)
```

### 2.2 Zekât Hesaplama Modülü (SA_ZAKAT)

```dart
ProductModule(
  code: 'SA_ZAKAT',
  name: 'Zekât Hesaplama ve Beyan Yönetimi',
  nameEn: 'Zakat Assessment & Compliance Module',
  nameAr: 'نظام حساب الزكاة والإقرار',
  category: ModuleCategory.compliance,
  tier: ModuleTier.professional,
  
  features: [
    '1445H Zekât Yönetmeliğine uyumlu hesaplama',
    'Suudi/yabancı hissedarlık oranı yönetimi',
    'Yıllık Zekât matrahı hesaplama (tam balans entegrasyon)',
    'Nisap eşiği otomatik güncelleme',
    'Zekât beyan raporu (ZATCA uyumlu)',
    'PDF rapor ihracı',
    'Tarihsel Zekât arşivi',
  ],
  
  dependencies: ['BASE', 'ACCOUNTING', 'SA_LEGISLATION'],
  
  pricing: ModulePricing(
    monthlyPriceSar: 299,
    yearlyPriceSar: 2_990,
    setupFeeSar: 800,
    currency: 'SAR',
  ),
)
```

### 2.3 Uyum Kontrol Modülü (COMPLIANCE_CENTER)

```dart
ProductModule(
  code: 'COMPLIANCE_CENTER',
  name: 'Uyum Merkezi',
  nameEn: 'Compliance Center',
  nameAr: 'مركز الامتثال',
  category: ModuleCategory.compliance,
  tier: ModuleTier.professional,
  
  features: [
    'Otomatik uyum durumu değerlendirme',
    'Kırmızı/Sarı/Yeşil trafik ışığı raporu',
    'SA + TR uyum kontrol listesi',
    'Yaklaşan mevzuat değişikliği uyarıları',
    'Eksik belge takibi',
    'Resmi kaynak bağlantıları (ZATCA, GİB)',
    'Uyum durumu PDF raporu',
  ],
  
  dependencies: ['BASE', 'SA_LEGISLATION'],
  
  pricing: ModulePricing(
    monthlyPriceSar: 199,
    yearlyPriceSar: 1_990,
    setupFeeSar: 500,
    currency: 'SAR',
  ),
)
```

---

## 3. Güncellenmiş Modül Kataloğu (Tam Liste)

| # | Kod | Modül | Aylık (SAR) | Tier |
|---|---|---|---|---|
| 1 | BASE | Temel Platform | Zorunlu | Standard |
| 2 | ACCOUNTING | Muhasebe | 299 | Standard |
| 3 | STOCK | Stok Yönetimi | 299 | Standard |
| 4 | SALES | Satış ve Faturalama | 299 | Standard |
| 5 | PURCHASING | Satın Alma | 299 | Standard |
| 6 | POS | Perakende/Kasa | 399 | Standard |
| 7 | TR_EINVOICE | TR e-Fatura (GİB) | 199 | Standard |
| 8 | **SA_ZATCA** | **SA ZATCA Phase 2** | **399** | **Professional** |
| 9 | **SA_LEGISLATION** | **SA Vergi Mevzuat Motoru** | **499** | **Enterprise** |
| 10 | **SA_ZAKAT** | **Zekât Hesaplama** | **299** | **Professional** |
| 11 | **COMPLIANCE_CENTER** | **Uyum Merkezi** | **199** | **Professional** |
| 12 | HR | İnsan Kaynakları | 299 | Standard |
| 13 | PAYROLL | Bordro | 399 | Standard |
| 14 | LOGISTICS | Lojistik ve Nakliye | 399 | Standard |
| 15 | AGRICULTURE | Tarım ve Hasat | 499 | Enterprise |
| 16 | HALAL | Helal Uyum | 299 | Professional |
| 17 | DATA_MIGRATION | Veri Aktarımı | Tek seferlik | Add-on |
| 18 | INITIAL_SETUP | İlk Kurulum Hizmeti | Tek seferlik | Add-on |

**Kalın** olanlar bu raporda yeni eklenen modüller.

---

## 4. Paketleme Stratejisi

### 4.1 SA Market Paketi (SA_STARTER)

Suudi Arabistan'daki işletmeler için özel bundle:

```
SA_STARTER Paketi = BASE + ACCOUNTING + SALES + SA_ZATCA + SA_LEGISLATION
Aylık: 1,395 SAR (ayrı satın alım: 1,695 SAR → %18 tasarruf)
Yıllık: 13,950 SAR
```

### 4.2 SA Enterprise Paketi (SA_ENTERPRISE)

Büyük SA şirketleri için tam paket:

```
SA_ENTERPRISE = BASE + ACCOUNTING + STOCK + SALES + PURCHASING + SA_ZATCA + SA_LEGISLATION + SA_ZAKAT + COMPLIANCE_CENTER
Aylık: 2,490 SAR (ayrı satın alım: 2,990 SAR → %17 tasarruf)
```

### 4.3 TR Market Paketi (TR_STARTER)

```
TR_STARTER = BASE + ACCOUNTING + SALES + TR_EINVOICE
Aylık: 799 SAR (veya ~7,800 TRY)
```

---

## 5. Mevzuat Modülü — Satış Argümanları

| Rekabet Avantajı | Açıklama |
|---|---|
| **Otomatik Tarihsel Hesaplama** | Hiçbir rakip tarihsel vergi kuralı versiyonlaması sunmuyor |
| **UNKNOWN Güvencesi** | Belirsiz kurallar için tahmin değil, şeffaf uyarı |
| **Resmi Kaynak Bağlantısı** | Her hesaplamada ZATCA/GİB kaynağı gösterilir |
| **Zekât Entegrasyonu** | SA'da yerleşik Suudi şirketlere özgü modül |
| **ZATCA Phase 2 Uyumu** | PIH hash zinciri, UBL 2.1, ECDSA imzalama |

---

## 6. Veri Aktarımı — Mevzuat Verisi İçin Fiyatlandırma

Müşteri kendi eski sisteminden mevzuat kural verisi aktarmak isterse:

| Hizmet | Ücret |
|---|---|
| HS Kodu bulk import (Excel) | 2,500 SAR (tek seferlik) |
| Tarihsel vergi kuralı aktarımı | 3,500 SAR (tek seferlik) |
| Özel kural tanımlama danışmanlığı | 500 SAR/saat |
| ZATCA CSID onboarding desteği | 2,000 SAR |

---

## 7. Modül Bağımlılık Kuralları

```dart
// SA_LEGISLATION'ı aktif etmek için:
dependencies: {
  'SA_LEGISLATION': ['BASE', 'ACCOUNTING', 'SA_ZATCA'],
  'SA_ZAKAT':       ['BASE', 'ACCOUNTING', 'SA_LEGISLATION'],
  'COMPLIANCE_CENTER': ['BASE', 'SA_LEGISLATION'],
}
```

Bağımlılık kuralları `module_catalog_service.dart`'taki `ModuleDependency` sınıfı üzerinden kontrol edilir.

---

*Bu rapor mevcut `docs/MODULE_CATALOG.md` ve `lib/services/billing/module_catalog_service.dart` ile birlikte okunmalıdır.*
