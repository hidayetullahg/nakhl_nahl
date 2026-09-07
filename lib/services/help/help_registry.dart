// NAKHL & NAHL — Universal Help Registry & Task Guidance Library
// Complies with Master Directive Sections 12-25, 34

import '../../models/help_models.dart';

class HelpRegistry {
  static final HelpRegistry _instance = HelpRegistry._internal();
  factory HelpRegistry() => _instance;
  HelpRegistry._internal();

  /// Comprehensive in-memory built-in ERP knowledge catalog
  static final List<HelpContent> defaultContents = [
    // 1. Şirket Kurulumu
    const HelpContent(
      id: 'help_company',
      route: '/settings/company',
      menuKey: 'company',
      title: 'Şirket ve Organizasyon Kurulumu',
      shortDescription: 'Tüzel kişilik unvanı, vergi dairesi ve temel ticaret ayarlarınızı yönetin.',
      longDescription: 'Sistemdeki tüm şubelerin, ambarların ve ticari defterlerin bağlı olduğu ana tüzel kişilik ayarları bu ekranda tanımlanır.',
      steps: [
        HelpStep(step: 1, title: 'Resmi Unvanı Tanımlayın', desc: 'Ticaret sicil gazetesindeki tam şirket unvanını girin.'),
        HelpStep(step: 2, title: 'Vergi Bilgilerini Girin', desc: 'Vergi dairesi ve 10 haneli VKN bilgisini eksiksiz doldurun.'),
        HelpStep(step: 3, title: 'Ana Para Birimini Seçin', desc: 'Resmi defterlerinizin tutulacağı ana para birimini (TRY, SAR vb.) belirleyin.'),
        HelpStep(step: 4, title: 'Kaydedin', desc: 'Kurulumu tamamlayıp şube ve ambar tanımlarına geçin.'),
      ],
      warnings: ['Vergi numarası kaydedildikten sonra resmi faturalarla mühürleneceği için dikkatli girilmelidir.'],
      tips: ['Logonuzu yükleyerek e-fatura ve teklif şablonlarında otomatik görünmesini sağlayabilirsiniz.'],
      relatedRoutes: ['/settings/branches', '/settings/users'],
      searchableText: 'şirket unvan vkn vergi dairesi para birimi logo kurulum organizasyon',
      role: 'admin',
    ),

    // 2. Şube Yönetimi
    const HelpContent(
      id: 'help_branches',
      route: '/settings/branches',
      menuKey: 'branches',
      title: 'Şube ve Lokasyon Yönetimi',
      shortDescription: 'Farklı şehir veya lokasyonlardaki şubelerinizi ve merkez ofislerinizi tanımlayın.',
      longDescription: 'Şubeler, operasyonel satış ve depoların bağımsız raporlanmasını ve yetkilendirilmesini sağlar.',
      steps: [
        HelpStep(step: 1, title: 'Yeni Şube Ekleyin', desc: '"+ Yeni Şube" butonuna tıklayın.'),
        HelpStep(step: 2, title: 'Şube Kodunu Belirleyin', desc: 'SUB-01, IST-MERKEZ gibi benzersiz bir kod verin.'),
        HelpStep(step: 3, title: 'Adres ve İletişim', desc: 'Şubenin fiziksel adresini ve depo eşleşmesini yapın.'),
      ],
      warnings: ['Şube kapatıldığında açık siparişlerin başka şubeye devredilmesi gerekir.'],
      tips: ['Her şubeye özel fatura seri numarası ön eki (örn: IST2026) atayabilirsiniz.'],
      relatedRoutes: ['/settings/company', '/inventory/warehouses'],
      searchableText: 'şube lokasyon ofis merkez mağaza kod seri no',
      role: 'admin',
    ),

    // 3. Kullanıcı ve Yetki Yönetimi
    const HelpContent(
      id: 'help_users_roles',
      route: '/settings/users',
      menuKey: 'users',
      title: 'Kullanıcı, Personel ve Rol Yönetimi',
      shortDescription: 'Kullanıcı ekleyin, rol bazlı yetkilerini belirleyin ve şirket erişimlerini yönetin.',
      longDescription: 'RBAC (Role Based Access Control) mimarisiyle admin, muhasebeci, depo sorumlusu ve kasiyer yetkilerini izole edin.',
      steps: [
        HelpStep(step: 1, title: 'Kullanıcı Davet Edin', desc: 'Personelin kurumsal e-posta adresini girin.'),
        HelpStep(step: 2, title: 'Rol Seçin', desc: 'Admin, Muhasebeci, Satış veya Depo rolü atayın.'),
        HelpStep(step: 3, title: 'Şirket/Şube Kısıtlaması', desc: 'Kullanıcının sadece yetkili olduğu şubeleri seçin.'),
      ],
      warnings: ['Admin rolü kritik sistem ayarları ve API anahtarlarına tam erişim sağlar; dikkatli verilmelidir.'],
      tips: ['Ayrılan personelin hesabını silmek yerine "Pasife Al" ile tüm geçmiş denetim izini koruyun.'],
      relatedRoutes: ['/settings/roles'],
      searchableText: 'kullanıcı personel rol yetki izin şifre davet rbac admin muhasebeci',
      role: 'admin',
    ),

    // 4. Müşteriler (Cari)
    const HelpContent(
      id: 'help_customers',
      route: '/customers',
      menuKey: 'customers',
      title: 'Müşteri Yönetimi (Cari Hesaplar)',
      shortDescription: 'Müşterilerinizi oluşturun, bakiye durumlarını izleyin ve cari hareketleri yönetin.',
      longDescription: 'Müşteriler ekranı, firmanızın satış yaptığı tüm gerçek ve tüzel kişilerin cari kartlarının toplandığı merkezdir.',
      steps: [
        HelpStep(step: 1, title: 'Yeni Müşteri Butonuna Tıklayın', desc: 'Ekranın sağ üst köşesindeki "+ Yeni Müşteri" butonuna basın.'),
        HelpStep(step: 2, title: 'Temel Bilgileri Girin', desc: 'Müşteri unvanı, telefon numarası ve e-posta adresini eksiksiz doldurun.'),
        HelpStep(step: 3, title: 'Vergi ve Kimlik Bilgilerini Tanımlayın', desc: 'Kurumsal müşteriler için 10 haneli VKN, şahıslar için 11 haneli TCKN girin.'),
        HelpStep(step: 4, title: 'Finansal Koşulları Ayarlayın', desc: 'Para birimi, vade günü ve kredi risk limitini belirleyin.'),
        HelpStep(step: 5, title: 'Kaydet Butonuna Basın', desc: 'Bilgileri kontrol ettikten sonra "Kaydet" butonuna basarak cari kartı açın.'),
      ],
      warnings: ['VKN/TCKN alanı e-Fatura ve ZATCA gönderimlerinde resmi doğrulama için zorunludur.'],
      tips: ['Cari ekstre dökümünü PDF veya Excel olarak anında dışa aktarabilirsiniz.'],
      relatedRoutes: ['/sales/invoices', '/sales/orders'],
      searchableText: 'müşteri cari hesap ekstre bakiye vkn tckn borç alacak tahsilat risk limiti fatura kesmek',
      role: 'all',
    ),

    // 5. Tedarikçiler
    const HelpContent(
      id: 'help_suppliers',
      route: '/suppliers',
      menuKey: 'suppliers',
      title: 'Tedarikçi Yönetimi',
      shortDescription: 'Mal ve hizmet satın aldığınız tedarikçi firmaları ve borç bakiyelerini yönetin.',
      longDescription: 'Tedarikçi kartları, satın alma faturalarının ve tedarikçi ödemelerinin ilişkilendirildiği cari hesaplardır.',
      steps: [
        HelpStep(step: 1, title: 'Yeni Tedarikçi Ekleyin', desc: 'Tedarikçi unvanı ve vergi numarasını girin.'),
        HelpStep(step: 2, title: 'Banka ve IBAN Tanımlayın', desc: 'EFT/Havale ödemeleri için resmi IBAN bilgisini kaydedin.'),
        HelpStep(step: 3, title: 'Vade ve Sözleşme Koşulları', desc: 'Standart ödeme vadesini belirleyin.'),
      ],
      warnings: ['Mükerrer tedarikçi kartı açılmasını önlemek için vergi numarası ile arama yapın.'],
      tips: ['Tedarikçi borç yaşlandırma raporu ile vadesi gelen ödemelerinizi planlayabilirsiniz.'],
      relatedRoutes: ['/purchases/invoices', '/purchases/orders'],
      searchableText: 'tedarikçi satıcı borç ödeme satın alma iban fatura',
      role: 'all',
    ),

    // 6. Ürünler
    const HelpContent(
      id: 'help_products',
      route: '/inventory/products',
      menuKey: 'products',
      title: 'Ürün ve Hizmet Kataloğu',
      shortDescription: 'Ürünlerinizi, barkodlarını, satış fiyatlarını ve KDV oranlarını yönetin.',
      longDescription: 'Ürünler ekranı, stoklu mallarınızın ve stoksuz hizmetlerinizin tanımlandığı ana katalogdur.',
      steps: [
        HelpStep(step: 1, title: 'Yeni Ürün Ekleyin', desc: '"+ Yeni Ürün" butonuna basın.'),
        HelpStep(step: 2, title: 'Stok Kodu (SKU) ve Ad', desc: 'Ürüne benzersiz bir SKU ve açıklayıcı ürün adı verin.'),
        HelpStep(step: 3, title: 'Barkod Tanımlayın', desc: 'Kamera veya barkod okuyucu ile barkod numarasını sisteme girin.'),
        HelpStep(step: 4, title: 'KDV Oranı ve Birim', desc: 'Mevzuata uygun KDV oranı (%1, %10, %20) ve birimi (Adet, Kg) seçin.'),
        HelpStep(step: 5, title: 'Fiyatları Belirleyin ve Kaydedin', desc: 'Alış ve satış fiyatlarını para birimi ile birlikte girin.'),
      ],
      warnings: ['Fatura kesildikten sonra ürünün KDV oranı geriye dönük değiştirilemez.'],
      tips: ['Hızlı satış (POS) için ürünlere renkli kategoriler ve görseller atayabilirsiniz.'],
      relatedRoutes: ['/inventory/stocks', '/sales/invoices'],
      searchableText: 'ürün hizmet stok barkod sku kdv fiyat alış satış birim',
      role: 'all',
    ),

    // 7. Depo ve Stok Yönetimi
    const HelpContent(
      id: 'help_stocks',
      route: '/inventory/stocks',
      menuKey: 'inventory',
      title: 'Depo ve Stok Yönetimi',
      shortDescription: 'Fiziksel depolarınızdaki stok miktarlarını, kritik seviyeleri ve transferleri izleyin.',
      longDescription: 'Çift taraflı stok defteri (Stock Ledger) mimarisiyle her stok giriş ve çıkışı kaydedilir ve denetlenir.',
      steps: [
        HelpStep(step: 1, title: 'Mevcut Stokları İnceleyin', desc: 'Hangi depoda ne kadar stok olduğunu kontrol edin.'),
        HelpStep(step: 2, title: 'Depo Transferi Yapın', desc: 'Depolar arası mal transferi oluşturarak stokları güncelleyin.'),
        HelpStep(step: 3, title: 'Stok Sayımı ve Düzeltme', desc: 'Fiziksel sayım sonuçlarını girip sayım fark fişi oluşturun.'),
      ],
      warnings: ['Sistem ayarlarında negatif stok kapalıysa eldeki miktardan fazla çıkış yapılamaz.'],
      tips: ['Kritik stok seviyesi belirleyerek stok bitmeden otomatik satın alma uyarısı alabilirsiniz.'],
      relatedRoutes: ['/inventory/products', '/inventory/warehouses'],
      searchableText: 'stok depo sayım transfer kritik miktar rezerve mal kabul raf',
      role: 'warehouse',
    ),

    // 8. Satış Faturaları & E-Fatura
    const HelpContent(
      id: 'help_invoices',
      route: '/sales/invoices',
      menuKey: 'invoices',
      title: 'Satış Faturaları ve E-Fatura',
      shortDescription: 'Satış faturası düzenleyin, GİB veya ZATCA üzerinden e-fatura/e-arşiv olarak gönderin.',
      longDescription: 'Faturalar ekranı, tüm satış işlemlerinizin resmileştiği finansal kalbidir. Otomatik cari borç kaydı ve stok çıkışı üretir.',
      steps: [
        HelpStep(step: 1, title: 'Yeni Fatura Açın', desc: '"+ Yeni Fatura" butonuna basın.'),
        HelpStep(step: 2, title: 'Müşteriyi Seçin', desc: 'Cari listeden müşteriyi seçin; vergi bilgileri otomatik gelir.'),
        HelpStep(step: 3, title: 'Ürünleri Ekleyin', desc: 'Miktar, birim fiyat ve iskonto oranlarını belirleyin.'),
        HelpStep(step: 4, title: 'Vergi ve Tevkifat Kontrolü', desc: 'KDV tutarlarını ve varsa tevkifat kodlarını onaylayın.'),
        HelpStep(step: 5, title: 'Kaydet ve E-Fatura Gönder', desc: '"Resmi Belge Gönder" butonuna basarak GİB/ZATCA sistemine iletin.'),
      ],
      warnings: ['Resmi onay almış bir e-Fatura değiştirilemez. Düzeltme için İptal veya İade Faturası kesilmelidir.'],
      tips: ['Fatura üzerindeki QR kodu mobil cihazınızla okutarak ZATCA/GİB geçerliliğini test edebilirsiniz.'],
      relatedRoutes: ['/customers', '/inventory/products', '/settings/integrations'],
      searchableText: 'fatura e-fatura e-arşiv zatca gib ubl vergi tevkifat kdv satış fatura kesmek',
      role: 'all',
      documentationUrl: 'https://efatura.gib.gov.tr',
    ),

    // 9. Entegrasyonlar
    const HelpContent(
      id: 'help_integrations',
      route: '/settings/integrations',
      menuKey: 'integrations',
      title: 'Resmi Sistem ve ERP Entegrasyonları',
      shortDescription: 'GİB, ZATCA, Logo, QNB, SAP, Peppol ve harici ERP sistemleri ile entegrasyonu yapılandırın.',
      longDescription: 'Universal Integration Connector üzerinden tüm ülke resmi vergi sistemleri ve üçüncü parti ERP yazılımlarına bağlanın.',
      steps: [
        HelpStep(step: 1, title: 'Ülke Seçin', desc: 'Türkiye, Suudi Arabistan, BAE, AB veya diğer ülkeleri belirleyin.'),
        HelpStep(step: 2, title: 'Ortamı Belirleyin', desc: 'Önce mutlaka "SANDBOX" seçerek test edin. Canlıya doğrulamadan geçmeyin.'),
        HelpStep(step: 3, title: 'Kimlik Bilgilerini Girin', desc: 'API Key, Client Secret veya Mali Mühür/CSID yükleyin.'),
        HelpStep(step: 4, title: 'Bağlantıyı Test Edin', desc: '"Bağlantıyı Test Et" butonu ile yeşil ışık (SUCCESS) aldığınızdan emin olun.'),
        HelpStep(step: 5, title: 'Entegrasyonu Etkinleştirin', desc: 'Durumu aktif konuma getirin.'),
      ],
      warnings: ['Canlı ortam kimlik bilgilerini asla test ortamında denemeyiniz.'],
      tips: ['Sistem Sağlığı sekmesinden anlık API yanıt sürelerini ve kuyruk durumunu izleyebilirsiniz.'],
      relatedRoutes: ['/sales/invoices', '/settings/integrations/health'],
      searchableText: 'entegrasyon gib zatca logo qnb uyumsoft sovos peppol api webhook connector sandbox production',
      role: 'admin',
    ),

    // 10. Genel Muhasebe & Yevmiye
    const HelpContent(
      id: 'help_accounting',
      route: '/accounting/ledger',
      menuKey: 'accounting',
      title: 'Genel Muhasebe ve Yevmiye Defteri',
      shortDescription: 'Tekdüzen hesap planı, yevmiye kayıtları ve bilanço/mizan raporlarını izleyin.',
      longDescription: 'NAKHL çift taraflı (double-entry) muhasebe motoru, kesilen her fatura ve tahsilatta otomatik yevmiye kaydı oluşturur.',
      steps: [
        HelpStep(step: 1, title: 'Hesap Planını İnceleyin', desc: '100 Kasa, 120 Alıcılar, 320 Satıcılar hesap kodlarını kontrol edin.'),
        HelpStep(step: 2, title: 'Manuel Mahsup Fişi Girin', desc: 'Gerektiğinde serbest muhasebe fişi düzenleyin.'),
        HelpStep(step: 3, title: 'Mizan ve Bilanço Alın', desc: 'Dönemsel borç/alacak dengesini kontrol edin.'),
      ],
      warnings: ['Borç ve alacak toplamı birbirine eşit olmayan yevmiye fişleri kesinleştirilemez.'],
      tips: ['Dönem sonu kapanış fişleri sistem tarafından otomatik hesaplanabilir.'],
      relatedRoutes: ['/sales/invoices', '/finance/receipts'],
      searchableText: 'muhasebe yevmiye mizan bilanço hesap planı borç alacak mahsup defter kebir',
      role: 'accountant',
    ),

    // 11. Hızlı Satış (POS)
    const HelpContent(
      id: 'help_pos',
      route: '/pos',
      menuKey: 'pos',
      title: 'Hızlı Satış (POS Terminali)',
      shortDescription: 'Barkod okutarak saniyeler içinde perakende satış yapın ve fiş yazdırın.',
      longDescription: 'Dokunmatik ekran ve barkod okuyucu uyumlu POS terminali ile mağaza satışlarınızı yönetin.',
      steps: [
        HelpStep(step: 1, title: 'Kasa Açılışı Yapın', desc: 'Güne başlarken kasadaki nakit miktarını girin.'),
        HelpStep(step: 2, title: 'Ürünleri Okutun', desc: 'Barkod okutun veya ekrandaki favori butonlara dokunun.'),
        HelpStep(step: 3, title: 'Ödeme Alın', desc: 'Nakit, Kredi Kartı veya Parçalı Ödeme seçin.'),
        HelpStep(step: 4, title: 'Fiş/Fatura Yazdırın', desc: 'Satışı tamamlayıp termal yazıcıdan fişi çıkartın.'),
      ],
      warnings: ['Gün sonunda "Kasa Kapanışı (Z Raporu)" yapmayı unutmayın.'],
      tips: ['İnternet kesildiğinde POS çevrimdışı (offline) çalışır, bağlantı gelince otomatik senkronize olur.'],
      relatedRoutes: ['/inventory/products', '/sales/invoices'],
      searchableText: 'pos hızlı satış perakende kasa fiş barkod z raporu kasa açılış kapanış',
      role: 'pos',
    ),

    // 12. Yedekleme ve Güvenlik
    const HelpContent(
      id: 'help_backup',
      route: '/settings/backup',
      menuKey: 'backup',
      title: 'Yedekleme ve Felaket Kurtarma',
      shortDescription: 'Veritabanı yedeklerinizi indirin ve geri yükleme planınızı denetleyin.',
      longDescription: 'Verileriniz şifrelenmiş olarak düzenli yedeklenir. Şirket bazlı dışa aktarım (tenant export) alabilirsiniz.',
      steps: [
        HelpStep(step: 1, title: 'Anlık Yedek Alın', desc: '"Şimdi Yedekle" butonuna basarak anlık SQL/JSON yedeğinizi oluşturun.'),
        HelpStep(step: 2, title: 'Yedeği İndirin', desc: 'Oluşturulan yedeği güvenli harici diskinize indirin.'),
        HelpStep(step: 3, title: 'Geri Yükleme Testi', desc: 'Periyodik olarak test ortamında yedeği doğrulayın.'),
      ],
      warnings: ['Yedek dosyaları tüm finansal verilerinizi içerir; güvenli ortamda saklayın.'],
      tips: ['Günlük otomatik yedeklemeler bulutta 30 gün boyunca versiyonlu olarak korunur.'],
      relatedRoutes: ['/settings'],
      searchableText: 'yedekleme backup restore geri yükleme felaket kurtarma güvenlik export',
      role: 'admin',
    ),
  ];

  /// Predefined step-by-step task guides for common user goals
  static final List<TaskGuide> taskGuides = [
    const TaskGuide(
      id: 'task_first_sale',
      title: 'İlk Satışımı Yapmak İstiyorum',
      description: 'Müşteri seçiminden fatura kesimine ve tahsilata kadar uçtan uca satış rehberi.',
      category: 'Satış',
      targetRoute: '/sales/invoices',
      steps: [
        HelpStep(step: 1, title: 'Müşteri Seçin veya Ekleyin', desc: 'Müşteriler menüsünden cari kart açın veya seçin.'),
        HelpStep(step: 2, title: 'Ürünleri Sepete Ekleyin', desc: 'Satılacak ürünleri, adetlerini ve fiyatlarını belirleyin.'),
        HelpStep(step: 3, title: 'İskonto ve KDV Kontrolü', desc: 'Vergi ve indirim oranlarını kontrol edin.'),
        HelpStep(step: 4, title: 'Faturayı Kaydedin', desc: 'Fatura kaydedildiğinde müşteri borçlanır ve stok azalır.'),
        HelpStep(step: 5, title: 'Tahsilat Alın', desc: 'Nakit veya banka tahsilat makbuzunu oluşturun.'),
      ],
    ),
    const TaskGuide(
      id: 'task_opening_stocks',
      title: 'Açılış Stoklarımı Girmek İstiyorum',
      description: 'Sisteme ilk geçişte mevcut ambar sayım miktarlarını yükleme adımları.',
      category: 'Stok',
      targetRoute: '/inventory/stocks',
      steps: [
        HelpStep(step: 1, title: 'Depo Tanımlayın', desc: 'Fiziksel deponuzu Ayarlar > Depolar alanından oluşturun.'),
        HelpStep(step: 2, title: 'Ürün Kartlarını Açın', desc: 'Ürünlerinizi SKU ve barkodlarıyla tanımlayın.'),
        HelpStep(step: 3, title: 'Açılış Fişi Düzenleyin', desc: 'Stok Yönetimi > Açılış Fişi ile depodaki adetleri girin.'),
        HelpStep(step: 4, title: 'Maliyet Fiyatı Girin', desc: 'Ortalama maliyet hesabı için birim maliyetleri yazın.'),
        HelpStep(step: 5, title: 'Onaylayın', desc: 'Stok defteri güncellenir ve satışa hazır hale gelir.'),
      ],
    ),
    const TaskGuide(
      id: 'task_einvoice_setup',
      title: 'E-Fatura Entegrasyonunu Bağlamak İstiyorum',
      description: 'GİB veya ZATCA sistemine bağlanarak resmi e-fatura kesmeye başlama kılavuzu.',
      category: 'Entegrasyon',
      targetRoute: '/settings/integrations',
      steps: [
        HelpStep(step: 1, title: 'Entegrasyonlar Menüsüne Gidin', desc: 'Ayarlar > Entegrasyonlar sekmesini açın.'),
        HelpStep(step: 2, title: 'Ülke ve Sağlayıcı Seçin', desc: 'Türkiye (GİB/Logo/QNB) veya Suudi Arabistan (ZATCA) seçin.'),
        HelpStep(step: 3, title: 'Sandbox Ortamında Test Edin', desc: 'Test API bilgilerini girip "Bağlantıyı Test Et"e basın.'),
        HelpStep(step: 4, title: 'Mali Mühür / CSID Yükleyin', desc: 'Resmi üretim sertifikanızı sisteme tanımlayın.'),
        HelpStep(step: 5, title: 'Canlıya Alın', desc: 'Ortamı "Production" olarak işaretleyip aktif edin.'),
      ],
    ),
  ];

  /// Find help content matching a specific route or menuKey
  HelpContent? getContentByRoute(String route, {String role = 'all', String language = 'tr'}) {
    try {
      // First exact route match
      return defaultContents.firstWhere(
        (c) => c.route == route && c.language == language,
      );
    } catch (_) {
      try {
        // Fallback to closest match
        return defaultContents.firstWhere(
          (c) => route.startsWith(c.route) || c.route.startsWith(route),
        );
      } catch (_) {
        return defaultContents.first; // Fallback to company setup
      }
    }
  }

  /// Search help content with keyword and synonym matching
  List<HelpContent> search(String query, {String role = 'all', String language = 'tr'}) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return defaultContents;

    // Expand common synonyms
    final terms = <String>[clean];
    if (clean.contains('fatura') || clean.contains('kesmek')) {
      terms.addAll(['fatura', 'e-fatura', 'zatca', 'gib', 'satış']);
    }
    if (clean.contains('stok') || clean.contains('depo')) {
      terms.addAll(['stok', 'ürün', 'sayım', 'transfer', 'depo']);
    }
    if (clean.contains('müşteri') || clean.contains('cari')) {
      terms.addAll(['müşteri', 'cari', 'bakiye', 'borç', 'alacak']);
    }

    final results = defaultContents.where((c) {
      if (role != 'all' && c.role != 'all' && c.role != role) return false;
      final fullText = '${c.title} ${c.shortDescription} ${c.longDescription} ${c.searchableText}'.toLowerCase();
      return terms.any((t) => fullText.contains(t));
    }).toList();

    return results;
  }
}
