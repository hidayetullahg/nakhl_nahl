import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// NAKHL&NAHL ERP — Sağ İçgörü Paneli (Business Intelligence & Alerts Drawer)
/// 
/// 300–360px genişlikte; proaktif finansal uyarılar, kritik stoklar,
/// tahsilat alarmları ve bekleyen onayları sunar.
class AppInsightPanel extends StatelessWidget {
  final VoidCallback? onClose;

  const AppInsightPanel({super.key, this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(left: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.insights_rounded, color: AppColors.secondary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'İşletme İçgörüleri',
                      style: AppTypography.cardTitle(),
                    ),
                  ],
                ),
                if (onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                    onPressed: onClose,
                    tooltip: 'Kapat',
                  ),
              ],
            ),
          ),

          // İçerik Listesi
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildInsightCard(
                  title: 'Satışlarda Güçlü Büyüme',
                  description: 'Bu ayki hurma satışları geçen aya göre %21 arttı.',
                  severity: 'success',
                  icon: Icons.trending_up_rounded,
                  actionLabel: 'Satış Raporunu İncele',
                ),
                const SizedBox(height: 12),
                _buildInsightCard(
                  title: 'Kritik Stok Uyarısı',
                  description: 'Medjool ve Sukari 1kg paketlerinde 12 ürün min stok seviyesinin altına indi.',
                  severity: 'danger',
                  icon: Icons.warning_amber_rounded,
                  actionLabel: 'Sipariş Oluştur',
                ),
                const SizedBox(height: 12),
                _buildInsightCard(
                  title: 'Tahsilat Süresi Değişimi',
                  description: 'Alacak tahsil süresi ortalama 36 güne yükseldi (+4 gün).',
                  severity: 'warning',
                  icon: Icons.schedule_rounded,
                  actionLabel: 'Yaşlandırma Tablosu',
                ),
                const SizedBox(height: 12),
                _buildInsightCard(
                  title: 'ZATCA & GİB Senkronizasyonu',
                  description: 'Tüm e-faturalar ve sınır ötesi sevkiyat belgeleri onaylandı.',
                  severity: 'info',
                  icon: Icons.verified_user_outlined,
                  actionLabel: 'Durumu Doğrula',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard({
    required String title,
    required String description,
    required String severity,
    required IconData icon,
    required String actionLabel,
  }) {
    Color accentColor;
    Color bgColor;

    switch (severity) {
      case 'success':
        accentColor = AppColors.success;
        bgColor = AppColors.successLight;
        break;
      case 'warning':
        accentColor = AppColors.warning;
        bgColor = AppColors.warningLight;
        break;
      case 'danger':
        accentColor = AppColors.danger;
        bgColor = AppColors.dangerLight;
        break;
      default:
        accentColor = AppColors.info;
        bgColor = AppColors.infoLight;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: accentColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.caption(color: AppColors.textPrimary).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: AppTypography.secondary(),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel,
                    style: AppTypography.caption(color: AppColors.primary).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
