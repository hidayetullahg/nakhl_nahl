import '../services/supabase_service.dart';
import '../core/tenant/tenant_context.dart';

class ProductCategory {
  final String id;
  final String tenantId;
  final String companyId;
  final String? parentId;
  final String code;
  final String name;
  final String? description;
  final bool isActive;

  const ProductCategory({
    required this.id,
    required this.tenantId,
    required this.companyId,
    this.parentId,
    required this.code,
    required this.name,
    this.description,
    required this.isActive,
  });

  factory ProductCategory.fromMap(Map<String, dynamic> map) {
    return ProductCategory(
      id: map['id'] ?? '',
      tenantId: map['tenant_id'] ?? '',
      companyId: map['company_id'] ?? '',
      parentId: map['parent_id'],
      code: map['code'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      isActive: map['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tenant_id': tenantId,
      'company_id': companyId,
      'parent_id': parentId,
      'code': code,
      'name': name,
      'description': description,
      'is_active': isActive,
    };
  }
}

class ProductCategoryRepository {
  ProductCategoryRepository._();
  static final ProductCategoryRepository instance =
      ProductCategoryRepository._();

  /// Şirkete ait ürün kategorilerini hiyerarşik listeler
  Future<List<ProductCategory>> getCategories(String companyId,
      {bool onlyActive = true}) async {
    try {
      var query = SupabaseService.client
          .from('product_categories')
          .select()
          .eq('company_id', companyId);

      if (onlyActive) {
        query = query.eq('is_active', true);
      }

      final response = await query.order('code', ascending: true);
      return (response as List<dynamic>)
          .map((m) => ProductCategory.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Yeni ürün kategorisi ekler
  Future<ProductCategory?> createCategory({
    required String companyId,
    String? parentId,
    required String code,
    required String name,
    String? description,
  }) async {
    try {
      final tenantId = TenantContext.instance.activeTenantId;
      if (tenantId == null) throw Exception('Aktif tenant seçilmedi.');

      final response = await SupabaseService.client
          .from('product_categories')
          .insert({
            'tenant_id': tenantId,
            'company_id': companyId,
            'parent_id': parentId,
            'code': code.toUpperCase().trim(),
            'name': name.trim(),
            'description': description?.trim(),
          })
          .select()
          .single();

      return ProductCategory.fromMap(response);
    } catch (_) {
      return null;
    }
  }
}
