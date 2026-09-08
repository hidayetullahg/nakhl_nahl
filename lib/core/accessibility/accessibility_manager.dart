import 'package:flutter/material.dart';

/// NAKHL & NAHL — ERİŞİLEBİLİRLİK VE OKUNABİLİRLİK YÖNETİCİSİ
/// Uzun saatler çalışan kurumsal ERP kullanıcıları için font ölçekleme, büyük butonlar, kontrast ve hareket azaltma.

enum FontSizeProfile {
  small(0.9, 'Küçük'),
  medium(1.0, 'Orta (Standart)'),
  large(1.15, 'Büyük'),
  extraLarge(1.30, 'Çok Büyük');

  final double scaleFactor;
  final String label;
  const FontSizeProfile(this.scaleFactor, this.label);
}

class AccessibilityManager extends ChangeNotifier {
  AccessibilityManager._();
  static final AccessibilityManager instance = AccessibilityManager._();

  FontSizeProfile _fontSizeProfile = FontSizeProfile.medium;
  bool _highContrast = false;
  bool _reducedMotion = false;
  bool _largerControls = true;
  bool _showTooltips = true;

  FontSizeProfile get fontSizeProfile => _fontSizeProfile;
  double get fontScale => _fontSizeProfile.scaleFactor;
  bool get highContrast => _highContrast;
  bool get reducedMotion => _reducedMotion;
  bool get largerControls => _largerControls;
  bool get showTooltips => _showTooltips;

  double get minTouchTarget => _largerControls ? 48.0 : 40.0;

  void setFontSizeProfile(FontSizeProfile profile) {
    if (_fontSizeProfile != profile) {
      _fontSizeProfile = profile;
      notifyListeners();
    }
  }

  void setHighContrast(bool value) {
    if (_highContrast != value) {
      _highContrast = value;
      notifyListeners();
    }
  }

  void setReducedMotion(bool value) {
    if (_reducedMotion != value) {
      _reducedMotion = value;
      notifyListeners();
    }
  }

  void setLargerControls(bool value) {
    if (_largerControls != value) {
      _largerControls = value;
      notifyListeners();
    }
  }

  void setShowTooltips(bool value) {
    if (_showTooltips != value) {
      _showTooltips = value;
      notifyListeners();
    }
  }
}
