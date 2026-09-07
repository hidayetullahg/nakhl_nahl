// ==============================================================================
// NAKHL & NAHL — COMMERCIAL MODULE CATALOG SERVICE
// File: lib/services/billing/module_catalog_service.dart
// Decoupled brand-independent SaaS module catalog and multi-currency pricing
// ==============================================================================

import '../supabase_service.dart';

/// Modül Kategorileri
enum ModuleCategory {
  core('CORE', 'Temel Altyapı'),
  finance('FINANCE', 'Finans & Muhasebe'),
  operations('OPERATIONS', 'Operasyon & Stok'),
  retail('RETAIL', 'Perakende & Satış Noktası'),
  compliance('COMPLIANCE', 'E-Dönüşüm & Mevzuat'),
  migration('MIGRATION', 'Veri Aktarımı & Taşıma'),
  service('SERVICE', 'Profesyonel Hizmetler'),
  analytics('ANALYTICS', 'Raporlama & Analitik'),
  ai('AI', 'Yapay Zekâ & OCR'),
  global('GLOBAL', 'Uluslararası Ticaret'),
  special('SPECIAL', 'Sektörel Özel Çözümler'),
  storage('STORAGE', 'Belge & Doküman'),
  enterprise('ENTERPRISE', 'Kurumsal & Konsolidasyon'),
  developer('DEVELOPER', 'Geliştirici & Entegrasyon');

  final String code;
  final String label;
  const ModuleCategory(this.code, this.label);

  static ModuleCategory fromCode(String code) {
    return ModuleCategory.values.firstWhere(
      (c) => c.code.toUpperCase() == code.toUpperCase(),
      orElse: () => ModuleCategory.core,
    );
  }
}

/// Ticari Satılabilir ERP Modeli
class CommercialModule {
  final String code;
  final String name;
  final String? description;
  final ModuleCategory category;
  final bool isCore;
  final bool isAddon;
  final bool requiresSetup;
  final int displayOrder;
  final List<String> dependencies;
  final List<String> features;
  final Map<String, ModulePricing> pricing; // Currency -> Pricing

  const CommercialModule({
    required this.code,
    required this.name,
    this.description,
    required this.category,
    this.isCore = false,
    this.isAddon = false,
    this.requiresSetup = false,
    this.displayOrder = 0,
    this.dependencies = const [],
    this.features = const [],
    this.pricing = const {},
  });

  factory CommercialModule.fromMap(Map<String, dynamic> map,
      {List<ModulePricing> pricingList = const []}) {
    final pricingMap = <String, ModulePricing>{};
    for (final p in pricingList) {
      if (p.moduleCode == map['code']) {
        pricingMap[p.currency] = p;
      }
    }

    final rawDeps = map['dependencies'];
    final List<String> deps = rawDeps is List
        ? rawDeps.map((e) => e.toString()).toList()
        : const [];

    final rawFeatures = map['features'];
    final List<String> feats = rawFeatures is List
        ? rawFeatures.map((e) => e.toString()).toList()
        : const [];

    return CommercialModule(
      code: map['code']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString(),
      category: ModuleCategory.fromCode(map['category']?.toString() ?? 'CORE'),
      isCore: map['is_core'] == true,
      isAddon: map['is_addon'] == true,
      requiresSetup: map['requires_setup'] == true,
      displayOrder: (map['display_order'] as num?)?.toInt() ?? 0,
      dependencies: deps,
      features: feats,
      pricing: pricingMap,
    );
  }

  ModulePricing? getPricing(String currency) => pricing[currency.toUpperCase()];
}

/// Modül Fiyatlandırma Modeli
class ModulePricing {
  final String moduleCode;
  final String currency;
  final double monthlyPrice;
  final double yearlyPrice;
  final double setupPrice;
  final double trainingPrice;
  final double dataMigrationPrice;

  const ModulePricing({
    required this.moduleCode,
    required this.currency,
    this.monthlyPrice = 0.0,
    this.yearlyPrice = 0.0,
    this.setupPrice = 0.0,
    this.trainingPrice = 0.0,
    this.dataMigrationPrice = 0.0,
  });

  factory ModulePricing.fromMap(Map<String, dynamic> map) {
    return ModulePricing(
      moduleCode: map['module_code']?.toString() ?? '',
      currency: map['currency']?.toString().toUpperCase() ?? 'SAR',
      monthlyPrice: (map['monthly_price'] as num?)?.toDouble() ?? 0.0,
      yearlyPrice: (map['yearly_price'] as num?)?.toDouble() ?? 0.0,
      setupPrice: (map['setup_price'] as num?)?.toDouble() ?? 0.0,
      trainingPrice: (map['training_price'] as num?)?.toDouble() ?? 0.0,
      dataMigrationPrice:
          (map['data_migration_price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Modül Kataloğu Servisi
class ModuleCatalogService {
  ModuleCatalogService._();
  static final ModuleCatalogService instance = ModuleCatalogService._();

  List<CommercialModule> _cachedModules = [];
  bool _isInitialized = false;

  /// Katalog Listesini Getir
  Future<List<CommercialModule>> getCatalog(
      {bool forceRefresh = false, String activeCurrency = 'SAR'}) async {
    if (_isInitialized && !forceRefresh && _cachedModules.isNotEmpty) {
      return _cachedModules;
    }

    try {
      final client = SupabaseService.client;
      final modRows = await client
          .from('commercial_modules')
          .select()
          .order('display_order', ascending: true);

      final priceRows = await client.from('commercial_module_pricing').select();

      final pricingList = (priceRows as List)
          .map((p) => ModulePricing.fromMap(p as Map<String, dynamic>))
          .toList();

      _cachedModules = (modRows as List).map((m) {
        return CommercialModule.fromMap(
          m as Map<String, dynamic>,
          pricingList: pricingList,
        );
      }).toList();

      _isInitialized = true;
      return _cachedModules;
    } catch (_) {
      // Fallback hardcoded catalog for offline or test environments
      _cachedModules = _getFallbackCatalog();
      _isInitialized = true;
      return _cachedModules;
    }
  }

  /// Tek Bir Modülü Kodu ile Getir
  Future<CommercialModule?> getModule(String code) async {
    final catalog = await getCatalog();
    try {
      return catalog.firstWhere((m) => m.code == code);
    } catch (_) {
      return null;
    }
  }

  /// Modül Bağımlılık Kontrolü
  List<String> checkMissingDependencies(
      CommercialModule module, List<String> activeModuleCodes) {
    final missing = <String>[];
    for (final dep in module.dependencies) {
      if (!activeModuleCodes.contains(dep)) {
        missing.add(dep);
      }
    }
    return missing;
  }

  /// Offline / Test Ortamı İçin Sabit Katalog
  List<CommercialModule> _getFallbackCatalog() {
    return [
      CommercialModule(
        code: 'MOD_CORE',
        name: 'Temel ERP & Multi-Tenant',
        description: 'Sistem omurgası, çoklu şirket ve kullanıcı yönetimi',
        category: ModuleCategory.core,
        isCore: true,
        displayOrder: 1,
        pricing: {
          'SAR': const ModulePricing(moduleCode: 'MOD_CORE', currency: 'SAR'),
          'TRY': const ModulePricing(moduleCode: 'MOD_CORE', currency: 'TRY'),
        },
      ),
      CommercialModule(
        code: 'MOD_ACCOUNTING',
        name: 'Genel Muhasebe & Finans',
        description: 'Tek düzen hesap planı, yevmiye defteri, mizan ve bilanço',
        category: ModuleCategory.finance,
        displayOrder: 2,
        pricing: {
          'SAR': const ModulePricing(
              moduleCode: 'MOD_ACCOUNTING',
              currency: 'SAR',
              monthlyPrice: 150.0,
              yearlyPrice: 1500.0),
          'TRY': const ModulePricing(
              moduleCode: 'MOD_ACCOUNTING',
              currency: 'TRY',
              monthlyPrice: 1250.0,
              yearlyPrice: 12500.0),
        },
      ),
      CommercialModule(
        code: 'MOD_INVENTORY',
        name: 'Stok & Depo Yönetimi',
        description: 'Çoklu depo, parti/lot takibi ve stok hareket defteri',
        category: ModuleCategory.operations,
        displayOrder: 3,
        pricing: {
          'SAR': const ModulePricing(
              moduleCode: 'MOD_INVENTORY',
              currency: 'SAR',
              monthlyPrice: 120.0,
              yearlyPrice: 1200.0),
          'TRY': const ModulePricing(
              moduleCode: 'MOD_INVENTORY',
              currency: 'TRY',
              monthlyPrice: 1000.0,
              yearlyPrice: 10000.0),
        },
      ),
      CommercialModule(
        code: 'MOD_SALES',
        name: 'Satış & Müşteri İlişkileri',
        description: 'Teklif, sipariş, irsaliye ve cari alacak yönetimi',
        category: ModuleCategory.operations,
        displayOrder: 4,
        dependencies: const ['MOD_INVENTORY'],
        pricing: {
          'SAR': const ModulePricing(
              moduleCode: 'MOD_SALES',
              currency: 'SAR',
              monthlyPrice: 100.0,
              yearlyPrice: 1000.0),
          'TRY': const ModulePricing(
              moduleCode: 'MOD_SALES',
              currency: 'TRY',
              monthlyPrice: 850.0,
              yearlyPrice: 8500.0),
        },
      ),
      CommercialModule(
        code: 'MOD_PURCHASE',
        name: 'Satın Alma & Tedarikçi',
        description: 'Tedarikçi siparişleri, mal kabul ve borç takibi',
        category: ModuleCategory.operations,
        displayOrder: 5,
        dependencies: const ['MOD_INVENTORY'],
        pricing: {
          'SAR': const ModulePricing(
              moduleCode: 'MOD_PURCHASE',
              currency: 'SAR',
              monthlyPrice: 100.0,
              yearlyPrice: 1000.0),
          'TRY': const ModulePricing(
              moduleCode: 'MOD_PURCHASE',
              currency: 'TRY',
              monthlyPrice: 850.0,
              yearlyPrice: 8500.0),
        },
      ),
      CommercialModule(
        code: 'MOD_POS',
        name: 'Hızlı Satış POS & Perakende',
        description: 'Barkodlu hızlı kasa, nakit/kredi kartı tahsilat',
        category: ModuleCategory.retail,
        displayOrder: 6,
        pricing: {
          'SAR': const ModulePricing(
              moduleCode: 'MOD_POS',
              currency: 'SAR',
              monthlyPrice: 80.0,
              yearlyPrice: 800.0),
          'TRY': const ModulePricing(
              moduleCode: 'MOD_POS',
              currency: 'TRY',
              monthlyPrice: 700.0,
              yearlyPrice: 7000.0),
        },
      ),
      CommercialModule(
        code: 'MOD_EINVOICE_TR',
        name: 'Türkiye E-Fatura & GİB',
        description: 'GİB e-Fatura, e-Arşiv, e-İrsaliye entegrasyonu',
        category: ModuleCategory.compliance,
        isAddon: true,
        displayOrder: 7,
        dependencies: const ['MOD_ACCOUNTING'],
        pricing: {
          'SAR': const ModulePricing(
              moduleCode: 'MOD_EINVOICE_TR',
              currency: 'SAR',
              monthlyPrice: 100.0,
              yearlyPrice: 1000.0),
          'TRY': const ModulePricing(
              moduleCode: 'MOD_EINVOICE_TR',
              currency: 'TRY',
              monthlyPrice: 750.0,
              yearlyPrice: 7500.0),
        },
      ),
      CommercialModule(
        code: 'MOD_ZATCA_SA',
        name: 'Suudi Arabistan ZATCA Fatoora',
        description: 'Faz-2 entegrasyonu, QR kod, CSID ve XML doğrulama',
        category: ModuleCategory.compliance,
        isAddon: true,
        displayOrder: 8,
        dependencies: const ['MOD_ACCOUNTING'],
        pricing: {
          'SAR': const ModulePricing(
              moduleCode: 'MOD_ZATCA_SA',
              currency: 'SAR',
              monthlyPrice: 150.0,
              yearlyPrice: 1500.0),
          'TRY': const ModulePricing(
              moduleCode: 'MOD_ZATCA_SA',
              currency: 'TRY',
              monthlyPrice: 1250.0,
              yearlyPrice: 12500.0),
        },
      ),
      CommercialModule(
        code: 'MOD_DATA_MIGRATION',
        name: 'Veri Aktarımı & Geçiş Sihirbazı',
        description:
            'Excel/Logo/Mikro/Netsis/SAP aktarım, eşleme ve denetimli yükleme',
        category: ModuleCategory.migration,
        isAddon: true,
        displayOrder: 9,
        pricing: {
          'SAR': const ModulePricing(
              moduleCode: 'MOD_DATA_MIGRATION',
              currency: 'SAR',
              dataMigrationPrice: 500.0),
          'TRY': const ModulePricing(
              moduleCode: 'MOD_DATA_MIGRATION',
              currency: 'TRY',
              dataMigrationPrice: 4000.0),
        },
      ),
      CommercialModule(
        code: 'MOD_INITIAL_SETUP',
        name: 'İlk Kurulum & Yapılandırma Hizmeti',
        description:
            'Uzman danışman eşliğinde hesap planı, depo ve şirket kurulumu',
        category: ModuleCategory.service,
        isAddon: true,
        requiresSetup: true,
        displayOrder: 10,
        pricing: {
          'SAR': const ModulePricing(
              moduleCode: 'MOD_INITIAL_SETUP',
              currency: 'SAR',
              setupPrice: 1000.0),
          'TRY': const ModulePricing(
              moduleCode: 'MOD_INITIAL_SETUP',
              currency: 'TRY',
              setupPrice: 8000.0),
        },
      ),
      CommercialModule(
        code: 'MOD_TRAINING',
        name: 'Kullanıcı & Personel Eğitimi',
        description: 'Birebir canlı online eğitim ve sertifikasyon paketi',
        category: ModuleCategory.service,
        isAddon: true,
        displayOrder: 11,
        pricing: {
          'SAR': const ModulePricing(
              moduleCode: 'MOD_TRAINING',
              currency: 'SAR',
              trainingPrice: 800.0),
          'TRY': const ModulePricing(
              moduleCode: 'MOD_TRAINING',
              currency: 'TRY',
              trainingPrice: 6500.0),
        },
      ),
      CommercialModule(
        code: 'MOD_REPORTING_ADV',
        name: 'Gelişmiş Raporlama & BI Analitik',
        description:
            'Özelleştirilebilir pivot tablolar, grafikler ve finansal analiz',
        category: ModuleCategory.analytics,
        displayOrder: 12,
        pricing: {
          'SAR': const ModulePricing(
              moduleCode: 'MOD_REPORTING_ADV',
              currency: 'SAR',
              monthlyPrice: 100.0,
              yearlyPrice: 1000.0),
          'TRY': const ModulePricing(
              moduleCode: 'MOD_REPORTING_ADV',
              currency: 'TRY',
              monthlyPrice: 850.0,
              yearlyPrice: 8500.0),
        },
      ),
      CommercialModule(
        code: 'MOD_AI_OCR',
        name: 'Yapay Zekâ & Akıllı Belge OCR',
        description:
            'Fatura ve fişleri otomatik tarama, metin okuma ve yevmiye kaydı',
        category: ModuleCategory.ai,
        displayOrder: 13,
        pricing: {
          'SAR': const ModulePricing(
              moduleCode: 'MOD_AI_OCR',
              currency: 'SAR',
              monthlyPrice: 150.0,
              yearlyPrice: 1500.0),
          'TRY': const ModulePricing(
              moduleCode: 'MOD_AI_OCR',
              currency: 'TRY',
              monthlyPrice: 1250.0,
              yearlyPrice: 12500.0),
        },
      ),
      CommercialModule(
        code: 'MOD_LOGISTICS_EXPORT',
        name: 'Uluslararası Ticaret & İhracat Lojistiği',
        description: 'Gümrük, konteyner takibi ve ihracat evrakları',
        category: ModuleCategory.global,
        displayOrder: 14,
        pricing: {
          'SAR': const ModulePricing(
              moduleCode: 'MOD_LOGISTICS_EXPORT',
              currency: 'SAR',
              monthlyPrice: 120.0,
              yearlyPrice: 1200.0),
          'TRY': const ModulePricing(
              moduleCode: 'MOD_LOGISTICS_EXPORT',
              currency: 'TRY',
              monthlyPrice: 1000.0,
              yearlyPrice: 10000.0),
        },
      ),
      CommercialModule(
        code: 'MOD_AGRICULTURE',
        name: 'Tarım & Hurma Bahçesi Yönetimi',
        description: 'Ağaç başına rekolte, hasat ve zirai bakım takibi',
        category: ModuleCategory.special,
        displayOrder: 15,
        pricing: {
          'SAR': const ModulePricing(
              moduleCode: 'MOD_AGRICULTURE',
              currency: 'SAR',
              monthlyPrice: 100.0,
              yearlyPrice: 1000.0),
          'TRY': const ModulePricing(
              moduleCode: 'MOD_AGRICULTURE',
              currency: 'TRY',
              monthlyPrice: 800.0,
              yearlyPrice: 8000.0),
        },
      ),
      CommercialModule(
        code: 'MOD_DOC_MANAGEMENT',
        name: 'Doküman Yönetimi & Arşivleme',
        description: 'Bulut dosya saklama, versiyonlama ve erişim izinleri',
        category: ModuleCategory.storage,
        displayOrder: 16,
        pricing: {
          'SAR': const ModulePricing(
              moduleCode: 'MOD_DOC_MANAGEMENT',
              currency: 'SAR',
              monthlyPrice: 80.0,
              yearlyPrice: 800.0),
          'TRY': const ModulePricing(
              moduleCode: 'MOD_DOC_MANAGEMENT',
              currency: 'TRY',
              monthlyPrice: 650.0,
              yearlyPrice: 6500.0),
        },
      ),
      CommercialModule(
        code: 'MOD_INTERCOMPANY',
        name: 'Grup Şirketleri & Konsolidasyon',
        description:
            'Grup içi faturalaşma, çapraz şirket transferi ve konsolide mizan',
        category: ModuleCategory.enterprise,
        displayOrder: 17,
        pricing: {
          'SAR': const ModulePricing(
              moduleCode: 'MOD_INTERCOMPANY',
              currency: 'SAR',
              monthlyPrice: 200.0,
              yearlyPrice: 2000.0),
          'TRY': const ModulePricing(
              moduleCode: 'MOD_INTERCOMPANY',
              currency: 'TRY',
              monthlyPrice: 1700.0,
              yearlyPrice: 17000.0),
        },
      ),
      CommercialModule(
        code: 'MOD_API_INTEGRATION',
        name: 'Açık API & Webhook Entegrasyon Portalı',
        description:
            'Harici yazılımlar ve e-ticaret siteleri için REST API erişimi',
        category: ModuleCategory.developer,
        displayOrder: 18,
        pricing: {
          'SAR': const ModulePricing(
              moduleCode: 'MOD_API_INTEGRATION',
              currency: 'SAR',
              monthlyPrice: 150.0,
              yearlyPrice: 1500.0),
          'TRY': const ModulePricing(
              moduleCode: 'MOD_API_INTEGRATION',
              currency: 'TRY',
              monthlyPrice: 1200.0,
              yearlyPrice: 12000.0),
        },
      ),
    ];
  }
}
