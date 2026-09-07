import 'package:flutter/material.dart';

/// Sektör Modeli (Sectors Master)
class SectorModel {
  final String id;
  final String code; // DATES, FOOD, AGRI, BEEKEEPING, FURNITURE, TEXTILE, etc.
  final String nameKey;
  final String defaultName;
  final String iconName;
  final bool isGlobal;
  final String? tenantId;
  final bool isActive;
  final int sortOrder;

  const SectorModel({
    required this.id,
    required this.code,
    required this.nameKey,
    required this.defaultName,
    this.iconName = 'category_rounded',
    this.isGlobal = true,
    this.tenantId,
    this.isActive = true,
    this.sortOrder = 0,
  });

  IconData get icon {
    switch (iconName) {
      case 'eco_rounded':
        return Icons.eco_rounded;
      case 'restaurant_rounded':
        return Icons.restaurant_rounded;
      case 'agriculture_rounded':
        return Icons.agriculture_rounded;
      case 'hive_rounded':
        return Icons.hive_rounded;
      case 'chair_rounded':
        return Icons.chair_rounded;
      case 'checkroom_rounded':
        return Icons.checkroom_rounded;
      case 'directions_car_rounded':
        return Icons.directions_car_rounded;
      case 'handyman_rounded':
        return Icons.handyman_rounded;
      case 'local_shipping_rounded':
        return Icons.local_shipping_rounded;
      case 'storefront_rounded':
        return Icons.storefront_rounded;
      case 'warehouse_rounded':
        return Icons.warehouse_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  factory SectorModel.fromMap(Map<String, dynamic> map) {
    return SectorModel(
      id: map['id']?.toString() ?? '',
      code: map['code']?.toString() ?? '',
      nameKey: map['name_key']?.toString() ?? '',
      defaultName: map['default_name']?.toString() ?? '',
      iconName: map['icon_name']?.toString() ?? 'category_rounded',
      isGlobal: map['is_global'] == true,
      tenantId: map['tenant_id']?.toString(),
      isActive: map['is_active'] != false,
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty) 'id': id,
      'code': code,
      'name_key': nameKey,
      'default_name': defaultName,
      'icon_name': iconName,
      'is_global': isGlobal,
      if (tenantId != null) 'tenant_id': tenantId,
      'is_active': isActive,
      'sort_order': sortOrder,
    };
  }
}

/// Tenant ve Sektör İlişki Modeli (Multi-Select)
class TenantSectorModel {
  final String id;
  final String tenantId;
  final String sectorId;
  final bool isPrimary;
  final SectorModel? sector;

  const TenantSectorModel({
    required this.id,
    required this.tenantId,
    required this.sectorId,
    this.isPrimary = false,
    this.sector,
  });

  factory TenantSectorModel.fromMap(Map<String, dynamic> map, {SectorModel? sector}) {
    return TenantSectorModel(
      id: map['id']?.toString() ?? '',
      tenantId: map['tenant_id']?.toString() ?? '',
      sectorId: map['sector_id']?.toString() ?? '',
      isPrimary: map['is_primary'] == true,
      sector: sector,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty) 'id': id,
      'tenant_id': tenantId,
      'sector_id': sectorId,
      'is_primary': isPrimary,
    };
  }
}

/// Ürün Kalite Derecesi Modeli
class ProductGradeModel {
  final String id;
  final String? tenantId;
  final String? sectorId;
  final String code; // PREMIUM, FIRST_GRADE, SECOND_GRADE
  final String nameKey;
  final String defaultName;
  final int sortOrder;
  final bool isActive;

  const ProductGradeModel({
    required this.id,
    this.tenantId,
    this.sectorId,
    required this.code,
    required this.nameKey,
    required this.defaultName,
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory ProductGradeModel.fromMap(Map<String, dynamic> map) {
    return ProductGradeModel(
      id: map['id']?.toString() ?? '',
      tenantId: map['tenant_id']?.toString(),
      sectorId: map['sector_id']?.toString(),
      code: map['code']?.toString() ?? '',
      nameKey: map['name_key']?.toString() ?? '',
      defaultName: map['default_name']?.toString() ?? '',
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
      isActive: map['is_active'] != false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (sectorId != null) 'sector_id': sectorId,
      'code': code,
      'name_key': nameKey,
      'default_name': defaultName,
      'sort_order': sortOrder,
      'is_active': isActive,
    };
  }
}

/// Ürün Durumu / Fire ve Kondisyon Modeli
/// ÖNEMLİ: Fire kalite derecesi değil, muhasebe ve stok etki türü olan bir kondisyondur.
class ProductConditionModel {
  final String id;
  final String? tenantId;
  final String code; // SOUND_NORMAL, DEFECTIVE_CLASS_B, FIRE_REJECT, EXPIRED_SCRAP, BY_PRODUCT
  final String nameKey;
  final String defaultName;
  final bool isScrapFire;
  final String accountingImpactType; // STANDARD, WRITE_OFF, DISCOUNTED_SALE, SCRAP_EXPENSE
  final bool isActive;

  const ProductConditionModel({
    required this.id,
    this.tenantId,
    required this.code,
    required this.nameKey,
    required this.defaultName,
    this.isScrapFire = false,
    this.accountingImpactType = 'STANDARD',
    this.isActive = true,
  });

  factory ProductConditionModel.fromMap(Map<String, dynamic> map) {
    return ProductConditionModel(
      id: map['id']?.toString() ?? '',
      tenantId: map['tenant_id']?.toString(),
      code: map['code']?.toString() ?? '',
      nameKey: map['name_key']?.toString() ?? '',
      defaultName: map['default_name']?.toString() ?? '',
      isScrapFire: map['is_scrap_fire'] == true,
      accountingImpactType: map['accounting_impact_type']?.toString() ?? 'STANDARD',
      isActive: map['is_active'] != false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      'code': code,
      'name_key': nameKey,
      'default_name': defaultName,
      'is_scrap_fire': isScrapFire,
      'accounting_impact_type': accountingImpactType,
      'is_active': isActive,
    };
  }
}
