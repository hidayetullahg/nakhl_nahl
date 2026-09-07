/// ============================================================
/// ÜLKE MEVZUATI MOTORU  (Madde 5 — Çoklu Ülke / Çoklu Mevzuat)
/// ============================================================
/// Yeni bir ülke eklemek için tek yapmanız gereken, aşağıdaki
/// `ulkeMevzuatlari` haritasına yeni bir ülke kodu (örn. 'PK', 'RU')
/// eklemektir. Ekranlar hiçbir değişiklik gerektirmez.
library country_legislation;

class UlkeMevzuati {
  final String ulkeAdi; // Menüde görünen ad
  final String ulkeKisaKodu; // Cari kod üretiminde kullanılır (TR, KSA, GLB...)
  final String paraBirimi; // Örn: "TRY (Turkish Lira)"
  final String vergiNoEtiketi; // Örn: "VKN / TCKN"
  final List<String> kdvOranlari; // Ülkeye özgü standart oranlar
  final bool eFaturaZorunlu;

  const UlkeMevzuati({
    required this.ulkeAdi,
    required this.ulkeKisaKodu,
    required this.paraBirimi,
    required this.vergiNoEtiketi,
    required this.kdvOranlari,
    required this.eFaturaZorunlu,
  });
}

final Map<String, UlkeMevzuati> ulkeMevzuatlari = {
  'KSA': const UlkeMevzuati(
    ulkeAdi: 'Suudi Arabistan (KSA) — ZATCA Uyumlu',
    ulkeKisaKodu: 'KSA',
    paraBirimi: 'SAR (Saudi Riyal)',
    vergiNoEtiketi: 'TRN — 15 Haneli ZATCA Vergi No',
    kdvOranlari: ['%15 (Standart)', '%0 (Muaf)'],
    eFaturaZorunlu: true,
  ),
  'TR': const UlkeMevzuati(
    ulkeAdi: 'Türkiye (TR) — GİB / e-Fatura',
    ulkeKisaKodu: 'TR',
    paraBirimi: 'TRY (Turkish Lira)',
    vergiNoEtiketi: 'VKN / TCKN',
    kdvOranlari: ['%1', '%10', '%20'],
    eFaturaZorunlu: true,
  ),
  'DE': const UlkeMevzuati(
    ulkeAdi: 'Almanya / Avrupa Birliği (EU)',
    ulkeKisaKodu: 'DE',
    paraBirimi: 'EUR (Euro)',
    vergiNoEtiketi: 'USt-IdNr.',
    kdvOranlari: ['%7', '%19'],
    eFaturaZorunlu: false,
  ),
  'US': const UlkeMevzuati(
    ulkeAdi: 'Amerika Birleşik Devletleri (USA)',
    ulkeKisaKodu: 'US',
    paraBirimi: 'USD (US Dollar)',
    vergiNoEtiketi: 'EIN',
    kdvOranlari: ['Eyalete Göre Değişken'],
    eFaturaZorunlu: false,
  ),
  'USA': const UlkeMevzuati(
    ulkeAdi: 'Amerika Birleşik Devletleri (USA)',
    ulkeKisaKodu: 'US',
    paraBirimi: 'USD (US Dollar)',
    vergiNoEtiketi: 'EIN',
    kdvOranlari: ['Eyalete Göre Değişken'],
    eFaturaZorunlu: false,
  ),
  'UK': const UlkeMevzuati(
    ulkeAdi: 'Birleşik Krallık (UK) — HMRC',
    ulkeKisaKodu: 'UK',
    paraBirimi: 'GBP (British Pound)',
    vergiNoEtiketi: 'VAT Number',
    kdvOranlari: ['%0', '%5', '%20'],
    eFaturaZorunlu: false,
  ),
  'IN': const UlkeMevzuati(
    ulkeAdi: 'Hindistan (IN) — GST',
    ulkeKisaKodu: 'IN',
    paraBirimi: 'INR (Indian Rupee)',
    vergiNoEtiketi: 'GSTIN',
    kdvOranlari: ['%5', '%12', '%18', '%28'],
    eFaturaZorunlu: false,
  ),
  'GLB': const UlkeMevzuati(
    ulkeAdi: 'Diğer / Global Standart',
    ulkeKisaKodu: 'GLB',
    paraBirimi: 'USD (US Dollar)',
    vergiNoEtiketi: 'Vergi Kimlik No',
    kdvOranlari: ['%0'],
    eFaturaZorunlu: false,
  ),
};
