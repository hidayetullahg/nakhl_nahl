// ==============================================================================
// NAKHL & NAHL — DELIVERY 08: CORPORATE THEMES & DESIGN TOKENS TEST SUITE
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nakhl_nahl/core/theme/app_theme_tokens.dart';

void main() {
  setUp(() {
    AppThemeManager.instance.initializeDefaults();
  });

  group('Delivery 08: Enterprise Themes & Tokens', () {
    test('All 6 corporate themes are defined with valid tokens', () {
      expect(AppThemeTokens.availableThemes.length, equals(6));

      expect(AppThemeTokens.corporateDark.id, equals('corporate_dark'));
      expect(AppThemeTokens.corporateLight.id, equals('corporate_light'));
      expect(AppThemeTokens.neutral.id, equals('neutral'));
      expect(AppThemeTokens.blueCorporate.id, equals('blue_corporate'));
      expect(AppThemeTokens.greenEnterprise.id, equals('green_enterprise'));
      expect(AppThemeTokens.highContrast.id, equals('high_contrast'));
    });

    test('Theme switching updates active theme tokens and notifies listeners', () {
      final manager = AppThemeManager.instance;
      bool notified = false;
      manager.addListener(() => notified = true);

      expect(manager.activeTheme.id, equals('corporate_dark'));

      manager.setTheme('blue_corporate');
      expect(manager.activeTheme.id, equals('blue_corporate'));
      expect(notified, isTrue);
    });

    test('High contrast theme enforces maximum readability contrast', () {
      final hc = AppThemeTokens.highContrast;
      expect(hc.surface, equals(Colors.black));
      expect(hc.textPrimary, equals(Colors.white));
      expect(hc.border, equals(Colors.yellowAccent));
    });

    test('AppThemeTokens converts cleanly to Material ThemeData', () {
      final themeData = AppThemeTokens.corporateDark.toThemeData(fontFamily: 'Inter');
      expect(themeData.brightness, equals(Brightness.dark));
      expect(themeData.scaffoldBackgroundColor, equals(AppThemeTokens.corporateDark.surface));
    });
  });
}
