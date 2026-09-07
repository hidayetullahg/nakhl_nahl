import 'supabase_service.dart';
import '../models/sector_model.dart';

class SectorService {
  SectorService._();
  static final SectorService instance = SectorService._();

  // Çevrimdışı ve başlangıç için 11 Çekirdek Sektör Fallback'i
  static const List<SectorModel> defaultGlobalSectors = [
    SectorModel(
      id: 'sec-dates',
      code: 'DATES',
      nameKey: 'sector.dates',
      defaultName: 'Hurma ve Hurma Ürünleri',
      iconName: 'eco_rounded',
      sortOrder: 1,
    ),
    SectorModel(
      id: 'sec-food',
      code: 'FOOD',
      nameKey: 'sector.food',
      defaultName: 'Gıda & İçecek',
      iconName: 'restaurant_rounded',
      sortOrder: 2,
    ),
    SectorModel(
      id: 'sec-agri',
      code: 'AGRI',
      nameKey: 'sector.agri',
      defaultName: 'Tarım & Ziraat',
      iconName: 'agriculture_rounded',
      sortOrder: 3,
    ),
    SectorModel(
      id: 'sec-beekeeping',
      code: 'BEEKEEPING',
      nameKey: 'sector.beekeeping',
      defaultName: 'Arıcılık & Bal',
      iconName: 'hive_rounded',
      sortOrder: 4,
    ),
    SectorModel(
      id: 'sec-furniture',
      code: 'FURNITURE',
      nameKey: 'sector.furniture',
      defaultName: 'Mobilya & Dekorasyon',
      iconName: 'chair_rounded',
      sortOrder: 5,
    ),
    SectorModel(
      id: 'sec-textile',
      code: 'TEXTILE',
      nameKey: 'sector.textile',
      defaultName: 'Tekstil & Konfeksiyon',
      iconName: 'checkroom_rounded',
      sortOrder: 6,
    ),
    SectorModel(
      id: 'sec-automotive',
      code: 'AUTOMOTIVE',
      nameKey: 'sector.automotive',
      defaultName: 'Otomotiv & Yedek Parça',
      iconName: 'directions_car_rounded',
      sortOrder: 7,
    ),
    SectorModel(
      id: 'sec-construction',
      code: 'CONSTRUCTION',
      nameKey: 'sector.construction',
      defaultName: 'İnşaat & Yapı Malzemeleri',
      iconName: 'handyman_rounded',
      sortOrder: 8,
    ),
    SectorModel(
      id: 'sec-logistics',
      code: 'LOGISTICS',
      nameKey: 'sector.logistics',
      defaultName: 'Lojistik & Taşımacılık',
      iconName: 'local_shipping_rounded',
      sortOrder: 9,
    ),
    SectorModel(
      id: 'sec-retail',
      code: 'RETAIL',
      nameKey: 'sector.retail',
      defaultName: 'Perakende & Mağazacılık',
      iconName: 'storefront_rounded',
      sortOrder: 10,
    ),
    SectorModel(
      id: 'sec-wholesale',
      code: 'WHOLESALE',
      nameKey: 'sector.wholesale',
      defaultName: 'Toptan Ticaret',
      iconName: 'warehouse_rounded',
      sortOrder: 11,
    ),
  ];

  /// Tüm küresel sektörleri ve tenant'a özel eklenmiş sektörleri listeler
  Future<List<SectorModel>> getAllSectors({String? tenantId}) async {
    try {
      var query = SupabaseService.client.from('sectors').select();
      if (tenantId != null) {
        query = query.or('is_global.eq.true,tenant_id.eq.$tenantId');
      } else {
        query = query.eq('is_global', true);
      }

      final response = await query.order('sort_order', ascending: true);
      final List<SectorModel> list = [];
      for (final row in (response as List<dynamic>)) {
        list.add(SectorModel.fromMap(row));
      }
      return list.isNotEmpty ? list : defaultGlobalSectors;
    } catch (_) {
      return defaultGlobalSectors;
    }
  }

  /// Tenant'ın seçtiği sektörleri getirir
  Future<List<TenantSectorModel>> getTenantSectors(String tenantId) async {
    try {
      final response = await SupabaseService.client
          .from('tenant_sectors')
          .select('*, sector:sectors(*)')
          .eq('tenant_id', tenantId);

      final List<TenantSectorModel> list = [];
      for (final row in (response as List<dynamic>)) {
        final sectorMap = row['sector'] as Map<String, dynamic>?;
        final sector = sectorMap != null ? SectorModel.fromMap(sectorMap) : null;
        list.add(TenantSectorModel.fromMap(row, sector: sector));
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  /// Tenant sektörlerini kaydeder (Çoklu seçim / Multi-Select)
  Future<void> saveTenantSectors(
    String tenantId,
    List<String> sectorIds, {
    String? primarySectorId,
  }) async {
    if (sectorIds.isEmpty) return;

    try {
      // Önce mevcut bağlantıları temizleyelim
      await SupabaseService.client
          .from('tenant_sectors')
          .delete()
          .eq('tenant_id', tenantId);

      // Yeni sektörleri toplu ekleyelim
      final records = sectorIds.map((secId) {
        return {
          'tenant_id': tenantId,
          'sector_id': secId,
          'is_primary': secId == (primarySectorId ?? sectorIds.first),
        };
      }).toList();

      await SupabaseService.client.from('tenant_sectors').insert(records);
    } catch (_) {
      // Offline/demo mod toleransı
    }
  }

  /// Kullanıcının kendi özel sektörünü dinamik olarak eklemesi
  Future<SectorModel> addCustomSector({
    required String tenantId,
    required String name,
    String? iconName,
  }) async {
    final code = 'CUSTOM_${DateTime.now().millisecondsSinceEpoch}';
    final newSectorMap = {
      'code': code,
      'name_key': 'sector.custom_${DateTime.now().millisecondsSinceEpoch}',
      'default_name': name,
      'icon_name': iconName ?? 'category_rounded',
      'is_global': false,
      'tenant_id': tenantId,
      'is_active': true,
      'sort_order': 99,
    };

    try {
      final res = await SupabaseService.client
          .from('sectors')
          .insert(newSectorMap)
          .select()
          .single();

      return SectorModel.fromMap(res);
    } catch (_) {
      // Çevrimdışı/Mock
      return SectorModel(
        id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
        code: code,
        nameKey: 'sector.custom',
        defaultName: name,
        iconName: iconName ?? 'category_rounded',
        isGlobal: false,
        tenantId: tenantId,
      );
    }
  }

  /// Ürün Kalite Derecelerini getirir (Premium, 1. Sınıf vb.)
  Future<List<ProductGradeModel>> getProductGrades({String? sectorId, String? tenantId}) async {
    try {
      var query = SupabaseService.client.from('product_grades').select();
      if (sectorId != null) query = query.eq('sector_id', sectorId);
      final res = await query.order('sort_order', ascending: true);

      final List<ProductGradeModel> list = [];
      for (final r in (res as List<dynamic>)) {
        list.add(ProductGradeModel.fromMap(r));
      }
      return list.isNotEmpty ? list : defaultGrades;
    } catch (_) {
      return defaultGrades;
    }
  }

  /// Ürün Durumları / Fire Kondisyonlarını getirir
  Future<List<ProductConditionModel>> getProductConditions({String? tenantId}) async {
    try {
      final res = await SupabaseService.client
          .from('product_conditions')
          .select()
          .order('code', ascending: true);

      final List<ProductConditionModel> list = [];
      for (final r in (res as List<dynamic>)) {
        list.add(ProductConditionModel.fromMap(r));
      }
      return list.isNotEmpty ? list : defaultConditions;
    } catch (_) {
      return defaultConditions;
    }
  }

  static const List<ProductGradeModel> defaultGrades = [
    ProductGradeModel(
      id: 'gr-prem',
      code: 'PREMIUM',
      nameKey: 'grade.premium',
      defaultName: 'Premium / Duble VIP',
      sortOrder: 1,
    ),
    ProductGradeModel(
      id: 'gr-first',
      code: 'FIRST_GRADE',
      nameKey: 'grade.first',
      defaultName: '1. Sınıf Seçme',
      sortOrder: 2,
    ),
    ProductGradeModel(
      id: 'gr-second',
      code: 'SECOND_GRADE',
      nameKey: 'grade.second',
      defaultName: '2. Sınıf Standart',
      sortOrder: 3,
    ),
    ProductGradeModel(
      id: 'gr-ind',
      code: 'INDUSTRIAL',
      nameKey: 'grade.industrial',
      defaultName: 'Sanayi / Endüstriyel Tip',
      sortOrder: 4,
    ),
  ];

  static const List<ProductConditionModel> defaultConditions = [
    ProductConditionModel(
      id: 'cond-sound',
      code: 'SOUND_NORMAL',
      nameKey: 'condition.sound_normal',
      defaultName: 'Normal Sağlam Mamul',
      isScrapFire: false,
      accountingImpactType: 'STANDARD',
    ),
    ProductConditionModel(
      id: 'cond-defective',
      code: 'DEFECTIVE_CLASS_B',
      nameKey: 'condition.defective_b',
      defaultName: 'Kusurlu / İkinci Kalite',
      isScrapFire: false,
      accountingImpactType: 'DISCOUNTED_SALE',
    ),
    ProductConditionModel(
      id: 'cond-fire',
      code: 'FIRE_REJECT',
      nameKey: 'condition.fire_reject',
      defaultName: 'Fire / Üretim-Depo Kaybı',
      isScrapFire: true,
      accountingImpactType: 'WRITE_OFF',
    ),
    ProductConditionModel(
      id: 'cond-scrap',
      code: 'EXPIRED_SCRAP',
      nameKey: 'condition.expired_scrap',
      defaultName: 'Miadı Dolmuş Hurda',
      isScrapFire: true,
      accountingImpactType: 'SCRAP_EXPENSE',
    ),
  ];
}
