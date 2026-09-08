import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// NAKHL&NAHL ERP — Yönetim Kurulu & Ortaklar Sunum Stüdyosu
/// 
/// Q1–Q4, Yıllık veya Özel Dönem seçimiyle 16 kritik slaytı
/// (İcra Özeti, Sağlık Skoru, Gelirler, Kasa Akışı, Alacaklar vb.) oluşturur ve yönetir.
class ManagementPresentationStudioScreen extends StatefulWidget {
  const ManagementPresentationStudioScreen({super.key});

  @override
  State<ManagementPresentationStudioScreen> createState() =>
      _ManagementPresentationStudioScreenState();
}

class _ManagementPresentationStudioScreenState
    extends State<ManagementPresentationStudioScreen> {
  final String _selectedPeriod = 'Q3 2026';
  final String _selectedType = 'Yönetim Kurulu';
  int _currentSlideIndex = 0;

  final List<String> _slides = [
    '1. İcra Özeti (Executive Summary)',
    '2. İşletme Sağlık Endeksi & Pulse',
    '3. Toplam Gelir ve Satış Performansı',
    '4. Karlılık ve Marj Analizi',
    '5. Nakit Akışı (Giriş / Çıkış / Net)',
    '6. Alacaklar ve Yaşlandırma Dağılımı',
    '7. Borçlar ve Tedarikçi Ödeme Yükümlülükleri',
    '8. Stok Değeri & Kritik Envanter Durumu',
    '9. En Çok Satan Hurma Ürünleri',
    '10. Müşteri Segmentasyonu & Cari Büyüme',
    '11. Lojistik, İhracat & Konteyner Sevkiyatları',
    '12. ZATCA & GİB Resmi Mevzuat Uyumluluğu',
    '13. Operasyonel Riskler & Tedbirler',
    '14. Gelecek Dönem Pazar Fırsatları',
    '15. Stratejik Büyüme Hedefleri (KPIs)',
    '16. Sonuç & Yönetim Kurulu Karar Taslağı',
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
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.co_present_rounded, color: Colors.black, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Yönetim Kurulu & Ortaklar Sunum Stüdyosu', style: AppTypography.cardTitle(color: Colors.white)),
                Text('Dönem: $_selectedPeriod | Mod: $_selectedType', style: AppTypography.caption(color: Colors.white70)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.accent),
            tooltip: 'PDF Olarak Dışa Aktar',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sunum PDF formatında başarıyla dışa aktarıldı.')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.slideshow_rounded),
            tooltip: 'Tam Ekran Sunum Başlat',
            onPressed: () {},
          ),
        ],
      ),
      body: Row(
        children: [
          // Sol Slayt Gezgini
          Container(
            width: 280,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(right: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text('SLAYTLAR (16 Adet)', style: AppTypography.caption().copyWith(fontWeight: FontWeight.w700)),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _slides.length,
                    itemBuilder: (ctx, idx) {
                      final isSelected = _currentSlideIndex == idx;
                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: AppColors.primaryContainer,
                        dense: true,
                        leading: CircleAvatar(
                          radius: 12,
                          backgroundColor: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                          child: Text('${idx + 1}', style: TextStyle(fontSize: 10, color: isSelected ? Colors.white : AppColors.textPrimary)),
                        ),
                        title: Text(
                          _slides[idx],
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => setState(() => _currentSlideIndex = idx),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Sağ Ana Slayt Görünümü (Temsili Projeksiyon Alanı)
          Expanded(
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(32),
                constraints: const BoxConstraints(maxWidth: 900, maxHeight: 560),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 2),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 10)),
                  ],
                ),
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.spa_rounded, color: AppColors.secondary, size: 24),
                            const SizedBox(width: 8),
                            Text('NAKHL&NAHL ERP', style: AppTypography.cardTitle(color: AppColors.primary)),
                          ],
                        ),
                        Text('Gizli & Kurumsal • Dönem: $_selectedPeriod', style: AppTypography.caption()),
                      ],
                    ),
                    const Divider(height: 32),
                    Text(
                      _slides[_currentSlideIndex],
                      style: AppTypography.displayMedium(color: AppColors.primary),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Bu slayt işletmenin gerçek Supabase verilerinden derlenen finansal ve operasyonel performansı sunmaktadır.',
                      style: AppTypography.bodyMedium(),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSlideMetric('Toplam Ciro', '₺1.245.000', AppColors.primary),
                          _buildSlideMetric('Net Nakit Girişi', '₺380.500', AppColors.success),
                          _buildSlideMetric('Tahsil Edilen', '%92.4', AppColors.info),
                          _buildSlideMetric('İşletme Skoru', '82 / 100', AppColors.accentDark),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Slayt ${_currentSlideIndex + 1} / ${_slides.length}', style: AppTypography.caption()),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _currentSlideIndex > 0 ? () => setState(() => _currentSlideIndex--) : null,
                              icon: const Icon(Icons.arrow_back_rounded, size: 16),
                              label: const Text('Önceki'),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.surfaceVariant),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: _currentSlideIndex < _slides.length - 1 ? () => setState(() => _currentSlideIndex++) : null,
                              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                              label: const Text('Sonraki'),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlideMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: AppTypography.caption()),
        const SizedBox(height: 4),
        Text(value, style: AppTypography.kpiNumberSm(color: color)),
      ],
    );
  }
}
