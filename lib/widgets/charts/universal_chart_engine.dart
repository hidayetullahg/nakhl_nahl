import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/enterprise_ui_components.dart';

/// Desteklenen Grafik Türleri
enum UniversalChartType {
  line,
  area,
  bar,
  donut,
  heatmap,
  aging,
}

/// Evrensel Veri Serisi Modeli
class ChartDataPoint {
  final String label;
  final double value;
  final double? secondaryValue;
  final String? tooltip;
  final Color? color;

  const ChartDataPoint({
    required this.label,
    required this.value,
    this.secondaryValue,
    this.tooltip,
    this.color,
  });
}

/// NAKHL&NAHL ERP — Evrensel Grafik Motoru (Universal Chart Engine)
/// 
/// Flutter 3.19 uyumlu, sıfır harici bağımlılık gerektiren,
/// CustomPainter tabanlı son derece hızlı, reaktif ve erişilebilir grafik bileşeni.
class UniversalChartEngine extends StatelessWidget {
  final String title;
  final String? subtitle;
  final UniversalChartType type;
  final List<ChartDataPoint> data;
  final double height;
  final Widget? filterWidget;

  const UniversalChartEngine({
    super.key,
    required this.title,
    this.subtitle,
    required this.type,
    required this.data,
    this.height = 240.0,
    this.filterWidget,
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.cardTitle()),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: AppTypography.caption()),
                  ],
                ],
              ),
              if (filterWidget != null) filterWidget!,
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: height,
            width: double.infinity,
            child: _buildChartContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildChartContent(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text('Görüntülenecek veri bulunamadı.', style: AppTypography.secondary()),
      );
    }

    switch (type) {
      case UniversalChartType.line:
      case UniversalChartType.area:
        return _LineAreaChartWidget(data: data, isArea: type == UniversalChartType.area);
      case UniversalChartType.bar:
        return _BarChartWidget(data: data);
      case UniversalChartType.donut:
        return _DonutChartWidget(data: data);
      case UniversalChartType.heatmap:
        return _HeatmapChartWidget(data: data);
      case UniversalChartType.aging:
        return _AgingChartWidget(data: data);
    }
  }
}

// ── 1. Çizgi & Alan Grafiği (Nakit Akışı vb.) ──
class _LineAreaChartWidget extends StatelessWidget {
  final List<ChartDataPoint> data;
  final bool isArea;

  const _LineAreaChartWidget({required this.data, required this.isArea});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _LineChartPainter(data: data, isArea: isArea),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<ChartDataPoint> data;
  final bool isArea;

  _LineChartPainter({required this.data, required this.isArea});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final maxVal = data.map((d) => d.value).reduce((a, b) => a > b ? a : b);
    final minVal = data.map((d) => d.value).reduce((a, b) => a < b ? a : b);
    final range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.fill;

    final path = Path();
    final stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalizedY = (data[i].value - minVal) / range;
      final y = size.height - (normalizedY * (size.height - 30)) - 15;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    if (isArea) {
      final areaPath = Path.from(path)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();

      final areaPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withOpacity(0.25),
            AppColors.primary.withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(areaPath, areaPaint);
    }

    canvas.drawPath(path, linePaint);

    // Noktalar
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalizedY = (data[i].value - minVal) / range;
      final y = size.height - (normalizedY * (size.height - 30)) - 15;
      canvas.drawCircle(Offset(x, y), 4.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ── 2. Bar Grafiği (Satış ve Hedef vb.) ──
class _BarChartWidget extends StatelessWidget {
  final List<ChartDataPoint> data;

  const _BarChartWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxVal = data.map((d) => d.value).reduce((a, b) => a > b ? a : b);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: data.map((d) {
        final heightRatio = maxVal > 0 ? (d.value / maxVal) : 0.0;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '₺${(d.value / 1000).toStringAsFixed(0)}k',
                  style: AppTypography.caption().copyWith(fontSize: 10, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 150 * heightRatio,
                  decoration: BoxDecoration(
                    color: d.color ?? AppColors.secondary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  d.label,
                  style: AppTypography.caption(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── 3. Donut Grafiği (Dağılım) ──
class _DonutChartWidget extends StatelessWidget {
  final List<ChartDataPoint> data;

  const _DonutChartWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    final total = data.map((d) => d.value).fold<double>(0.0, (a, b) => a + b);

    return Row(
      children: [
        Expanded(
          flex: 5,
          child: CustomPaint(
            size: Size.infinite,
            painter: _DonutChartPainter(data: data, total: total),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 6,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: data.map((d) {
              final pct = total > 0 ? (d.value / total * 100).toStringAsFixed(1) : '0';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: d.color ?? AppColors.primary, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(d.label, style: AppTypography.caption(), overflow: TextOverflow.ellipsis)),
                    Text('%$pct', style: AppTypography.caption().copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<ChartDataPoint> data;
  final double total;

  _DonutChartPainter({required this.data, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width < size.height ? size.width : size.height) / 2.2;
    final strokeWidth = radius * 0.35;

    double startAngle = -3.14159 / 2;

    for (int i = 0; i < data.length; i++) {
      final sweepAngle = (data[i].value / total) * 2 * 3.14159;
      final paint = Paint()
        ..color = data[i].color ?? AppColors.chartPalette[i % AppColors.chartPalette.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ── 4. Alacak Yaşlandırma Grafiği (Aging Chart) ──
class _AgingChartWidget extends StatelessWidget {
  final List<ChartDataPoint> data;

  const _AgingChartWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    final total = data.map((d) => d.value).fold<double>(0.0, (a, b) => a + b);

    return Column(
      children: [
        // Yığılmış Çubuk
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 28,
            child: Row(
              children: data.map((d) {
                final flex = (d.value / (total == 0 ? 1 : total) * 1000).toInt();
                return Expanded(
                  flex: flex > 0 ? flex : 1,
                  child: Container(color: d.color ?? AppColors.primary),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Kırılımlar
        Expanded(
          child: ListView(
            children: data.map((d) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: d.color, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Text(d.label, style: AppTypography.caption()),
                      ],
                    ),
                    Text('₺${d.value.toStringAsFixed(0)}', style: AppTypography.caption().copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── 5. Stok Isı Haritası (Heatmap) ──
class _HeatmapChartWidget extends StatelessWidget {
  final List<ChartDataPoint> data;

  const _HeatmapChartWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2.5,
      ),
      itemCount: data.length,
      itemBuilder: (ctx, i) {
        final d = data[i];
        final isCritical = d.value < 20;
        final color = isCritical ? AppColors.danger : (d.value < 50 ? AppColors.warning : AppColors.success);

        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(d.label, style: AppTypography.caption().copyWith(fontWeight: FontWeight.w700), maxLines: 1),
              Text('${d.value.toInt()} Kg Stok', style: AppTypography.caption(color: color).copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        );
      },
    );
  }
}
