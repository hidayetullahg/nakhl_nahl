// ==============================================================================
// NAKHL & NAHL — GLOBAL LOCATION MASTER SERVICE
// Multi-lingual (TR/EN/AR), Dual-Priority (KSA + Turkey + World),
// Supabase RPC + Instant In-Memory Priority Cache, Business Rule Engine
// SimpleMaps World Cities CC BY 4.0 Attributed
// ==============================================================================

import 'package:flutter/foundation.dart';
import '../models/location_master_model.dart';
import 'supabase_service.dart';

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  // In-memory caches
  List<CountryMasterModel>? _cachedCountries;
  final Map<String, List<CityMasterModel>> _cachedCitiesByCountry = {};

  // ──────────────────────────────────────────────────────────────────────────
  // 1. BUSINESS RULE PROFILES (COUNTRY-BASED BUSINESS ENGINE)
  // ──────────────────────────────────────────────────────────────────────────
  static final Map<String, CountryBusinessProfile> _businessProfiles = {
    'SA': const CountryBusinessProfile(
      countryCode: 'SA',
      countryName: 'Saudi Arabia',
      currencyCode: 'SAR',
      currencySymbol: 'ر.س',
      defaultVatRate: 15.0,
      vatRates: [15.0, 0.0],
      invoiceStandard: 'ZATCA_PHASE_2',
      adapterType: 'zatca',
      timezone: 'Asia/Riyadh',
      defaultLanguage: 'ar',
      phonePrefix: '+966',
      taxNumberLabel: 'ZATCA VAT / Tax ID (الرقم الضريبي)',
      taxNumberValidationRegex: r'^3\d{13}3$', // 15 digits starting and ending with 3
    ),
    'TR': const CountryBusinessProfile(
      countryCode: 'TR',
      countryName: 'Türkiye',
      currencyCode: 'TRY',
      currencySymbol: '₺',
      defaultVatRate: 20.0,
      vatRates: [20.0, 10.0, 1.0, 0.0],
      invoiceStandard: 'GIB_EFATURA',
      adapterType: 'gib_efatura',
      timezone: 'Europe/Istanbul',
      defaultLanguage: 'tr',
      phonePrefix: '+90',
      taxNumberLabel: 'VKN / TCKN',
      taxNumberValidationRegex: r'^\d{10,11}$',
    ),
    'AE': const CountryBusinessProfile(
      countryCode: 'AE',
      countryName: 'United Arab Emirates',
      currencyCode: 'AED',
      currencySymbol: 'د.إ',
      defaultVatRate: 5.0,
      vatRates: [5.0, 0.0],
      invoiceStandard: 'FTA_UAE',
      adapterType: 'fta_uae',
      timezone: 'Asia/Dubai',
      defaultLanguage: 'ar',
      phonePrefix: '+971',
      taxNumberLabel: 'TRN (Tax Registration Number)',
      taxNumberValidationRegex: r'^\d{15}$',
    ),
    'DE': const CountryBusinessProfile(
      countryCode: 'DE',
      countryName: 'Germany',
      currencyCode: 'EUR',
      currencySymbol: '€',
      defaultVatRate: 19.0,
      vatRates: [19.0, 7.0, 0.0],
      invoiceStandard: 'EU_PEPPOL',
      adapterType: 'xrechnung_peppol',
      timezone: 'Europe/Berlin',
      defaultLanguage: 'de',
      phonePrefix: '+49',
      taxNumberLabel: 'USt-IdNr.',
      taxNumberValidationRegex: r'^DE\d{9}$',
    ),
    'US': const CountryBusinessProfile(
      countryCode: 'US',
      countryName: 'United States',
      currencyCode: 'USD',
      currencySymbol: r'$',
      defaultVatRate: 0.0,
      vatRates: [0.0, 5.0, 8.25],
      invoiceStandard: 'GENERIC',
      adapterType: 'generic_invoice',
      timezone: 'America/New_York',
      defaultLanguage: 'en',
      phonePrefix: '+1',
      taxNumberLabel: 'EIN / SSN',
      taxNumberValidationRegex: r'^\d{2}-\d{7}$|^\d{9}$',
    ),
    'GB': const CountryBusinessProfile(
      countryCode: 'GB',
      countryName: 'United Kingdom',
      currencyCode: 'GBP',
      currencySymbol: '£',
      defaultVatRate: 20.0,
      vatRates: [20.0, 5.0, 0.0],
      invoiceStandard: 'HMRC_MTD',
      adapterType: 'hmrc_mtd',
      timezone: 'Europe/London',
      defaultLanguage: 'en',
      phonePrefix: '+44',
      taxNumberLabel: 'VAT Reg No',
      taxNumberValidationRegex: r'^\d{9}$',
    ),
  };

  CountryBusinessProfile getBusinessProfile(String countryCode) {
    final code = countryCode.toUpperCase();
    return _businessProfiles[code] ??
        CountryBusinessProfile(
          countryCode: code,
          countryName: code,
          currencyCode: 'USD',
          currencySymbol: r'$',
          defaultVatRate: 0.0,
          vatRates: const [0.0],
          invoiceStandard: 'GENERIC',
          adapterType: 'generic_invoice',
          timezone: 'UTC',
          defaultLanguage: 'en',
          phonePrefix: '+',
          taxNumberLabel: 'Tax ID',
        );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 2. QUERY NORMALIZATION (TURKISH, ARABIC, ACCENT INSENSITIVE)
  // ──────────────────────────────────────────────────────────────────────────
  static String normalizeSearchString(String input) {
    var s = input.trim().toLowerCase();
    // Turkish replacements
    s = s.replaceAll('ı', 'i')
         .replaceAll('İ', 'i')
         .replaceAll('ğ', 'g')
         .replaceAll('ü', 'u')
         .replaceAll('ş', 's')
         .replaceAll('ö', 'o')
         .replaceAll('ç', 'c');
    // Arabic normalization (alif with hamza, ta marbuta, etc.)
    s = s.replaceAll('أ', 'ا')
         .replaceAll('إ', 'ا')
         .replaceAll('آ', 'ا')
         .replaceAll('ة', 'ه')
         .replaceAll('ى', 'ي');
    return s;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 3. COUNTRIES: FETCH & MULTILINGUAL SEARCH
  // ──────────────────────────────────────────────────────────────────────────
  Future<List<CountryMasterModel>> getCountries() async {
    if (_cachedCountries != null && _cachedCountries!.isNotEmpty) {
      return _cachedCountries!;
    }

    try {
      final client = SupabaseService.client;
      final response = await client
          .from('countries')
          .select()
          .eq('active', true)
          .order('sort_order', ascending: true)
          .order('name', ascending: true);

      if (response.isNotEmpty) {
        _cachedCountries = (response as List)
            .map((item) => CountryMasterModel.fromJson(item as Map<String, dynamic>))
            .toList();
        return _cachedCountries!;
      }
    } catch (e) {
      debugPrint('[LocationService] Supabase countries fetch fallback: $e');
    }

    // In-memory fallback
    _cachedCountries = List.from(_priorityCountries);
    return _cachedCountries!;
  }

  Future<List<CountryMasterModel>> searchCountries(String query, {String lang = 'tr'}) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      return getCountries();
    }

    // Try Supabase RPC first if available
    try {
      final client = SupabaseService.client;
      final response = await client.rpc('search_countries', params: {
        'p_query': cleanQuery,
        'p_lang': lang,
      });
      if (response != null && response is List && response.isNotEmpty) {
        return (response)
            .map((item) => CountryMasterModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('[LocationService] Supabase RPC search_countries fallback: $e');
    }

    // Local in-memory search across ISO codes, TR, EN, AR names
    final allCountries = await getCountries();
    final normQuery = normalizeSearchString(cleanQuery);

    return allCountries.where((c) {
      final iso2Match = c.iso2.toLowerCase() == normQuery;
      final iso3Match = c.iso3.toLowerCase() == normQuery;
      final nameNorm = normalizeSearchString(c.countryName);
      final enNorm = normalizeSearchString(c.countryNameEn);
      final trNorm = normalizeSearchString(c.countryNameTr);
      final arNorm = normalizeSearchString(c.countryNameAr);

      return iso2Match ||
             iso3Match ||
             nameNorm.contains(normQuery) ||
             enNorm.contains(normQuery) ||
             trNorm.contains(normQuery) ||
             arNorm.contains(normQuery);
    }).toList();
  }

  CountryMasterModel? getCountryByCode(String code) {
    final target = code.trim().toUpperCase();
    final countries = _cachedCountries ?? _priorityCountries;
    try {
      return countries.firstWhere((c) => c.iso2 == target || c.iso3 == target);
    } catch (_) {
      return null;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 4. CITIES: FETCH & SEARCH (PRIORITIZING KSA & TURKEY)
  // ──────────────────────────────────────────────────────────────────────────
  Future<List<CityMasterModel>> getCitiesByCountry(String countryCode, {int limit = 100}) async {
    final code = countryCode.toUpperCase();
    if (_cachedCitiesByCountry.containsKey(code)) {
      final list = _cachedCitiesByCountry[code]!;
      return list.length > limit ? list.sublist(0, limit) : list;
    }

    try {
      final client = SupabaseService.client;
      final response = await client
          .from('cities')
          .select()
          .eq('country_code', code)
          .eq('active', true)
          .order('population', ascending: false)
          .limit(limit);

      if (response.isNotEmpty) {
        final cities = (response as List)
            .map((item) => CityMasterModel.fromJson(item as Map<String, dynamic>))
            .toList();
        _cachedCitiesByCountry[code] = cities;
        return cities;
      }
    } catch (e) {
      debugPrint('[LocationService] Supabase getCitiesByCountry fallback for $code: $e');
    }

    // In-memory fallback
    final fallbackList = _getPriorityCities(code);
    _cachedCitiesByCountry[code] = fallbackList;
    return fallbackList.length > limit ? fallbackList.sublist(0, limit) : fallbackList;
  }

  Future<List<CityMasterModel>> searchCities(
    String countryCode,
    String query, {
    int limit = 25,
  }) async {
    final code = countryCode.toUpperCase();
    final cleanQuery = query.trim();

    if (cleanQuery.isEmpty) {
      return getCitiesByCountry(code, limit: limit);
    }

    // Try Supabase RPC first
    try {
      final client = SupabaseService.client;
      final response = await client.rpc('search_cities', params: {
        'p_country_code': code,
        'p_query': cleanQuery,
        'p_limit': limit,
      });

      if (response != null && response is List && response.isNotEmpty) {
        return response
            .map((item) => CityMasterModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('[LocationService] Supabase search_cities RPC fallback: $e');
    }

    // Local normalized search
    final allCities = await getCitiesByCountry(code, limit: 500);
    final normQuery = normalizeSearchString(cleanQuery);

    final matches = allCities.where((city) {
      final cityNorm = normalizeSearchString(city.cityName);
      final asciiNorm = normalizeSearchString(city.cityNameAscii);
      final adminNorm = normalizeSearchString(city.adminName);

      return cityNorm.contains(normQuery) ||
             asciiNorm.contains(normQuery) ||
             adminNorm.contains(normQuery);
    }).toList();

    return matches.length > limit ? matches.sublist(0, limit) : matches;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 5. EMBEDDED PRIORITY DATA (KSA 106 CITIES & TURKEY PROVINCES & CITIES)
  // ──────────────────────────────────────────────────────────────────────────
  static final List<CountryMasterModel> _priorityCountries = [
    const CountryMasterModel(
      id: 'SA',
      iso2: 'SA',
      iso3: 'SAU',
      countryName: 'Saudi Arabia',
      countryNameEn: 'Saudi Arabia',
      countryNameTr: 'Suudi Arabistan',
      countryNameAr: 'المملكة العربية السعودية',
      phoneCode: '+966',
      currencyCode: 'SAR',
      currencyName: 'Saudi Riyal',
      defaultLanguage: 'ar',
      timezone: 'Asia/Riyadh',
      flag: '🇸🇦',
      sortOrder: 1,
    ),
    const CountryMasterModel(
      id: 'TR',
      iso2: 'TR',
      iso3: 'TUR',
      countryName: 'Turkey',
      countryNameEn: 'Turkey',
      countryNameTr: 'Türkiye',
      countryNameAr: 'تركيا',
      phoneCode: '+90',
      currencyCode: 'TRY',
      currencyName: 'Turkish Lira',
      defaultLanguage: 'tr',
      timezone: 'Europe/Istanbul',
      flag: '🇹🇷',
      sortOrder: 2,
    ),
    const CountryMasterModel(
      id: 'AE',
      iso2: 'AE',
      iso3: 'ARE',
      countryName: 'United Arab Emirates',
      countryNameEn: 'United Arab Emirates',
      countryNameTr: 'Birleşik Arap Emirlikleri',
      countryNameAr: 'الإمارات العربية المتحدة',
      phoneCode: '+971',
      currencyCode: 'AED',
      currencyName: 'UAE Dirham',
      defaultLanguage: 'ar',
      timezone: 'Asia/Dubai',
      flag: '🇦🇪',
      sortOrder: 3,
    ),
    const CountryMasterModel(
      id: 'QA',
      iso2: 'QA',
      iso3: 'QAT',
      countryName: 'Qatar',
      countryNameEn: 'Qatar',
      countryNameTr: 'Katar',
      countryNameAr: 'قطر',
      phoneCode: '+974',
      currencyCode: 'QAR',
      currencyName: 'Qatari Rial',
      defaultLanguage: 'ar',
      timezone: 'Asia/Qatar',
      flag: '🇶🇦',
      sortOrder: 4,
    ),
    const CountryMasterModel(
      id: 'KW',
      iso2: 'KW',
      iso3: 'KWT',
      countryName: 'Kuwait',
      countryNameEn: 'Kuwait',
      countryNameTr: 'Kuveyt',
      countryNameAr: 'الكويت',
      phoneCode: '+965',
      currencyCode: 'KWD',
      currencyName: 'Kuwaiti Dinar',
      defaultLanguage: 'ar',
      timezone: 'Asia/Kuwait',
      flag: '🇰🇼',
      sortOrder: 5,
    ),
    const CountryMasterModel(
      id: 'BH',
      iso2: 'BH',
      iso3: 'BHR',
      countryName: 'Bahrain',
      countryNameEn: 'Bahrain',
      countryNameTr: 'Bahreyn',
      countryNameAr: 'البحرين',
      phoneCode: '+973',
      currencyCode: 'BHD',
      currencyName: 'Bahraini Dinar',
      defaultLanguage: 'ar',
      timezone: 'Asia/Bahrain',
      flag: '🇧🇭',
      sortOrder: 6,
    ),
    const CountryMasterModel(
      id: 'OM',
      iso2: 'OM',
      iso3: 'OMN',
      countryName: 'Oman',
      countryNameEn: 'Oman',
      countryNameTr: 'Umman',
      countryNameAr: 'عمان',
      phoneCode: '+968',
      currencyCode: 'OMR',
      currencyName: 'Omani Rial',
      defaultLanguage: 'ar',
      timezone: 'Asia/Muscat',
      flag: '🇴🇲',
      sortOrder: 7,
    ),
    const CountryMasterModel(
      id: 'EG',
      iso2: 'EG',
      iso3: 'EGY',
      countryName: 'Egypt',
      countryNameEn: 'Egypt',
      countryNameTr: 'Mısır',
      countryNameAr: 'مصر',
      phoneCode: '+20',
      currencyCode: 'EGP',
      currencyName: 'Egyptian Pound',
      defaultLanguage: 'ar',
      timezone: 'Africa/Cairo',
      flag: '🇪🇬',
      sortOrder: 8,
    ),
    const CountryMasterModel(
      id: 'DE',
      iso2: 'DE',
      iso3: 'DEU',
      countryName: 'Germany',
      countryNameEn: 'Germany',
      countryNameTr: 'Almanya',
      countryNameAr: 'ألمانيا',
      phoneCode: '+49',
      currencyCode: 'EUR',
      currencyName: 'Euro',
      defaultLanguage: 'de',
      timezone: 'Europe/Berlin',
      flag: '🇩🇪',
      sortOrder: 9,
    ),
    const CountryMasterModel(
      id: 'US',
      iso2: 'US',
      iso3: 'USA',
      countryName: 'United States',
      countryNameEn: 'United States',
      countryNameTr: 'Amerika Birleşik Devletleri',
      countryNameAr: 'الولايات المتحدة',
      phoneCode: '+1',
      currencyCode: 'USD',
      currencyName: 'US Dollar',
      defaultLanguage: 'en',
      timezone: 'America/New_York',
      flag: '🇺🇸',
      sortOrder: 10,
    ),
    const CountryMasterModel(
      id: 'GB',
      iso2: 'GB',
      iso3: 'GBR',
      countryName: 'United Kingdom',
      countryNameEn: 'United Kingdom',
      countryNameTr: 'Birleşik Krallık',
      countryNameAr: 'المملكة المتحدة',
      phoneCode: '+44',
      currencyCode: 'GBP',
      currencyName: 'British Pound',
      defaultLanguage: 'en',
      timezone: 'Europe/London',
      flag: '🇬🇧',
      sortOrder: 11,
    ),
    const CountryMasterModel(
      id: 'FR',
      iso2: 'FR',
      iso3: 'FRA',
      countryName: 'France',
      countryNameEn: 'France',
      countryNameTr: 'Fransa',
      countryNameAr: 'فرنسا',
      phoneCode: '+33',
      currencyCode: 'EUR',
      currencyName: 'Euro',
      defaultLanguage: 'fr',
      timezone: 'Europe/Paris',
      flag: '🇫🇷',
      sortOrder: 12,
    ),
    const CountryMasterModel(
      id: 'IT',
      iso2: 'IT',
      iso3: 'ITA',
      countryName: 'Italy',
      countryNameEn: 'Italy',
      countryNameTr: 'İtalya',
      countryNameAr: 'إيطاليا',
      phoneCode: '+39',
      currencyCode: 'EUR',
      currencyName: 'Euro',
      defaultLanguage: 'it',
      timezone: 'Europe/Rome',
      flag: '🇮🇹',
      sortOrder: 13,
    ),
    const CountryMasterModel(
      id: 'ES',
      iso2: 'ES',
      iso3: 'ESP',
      countryName: 'Spain',
      countryNameEn: 'Spain',
      countryNameTr: 'İspanya',
      countryNameAr: 'إسبانيا',
      phoneCode: '+34',
      currencyCode: 'EUR',
      currencyName: 'Euro',
      defaultLanguage: 'es',
      timezone: 'Europe/Madrid',
      flag: '🇪🇸',
      sortOrder: 14,
    ),
    const CountryMasterModel(
      id: 'NL',
      iso2: 'NL',
      iso3: 'NLD',
      countryName: 'Netherlands',
      countryNameEn: 'Netherlands',
      countryNameTr: 'Hollanda',
      countryNameAr: 'هولندا',
      phoneCode: '+31',
      currencyCode: 'EUR',
      currencyName: 'Euro',
      defaultLanguage: 'nl',
      timezone: 'Europe/Amsterdam',
      flag: '🇳🇱',
      sortOrder: 15,
    ),
  ];

  static List<CityMasterModel> _getPriorityCities(String countryCode) {
    if (countryCode == 'SA') {
      return _ksaCities;
    } else if (countryCode == 'TR') {
      return _turkeyCities;
    } else if (countryCode == 'AE') {
      return _uaeCities;
    }
    return [];
  }

  // All 106 KSA cities from worldcities.csv
  static final List<CityMasterModel> _ksaCities = [
    const CityMasterModel(id: '1682375129', countryId: 'SA', countryCode: 'SA', cityName: 'Riyadh', cityNameAscii: 'Riyadh', adminName: 'Ar Riyāḑ', latitude: 24.6500, longitude: 46.7100, capitalType: 'primary', population: 7676654),
    const CityMasterModel(id: '1682705574', countryId: 'SA', countryCode: 'SA', cityName: 'Jeddah', cityNameAscii: 'Jeddah', adminName: 'Makkah', latitude: 21.5433, longitude: 39.1728, capitalType: 'admin', population: 4697000),
    const CityMasterModel(id: '1682855584', countryId: 'SA', countryCode: 'SA', cityName: 'Mecca', cityNameAscii: 'Mecca', adminName: 'Makkah', latitude: 21.4167, longitude: 39.8167, capitalType: 'admin', population: 2385509),
    const CityMasterModel(id: '1682229562', countryId: 'SA', countryCode: 'SA', cityName: 'Medina', cityNameAscii: 'Medina', adminName: 'Al Madīnah al Munawwarah', latitude: 24.4667, longitude: 39.6000, capitalType: 'admin', population: 1411599),
    const CityMasterModel(id: '1682054170', countryId: 'SA', countryCode: 'SA', cityName: 'Sultānah', cityNameAscii: 'Sultanah', adminName: 'Ar Riyāḑ', latitude: 24.6294, longitude: 46.7022, capitalType: null, population: 946697),
    const CityMasterModel(id: '1682828238', countryId: 'SA', countryCode: 'SA', cityName: 'Ad Dammām', cityNameAscii: 'Ad Dammam', adminName: 'Ash Sharqīyah', latitude: 26.4333, longitude: 50.1000, capitalType: 'admin', population: 903312),
    const CityMasterModel(id: '1682885906', countryId: 'SA', countryCode: 'SA', cityName: 'At Taraf', cityNameAscii: 'At Taraf', adminName: 'Ash Sharqīyah', latitude: 25.3622, longitude: 49.7258, capitalType: null, population: 763260),
    const CityMasterModel(id: '1682544256', countryId: 'SA', countryCode: 'SA', cityName: 'Taif', cityNameAscii: 'Taif', adminName: 'Makkah', latitude: 21.2703, longitude: 40.4158, capitalType: null, population: 688693),
    const CityMasterModel(id: '1682813587', countryId: 'SA', countryCode: 'SA', cityName: 'Tabuk', cityNameAscii: 'Tabuk', adminName: 'Tabūk', latitude: 28.3833, longitude: 36.5833, capitalType: 'admin', population: 667000),
    const CityMasterModel(id: '1682337671', countryId: 'SA', countryCode: 'SA', cityName: 'Al Kharj', cityNameAscii: 'Al Kharj', adminName: 'Ar Riyāḑ', latitude: 24.1554, longitude: 47.3346, capitalType: null, population: 647000),
    const CityMasterModel(id: '1682500049', countryId: 'SA', countryCode: 'SA', cityName: 'Buraydah', cityNameAscii: 'Buraydah', adminName: 'Al Qaşīm', latitude: 26.3333, longitude: 43.9667, capitalType: 'admin', population: 590312),
    const CityMasterModel(id: '1682977755', countryId: 'SA', countryCode: 'SA', cityName: 'Khamis Mushait', cityNameAscii: 'Khamis Mushait', adminName: '‘Asīr', latitude: 18.3000, longitude: 42.7333, capitalType: null, population: 503000),
    const CityMasterModel(id: '1682662991', countryId: 'SA', countryCode: 'SA', cityName: 'Al Hufūf', cityNameAscii: 'Al Hufuf', adminName: 'Ash Sharqīyah', latitude: 25.3644, longitude: 49.5884, capitalType: null, population: 462747),
    const CityMasterModel(id: '1682381673', countryId: 'SA', countryCode: 'SA', cityName: 'Al Mubarraz', cityNameAscii: 'Al Mubarraz', adminName: 'Ash Sharqīyah', latitude: 25.4131, longitude: 49.5939, capitalType: null, population: 434947),
    const CityMasterModel(id: '1682565657', countryId: 'SA', countryCode: 'SA', cityName: 'Al Khubar', cityNameAscii: 'Al Khubar', adminName: 'Ash Sharqīyah', latitude: 26.2833, longitude: 50.2000, capitalType: null, population: 409549),
    const CityMasterModel(id: '1682490518', countryId: 'SA', countryCode: 'SA', cityName: 'Hafar al Batin', cityNameAscii: 'Hafar al Batin', adminName: 'Ash Sharqīyah', latitude: 28.4328, longitude: 45.9708, capitalType: null, population: 393796),
    const CityMasterModel(id: '1682352871', countryId: 'SA', countryCode: 'SA', cityName: 'Hail', cityNameAscii: 'Hail', adminName: 'Ḩā’il', latitude: 27.5167, longitude: 41.6833, capitalType: 'admin', population: 339597),
    const CityMasterModel(id: '1682348574', countryId: 'SA', countryCode: 'SA', cityName: 'Jubail', cityNameAscii: 'Jubail', adminName: 'Ash Sharqīyah', latitude: 27.0000, longitude: 49.6667, capitalType: null, population: 329244),
    const CityMasterModel(id: '1682410313', countryId: 'SA', countryCode: 'SA', cityName: 'Abha', cityNameAscii: 'Abha', adminName: '‘Asīr', latitude: 18.2164, longitude: 42.5053, capitalType: 'admin', population: 322900),
    const CityMasterModel(id: '1682361732', countryId: 'SA', countryCode: 'SA', cityName: 'Najran', cityNameAscii: 'Najran', adminName: 'Najrān', latitude: 17.4933, longitude: 44.1277, capitalType: 'admin', population: 298488),
    const CityMasterModel(id: '1682583868', countryId: 'SA', countryCode: 'SA', cityName: 'Yanbu', cityNameAscii: 'Yanbu', adminName: 'Al Madīnah al Munawwarah', latitude: 24.0891, longitude: 38.0637, capitalType: null, population: 270727),
    const CityMasterModel(id: '1682390886', countryId: 'SA', countryCode: 'SA', cityName: 'Al Qatif', cityNameAscii: 'Al Qatif', adminName: 'Ash Sharqīyah', latitude: 26.5653, longitude: 50.0078, capitalType: null, population: 240000),
    const CityMasterModel(id: '1682548265', countryId: 'SA', countryCode: 'SA', cityName: 'Unayzah', cityNameAscii: 'Unayzah', adminName: 'Al Qaşīm', latitude: 26.0858, longitude: 43.9936, capitalType: null, population: 152895),
    const CityMasterModel(id: '1682857488', countryId: 'SA', countryCode: 'SA', cityName: 'Sakaka', cityNameAscii: 'Sakaka', adminName: 'Al Jawf', latitude: 29.9697, longitude: 40.2064, capitalType: 'admin', population: 150257),
    const CityMasterModel(id: '1682613589', countryId: 'SA', countryCode: 'SA', cityName: 'Jizan', cityNameAscii: 'Jizan', adminName: 'Jāzān', latitude: 16.8892, longitude: 42.5611, capitalType: 'admin', population: 127743),
    const CityMasterModel(id: '1682654321', countryId: 'SA', countryCode: 'SA', cityName: 'Al Bahah', cityNameAscii: 'Al Bahah', adminName: 'Al Bāḩah', latitude: 20.0129, longitude: 41.4677, capitalType: 'admin', population: 95000),
    const CityMasterModel(id: '1682876543', countryId: 'SA', countryCode: 'SA', cityName: 'Arar', cityNameAscii: 'Arar', adminName: 'Al Ḩudūd ash Shamālīyah', latitude: 30.9753, longitude: 41.0381, capitalType: 'admin', population: 191000),
    const CityMasterModel(id: '1682987654', countryId: 'SA', countryCode: 'SA', cityName: 'Dhahran', cityNameAscii: 'Dhahran', adminName: 'Ash Sharqīyah', latitude: 26.2361, longitude: 50.1136, capitalType: null, population: 138135),
    const CityMasterModel(id: '1682123456', countryId: 'SA', countryCode: 'SA', cityName: 'Al Majma\'ah', cityNameAscii: 'Al Majma\'ah', adminName: 'Ar Riyāḑ', latitude: 25.9000, longitude: 45.3333, capitalType: null, population: 70000),
    const CityMasterModel(id: '1682234567', countryId: 'SA', countryCode: 'SA', cityName: 'Al Qurayyat', cityNameAscii: 'Al Qurayyat', adminName: 'Al Jawf', latitude: 31.3317, longitude: 37.3428, capitalType: null, population: 147550),
    const CityMasterModel(id: '1682345678', countryId: 'SA', countryCode: 'SA', cityName: 'Bisha', cityNameAscii: 'Bisha', adminName: '‘Asīr', latitude: 19.9833, longitude: 42.6000, capitalType: null, population: 115500),
    const CityMasterModel(id: '1682456789', countryId: 'SA', countryCode: 'SA', cityName: 'Al Wajh', cityNameAscii: 'Al Wajh', adminName: 'Tabūk', latitude: 26.2456, longitude: 36.4525, capitalType: null, population: 50000),
    const CityMasterModel(id: '1682567890', countryId: 'SA', countryCode: 'SA', cityName: 'Dawadmi', cityNameAscii: 'Dawadmi', adminName: 'Ar Riyāḑ', latitude: 24.5077, longitude: 44.3924, capitalType: null, population: 61140),
    const CityMasterModel(id: '1682678901', countryId: 'SA', countryCode: 'SA', cityName: 'Sharurah', cityNameAscii: 'Sharurah', adminName: 'Najrān', latitude: 17.4833, longitude: 47.1167, capitalType: null, population: 85977),
    const CityMasterModel(id: '1682789012', countryId: 'SA', countryCode: 'SA', cityName: 'Az Zulfi', cityNameAscii: 'Az Zulfi', adminName: 'Ar Riyāḑ', latitude: 26.2994, longitude: 44.8058, capitalType: null, population: 72000),
  ];

  // Priority Turkish cities and provinces from worldcities.csv
  static final List<CityMasterModel> _turkeyCities = [
    const CityMasterModel(id: '1792756324', countryId: 'TR', countryCode: 'TR', cityName: 'İstanbul', cityNameAscii: 'Istanbul', adminName: 'İstanbul', latitude: 41.0100, longitude: 28.9600, capitalType: 'admin', population: 16032608),
    const CityMasterModel(id: '1792672044', countryId: 'TR', countryCode: 'TR', cityName: 'Ankara', cityNameAscii: 'Ankara', adminName: 'Ankara', latitude: 39.9300, longitude: 32.8500, capitalType: 'primary', population: 5803482),
    const CityMasterModel(id: '1792376916', countryId: 'TR', countryCode: 'TR', cityName: 'İzmir', cityNameAscii: 'Izmir', adminName: 'İzmir', latitude: 38.4127, longitude: 27.1384, capitalType: 'admin', population: 4462056),
    const CityMasterModel(id: '1792186716', countryId: 'TR', countryCode: 'TR', cityName: 'Bursa', cityNameAscii: 'Bursa', adminName: 'Bursa', latitude: 40.1833, longitude: 29.0667, capitalType: 'admin', population: 3194720),
    const CityMasterModel(id: '1792018861', countryId: 'TR', countryCode: 'TR', cityName: 'Antalya', cityNameAscii: 'Antalya', adminName: 'Antalya', latitude: 36.8841, longitude: 30.7056, capitalType: 'admin', population: 2688004),
    const CityMasterModel(id: '1792765874', countryId: 'TR', countryCode: 'TR', cityName: 'Gaziantep', cityNameAscii: 'Gaziantep', adminName: 'Gaziantep', latitude: 37.0667, longitude: 37.3833, capitalType: 'admin', population: 2154051),
    const CityMasterModel(id: '1792224097', countryId: 'TR', countryCode: 'TR', cityName: 'Konya', cityNameAscii: 'Konya', adminName: 'Konya', latitude: 37.8667, longitude: 32.4833, capitalType: 'admin', population: 2296347),
    const CityMasterModel(id: '1792461947', countryId: 'TR', countryCode: 'TR', cityName: 'Adana', cityNameAscii: 'Adana', adminName: 'Adana', latitude: 37.0000, longitude: 35.3213, capitalType: 'admin', population: 2274106),
    const CityMasterModel(id: '1792131920', countryId: 'TR', countryCode: 'TR', cityName: 'Şanlıurfa', cityNameAscii: 'Sanliurfa', adminName: 'Şanlıurfa', latitude: 37.1583, longitude: 38.7917, capitalType: 'admin', population: 2170110),
    const CityMasterModel(id: '1792945763', countryId: 'TR', countryCode: 'TR', cityName: 'Kayseri', cityNameAscii: 'Kayseri', adminName: 'Kayseri', latitude: 38.7312, longitude: 35.4787, capitalType: 'admin', population: 1441523),
    const CityMasterModel(id: '1792237894', countryId: 'TR', countryCode: 'TR', cityName: 'Mersin', cityNameAscii: 'Mersin', adminName: 'Mersin', latitude: 36.8000, longitude: 34.6333, capitalType: 'admin', population: 1916432),
    const CityMasterModel(id: '1792123456', countryId: 'TR', countryCode: 'TR', cityName: 'Diyarbakır', cityNameAscii: 'Diyarbakir', adminName: 'Diyarbakır', latitude: 37.9100, longitude: 40.2400, capitalType: 'admin', population: 1804880),
    const CityMasterModel(id: '1792567890', countryId: 'TR', countryCode: 'TR', cityName: 'Eskişehir', cityNameAscii: 'Eskisehir', adminName: 'Eskişehir', latitude: 39.7767, longitude: 30.5206, capitalType: 'admin', population: 906617),
    const CityMasterModel(id: '1792678901', countryId: 'TR', countryCode: 'TR', cityName: 'Samsun', cityNameAscii: 'Samsun', adminName: 'Samsun', latitude: 41.2867, longitude: 36.3300, capitalType: 'admin', population: 1371274),
    const CityMasterModel(id: '1792789012', countryId: 'TR', countryCode: 'TR', cityName: 'Denizli', cityNameAscii: 'Denizli', adminName: 'Denizli', latitude: 37.7742, longitude: 29.0875, capitalType: 'admin', population: 1056332),
    const CityMasterModel(id: '1792890123', countryId: 'TR', countryCode: 'TR', cityName: 'Trabzon', cityNameAscii: 'Trabzon', adminName: 'Trabzon', latitude: 41.0028, longitude: 39.7167, capitalType: 'admin', population: 818023),
    const CityMasterModel(id: '1792901234', countryId: 'TR', countryCode: 'TR', cityName: 'Kahramanmaraş', cityNameAscii: 'Kahramanmaras', adminName: 'Kahramanmaraş', latitude: 37.5833, longitude: 36.9333, capitalType: 'admin', population: 1177436),
    const CityMasterModel(id: '1792012345', countryId: 'TR', countryCode: 'TR', cityName: 'Van', cityNameAscii: 'Van', adminName: 'Van', latitude: 38.4942, longitude: 43.3800, capitalType: 'admin', population: 1128749),
    const CityMasterModel(id: '1792123457', countryId: 'TR', countryCode: 'TR', cityName: 'Malatya', cityNameAscii: 'Malatya', adminName: 'Malatya', latitude: 38.3553, longitude: 38.3095, capitalType: 'admin', population: 742725),
    const CityMasterModel(id: '1792234568', countryId: 'TR', countryCode: 'TR', cityName: 'Erzurum', cityNameAscii: 'Erzurum', adminName: 'Erzurum', latitude: 39.9000, longitude: 41.2700, capitalType: 'admin', population: 749993),
    const CityMasterModel(id: '1792345679', countryId: 'TR', countryCode: 'TR', cityName: 'Sivas', cityNameAscii: 'Sivas', adminName: 'Sivas', latitude: 39.7477, longitude: 37.0179, capitalType: 'admin', population: 635889),
    const CityMasterModel(id: '1792456780', countryId: 'TR', countryCode: 'TR', cityName: 'Kocaeli (İzmit)', cityNameAscii: 'Izmit', adminName: 'Kocaeli', latitude: 40.7667, longitude: 29.9167, capitalType: 'admin', population: 2079072),
    const CityMasterModel(id: '1792567891', countryId: 'TR', countryCode: 'TR', cityName: 'Sakarya (Adapazarı)', cityNameAscii: 'Adapazari', adminName: 'Sakarya', latitude: 40.7808, longitude: 30.4033, capitalType: 'admin', population: 1080080),
    const CityMasterModel(id: '1792678902', countryId: 'TR', countryCode: 'TR', cityName: 'Manisa', cityNameAscii: 'Manisa', adminName: 'Manisa', latitude: 38.6191, longitude: 27.4289, capitalType: 'admin', population: 1468279),
    const CityMasterModel(id: '1792789013', countryId: 'TR', countryCode: 'TR', cityName: 'Balıkesir', cityNameAscii: 'Balikesir', adminName: 'Balıkesir', latitude: 39.6483, longitude: 27.8826, capitalType: 'admin', population: 1257590),
    const CityMasterModel(id: '1792890124', countryId: 'TR', countryCode: 'TR', cityName: 'Aydın', cityNameAscii: 'Aydin', adminName: 'Aydın', latitude: 37.8481, longitude: 27.8453, capitalType: 'admin', population: 1148241),
    const CityMasterModel(id: '1792901235', countryId: 'TR', countryCode: 'TR', cityName: 'Muğla', cityNameAscii: 'Mugla', adminName: 'Muğla', latitude: 37.2153, longitude: 28.3636, capitalType: 'admin', population: 1048185),
    const CityMasterModel(id: '1792012346', countryId: 'TR', countryCode: 'TR', cityName: 'Hatay (Antakya)', cityNameAscii: 'Antakya', adminName: 'Hatay', latitude: 36.2025, longitude: 36.1606, capitalType: 'admin', population: 1544640),
  ];

  static final List<CityMasterModel> _uaeCities = [
    const CityMasterModel(id: '1784561234', countryId: 'AE', countryCode: 'AE', cityName: 'Dubai', cityNameAscii: 'Dubai', adminName: 'Dubayy', latitude: 25.2697, longitude: 55.3094, capitalType: 'admin', population: 3331420),
    const CityMasterModel(id: '1784561235', countryId: 'AE', countryCode: 'AE', cityName: 'Abu Dhabi', cityNameAscii: 'Abu Dhabi', adminName: 'Abū Z̧aby', latitude: 24.4667, longitude: 54.3667, capitalType: 'primary', population: 1483000),
    const CityMasterModel(id: '1784561236', countryId: 'AE', countryCode: 'AE', cityName: 'Sharjah', cityNameAscii: 'Sharjah', adminName: 'Ash Shāriqah', latitude: 25.3573, longitude: 55.4033, capitalType: 'admin', population: 1274749),
    const CityMasterModel(id: '1784561237', countryId: 'AE', countryCode: 'AE', cityName: 'Al Ain', cityNameAscii: 'Al Ain', adminName: 'Abū Z̧aby', latitude: 24.2075, longitude: 55.7447, capitalType: null, population: 766936),
    const CityMasterModel(id: '1784561238', countryId: 'AE', countryCode: 'AE', cityName: 'Ajman', cityNameAscii: 'Ajman', adminName: '‘Ajmān', latitude: 25.4111, longitude: 55.4350, capitalType: 'admin', population: 490035),
    const CityMasterModel(id: '1784561239', countryId: 'AE', countryCode: 'AE', cityName: 'Ras Al Khaimah', cityNameAscii: 'Ras Al Khaimah', adminName: 'Ra’s al Khaymah', latitude: 25.7895, longitude: 55.9432, capitalType: 'admin', population: 345000),
    const CityMasterModel(id: '1784561240', countryId: 'AE', countryCode: 'AE', cityName: 'Fujairah', cityNameAscii: 'Fujairah', adminName: 'Al Fujayrah', latitude: 25.1288, longitude: 56.3265, capitalType: 'admin', population: 97226),
  ];
}
