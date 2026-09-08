import 'package:decimal/decimal.dart';

enum MoneyRounding { halfEven, halfUp }

class CurrencyMismatchException implements Exception {
  final String leftCurrency;
  final String rightCurrency;

  const CurrencyMismatchException(this.leftCurrency, this.rightCurrency);

  @override
  String toString() =>
      'Currency mismatch: $leftCurrency cannot be combined with $rightCurrency';
}

class Money implements Comparable<Money> {
  static const Map<String, int> currencyScale = {
    'BHD': 3,
    'IQD': 3,
    'JOD': 3,
    'JPY': 0,
    'KWD': 3,
    'OMR': 3,
    'TND': 3,
    'KRW': 0,
    'SAR': 2,
    'TRY': 2,
    'USD': 2,
    'EUR': 2,
  };

  final Decimal amount;
  final String currencyCode;

  const Money(this.amount, this.currencyCode);

  factory Money.fromString(String value, String currencyCode) {
    return Money(Decimal.parse(value), currencyCode.toUpperCase());
  }

  factory Money.fromMinorUnits(BigInt value, String currencyCode) {
    final code = currencyCode.toUpperCase();
    final scale = decimalsFor(code);
    final divisor = BigInt.from(10).pow(scale);
    final whole = value ~/ divisor;
    final remainder = value.remainder(divisor).abs();
    if (scale == 0) return Money(Decimal.fromInt(whole.toInt()), code);
    final fraction = remainder.toString().padLeft(scale, '0');
    final sign = value.isNegative ? '-' : '';
    return Money.fromString('$sign$whole.$fraction', code);
  }

  factory Money.zero(String currencyCode) =>
      Money(Decimal.zero, currencyCode.toUpperCase());

  static int decimalsFor(String currencyCode) =>
      currencyScale[currencyCode.toUpperCase()] ?? 2;

  Money round({MoneyRounding mode = MoneyRounding.halfEven}) {
    final scale = decimalsFor(currencyCode);
    final scaled = amount.shift(scale);
    final integer = scaled.truncate();
    final remainder = scaled - integer;
    final absoluteRemainder = remainder.abs();
    final half = Decimal.parse('0.5');
    var adjusted = integer;
    if (absoluteRemainder > half ||
        (absoluteRemainder == half &&
            (mode == MoneyRounding.halfUp ||
                integer.remainder(Decimal.fromInt(2)) != Decimal.zero))) {
      adjusted += scaled.sign < 0 ? Decimal.fromInt(-1) : Decimal.fromInt(1);
    }
    return Money(adjusted.shift(-scale), currencyCode);
  }

  BigInt toMinorUnits({MoneyRounding mode = MoneyRounding.halfEven}) {
    final rounded = round(mode: mode);
    return rounded.amount
        .shift(decimalsFor(currencyCode))
        .truncate()
        .toBigInt();
  }

  Money operator +(Money other) {
    _ensureSameCurrency(other);
    return Money(amount + other.amount, currencyCode);
  }

  Money operator -(Money other) {
    _ensureSameCurrency(other);
    return Money(amount - other.amount, currencyCode);
  }

  Money operator *(Decimal scalar) => Money(amount * scalar, currencyCode);

  bool operator <(Money other) {
    _ensureSameCurrency(other);
    return amount < other.amount;
  }

  bool operator >(Money other) {
    _ensureSameCurrency(other);
    return amount > other.amount;
  }

  @override
  int compareTo(Money other) {
    _ensureSameCurrency(other);
    return amount.compareTo(other.amount);
  }

  @override
  bool operator ==(Object other) =>
      other is Money &&
      currencyCode == other.currencyCode &&
      amount == other.amount;

  @override
  int get hashCode => Object.hash(amount, currencyCode);

  @override
  String toString() => '$amount $currencyCode';

  String toStringAsFixed(int fractionDigits) {
    final value = amount.toString();
    final separator = value.indexOf('.');
    if (separator < 0) {
      return '$value.${'0' * fractionDigits}';
    }
    final decimals = value.substring(separator + 1);
    if (decimals.length >= fractionDigits) {
      return value.substring(0, separator + fractionDigits + 1);
    }
    return '$value${'0' * (fractionDigits - decimals.length)}';
  }

  void _ensureSameCurrency(Money other) {
    if (currencyCode != other.currencyCode) {
      throw CurrencyMismatchException(currencyCode, other.currencyCode);
    }
  }
}
