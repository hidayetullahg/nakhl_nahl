import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/time/timezone_service.dart';
import '../../core/time/world_clock_service.dart';
import '../../core/time/calendar_service.dart';
import '../../core/market/exchange_rate_service.dart';
import '../../core/market/gold_price_service.dart';
import '../../core/theme/app_theme_tokens.dart';
import '../../core/i18n/locale_script_manager.dart';

class GlobalInformationCenter extends StatefulWidget {
  const GlobalInformationCenter({super.key});

  @override
  State<GlobalInformationCenter> createState() =>
      _GlobalInformationCenterState();
}

class _GlobalInformationCenterState extends State<GlobalInformationCenter> {
  void _showAddTimezoneDialog() {
    final searchController = TextEditingController();
    List<IanaTimeZone> searchResults = TimezoneService.catalog;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final tokens = AppThemeManager.instance.tokens;

            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.public, color: Color(0xFFD4AF37)),
                  SizedBox(width: 8),
                  Text('Dünya Saati / Zaman Dilimi Ekle'),
                ],
              ),
              content: SizedBox(
                width: 450,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        hintText:
                            'Şehir veya IANA bölgesi ara (Örn: Tokyo, London)...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (val) {
                        setDialogState(() {
                          searchResults = TimezoneService.instance.search(val);
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        itemCount: searchResults.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, idx) {
                          final tz = searchResults[idx];
                          final isAlreadyAdded = WorldClockService
                              .instance.clocks
                              .any((c) => c.timeZoneId == tz.id);

                          return ListTile(
                            dense: true,
                            title: Text(tz.cityName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: tokens.textPrimary,
                                )),
                            subtitle: Text('${tz.countryName} (${tz.id})',
                                style: TextStyle(
                                    fontSize: 11, color: tokens.textMuted)),
                            trailing: isAlreadyAdded
                                ? const Chip(
                                    label: Text('Ekli',
                                        style: TextStyle(fontSize: 10)),
                                    padding: EdgeInsets.zero,
                                  )
                                : ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size(60, 32),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                    ),
                                    onPressed: () {
                                      WorldClockService.instance.addClock(
                                          timeZone: tz, isFavorite: true);
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              '✓ ${tz.cityName} saat dilimi eklendi.'),
                                          backgroundColor:
                                              const Color(0xFF10B981),
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                    child: const Text('Ekle'),
                                  ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Kapat'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeManager.instance.tokens;
    final locManager = LocaleScriptManager.instance;

    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.public_rounded, size: 18, color: tokens.primary),
          const SizedBox(width: 8),
          Text(
            locManager.translate('world_clocks',
                defaultValue: 'PİYASA / ZAMAN'),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
              color: tokens.textMuted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: const [
                  _CompactInfoItem(
                      icon: Icons.schedule_rounded, child: _LiveClockWidget()),
                  _CompactInfoItem(
                      icon: Icons.today_rounded, child: _DualCalendarWidget()),
                  _CompactInfoItem(
                      icon: Icons.currency_exchange_rounded,
                      child: _ExchangeRatesMiniCard()),
                  _CompactInfoItem(
                      icon: Icons.workspace_premium_rounded,
                      child: _GoldPriceMiniCard()),
                  _CompactInfoItem(
                      icon: Icons.language_rounded, child: _WorldClocksStrip()),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 18),
            tooltip: 'Saat Dilimi Ekle',
            onPressed: _showAddTimezoneDialog,
          ),
        ],
      ),
    );
  }
}

class _CompactInfoItem extends StatelessWidget {
  final IconData icon;
  final Widget child;

  const _CompactInfoItem({required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 118, maxWidth: 220),
      height: 58,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppThemeManager.instance.tokens.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppThemeManager.instance.tokens.primary),
          const SizedBox(width: 7),
          Flexible(child: child),
        ],
      ),
    );
  }
}

/// Canlı Yerel Saat Widget'ı (Sadece bu widget saniye bazında güncellenir)
class _LiveClockWidget extends StatefulWidget {
  const _LiveClockWidget();

  @override
  State<_LiveClockWidget> createState() => _LiveClockWidgetState();
}

class _LiveClockWidgetState extends State<_LiveClockWidget> {
  late Timer _timer;
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeManager.instance.tokens;
    final timeStr =
        '${_currentTime.hour.toString().padLeft(2, '0')}:${_currentTime.minute.toString().padLeft(2, '0')}:${_currentTime.second.toString().padLeft(2, '0')}';
    final tzId = TimezoneService.instance.detectLocalTimeZoneId();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.surfaceVariant,
        borderRadius: BorderRadius.circular(tokens.borderRadius),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time_filled, size: 14, color: tokens.primary),
              const SizedBox(width: 6),
              Text(
                'YEREL SAAT',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: tokens.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              timeStr,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: tokens.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            tzId,
            style: TextStyle(fontSize: 10, color: tokens.textMuted),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Çift Takvim Widget'ı (Miladi & Hicri)
class _DualCalendarWidget extends StatelessWidget {
  const _DualCalendarWidget();

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeManager.instance.tokens;
    final locManager = LocaleScriptManager.instance;
    final calService = CalendarService.instance;
    final now = DateTime.now();

    final gregStr = calService.formatGregorian(
      now,
      languageCode: locManager.activeLanguageCode,
    );
    final hijri = calService.gregorianToHijri(now);
    final hijriStr = calService.formatHijri(
      hijri,
      languageCode: locManager.activeLanguageCode,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.surfaceVariant,
        borderRadius: BorderRadius.circular(tokens.borderRadius),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month, size: 14, color: tokens.primary),
              const SizedBox(width: 6),
              Text(
                'MİLADİ & HİCRİ TAKVİM',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: tokens.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            gregStr,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: tokens.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            hijriStr,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: tokens.primary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Döviz Kurları Mini Kartı
class _ExchangeRatesMiniCard extends StatelessWidget {
  const _ExchangeRatesMiniCard();

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeManager.instance.tokens;

    return AnimatedBuilder(
      animation: ExchangeRateService.instance,
      builder: (context, _) {
        final quotes = ExchangeRateService.instance.favoriteQuotes;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: tokens.surfaceVariant,
            borderRadius: BorderRadius.circular(tokens.borderRadius),
            border: Border.all(color: tokens.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.currency_exchange,
                          size: 14, color: tokens.primary),
                      const SizedBox(width: 6),
                      Text(
                        'DÖVİZ (PİYASA)',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: tokens.textMuted),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: tokens.primaryContainer,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      'REF',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: tokens.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ...quotes.take(2).map((q) {
                final isPositive = (q.changePercent ?? 0) >= 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        q.pairSymbol,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: tokens.textSecondary,
                        ),
                      ),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Row(
                          children: [
                            Text(
                              q.rate.toStringAsFixed(4),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: tokens.textPrimary,
                              ),
                            ),
                            if (q.changePercent != null) ...[
                              const SizedBox(width: 4),
                              Text(
                                '${isPositive ? "▲" : "▼"} ${q.changePercent!.abs().toStringAsFixed(2)}%',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isPositive
                                      ? tokens.success
                                      : tokens.danger,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

/// Altın Mini Kartı
class _GoldPriceMiniCard extends StatelessWidget {
  const _GoldPriceMiniCard();

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeManager.instance.tokens;

    return AnimatedBuilder(
      animation: GoldPriceService.instance,
      builder: (context, _) {
        final quotes = GoldPriceService.instance.favoriteQuotes;
        final spot = quotes.isNotEmpty ? quotes.first : null;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: tokens.surfaceVariant,
            borderRadius: BorderRadius.circular(tokens.borderRadius),
            border: Border.all(color: tokens.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.monetization_on,
                          size: 14, color: const Color(0xFFD4AF37)),
                      const SizedBox(width: 6),
                      Text(
                        'ALTIN',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: tokens.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (spot != null) ...[
                Text(
                  spot.displayName,
                  style: TextStyle(fontSize: 11, color: tokens.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    children: [
                      Text(
                        '${spot.price.toStringAsFixed(2)} ${spot.currency}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: tokens.textPrimary,
                        ),
                      ),
                      if (spot.changePercent != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          '▲ ${spot.changePercent!}%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: tokens.success,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ] else
                Text(
                  'Veri Alınamıyor',
                  style: TextStyle(fontSize: 11, color: tokens.textMuted),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Dünya Saatleri Şeridi
class _WorldClocksStrip extends StatefulWidget {
  const _WorldClocksStrip();

  @override
  State<_WorldClocksStrip> createState() => _WorldClocksStripState();
}

class _WorldClocksStripState extends State<_WorldClocksStrip> {
  late Timer _clockTimer;

  @override
  void initState() {
    super.initState();
    // Dakikada bir veya 5 saniyede bir dünya saatlerini tazele
    _clockTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeManager.instance.tokens;

    return AnimatedBuilder(
      animation: WorldClockService.instance,
      builder: (context, _) {
        final clocks = WorldClockService.instance.clocks;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: clocks.map((c) {
              final time = c.currentTime;
              final timeFormatted =
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

              return Container(
                margin: const EdgeInsets.only(right: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: tokens.surfaceVariant,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: c.isFavorite ? tokens.primary : tokens.border,
                    width: c.isFavorite ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.cityName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: tokens.textPrimary,
                          ),
                        ),
                        Text(
                          c.countryName,
                          style:
                              TextStyle(fontSize: 10, color: tokens.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        timeFormatted,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: tokens.textPrimary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
