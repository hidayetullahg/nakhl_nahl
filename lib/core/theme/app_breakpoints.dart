import 'package:flutter/material.dart';

/// NAKHL&NAHL ERP — Duyarlı Ekran Kesme Noktaları (Responsive Breakpoints)
/// 
/// Mobile: < 600px
/// Tablet: 600px – 1024px
/// Desktop: 1024px – 1440px
/// Large Desktop: > 1440px
class AppBreakpoints {
  AppBreakpoints._();

  static const double mobileMax = 600.0;
  static const double tabletMax = 1024.0;
  static const double desktopMax = 1440.0;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileMax;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobileMax && width < tabletMax;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletMax;

  static bool isLargeDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktopMax;

  /// Ekran genişliğine göre dinamik kolon sayısı döndürür
  static int getGridColumnCount(BuildContext context, {int mobile = 1, int tablet = 2, int desktop = 4, int large = 6}) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < mobileMax) return mobile;
    if (width < tabletMax) return tablet;
    if (width < desktopMax) return desktop;
    return large;
  }
}
