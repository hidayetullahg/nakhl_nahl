// ==============================================================================
// NAKHL & NAHL — CROSS-BORDER LEGAL ENGINE SERVICE
// Master Directive: Multi-Jurisdiction Isolation & Cross-Border Framework Resolver
// ==============================================================================

import '../../models/legislation/product_legal_profile_model.dart';
import '../../models/legislation/cross_border_evaluation_model.dart';

class CrossBorderLegalEngineService {
  static final CrossBorderLegalEngineService instance = CrossBorderLegalEngineService._();
  CrossBorderLegalEngineService._();

  /// Ana Çapraz Sınır Mevzuat Çözümleme Motoru
  /// Kuralları Asla Birleştirmez (JURISDICTION ISOLATION):
  /// - Source Jurisdiction (İhracat ve Çıkış Hukuku)
  /// - Supranational Framework (AB Gıda İthalat & Resmi Kontroller)
  /// - Member State (Almanya Ulusal Piyasaya Arz & Ambalaj)
  CrossBorderEvaluationResult resolveApplicableLegalFramework(ProductLegalProfileModel profile) {
    final now = DateTime.now();
    final source = profile.sourceCountry.toUpperCase();
    final dest = profile.destinationCountry.toUpperCase();

    // 1. Durum: Boş Raf (NOT_LOADED) Kontrolü
    final activeCountries = {'SA', 'TR', 'DE', 'EU'};
    if (!activeCountries.contains(dest)) {
      return _buildEmptyShelfResult(profile, now);
    }

    // 2. Senaryolar
    if (source == 'SA' && (dest == 'DE' || dest == 'EU' || dest == 'SA')) {
      return _evaluateSaudiToGermany(profile, now);
    } else if (source == 'TR' && (dest == 'DE' || dest == 'EU' || dest == 'TR')) {
      return _evaluateTurkeyToGermany(profile, now);
    } else if (source == 'SA' && dest == 'TR') {
      return _evaluateSaudiToTurkey(profile, now);
    } else if (source == 'TR' && dest == 'SA') {
      return _evaluateTurkeyToSaudi(profile, now);
    }

    // Bilinmeyen kombinasyon için güvenli fallback
    return _buildUnknownRouteResult(profile, now);
  }

  /// Uyumluluk analizi için yüksek seviyeli yardımcı fonksiyon
  CrossBorderEvaluationResult analyzeExportCompliance({
    required String originCountry,
    required String destinationCountry,
    required String hsCode,
    required String productType,
    double quantityKg = 1000.0,
  }) {
    final profile = ProductLegalProfileModel(
      productName: productType,
      hsCode: hsCode,
      sourceCountry: originCountry,
      destinationCountry: destinationCountry,
      quantityKg: quantityKg,
    );
    return resolveApplicableLegalFramework(profile);
  }

  // --------------------------------------------------------------------------
  // SENARYO 1: SUUDİ ARABİSTAN → ALMANYA / AB (HURMA / GIDA İHRACATI)
  // --------------------------------------------------------------------------
  CrossBorderEvaluationResult _evaluateSaudiToGermany(
    ProductLegalProfileModel profile,
    DateTime now,
  ) {
    // 1. Suudi Arabistan Çıkış & İhracat Yükümlülükleri (ZATCA, SFDA, MEWA)
    final saExportObligations = [
      const LegalObligationItem(
        code: 'SA_EXP_FASAH_DECLARATION',
        title: 'ZATCA Fasah İhracat Gümrük Beyannamesi',
        description: 'Tüm ticari ihracat sevkiyatları Fasah platformu üzerinden çıkış gümrüğüne önceden beyan edilmelidir.',
        jurisdictionCode: 'SA',
        authority: 'ZATCA',
        officialCitation: 'Saudi Unified Customs Law, Art. 31 & Fasah Procedural Guide 2024',
        responsibleParty: 'EXPORTER',
      ),
      const LegalObligationItem(
        code: 'SA_EXP_SFDA_HEALTH_CLEARANCE',
        title: 'SFDA İhracat Sağlık ve Uygunluk Onayı',
        description: 'İhraç edilen gıda ürününün Suudi Gıda ve İlaç Kurumu (SFDA) kayıtlı tesislerde üretilmiş ve paketlenmiş olması zorunludur.',
        jurisdictionCode: 'SA',
        authority: 'SFDA',
        officialCitation: 'SFDA Food Act Royal Decree No. M/1, Art. 14',
        responsibleParty: 'EXPORTER',
      ),
      const LegalObligationItem(
        code: 'SA_EXP_MEWA_PHYTOSANITARY',
        title: 'MEWA Bitki Sağlık Sertifikası (Phytosanitary)',
        description: 'Hurma ve tarımsal bitkisel ürünlerin sevkiyatı öncesinde Çevre, Su ve Tarım Bakanlığı (MEWA) fitosaniter denetiminden geçmesi şarttır.',
        jurisdictionCode: 'SA',
        authority: 'MEWA',
        officialCitation: 'MEWA Agricultural Quarantine Law, Executive Regulation Art. 8',
        responsibleParty: 'EXPORTER',
      ),
      const LegalObligationItem(
        code: 'SA_EXP_VAT_ZERO_RATE',
        title: 'ZATCA KDV İhracat İstisnası (%0)',
        description: 'Suudi Arabistan dışına yapılan resmi ihracatlar gümrük çıkış beyannamesiyle tevsik edilmek şartıyla %0 KDV oranına tabidir.',
        jurisdictionCode: 'SA',
        authority: 'ZATCA',
        officialCitation: 'Saudi VAT Implementing Regulations 2020, Art. 32',
        responsibleParty: 'EXPORTER',
      ),
    ];

    // 2. Avrupa Birliği Gıda İthalatı Yükümlülükleri (Reg 178/2002, Reg 2017/625, TRACES NT)
    final euObligations = [
      const LegalObligationItem(
        code: 'EU_FOOD_GENERAL_LAW_TRACEABILITY',
        title: 'AB General Food Law Çiftlikten Çatala İzlenebilirlik (Madde 18)',
        description: 'Gıda işletmecisi ve ithalatçı, ürünün kimden alındığını ve kime satıldığını bir adım geriye ve bir adım ileriye doğru kanıtlayabilmelidir.',
        jurisdictionCode: 'EU',
        authority: 'DG SANTE',
        officialCitation: 'Regulation (EC) No 178/2002, Article 18',
        responsibleParty: 'IMPORTER',
      ),
      const LegalObligationItem(
        code: 'EU_OFFICIAL_CONTROLS_BCP',
        title: 'AB Resmi Kontroller ve Sınır Kontrol Noktası (BCP) Denetimi',
        description: 'Üçüncü ülkelerden AB’ye giriş yapan gıda sevkiyatları yetkili Sınır Kontrol Noktalarında belge, kimlik ve gerektiğinde fiziksel kontrole tabidir.',
        jurisdictionCode: 'EU',
        authority: 'DG SANTE / Customs',
        officialCitation: 'Regulation (EU) 2017/625, Articles 47-57',
        responsibleParty: 'IMPORTER',
      ),
      const LegalObligationItem(
        code: 'EU_TRACES_NT_CHED_D',
        title: 'TRACES NT Dijital Ön Bildirim ve CHED-D Giriş Belgesi',
        description: 'Hayvansal olmayan gıda sevkiyatları varıştan en az 24 saat önce TRACES NT sisteminde CHED-D belgesiyle yetkili sınır kontrol noktasına bildirilmelidir.',
        jurisdictionCode: 'EU',
        authority: 'TRACES NT / European Commission',
        officialCitation: 'Commission Implementing Regulation (EU) 2019/1715 (IMSOC)',
        responsibleParty: 'IMPORTER',
      ),
      const LegalObligationItem(
        code: 'EU_CONTAMINANTS_MRL_LIMITS',
        title: 'AB Kontaminant (Aflatoksin/Okratoksin) ve Pestisit MRL Limitleri',
        description: 'Kuru hurmada Aflatoksin B1 (maks 2.0 µg/kg), Toplam Aflatoksin (maks 4.0 µg/kg) ve AB pestisit maksimum kalıntı limitlerine (MRL) tam uyum.',
        jurisdictionCode: 'EU',
        authority: 'EFSA / DG SANTE',
        officialCitation: 'Commission Regulation (EU) 2023/915 & Regulation (EC) No 396/2005',
        responsibleParty: 'EXPORTER',
      ),
      const LegalObligationItem(
        code: 'EU_FOOD_LABELING_REG_1169',
        title: 'AB Gıda Bilgilendirme ve Etiketleme Tüzüğü (FIC)',
        description: 'Net miktar, parti/lot no, tavsiye edilen tüketim tarihi, menşe ülke, besin öğeleri tablosu ve ithalatçı adresi etikette bulunmalıdır.',
        jurisdictionCode: 'EU',
        authority: 'European Commission',
        officialCitation: 'Regulation (EU) No 1169/2011, Articles 9 & 14',
        responsibleParty: 'IMPORTER',
      ),
    ];

    // 3. Almanya Ulusal Piyasaya Arz & Ambalaj Yükümlülükleri (VerpackG, BVL, LFGB)
    final deObligations = [
      const LegalObligationItem(
        code: 'DE_VERPACKG_LUCID_REGISTRATION',
        title: 'Almanya Ambalaj Yasası (VerpackG) LUCID Sicil & Lisanslama Zorunluluğu',
        description: 'Almanya pazarına ambalajlı ürün sokan ilk ticari ithalatçı, ZSVR (LUCID) ambalaj siciline kayıtlı olmalı ve çift sistem (Dual System) geri dönüşüm lisansı almalıdır.',
        jurisdictionCode: 'DE',
        authority: 'ZSVR (Zentrale Stelle Verpackungsregister)',
        officialCitation: 'Verpackungsgesetz (VerpackG) § 9 & § 10',
        responsibleParty: 'IMPORTER',
      ),
      const LegalObligationItem(
        code: 'DE_LMIV_GERMAN_LANGUAGE_LABEL',
        title: 'Almanca Dilinde Etiketleme Zorunluluğu (LMIV / LFGB)',
        description: 'Almanya’daki perakende tüketicilere sunulacak ambalajlı gıdalarda tüm zorunlu gıda bilgileri anlaşılır Almanca dilinde basılmalıdır.',
        jurisdictionCode: 'DE',
        authority: 'BVL / Bundesministerium für Ernährung und Landwirtschaft',
        officialCitation: 'LFGB § 11 & LMIV § 2',
        responsibleParty: 'IMPORTER',
      ),
    ];

    // Gerekli Belgeler Listesi
    final requiredDocs = [
      const RequiredDocumentItem(
        documentName: 'Uluslararası Ticari Fatura (Commercial Invoice)',
        issuingAuthority: 'İhracatçı Firma (NAKHL & NAHL)',
        jurisdictionCode: 'SA',
        purpose: 'Gümrük kıymet tespiti ve TARIC tarife hesabı',
      ),
      const RequiredDocumentItem(
        documentName: 'Çeki Listesi (Packing List)',
        issuingAuthority: 'İhracatçı Firma (NAKHL & NAHL)',
        jurisdictionCode: 'SA',
        purpose: 'Koli, palet, brüt/net ağırlık kontrolü',
      ),
      const RequiredDocumentItem(
        documentName: 'Bitki Sağlık Sertifikası (Phytosanitary Certificate)',
        issuingAuthority: 'Suudi MEWA Bakanlığı',
        jurisdictionCode: 'SA',
        purpose: 'Zararlı böcek ve karantina kontrolü (IPPC formatı)',
      ),
      const RequiredDocumentItem(
        documentName: 'Menşe Şahadetnamesi (Certificate of Origin)',
        issuingAuthority: 'Riyad Ticaret Odası / Suudi Ticaret Bakanlığı',
        jurisdictionCode: 'SA',
        purpose: 'Ürünün Suudi Arabistan menşeini ispatlamak',
      ),
      const RequiredDocumentItem(
        documentName: 'CHED-D Dijital Giriş Belgesi',
        issuingAuthority: 'Alman İthalatçı / TRACES NT Sistemi',
        jurisdictionCode: 'EU',
        purpose: 'Sınır Kontrol Noktası resmi gıda kabulü',
        digitalSystem: 'TRACES NT',
      ),
      const RequiredDocumentItem(
        documentName: 'Akredite Laboratuvar Aflatoksin & Kalıntı Analiz Raporu',
        issuingAuthority: 'ISO 17025 Akredite Gıda Laboratuvarı',
        jurisdictionCode: 'SA',
        purpose: 'AB sınırında rastgele laboratuvar tutulmasını önlemek',
      ),
    ];

    final certs = <String>[
      'MEWA Bitki Sağlık Sertifikası',
      'Suudi Menşe Şahadetnamesi',
      if (profile.isHalalCertified) 'SFDA Halal Center Helal Sertifikası',
      if (profile.isOrganic) 'AB Organik Kontrol Sertifikası (COI - TRACES)',
    ];

    return CrossBorderEvaluationResult(
      sourceCountry: 'SA',
      destinationCountry: 'DE',
      productName: profile.productName,
      hsCode: profile.hsCode,
      evaluatedAt: now,
      sourceExportObligations: saExportObligations,
      supranationalObligations: euObligations,
      destinationNationalObligations: deObligations,
      requiredDocuments: requiredDocs,
      requiredCertificates: certs,
      isTracesNtRequired: true,
      tracesNtType: 'CHED-D (Bitkisel & Hayvansal Olmayan)',
      isBorderControlPostRequired: true,
      isLabAnalysisRequired: true,
      mandatoryLabelingElements: const [
        'Ürün Adı: Getrocknete Datteln (Kuru Hurma)',
        'Net Miktar (Nettofüllmenge) [g veya kg]',
        'Tavsiye Edilen Tüketim Tarihi (Mindestens haltbar bis)',
        'Menşe Ülke (Ursprungsland: Saudi-Arabien)',
        'Parti / Lot Numarası (Losnummer)',
        'Saklama Koşulları (Kühl und trocken lagern)',
        'AB İthalatçı Adı ve Adresi (Inverkehrbringer)',
        '100g Besin Değerleri Tablosu (Nährwertdeklaration)',
      ],
      packagingAndRecyclingObligations: const [
        'VerpackG LUCID Sicil Kaydı (İthalatçı)',
        'Dual System Geri Dönüşüm Lisansı (Grüner Punkt, BellandVision vb.)',
        'Gıda ile Temas Eden Materyaller Uygunluk Beyanı (Reg 1935/2004)',
      ],
      customsDutyRate: 0.0, // Hurma için AB genelinde TARIC gümrük vergisi çoğunlukla %0 veya düşük oranlıdır
      customsTariffCitation: 'EU TARIC Code 0804 10 00 (Dates, fresh or dried)',
      importVatRate: 7.0, // Almanya gıda için indirimli KDV oranı %7 (ermäßigter Steuersatz)
      isReverseChargeApplicable: false, // İthalatta gümrükte Einfuhrumsatzsteuer (EUSt) ödenir
      criticalDeadlines: const [
        'TRACES NT Ön Bildirimi: Sevkiyat AB sınırına gelmeden en az 24 saat önce girilmelidir.',
        'MEWA Bitki Sağlık Sertifikası: Yükleme tarihinden en fazla 14 gün önce düzenlenmelidir.',
        'LUCID Yıllık Ambalaj Hacim Bildirimi: Her takvim yılı başında sisteme girilmelidir.',
      ],
      riskLevel: 'LOW',
      riskAlerts: const [
        '✅ Ürün hayvansal kökenli değildir (Non-Animal Origin), bu nedenle veteriner sınır kontrolü yerine standart bitkisel kontrol uygulanır.',
        '⚠️ Aflatoksin limitleri (2 µg/kg) aşılırsa ürün sınırda imha edilir veya menşe ülkeye geri gönderilir.',
        '⚠️ Almanca etiketsiz perakende ambalajlar Almanya gıda piyasasına arz edilemez (LFGB cezası).',
      ],
      legalDisclaimer: 'Bu değerlendirme resmi ZATCA, SFDA, AB Reg 178/2002, Reg 2017/625 ve Alman VerpackG mevzuatına dayanır. Ticari sevkiyattan önce sınır kontrol noktasından teyit alınması tavsiye edilir.',
    );
  }

  // --------------------------------------------------------------------------
  // SENARYO 2: TÜRKİYE → ALMANYA / AB (GIDA İHRACATI)
  // --------------------------------------------------------------------------
  CrossBorderEvaluationResult _evaluateTurkeyToGermany(
    ProductLegalProfileModel profile,
    DateTime now,
  ) {
    final trExportObligations = [
      const LegalObligationItem(
        code: 'TR_EXP_GUMRUK_BEYANNAME',
        title: 'Türkiye Ticaret Bakanlığı İhracat Gümrük Beyannamesi',
        description: 'Gümrük Müsteşarlığı BİLGE sistemi üzerinden çıkış beyannamesi tescil edilmelidir.',
        jurisdictionCode: 'TR',
        authority: 'Ticaret Bakanlığı',
        officialCitation: '4458 Sayılı Gümrük Kanunu Madde 69-71',
        responsibleParty: 'EXPORTER',
      ),
      const LegalObligationItem(
        code: 'TR_EXP_TARIM_SAGLIK_SERTIFIKASI',
        title: 'Tarım ve Orman Bakanlığı İhracat Bitki Sağlık / Gıda Sertifikası',
        description: 'İl/İlçe Tarım Müdürlüğü denetçileri tarafından numune alınarak analiz raporu ve Bitki Sağlık Sertifikası tanzim edilir.',
        jurisdictionCode: 'TR',
        authority: 'Tarım ve Orman Bakanlığı',
        officialCitation: '5996 Sayılı Veteriner Hizmetleri, Bitki Sağlığı, Gıda ve Yem Kanunu',
        responsibleParty: 'EXPORTER',
      ),
      const LegalObligationItem(
        code: 'TR_EXP_KDV_ISTISNASI',
        title: 'GİB İhracat İstisnası (KDV %0)',
        description: 'Yurt dışına yapılan ihracatta 3065 sayılı KDV Kanunu 11/1-a uyarınca KDV tahsil edilmez.',
        jurisdictionCode: 'TR',
        authority: 'GİB',
        officialCitation: '3065 Sayılı KDV Kanunu Madde 11/1-a',
        responsibleParty: 'EXPORTER',
      ),
    ];

    final euObligations = [
      const LegalObligationItem(
        code: 'EU_FOOD_GENERAL_LAW_TRACEABILITY',
        title: 'AB General Food Law Çiftlikten Çatala İzlenebilirlik',
        description: 'Gıda güvenliği ve geriye dönük parti takibi zorunluluğu.',
        jurisdictionCode: 'EU',
        authority: 'DG SANTE',
        officialCitation: 'Regulation (EC) No 178/2002, Article 18',
        responsibleParty: 'IMPORTER',
      ),
      const LegalObligationItem(
        code: 'EU_TRACES_NT_CHED_D',
        title: 'TRACES NT Dijital Ön Bildirim',
        description: 'CHED-D belgesi ile 24 saat önceden sınır kontrol noktasına bildirim.',
        jurisdictionCode: 'EU',
        authority: 'TRACES NT',
        officialCitation: 'Implementing Regulation (EU) 2019/1715',
        responsibleParty: 'IMPORTER',
      ),
    ];

    final deObligations = [
      const LegalObligationItem(
        code: 'DE_VERPACKG_LUCID',
        title: 'Almanya Ambalaj Yasası (VerpackG) LUCID Kaydı',
        description: 'Almanya pazarına arz edilen ambalajların lisanslanması.',
        jurisdictionCode: 'DE',
        authority: 'ZSVR',
        officialCitation: 'VerpackG § 9',
        responsibleParty: 'IMPORTER',
      ),
      const LegalObligationItem(
        code: 'DE_LMIV_LABEL',
        title: 'Almanca Dilinde Etiketleme',
        description: 'Zorunlu etiket bilgilerinin Almanca olarak basılması.',
        jurisdictionCode: 'DE',
        authority: 'BVL',
        officialCitation: 'LMIV / LFGB',
        responsibleParty: 'IMPORTER',
      ),
    ];

    return CrossBorderEvaluationResult(
      sourceCountry: 'TR',
      destinationCountry: 'DE',
      productName: profile.productName,
      hsCode: profile.hsCode,
      evaluatedAt: now,
      sourceExportObligations: trExportObligations,
      supranationalObligations: euObligations,
      destinationNationalObligations: deObligations,
      requiredDocuments: [
        const RequiredDocumentItem(
          documentName: 'E-İhracat Faturası (GİB Onaylı UBL-XML)',
          issuingAuthority: 'NAKHL & NAHL Türkiye / GİB',
          jurisdictionCode: 'TR',
          purpose: 'İhracat gümrük tescili ve vergi istisnası',
          digitalSystem: 'GİB',
        ),
        const RequiredDocumentItem(
          documentName: 'A.TR Dolaşım Belgesi / Menşe Şahadetnamesi',
          issuingAuthority: 'Türkiye Ticaret Odası / Gümrük',
          jurisdictionCode: 'TR',
          purpose: 'Gümrük birliği tercihli tarife veya menşe tespiti',
        ),
        const RequiredDocumentItem(
          documentName: 'Tarım Bakanlığı Bitki Sağlık Sertifikası',
          issuingAuthority: 'Tarım ve Orman Bakanlığı',
          jurisdictionCode: 'TR',
          purpose: 'Karantina ve bitki sağlığı uygunluğu',
        ),
      ],
      requiredCertificates: const [
        'Bitki Sağlık Sertifikası',
        'A.TR / Menşe İspat Belgesi',
      ],
      isTracesNtRequired: true,
      tracesNtType: 'CHED-D',
      isBorderControlPostRequired: true,
      isLabAnalysisRequired: false,
      mandatoryLabelingElements: const [
        'Almanca Ürün Adı',
        'Net Ağırlık',
        'Tüketim Tarihi',
        'Almanya İthalatçı Adresi',
        'Menşe: Türkei',
        'Besin Tablosu',
      ],
      packagingAndRecyclingObligations: const [
        'LUCID Sicil Kaydı',
        'Dual System Geri Dönüşüm Lisansı',
      ],
      customsDutyRate: 0.0,
      customsTariffCitation: 'TR-EU Gümrük Birliği & Tarım Tercihli Rejimi',
      importVatRate: 7.0, // Almanya gıda KDV
      isReverseChargeApplicable: false,
      criticalDeadlines: const [
        'TRACES NT Bildirimi: 24 saat önceden',
        'GİB İhracat Kapanış Beyanı: 180 gün içinde döviz getirme şartı (İBKB)',
      ],
      riskLevel: 'LOW',
      riskAlerts: const [
        '✅ Türkiye çıkışında e-İhracat faturası gümrük sistemine otomatik bağlanır.',
        '⚠️ Türk menşeli kurutulmuş ürünlerde pestisit denetimleri sıkılaştırılmış olabilir.',
      ],
      legalDisclaimer: 'GİB, Türkiye Ticaret Bakanlığı ve AB Gıda İthalat Tüzüklerine uygundur.',
    );
  }

  // --------------------------------------------------------------------------
  // SENARYO 3: SUUDİ ARABİSTAN → TÜRKİYE (İTHALAT)
  // --------------------------------------------------------------------------
  CrossBorderEvaluationResult _evaluateSaudiToTurkey(
    ProductLegalProfileModel profile,
    DateTime now,
  ) {
    final saExport = [
      const LegalObligationItem(
        code: 'SA_EXP_FASAH',
        title: 'ZATCA Fasah Çıkış Beyannamesi',
        description: 'Suudi gümrüğünden resmi çıkış onayı.',
        jurisdictionCode: 'SA',
        authority: 'ZATCA',
        officialCitation: 'Saudi Customs Law',
        responsibleParty: 'EXPORTER',
      ),
      const LegalObligationItem(
        code: 'SA_EXP_ORIGIN',
        title: 'Suudi Menşe Şahadetnamesi',
        description: 'Ticaret Odası tasdikli resmi menşe belgesi.',
        jurisdictionCode: 'SA',
        authority: 'MOC',
        officialCitation: 'GCC Rules of Origin',
        responsibleParty: 'EXPORTER',
      ),
    ];

    final trImport = [
      const LegalObligationItem(
        code: 'TR_IMP_TARIM_KONTROL',
        title: 'Tarım ve Orman Bakanlığı İthalat Uygunluk Belgesi',
        description: 'Gıda maddelerinin Türkiye gümrük bölgesine girişinde Tarım Bakanlığı denetimi ve analizi zorunludur.',
        jurisdictionCode: 'TR',
        authority: 'Tarım ve Orman Bakanlığı',
        officialCitation: '5996 Sayılı Kanun & Gıda İthalatı Tebliği',
        responsibleParty: 'IMPORTER',
      ),
      const LegalObligationItem(
        code: 'TR_IMP_TURKCE_ETIKET',
        title: 'Türk Gıda Kodeksi Türkçe Etiketleme Şartı',
        description: 'Gıdanın adı, içindekiler, net miktar, parti no, menşe ülke Türkçe basılmalıdır.',
        jurisdictionCode: 'TR',
        authority: 'Tarım ve Orman Bakanlığı',
        officialCitation: 'Türk Gıda Kodeksi Gıda Etiketleme Yönetmeliği',
        responsibleParty: 'IMPORTER',
      ),
      const LegalObligationItem(
        code: 'TR_IMP_KDV_ORANI',
        title: 'İthalatta KDV Oranı (%1 Toptan Hurma / %10 Perakende)',
        description: 'Kuru hurmanın toptan tesliminde %1, perakende satışında %10 KDV uygulanır.',
        jurisdictionCode: 'TR',
        authority: 'GİB',
        officialCitation: '2007/13033 Sayılı BKK / KDV Oran Listesi I-A',
        responsibleParty: 'IMPORTER',
      ),
    ];

    return CrossBorderEvaluationResult(
      sourceCountry: 'SA',
      destinationCountry: 'TR',
      productName: profile.productName,
      hsCode: profile.hsCode,
      evaluatedAt: now,
      sourceExportObligations: saExport,
      supranationalObligations: const [],
      destinationNationalObligations: trImport,
      requiredDocuments: const [
        RequiredDocumentItem(
          documentName: 'Orijinal Fatura & Çeki Listesi',
          issuingAuthority: 'Suudi İhracatçı',
          jurisdictionCode: 'SA',
          purpose: 'Gümrük beyanı',
        ),
        RequiredDocumentItem(
          documentName: 'MEWA Bitki Sağlık Sertifikası (Phytosanitary)',
          issuingAuthority: 'Suudi MEWA',
          jurisdictionCode: 'SA',
          purpose: 'Tarım Bakanlığı zirai karantina onayı',
        ),
        RequiredDocumentItem(
          documentName: 'Apostil veya Konsolosluk Tasdikli Menşe Belgesi',
          issuingAuthority: 'Suudi Ticaret Odası',
          jurisdictionCode: 'SA',
          purpose: 'Menşe ispatı',
        ),
      ],
      requiredCertificates: const [
        'MEWA Bitki Sağlık Sertifikası',
        'Suudi Menşe Şahadetnamesi',
      ],
      isTracesNtRequired: false,
      tracesNtType: 'YOK (AB Dışı)',
      isBorderControlPostRequired: true,
      isLabAnalysisRequired: true,
      mandatoryLabelingElements: const [
        'Türkçe Ürün Adı (Kuru Hurma)',
        'Net Miktar (g/kg)',
        'İçindekiler Listesi',
        'Tavsiye Edilen Tüketim Tarihi (TETT)',
        'Menşe Ülke: Suudi Arabistan',
        'İthalatçı Firma Ünvanı ve Adresi',
      ],
      packagingAndRecyclingObligations: const [
        'Gıda ile Temas Eden Madde ve Malzemeler Yönetmeliği (TGK)',
        'Sıfır Atık / Geri Kazanım Katılım Payı (GEKAP)',
      ],
      customsDutyRate: 0.0, // Hurma genellikle Türkiye İthalat Rejiminde özel/düşük korumadadır
      customsTariffCitation: 'Türk Gümrük Tarife Cetveli 0804.10.00.00.00',
      importVatRate: 1.0, // Toptan hurma %1 KDV
      isReverseChargeApplicable: false,
      criticalDeadlines: const [
        'Tarım Bakanlığı Ön Başvuru: E-Devlet üzerinden gümrüğe varıştan önce yapılmalıdır.',
      ],
      riskLevel: 'LOW',
      riskAlerts: const [
        '⚠️ Türkiye gümrüğünde Tarım Bakanlığı numune alıp analiz yapmadan ithalat tamamlanamaz.',
      ],
      legalDisclaimer: 'GİB ve Tarım ve Orman Bakanlığı resmi ithalat mevzuatına uygundur.',
    );
  }

  // --------------------------------------------------------------------------
  // SENARYO 4: TÜRKİYE → SUUDİ ARABİSTAN (İTHALAT)
  // --------------------------------------------------------------------------
  CrossBorderEvaluationResult _evaluateTurkeyToSaudi(
    ProductLegalProfileModel profile,
    DateTime now,
  ) {
    final trExport = [
      const LegalObligationItem(
        code: 'TR_EXP_GUMRUK',
        title: 'GİB & Ticaret Bakanlığı İhracat Beyannamesi',
        description: 'Gümrük çıkış beyanı.',
        jurisdictionCode: 'TR',
        authority: 'Ticaret Bakanlığı',
        officialCitation: 'Gümrük Kanunu',
        responsibleParty: 'EXPORTER',
      ),
    ];

    final saImport = [
      const LegalObligationItem(
        code: 'SA_IMP_SFDA_FRS_REGISTRATION',
        title: 'SFDA Gıda Kayıt Sistemi (FRS) Barkod ve Ürün Kaydı',
        description: 'Suudi Arabistan’a ithal edilecek her gıda ambalajının SFDA elektronik sisteminde önceden kayıtlı ve onaylı olması şarttır.',
        jurisdictionCode: 'SA',
        authority: 'SFDA',
        officialCitation: 'SFDA Imported Food Control Regulations 2023',
        responsibleParty: 'IMPORTER',
      ),
      const LegalObligationItem(
        code: 'SA_IMP_HALAL_CENTER_APPROVAL',
        title: 'SFDA Helal Merkezi Onaylı Helal Sertifikası',
        description: 'İthal edilecek ürünlerin SFDA tarafından akredite edilmiş helal belgelendirme kuruluşundan sertifikalandırılması gereklidir.',
        jurisdictionCode: 'SA',
        authority: 'SFDA Halal Center',
        officialCitation: 'GSO 2055-1 / SFDA Halal Regulations',
        responsibleParty: 'EXPORTER',
      ),
      const LegalObligationItem(
        code: 'SA_IMP_VAT_STANDARD_15',
        title: 'ZATCA Standart İthalat KDV Oranı (%15)',
        description: 'İthal edilen gıda ürünlerinde CIF bedel ve gümrük vergisi üzerinden %15 KDV tahsil edilir.',
        jurisdictionCode: 'SA',
        authority: 'ZATCA',
        officialCitation: 'Saudi VAT Law 2020, Art. 5',
        responsibleParty: 'IMPORTER',
      ),
    ];

    return CrossBorderEvaluationResult(
      sourceCountry: 'TR',
      destinationCountry: 'SA',
      productName: profile.productName,
      hsCode: profile.hsCode,
      evaluatedAt: now,
      sourceExportObligations: trExport,
      supranationalObligations: const [],
      destinationNationalObligations: saImport,
      requiredDocuments: const [
        RequiredDocumentItem(
          documentName: 'Ticari Fatura & Çeki Listesi',
          issuingAuthority: 'Türk İhracatçı',
          jurisdictionCode: 'TR',
          purpose: 'ZATCA gümrük kıymet tespiti',
        ),
        RequiredDocumentItem(
          documentName: 'SFDA Onaylı FRS Ürün Kayıt Belgesi',
          issuingAuthority: 'SFDA',
          jurisdictionCode: 'SA',
          purpose: 'Gıda ithalat izni',
        ),
        RequiredDocumentItem(
          documentName: 'Akredite Helal Sertifikası',
          issuingAuthority: 'SFDA Akredite Helal Kuruluşu / HAK',
          jurisdictionCode: 'TR',
          purpose: 'Helal gıda güvencesi',
        ),
        RequiredDocumentItem(
          documentName: 'Bitki Sağlık / İhracat Sağlık Sertifikası',
          issuingAuthority: 'Tarım ve Orman Bakanlığı',
          jurisdictionCode: 'TR',
          purpose: 'Sağlık denetimi',
        ),
      ],
      requiredCertificates: const [
        'SFDA Akredite Helal Sertifikası',
        'Tarım Bakanlığı Bitki Sağlık Sertifikası',
      ],
      isTracesNtRequired: false,
      tracesNtType: 'YOK (Fasah Kullanılır)',
      isBorderControlPostRequired: true,
      isLabAnalysisRequired: true,
      mandatoryLabelingElements: const [
        'Arapça Ürün Adı',
        'Üretim ve Son Kullanma Tarihi (Hicri/Miladi)',
        'Net Ağırlık',
        'İçindekiler Listesi',
        'Menşe Ülke: Türkiye',
        'Suudi İthalatçı Lisans Bilgileri',
      ],
      packagingAndRecyclingObligations: const [
        'SASO Gıda Ambalajı Standartları (GSO 839)',
      ],
      customsDutyRate: 5.0, // GCC Birleşik Gümrük Tarifesi standardı genelde %5
      customsTariffCitation: 'GCC Common External Tariff (CET) 12-digit level',
      importVatRate: 15.0, // Suudi KDV %15
      isReverseChargeApplicable: false,
      criticalDeadlines: const [
        'Fasah İthalat Ön Beyanı: Sevkiyat limana varmadan önce girilmelidir.',
      ],
      riskLevel: 'LOW',
      riskAlerts: const [
        '⚠️ SFDA kaydı olmayan gıda ürünleri Suudi gümrüğünde Fasah sisteminden geçemez ve limanda bloke edilir.',
        '⚠️ Arapça etiketleme eksikliği durumunda cezai işlem ve etiketleme düzeltme maliyeti doğar.',
      ],
      legalDisclaimer: 'ZATCA ve SFDA resmi ithalat standartlarına uygundur.',
    );
  }

  // --------------------------------------------------------------------------
  // DURUM: BOŞ RAF (NOT_LOADED) FALLBACK
  // --------------------------------------------------------------------------
  CrossBorderEvaluationResult _buildEmptyShelfResult(
    ProductLegalProfileModel profile,
    DateTime now,
  ) {
    return CrossBorderEvaluationResult(
      sourceCountry: profile.sourceCountry,
      destinationCountry: profile.destinationCountry,
      productName: profile.productName,
      hsCode: profile.hsCode,
      evaluatedAt: now,
      sourceExportObligations: const [],
      supranationalObligations: const [],
      destinationNationalObligations: const [],
      requiredDocuments: const [],
      requiredCertificates: const [],
      isTracesNtRequired: false,
      tracesNtType: 'HENÜZ YÜKLENMEDİ',
      isBorderControlPostRequired: false,
      isLabAnalysisRequired: false,
      mandatoryLabelingElements: const [],
      packagingAndRecyclingObligations: const [],
      customsDutyRate: 0.0,
      customsTariffCitation: 'NOT_LOADED',
      importVatRate: 0.0,
      isReverseChargeApplicable: false,
      criticalDeadlines: const [],
      riskLevel: 'HIGH',
      riskAlerts: [
        '⚠️ Hedef Ülke ("${profile.destinationCountry}") Mevzuat Rafı HENÜZ YÜKLENMEMİŞTİR (Status: NOT_LOADED).',
        '💡 Sistem prensibi: "Dünyanın bütün mevzuatını baştan doldurma; ihtiyaç kadarını doldur, diğerlerini boş raf olarak hazırla."',
        '🚀 Bu ülkeye ihracat kararı alındığında "Legal Discovery Workflow" tetiklenerek yalnızca gerekli resmi kaynaklar (Gıda/Gümrük/Vergi) taranmalı ve insan incelemesi (Human Legal Review) ile aktive edilmelidir.',
      ],
      legalDisclaimer: 'Bu ülke için aktif mevzuat kuralı bulunmamaktadır. AI tarafından bağlayıcı olmayan tahmin veya farazi kural üretilmesi yasaktır.',
      isShelfEmpty: true,
    );
  }

  // --------------------------------------------------------------------------
  // DURUM: BİLİNMEYEN ROTA
  // --------------------------------------------------------------------------
  CrossBorderEvaluationResult _buildUnknownRouteResult(
    ProductLegalProfileModel profile,
    DateTime now,
  ) {
    return CrossBorderEvaluationResult(
      sourceCountry: profile.sourceCountry,
      destinationCountry: profile.destinationCountry,
      productName: profile.productName,
      hsCode: profile.hsCode,
      evaluatedAt: now,
      sourceExportObligations: const [],
      supranationalObligations: const [],
      destinationNationalObligations: const [],
      requiredDocuments: const [],
      requiredCertificates: const [],
      isTracesNtRequired: false,
      tracesNtType: 'BİLİNMİYOR',
      isBorderControlPostRequired: false,
      isLabAnalysisRequired: false,
      mandatoryLabelingElements: const [],
      packagingAndRecyclingObligations: const [],
      customsDutyRate: 0.0,
      customsTariffCitation: 'UNKNOWN',
      importVatRate: 0.0,
      isReverseChargeApplicable: false,
      criticalDeadlines: const [],
      riskLevel: 'MEDIUM',
      riskAlerts: [
        '⚠️ Bu rota için henüz tanımlanmış çapraz sınır kural seti bulunmamaktadır.',
      ],
      legalDisclaimer: 'UNKNOWN: Resmi kaynak teyidi beklenmektedir.',
    );
  }
}
