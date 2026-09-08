import 'package:decimal/decimal.dart';

import 'money.dart';

class ExchangeRateQuote {
  final String fromCurrency;
  final String toCurrency;
  final Decimal rate;
  final DateTime rateDate;
  final String source;

  const ExchangeRateQuote({
    required this.fromCurrency,
    required this.toCurrency,
    required this.rate,
    required this.rateDate,
    required this.source,
  });
}

class ConvertedMoney {
  final Money money;
  final ExchangeRateQuote quote;

  const ConvertedMoney({required this.money, required this.quote});
}

ConvertedMoney convert(
  Money value,
  String targetCurrency,
  Decimal rate,
  DateTime rateDate, {
  String source = 'UNKNOWN',
}) {
  final target = targetCurrency.toUpperCase();
  final quote = ExchangeRateQuote(
    fromCurrency: value.currencyCode,
    toCurrency: target,
    rate: rate,
    rateDate: rateDate,
    source: source,
  );
  return ConvertedMoney(
    money: Money(value.amount * rate, target).round(),
    quote: quote,
  );
}
