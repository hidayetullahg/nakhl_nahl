import '../services/supabase_service.dart';

class RegionalLocale {
  final String localeCode; // tr-TR, ar-SA, en-US, fa-IR, ur-PK
  final String languageCode;
  final String countryCode;
  final String scriptCode;
  final String direction; // ltr, rtl
  final String dateFormat;
  final String timeFormat;
  final String decimalSeparator;
  final String thousandsSeparator;
  final String currencySymbolPlacement; // BEFORE, AFTER
  final bool isActive;

  const RegionalLocale({
    required this.localeCode,
    required this.languageCode,
    required this.countryCode,
    required this.scriptCode,
    required this.direction,
    required this.dateFormat,
    required this.timeFormat,
    required this.decimalSeparator,
    required this.thousandsSeparator,
    required this.currencySymbolPlacement,
    required this.isActive,
  });

  bool get isRtl => direction.toLowerCase() == 'rtl';

  factory RegionalLocale.fromMap(Map<String, dynamic> map) {
    return RegionalLocale(
      localeCode: map['locale_code'] ?? '',
      languageCode: map['language_code'] ?? '',
      countryCode: map['country_code'] ?? '',
      scriptCode: map['script_code'] ?? '',
      direction: map['direction'] ?? 'ltr',
      dateFormat: map['date_format'] ?? 'DD/MM/YYYY',
      timeFormat: map['time_format'] ?? 'HH:mm:ss',
      decimalSeparator: map['decimal_separator'] ?? '.',
      thousandsSeparator: map['thousands_separator'] ?? ',',
      currencySymbolPlacement: map['currency_symbol_placement'] ?? 'AFTER',
      isActive: map['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'locale_code': localeCode,
      'language_code': languageCode,
      'country_code': countryCode,
      'script_code': scriptCode,
      'direction': direction,
      'date_format': dateFormat,
      'time_format': timeFormat,
      'decimal_separator': decimalSeparator,
      'thousands_separator': thousandsSeparator,
      'currency_symbol_placement': currencySymbolPlacement,
      'is_active': isActive,
    };
  }
}

class LocaleRepository {
  LocaleRepository._();
  static final LocaleRepository instance = LocaleRepository._();

  /// Bölgesel yerel ayarları (Locales) listeler
  Future<List<RegionalLocale>> getLocales({bool onlyActive = true}) async {
    try {
      var query = SupabaseService.client.from('regional_locales').select();
      if (onlyActive) {
        query = query.eq('is_active', true);
      }
      final response = await query.order('locale_code', ascending: true);
      return (response as List<dynamic>)
          .map((m) => RegionalLocale.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Locale koduna göre (örn: 'ar-SA', 'tr-TR') getirir
  Future<RegionalLocale?> getLocaleByCode(String localeCode) async {
    try {
      final response = await SupabaseService.client
          .from('regional_locales')
          .select()
          .eq('locale_code', localeCode.trim())
          .maybeSingle();

      if (response != null) {
        return RegionalLocale.fromMap(response);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
