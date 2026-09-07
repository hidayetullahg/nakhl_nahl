import '../services/supabase_service.dart';
import '../core/tenant/tenant_context.dart';

class Product {
  final String id;
  final String tenantId;
  final String companyId;
  final String itemCode;
  final String? barcode;
  final String itemName;
  final String? description;
  final String? categoryId;
  final String categoryName;
  final String baseUnit;
  final String? salesUom;
  final String? purchaseUom;
  final String
      productType; // FINISHED_GOOD, RAW_MATERIAL, TRADING_GOOD, SERVICE
  final bool traceabilityRequired;
  final bool lotRequired;
  final bool halalRequired;
  final bool qualityRequired;
  final double defaultVatRate;
  final double minStockLevel;
  final bool isActive;

  const Product({
    required this.id,
    required this.tenantId,
    required this.companyId,
    required this.itemCode,
    this.barcode,
    required this.itemName,
    this.description,
    this.categoryId,
    required this.categoryName,
    required this.baseUnit,
    this.salesUom,
    this.purchaseUom,
    required this.productType,
    required this.traceabilityRequired,
    required this.lotRequired,
    required this.halalRequired,
    required this.qualityRequired,
    required this.defaultVatRate,
    required this.minStockLevel,
    required this.isActive,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      tenantId: map['tenant_id'] ?? '',
      companyId: map['company_id'] ?? '',
      itemCode: map['item_code'] ?? '',
      barcode: map['barcode'],
      itemName: map['item_name'] ?? '',
      description: map['description'],
      categoryId: map['category_id'],
      categoryName: map['category_name'] ?? 'Hurma',
      baseUnit: map['base_unit'] ?? 'Kg',
      salesUom: map['sales_uom'],
      purchaseUom: map['purchase_uom'],
      productType: map['product_type'] ?? 'FINISHED_GOOD',
      traceabilityRequired: map['traceability_required'] ?? true,
      lotRequired: map['lot_required'] ?? true,
      halalRequired: map['halal_required'] ?? true,
      qualityRequired: map['quality_required'] ?? true,
      defaultVatRate: (map['default_vat_rate'] as num?)?.toDouble() ?? 15.0,
      minStockLevel: (map['min_stock_level'] as num?)?.toDouble() ?? 0.0,
      isActive: map['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tenant_id': tenantId,
      'company_id': companyId,
      'item_code': itemCode,
      'barcode': barcode,
      'item_name': itemName,
      'description': description,
      'category_id': categoryId,
      'category_name': categoryName,
      'base_unit': baseUnit,
      'sales_uom': salesUom,
      'purchase_uom': purchaseUom,
      'product_type': productType,
      'traceability_required': traceabilityRequired,
      'lot_required': lotRequired,
      'halal_required': halalRequired,
      'quality_required': qualityRequired,
      'default_vat_rate': defaultVatRate,
      'min_stock_level': minStockLevel,
      'is_active': isActive,
    };
  }
}

class ProductRepository {
  ProductRepository._();
  static final ProductRepository instance = ProductRepository._();

  /// Şirkete ait ürünleri listeler
  Future<List<Product>> getProducts(String companyId,
      {bool onlyActive = true}) async {
    try {
      var query = SupabaseService.client
          .from('items')
          .select()
          .eq('company_id', companyId);

      if (onlyActive) {
        query = query.eq('is_active', true);
      }

      final response = await query.order('item_code', ascending: true);
      return (response as List<dynamic>)
          .map((m) => Product.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Barkod veya kod ile ürün arar
  Future<Product?> findByCodeOrBarcode(
      String companyId, String codeOrBarcode) async {
    try {
      final term = codeOrBarcode.trim();
      final response = await SupabaseService.client
          .from('items')
          .select()
          .eq('company_id', companyId)
          .or('item_code.eq.$term,barcode.eq.$term')
          .maybeSingle();

      if (response != null) {
        return Product.fromMap(response);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Yeni ürün kaydeder
  Future<Product?> createProduct({
    required String companyId,
    required String itemCode,
    String? barcode,
    required String itemName,
    String? description,
    String? categoryId,
    String categoryName = 'Hurma',
    String baseUnit = 'Kg',
    String? salesUom,
    String? purchaseUom,
    String productType = 'FINISHED_GOOD',
    bool traceabilityRequired = true,
    bool lotRequired = true,
    bool halalRequired = true,
    bool qualityRequired = true,
    double defaultVatRate = 15.0,
    double minStockLevel = 0.0,
  }) async {
    try {
      final tenantId = TenantContext.instance.activeTenantId;
      if (tenantId == null) throw Exception('Aktif tenant seçilmedi.');

      final response = await SupabaseService.client
          .from('items')
          .insert({
            'tenant_id': tenantId,
            'company_id': companyId,
            'item_code': itemCode.toUpperCase().trim(),
            'barcode': barcode?.trim(),
            'item_name': itemName.trim(),
            'description': description?.trim(),
            'category_id': categoryId,
            'category_name': categoryName.trim(),
            'base_unit': baseUnit.trim(),
            'sales_uom': salesUom,
            'purchase_uom': purchaseUom,
            'product_type': productType,
            'traceability_required': traceabilityRequired,
            'lot_required': lotRequired,
            'halal_required': halalRequired,
            'quality_required': qualityRequired,
            'default_vat_rate': defaultVatRate,
            'min_stock_level': minStockLevel,
          })
          .select()
          .single();

      return Product.fromMap(response);
    } catch (_) {
      return null;
    }
  }
}
