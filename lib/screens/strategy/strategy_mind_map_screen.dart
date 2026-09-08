import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// NAKHL&NAHL ERP — Strateji ve Zihin Haritası (Strategy Mind Map)
/// 
/// Finans, Satış, Müşteri, Stok, Tedarik, Lojistik, İnsan, Risk ve Hedefler
/// dallarını etkileşimli, taranabilir ve iş odaklı bir hiyerarşide görselleştirir.
class StrategyMindMapScreen extends StatefulWidget {
  const StrategyMindMapScreen({super.key});

  @override
  State<StrategyMindMapScreen> createState() => _StrategyMindMapScreenState();
}

class _StrategyMindMapScreenState extends State<StrategyMindMapScreen> {
  final TransformationController _transController = TransformationController();

  final List<_MindMapBranch> _branches = [
    _MindMapBranch(
      title: 'Finansal Hedefler',
      icon: Icons.account_balance_rounded,
      color: AppColors.primary,
      nodes: [
        'Yıllık Ciro: ₺15.000.000',
        'Nakit Akışı Fazlası: %25',
        'Tahsilat Süresi: < 30 Gün',
      ],
    ),
    _MindMapBranch(
      title: 'Satış & Pazarlama',
      icon: Icons.point_of_sale_rounded,
      color: AppColors.secondary,
      nodes: [
        'Körfez Pazarı Genişlemesi',
        'AB Hurma İhracat Hacmi (+30%)',
        'Yeni Kurumsal Cari Kazanımı',
      ],
    ),
    _MindMapBranch(
      title: 'Stok & Tedarik Zinciri',
      icon: Icons.inventory_2_rounded,
      color: AppColors.warning,
      nodes: [
        'Dammam & Riyad Depo Optimizasyonu',
        'Medjool Parti İzlenebilirliği',
        'Min Stok Fire Oranı: < %1.5',
      ],
    ),
    _MindMapBranch(
      title: 'Resmi Mevzuat & Helal',
      icon: Icons.verified_user_rounded,
      color: AppColors.info,
      nodes: [
        'ZATCA Phase 2 E-Fatura Uyumu',
        'SFDA & TRACES NT Gıda Sertifikasyonu',
        'HAK Akredite Helal Sürekliliği',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.hub_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Strateji / Zihin Haritası', style: AppTypography.cardTitle(color: Colors.white)),
                Text('Hedefler, KPI Bağlantıları & Sorumluluk Ağacı', style: AppTypography.caption(color: Colors.white70)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_out_map_rounded),
            tooltip: 'Görünümü Sıfırla',
            onPressed: () {
              _transController.value = Matrix4.identity();
            },
          ),
        ],
      ),
      body: InteractiveViewer(
        transformationController: _transController,
        boundaryMargin: const EdgeInsets.all(200),
        minScale: 0.5,
        maxScale: 2.5,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Merkez Düğüm (NAKHL&NAHL Core)
              Container(
                width: 200,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.accent, width: 2),
                  boxShadow: [
                    BoxShadow(color: AppColors.primaryDark.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 6)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.spa_rounded, color: AppColors.accent, size: 36),
                    const SizedBox(height: 10),
                    Text(
                      'NAKHL & NAHL',
                      textAlign: TextAlign.center,
                      style: AppTypography.cardTitle(color: Colors.white).copyWith(letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '2026 Stratejik Vizyonu',
                      textAlign: TextAlign.center,
                      style: AppTypography.caption(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 60),

              // Dallar (Stratejik Kollar)
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _branches.map((branch) => _buildBranchWidget(branch)).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBranchWidget(_MindMapBranch branch) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Bağlantı Çizgisi
          Container(width: 40, height: 2, color: branch.color.withOpacity(0.5)),
          const SizedBox(width: 8),

          // Ana Dal Kartı
          Container(
            width: 200,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: branch.color, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(branch.icon, size: 18, color: branch.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    branch.title,
                    style: AppTypography.caption(color: AppColors.textPrimary).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),
          Container(width: 30, height: 2, color: branch.color.withOpacity(0.3)),
          const SizedBox(width: 8),

          // Alt Hedef Düğümleri
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: branch.nodes.map((node) {
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: branch.color, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(node, style: AppTypography.caption()),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _MindMapBranch {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> nodes;

  const _MindMapBranch({
    required this.title,
    required this.icon,
    required this.color,
    required this.nodes,
  });
}
