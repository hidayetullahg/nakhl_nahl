import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_breakpoints.dart';
import 'app_sidebar.dart';
import 'app_top_bar.dart';
import 'app_insight_panel.dart';
import '../ai/nakhl_assistant_drawer.dart';

/// NAKHL&NAHL ERP — Ana Uygulama Kabuğu (Responsive AppShell)
/// 
/// Masaüstünde Sol Sidebar (260px) + Üst Bar (68px) + Gövde + Opsiyonel Sağ İçgörü Paneli (320px).
/// Tablet ve Mobilde otomatik daralan/drawer'a dönüşen modern kurumsal düzen.
class AppShell extends StatefulWidget {
  final Widget body;
  final String activeMenuKey;
  final ValueChanged<String>? onMenuSelected;
  final Widget? floatingActionButton;

  const AppShell({
    super.key,
    required this.body,
    this.activeMenuKey = 'dashboard',
    this.onMenuSelected,
    this.floatingActionButton,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _isSidebarCollapsed = false;
  bool _isInsightPanelOpen = false;

  void _handleMenuSelect(String key) {
    if (widget.onMenuSelected != null) {
      widget.onMenuSelected!(key);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = AppBreakpoints.isDesktop(context);
    final isMobile = AppBreakpoints.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        onOpenSearch: () {
          // Global Search Palette açma
          _showCommandPalette(context);
        },
        onOpenAssistant: () {
          // AI Asistan çekmecesini açma
          Scaffold.of(context).openEndDrawer();
        },
        onOpenNotifications: () {
          setState(() {
            _isInsightPanelOpen = !_isInsightPanelOpen;
          });
        },
        onOpenSidebarMobile: !isDesktop
            ? () {
                Scaffold.of(context).openDrawer();
              }
            : null,
      ),
      drawer: !isDesktop
          ? Drawer(
              child: AppSidebar(
                isCollapsed: false,
                selectedKey: widget.activeMenuKey,
                onSelect: (key) {
                  Navigator.pop(context);
                  _handleMenuSelect(key);
                },
                onToggleCollapse: () {},
              ),
            )
          : null,
      endDrawer: const NakhlAssistantDrawer(
        moduleName: 'enterprise_shell',
        screenName: 'main_workspace',
      ),
      body: Row(
        children: [
          // Masaüstü Sol Kenar Çubuğu
          if (isDesktop)
            AppSidebar(
              isCollapsed: _isSidebarCollapsed,
              selectedKey: widget.activeMenuKey,
              onSelect: _handleMenuSelect,
              onToggleCollapse: () {
                setState(() {
                  _isSidebarCollapsed = !_isSidebarCollapsed;
                });
              },
            ),

          // Ana Çalışma Alanı
          Expanded(
            child: widget.body,
          ),

          // Opsiyonel Sağ İçgörü Paneli (Desktop)
          if (isDesktop && _isInsightPanelOpen)
            AppInsightPanel(
              onClose: () {
                setState(() {
                  _isInsightPanelOpen = false;
                });
              },
            ),
        ],
      ),
      bottomNavigationBar: isMobile ? _buildMobileBottomBar() : null,
      floatingActionButton: widget.floatingActionButton,
    );
  }

  Widget _buildMobileBottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: BottomNavigationBar(
        currentIndex: _getMobileNavIndex(widget.activeMenuKey),
        onTap: (index) {
          switch (index) {
            case 0:
              _handleMenuSelect('dashboard');
              break;
            case 1:
              _handleMenuSelect('finans');
              break;
            case 2:
              _handleMenuSelect('satis');
              break;
            case 3:
              _handleMenuSelect('stok');
              break;
            case 4:
              _handleMenuSelect('raporlar');
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Ana Sayfa'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Finans'),
          BottomNavigationBarItem(icon: Icon(Icons.point_of_sale_outlined), label: 'Satış'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Stok'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), label: 'Raporlar'),
        ],
      ),
    );
  }

  int _getMobileNavIndex(String key) {
    switch (key) {
      case 'dashboard':
        return 0;
      case 'finans':
        return 1;
      case 'satis':
        return 2;
      case 'stok':
        return 3;
      case 'raporlar':
        return 4;
      default:
        return 0;
    }
  }

  void _showCommandPalette(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Container(
            width: 600,
            constraints: const BoxConstraints(maxHeight: 480),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 24, offset: const Offset(0, 8)),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: TextField(
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Komut yazın veya arama yapın (ör: Yeni Fatura, Müşteri, Stok)...',
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary),
                    ),
                    onSubmitted: (val) => Navigator.pop(ctx),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(8),
                    children: [
                      _buildCommandItem(ctx, 'Yeni Satış Faturası', Icons.receipt_long_rounded, 'satis'),
                      _buildCommandItem(ctx, 'Yeni Cari Kart Ekle', Icons.person_add_alt_1_rounded, 'cari'),
                      _buildCommandItem(ctx, 'Tahsilat / Ödeme Girişi', Icons.payments_rounded, 'finans'),
                      _buildCommandItem(ctx, 'Stok Girişi & Sayım', Icons.inventory_2_rounded, 'stok'),
                      _buildCommandItem(ctx, 'Yönetim Kurulu Sunumu Oluştur', Icons.co_present_rounded, 'sunum'),
                      _buildCommandItem(ctx, 'Strateji Zihin Haritasını Aç', Icons.hub_rounded, 'strateji'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCommandItem(BuildContext ctx, String title, IconData icon, String targetKey) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
      onTap: () {
        Navigator.pop(ctx);
        _handleMenuSelect(targetKey);
      },
    );
  }
}
