import 'package:flutter/material.dart';

/// NAKHL&NAHL ERP — Premium Kurumsal Renk Sistemi
/// 
/// Görsel Kimlik:
/// Primary: Deep Petrol / Midnight Teal (#0B4656)
/// Secondary: Palm Green (#287A52)
/// Accent: Warm Amber (#F5A623)
/// Background: Warm Sand (#F7F3EB)
/// Surface: White (#FFFFFF)
/// Text Primary: Deep Cyan/Charcoal (#102A33)
/// Text Secondary: Slate Gray (#60727A)
class AppColors {
  AppColors._();

  // Ana Marka ve Kurumsal Renkler
  static const Color primary = Color(0xFF0B4656); // Deep Petrol / Midnight Teal
  static const Color primaryDark = Color(0xFF062A34);
  static const Color primaryLight = Color(0xFF165C70);
  static const Color primaryContainer = Color(0xFFE2F0F3);

  static const Color secondary = Color(0xFF287A52); // Palm Green
  static const Color secondaryDark = Color(0xFF1B5539);
  static const Color secondaryLight = Color(0xFF389B6B);
  static const Color secondaryContainer = Color(0xFFE4F4EC);

  static const Color accent = Color(0xFFF5A623); // Warm Amber
  static const Color accentDark = Color(0xFFC78112);
  static const Color accentLight = Color(0xFFF8BD56);
  static const Color accentContainer = Color(0xFFFDF3E3);

  // Arka Plan ve Yüzeyler (Sıcak Kum & Temiz Kartlar)
  static const Color background = Color(0xFFF7F3EB); // Warm Sand
  static const Color backgroundDark = Color(0xFF0D1619); // Koyu mod zemin
  static const Color surface = Color(0xFFFFFFFF); // Temiz Kart
  static const Color surfaceDark = Color(0xFF152227); // Koyu mod kart
  static const Color surfaceVariant = Color(0xFFEFEBE2);
  static const Color surfaceVariantDark = Color(0xFF1F3036);

  // Tipografi Renkleri
  static const Color textPrimary = Color(0xFF102A33);
  static const Color textPrimaryDark = Color(0xFFF2F7F8);
  static const Color textSecondary = Color(0xFF60727A);
  static const Color textSecondaryDark = Color(0xFFA0B2B9);
  static const Color textMuted = Color(0xFF8F9FA6);
  static const Color textMutedDark = Color(0xFF677980);

  // Semantik Durum Renkleri (WCAG AA/AAA uyumlu)
  static const Color success = Color(0xFF2E8B57); // Sea Green / Palm Emerald
  static const Color successLight = Color(0xFFEAF6EE);
  static const Color warning = Color(0xFFF5A623); // Warm Amber
  static const Color warningLight = Color(0xFFFFF7EA);
  static const Color danger = Color(0xFFD94A4A); // Crimson Alert
  static const Color dangerLight = Color(0xFFFDF0F0);
  static const Color info = Color(0xFF3B82A0); // Enterprise Ocean
  static const Color infoLight = Color(0xFFEDF5F8);

  // Kenarlık ve Ayırıcılar
  static const Color border = Color(0xFFE2DDD2);
  static const Color borderDark = Color(0xFF283C43);
  static const Color borderLight = Color(0xFFEFECE5);

  // Grafik Paleti (Analytics & Visualizations)
  static const List<Color> chartPalette = [
    Color(0xFF0B4656), // Midnight Teal
    Color(0xFF287A52), // Palm Green
    Color(0xFFF5A623), // Warm Amber
    Color(0xFF3B82A0), // Ocean Cyan
    Color(0xFF8B5CF6), // Royal Purple
    Color(0xFFEC4899), // Rose Pink
    Color(0xFF10B981), // Emerald
    Color(0xFF6366F1), // Indigo
  ];
}

/// 8px Tabanlı Spacing & Radius Standartları
class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 40.0;
  static const double huge = 48.0;

  // Radius Tokenları
  static const double radiusSm = 6.0;
  static const double radiusMd = 10.0;
  static const double radiusLg = 14.0;
  static const double radiusXl = 18.0;
  static const double radiusPill = 999.0;
}
