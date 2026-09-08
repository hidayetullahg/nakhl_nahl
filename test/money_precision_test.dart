import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nakhl_nahl/core/money/exchange_rate.dart';
import 'package:nakhl_nahl/core/money/money.dart';

void main() {
  group('Money precision', () {
    test('Decimal arithmetic preserves 0.1 + 0.2 = 0.3', () {
      final result =
          Money.fromString('0.1', 'USD') + Money.fromString('0.2', 'USD');

      expect(result, Money.fromString('0.3', 'USD'));
    });

    test('10,000 amounts of 0.01 sum exactly to 100.00', () {
      var total = Money.zero('USD');
      for (var index = 0; index < 10000; index++) {
        total += Money.fromString('0.01', 'USD');
      }

      expect(total, Money.fromString('100.00', 'USD'));
      expect(total.toMinorUnits(), BigInt.from(10000));
    });

    test('adding different currencies throws', () {
      expect(
        () => Money.fromString('1', 'USD') + Money.fromString('1', 'EUR'),
        throwsA(isA<CurrencyMismatchException>()),
      );
    });

    test('JPY and KWD use their configured decimal scales', () {
      expect(
        Money.fromString('1.5', 'JPY')
            .round(mode: MoneyRounding.halfUp)
            .toMinorUnits(),
        BigInt.from(2),
      );
      expect(
        Money.fromString('2.5', 'JPY')
            .round(mode: MoneyRounding.halfEven)
            .toMinorUnits(),
        BigInt.from(2),
      );
      expect(
        Money.fromString('1.2345', 'KWD')
            .round(mode: MoneyRounding.halfUp)
            .toMinorUnits(),
        BigInt.from(1235),
      );
    });

    test('1,000 journal receipts balance to the smallest unit', () {
      var debit = Money.zero('SAR');
      var credit = Money.zero('SAR');

      for (var index = 1; index <= 1000; index++) {
        final amount = Money.fromMinorUnits(
          BigInt.from((index * 37) % 10000),
          'SAR',
        );
        debit += amount;
        credit += amount;
      }

      expect(debit.toMinorUnits(), credit.toMinorUnits());
      expect(debit, credit);
    });

    test('conversion retains rate, source, and historical date', () {
      final date = DateTime.utc(2026, 9, 8);
      final converted = convert(
        Money.fromString('10.00', 'USD'),
        'SAR',
        Decimal.parse('3.7500'),
        date,
        source: 'CENTRAL_BANK',
      );

      expect(converted.money, Money.fromString('37.50', 'SAR'));
      expect(converted.quote.rate, Decimal.parse('3.7500'));
      expect(converted.quote.source, 'CENTRAL_BANK');
      expect(converted.quote.rateDate, date);
    });
  });
}
