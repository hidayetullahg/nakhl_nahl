# R15 — UI/UX — MEVZUAT YÖNETİM EKRANI TASARIMI
## Legislation Management Screen Design

**Rapor No:** R15  
**Versiyon:** 1.0  
**Tarih:** 2026-09-07  
**Durum:** ONAY BEKLİYOR  

---

## 1. Ekran Haritası (Yeni Ekranlar)

```
lib/screens/legislation/
  legislation_dashboard_screen.dart     ← Ana mevzuat gösterge paneli
  compliance_check_screen.dart          ← Uyum kontrolü
  tax_rule_lookup_screen.dart           ← Vergi kuralı sorgulama
  tariff_lookup_screen.dart             ← GCC Gümrük Tarifesi arama
  zakat_assessment_screen.dart          ← Zekât hesaplama ekranı
  withholding_calculator_screen.dart    ← Stopaj vergisi hesaplama
  legislation_list_screen.dart          ← Mevzuat listesi
  legislation_change_alerts_screen.dart ← Yaklaşan değişiklikler
```

---

## 2. Ana Ekran: `LegislationDashboardScreen`

### 2.1 Tasarım Konsepti

```
┌─────────────────────────────────────────────────────┐
│  🏛️  MEVZUAT & UYUM MERKEZİ                        │
│  Son güncelleme: 7 Eylül 2026                       │
│─────────────────────────────────────────────────────│
│                                                     │
│  [🔴 KRİTİK] Uyum Durumu                           │
│  ZATCA Phase 2 CSID eksik — e-fatura gönderilemez  │
│  [Hemen Düzelt]                                     │
│                                                     │
│─────────────────────────────────────────────────────│
│  HIZLI ARAÇLAR                                      │
│                                                     │
│  [KDV Hesapla]  [Tarife Ara]  [Zekât Hesapla]      │
│  [Stopaj]       [Uyum Raporu] [Mevzuat Listesi]    │
│                                                     │
│─────────────────────────────────────────────────────│
│  YAKLAŞAN DEĞİŞİKLİKLER                            │
│                                                     │
│  📅 45 gün sonra: SA KDV oranı güncellenebilir     │
│     Kaynak: ZATCA Duyurusu                          │
│                                                     │
│─────────────────────────────────────────────────────│
│  SON HESAPLAMALAR                                   │
│  • 07.09.2026 — Fatura INV-SA-2026-0042 — %15 KDV  │
│  • 06.09.2026 — İthalat HS 8517.13 — %5 Gümrük     │
└─────────────────────────────────────────────────────┘
```

---

## 3. Uyum Kontrol Ekranı: `ComplianceCheckScreen`

```dart
class ComplianceCheckScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Uyum Durumu Kontrolü')),
      body: FutureBuilder<ComplianceReport>(
        future: context.read<LegislationEngineService>()
                       .assessCompliance(companyId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const LoadingIndicator();
          
          final report = snapshot.data!;
          return Column(children: [
            _buildOverallStatusBanner(report.overallStatus),
            Expanded(child: ListView.builder(
              itemCount: report.checks.length,
              itemBuilder: (ctx, i) => _buildCheckTile(report.checks[i]),
            )),
          ]);
        },
      ),
    );
  }
  
  Widget _buildCheckTile(ComplianceCheckResult check) {
    return ListTile(
      leading: Icon(_getStatusIcon(check.status), color: _getStatusColor(check.status)),
      title: Text(check.title),
      subtitle: Text(check.statusDetail),
      trailing: check.sourceUrl != null
          ? IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: () => launchUrl(Uri.parse(check.sourceUrl!)),
            )
          : null,
    );
  }
}
```

---

## 4. Vergi Kuralı Sorgulama: `TaxRuleLookupScreen`

```
┌─────────────────────────────────────────────────────┐
│  🔍  VERGİ KURALI SORGULAMA                        │
│─────────────────────────────────────────────────────│
│  Ülke:          [Suudi Arabistan ▼]                 │
│  İşlem Tipi:    [Satış ▼]                           │
│  İşlem Tarihi:  [07.09.2026]                        │
│  Tutar (SAR):   [10,000]                            │
│  Ürün/HS Kodu:  [İsteğe bağlı]                      │
│                                                     │
│  [VERGİYİ HESAPLA]                                  │
│                                                     │
│─────────────────────────────────────────────────────│
│  SONUÇ                                              │
│                                                     │
│  ✅ SA_VAT_STANDARD_15                              │
│  KDV Oranı:     %15                                 │
│  KDV Tutarı:    1,500 SAR                           │
│  TOPLAM:        11,500 SAR                          │
│                                                     │
│  Kesinlik:      ✅ KESİN                            │
│  Kaynak:        Royal Decree M/113 — Art. 7         │
│  Resmi Link:    [zatca.gov.sa ↗]                    │
│                                                     │
│  ⚠️ Bu hesaplama bilgi amaçlıdır...                │
└─────────────────────────────────────────────────────┘
```

---

## 5. GCC Tarife Arama: `TariffLookupScreen`

```
┌─────────────────────────────────────────────────────┐
│  📦  GCC GÜMRÜK TARİFE SORGUSU                     │
│─────────────────────────────────────────────────────│
│  HS Kodu:  [8517.13_______]    [ARA]                │
│            VEYA                                     │
│  Ürün Adı: [akıllı telefon___] [METIN ARA]         │
│                                                     │
│  İthalat Tarihi: [07.09.2026]                       │
│  CIF Değer (SAR): [50,000]                          │
│                                                     │
│─────────────────────────────────────────────────────│
│  SONUÇ: HS 8517.13                                  │
│  Açıklama: Smartphones and other mobile phones      │
│                                                     │
│  GCC CET Oranı:    %5                               │
│  Gümrük Vergisi:   2,500 SAR                        │
│  ÖTV:              Hayır                            │
│  KDV Matrahı:      52,500 SAR                       │
│  KDV (%15):        7,875 SAR                        │
│  TOPLAM MALİYET:   60,375 SAR                       │
│                                                     │
│  İthalat Durumu:   ✅ SERBEST                       │
└─────────────────────────────────────────────────────┘
```

---

## 6. Zekât Hesaplama Ekranı: `ZakatAssessmentScreen`

```
┌─────────────────────────────────────────────────────┐
│  🕌  ZEKÂT HESAPLAMA                               │
│  1446H / 2024 Mali Yılı                             │
│─────────────────────────────────────────────────────│
│  ÖDENMIŞ SERMAYE:          [1,000,000 SAR]          │
│  YASAL YEDEKLER:           [200,000 SAR]            │
│  DAĞITILMAMIŞ KÂR:        [500,000 SAR]             │
│  CARİ YIL NET KÂRI:        [300,000 SAR]            │
│  UZUN VADELİ BORÇLAR:      [400,000 SAR]            │
│  SABİT VARLIKLAR (NET):    [800,000 SAR]            │
│  MADDİ OLMAYAN VARLIKLAR:  [50,000 SAR]             │
│  UZUN VADELİ YATIRIMLAR:   [100,000 SAR]            │
│  UZUN VADELİ AVANSLAR:     [30,000 SAR]             │
│                                                     │
│  SUUDİ HİSSE ORANI:        [%100 ▼]                │
│                                                     │
│  [HESAPLA]                                          │
│─────────────────────────────────────────────────────│
│  SONUÇ                                              │
│  Zekât Matrahı:    1,420,000 SAR                    │
│  Suudi Hisse:      %100                             │
│  Zekât Oranı:      %2.5                             │
│  ÖDENECEK ZEKÂT:   35,500 SAR                       │
│                                                     │
│  Nisap Eşiği:      18,400 SAR — ✅ Eşik Üstü       │
│                                                     │
│  ⚠️ Bu hesaplama tahminden ibarettir...             │
│  [PDF Rapor]  [ZATCA'ya Git ↗]                      │
└─────────────────────────────────────────────────────┘
```

---

## 7. Dashboard Entegrasyonu

Mevcut `dashboard_screen.dart`'a eklenecek yeni widget:

```dart
class LegislationComplianceWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ComplianceStatusCard(
      onTap: () => Navigator.pushNamed(context, '/legislation/compliance'),
      // Kırmızı/Sarı/Yeşil renk kodu
      // Kritik uyum sayısı
      // Son güncelleme tarihi
    );
  }
}
```

---

## 8. Navigation Entegrasyonu

`lib/main.dart` veya router dosyasına eklenecek route'lar:

```dart
'/legislation':             LegislationDashboardScreen(),
'/legislation/compliance':  ComplianceCheckScreen(),
'/legislation/tax-lookup':  TaxRuleLookupScreen(),
'/legislation/tariff':      TariffLookupScreen(),
'/legislation/zakat':       ZakatAssessmentScreen(),
'/legislation/withholding': WithholdingCalculatorScreen(),
'/legislation/changes':     LegislationChangeAlertsScreen(),
```

---

*Bu rapor R11 (Uyum Kontrol) ve R14 (Dart Servis Katmanı) ile birlikte uygulanmalıdır.*
