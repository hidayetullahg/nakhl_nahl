import 'package:flutter/foundation.dart';
import 'timezone_service.dart';

/// NAKHL & NAHL — DÜNYA SAATLERİ YÖNETİMİ
/// Kullanıcının seçtiği saat dilimlerini sıralama, favorileme, ekleme ve çıkarma servisi.

class WorldClockService extends ChangeNotifier {
  WorldClockService._() {
    _initDefaultClocks();
  }
  static final WorldClockService instance = WorldClockService._();

  final List<WorldClockItem> _clocks = [];

  List<WorldClockItem> get clocks => List.unmodifiable(_clocks);
  List<WorldClockItem> get favoriteClocks =>
      _clocks.where((c) => c.isFavorite).toList();

  void _initDefaultClocks() {
    _clocks.addAll([
      const WorldClockItem(
        id: 'clk_riyadh',
        timeZoneId: 'Asia/Riyadh',
        cityName: 'Riyadh',
        countryName: 'Saudi Arabia',
        offsetMinutes: 180,
        isFavorite: true,
        sortOrder: 0,
      ),
      const WorldClockItem(
        id: 'clk_istanbul',
        timeZoneId: 'Europe/Istanbul',
        cityName: 'Istanbul',
        countryName: 'Turkey',
        offsetMinutes: 180,
        isFavorite: true,
        sortOrder: 1,
      ),
      const WorldClockItem(
        id: 'clk_dubai',
        timeZoneId: 'Asia/Dubai',
        cityName: 'Dubai',
        countryName: 'UAE',
        offsetMinutes: 240,
        isFavorite: true,
        sortOrder: 2,
      ),
      const WorldClockItem(
        id: 'clk_london',
        timeZoneId: 'Europe/London',
        cityName: 'London',
        countryName: 'UK',
        offsetMinutes: 60, // Summer BST
        isFavorite: true,
        sortOrder: 3,
      ),
      const WorldClockItem(
        id: 'clk_new_york',
        timeZoneId: 'America/New_York',
        cityName: 'New York',
        countryName: 'USA',
        offsetMinutes: -240, // Summer EDT
        isFavorite: true,
        sortOrder: 4,
      ),
    ]);
  }

  void initializeDefaults() {
    _clocks.clear();
    _initDefaultClocks();
    notifyListeners();
  }

  void addClock({
    IanaTimeZone? timeZone,
    String? timezoneId,
    String? city,
    String? country,
    String? displayName,
    bool isFavorite = false,
  }) {
    final tzId = timeZone?.id ?? timezoneId ?? 'Asia/Riyadh';
    if (_clocks.any((c) => c.timeZoneId == tzId)) return;

    final cityName = city ?? (timeZone?.cityName.split('(').first.trim() ?? tzId);
    final countryName = country ?? (timeZone?.countryName ?? 'Global');
    final offset = timeZone?.baseOffsetMinutes ?? 0;

    final newClock = WorldClockItem(
      id: 'clk_${tzId.replaceAll('/', '_').toLowerCase()}',
      timeZoneId: tzId,
      cityName: cityName,
      countryName: countryName,
      offsetMinutes: offset,
      isFavorite: isFavorite,
      sortOrder: _clocks.length,
    );
    _clocks.add(newClock);
    notifyListeners();
  }

  bool removeClock(String idOrTz) {
    if (_clocks.length <= 1) return false;
    final index = _clocks.indexWhere((c) => c.id == idOrTz || c.timeZoneId == idOrTz);
    if (index != -1) {
      _clocks.removeAt(index);
      _reindexSortOrders();
      notifyListeners();
      return true;
    }
    return false;
  }

  void moveUp(int index) {
    if (index <= 0 || index >= _clocks.length) return;
    final item = _clocks.removeAt(index);
    _clocks.insert(index - 1, item);
    _reindexSortOrders();
    notifyListeners();
  }

  void moveDown(int index) {
    if (index < 0 || index >= _clocks.length - 1) return;
    final item = _clocks.removeAt(index);
    _clocks.insert(index + 1, item);
    _reindexSortOrders();
    notifyListeners();
  }

  void toggleFavorite(String idOrTz) {
    final index = _clocks.indexWhere((c) => c.id == idOrTz || c.timeZoneId == idOrTz);
    if (index != -1) {
      final current = _clocks[index];
      _clocks[index] = current.copyWith(isFavorite: !current.isFavorite);
      notifyListeners();
    }
  }

  void _reindexSortOrders() {
    for (int i = 0; i < _clocks.length; i++) {
      _clocks[i] = _clocks[i].copyWith(sortOrder: i);
    }
  }
}
