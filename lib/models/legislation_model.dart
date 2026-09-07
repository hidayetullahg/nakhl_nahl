/// NAKHL & NAHL - Uluslararası Mevzuat ve Dil Modelleri

/// Ülke mevzuatı, devlet resmi kimlik/vergi kuralları ve para birimi model tanımı
class CountryLegislation {
  final String code; // ISO Ülke Kodu (TR, SA, CN, DE, EU, AE, US, GB)
  final String name; // Ülke Adı
  final String flag; // Emoji Bayrak
  final String currencyCode; // TRY, SAR, CNY, EUR, USD, GBP, AED
  final String currencySymbol; // ₺, ﷼, ¥, €, $, £, د.إ

  // 1. Devlet Resmi Vergi Kimlik Numarası (Tax ID / VAT / TIN)
  final String
      taxLabel; // Resmi Vergi No Etiketi (VKN, ZATCA VAT, USCI, USt-IdNr., EIN, TRN)
  final String taxHint; // Vergi no hane sayısı ve kuralı
  final String? taxRegex; // Vergi format regex doğrulaması

  // 2. Devlet Resmi Vatandaşlık / Şahıs Kimlik Numarası (National ID / Personal ID)
  final String
      nationalIdLabel; // TCKN, Iqama/National ID, 居民身份证 (SFZ), Steuer-ID, SSN/ITIN, Emirates ID, NINO
  final String nationalIdHint; // Şahıs kimlik no kuralı ve formatı
  final String? nationalIdRegex; // Şahıs kimlik regex

  // 3. Devlet Resmi Şirket Ticaret Sicil / Tescil Numarası (Company Reg / Trade License / CR)
  final String
      companyRegLabel; // Ticaret Sicil No & Mersis, CR Number (السجل التجاري), 营业执照, Handelsregister, State Entity ID, Trade License, CRN
  final String companyRegHint; // Sicil tescil kuralı

  // 4. Vergi Dairesi / İdare Adı
  final String
      taxAuthorityName; // Vergi Dairesi, ZATCA Şubesi, 税务局 (STA), Finanzamt, IRS / State Treasury, HMRC, FTA

  // 5. Yasal KDV / MwSt / Satış Vergisi
  final bool requiresVat; // KDV uygulanıyor mu?
  final List<String> vatOptions; // Yasal KDV oranları
  final String standardVat; // Varsayılan yasal oran

  // 6. E-Fatura / Elektronik Vergi Sistemi
  final String
      eInvoiceSystemName; // GİB E-Fatura, ZATCA Fatoorah, 数电发票 (Golden Tax), E-Rechnung (XRechnung/ZUGFeRD), Peppol

  const CountryLegislation({
    required this.code,
    required this.name,
    required this.flag,
    required this.currencyCode,
    required this.currencySymbol,
    required this.taxLabel,
    required this.taxHint,
    this.taxRegex,
    required this.nationalIdLabel,
    required this.nationalIdHint,
    this.nationalIdRegex,
    required this.companyRegLabel,
    required this.companyRegHint,
    required this.taxAuthorityName,
    required this.requiresVat,
    required this.vatOptions,
    required this.standardVat,
    required this.eInvoiceSystemName,
  });

  String get currencyDisplay => '$currencyCode ($currencySymbol)';
}

/// Uygulama dil modeli (LTR / RTL desteği ile)
class AppLanguage {
  final String code; // TR, UG, AR, ZH, DE, EN
  final String nativeName; // Türkçe, ئۇيغۇرچە, العربية, 简体中文, Deutsch, English
  final String englishName;
  final String flag;
  final bool isRtl; // Arapça ve Uygurca için true

  const AppLanguage({
    required this.code,
    required this.nativeName,
    required this.englishName,
    required this.flag,
    this.isRtl = false,
  });
}
