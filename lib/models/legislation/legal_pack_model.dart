// ==============================================================================
// NAKHL & NAHL — LEGAL PACK & JURISDICTION MODELS
// Master Directive: Focused Legislation Library & Global Shelf Architecture
// ==============================================================================

enum LegalShelfStatus {
  notLoaded,
  discovery,
  partial,
  active,
  maintenance,
  suspended,
  archived,
}

enum LegalPackScope {
  fullBusinessOperation,
  foodImportOnly,
  foodExportOnly,
  none,
}

enum AuthorityType {
  tax,
  customs,
  foodSafety,
  standards,
  commerce,
  agriculture,
  health,
}

class LegalJurisdictionModel {
  final String code; // 'SA', 'TR', 'EU', 'DE', 'CN', etc.
  final String isoAlpha2;
  final String nameTr;
  final String nameEn;
  final String? nameAr;
  final String region;
  final bool isActive;
  final LegalShelfStatus shelfStatus;
  final String? officialPortalUrl;

  const LegalJurisdictionModel({
    required this.code,
    required this.isoAlpha2,
    required this.nameTr,
    required this.nameEn,
    this.nameAr,
    required this.region,
    required this.isActive,
    required this.shelfStatus,
    this.officialPortalUrl,
  });

  factory LegalJurisdictionModel.fromJson(Map<String, dynamic> json) {
    return LegalJurisdictionModel(
      code: json['code'] ?? '',
      isoAlpha2: json['iso_alpha2'] ?? '',
      nameTr: json['name_tr'] ?? '',
      nameEn: json['name_en'] ?? '',
      nameAr: json['name_ar'],
      region: json['region'] ?? 'GLOBAL',
      isActive: json['is_active'] ?? false,
      shelfStatus: _parseShelfStatus(json['shelf_status']),
      officialPortalUrl: json['official_portal_url'],
    );
  }

  static LegalShelfStatus _parseShelfStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'ACTIVE':
        return LegalShelfStatus.active;
      case 'DISCOVERY':
        return LegalShelfStatus.discovery;
      case 'PARTIAL':
        return LegalShelfStatus.partial;
      case 'MAINTENANCE':
        return LegalShelfStatus.maintenance;
      case 'SUSPENDED':
        return LegalShelfStatus.suspended;
      case 'ARCHIVED':
        return LegalShelfStatus.archived;
      case 'NOT_LOADED':
      default:
        return LegalShelfStatus.notLoaded;
    }
  }

  String get flagEmoji {
    switch (code) {
      case 'SA':
        return '🇸🇦';
      case 'TR':
        return '🇹🇷';
      case 'EU':
        return '🇪🇺';
      case 'DE':
        return '🇩🇪';
      case 'CN':
        return '🇨🇳';
      case 'IN':
        return '🇮🇳';
      case 'RU':
        return '🇷🇺';
      case 'AE':
        return '🇦🇪';
      case 'QA':
        return '🇶🇦';
      case 'KW':
        return '🇰🇼';
      case 'BH':
        return '🇧🇭';
      case 'OM':
        return '🇴🇲';
      case 'EG':
        return '🇪🇬';
      case 'JO':
        return '🇯🇴';
      case 'GB':
        return '🇬🇧';
      case 'US':
        return '🇺🇸';
      case 'CA':
        return '🇨🇦';
      case 'AU':
        return '🇦🇺';
      case 'JP':
        return '🇯🇵';
      case 'KR':
        return '🇰🇷';
      case 'KZ':
        return '🇰🇿';
      case 'UZ':
        return '🇺🇿';
      case 'AZ':
        return '🇦🇿';
      default:
        return '🌐';
    }
  }
}

class LegalPackModel {
  final String packCode;
  final String jurisdictionCode;
  final String packNameTr;
  final String packNameEn;
  final LegalPackScope scope;
  final LegalShelfStatus status;
  final double coveragePercentage;
  final List<String> primaryAuthorities;
  final List<String> coveredDomains;
  final String? notes;

  const LegalPackModel({
    required this.packCode,
    required this.jurisdictionCode,
    required this.packNameTr,
    required this.packNameEn,
    required this.scope,
    required this.status,
    required this.coveragePercentage,
    required this.primaryAuthorities,
    required this.coveredDomains,
    this.notes,
  });

  bool get isFullyActive => status == LegalShelfStatus.active;
  bool get isShelfEmpty => status == LegalShelfStatus.notLoaded;
  String get packId => packCode;

  String get scopeDisplayTr {
    switch (scope) {
      case LegalPackScope.fullBusinessOperation:
        return 'Tam Operasyonel (Şirket, Vergi, Gümrük, Gıda, Ticaret)';
      case LegalPackScope.foodImportOnly:
        return 'Yalnızca Gıda İthalatı & Pazar Gereksinimleri';
      case LegalPackScope.foodExportOnly:
        return 'Yalnızca Gıda İhracatı';
      case LegalPackScope.none:
        return 'Boş Raf (Henüz Yüklenmedi)';
    }
  }
}
