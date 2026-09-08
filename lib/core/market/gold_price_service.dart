import 'package:flutter/foundation.dart';
import 'exchange_rate_service.dart';

/// NAKHL & NAHL — ALTIN VE KIYMETLİ MADEN PİYASA SERVİSİ
/// Spot külçe ons ile yerel gram altın ürünlerini ayıran, sağlayıcı soyutlamalı piyasa servisidir.

enum GoldInstrumentType {
  spotMetal('Spot Ons (Global)'),
  localGoldProduct('Yerel Gram / Ayar Ürünü');

  final String label;
  const GoldInstrumentType(this.label);
}

class GoldPriceQuote {
  final String code; // Örn: XAU_USD, GOLD_GRAM_TRY, GOLD_GRAM_SAR
  final String displayName;
  final GoldInstrumentType type;
  final String currency; // USD, TRY, SAR
  final String unit; // Ounce, Gram, Kilo
  final double price;
  final double? changePercent;
  final RateStatus status;
  final String providerName;
  final DateTime lastUpdated;
  final bool isFavorite;

  const GoldPriceQuote({
    required this.code,
    required this.displayName,
    required this.type,
    required this.currency,
    required this.unit,
    required this.price,
    this.changePercent,
    this.status = RateStatus.reference,
    required this.providerName,
    required this.lastUpdated,
    this.isFavorite = true,
  });

  GoldInstrumentType get instrumentType => type;
  double get pricePerUnit => price;
  String get provider => providerName;

  GoldPriceQuote copyWith({
    double? price,
    double? changePercent,
    RateStatus? status,
    bool? isFavorite,
    DateTime? lastUpdated,
  }) {
    return GoldPriceQuote(
      code: code,
      displayName: displayName,
      type: type,
      currency: currency,
      unit: unit,
      price: price ?? this.price,
      changePercent: changePercent ?? this.changePercent,
      status: status ?? this.status,
      providerName: providerName,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

abstract class GoldPriceProvider {
  String get providerName;
  Future<List<GoldPriceQuote>> fetchGoldQuotes();
}

class DefaultGoldPriceProvider implements GoldPriceProvider {
  @override
  String get providerName => 'Global Bullion & Market Reference Feed';

  @override
  Future<List<GoldPriceQuote>> fetchGoldQuotes() async {
    final now = DateTime.now();
    return [
      GoldPriceQuote(
        code: 'XAU_USD',
        displayName: 'Spot Altın (Ons)',
        type: GoldInstrumentType.spotMetal,
        currency: 'USD',
        unit: 'Ons (oz)',
        price: 2505.40,
        changePercent: 0.35,
        status: RateStatus.reference,
        providerName: providerName,
        lastUpdated: now,
        isFavorite: true,
      ),
      GoldPriceQuote(
        code: 'XAU_SAR',
        displayName: 'Spot Altın (Ons SAR)',
        type: GoldInstrumentType.spotMetal,
        currency: 'SAR',
        unit: 'Ons (oz)',
        price: 9395.25,
        changePercent: 0.35,
        status: RateStatus.reference,
        providerName: providerName,
        lastUpdated: now,
        isFavorite: true,
      ),
      GoldPriceQuote(
        code: 'GOLD_GRAM_SAR',
        displayName: 'Gram Altın 24K (SAR)',
        type: GoldInstrumentType.localGoldProduct,
        currency: 'SAR',
        unit: 'Gram',
        price: 302.15,
        changePercent: 0.28,
        status: RateStatus.reference,
        providerName: providerName,
        lastUpdated: now,
        isFavorite: true,
      ),
      GoldPriceQuote(
        code: 'GOLD_GRAM_TRY',
        displayName: 'Gram Altın 24K (TRY)',
        type: GoldInstrumentType.localGoldProduct,
        currency: 'TRY',
        unit: 'Gram',
        price: 2750.80,
        changePercent: 0.42,
        status: RateStatus.reference,
        providerName: providerName,
        lastUpdated: now,
        isFavorite: true,
      ),
      GoldPriceQuote(
        code: 'GOLD_22K_SAR',
        displayName: 'Gram Altın 22K (SAR)',
        type: GoldInstrumentType.localGoldProduct,
        currency: 'SAR',
        unit: 'Gram',
        price: 277.00,
        changePercent: 0.25,
        status: RateStatus.reference,
        providerName: providerName,
        lastUpdated: now,
        isFavorite: false,
      ),
    ];
  }
}

class GoldPriceService extends ChangeNotifier {
  GoldPriceService._() {
    _provider = DefaultGoldPriceProvider();
    refreshQuotes();
  }
  static final GoldPriceService instance = GoldPriceService._();

  late GoldPriceProvider _provider;
  final List<GoldPriceQuote> _quotes = [];
  bool _isLoading = false;

  List<GoldPriceQuote> get quotes => List.unmodifiable(_quotes);
  List<GoldPriceQuote> get favoriteQuotes =>
      _quotes.where((q) => q.isFavorite).toList();
  bool get isLoading => _isLoading;

  void initializeDefaults() {
    _quotes.clear();
    refreshQuotes();
    notifyListeners();
  }

  GoldPriceQuote? getPrice(String codeOrPair) {
    final clean = codeOrPair.replaceAll('/', '_').toUpperCase();
    try {
      if (clean == 'GOLD_SAR' || clean == 'XAU_SAR') {
        final spot = _quotes.firstWhere(
          (q) => q.currency == 'SAR' && q.type == GoldInstrumentType.spotMetal,
          orElse: () => _quotes.firstWhere((q) => q.code == 'XAU_SAR'),
        );
        return spot;
      }
      return _quotes.firstWhere((q) =>
          q.code == clean ||
          q.code == codeOrPair ||
          q.displayName.toUpperCase().contains(clean));
    } catch (_) {
      try {
        return _quotes.firstWhere(
            (q) => q.currency.toUpperCase() == clean.split('_').last);
      } catch (_) {
        return _quotes.isNotEmpty ? _quotes.first : null;
      }
    }
  }

  Future<void> refreshQuotes() async {
    _isLoading = true;
    notifyListeners();

    try {
      final fetched = await _provider.fetchGoldQuotes();
      _quotes.clear();
      _quotes.addAll(fetched);
    } catch (_) {
      for (int i = 0; i < _quotes.length; i++) {
        _quotes[i] = _quotes[i].copyWith(status: RateStatus.cached);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleFavorite(String code) {
    final index = _quotes.indexWhere((q) => q.code == code);
    if (index != -1) {
      _quotes[index] = _quotes[index].copyWith(
        isFavorite: !_quotes[index].isFavorite,
      );
      notifyListeners();
    }
  }
}
