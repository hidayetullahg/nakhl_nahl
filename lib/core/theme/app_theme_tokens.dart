import 'package:flutter/material.dart';

/// NAKHL & NAHL — KURUMSAL ERP TEMA TOKENS & PALET SİSTEMİ
/// Hard-coded renkleri engelleyen, kurumsal antrasit, kurumsal açık, mavi, yeşil ve yüksek kontrast modlarını yöneten tema sistemi.

enum AppThemeMode {
  corporateDark, // Koyu Antrasit Temel Tema
  corporateLight, // Profesyonel Açık ERP Teması
  neutral, // Nötr Gri & Minimalist Tema
  blueCorporate, // Bankacılık & Finans Kurumsal Mavi
  greenEnterprise, // Tarım, Helal & Sürdürülebilirlik Yeşili
  highContrast, // WCAG AAA Erişilebilirlik Yüksek Kontrast
}

class AppThemeTokens {
  final AppThemeMode mode;
  final String displayName;
  final Color primary;
  final Color primaryContainer;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
  final double borderRadius;
  final double cardElevation;

  const AppThemeTokens({
    required this.mode,
    required this.displayName,
    required this.primary,
    required this.primaryContainer,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    this.borderRadius = 8.0,
    this.cardElevation = 1.0,
  });

  bool get isDark =>
      mode == AppThemeMode.corporateDark || mode == AppThemeMode.highContrast;

  // 1. Corporate Dark (Koyu Antrasit Profesyonel ERP)
  static const AppThemeTokens corporateDark = AppThemeTokens(
    mode: AppThemeMode.corporateDark,
    displayName: 'Corporate Dark (Koyu Antrasit)',
    primary: Color(0xFFD4AF37), // Altın / Hurma Sarısı
    primaryContainer: Color(0xFF2C2416),
    secondary: Color(0xFF90CAF9),
    background: Color(0xFF121418), // Koyu Antrasit Zemin
    surface: Color(0xFF1B1E24), // Yükseltilmiş Kart Yüzeyi
    surfaceVariant: Color(0xFF242831),
    border: Color(0xFF2D323F),
    textPrimary: Color(0xFFF3F4F6),
    textSecondary: Color(0xFF9CA3AF),
    textMuted: Color(0xFF6B7280),
    success: Color(0xFF10B981),
    warning: Color(0xFFF59E0B),
    danger: Color(0xFFEF4444),
    info: Color(0xFF3B82F6),
    borderRadius: 8.0,
    cardElevation: 0.0,
  );

  // 2. Corporate Light (Deep Petrol / Midnight Teal & Warm Sand)
  static const AppThemeTokens corporateLight = AppThemeTokens(
    mode: AppThemeMode.corporateLight,
    displayName: 'Corporate Light (Petrol & Sıcak Kum)',
    primary: Color(0xFF0B4656), // Deep Petrol / Midnight Teal
    primaryContainer: Color(0xFFE2F0F3),
    secondary: Color(0xFF287A52), // Palm Green
    background: Color(0xFFF7F3EB), // Warm Sand
    surface: Color(0xFFFFFFFF), // Temiz Beyaz Kart
    surfaceVariant: Color(0xFFEFEBE2),
    border: Color(0xFFE2DDD2),
    textPrimary: Color(0xFF102A33),
    textSecondary: Color(0xFF60727A),
    textMuted: Color(0xFF8F9FA6),
    success: Color(0xFF2E8B57), // Palm Emerald
    warning: Color(0xFFF5A623), // Warm Amber
    danger: Color(0xFFD94A4A),
    info: Color(0xFF3B82A0),
    borderRadius: 12.0,
    cardElevation: 0.5,
  );

  // 3. Neutral (Minimalist Gri)
  static const AppThemeTokens neutral = AppThemeTokens(
    mode: AppThemeMode.neutral,
    displayName: 'Neutral (Minimal Gri)',
    primary: Color(0xFF374151),
    primaryContainer: Color(0xFFE5E7EB),
    secondary: Color(0xFF4B5563),
    background: Color(0xFFF3F4F6),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFE5E7EB),
    border: Color(0xFFD1D5DB),
    textPrimary: Color(0xFF1F2937),
    textSecondary: Color(0xFF6B7280),
    textMuted: Color(0xFF9CA3AF),
    success: Color(0xFF10B981),
    warning: Color(0xFFF59E0B),
    danger: Color(0xFFEF4444),
    info: Color(0xFF3B82F6),
    borderRadius: 6.0,
    cardElevation: 1.0,
  );

  // 4. Blue Corporate (Finans & Dış Ticaret)
  static const AppThemeTokens blueCorporate = AppThemeTokens(
    mode: AppThemeMode.blueCorporate,
    displayName: 'Blue Corporate (Finans Mavisi)',
    primary: Color(0xFF1E40AF),
    primaryContainer: Color(0xFFDBEAFE),
    secondary: Color(0xFF0284C7),
    background: Color(0xFFF8FAFC),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF1F5F9),
    border: Color(0xFFCBD5E1),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF334155),
    textMuted: Color(0xFF64748B),
    success: Color(0xFF0D9488),
    warning: Color(0xFFD97706),
    danger: Color(0xFFE11D48),
    info: Color(0xFF2563EB),
    borderRadius: 8.0,
    cardElevation: 1.0,
  );

  // 5. Green Enterprise (Tarım, Hasat & Helal)
  static const AppThemeTokens greenEnterprise = AppThemeTokens(
    mode: AppThemeMode.greenEnterprise,
    displayName: 'Green Enterprise (Tarım & Helal)',
    primary: Color(0xFF166534),
    primaryContainer: Color(0xFFDCFCE7),
    secondary: Color(0xFF854D0E),
    background: Color(0xFFF7FDF9),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF0FDF4),
    border: Color(0xFFBBF7D0),
    textPrimary: Color(0xFF14532D),
    textSecondary: Color(0xFF166534),
    textMuted: Color(0xFF4ADE80),
    success: Color(0xFF15803D),
    warning: Color(0xFFCA8A04),
    danger: Color(0xFFB91C1C),
    info: Color(0xFF0284C7),
    borderRadius: 8.0,
    cardElevation: 1.0,
  );

  // 6. High Contrast (Yüksek Kontrast & Erişilebilirlik)
  static const AppThemeTokens highContrast = AppThemeTokens(
    mode: AppThemeMode.highContrast,
    displayName: 'High Contrast (Yüksek Kontrast AAA)',
    primary: Color(0xFFFFFF00), // Sarı
    primaryContainer: Color(0xFF333300),
    secondary: Color(0xFF00FFFF), // Camgöbeği
    background: Colors.black,
    surface: Colors.black,
    surfaceVariant: Color(0xFF111111),
    border: Colors.yellowAccent,
    textPrimary: Colors.white,
    textSecondary: Color(0xFFE0E0E0),
    textMuted: Color(0xFFCCCCCC),
    success: Color(0xFF00FF00),
    warning: Color(0xFFFFCC00),
    danger: Color(0xFFFF3333),
    info: Color(0xFF33CCFF),
    borderRadius: 4.0,
    cardElevation: 0.0,
  );

  static const Map<AppThemeMode, AppThemeTokens> tokensMap = {
    AppThemeMode.corporateDark: corporateDark,
    AppThemeMode.corporateLight: corporateLight,
    AppThemeMode.neutral: neutral,
    AppThemeMode.blueCorporate: blueCorporate,
    AppThemeMode.greenEnterprise: greenEnterprise,
    AppThemeMode.highContrast: highContrast,
  };

  static List<AppThemeTokens> get availableThemes => tokensMap.values.toList();

  String get id {
    switch (mode) {
      case AppThemeMode.corporateDark:
        return 'corporate_dark';
      case AppThemeMode.corporateLight:
        return 'corporate_light';
      case AppThemeMode.neutral:
        return 'neutral';
      case AppThemeMode.blueCorporate:
        return 'blue_corporate';
      case AppThemeMode.greenEnterprise:
        return 'green_enterprise';
      case AppThemeMode.highContrast:
        return 'high_contrast';
    }
  }

  /// Flutter ThemeData üretir
  ThemeData toThemeData({String? fontFamily}) {
    final colorScheme = ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: primary,
      onPrimary: isDark ? const Color(0xFF121418) : Colors.white,
      primaryContainer: primaryContainer,
      onPrimaryContainer: isDark ? const Color(0xFFF3F4F6) : primary,
      secondary: secondary,
      onSecondary: Colors.white,
      surface: surface,
      onSurface: textPrimary,
      background: background,
      onBackground: textPrimary,
      error: danger,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surface,
      fontFamily: fontFamily,
      cardTheme: CardThemeData(
        color: surface,
        elevation: cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: BorderSide(color: border, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: Border(bottom: BorderSide(color: border, width: 1)),
      ),
      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(88, 44),
          backgroundColor: primary,
          foregroundColor: isDark ? const Color(0xFF121418) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(88, 44),
          foregroundColor: primary,
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

/// Global Tema Yöneticisi (ChangeNotifier)
class AppThemeManager extends ChangeNotifier {
  AppThemeManager._();
  static final AppThemeManager instance = AppThemeManager._();

  AppThemeMode _currentMode = AppThemeMode.corporateDark;

  AppThemeMode get currentMode => _currentMode;
  AppThemeTokens get tokens =>
      AppThemeTokens.tokensMap[_currentMode] ?? AppThemeTokens.corporateDark;
  AppThemeTokens get activeTheme => tokens;

  void initializeDefaults() {
    _currentMode = AppThemeMode.corporateDark;
    notifyListeners();
  }

  void setTheme(dynamic modeOrId) {
    if (modeOrId is AppThemeMode) {
      if (_currentMode != modeOrId) {
        _currentMode = modeOrId;
        notifyListeners();
      }
    } else if (modeOrId is String) {
      for (final mode in AppThemeMode.values) {
        final snake = mode.name.replaceAll(RegExp(r'(?=[A-Z])'), '_').toLowerCase();
        if (mode.name.toLowerCase() == modeOrId.toLowerCase() || snake == modeOrId.toLowerCase()) {
          _currentMode = mode;
          notifyListeners();
          return;
        }
      }
    }
  }
}
