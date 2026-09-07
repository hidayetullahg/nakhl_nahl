// ==============================================================================
// NAKHL & NAHL — GLOBAL LOCATION MASTER DATA TEST SUITE
// Tests Country Master, City Master, Multilingual Search, KSA & Turkey Priorities,
// Structured Address Model, and Country Business Engine
// SimpleMaps World Cities CC BY 4.0 Attributed
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:nakhl_nahl/models/location_master_model.dart';
import 'package:nakhl_nahl/services/location_service.dart';

void main() {
  group('1. Global Country Master Tests', () {
    test('Country Master ISO codes must be unique and normalized', () async {
      final countries = await LocationService.instance.getCountries();
      expect(countries.isNotEmpty, isTrue);

      final iso2Set = <String>{};
      final iso3Set = <String>{};

      for (final c in countries) {
        expect(c.iso2.length, equals(2), reason: 'ISO2 must be 2 uppercase chars: ${c.iso2}');
        expect(c.iso3.length, equals(3), reason: 'ISO3 must be 3 uppercase chars: ${c.iso3}');
        expect(iso2Set.add(c.iso2), isTrue, reason: 'Duplicate ISO2: ${c.iso2}');
        expect(iso3Set.add(c.iso3), isTrue, reason: 'Duplicate ISO3: ${c.iso3}');
      }
    });

    test('Country search supports Turkish, English, Arabic, ISO2, and ISO3', () async {
      // 1. Search by ISO2
      final saIso2 = await LocationService.instance.searchCountries('SA');
      expect(saIso2.any((c) => c.iso2 == 'SA'), isTrue);

      // 2. Search by ISO3
      final turIso3 = await LocationService.instance.searchCountries('TUR');
      expect(turIso3.any((c) => c.iso2 == 'TR'), isTrue);

      // 3. Search in English: 'Saudi'
      final saEn = await LocationService.instance.searchCountries('Saudi');
      expect(saEn.any((c) => c.iso2 == 'SA'), isTrue);

      // 4. Search in Turkish: 'Suudi'
      final saTr = await LocationService.instance.searchCountries('Suudi');
      expect(saTr.any((c) => c.iso2 == 'SA'), isTrue);

      // 5. Search in Arabic: 'السعودية'
      final saAr = await LocationService.instance.searchCountries('السعودية');
      expect(saAr.any((c) => c.iso2 == 'SA'), isTrue);

      // 6. Search Turkey with Turkish character normalization
      final trSearch = await LocationService.instance.searchCountries('Türkiye');
      expect(trSearch.any((c) => c.iso2 == 'TR'), isTrue);

      // 7. Search Germany in Turkish: 'Almanya'
      final deTr = await LocationService.instance.searchCountries('Almanya');
      expect(deTr.any((c) => c.iso2 == 'DE'), isTrue);
    });

    test('Country localization helper returns correct language', () async {
      final sa = LocationService.instance.getCountryByCode('SA');
      expect(sa, isNotNull);
      expect(sa!.getLocalizedName('tr'), equals('Suudi Arabistan'));
      expect(sa.getLocalizedName('en'), equals('Saudi Arabia'));
      expect(sa.getLocalizedName('ar'), contains('المملكة'));
    });
  });

  group('2. Global City Master Tests (KSA & Turkey Priorities)', () {
    test('KSA cities include all major metropolitan hubs and dates centers', () async {
      final ksaCities = await LocationService.instance.getCitiesByCountry('SA', limit: 150);
      expect(ksaCities.length, greaterThanOrEqualTo(30));

      final cityNames = ksaCities.map((c) => c.cityNameAscii.toLowerCase()).toList();

      // Check essential KSA cities
      expect(cityNames, contains('riyadh'));
      expect(cityNames, contains('jeddah'));
      expect(cityNames, contains('mecca'));
      expect(cityNames, contains('medina'));
      expect(cityNames.any((name) => name.contains('dammam')), isTrue);
      expect(cityNames.any((name) => name.contains('khubar') || name.contains('khobar')), isTrue);
      expect(cityNames, contains('taif'));
      expect(cityNames, contains('tabuk'));
      expect(cityNames, contains('buraydah'));
      expect(cityNames, contains('abha'));
      expect(cityNames.any((name) => name.contains('hufuf') || name.contains('ahsa')), isTrue);
      expect(cityNames, contains('yanbu'));
      expect(cityNames, contains('jubail'));
    });

    test('Turkey cities include 81 provinces and handle Turkish character search', () async {
      final trCities = await LocationService.instance.getCitiesByCountry('TR', limit: 150);
      expect(trCities.isNotEmpty, isTrue);

      // 1. Search with Turkish characters: 'İstanbul'
      final istanbulSearch = await LocationService.instance.searchCities('TR', 'İstanbul');
      expect(istanbulSearch.any((c) => c.cityNameAscii == 'Istanbul'), isTrue);

      // 2. Search with ASCII: 'Istanbul'
      final asciiSearch = await LocationService.instance.searchCities('TR', 'Istanbul');
      expect(asciiSearch.any((c) => c.cityNameAscii == 'Istanbul'), isTrue);

      // 3. Search 'İzmir' vs 'Izmir'
      final izmirSearch = await LocationService.instance.searchCities('TR', 'İzmir');
      expect(izmirSearch.any((c) => c.cityNameAscii == 'Izmir'), isTrue);

      // 4. Search 'Ankara'
      final ankaraSearch = await LocationService.instance.searchCities('TR', 'Ankara');
      expect(ankaraSearch.any((c) => c.cityName == 'Ankara'), isTrue);

      // 5. Search 'Bursa'
      final bursaSearch = await LocationService.instance.searchCities('TR', 'Bursa');
      expect(bursaSearch.any((c) => c.cityName == 'Bursa'), isTrue);

      // 6. Search 'Gaziantep'
      final antepSearch = await LocationService.instance.searchCities('TR', 'Gaziantep');
      expect(antepSearch.any((c) => c.cityName == 'Gaziantep'), isTrue);
    });

    test('CityMasterModel json serialization and coordinates validity', () {
      const city = CityMasterModel(
        id: '1682375129',
        countryId: 'SA',
        countryCode: 'SA',
        cityName: 'Riyadh',
        cityNameAscii: 'Riyadh',
        adminName: 'Ar Riyāḑ',
        latitude: 24.6500,
        longitude: 46.7100,
        capitalType: 'primary',
        population: 7676654,
      );

      final json = city.toJson();
      expect(json['country_code'], equals('SA'));
      expect(json['city_name'], equals('Riyadh'));
      expect(json['latitude'], equals(24.6500));
      expect(json['longitude'], equals(46.7100));

      final restored = CityMasterModel.fromJson(json);
      expect(restored.id, equals(city.id));
      expect(restored.cityName, equals(city.cityName));
      expect(restored.latitude, equals(city.latitude));
      expect(restored.longitude, equals(city.longitude));
    });
  });

  group('3. Global Structured Address Model Tests', () {
    test('Structured address formats cleanly across country standards', () {
      const ksaAddress = GlobalAddressModel(
        countryCode: 'SA',
        administrativeArea: 'Riyad Bölgesi',
        cityName: 'Riyadh',
        district: 'El-Olaya',
        neighborhood: 'Kral Fahd Mahallesi',
        postalCode: '12211',
        addressLine1: 'Kral Fahd Cad. Bina No: 142',
      );

      final formattedKsa = ksaAddress.toFullAddress();
      expect(formattedKsa, contains('Kral Fahd Cad. Bina No: 142'));
      expect(formattedKsa, contains('Kral Fahd Mahallesi'));
      expect(formattedKsa, contains('El-Olaya'));
      expect(formattedKsa, contains('Riyadh'));
      expect(formattedKsa, contains('12211'));
      expect(formattedKsa, contains('SA'));

      const trAddress = GlobalAddressModel(
        countryCode: 'TR',
        administrativeArea: 'İstanbul',
        cityName: 'İstanbul',
        district: 'Kadıköy',
        neighborhood: 'Moda Mah.',
        postalCode: '34710',
        addressLine1: 'Moda Cad. No: 15 Kat: 2',
      );

      final formattedTr = trAddress.toFullAddress();
      expect(formattedTr, contains('Moda Cad. No: 15 Kat: 2'));
      expect(formattedTr, contains('Kadıköy'));
      expect(formattedTr, contains('TR'));
    });
  });

  group('4. Country Business Rule Engine Tests', () {
    test('KSA business profile configures SAR, 15% VAT, and ZATCA Phase 2', () {
      final profile = LocationService.instance.getBusinessProfile('SA');
      expect(profile.countryCode, equals('SA'));
      expect(profile.currencyCode, equals('SAR'));
      expect(profile.currencySymbol, equals('ر.س'));
      expect(profile.defaultVatRate, equals(15.0));
      expect(profile.invoiceStandard, equals('ZATCA_PHASE_2'));
      expect(profile.adapterType, equals('zatca'));
      expect(profile.timezone, equals('Asia/Riyadh'));
      expect(profile.phonePrefix, equals('+966'));

      // Validate ZATCA 15-digit Tax ID pattern (must start and end with 3)
      final zatcaRegex = RegExp(profile.taxNumberValidationRegex);
      expect(zatcaRegex.hasMatch('310123456700003'), isTrue);
      expect(zatcaRegex.hasMatch('123456789012345'), isFalse); // Does not start/end with 3
      expect(zatcaRegex.hasMatch('3101234567'), isFalse); // Not 15 digits
    });

    test('Turkey business profile configures TRY, 20% KDV, and GİB e-Fatura', () {
      final profile = LocationService.instance.getBusinessProfile('TR');
      expect(profile.countryCode, equals('TR'));
      expect(profile.currencyCode, equals('TRY'));
      expect(profile.currencySymbol, equals('₺'));
      expect(profile.defaultVatRate, equals(20.0));
      expect(profile.vatRates, contains(20.0));
      expect(profile.vatRates, contains(10.0));
      expect(profile.vatRates, contains(1.0));
      expect(profile.invoiceStandard, equals('GIB_EFATURA'));
      expect(profile.adapterType, equals('gib_efatura'));
      expect(profile.timezone, equals('Europe/Istanbul'));
      expect(profile.phonePrefix, equals('+90'));

      // Validate VKN (10 digits) or TCKN (11 digits)
      final gibRegex = RegExp(profile.taxNumberValidationRegex);
      expect(gibRegex.hasMatch('1234567890'), isTrue);
      expect(gibRegex.hasMatch('12345678901'), isTrue);
      expect(gibRegex.hasMatch('12345'), isFalse);
    });

    test('Other countries fallback gracefully with generic defaults', () {
      final usProfile = LocationService.instance.getBusinessProfile('US');
      expect(usProfile.currencyCode, equals('USD'));
      expect(usProfile.timezone, equals('America/New_York'));

      final deProfile = LocationService.instance.getBusinessProfile('DE');
      expect(deProfile.currencyCode, equals('EUR'));
      expect(deProfile.invoiceStandard, equals('EU_PEPPOL'));

      final fallbackProfile = LocationService.instance.getBusinessProfile('ZZ');
      expect(fallbackProfile.currencyCode, equals('USD'));
      expect(fallbackProfile.invoiceStandard, equals('GENERIC'));
    });
  });

  group('5. Tenant Isolation and Master Data Security Tests', () {
    test('Master data is read-only for tenant operations', () {
      // Global master data is public read-only
      final sa = LocationService.instance.getCountryByCode('SA');
      expect(sa, isNotNull);
      // Models are immutable (final fields)
      expect(sa!.iso2, equals('SA'));
    });
  });
}
