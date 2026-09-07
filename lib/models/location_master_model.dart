// ==============================================================================
// NAKHL & NAHL — GLOBAL LOCATION MASTER DATA MODELS
// Country, City, Global Address & Country Business Rule Engine Profiles
// CC BY 4.0 SimpleMaps World Cities Attribution Supported
// ==============================================================================

class CountryMasterModel {
  final String id;
  final String iso2;
  final String iso3;
  final String countryName;
  final String countryNameEn;
  final String countryNameTr;
  final String countryNameAr;
  final String phoneCode;
  final String currencyCode;
  final String currencyName;
  final String defaultLanguage;
  final String timezone;
  final String flag;
  final bool active;
  final int sortOrder;

  const CountryMasterModel({
    required this.id,
    required this.iso2,
    required this.iso3,
    required this.countryName,
    required this.countryNameEn,
    required this.countryNameTr,
    required this.countryNameAr,
    required this.phoneCode,
    required this.currencyCode,
    required this.currencyName,
    required this.defaultLanguage,
    required this.timezone,
    required this.flag,
    this.active = true,
    this.sortOrder = 100,
  });

  /// Get localized name depending on active language code
  String getLocalizedName(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'tr':
        return countryNameTr.isNotEmpty ? countryNameTr : countryName;
      case 'ar':
        return countryNameAr.isNotEmpty ? countryNameAr : countryName;
      case 'en':
      default:
        return countryNameEn.isNotEmpty ? countryNameEn : countryName;
    }
  }

  factory CountryMasterModel.fromJson(Map<String, dynamic> json) {
    return CountryMasterModel(
      id: json['id']?.toString() ?? json['iso2']?.toString() ?? '',
      iso2: (json['iso2'] ?? json['code'] ?? '').toString().toUpperCase(),
      iso3: (json['iso3'] ?? '').toString().toUpperCase(),
      countryName: json['country_name'] ?? json['name'] ?? '',
      countryNameEn: json['country_name_en'] ?? json['name_en'] ?? json['country_name'] ?? '',
      countryNameTr: json['country_name_tr'] ?? json['name_tr'] ?? json['country_name'] ?? '',
      countryNameAr: json['country_name_ar'] ?? json['name_ar'] ?? json['country_name'] ?? '',
      phoneCode: json['phone_code'] ?? '',
      currencyCode: json['currency_code'] ?? 'USD',
      currencyName: json['currency_name'] ?? '',
      defaultLanguage: json['default_language'] ?? 'en',
      timezone: json['timezone'] ?? 'UTC',
      flag: json['flag'] ?? '🌐',
      active: json['active'] ?? true,
      sortOrder: json['sort_order'] is int ? json['sort_order'] : 100,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'iso2': iso2,
      'iso3': iso3,
      'country_name': countryName,
      'country_name_en': countryNameEn,
      'country_name_tr': countryNameTr,
      'country_name_ar': countryNameAr,
      'phone_code': phoneCode,
      'currency_code': currencyCode,
      'currency_name': currencyName,
      'default_language': defaultLanguage,
      'timezone': timezone,
      'flag': flag,
      'active': active,
      'sort_order': sortOrder,
    };
  }
}

class CityMasterModel {
  final String id;
  final String countryId;
  final String countryCode;
  final String cityName;
  final String cityNameAscii;
  final String adminName;
  final double latitude;
  final double longitude;
  final String? capitalType;
  final int population;
  final String? sourceId;
  final bool active;

  const CityMasterModel({
    required this.id,
    required this.countryId,
    required this.countryCode,
    required this.cityName,
    required this.cityNameAscii,
    required this.adminName,
    required this.latitude,
    required this.longitude,
    this.capitalType,
    this.population = 0,
    this.sourceId,
    this.active = true,
  });

  factory CityMasterModel.fromJson(Map<String, dynamic> json) {
    return CityMasterModel(
      id: json['id']?.toString() ?? '',
      countryId: json['country_id']?.toString() ?? '',
      countryCode: (json['country_code'] ?? json['iso2'] ?? '').toString().toUpperCase(),
      cityName: json['city_name'] ?? json['city'] ?? '',
      cityNameAscii: json['city_name_ascii'] ?? json['city_ascii'] ?? json['city_name'] ?? '',
      adminName: json['admin_name'] ?? '',
      latitude: (json['latitude'] ?? json['lat'] ?? 0.0) is num
          ? (json['latitude'] ?? json['lat'] ?? 0.0).toDouble()
          : double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: (json['longitude'] ?? json['lng'] ?? 0.0) is num
          ? (json['longitude'] ?? json['lng'] ?? 0.0).toDouble()
          : double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
      capitalType: json['capital_type'] ?? json['capital'],
      population: (json['population'] is num)
          ? (json['population'] as num).toInt()
          : int.tryParse(json['population']?.toString() ?? '0') ?? 0,
      sourceId: json['source_id']?.toString() ?? json['id']?.toString(),
      active: json['active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'country_id': countryId,
      'country_code': countryCode,
      'city_name': cityName,
      'city_name_ascii': cityNameAscii,
      'admin_name': adminName,
      'latitude': latitude,
      'longitude': longitude,
      'capital_type': capitalType,
      'population': population,
      'source_id': sourceId,
      'active': active,
    };
  }
}

class GlobalAddressModel {
  final String countryCode;
  final String? countryId;
  final String administrativeArea; // İl / Bölge / Province / Region
  final String cityName;
  final String? cityId;
  final String district;           // İlçe / District / County
  final String? neighborhood;      // Mahalle / Neighborhood
  final String postalCode;
  final String addressLine1;       // Cadde, Sokak, Bina No
  final String? addressLine2;       // Daire, Kat, vb.
  final double? latitude;
  final double? longitude;

  const GlobalAddressModel({
    required this.countryCode,
    this.countryId,
    required this.administrativeArea,
    required this.cityName,
    this.cityId,
    this.district = '',
    this.neighborhood,
    this.postalCode = '',
    required this.addressLine1,
    this.addressLine2,
    this.latitude,
    this.longitude,
  });

  String toFullAddress() {
    final parts = <String>[];
    if (addressLine1.isNotEmpty) parts.add(addressLine1);
    if (addressLine2 != null && addressLine2!.isNotEmpty) parts.add(addressLine2!);
    if (neighborhood != null && neighborhood!.isNotEmpty) parts.add(neighborhood!);
    if (district.isNotEmpty) parts.add(district);
    if (cityName.isNotEmpty) parts.add(cityName);
    if (administrativeArea.isNotEmpty && administrativeArea != cityName) {
      parts.add(administrativeArea);
    }
    if (postalCode.isNotEmpty) parts.add(postalCode);
    parts.add(countryCode);
    return parts.join(', ');
  }

  factory GlobalAddressModel.fromJson(Map<String, dynamic> json) {
    return GlobalAddressModel(
      countryCode: (json['country_code'] ?? 'SA').toString().toUpperCase(),
      countryId: json['country_id']?.toString(),
      administrativeArea: json['administrative_area'] ?? json['region'] ?? '',
      cityName: json['city_name'] ?? json['city'] ?? '',
      cityId: json['city_id']?.toString(),
      district: json['district'] ?? '',
      neighborhood: json['neighborhood'],
      postalCode: json['postal_code'] ?? '',
      addressLine1: json['address_line_1'] ?? json['address'] ?? '',
      addressLine2: json['address_line_2'],
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'country_code': countryCode,
      'country_id': countryId,
      'administrative_area': administrativeArea,
      'city_name': cityName,
      'city_id': cityId,
      'district': district,
      'neighborhood': neighborhood,
      'postal_code': postalCode,
      'address_line_1': addressLine1,
      'address_line_2': addressLine2,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

/// Country Business Rules Configuration
class CountryBusinessProfile {
  final String countryCode;
  final String countryName;
  final String currencyCode;
  final String currencySymbol;
  final double defaultVatRate;
  final List<double> vatRates;
  final String invoiceStandard; // 'ZATCA_PHASE_2' | 'GIB_EFATURA' | 'EU_PEPPOL' | 'GENERIC'
  final String adapterType;
  final String timezone;
  final String defaultLanguage;
  final String phonePrefix;
  final bool requiresTaxNumber;
  final String taxNumberLabel;
  final String taxNumberValidationRegex;

  const CountryBusinessProfile({
    required this.countryCode,
    required this.countryName,
    required this.currencyCode,
    required this.currencySymbol,
    required this.defaultVatRate,
    required this.vatRates,
    required this.invoiceStandard,
    required this.adapterType,
    required this.timezone,
    required this.defaultLanguage,
    required this.phonePrefix,
    this.requiresTaxNumber = true,
    this.taxNumberLabel = 'Tax / VAT Number',
    this.taxNumberValidationRegex = r'^\d+$',
  });
}
