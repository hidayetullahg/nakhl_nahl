import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// NAKHL&NAHL ERP — Navigasyon Öğe Modeli
class NavigationItem {
  final String key;
  final String label;
  final IconData icon;
  final String? badge;
  final String route;

  const NavigationItem({
    required this.key,
    required this.label,
    required this.icon,
    this.badge,
    required this.route,
  });
}

/// NAKHL&NAHL ERP — Sol Kenar Çubuğu (Enterprise Sidebar)
class AppSidebar extends StatelessWidget {
  final bool isCollapsed;
  final String selectedKey;
  final ValueChanged<String> onSelect;
  final VoidCallback onToggleCollapse;

  const AppSidebar({
    super.key,
    required this.isCollapsed,
    required this.selectedKey,
    required this.onSelect,
    required this.onToggleCollapse,
  });

  static const List<NavigationItem> mainMenuItems = [
    NavigationItem(key: 'dashboard', label: 'Ana Sayfa', icon: Icons.dashboard_outlined, route: '/dashboard'),
    NavigationItem(key: 'finans', label: 'Finans', icon: Icons.account_balance_wallet_outlined, route: '/finans'),
    NavigationItem(key: 'satis', label: 'Satış', icon: Icons.point_of_sale_outlined, route: '/satis'),
    NavigationItem(key: 'satinalma', label: 'Satın Alma', icon: Icons.shopping_bag_outlined, route: '/satinalma'),
    NavigationItem(key: 'cari', label: 'Cari Kartlar', icon: Icons.people_alt_outlined, route: '/cari'),
    NavigationItem(key: 'stok', label: 'Stok & Depo', icon: Icons.inventory_2_outlined, route: '/stok'),
    NavigationItem(key: 'muhasebe', label: 'Muhasebe', icon: Icons.receipt_long_outlined, route: '/muhasebe'),
    NavigationItem(key: 'lojistik', label: 'Lojistik & Dış Ticaret', icon: Icons.local_shipping_outlined, route: '/lojistik'),
    NavigationItem(key: 'raporlar', label: 'Raporlar', icon: Icons.analytics_outlined, route: '/raporlar'),
    NavigationItem(key: 'strateji', label: 'Strateji & Zihin Haritası', icon: Icons.hub_outlined, route: '/strateji'),
    NavigationItem(key: 'yonetim_sunum', label: 'Yönetim & Ortaklar', icon: Icons.co_present_outlined, route: '/sunum'),
  ];

  static const List<NavigationItem> secondaryMenuItems = [
    NavigationItem(key: 'onaylar', label: 'Onay Merkezi', icon: Icons.fact_check_outlined, badge: '3', route: '/onaylar'),
    NavigationItem(key: 'bildirimler', label: 'Bildirimler', icon: Icons.notifications_none_outlined, route: '/bildirimler'),
    NavigationItem(key: 'ayarlar', label: 'Ayarlar', icon: Icons.settings_outlined, route: '/ayarlar'),
    NavigationItem(key: 'yardim', label: 'Yardım & Eğitim', icon: Icons.help_outline_rounded, route: '/yardim'),
  ];

  @override
  Widget build(BuildContext context) {
    final width = isCollapsed ? 76.0 : 260.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        border: Border(right: BorderSide(color: Colors.white.withOpacity(0.08), width: 1)),
      ),
      child: Column(
        children: [
          // Üst Logo & Başlık Alanı
          Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06), width: 1)),
            ),
            child: Row(
              children: [
                // Hurma / Palm Yaprağı Geometrik Marka İkonu
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.spa_rounded, color: Colors.white, size: 22),
                  ),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NAKHL & NAHL',
                          style: AppTypography.cardTitle(color: Colors.white).copyWith(
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                        ),
                        Text(
                          'GLOBAL ERP SYSTEM',
                          style: AppTypography.caption(color: AppColors.accent).copyWith(
                            letterSpacing: 0.8,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, color: Colors.white70, size: 20),
                    onPressed: onToggleCollapse,
                    tooltip: 'Menüyü Daralt',
                  ),
                ],
              ],
            ),
          ),

          // Menü Öğeleri Listesi
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              children: [
                if (!isCollapsed)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 8, top: 4),
                    child: Text(
                      'ANA MODÜLLER',
                      style: AppTypography.caption(color: Colors.white38).copyWith(letterSpacing: 1.2),
                    ),
                  ),
                ...mainMenuItems.map((item) => _buildNavItem(item)),
                const SizedBox(height: 16),
                if (!isCollapsed)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 8, top: 4),
                    child: Text(
                      'SİSTEM & YÖNETİM',
                      style: AppTypography.caption(color: Colors.white38).copyWith(letterSpacing: 1.2),
                    ),
                  ),
                ...secondaryMenuItems.map((item) => _buildNavItem(item)),
              ],
            ),
          ),

          // Alt Daraltma Butonu (Collapsed durumda ise)
          if (isCollapsed)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: IconButton(
                icon: const Icon(Icons.chevron_right_rounded, color: Colors.white70),
                onPressed: onToggleCollapse,
                tooltip: 'Menüyü Genişlet',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavItem(NavigationItem item) {
    final isSelected = selectedKey == item.key;
    final activeBg = isSelected ? AppColors.secondary.withOpacity(0.9) : Colors.transparent;
    final textColor = isSelected ? Colors.white : Colors.white70;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Tooltip(
        message: isCollapsed ? item.label : '',
        waitDuration: const Duration(milliseconds: 500),
        child: InkWell(
          onTap: () => onSelect(item.key),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 12 : 14,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: activeBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: isSelected ? Colors.white : Colors.white60,
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.label,
                      style: AppTypography.bodyMedium(color: textColor).copyWith(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (item.badge != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.badge!,
                        style: AppTypography.caption(color: Colors.black).copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
