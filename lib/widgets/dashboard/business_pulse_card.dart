import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/enterprise_ui_components.dart';

/// NAKHL&NAHL ERP — İşletme Sağlığı (Business Pulse) Kartı
/// 
/// Finans (88), Satış (81), Stok (76), Tahsilat (84), Operasyon (79)
/// metriklerinden ağırlıklı olarak hesaplanan kurumsal sağlık skoru.
class BusinessPulseCard extends StatelessWidget {
  final int overallScore;
  final int financeScore;
  final int salesScore;
  final int stockScore;
  final int collectionScore;
  final int operationScore;

  const BusinessPulseCard({
    super.key,
    this.overallScore = 82,
    this.financeScore = 88,
    this.salesScore = 81,
    this.stockScore = 76,
    this.collectionScore = 84,
    this.operationScore = 79,
  });

  @override
  Widget build(BuildContext context) {
    return EnterpriseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.favorite_rounded, color: AppColors.secondary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'İşletme Sağlığı Skoru',
                        style: AppTypography.cardTitle(),
                      ),
                      Text(
                        'Canlı ERP veri akışından hesaplanan kurumsal performans endeksi',
                        style: AppTypography.caption(),
                      ),
                    ],
                  ),
                ],
              ),
              StatusBadge.success(
                label: 'Mükemmel Seviye',
                icon: Icons.verified_rounded,
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Ana Skor ve Metrik İlerleme Çubukları
          Row(
            children: [
              // Sol Yuvarlak / Büyük Skor Göstergesi
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryContainer,
                  border: Border.all(color: AppColors.primary, width: 3),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$overallScore',
                        style: AppTypography.displayLarge(color: AppColors.primary).copyWith(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '/ 100',
                        style: AppTypography.caption(color: AppColors.textSecondary).copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 24),

              // Sağ: 5 Boyutlu Sağlık Kırılımları
              Expanded(
                child: Column(
                  children: [
                    _buildMetricBar('Finansal Güç', financeScore, AppColors.primary),
                    const SizedBox(height: 8),
                    _buildMetricBar('Satış & Büyüme', salesScore, AppColors.secondary),
                    const SizedBox(height: 8),
                    _buildMetricBar('Stok Sağlığı & Devir', stockScore, AppColors.warning),
                    const SizedBox(height: 8),
                    _buildMetricBar('Tahsilat Performansı', collectionScore, AppColors.info),
                    const SizedBox(height: 8),
                    _buildMetricBar('Operasyon & Lojistik', operationScore, AppColors.accentDark),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBar(String label, int score, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: AppTypography.caption(color: AppColors.textPrimary).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100.0,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 32,
          child: Text(
            '$score',
            textAlign: TextAlign.end,
            style: AppTypography.caption(color: AppColors.textPrimary).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
