import 'package:flutter/foundation.dart';

/// NAKHL & NAHL — DÖVİZ KURLARI SERVİSİ
/// Piyasa (Market / Reference) kurları ile Muhasebe (Accounting) kurlarını kesin olarak ayıran,
/// sağlayıcı soyutlaması ve önbellek mekanizması sunan kur servisidir.

enum RateStatus {
  live('CANLI'),
  cached('ÖNBELLEK'),
  reference('REFERANS'),
  unavailable('VERİ YOK');

  final String label;
  const RateStatus(this.label);
}

enum RateCategory {
  marketRate('Piyasa / Serbest Piyasa Kuru'),
  accountingRate('Resmi Muhasebe / Defter Kuru'),
  officialCentralBank('Merkez Bankası Gösterge Kuru');

  final String label;
  const RateCategory(this.label);
}

typedef RateQuoteType = RateCategory;

class CurrencyPairQuote {
  final String id;
  final String baseCurrency; // Örn: USD
  final String quoteCurrency; // Örn: SAR
  final double rate;
  final double? changePercent;
  final RateStatus status;
  final RateCategory category;
  final String providerName;
  final DateTime lastUpdated;
  final bool isFavorite;
  final int sortOrder;

  const CurrencyPairQuote({
    required this.id,
    required this.baseCurrency,
    required this.quoteCurrency,
    required this.rate,
    this.changePercent,
    this.status = RateStatus.reference,
    this.category = RateCategory.marketRate,
    required this.providerName,
    required this.lastUpdated,
    this.isFavorite = true,
    this.sortOrder = 0,
  });

  String get pairSymbol => '$baseCurrency / $quoteCurrency';
  String get pair => '$baseCurrency/$quoteCurrency';
  double get midRate => rate;
  RateCategory get quoteType => category;

  CurrencyPairQuote copyWith({
    double? rate,
    double? changePercent,
    RateStatus? status,
    bool? isFavorite,
    int? sortOrder,
    DateTime? lastUpdated,
  }) {
    return CurrencyPairQuote(
      id: id,
      baseCurrency: baseCurrency,
      quoteCurrency: quoteCurrency,
      rate: rate ?? this.rate,
      changePercent: changePercent ?? this.changePercent,
      status: status ?? this.status,
      category: category,
      providerName: providerName,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isFavorite: isFavorite ?? this.isFavorite,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

abstract class ExchangeRateProvider {
  String get providerName;
  Future<List<CurrencyPairQuote>> fetchRates();
}

/// Varsayılan Referans Kur Sağlayıcısı (Piyasa Kurları)
class DefaultReferenceRateProvider implements ExchangeRateProvider {
  @override
  String get providerName => 'SAMA / TCMB / Reference Market Feed';

  @override
  Future<List<CurrencyPairQuote>> fetchRates() async {
    final now = DateTime.now();
    return [
      CurrencyPairQuote(
        id: 'USD_SAR',
        baseCurrency: 'USD',
        quoteCurrency: 'SAR',
        rate: 3.7500,
        changePercent: 0.01,
        status: RateStatus.reference,
        category: RateCategory.marketRate,
        providerName: providerName,
        lastUpdated: now,
        isFavorite: true,
        sortOrder: 0,
      ),
      CurrencyPairQuote(
        id: 'USD_TRY',
        baseCurrency: 'USD',
        quoteCurrency: 'TRY',
        rate: 34.1500,
        changePercent: 0.12,
        status: RateStatus.reference,
        category: RateCategory.marketRate,
        providerName: providerName,
        lastUpdated: now,
        isFavorite: true,
        sortOrder: 1,
      ),
      CurrencyPairQuote(
        id: 'EUR_TRY',
        baseCurrency: 'EUR',
        quoteCurrency: 'TRY',
        rate: 37.8200,
        changePercent: -0.08,
        status: RateStatus.reference,
        category: RateCategory.marketRate,
        providerName: providerName,
        lastUpdated: now,
        isFavorite: true,
        sortOrder: 2,
      ),
      CurrencyPairQuote(
        id: 'EUR_SAR',
        baseCurrency: 'EUR',
        quoteCurrency: 'SAR',
        rate: 4.1450,
        changePercent: 0.04,
        status: RateStatus.reference,
        category: RateCategory.marketRate,
        providerName: providerName,
        lastUpdated: now,
        isFavorite: true,
        sortOrder: 3,
      ),
      CurrencyPairQuote(
        id: 'AED_SAR',
        baseCurrency: 'AED',
        quoteCurrency: 'SAR',
        rate: 1.0210,
        changePercent: 0.00,
        status: RateStatus.reference,
        category: RateCategory.marketRate,
        providerName: providerName,
        lastUpdated: now,
        isFavorite: false,
        sortOrder: 4,
      ),
    ];
  }
}

class ExchangeRateService extends ChangeNotifier {
  ExchangeRateService._() {
    _provider = DefaultReferenceRateProvider();
    refreshRates();
  }
  static final ExchangeRateService instance = ExchangeRateService._();

  late ExchangeRateProvider _provider;
  final List<CurrencyPairQuote> _quotes = [];
  bool _isLoading = false;

  List<CurrencyPairQuote> get quotes => List.unmodifiable(_quotes);
  List<CurrencyPairQuote> get favoriteQuotes =>
      _quotes.where((q) => q.isFavorite).toList();
  bool get isLoading => _isLoading;

  void initializeDefaults() {
    _quotes.clear();
    refreshRates();
    notifyListeners();
  }

  CurrencyPairQuote? getRate(String pair) {
    final clean = pair.replaceAll(' ', '').toUpperCase();
    try {
      return _quotes.firstWhere(
        (q) => '${q.baseCurrency}/${q.quoteCurrency}' == clean || q.id == clean.replaceAll('/', '_'),
      );
    } catch (_) {
      return null;
    }
  }

  void setProvider(ExchangeRateProvider provider) {
    _provider = provider;
    refreshRates();
  }

  Future<void> refreshRates() async {
    _isLoading = true;
    notifyListeners();

    try {
      final fetched = await _provider.fetchRates();
      _quotes.clear();
      _quotes.addAll(fetched);
    } catch (_) {
      // Çevrimdışı fallback: mevcut kurları cached olarak işaretle
      for (int i = 0; i < _quotes.length; i++) {
        _quotes[i] = _quotes[i].copyWith(status: RateStatus.cached);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addCurrencyPair(String base, String quote) {
    final id = '${base.toUpperCase()}_${quote.toUpperCase()}';
    if (_quotes.any((q) => q.id == id)) return;

    _quotes.add(CurrencyPairQuote(
      id: id,
      baseCurrency: base.toUpperCase(),
      quoteCurrency: quote.toUpperCase(),
      rate: 1.0,
      status: RateStatus.reference,
      providerName: _provider.providerName,
      lastUpdated: DateTime.now(),
      sortOrder: _quotes.length,
      isFavorite: true,
    ));
    notifyListeners();
  }

  void removeCurrencyPair(String id) {
    _quotes.removeWhere((q) => q.id == id);
    notifyListeners();
  }

  void toggleFavorite(String id) {
    final index = _quotes.indexWhere((q) => q.id == id);
    if (index != -1) {
      _quotes[index] = _quotes[index].copyWith(
        isFavorite: !_quotes[index].isFavorite,
      );
      notifyListeners();
    }
  }
}
