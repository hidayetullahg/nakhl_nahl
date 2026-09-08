import 'package:flutter/material.dart';
import 'app_colors.dart';

/// NAKHL&NAHL ERP — Profesyonel Tipografi Hiyerarşisi
/// 
/// Inter ve modern sans-serif temelinde belirlenmiş kurumsal metin stilleri.
/// Display: 32–40, Page Title: 24–28, Section Title: 18–20,
/// Card Title: 14–16, Body: 13–15, Secondary: 11–13, KPI: 24–32.
class AppTypography {
  AppTypography._();

  static const String defaultFontFamily = 'Inter';

  // Display Stilleri
  static TextStyle displayLarge({Color? color}) => TextStyle(
        fontFamily: defaultFontFamily,
        fontSize: 36.0,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle displayMedium({Color? color}) => TextStyle(
        fontFamily: defaultFontFamily,
        fontSize: 30.0,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: color ?? AppColors.textPrimary,
      );

  // Başlıklar
  static TextStyle pageTitle({Color? color}) => TextStyle(
        fontFamily: defaultFontFamily,
        fontSize: 24.0,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle sectionTitle({Color? color}) => TextStyle(
        fontFamily: defaultFontFamily,
        fontSize: 18.0,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle cardTitle({Color? color}) => TextStyle(
        fontFamily: defaultFontFamily,
        fontSize: 15.0,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.textPrimary,
      );

  // Finansal KPI & Rakam Vurguları
  static TextStyle kpiNumber({Color? color}) => TextStyle(
        fontFamily: defaultFontFamily,
        fontSize: 28.0,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle kpiNumberSm({Color? color}) => TextStyle(
        fontFamily: defaultFontFamily,
        fontSize: 22.0,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: color ?? AppColors.textPrimary,
      );

  // Gövde Metinleri
  static TextStyle bodyLarge({Color? color}) => TextStyle(
        fontFamily: defaultFontFamily,
        fontSize: 15.0,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle bodyMedium({Color? color}) => TextStyle(
        fontFamily: defaultFontFamily,
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: color ?? AppColors.textPrimary,
      );

  // İkincil ve Açıklama Metinleri
  static TextStyle secondary({Color? color}) => TextStyle(
        fontFamily: defaultFontFamily,
        fontSize: 12.0,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.textSecondary,
      );

  static TextStyle caption({Color? color}) => TextStyle(
        fontFamily: defaultFontFamily,
        fontSize: 11.0,
        fontWeight: FontWeight.w500,
        color: color ?? AppColors.textMuted,
      );

  // Buton ve Etiketler
  static TextStyle button({Color? color}) => TextStyle(
        fontFamily: defaultFontFamily,
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: color ?? Colors.white,
      );

  static TextStyle badge({Color? color}) => TextStyle(
        fontFamily: defaultFontFamily,
        fontSize: 11.0,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: color ?? AppColors.textPrimary,
      );
}
