// ==============================================================================
// NAKHL & NAHL — AÇILIŞ BAKİYESİ VE GÜNLÜK İŞLETME SERVİSİ
// "Bugünün Fotoğrafı", Kurulum Eksikleri ve Günlük Kontrol Listesi
// ==============================================================================

class BusinessSnapshot {
  final double totalCash; // Kasa toplamı
  final double totalBank; // Banka hesapları toplamı
  final double pocketCash; // İşletme eldeki nakdi
  final double totalReceivables; // Toplam Alacaklar (Müşteriler)
  final double totalPayables; // Toplam Borçlar (Tedarikçiler)
  final double totalInventoryValue; // Toplam Stok Değeri
  final int customerCount;
  final int supplierCount;
  final int productCount;
  final int warehouseCount;
  final int branchCount;
  final DateTime openingDate;
  final String currency;

  const BusinessSnapshot({
    required this.totalCash,
    required this.totalBank,
    required this.pocketCash,
    required this.totalReceivables,
    required this.totalPayables,
    required this.totalInventoryValue,
    required this.customerCount,
    required this.supplierCount,
    required this.productCount,
    required this.warehouseCount,
    required this.branchCount,
    required this.openingDate,
    required this.currency,
  });

  /// Net İşletme Varlığı (Özkaynak / Net Değer):
  /// (Kasa + Banka + Eldeki Nakit + Alacaklar + Stok) - Borçlar
  double get netWorth =>
      (totalCash + totalBank + pocketCash + totalReceivables + totalInventoryValue) -
      totalPayables;

  /// Toplam Likit Fonlar (Nakit + Banka + Cep)
  double get totalLiquidAssets => totalCash + totalBank + pocketCash;
}

class DailyChecklistItem {
  final String id;
  final String title;
  final String description;
  bool isCompleted;

  DailyChecklistItem({
    required this.id,
    required this.title,
    required this.description,
    this.isCompleted = false,
  });
}

class OpeningBalanceService {
  OpeningBalanceService._();
  static final OpeningBalanceService instance = OpeningBalanceService._();

  BusinessSnapshot? _currentSnapshot;
  BusinessSnapshot? get currentSnapshot => _currentSnapshot;

  /// Günlük İşletme Kontrol Listesi (Checklist)
  final List<DailyChecklistItem> _dailyChecklist = [
    DailyChecklistItem(
      id: 'kasa_kontrol',
      title: 'Kasa Kontrol Edildi',
      description: 'Gün başı fiili kasa nakdi sistem bakiyesiyle karşılaştırıldı.',
    ),
    DailyChecklistItem(
      id: 'satislar',
      title: 'Günün Satışları İşlendi',
      description: 'Yapılan peşin ve vadeli satışlar faturalandırıldı/kaydedildi.',
    ),
    DailyChecklistItem(
      id: 'tahsilatlar',
      title: 'Müşteri Tahsilatları Alındı',
      description: 'Müşterilerden gelen nakit veya banka tahsilatları cariye işlendi.',
    ),
    DailyChecklistItem(
      id: 'alislar',
      title: 'Mal Alışları Girildi',
      description: 'Gelen hammadde, hurma veya ticari malların alış faturaları kaydedildi.',
    ),
    DailyChecklistItem(
      id: 'odemeler',
      title: 'Tedarikçi Ödemeleri Yapıldı',
      description: 'Tedarikçilere yapılan EFT, havale veya nakit ödemeler düşüldü.',
    ),
    DailyChecklistItem(
      id: 'stok_hareketleri',
      title: 'Stok Hareketleri Denetlendi',
      description: 'Depolar arası transferler ve fire/sayım farkları stok defterine işlendi.',
    ),
    DailyChecklistItem(
      id: 'banka_kontrol',
      title: 'Banka Hesapları Mutabakatı',
      description: 'Banka ekstrelerindeki POS ve EFT hareketleri doğrulandı.',
    ),
    DailyChecklistItem(
      id: 'faturalar',
      title: 'E-Faturalar ve İrsaliyeler Gönderildi',
      description: 'GİB veya ZATCA sistemine e-arşiv ve e-faturalar iletildi.',
    ),
    DailyChecklistItem(
      id: 'cari_kontrol',
      title: 'Cari Bakiye ve Risk Kontrolü',
      description: 'Vadesi geçen alacaklar ve yaklaşan borçlar gözden geçirildi.',
    ),
    DailyChecklistItem(
      id: 'gun_sonu',
      title: 'Gün Sonu Kasa Mutabakatı Tamamlandı',
      description: 'Akşam kasa sayımı yapıldı, kasa defteri kapatıldı.',
    ),
  ];

  List<DailyChecklistItem> get dailyChecklist => List.unmodifiable(_dailyChecklist);

  void toggleChecklistItem(String id) {
    final item = _dailyChecklist.firstWhere((x) => x.id == id, orElse: () => _dailyChecklist.first);
    item.isCompleted = !item.isCompleted;
  }

  void saveSnapshot(BusinessSnapshot snapshot) {
    _currentSnapshot = snapshot;
  }

  /// Kurulum Eksiklikleri Denetleyicisi
  List<String> getSetupDeficiencies() {
    final List<String> deficiencies = [];
    final snap = _currentSnapshot;

    if (snap == null) {
      deficiencies.add('İşletme başlangıç fotoğrafı henüz oluşturulmadı.');
      return deficiencies;
    }

    if (snap.totalCash == 0 && snap.pocketCash == 0) {
      deficiencies.add('Kasa nakit bakiyesi tanımlanmadı.');
    }
    if (snap.totalBank == 0) {
      deficiencies.add('Banka hesabı tanımlanmadı.');
    }
    if (snap.warehouseCount == 0) {
      deficiencies.add('Operasyonel depo tanımlanmadı.');
    }
    if (snap.productCount == 0) {
      deficiencies.add('Kayıtlı ürün/hizmet kartı bulunmuyor.');
    }
    if (snap.customerCount == 0) {
      deficiencies.add('Kayıtlı müşteri cari kartı bulunmuyor.');
    }
    if (snap.totalInventoryValue == 0) {
      deficiencies.add('Açılış stokları girilmedi.');
    }

    return deficiencies;
  }

  /// Varsayılan Demo Snapshot'ı (Hızlı İnceleme & Test İçin)
  void initializeDemoSnapshot({String currency = 'SAR'}) {
    _currentSnapshot = BusinessSnapshot(
      totalCash: 45000.0,
      totalBank: 185000.0,
      pocketCash: 5000.0,
      totalReceivables: 124000.0,
      totalPayables: 68000.0,
      totalInventoryValue: 310000.0,
      customerCount: 14,
      supplierCount: 8,
      productCount: 22,
      warehouseCount: 2,
      branchCount: 1,
      openingDate: DateTime.now(),
      currency: currency,
    );
  }
}
