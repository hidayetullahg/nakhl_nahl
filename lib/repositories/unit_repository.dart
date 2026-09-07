import '../services/supabase_service.dart';

class UomCategory {
  final String id; // WEIGHT, VOLUME, COUNT, PACKAGING
  final String name;
  final String? description;

  const UomCategory({
    required this.id,
    required this.name,
    this.description,
  });

  factory UomCategory.fromMap(Map<String, dynamic> map) {
    return UomCategory(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
    );
  }
}

class UnitOfMeasure {
  final String code; // KG, G, TON, L, ML, PCS, BOX, PALLET, CONTAINER
  final String categoryId;
  final String name;
  final String symbol;
  final bool isBaseUnit;
  final bool isActive;

  const UnitOfMeasure({
    required this.code,
    required this.categoryId,
    required this.name,
    required this.symbol,
    required this.isBaseUnit,
    required this.isActive,
  });

  factory UnitOfMeasure.fromMap(Map<String, dynamic> map) {
    return UnitOfMeasure(
      code: map['code'] ?? '',
      categoryId: map['category_id'] ?? '',
      name: map['name'] ?? '',
      symbol: map['symbol'] ?? '',
      isBaseUnit: map['is_base_unit'] ?? false,
      isActive: map['is_active'] ?? true,
    );
  }
}

class UnitConversion {
  final String id;
  final String fromUnit;
  final String toUnit;
  final double factor;

  const UnitConversion({
    required this.id,
    required this.fromUnit,
    required this.toUnit,
    required this.factor,
  });

  factory UnitConversion.fromMap(Map<String, dynamic> map) {
    return UnitConversion(
      id: map['id'] ?? '',
      fromUnit: map['from_unit'] ?? '',
      toUnit: map['to_unit'] ?? '',
      factor: (map['factor'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

class UnitRepository {
  UnitRepository._();
  static final UnitRepository instance = UnitRepository._();

  /// Tüm UOM kategorilerini listeler
  Future<List<UomCategory>> getCategories() async {
    try {
      final response = await SupabaseService.client
          .from('uom_categories')
          .select()
          .order('id', ascending: true);
      return (response as List<dynamic>)
          .map((m) => UomCategory.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Ölçü birimlerini listeler (Kategoriye göre filtrelenebilir)
  Future<List<UnitOfMeasure>> getUnits(
      {String? categoryId, bool onlyActive = true}) async {
    try {
      var query = SupabaseService.client.from('units').select();
      if (categoryId != null && categoryId.isNotEmpty) {
        query = query.eq('category_id', categoryId);
      }
      if (onlyActive) {
        query = query.eq('is_active', true);
      }
      final response = await query.order('code', ascending: true);
      return (response as List<dynamic>)
          .map((m) => UnitOfMeasure.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// İki birim arasındaki dönüşüm katsayısını hesaplar
  Future<double?> getConversionFactor(String fromUnit, String toUnit) async {
    if (fromUnit == toUnit) return 1.0;
    try {
      final response = await SupabaseService.client
          .from('unit_conversions')
          .select()
          .eq('from_unit', fromUnit)
          .eq('to_unit', toUnit)
          .maybeSingle();

      if (response != null) {
        return (response['factor'] as num?)?.toDouble();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Miktar dönüştür
  Future<double> convert({
    required double quantity,
    required String fromUnit,
    required String toUnit,
  }) async {
    if (fromUnit == toUnit) return quantity;
    final factor = await getConversionFactor(fromUnit, toUnit);
    if (factor != null) {
      return quantity * factor;
    }
    return quantity;
  }
}
