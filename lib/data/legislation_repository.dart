import '../models/legislation_model.dart';

/// NAKHL & NAHL - Uluslararası Ülke Mevzuatı ve Resmi Devlet Kimlik/Vergi Deposu
class LegislationRepository {
  /// Desteklenen Diller (Öncelikli diller: TR, UG, AR, ZH, DE, EN)
  static const List<AppLanguage> supportedLanguages = [
    AppLanguage(
      code: 'TR',
      nativeName: 'Türkçe',
      englishName: 'Turkish',
      flag: '🇹🇷',
      isRtl: false,
    ),
    AppLanguage(
      code: 'UG',
      nativeName: 'ئۇيغۇرچە',
      englishName: 'Uyghur',
      flag: '🌙',
      isRtl: true, // Uygur Arap Alfabesi - Sağdan Sola
    ),
    AppLanguage(
      code: 'AR',
      nativeName: 'العربية',
      englishName: 'Arabic',
      flag: '🇸🇦',
      isRtl: true, // Arapça - Sağdan Sola
    ),
    AppLanguage(
      code: 'ZH',
      nativeName: '简体中文',
      englishName: 'Chinese (Simplified)',
      flag: '🇨🇳',
      isRtl: false,
    ),
    AppLanguage(
      code: 'DE',
      nativeName: 'Deutsch',
      englishName: 'German',
      flag: '🇩🇪',
      isRtl: false,
    ),
    AppLanguage(
      code: 'EN',
      nativeName: 'English',
      englishName: 'English',
      flag: '🇬🇧',
      isRtl: false,
    ),
  ];

  /// Desteklenen Ülkeler ve Devlet Resmi Kimlik / Vergi Mevzuatları
  static const Map<String, CountryLegislation> countries = {
    // 1. TÜRKİYE
    'TR': CountryLegislation(
      code: 'TR',
      name: 'Türkiye',
      flag: '🇹🇷',
      currencyCode: 'TRY',
      currencySymbol: '₺',
      taxLabel: 'VKN (Vergi Kimlik Numarası - 10 Hane)',
      taxHint: 'Tüzel şirketler için 10 haneli resmi vergi numarası',
      taxRegex: r'^\d{10}$',
      nationalIdLabel: 'TCKN (T.C. Kimlik Numarası - 11 Hane)',
      nationalIdHint: 'Gerçek şahıslar ve şahıs şirketleri için 11 haneli TCKN',
      nationalIdRegex: r'^\d{11}$',
      companyRegLabel: 'Ticaret Sicil No & MERSİS Numarası',
      companyRegHint: 'Ticaret Sicil Müdürlüğü tescil no ve 16 haneli MERSİS',
      taxAuthorityName: 'Bağlı Olunan Vergi Dairesi Müdürlüğü',
      requiresVat: true,
      vatOptions: ['%0', '%1', '%10', '%20'],
      standardVat: '%20',
      eInvoiceSystemName: 'GİB E-Fatura & E-Arşiv Portalı',
    ),

    // 2. SUUDİ ARABİSTAN
    'SA': CountryLegislation(
      code: 'SA',
      name: 'Suudi Arabistan (المملكة العربية السعودية)',
      flag: '🇸🇦',
      currencyCode: 'SAR',
      currencySymbol: '﷼',
      taxLabel: 'ZATCA VAT / TIN (الرقم الضريبي - 15 Hane)',
      taxHint: '15 haneli ZATCA vergi numarası (3 ile başlar, 3 ile biter)',
      taxRegex: r'^3\d{13}3$',
      nationalIdLabel:
          'National ID / Iqama (الهوية الوطنية / الإقامة - 10 Hane)',
      nationalIdHint:
          'Suudi vatandaşları için 1 ile, ikametli yabancılar için 2 ile başlayan 10 hane',
      nationalIdRegex: r'^[12]\d{9}$',
      companyRegLabel: 'CR Number / Commercial Registration (السجل التجاري)',
      companyRegHint:
          'Ticaret Bakanlığı 10 haneli resmi ticari sicil belgesi no',
      taxAuthorityName:
          'ZATCA (Zakat, Tax and Customs Authority - هيئة الزكاة والضريبة)',
      requiresVat: true,
      vatOptions: ['%15', '%0 (İhracat/المعفاة)'],
      standardVat: '%15',
      eInvoiceSystemName: 'ZATCA Fatoorah Phase 2 (Elektronik Fatura)',
    ),

    // 3. ÇİN HALK CUMHURİYETİ
    'CN': CountryLegislation(
      code: 'CN',
      name: 'Çin Halk Cumhuriyeti (中华人民共和国)',
      flag: '🇨🇳',
      currencyCode: 'CNY',
      currencySymbol: '¥',
      taxLabel: 'USCI / 统一社会信用代码 (18 Haneli Tekil Sosyal Kredi Kodu)',
      taxHint: 'SAMR ve Vergi İdaresi STA ortak tekil işletme ve vergi kimliği',
      taxRegex: r'^[0-9A-Z]{18}$',
      nationalIdLabel: 'Resident Identity Card / 居民身份证 (SFZ - 18 Hane)',
      nationalIdHint:
          '18 haneli vatandaşlık kimlik kartı numarası (17 rakam + 1 basamak/X)',
      nationalIdRegex: r'^\d{17}[\dXx]$',
      companyRegLabel: 'Business License No / 营业执照注册号',
      companyRegHint: 'Resmi işletme faaliyet ruhsatı tescil numarası',
      taxAuthorityName: 'Devlet Vergi İdaresi / 国家税务总局 (STA)',
      requiresVat: true,
      vatOptions: [
        '%0 (Muaf/免税)',
        '%3 (Küçük İşletme/小规模)',
        '%6 (Hizmet/现代服务)',
        '%9 (Ulaşım & İnşaat/交通建筑)',
        '%13 (Genel İmalat & Mal/一般制造业)'
      ],
      standardVat: '%13 (Genel İmalat & Mal/一般制造业)',
      eInvoiceSystemName:
          '数电发票 (Fully Digitalized E-Fapiao / Golden Tax Phase IV)',
    ),

    // 4. ALMANYA
    'DE': CountryLegislation(
      code: 'DE',
      name: 'Almanya (Deutschland)',
      flag: '🇩🇪',
      currencyCode: 'EUR',
      currencySymbol: '€',
      taxLabel: 'USt-IdNr. (DE + 9 Hane) & Steuernummer',
      taxHint:
          'AB KDV numarası (DE123456789) veya eyalet Steuernummer (12/345/67890)',
      taxRegex: r'^(DE)?[0-9]{9,11}$',
      nationalIdLabel:
          'Steuer-ID / IdNr. (Steuerliche Identifikationsnummer - 11 Hane)',
      nationalIdHint:
          'Almanya mukimleri için 11 haneli ömür boyu şahıs vergi kimliği',
      nationalIdRegex: r'^\d{11}$',
      companyRegLabel: 'Handelsregisternummer (HRB / HRA & Amtsgericht)',
      companyRegHint:
          'Yetkili mahkeme ve ticaret sicil numarası (Örn: HRB 123456 Amtsgericht Berlin)',
      taxAuthorityName: 'Zuständiges Finanzamt (Yetkili Vergi Dairesi)',
      requiresVat: true,
      vatOptions: [
        '%0',
        '%7 (Ermäßigt/İndirimli)',
        '%19 (Regelsteuersatz/Standart)'
      ],
      standardVat: '%19 (Regelsteuersatz/Standart)',
      eInvoiceSystemName: 'E-Rechnung (XRechnung & ZUGFeRD 2.0)',
    ),

    // 5. AVRUPA BİRLİĞİ (GENEL)
    'EU': CountryLegislation(
      code: 'EU',
      name: 'Avrupa Birliği (European Union)',
      flag: '🇪🇺',
      currencyCode: 'EUR',
      currencySymbol: '€',
      taxLabel: 'EU VAT / VIES Numarası',
      taxHint:
          'Ülke Kodu + 8-12 hane (Örn: FR12345678901, IT12345678901, PL1234567890)',
      nationalIdLabel: 'National ID / Personal Tax Identification Number',
      nationalIdHint:
          'İlgili AB üye devleti ulusal kimlik veya şahıs vergi numarası',
      companyRegLabel: 'Company Registry / EORI Numarası',
      companyRegHint:
          'AB Gümrük ve Dış Ticaret Operatör Kimlik Numarası (EORI)',
      taxAuthorityName: 'National Tax & Customs Administration / VIES',
      requiresVat: true,
      vatOptions: [
        '%0 (Intra-Community/İç Pazar Muaf)',
        '%5 (İndirimli)',
        '%10 (Orta Oran)',
        '%20 (Standart Oran)',
        '%21 (Standart Oran)',
        '%23 (Yüksek Standart)'
      ],
      standardVat: '%20 (Standart Oran)',
      eInvoiceSystemName: 'Peppol BIS Billing 3.0 / EU Directive 2014/55/EU',
    ),

    // 6. BİRLEŞİK ARAP EMİRLİKLERİ
    'AE': CountryLegislation(
      code: 'AE',
      name: 'Birleşik Arap Emirlikleri (الإمارات العربية المتحدة)',
      flag: '🇦🇪',
      currencyCode: 'AED',
      currencySymbol: 'د.إ',
      taxLabel: 'FTA TRN (Tax Registration Number - 15 Hane)',
      taxHint: '15 haneli Federal Vergi İdaresi KDV numarası (100 ile başlar)',
      taxRegex: r'^\d{15}$',
      nationalIdLabel: 'Emirates ID (بطاقة الهوية الإماراتية - 15 Hane)',
      nationalIdHint:
          '784 ile başlayan 15 haneli BAE ulusal kimlik kartı numarası',
      nationalIdRegex: r'^784-?\d{4}-?\d{7}-?\d$',
      companyRegLabel: 'Trade License Number (رخصة تجارية - DED / Freezone)',
      companyRegHint:
          'Ekonomi Departmanı (DED) veya Serbest Bölge resmi ticaret lisans no',
      taxAuthorityName:
          'Federal Tax Authority (الهيئة الاتحادية للضرائب - FTA)',
      requiresVat: true,
      vatOptions: ['%0 (Sıfır Oranlı / Zero Rated)', '%5 (Standart)'],
      standardVat: '%5 (Standart)',
      eInvoiceSystemName: 'UAE E-Invoicing System (MoF & FTA Peppol)',
    ),

    // 7. AMERİKA BİRLEŞİK DEVLETLERİ
    'US': CountryLegislation(
      code: 'US',
      name: 'Amerika Birleşik Devletleri (United States)',
      flag: '🇺🇸',
      currencyCode: 'USD',
      currencySymbol: r'$',
      taxLabel: 'EIN / FEIN (Employer Identification Number - 9 Hane)',
      taxHint: 'IRS Federal İşveren Vergi Kimlik Numarası (Format: 12-3456789)',
      taxRegex: r'^\d{2}-?\d{7}$',
      nationalIdLabel:
          'SSN (Social Security) / ITIN (Individual Tax ID - 9 Hane)',
      nationalIdHint:
          'Şahıslar için 9 haneli SSN (123-45-6789) veya ITIN (9XX-XX-XXXX)',
      nationalIdRegex: r'^\d{3}-?\d{2}-?\d{4}$',
      companyRegLabel: 'State Entity ID / Secretary of State File Number',
      companyRegHint:
          'Şirketin tescil edildiği eyalet sekreterliği no (Delaware, Wyoming vb.)',
      taxAuthorityName:
          'Internal Revenue Service (IRS) & State Dept. of Revenue',
      requiresVat: false, // Eyalet satış vergisi esastır
      vatOptions: [
        '%0 (Federal Exemption / B2B Wholesales)',
        '%4 (State Sales Tax Base)',
        '%6 (Average State Sales Tax)',
        '%8.25 (Combined State & Local Tax)'
      ],
      standardVat: '%0 (Federal Exemption / B2B Wholesales)',
      eInvoiceSystemName: 'E-Invoicing Exchange Market Pilot / BPC Network',
    ),

    // 8. BİRLEŞİK KRALLIK
    'GB': CountryLegislation(
      code: 'GB',
      name: 'Birleşik Krallık (United Kingdom)',
      flag: '🇬🇧',
      currencyCode: 'GBP',
      currencySymbol: '£',
      taxLabel: 'HMRC VAT Registration Number (GB + 9 Hane)',
      taxHint:
          'Format: GB123456789 veya 10 haneli UTR (Unique Taxpayer Reference)',
      taxRegex: r'^(GB)?[0-9]{9,10}$',
      nationalIdLabel: 'National Insurance Number (NINO) / Personal UTR',
      nationalIdHint: 'Format: QQ 12 34 56 A veya şahıs 10 haneli UTR numarası',
      companyRegLabel:
          'Companies House CRN (Company Registration Number - 8 Hane)',
      companyRegHint:
          'Companies House tarafından verilen 8 karakterli şirket tescil no',
      taxAuthorityName: 'HM Revenue and Customs (HMRC)',
      requiresVat: true,
      vatOptions: [
        '%0 (Zero Rate)',
        '%5 (Reduced Rate)',
        '%20 (Standard Rate)'
      ],
      standardVat: '%20 (Standard Rate)',
      eInvoiceSystemName: 'Making Tax Digital (MTD) for VAT',
    ),
  };

  /// Ülke koduna göre mevzuat getir
  static CountryLegislation getLegislation(String countryCode) {
    return countries[countryCode] ?? countries['TR']!;
  }

  /// Dil koduna göre dil modeli getir
  static AppLanguage getLanguage(String langCode) {
    return supportedLanguages.firstWhere(
      (lang) => lang.code == langCode,
      orElse: () => supportedLanguages.first,
    );
  }
}
