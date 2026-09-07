import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../core/tenant/tenant_context.dart';
import '../core/i18n/locale_script_manager.dart';

class DynamicMenuItem {
  final String id;
  final String moduleCode;
  final String menuKey;
  final String routePath;
  final String iconName;
  final String? requiredPermission;
  final int sortOrder;

  const DynamicMenuItem({
    required this.id,
    required this.moduleCode,
    required this.menuKey,
    required this.routePath,
    required this.iconName,
    this.requiredPermission,
    required this.sortOrder,
  });

  IconData get icon {
    switch (iconName) {
      case 'dashboard_rounded':
        return Icons.dashboard_rounded;
      case 'contacts_rounded':
        return Icons.contacts_rounded;
      case 'account_balance_rounded':
        return Icons.account_balance_rounded;
      case 'inventory_2_rounded':
        return Icons.inventory_2_rounded;
      case 'local_shipping_rounded':
        return Icons.local_shipping_rounded;
      case 'verified_rounded':
        return Icons.verified_rounded;
      case 'assessment_rounded':
        return Icons.assessment_rounded;
      default:
        return Icons.circle_outlined;
    }
  }
}

class NavigationMenuService {
  NavigationMenuService._();
  static final NavigationMenuService instance = NavigationMenuService._();

  /// Tenant'ın aktif modüllerine ve kullanıcının yetkilerine göre menüyü derler
  Future<List<DynamicMenuItem>> getAuthorizedMenuItems() async {
    try {
      final tenantId = TenantContext.instance.activeTenantId;
      if (tenantId == null) return [];

      // 1. Tenant'ın aktif modüllerini çek
      final tenantModulesRes = await SupabaseService.client
          .from('tenant_modules')
          .select('module_code')
          .eq('tenant_id', tenantId)
          .eq('enabled', true);

      final activeModules = (tenantModulesRes as List)
          .map((r) => r['module_code'] as String)
          .toSet();

      // Çekirdek modülleri her zaman aktif say
      activeModules.addAll([
        'DASHBOARD',
        'CARI',
        'ACCOUNTING',
        'INVENTORY',
        'EXPORT',
        'HALAL',
        'REPORTING'
      ]);

      // 2. Menü tanımlarını veritabanından getir
      final menusRes = await SupabaseService.client
          .from('menu_definitions')
          .select()
          .eq('is_visible', true)
          .order('sort_order', ascending: true);

      final List<DynamicMenuItem> list = [];
      for (final row in (menusRes as List<dynamic>)) {
        final modCode = row['module_code'] as String;
        if (activeModules.contains(modCode)) {
          list.add(DynamicMenuItem(
            id: row['id'],
            moduleCode: modCode,
            menuKey: row['menu_key'],
            routePath: row['route_path'],
            iconName: row['icon_name'],
            requiredPermission: row['required_permission'],
            sortOrder: row['sort_order'] ?? 0,
          ));
        }
      }

      return list;
    } catch (e) {
      return [];
    }
  }

  /// Menü başlığını dilden bağımsız yazı sistemine göre dinamik çevirir
  String getMenuTitle(DynamicMenuItem item) {
    return LocaleScriptManager.instance
        .translate(item.menuKey, defaultValue: item.moduleCode);
  }
}
