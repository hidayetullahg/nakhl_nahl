import '../services/supabase_service.dart';

class Currency {
  final String code; // SAR, USD, TRY, EUR, AED, PKR
  final String? numericCode;
  final String name;
  final String symbol;
  final int decimalPlaces;
  final bool isActive;

  const Currency({
    required this.code,
    this.numericCode,
    required this.name,
    required this.symbol,
    required this.decimalPlaces,
    required this.isActive,
  });

  factory Currency.fromMap(Map<String, dynamic> map) {
    return Currency(
      code: map['code'] ?? '',
      numericCode: map['numeric_code'],
      name: map['name'] ?? '',
      symbol: map['symbol'] ?? '',
      decimalPlaces: map['decimal_places'] ?? 2,
      isActive: map['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'numeric_code': numericCode,
      'name': name,
      'symbol': symbol,
      'decimal_places': decimalPlaces,
      'is_active': isActive,
    };
  }
}

class CurrencyRepository {
  CurrencyRepository._();
  static final CurrencyRepository instance = CurrencyRepository._();

  /// Desteklenen tüm para birimlerini listeler
  Future<List<Currency>> getCurrencies({bool onlyActive = true}) async {
    try {
      var query = SupabaseService.client.from('currencies').select();
      if (onlyActive) {
        query = query.eq('is_active', true);
      }
      final response = await query.order('code', ascending: true);
      return (response as List<dynamic>)
          .map((m) => Currency.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// ISO koduna göre (örn: SAR, USD) para birimi getirir
  Future<Currency?> getCurrencyByCode(String code) async {
    try {
      final response = await SupabaseService.client
          .from('currencies')
          .select()
          .eq('code', code.toUpperCase().trim())
          .maybeSingle();

      if (response != null) {
        return Currency.fromMap(response);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
