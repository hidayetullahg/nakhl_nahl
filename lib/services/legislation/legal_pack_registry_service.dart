// ==============================================================================
// NAKHL & NAHL — LEGAL PACK REGISTRY SERVICE
// Master Directive: Global Shelf Architecture & Pack Lifecycle Management
// ==============================================================================

import '../../models/legislation/legal_pack_model.dart';

class LegalPackRegistryService {
  static final LegalPackRegistryService instance = LegalPackRegistryService._();
  LegalPackRegistryService._();

  // 4 Aktif Paket (Master Directive Öncelik 1-4)
  final List<LegalPackModel> _activePacks = [
    const LegalPackModel(
      packCode: 'SAUDI_ARABIA_PACK',
      jurisdictionCode: 'SA',
      packNameTr: 'Suudi Arabistan Tam Operasyonel Mevzuat Paketi',
      packNameEn: 'Saudi Arabia Full Business Operation Pack',
      scope: LegalPackScope.fullBusinessOperation,
      status: LegalShelfStatus.active,
      coveragePercentage: 98.5,
      primaryAuthorities: ['ZATCA (Vergi/Gümrük)', 'SFDA (Gıda/Helal)', 'Ticaret Bakanlığı (CR)', 'MEWA (Tarım)'],
      coveredDomains: ['KDV %15', '1445H Zekât', 'ÖTV/Excise', 'Fatoora Faz 2', 'GCC Gümrük Tarifesi', 'SFDA Gıda İthalat', 'Fasah'],
      notes: 'ZATCA, SFDA ve MEWA resmi kaynaklarına tam entegre çalışır durumdadır.',
    ),
    const LegalPackModel(
      packCode: 'TURKEY_PACK',
      jurisdictionCode: 'TR',
      packNameTr: 'Türkiye Tam Operasyonel Mevzuat Paketi',
      packNameEn: 'Turkey Full Business Operation Pack',
      scope: LegalPackScope.fullBusinessOperation,
      status: LegalShelfStatus.active,
      coveragePercentage: 98.0,
      primaryAuthorities: ['GİB (Gelir İdaresi)', 'Ticaret Bakanlığı (Gümrük)', 'Tarım ve Orman Bakanlığı', 'HAK (Helal)'],
      coveredDomains: ['KDV %1/%10/%20', 'Kurumlar %25', 'e-Fatura / e-Arşiv / e-İrsaliye', 'GTİP Tarife', 'TGK Etiketleme', 'HAK Helal'],
      notes: 'GİB ve Tarım Bakanlığı güncel tebliğ ve kanunlarıyla tam uyumludur.',
    ),
    const LegalPackModel(
      packCode: 'EU_FOOD_IMPORT_PACK',
      jurisdictionCode: 'EU',
      packNameTr: 'Avrupa Birliği Gıda İthalatı & Resmi Kontroller Paketi',
      packNameEn: 'European Union Food Import & Official Controls Pack',
      scope: LegalPackScope.foodImportOnly,
      status: LegalShelfStatus.active,
      coveragePercentage: 95.0,
      primaryAuthorities: ['European Commission DG SANTE', 'TRACES NT', 'EFSA', 'EUR-Lex'],
      coveredDomains: ['General Food Law (Reg 178/2002 Art 18)', 'Resmi Kontroller (Reg 2017/625)', 'TRACES CHED-D', 'FIC Etiketleme (Reg 1169/2011)', 'Aflatoksin & Pestisit MRL'],
      notes: 'Yalnızca TR ve SA’dan AB’ye gıda ihracatı/ithalatı için gereken mevzuattır. Genel AB müktesebatını içermez.',
    ),
    const LegalPackModel(
      packCode: 'GERMANY_FOOD_IMPORT_PACK',
      jurisdictionCode: 'DE',
      packNameTr: 'Almanya Ulusal Gıda İthalatı & Piyasaya Arz Paketi',
      packNameEn: 'Germany Food Import & Market Pack',
      scope: LegalPackScope.foodImportOnly,
      status: LegalShelfStatus.active,
      coveragePercentage: 94.5,
      primaryAuthorities: ['BVL (Federal Tüketici Koruma & Gıda)', 'ZSVR (LUCID Ambalaj Sicili)', 'Bundeszollverwaltung (Alman Gümrük)'],
      coveredDomains: ['LFGB Ulusal Gıda Kanunu', 'VerpackG LUCID Sicil & Lisans', 'Almanca Dilinde Etiketleme Şartı', 'Alman İthalatçı Sorumlulukları'],
      notes: 'AB mevzuatı üzerine eklenen Almanya ulusal gereksinimleridir.',
    ),
  ];

  // Boş Raflar (NOT_LOADED) — İhtiyaç olduğunda açılır
  final List<LegalJurisdictionModel> _emptyShelves = [
    const LegalJurisdictionModel(
      code: 'CN',
      isoAlpha2: 'CN',
      nameTr: 'Çin',
      nameEn: 'China',
      nameAr: 'الصين',
      region: 'ASIA',
      isActive: false,
      shelfStatus: LegalShelfStatus.notLoaded,
      officialPortalUrl: 'http://customs.gov.cn',
    ),
    const LegalJurisdictionModel(
      code: 'IN',
      isoAlpha2: 'IN',
      nameTr: 'Hindistan',
      nameEn: 'India',
      nameAr: 'الهند',
      region: 'ASIA',
      isActive: false,
      shelfStatus: LegalShelfStatus.notLoaded,
      officialPortalUrl: 'https://www.fssai.gov.in',
    ),
    const LegalJurisdictionModel(
      code: 'RU',
      isoAlpha2: 'RU',
      nameTr: 'Rusya',
      nameEn: 'Russia',
      nameAr: 'روسيا',
      region: 'ASIA',
      isActive: false,
      shelfStatus: LegalShelfStatus.notLoaded,
      officialPortalUrl: 'https://fsvps.gov.ru',
    ),
    const LegalJurisdictionModel(
      code: 'AE',
      isoAlpha2: 'AE',
      nameTr: 'Birleşik Arap Emirlikleri',
      nameEn: 'United Arab Emirates',
      nameAr: 'الإمارات العربية المتحدة',
      region: 'MIDDLE_EAST',
      isActive: false,
      shelfStatus: LegalShelfStatus.notLoaded,
      officialPortalUrl: 'https://tax.gov.ae',
    ),
    const LegalJurisdictionModel(
      code: 'QA',
      isoAlpha2: 'QA',
      nameTr: 'Katar',
      nameEn: 'Qatar',
      nameAr: 'قطر',
      region: 'MIDDLE_EAST',
      isActive: false,
      shelfStatus: LegalShelfStatus.notLoaded,
      officialPortalUrl: 'https://www.moph.gov.qa',
    ),
    const LegalJurisdictionModel(
      code: 'KW',
      isoAlpha2: 'KW',
      nameTr: 'Kuveyt',
      nameEn: 'Kuwait',
      nameAr: 'الكويت',
      region: 'MIDDLE_EAST',
      isActive: false,
      shelfStatus: LegalShelfStatus.notLoaded,
      officialPortalUrl: 'https://www.customs.gov.kw',
    ),
    const LegalJurisdictionModel(
      code: 'BH',
      isoAlpha2: 'BH',
      nameTr: 'Bahreyn',
      nameEn: 'Bahrain',
      nameAr: 'البحرين',
      region: 'MIDDLE_EAST',
      isActive: false,
      shelfStatus: LegalShelfStatus.notLoaded,
      officialPortalUrl: 'https://www.nbr.gov.bh',
    ),
    const LegalJurisdictionModel(
      code: 'OM',
      isoAlpha2: 'OM',
      nameTr: 'Umman',
      nameEn: 'Oman',
      nameAr: 'عمان',
      region: 'MIDDLE_EAST',
      isActive: false,
      shelfStatus: LegalShelfStatus.notLoaded,
      officialPortalUrl: 'https://tms.taxoman.gov.om',
    ),
    const LegalJurisdictionModel(
      code: 'EG',
      isoAlpha2: 'EG',
      nameTr: 'Mısır',
      nameEn: 'Egypt',
      nameAr: 'مصر',
      region: 'MIDDLE_EAST',
      isActive: false,
      shelfStatus: LegalShelfStatus.notLoaded,
      officialPortalUrl: 'https://www.eta.gov.eg',
    ),
    const LegalJurisdictionModel(
      code: 'JO',
      isoAlpha2: 'JO',
      nameTr: 'Ürdün',
      nameEn: 'Jordan',
      nameAr: 'الأردن',
      region: 'MIDDLE_EAST',
      isActive: false,
      shelfStatus: LegalShelfStatus.notLoaded,
      officialPortalUrl: 'https://jfda.jo',
    ),
    const LegalJurisdictionModel(
      code: 'GB',
      isoAlpha2: 'GB',
      nameTr: 'Birleşik Krallık',
      nameEn: 'United Kingdom',
      nameAr: 'المملكة المتحدة',
      region: 'EUROPE',
      isActive: false,
      shelfStatus: LegalShelfStatus.notLoaded,
      officialPortalUrl: 'https://www.food.gov.uk',
    ),
    const LegalJurisdictionModel(
      code: 'US',
      isoAlpha2: 'US',
      nameTr: 'Amerika Birleşik Devletleri',
      nameEn: 'United States',
      nameAr: 'الولايات المتحدة',
      region: 'AMERICAS',
      isActive: false,
      shelfStatus: LegalShelfStatus.notLoaded,
      officialPortalUrl: 'https://www.fda.gov',
    ),
    const LegalJurisdictionModel(
      code: 'CA',
      isoAlpha2: 'CA',
      nameTr: 'Kanada',
      nameEn: 'Canada',
      nameAr: 'كندا',
      region: 'AMERICAS',
      isActive: false,
      shelfStatus: LegalShelfStatus.notLoaded,
      officialPortalUrl: 'https://inspection.canada.ca',
    ),
    const LegalJurisdictionModel(
      code: 'AU',
      isoAlpha2: 'AU',
      nameTr: 'Avustralya',
      nameEn: 'Australia',
      nameAr: 'أستراليا',
      region: 'ASIA',
      isActive: false,
      shelfStatus: LegalShelfStatus.notLoaded,
      officialPortalUrl: 'https://www.agriculture.gov.au',
    ),
    const LegalJurisdictionModel(
      code: 'JP',
      isoAlpha2: 'JP',
      nameTr: 'Japonya',
      nameEn: 'Japan',
      nameAr: 'اليابان',
      region: 'ASIA',
      isActive: false,
      shelfStatus: LegalShelfStatus.notLoaded,
      officialPortalUrl: 'https://www.mhlw.go.jp',
    ),
    const LegalJurisdictionModel(
      code: 'KR',
      isoAlpha2: 'KR',
      nameTr: 'Güney Kore',
      nameEn: 'South Korea',
      nameAr: 'كوريا الجنوبية',
      region: 'ASIA',
      isActive: false,
      shelfStatus: LegalShelfStatus.notLoaded,
      officialPortalUrl: 'https://www.mfds.go.kr',
    ),
    const LegalJurisdictionModel(
      code: 'KZ',
      isoAlpha2: 'KZ',
      nameTr: 'Kazakistan',
      nameEn: 'Kazakhstan',
      nameAr: 'كازاخستان',
      region: 'ASIA',
      isActive: false,
      shelfStatus: LegalShelfStatus.notLoaded,
      officialPortalUrl: 'https://kgd.gov.kz',
    ),
    const LegalJurisdictionModel(
      code: 'UZ',
      isoAlpha2: 'UZ',
      nameTr: 'Özbekistan',
      nameEn: 'Uzbekistan',
      nameAr: 'أوزبكستان',
      region: 'ASIA',
      isActive: false,
      shelfStatus: LegalShelfStatus.notLoaded,
      officialPortalUrl: 'https://soliq.uz',
    ),
    const LegalJurisdictionModel(
      code: 'AZ',
      isoAlpha2: 'AZ',
      nameTr: 'Azerbaycan',
      nameEn: 'Azerbaijan',
      nameAr: 'أذربيجان',
      region: 'ASIA',
      isActive: false,
      shelfStatus: LegalShelfStatus.notLoaded,
      officialPortalUrl: 'https://afsa.gov.az',
    ),
  ];

  List<LegalPackModel> getActivePacks() => List.unmodifiable(_activePacks);
  List<LegalJurisdictionModel> getEmptyShelves() => List.unmodifiable(_emptyShelves);

  /// Ülke koduna göre aktif mevzuat paketini döner (Bulunamazsa null)
  LegalPackModel? getPackForCountry(String countryCode) {
    try {
      return _activePacks.firstWhere(
        (p) => p.jurisdictionCode.toUpperCase() == countryCode.toUpperCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Ülke paketinin aktif olup olmadığını kontrol eder
  bool isCountryPackActive(String countryCode) {
    final pack = getPackForCountry(countryCode);
    return pack != null && pack.status == LegalShelfStatus.active;
  }

  /// On-Demand Keşif İsteği (Yeni Ülkeye İhracat Başlatma Talebi)
  /// Durumu NOT_LOADED -> DISCOVERY yapar.
  Map<String, dynamic> requestPackDiscovery({
    required String countryCode,
    required String targetProductCategory,
    String? requesterNote,
  }) {
    final shelf = _emptyShelves.firstWhere(
      (s) => s.code == countryCode,
      orElse: () => throw Exception('Bilinmeyen ülke kodu: $countryCode'),
    );

    return {
      'status': 'DISCOVERY',
      'countryCode': shelf.code,
      'countryName': shelf.nameTr,
      'targetProductCategory': targetProductCategory,
      'workflow': 'DISCOVERED -> EXTRACTED -> AI_PROPOSED -> TESTING -> LEGAL_REVIEW -> APPROVED -> ACTIVE',
      'message': '${shelf.nameTr} için odaklanmış gıda ithalatı ve gümrük mevzuatı resmi kaynak taraması kuyruğa alındı. İnsan Hukuk İncelemesi (Human Legal Review) onayı olmadan bağlayıcı kural aktive edilmez.',
      'officialPortalUrl': shelf.officialPortalUrl,
      'queuedAt': DateTime.now().toIso8601String(),
    };
  }
}
