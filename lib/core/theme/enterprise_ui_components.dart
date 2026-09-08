import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// NAKHL&NAHL ERP — Yeniden Kullanılabilir Kart Bileşeni
class EnterpriseCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Border? border;
  final double? borderRadius;

  const EnterpriseCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.border,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius ?? AppSpacing.radiusLg),
        border: border ?? Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius ?? AppSpacing.radiusLg),
        child: cardContent,
      );
    }
    return cardContent;
  }
}

/// NAKHL&NAHL ERP — Bölüm Başlığı (Section Header)
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final IconData? icon;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Flexible(
                      child: Text(
                        title,
                        style: AppTypography.sectionTitle(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTypography.secondary(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

/// NAKHL&NAHL ERP — Semantik Durum Rozeti (Status Badge)
/// Yalnızca renkle değil; metin, ikon ve şekille durumu ifade eder.
class StatusBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final Color? backgroundColor;
  final bool isSmall;

  const StatusBadge({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.backgroundColor,
    this.isSmall = false,
  });

  factory StatusBadge.success({required String label, IconData? icon, bool isSmall = false}) {
    return StatusBadge(
      label: label,
      icon: icon ?? Icons.check_circle_outline_rounded,
      color: AppColors.success,
      backgroundColor: AppColors.successLight,
      isSmall: isSmall,
    );
  }

  factory StatusBadge.warning({required String label, IconData? icon, bool isSmall = false}) {
    return StatusBadge(
      label: label,
      icon: icon ?? Icons.warning_amber_rounded,
      color: AppColors.warning,
      backgroundColor: AppColors.warningLight,
      isSmall: isSmall,
    );
  }

  factory StatusBadge.danger({required String label, IconData? icon, bool isSmall = false}) {
    return StatusBadge(
      label: label,
      icon: icon ?? Icons.error_outline_rounded,
      color: AppColors.danger,
      backgroundColor: AppColors.dangerLight,
      isSmall: isSmall,
    );
  }

  factory StatusBadge.info({required String label, IconData? icon, bool isSmall = false}) {
    return StatusBadge(
      label: label,
      icon: icon ?? Icons.info_outline_rounded,
      color: AppColors.info,
      backgroundColor: AppColors.infoLight,
      isSmall: isSmall,
    );
  }

  @override
  Widget build(BuildContext context) {
    final fg = color ?? AppColors.primary;
    final bg = backgroundColor ?? fg.withOpacity(0.12);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? AppSpacing.sm : AppSpacing.md,
        vertical: isSmall ? 3.0 : 6.0,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: fg.withOpacity(0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: isSmall ? 12 : 14, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: isSmall
                ? AppTypography.caption(color: fg).copyWith(fontWeight: FontWeight.w600)
                : AppTypography.badge(color: fg),
          ),
        ],
      ),
    );
  }
}

/// NAKHL&NAHL ERP — Finansal & Operasyonel KPI Kartı
class KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final double? changePercent;
  final String? comparisonPeriod;
  final VoidCallback? onTap;

  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor,
    this.changePercent,
    this.comparisonPeriod = 'Geçen aya göre',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = (changePercent ?? 0) >= 0;
    final trendColor = isPositive ? AppColors.success : AppColors.danger;
    final trendIcon = isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded;

    return EnterpriseCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTypography.secondary().copyWith(fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.primary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(icon, size: 18, color: iconColor ?? AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: AppTypography.kpiNumber(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (changePercent != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(trendIcon, size: 16, color: trendColor),
                const SizedBox(width: 4),
                Text(
                  '${isPositive ? '+' : ''}${changePercent!.toStringAsFixed(1)}%',
                  style: AppTypography.caption(color: trendColor).copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    comparisonPeriod ?? '',
                    style: AppTypography.caption(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
