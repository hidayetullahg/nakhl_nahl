import 'package:flutter/foundation.dart';

/// NAKHL & NAHL — MİLADİ VE HİCRİ TAKVİM SERVİSİ
/// Umm al-Qura & Algoritmik Hicri Takvim dönüşümü, çift takvim (Dual Calendar) formatlaması.

enum CalendarSystem {
  gregorian('Miladi (Gregorian)'),
  hijri('Hicri (Umm al-Qura)'),
  dual('Çift Takvim (Dual Calendar)');

  final String label;
  const CalendarSystem(this.label);
}

class HijriDate {
  final int year;
  final int month; // 1 to 12
  final int day; // 1 to 30

  const HijriDate({
    required this.year,
    required this.month,
    required this.day,
  });

  @override
  String toString() => '$day/${month.toString().padLeft(2, '0')}/$year AH';
}

class CalendarService extends ChangeNotifier {
  CalendarService._();
  static final CalendarService instance = CalendarService._();

  CalendarSystem _currentSystem = CalendarSystem.dual;
  CalendarSystem get currentSystem => _currentSystem;

  void setCalendarSystem(CalendarSystem system) {
    if (_currentSystem != system) {
      _currentSystem = system;
      notifyListeners();
    }
  }

  // Hicri Ay İsimleri (TR, EN, AR, AR-LAT)
  static const Map<String, List<String>> hijriMonths = {
    'TR': [
      'Muharrem',
      'Safer',
      'Rebiülevvel',
      'Rebiülahir',
      'Cemaziyelevvel',
      'Cemaziyelahir',
      'Recep',
      'Şaban',
      'Ramazan',
      'Şevval',
      'Zilkade',
      'Zilhicce',
    ],
    'EN': [
      'Muharram',
      'Safar',
      'Rabi\' al-Awwal',
      'Rabi\' al-Thani',
      'Jumada al-Awwal',
      'Jumada al-Thani',
      'Rajab',
      'Sha\'ban',
      'Ramadan',
      'Shawwal',
      'Dhu al-Qi\'dah',
      'Dhu al-Hijjah',
    ],
    'AR': [
      'محرم',
      'صفر',
      'ربيع الأول',
      'ربيع الثاني',
      'جمادى الأولى',
      'جمادى الآخرة',
      'رجب',
      'شعبان',
      'رمضان',
      'شوال',
      'ذو القعدة',
      'ذو الحجة',
    ],
    'AR-LAT': [
      'Muharram',
      'Safar',
      'Rabi\' Al-Awwal',
      'Rabi\' Al-Thani',
      'Jumada Al-Oola',
      'Jumada Al-Aakhirah',
      'Rajab',
      'Sha\'baan',
      'Ramadan',
      'Shawwal',
      'Dhu Al-Qi\'dah',
      'Dhu Al-Hijjah',
    ],
  };

  // Miladi Ay İsimleri (TR, EN, AR, AR-LAT)
  static const Map<String, List<String>> gregorianMonths = {
    'TR': [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ],
    'EN': [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ],
    'AR': [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ],
    'AR-LAT': [
      'Yanayir', 'Fibrayir', 'Maaris', 'Ibreel', 'Maayo', 'Yoonyo',
      'Yoolyo', 'Aghustus', 'Sibtambir', 'Uktoobar', 'Noofambir', 'Deesambir'
    ],
  };

  /// Miladi tarihi Hicri tarihe dönüştürür (Kuwaiti / Umm al-Qura Algoritması)
  HijriDate gregorianToHijri(DateTime date) {
    int day = date.day;
    int month = date.month;
    int year = date.year;

    int m = month;
    int y = year;
    if (m < 3) {
      y -= 1;
      m += 12;
    }

    int a = (y / 100).floor();
    int b = 2 - a + (a / 4).floor();
    int jd = (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        day +
        b -
        1524;

    // Julian Gününden Hicri Güne Dönüşüm
    int l = jd - 1948440 + 10632;
    int n = ((l - 1) / 10631).floor();
    l = l - 10631 * n + 354;
    int j = ((10985 - l) / 5316).floor() * ((50 * l) / 17719).floor() +
        (l / 5670).floor() * ((43 * l) / 15238).floor();
    l = l -
        ((30 - j) / 15).floor() * ((17719 * j) / 50).floor() -
        (j / 16).floor() * ((15238 * j) / 43).floor() +
        29;
    m = ((24 * l) / 709).floor();
    int d = l - ((709 * m) / 24).floor();
    y = 30 * n + j - 30;

    return HijriDate(year: y, month: m, day: d);
  }

  /// Aktif dile göre formatlanmış Miladi metin döner (Örn: "07 Eylül 2026")
  String formatGregorian(DateTime date, {String languageCode = 'TR'}) {
    final lang = languageCode.toUpperCase();
    final months = gregorianMonths[lang] ?? gregorianMonths['EN']!;
    final monthName = months[(date.month - 1).clamp(0, 11)];
    final dayStr = date.day.toString().padLeft(2, '0');
    return '$dayStr $monthName ${date.year}';
  }

  /// Aktif dile göre formatlanmış Hicri metin döner (Örn: "15 Rebiülevvel 1448")
  String formatHijri(HijriDate hijri, {String languageCode = 'TR'}) {
    final lang = languageCode.toUpperCase();
    final months = hijriMonths[lang] ?? hijriMonths['EN']!;
    final monthName = months[(hijri.month - 1).clamp(0, 11)];
    final suffix = lang == 'TR' ? 'H' : (lang == 'AR' ? 'هـ' : 'AH');
    return '${hijri.day} $monthName ${hijri.year} $suffix';
  }

  /// Seçili takvim moduna göre başlık metni üretir
  String formatDualCalendar(DateTime date, {String languageCode = 'TR'}) {
    final greg = formatGregorian(date, languageCode: languageCode);
    final hijri = gregorianToHijri(date);
    final hijriStr = formatHijri(hijri, languageCode: languageCode);

    switch (_currentSystem) {
      case CalendarSystem.gregorian:
        return greg;
      case CalendarSystem.hijri:
        return hijriStr;
      case CalendarSystem.dual:
        return '$greg • $hijriStr';
    }
  }

  /// Yapılandırılmış çift takvim sonucu döner
  DualDateResult getDualDate(DateTime date, String languageCode) {
    final greg = formatGregorian(date, languageCode: languageCode);
    final hijri = gregorianToHijri(date);
    final hijriStr = formatHijri(hijri, languageCode: languageCode);

    return DualDateResult(
      gregorian: greg,
      hijri: hijriStr,
      hijriYear: hijri.year,
      hijriMonth: hijri.month,
      hijriDay: hijri.day,
    );
  }
}

class DualDateResult {
  final String gregorian;
  final String hijri;
  final int hijriYear;
  final int hijriMonth;
  final int hijriDay;

  const DualDateResult({
    required this.gregorian,
    required this.hijri,
    required this.hijriYear,
    required this.hijriMonth,
    required this.hijriDay,
  });
}

