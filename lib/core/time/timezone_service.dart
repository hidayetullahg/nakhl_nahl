/// NAKHL & NAHL — TIMEZONE VE DÜNYA SAATLERİ SERVİSİ
/// IANA saat dilimleri kataloğu, yerel saat dilimi tespiti ve çoklu saat yönetimi.

class IanaTimeZone {
  final String id; // Örn: 'Asia/Riyadh'
  final String cityName;
  final String countryName;
  final int baseOffsetMinutes;
  final bool isDefault;

  const IanaTimeZone({
    required this.id,
    required this.cityName,
    required this.countryName,
    required this.baseOffsetMinutes,
    this.isDefault = false,
  });

  Duration get offset => Duration(minutes: baseOffsetMinutes);
}

class WorldClockItem {
  final String id;
  final String timeZoneId;
  final String cityName;
  final String countryName;
  final int offsetMinutes;
  final bool isFavorite;
  final int sortOrder;

  const WorldClockItem({
    required this.id,
    required this.timeZoneId,
    required this.cityName,
    required this.countryName,
    required this.offsetMinutes,
    this.isFavorite = false,
    this.sortOrder = 0,
  });

  DateTime get currentTime {
    final nowUtc = DateTime.now().toUtc();
    return nowUtc.add(Duration(minutes: offsetMinutes));
  }

  String get city => cityName;
  String get country => countryName;
  String get timezoneId => timeZoneId;

  WorldClockItem copyWith({
    bool? isFavorite,
    int? sortOrder,
  }) {
    return WorldClockItem(
      id: id,
      timeZoneId: timeZoneId,
      cityName: cityName,
      countryName: countryName,
      offsetMinutes: offsetMinutes,
      isFavorite: isFavorite ?? this.isFavorite,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

class TimezoneService {
  TimezoneService._();
  static final TimezoneService instance = TimezoneService._();

  // IANA Standard Saat Dilimleri Kataloğu
  static const List<IanaTimeZone> catalog = [
    IanaTimeZone(
      id: 'Asia/Riyadh',
      cityName: 'Riyadh (Riyad)',
      countryName: 'Suudi Arabistan',
      baseOffsetMinutes: 180, // UTC+3
      isDefault: true,
    ),
    IanaTimeZone(
      id: 'Europe/Istanbul',
      cityName: 'Istanbul (İstanbul)',
      countryName: 'Türkiye',
      baseOffsetMinutes: 180, // UTC+3
      isDefault: true,
    ),
    IanaTimeZone(
      id: 'Asia/Dubai',
      cityName: 'Dubai',
      countryName: 'Birleşik Arap Emirlikleri',
      baseOffsetMinutes: 240, // UTC+4
      isDefault: true,
    ),
    IanaTimeZone(
      id: 'Europe/London',
      cityName: 'London (Londra)',
      countryName: 'Birleşik Krallık',
      baseOffsetMinutes: 0, // UTC+0 (BST: +60)
      isDefault: true,
    ),
    IanaTimeZone(
      id: 'Europe/Berlin',
      cityName: 'Berlin',
      countryName: 'Almanya',
      baseOffsetMinutes: 60, // UTC+1 (CEST: +120)
      isDefault: true,
    ),
    IanaTimeZone(
      id: 'America/New_York',
      cityName: 'New York',
      countryName: 'ABD',
      baseOffsetMinutes: -300, // UTC-5 (EDT: -240)
      isDefault: true,
    ),
    IanaTimeZone(
      id: 'Asia/Tokyo',
      cityName: 'Tokyo',
      countryName: 'Japonya',
      baseOffsetMinutes: 540, // UTC+9
      isDefault: true,
    ),
    IanaTimeZone(
      id: 'Asia/Singapore',
      cityName: 'Singapore (Singapur)',
      countryName: 'Singapur',
      baseOffsetMinutes: 480, // UTC+8
    ),
    IanaTimeZone(
      id: 'Asia/Baku',
      cityName: 'Baku (Bakü)',
      countryName: 'Azerbaycan',
      baseOffsetMinutes: 240, // UTC+4
    ),
    IanaTimeZone(
      id: 'Asia/Kuala_Lumpur',
      cityName: 'Kuala Lumpur',
      countryName: 'Malezya',
      baseOffsetMinutes: 480, // UTC+8
    ),
    IanaTimeZone(
      id: 'Asia/Qatar',
      cityName: 'Doha',
      countryName: 'Katar',
      baseOffsetMinutes: 180, // UTC+3
    ),
    IanaTimeZone(
      id: 'Asia/Kuwait',
      cityName: 'Kuwait City (Kuveyt)',
      countryName: 'Kuveyt',
      baseOffsetMinutes: 180, // UTC+3
    ),
  ];

  /// Yerel cihaz saat dilimini tespit eder
  String detectLocalTimeZoneId() {
    final offset = DateTime.now().timeZoneOffset.inMinutes;
    // Eşleşen bilinen IANA ID'yi bul
    for (final tz in catalog) {
      if (tz.baseOffsetMinutes == offset) {
        return tz.id;
      }
    }
    return 'Asia/Riyadh'; // Global default
  }

  /// Saat dilimi arama
  List<IanaTimeZone> search(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return catalog;
    return catalog.where((tz) {
      return tz.cityName.toLowerCase().contains(q) ||
          tz.countryName.toLowerCase().contains(q) ||
          tz.id.toLowerCase().contains(q);
    }).toList();
  }
}
