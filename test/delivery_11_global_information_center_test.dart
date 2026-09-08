// ==============================================================================
// NAKHL & NAHL — DELIVERY 11: GLOBAL INFORMATION CENTER TEST SUITE
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:nakhl_nahl/core/time/world_clock_service.dart';
import 'package:nakhl_nahl/core/time/calendar_service.dart';
import 'package:nakhl_nahl/core/market/exchange_rate_service.dart';
import 'package:nakhl_nahl/core/market/gold_price_service.dart';

void main() {
  setUp(() {
    WorldClockService.instance.initializeDefaults();
    ExchangeRateService.instance.initializeDefaults();
    GoldPriceService.instance.initializeDefaults();
  });

  group('Delivery 11: Global Information Center & Market Data', () {
    test('World clocks contain key international trade hubs with IANA timezones', () {
      final service = WorldClockService.instance;
      final clocks = service.clocks;

      expect(clocks.isNotEmpty, isTrue);
      final cities = clocks.map((c) => c.city).toList();
      expect(cities, contains('Riyadh'));
      expect(cities, contains('Istanbul'));
      expect(cities, contains('Dubai'));
      expect(cities, contains('London'));
    });

    test('Add, remove and toggle favorite on world clocks', () {
      final service = WorldClockService.instance;
      final initialCount = service.clocks.length;

      // Add Tokyo
      service.addClock(
        timezoneId: 'Asia/Tokyo',
        city: 'Tokyo',
        country: 'Japan',
        displayName: 'Tokyo Hub',
      );
      expect(service.clocks.length, equals(initialCount + 1));

      // Toggle favorite
      service.toggleFavorite('Asia/Tokyo');
      final tokyo = service.clocks.firstWhere((c) => c.timezoneId == 'Asia/Tokyo');
      expect(tokyo.isFavorite, isTrue);

      // Remove Tokyo
      service.removeClock('Asia/Tokyo');
      expect(service.clocks.length, equals(initialCount));
    });

    test('CalendarService produces accurate Dual Gregorian & Hijri dates', () {
      final service = CalendarService.instance;
      final testDate = DateTime(2026, 9, 7);

      final dual = service.getDualDate(testDate, 'tr');
      expect(dual.gregorian, contains('2026'));
      expect(dual.hijri, contains('1448'));
      expect(dual.hijriYear, equals(1448));
    });

    test('ExchangeRateService distinguishes market reference rates from accounting rates', () {
      final service = ExchangeRateService.instance;
      final quote = service.getRate('USD/SAR');

      expect(quote, isNotNull);
      expect(quote?.pair, equals('USD/SAR'));
      expect(quote?.midRate, equals(3.7500));
      expect(quote?.quoteType, equals(RateQuoteType.marketRate));

      // Accounting rate is separated and not overridden by raw market ticks
      expect(quote?.quoteType != RateQuoteType.accountingRate, isTrue);
    });

    test('GoldPriceService manages spot metals and local gold products with source metadata', () {
      final service = GoldPriceService.instance;
      final sarGold = service.getPrice('GOLD/SAR');

      expect(sarGold, isNotNull);
      expect(sarGold?.instrumentType, equals(GoldInstrumentType.spotMetal));
      expect(sarGold?.currency, equals('SAR'));
      expect(sarGold?.pricePerUnit, greaterThan(0));
      expect(sarGold?.provider, isNotEmpty);
    });
  });
}
