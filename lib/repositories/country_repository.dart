import '../services/supabase_service.dart';

class Country {
  final String code;
  final String isoAlpha3;
  final String? isoNumeric;
  final String name;
  final String? nativeName;
  final String? region;
  final String? phoneCode;
  final String? defaultLanguageCode;
  final String? defaultCurrencyCode;
  final String timezone;
  final bool isActive;

  const Country({
    required this.code,
    required this.isoAlpha3,
    this.isoNumeric,
    required this.name,
    this.nativeName,
    this.region,
    this.phoneCode,
    this.defaultLanguageCode,
    this.defaultCurrencyCode,
    required this.timezone,
    required this.isActive,
  });

  factory Country.fromMap(Map<String, dynamic> map) {
    return Country(
      code: map['code'] ?? '',
      isoAlpha3: map['iso_alpha3'] ?? '',
      isoNumeric: map['iso_numeric'],
      name: map['name'] ?? '',
      nativeName: map['native_name'],
      region: map['region'],
      phoneCode: map['phone_code'],
      defaultLanguageCode: map['default_language_code'],
      defaultCurrencyCode: map['default_currency_code'],
      timezone: map['timezone'] ?? 'UTC',
      isActive: map['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'iso_alpha3': isoAlpha3,
      'iso_numeric': isoNumeric,
      'name': name,
      'native_name': nativeName,
      'region': region,
      'phone_code': phoneCode,
      'default_language_code': defaultLanguageCode,
      'default_currency_code': defaultCurrencyCode,
      'timezone': timezone,
      'is_active': isActive,
    };
  }
}

class CountryRepository {
  CountryRepository._();
  static final CountryRepository instance = CountryRepository._();

  /// Aktif tüm ülkeleri listeler
  Future<List<Country>> getCountries({bool onlyActive = true}) async {
    try {
      var query = SupabaseService.client.from('countries').select();
      if (onlyActive) {
        query = query.eq('is_active', true);
      }
      final response = await query.order('name', ascending: true);
      return (response as List<dynamic>)
          .map((m) => Country.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// ISO-2 koduna göre ülke getirir
  Future<Country?> getCountryByCode(String code) async {
    try {
      final response = await SupabaseService.client
          .from('countries')
          .select()
          .eq('code', code.toUpperCase().trim())
          .maybeSingle();

      if (response != null) {
        return Country.fromMap(response);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
