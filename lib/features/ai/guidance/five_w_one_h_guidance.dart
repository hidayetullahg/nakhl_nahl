/// NAKHL & NAHL — 5N1K KULLANICI REHBERİ VE YÖNLENDİRME MOTORU
/// Kullanıcıya teorik bilgi vermek yerine; ne yapılacağını, neden yapılacağını,
/// hangi ekranda yapılacağını ve hangi alanların doldurulacağını 5N1K formatında sunar.

class FiveWOneHGuidance {
  final String what; // NE?
  final String why; // NEDEN?
  final String where; // NEREDE? (Menü > Ekran > Alan)
  final String when; // NE ZAMAN?
  final String how; // NASIL?
  final String who; // KİM?
  final List<String> requiredData; // GEREKLİ VERİLER
  final List<String> requiredDocuments; // GEREKLİ BELGELER
  final List<String> validations; // KONTROLLER
  final List<String> missingItems; // EKSİKLER
  final List<String> risks; // RİSKLER
  final String legislation; // MEVZUAT
  final String nextStep; // SONRAKİ ADIM

  const FiveWOneHGuidance({
    required this.what,
    required this.why,
    required this.where,
    required this.when,
    required this.how,
    required this.who,
    this.requiredData = const [],
    this.requiredDocuments = const [],
    this.validations = const [],
    this.missingItems = const [],
    this.risks = const [],
    required this.legislation,
    required this.nextStep,
  });

  String toFormattedMarkdown() {
    final buffer = StringBuffer();
    buffer.writeln('### 📌 5N1K KULLANICI REHBERİ\n');
    buffer.writeln('**NE?**\n$what\n');
    buffer.writeln('**NEDEN?**\n$why\n');
    buffer.writeln('**NEREDE? (PROGRAMDA YOL)**\n`$where`\n');
    buffer.writeln('**NE ZAMAN?**\n$when\n');
    buffer.writeln('**NASIL? (ADIM ADIM)**\n$how\n');
    buffer.writeln('**KİM YAPMALI?**\n$who\n');

    if (requiredData.isNotEmpty) {
      buffer.writeln('**GEREKLİ VERİLER:**');
      for (final item in requiredData) {
        buffer.writeln('- $item');
      }
      buffer.writeln();
    }

    if (requiredDocuments.isNotEmpty) {
      buffer.writeln('**GEREKLİ BELGELER:**');
      for (final item in requiredDocuments) {
        buffer.writeln('- $item');
      }
      buffer.writeln();
    }

    if (missingItems.isNotEmpty) {
      buffer.writeln('**⚠️ DİKKAT / EKSİKLER:**');
      for (final item in missingItems) {
        buffer.writeln('- $item');
      }
      buffer.writeln();
    }

    buffer.writeln('**MEVZUAT DAYANAĞI:**\n$legislation\n');
    buffer.writeln('**SONRAKİ ADIM:**\n$nextStep');

    return buffer.toString();
  }

  /// Satış İhracat Faturası için hazır 5N1K Rehberi
  static FiveWOneHGuidance get exportInvoiceGuidance => const FiveWOneHGuidance(
        what: 'İhracat Satış Faturası ve ZATCA/GİB uyumlu e-Fatura oluşturulacak.',
        why: 'Uluslararası gümrük beyanı, KDV istisnası ve yasal muhasebe kaydı için zorunludur.',
        where: 'Menü > Satış & Faturalandırma > Satış Faturası > Yeni Fatura',
        when: 'Mallar gümrüğe sevk edilmeden veya taşıyıcıya teslim edilmeden önce düzenlenmelidir.',
        how: '1. Müşteri cari kartını seçin.\n2. Para birimi ve kuru belirleyin.\n3. Hurma/ürün kalemlerini ve lot numarasını girin.\n4. İhracat KDV istisna kodunu seçin.\n5. Kaydet ve ZATCA/GİB portalına ilet butonuna basın.',
        who: 'İhracat Uzmanı veya Muhasebe Yetkilisi',
        requiredData: [
          'Alıcı Resmi Ünvanı ve Ülkesi',
          'GTİP / HS Kodu (Örn: 0804.10)',
          'Net / Brüt Ağırlık',
          'Incoterm Teslim Şekli (FOB/CIF)',
          'Para Birimi (SAR / USD / EUR)'
        ],
        requiredDocuments: [
          'Ticari Fatura (Commercial Invoice)',
          'Çeki Listesi (Packing List)',
          'Menşe Şahadetnamesi (Certificate of Origin)',
          'Gıda Sağlık / Bitki Karantina Sertifikası'
        ],
        validations: [
          'Cari kart VKN/TIN doğrulaması',
          'HS Kodu format kontrolü',
          'Stok mevcudu ve lot geçerlilik tarihi'
        ],
        missingItems: [
          'HS Kodu girilmemiş olabilir',
          'Fasah / Gümrük çıkış limanı seçilmelidir'
        ],
        risks: [
          'HS Kodu hatalı girilirse gümrükte ceza ve bekleme maliyeti oluşur.',
          'e-Fatura zamanında ZATCA portalına iletilmezse vergi cezası doğar.'
        ],
        legislation: 'ZATCA E-Invoicing Phase 2 Fatoora Regulations & Resmî Gazete İhracat Tebliği',
        nextStep: 'Fatura taslağını onaylayıp Gümrük Çıkış Beyannamesi modülüne aktarın.',
      );

  /// Cari Kart Ekleme için hazır 5N1K Rehberi
  static FiveWOneHGuidance get cariCreateGuidance => const FiveWOneHGuidance(
        what: 'Yeni Müşteri veya Tedarikçi Cari Kartı açılacak.',
        why: 'Tüm ticari işlemler, faturalar ve tahsilat/tediye makbuzları bir cari hesaba bağlanmalıdır.',
        where: 'Menü > Cariler & Müşteriler > Yeni Cari Kart',
        when: 'Yeni bir müşteri ile sözleşme yapıldığında veya tedarikçiden ilk mal alınmadan önce.',
        how: '1. Cari Tipini (Müşteri / Tedarikçi) seçin.\n2. Resmi Şirket Ünvanını girin.\n3. Ülke ve Vergi Kimlik Numarasını (VKN/TIN) yazın.\n4. İletişim ve e-Fatura posta kutusu adresini kaydedin.',
        who: 'Satış Temsilcisi, Satın Alma Uzmanı veya Ön Muhasebe',
        requiredData: [
          'Resmi Ticari Ünvan',
          'Vergi Dairesi ve Vergi Kimlik No (VKN / TIN)',
          'Ülke, İl, İlçe ve Açık Adres',
          'Telefon ve Resmi E-posta'
        ],
        requiredDocuments: [
          'Ticaret Sicil Gazetesi / Ticari Kayıt Belgesi (CR)',
          'Vergi Levhası / ZATCA Kayıt Belgesi',
          'İmza Sirküleri'
        ],
        validations: [
          'VKN 10 veya 11 hane kontrolü (KSA: 15 haneli 3 ile başlayıp biten ZATCA numarası)',
          'Mükerrer cari kayıt kontrolü'
        ],
        risks: [
          'Vergi numarası yanlış girilirse e-Faturalar GİB/ZATCA tarafından reddedilir.'
        ],
        legislation: 'VUK 229-232 & ZATCA Tax Registration Rules',
        nextStep: 'Cari açıldıktan sonra Finans modülünden açılış bakiyesi veya sipariş girişi yapabilirsiniz.',
      );

  /// Ekran ve modül bağlamına göre otomatik 5N1K rehberi üretir
  static FiveWOneHGuidance getGuidanceForScreen({
    required String module,
    required String screen,
    String? country,
  }) {
    if (module.toLowerCase().contains('export') ||
        module.toLowerCase().contains('satis') ||
        screen.toLowerCase().contains('shipment') ||
        screen.toLowerCase().contains('fatura') ||
        screen.toLowerCase().contains('invoice')) {
      return exportInvoiceGuidance;
    }
    return cariCreateGuidance;
  }
}
