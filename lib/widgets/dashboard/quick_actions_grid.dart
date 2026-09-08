import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/enterprise_ui_components.dart';

/// NAKHL&NAHL ERP — Hızlı İşlemler (Quick Actions) Paneli
///
/// 10 Kritik ERP operasyonunu tek tıkla açar:
/// Tahsilat Al, Ödeme Yap, Satış, Alış, Fatura, Stok Girişi,
/// Cari İşlem, Yeni Müşteri, Yeni Tedarikçi, Yeni Sipariş.
class QuickActionsGrid extends StatelessWidget {
  final Function(String actionKey)? onActionSelected;

  const QuickActionsGrid({super.key, this.onActionSelected});

  static const List<QuickActionItem> actions = [
    QuickActionItem(
        key: 'tahsilat',
        label: 'Tahsilat Al',
        icon: Icons.arrow_downward_rounded,
        color: AppColors.success),
    QuickActionItem(
        key: 'odeme',
        label: 'Ödeme Yap',
        icon: Icons.arrow_upward_rounded,
        color: AppColors.danger),
    QuickActionItem(
        key: 'satis',
        label: 'Yeni Satış',
        icon: Icons.point_of_sale_rounded,
        color: AppColors.primary),
    QuickActionItem(
        key: 'alis',
        label: 'Yeni Alış',
        icon: Icons.shopping_cart_outlined,
        color: AppColors.secondary),
    QuickActionItem(
        key: 'fatura',
        label: 'Fatura Kes',
        icon: Icons.receipt_long_rounded,
        color: AppColors.accentDark),
    QuickActionItem(
        key: 'stok_girisi',
        label: 'Stok Girişi',
        icon: Icons.add_box_outlined,
        color: AppColors.info),
    QuickActionItem(
        key: 'cari_islem',
        label: 'Cari İşlem',
        icon: Icons.swap_horiz_rounded,
        color: Color(0xFF6B7280)),
    QuickActionItem(
        key: 'yeni_musteri',
        label: 'Yeni Müşteri',
        icon: Icons.person_add_alt_1_outlined,
        color: AppColors.secondary),
    QuickActionItem(
        key: 'yeni_tedarikci',
        label: 'Yeni Tedarikçi',
        icon: Icons.storefront_outlined,
        color: AppColors.primary),
    QuickActionItem(
        key: 'yeni_siparis',
        label: 'Yeni Sipariş',
        icon: Icons.assignment_outlined,
        color: AppColors.accentDark),
  ];

  @override
  Widget build(BuildContext context) {
    return EnterpriseCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hızlı İşlemler',
                style: AppTypography.cardTitle(),
              ),
              Text(
                'Sık kullanılan 10 operasyon',
                style: AppTypography.caption(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 980
                  ? 5
                  : constraints.maxWidth >= 620
                      ? 3
                      : 2;
              return GridView.builder(
                itemCount: actions.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.618,
                ),
                itemBuilder: (context, index) =>
                    _buildActionButton(context, actions[index]),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, QuickActionItem item) {
    return InkWell(
      onTap: () => onActionSelected?.call(item.key),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item.icon, size: 16, color: item.color),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                item.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption(color: AppColors.textPrimary)
                    .copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuickActionItem {
  final String key;
  final String label;
  final IconData icon;
  final Color color;

  const QuickActionItem({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
  });
}
