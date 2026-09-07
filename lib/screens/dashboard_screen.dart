// ============================================================
// YÖNETİCİ PANELİ EKRANI (DASHBOARD)
// ============================================================
// NAKHL & NAHL Kurumsal ERP Sistemi
//
// Bu ekran yönetici seviyesinde gerçek zamanlı:
//   1. Kasadaki toplam bakiye (Firestore: 'finansal_hareketler')
//   2. Depodaki toplam hurma tonajı (Firestore: 'stoklar')
//   3. Aktif müşteri ve cari sayısı (Supabase: 'cariler')
//   4. Devam eden lojistik sevkiyatlar (Firestore: 'sevkiyatlar')
//
// KPI özet kartlarını canlı StreamBuilder altyapısıyla gösterir
// ve alt navigasyon çubuğu ile Cari, Finans, Stok, Satış
// ekranlarına tek dokunuşla geçiş sağlar.
// ============================================================

import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'cari_kart_ekle_screen.dart';
import 'finans_islem_screen.dart';
import 'stok_yonetim_screen.dart';
import 'satis_fatura_screen.dart';
import 'ihracat_sevkiyat_screen.dart';
import 'raporlama_screen.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import '../services/mobil_entegrasyon_servisi.dart';
import '../services/opening_balance_service.dart';
import 'integrations/integration_settings_screen.dart';
import 'help/help_center_screen.dart';
import 'onboarding/first_time_setup_screen.dart';
import 'billing/module_store_screen.dart';
import 'migration/data_migration_screen.dart';
import 'admin/platform_admin_screen.dart';
import 'legislation/legislation_library_screen.dart';
import 'settings/user_parameters_screen.dart';
import '../core/i18n/locale_script_manager.dart';

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic>? sirketVerisi;

  const DashboardScreen({super.key, this.sirketVerisi});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Kurumsal Renk Paleti
  static const Color hurmaKahvesi = Color(0xFF5C4033);
  static const Color hurmaKahvesiKoyu = Color(0xFF3E2723);
  static const Color hurmaKahvesiAcik = Color(0xFF8D6E63);
  static const Color kremArkaplan = Color(0xFFFBF9F1);
  static const Color altinSarisi = Color(0xFFC89033);

  int _seciliAltIndeks = 0;

  // Şirket Parametreleri
  late String _sirketKodu;
  late String _ulkeKodu;
  late String _birincilDil;
  String? _ikincilDil;

  @override
  void initState() {
    super.initState();
    _sirketKodu = widget.sirketVerisi?['sirketKisaltmasi'] ?? 'HGLTD';
    _ulkeKodu = widget.sirketVerisi?['ulkeKodu'] ?? 'SA';
    _birincilDil = widget.sirketVerisi?['birincilDil'] ?? 'TR';
    _ikincilDil = widget.sirketVerisi?['ikincilDil'] ?? 'AR';
  }

  void _altNavigasyonaGit(int index) {
    if (index == 0) return; // Zaten Dashboard'dayız

    String modulKey;
    switch (index) {
      case 1:
        modulKey = 'cari';
        break;
      case 2:
        modulKey = 'finans';
        break;
      case 3:
        modulKey = 'stok';
        break;
      case 4:
        modulKey = 'satis';
        break;
      default:
        modulKey = '';
    }

    if (!AuthService.instance.yetkiVarMi(modulKey)) {
      final rolBaslik =
          AuthService.instance.aktifProfil?.rol.baslik ?? 'Mevcut Rol';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '⚠️ Yetki Sınırı: "$rolBaslik" bu ekrana erişim yetkisine sahip değildir.'),
          backgroundColor: hurmaKahvesiKoyu,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _seciliAltIndeks = 0);
      return;
    }

    Widget hedefSayfa;
    switch (index) {
      case 1:
        hedefSayfa = CariKartEkleScreen(
          bizimSirketKisaltmamiz: _sirketKodu,
          varsayilanUlkeKodu: _ulkeKodu,
          birincilDil: _birincilDil,
          ikincilDil: _ikincilDil,
        );
      case 2:
        hedefSayfa = const FinansIslemScreen();
      case 3:
        hedefSayfa = const StokYonetimScreen();
      case 4:
        hedefSayfa = const SatisFaturaScreen();
      default:
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => hedefSayfa),
    ).then((_) {
      if (mounted) setState(() => _seciliAltIndeks = 0);
    });
  }

  void _yetkiliSayfayaGit(String modulKey, Widget sayfa) {
    if (!AuthService.instance.yetkiVarMi(modulKey)) {
      final rolBaslik =
          AuthService.instance.aktifProfil?.rol.baslik ?? 'Mevcut Rol';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '⚠️ Yetki Sınırı: "$rolBaslik" bu modüle erişim yetkisine sahip değildir.'),
          backgroundColor: hurmaKahvesiKoyu,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => sayfa));
  }

  void _barkodSonucDialogunuGoster(BarkodDetayi sonuc) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: hurmaKahvesi.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(sonuc.tip.ikon, color: hurmaKahvesi, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sonuc.tip.baslik,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: hurmaKahvesiKoyu)),
                    const Text('Barkod Başarıyla Okundu',
                        style: TextStyle(fontSize: 11, color: Colors.green)),
                  ],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kremArkaplan,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Okunan Barkod / QR Değeri:',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 4),
                    SelectableText(
                      sonuc.hamKod,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: hurmaKahvesiKoyu),
                    ),
                    if (sonuc.baslik != null) ...[
                      const SizedBox(height: 8),
                      Text(sonuc.baslik!,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                    if (sonuc.altBilgi != null) ...[
                      const SizedBox(height: 2),
                      Text(sonuc.altBilgi!,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.black54)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Kapat', style: TextStyle(color: Colors.grey)),
            ),
            if (sonuc.tip == BarkodTipi.cariKodu)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _altNavigasyonaGit(1);
                },
                icon: const Icon(Icons.person, size: 16),
                label: const Text('Cariyi Aç'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: hurmaKahvesi,
                    foregroundColor: Colors.white),
              )
            else if (sonuc.tip == BarkodTipi.hurmaPaleti)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _altNavigasyonaGit(3);
                },
                icon: const Icon(Icons.inventory, size: 16),
                label: const Text('Stoğu İncele'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE65100),
                    foregroundColor: Colors.white),
              )
            else
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _altNavigasyonaGit(4);
                },
                icon: const Icon(Icons.point_of_sale, size: 16),
                label: const Text('Faturaya Ekle'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kremArkaplan,
      appBar: AppBar(
        backgroundColor: hurmaKahvesi,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.dashboard_customize_rounded,
                  color: altinSarisi, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NAKHL & NAHL',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8),
                ),
                Text(
                  'Yönetici Kontrol Paneli (${_sirketKodu.toUpperCase()})',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // FAZ 11: Hızlı Dil ve Alfabe Değiştirici
          PopupMenuButton<String>(
            icon: const Icon(Icons.language_rounded, color: altinSarisi),
            tooltip: 'Hızlı Dil / Alfabe Değiştir',
            onSelected: (langCode) async {
              await LocaleScriptManager.instance.switchToLanguage(langCode);
              setState(() {});
            },
            itemBuilder: (ctx) {
              final userLangs = LocaleScriptManager.instance.userLanguages;
              final catalog = LocaleScriptManager.languagesCatalog;
              return userLangs.map((lCode) {
                final l = catalog[lCode];
                final isCurrent = LocaleScriptManager.instance.activeLanguageCode == lCode;
                return PopupMenuItem(
                  value: lCode,
                  child: Row(
                    children: [
                      if (isCurrent) const Icon(Icons.check, size: 16, color: hurmaKahvesi) else const SizedBox(width: 16),
                      const SizedBox(width: 8),
                      Text('${l?.nativeName ?? lCode} (${lCode.toUpperCase()})'),
                    ],
                  ),
                );
              }).toList();
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Kullanıcı Parametreleri',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserParametersScreen()),
              ).then((_) => setState(() {}));
            },
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Kamera / Barkod & Cari Oku',

            onPressed: () async {
              final sonuc =
                  await MobilEntegrasyonServisi.barkodTaraModaliniAc(context);
              if (sonuc != null && context.mounted) {
                _barkodSonucDialogunuGoster(sonuc);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.hub_outlined),
            tooltip: 'Resmi Sistem & ERP Entegrasyonları',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const IntegrationSettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: '❓ NAKHL & NAHL Yardım ve Eğitim Merkezi',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const HelpCenterScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Raporlama Merkezi',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const RaporlamaScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.storefront_rounded),
            tooltip: 'Modül & Lisans Mağazası',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ModuleStoreScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.drive_folder_upload_rounded),
            tooltip: 'Veri Aktarımı & Geçiş Sihirbazı',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DataMigrationScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.gavel_rounded),
            tooltip: 'Mevzuat Kütüphanesi & Global Raflar',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LegislationLibraryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_rounded),
            tooltip: 'Platform Yönetim Merkezi',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlatformAdminScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Yenile',
            onPressed: () => setState(() {}),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Güvenli Çıkış Yap',
            onPressed: () async {
              await AuthService.instance.cikisYap();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. LÜKS KURUMSAL ÜST BİLGİ KARTI ──
            _kurumsalHeroKarti(),
            const SizedBox(height: 14),

            // ── TİCARİ MODÜL MAĞAZASI & VERİ AKTARIMI HIZLI ERİŞİM ──
            _ticariSaaSVeVeriAktarimBanneri(),
            const SizedBox(height: 18),

            // ── KURULUM EKSİKLERİ VE HIZLI TAMAMLAMA ──
            _kurulumEksikleriBanneri(),

            // ── BUGÜNÜN FOTOĞRAFI (AÇILIŞ & CANLI BİLANÇO ÖZETİ) ──
            _bugununFotografiKarti(),

            // ── GÜNLÜK KONTROL LİSTESİ (CHECKLIST) ──
            _gunlukKontrolListesiKarti(),

            // ── REHBERLİK & "BANA SİSTEMİ ÖĞRET" BANNERI ──
            _rehberlikVeEgitimBanneri(),
            const SizedBox(height: 18),

            // ── 2. GERÇEK ZAMANLI 4 ANA KPI KARTI (STREAMBUILDER) ──
            _bolumBasligi('📊 Canlı Performans & Finansal Durum',
                'Supabase Core Database gerçek zamanlı veri akışı:'),
            const SizedBox(height: 14),
            _canliKpiKartlariGrid(),
            const SizedBox(height: 24),

            // ── 3. HIZLI İŞLEM KISAYOLLARI ──
            _bolumBasligi(
                '⚡ Hızlı ERP İşlemleri', 'Tek dokunuşla ilgili modülü açın:'),
            const SizedBox(height: 12),
            _hizliIslemButonlari(),
            const SizedBox(height: 24),

            // ── 4. CANLI VERİ AKIŞLARI (SON FATURALAR & SEVKİYATLAR) ──
            _bolumBasligi('📑 Son Satış Faturaları',
                'En son onaylanan ve taslak fatura kayıtları:'),
            const SizedBox(height: 12),
            _sonFaturalarCanliListesi(),
            const SizedBox(height: 24),

            _bolumBasligi('🚢 Devam Eden Lojistik ve Sevkiyatlar',
                'Gümrükte ve yoldaki konteyner hareketleri:'),
            const SizedBox(height: 12),
            _sonSevkiyatlarCanliListesi(),
            const SizedBox(height: 30),
          ],
        ),
      ),

      // ── 4. ALT NAVİGASYON MENÜSÜ ──
      bottomNavigationBar: _altNavigasyonBari(),
    );
  }

  // ============================================================
  // BİLEŞEN: LÜKS KURUMSAL HERO KARTI
  // ============================================================

  Widget _kurumsalHeroKarti() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [hurmaKahvesi, hurmaKahvesiKoyu],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: hurmaKahvesi.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: Colors.greenAccent.withOpacity(0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fiber_manual_record,
                        color: Colors.greenAccent, size: 10),
                    SizedBox(width: 6),
                    Text(
                      'Sistem Çevrimiçi & Senkronize',
                      style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Text(
                'Mevzuat: ${_ulkeKodu.toUpperCase()}',
                style: const TextStyle(
                    color: altinSarisi,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'NAKHL & NAHL HURMA VE DIŞ TİCARET A.Ş.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Medine-i Münevvere Envanteri, Uluslararası Lojistik & Kasa Yönetimi',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: altinSarisi.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_user_rounded,
                        color: altinSarisi, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Yetki: ${AuthService.instance.aktifProfil?.rol.baslik ?? "Yönetici / Admin"}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Text(
                'Kullanıcı: ${AuthService.instance.aktifProfil?.adSoyad ?? "Sistem Yöneticisi"}',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BİLEŞEN: KURULUM EKSİKLERİ BANNERI
  // ============================================================

  Widget _kurulumEksikleriBanneri() {
    final deficiencies = OpeningBalanceService.instance.getSetupDeficiencies();
    if (deficiencies.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade400, width: 1.5),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 24),
              const SizedBox(width: 8),
              const Text(
                'İşletme Kurulum Eksiklikleri:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF5C4033)),
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: hurmaKahvesi,
                  foregroundColor: altinSarisi,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FirstTimeSetupScreen(
                        onSetupCompleted: () => setState(() {}),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.rocket_launch, size: 14),
                label: const Text('Sihirbazla Tamamla', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...deficiencies.map((d) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_right, size: 18, color: Colors.deepOrange),
                    Text(d, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ============================================================
  // BİLEŞEN: BUGÜNÜN FOTOĞRAFI (AÇILIŞ & CANLI BİLANÇO)
  // ============================================================

  Widget _bugununFotografiKarti() {
    final snap = OpeningBalanceService.instance.currentSnapshot;
    final currency = snap?.currency ?? (_ulkeKodu == 'SA' ? 'SAR' : 'TRY');
    final double kasa = snap?.totalCash ?? 45000.0;
    final double banka = snap?.totalBank ?? 185000.0;
    final double nakit = snap?.pocketCash ?? 5000.0;
    final double alacak = snap?.totalReceivables ?? 124000.0;
    final double borc = snap?.totalPayables ?? 68000.0;
    final double stok = snap?.totalInventoryValue ?? 310000.0;
    final double netWorth = (kasa + banka + nakit + alacak + stok) - borc;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: hurmaKahvesi.withOpacity(0.15)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.camera_alt_rounded, color: hurmaKahvesi, size: 24),
                  SizedBox(width: 8),
                  Text(
                    '📸 Bugünün Fotoğrafı (Finansal Durum & Bilanço)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: hurmaKahvesi),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hurmaKahvesi.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Açılış Tarihi: ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: hurmaKahvesi),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _fotoMiniKart('Kasa Nakdi', '${kasa.toStringAsFixed(0)} $currency', Icons.point_of_sale, Colors.green),
              _fotoMiniKart('Banka Mevduatı', '${banka.toStringAsFixed(0)} $currency', Icons.account_balance, Colors.blue),
              _fotoMiniKart('Eldeki Nakit', '${nakit.toStringAsFixed(0)} $currency', Icons.account_balance_wallet, Colors.teal),
              _fotoMiniKart('Müşteri Alacağı', '${alacak.toStringAsFixed(0)} $currency', Icons.arrow_downward, Colors.green.shade800),
              _fotoMiniKart('Tedarikçi Borcu', '${borc.toStringAsFixed(0)} $currency', Icons.arrow_upward, Colors.red.shade800),
              _fotoMiniKart('Depo Stok Değeri', '${stok.toStringAsFixed(0)} $currency', Icons.inventory_2, Colors.orange.shade900),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: hurmaKahvesi.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: hurmaKahvesi.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '💎 Net İşletme Varlığı (Özkaynak Değeri):',
                  style: TextStyle(fontWeight: FontWeight.bold, color: hurmaKahvesi, fontSize: 14),
                ),
                Text(
                  '${netWorth.toStringAsFixed(2)} $currency',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: hurmaKahvesiKoyu, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fotoMiniKart(String title, String value, IconData icon, Color color) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BİLEŞEN: GÜNLÜK İŞLETME KONTROL LİSTESİ (CHECKLIST)
  // ============================================================

  Widget _gunlukKontrolListesiKarti() {
    final items = OpeningBalanceService.instance.dailyChecklist;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: hurmaKahvesi.withOpacity(0.15)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.checklist_rounded, color: hurmaKahvesi, size: 24),
                  SizedBox(width: 8),
                  Text(
                    '📋 Günlük İşletme Kontrol Listesi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: hurmaKahvesi),
                  ),
                ],
              ),
              Text(
                'Tamamlanan: ${items.where((i) => i.isCompleted).length} / ${items.length}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, idx) {
              final item = items[idx];
              return CheckboxListTile(
                dense: true,
                value: item.isCompleted,
                activeColor: hurmaKahvesi,
                title: Text(
                  item.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                    color: item.isCompleted ? Colors.grey : Colors.black87,
                  ),
                ),
                subtitle: Text(item.description, style: const TextStyle(fontSize: 11)),
                onChanged: (_) {
                  setState(() {
                    OpeningBalanceService.instance.toggleChecklistItem(item.id);
                  });
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BİLEŞEN: REHBERLİK & "BANA SİSTEMİ ÖĞRET" BANNERI
  // ============================================================

  Widget _rehberlikVeEgitimBanneri() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hurmaKahvesi.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hurmaKahvesi.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.school_rounded, color: hurmaKahvesi, size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Ne Yapacağınızı Bilmiyor musunuz?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: hurmaKahvesi),
                ),
                SizedBox(height: 2),
                Text(
                  'Sistem size günlük işletme adımlarını (Kasa açılışı, satış, tahsilat, gün sonu) sırayla öğretir.',
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: hurmaKahvesi,
              foregroundColor: altinSarisi,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onPressed: () => _bilmiyorumRehberiModaliniAc(context),
            icon: const Icon(Icons.explore_rounded, size: 16),
            label: const Text('Bana Sistemi Öğret', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _bilmiyorumRehberiModaliniAc(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.explore, color: hurmaKahvesi),
            SizedBox(width: 8),
            Text('Günlük İşletme Rehberi'),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Bir günde sırasıyla ne yapmalısınız?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: hurmaKahvesi),
              ),
              SizedBox(height: 12),
              Text('1. Sabah: Kasanızdaki nakdi sayın ve Kasa Defteri ile karşılaştırın.'),
              SizedBox(height: 6),
              Text('2. Gün Boyunca: Müşteriye her ürün tesliminde "Yeni Satış" girin.'),
              SizedBox(height: 6),
              Text('3. Tahsilat: Elden nakit veya bankadan para aldığınızda "Tahsilat" butonuna basın.'),
              SizedBox(height: 6),
              Text('4. Satın Alma: Tedarikçiden hurma/mal aldığınızda faturayı sisteme girin.'),
              SizedBox(height: 6),
              Text('5. Ödeme: Tedarikçiye ödeme yaptığınızda "Ödeme Yap" fişini kesin.'),
              SizedBox(height: 6),
              Text('6. Akşam: Gün sonu sayımını tamamlayıp Kasa Defterini kapatın.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Anladım', style: TextStyle(color: hurmaKahvesi, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _bolumBasligi(String baslik, String aciklama) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          baslik,
          style: const TextStyle(
              color: hurmaKahvesiKoyu,
              fontSize: 16,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          aciklama,
          style: const TextStyle(color: hurmaKahvesiAcik, fontSize: 12),
        ),
      ],
    );
  }

  // ============================================================
  // BİLEŞEN: GERÇEK ZAMANLI 4 KPI KARTI (STREAMBUILDER)
  // ============================================================

  Widget _canliKpiKartlariGrid() {
    return Column(
      children: [
        // Satır 1: Kasa Bakiyesi + Depo Tonajı
        Row(
          children: [
            // KPI 1: KASA TOPLAM BAKİYE (Supabase 'journal_entries')
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: SupabaseService.client
                    .from('journal_entries')
                    .stream(primaryKey: ['id']),
                builder: (context, snapshot) {
                  double bakiyeSar = 0.0;
                  int islemSayisi = 0;

                  if (snapshot.hasData && snapshot.data != null) {
                    final docs = snapshot.data!;
                    islemSayisi = docs.length;
                    for (final doc in docs) {
                      final tutar =
                          (doc['total_debit'] as num?)?.toDouble() ?? 0.0;
                      final tur = doc['entry_type']?.toString() ?? 'Tahsilat';
                      if (tur.toLowerCase().contains('sales') ||
                          tur.toLowerCase().contains('tahsilat')) {
                        bakiyeSar += tutar;
                      } else {
                        bakiyeSar -= tutar;
                      }
                    }
                  }

                  return _kpiKarti(
                    baslik: 'Kasadaki Bakiye',
                    anaDeger: '${bakiyeSar.toStringAsFixed(0)} SAR',
                    altBilgi: '$islemSayisi Muhasebe Kaydı',
                    icon: Icons.account_balance_wallet_rounded,
                    anaRenk: const Color(0xFF2E7D32),
                    yukleniyor:
                        snapshot.connectionState == ConnectionState.waiting,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const FinansIslemScreen())),
                  );
                },
              ),
            ),
            const SizedBox(width: 14),

            // KPI 2: DEPO TOPLAM TONAJ (Supabase 'items')
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: SupabaseService.client
                    .from('items')
                    .stream(primaryKey: ['id']),
                builder: (context, snapshot) {
                  double toplamTonaj = 0.0;
                  int cesitSayisi = 0;

                  if (snapshot.hasData && snapshot.data != null) {
                    final docs = snapshot.data!;
                    cesitSayisi = docs.length;
                    for (final doc in docs) {
                      final miktar = (doc['miktar'] as num?)?.toDouble() ?? 0.0;
                      final birim = doc['birim']?.toString() ??
                          doc['unit_of_measure']?.toString() ??
                          'Ton';
                      if (birim == 'Ton') {
                        toplamTonaj += miktar;
                      } else if (birim == 'Kg') {
                        toplamTonaj += miktar / 1000.0;
                      } else {
                        toplamTonaj += miktar * 0.01;
                      }
                    }
                  }

                  return _kpiKarti(
                    baslik: context.tr('dashboard.kpi.inventory_weight', fallback: 'Depo Envanter / Ürün Tonajı'),
                    anaDeger: '${toplamTonaj.toStringAsFixed(1)} Ton',
                    altBilgi: '$cesitSayisi ${context.tr("menu.product", fallback: "Ürün")} Çeşidi',
                    icon: Icons.inventory_2_rounded,
                    anaRenk: const Color(0xFFE65100),

                    yukleniyor:
                        snapshot.connectionState == ConnectionState.waiting,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const StokYonetimScreen())),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Satır 2: Aktif Müşteriler + Devam Eden Sevkiyatlar
        Row(
          children: [
            // KPI 3: AKTİF MÜŞTERİ SAYISI (Supabase 'cariler')
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: SupabaseService.carileriGetirStream(),
                builder: (context, snapshot) {
                  int cariSayisi = 0;
                  int musteriSayisi = 0;

                  if (snapshot.hasData && snapshot.data != null) {
                    final list = snapshot.data!;
                    cariSayisi = list.length;
                    musteriSayisi = list
                        .where(
                            (c) => c['tip'] == 'Müşteri' || c['tip'] == 'Ortak')
                        .length;
                  }

                  return _kpiKarti(
                    baslik: 'Aktif Cariler',
                    anaDeger: '$cariSayisi Cari',
                    altBilgi: '$musteriSayisi Alıcı / Müşteri',
                    icon: Icons.people_alt_rounded,
                    anaRenk: const Color(0xFF1565C0),
                    yukleniyor:
                        snapshot.connectionState == ConnectionState.waiting,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CariKartEkleScreen(
                          bizimSirketKisaltmamiz: _sirketKodu,
                          varsayilanUlkeKodu: _ulkeKodu,
                          birincilDil: _birincilDil,
                          ikincilDil: _ikincilDil,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 14),

            // KPI 4: DEVAM EDEN SEVKİYATLAR (Supabase 'shipments')
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: SupabaseService.client
                    .from('shipments')
                    .stream(primaryKey: ['id']),
                builder: (context, snapshot) {
                  int aktifSevkiyat = 0;
                  int transitSayisi = 0;

                  if (snapshot.hasData && snapshot.data != null) {
                    final docs = snapshot.data!;
                    for (final doc in docs) {
                      final durum = doc['sevkiyatDurumu']?.toString() ??
                          doc['status']?.toString() ??
                          'Hazırlanıyor';
                      if (durum != 'Teslim Edildi' && durum != 'delivered') {
                        aktifSevkiyat++;
                        if (durum == 'Yolda' ||
                            durum == 'Gümrükte' ||
                            durum == 'in_transit' ||
                            durum == 'customs') {
                          transitSayisi++;
                        }
                      }
                    }
                  }

                  return _kpiKarti(
                    baslik: 'Aktif Sevkiyatlar',
                    anaDeger: '$aktifSevkiyat Sevk',
                    altBilgi: '$transitSayisi Transit / Gümrükte',
                    icon: Icons.local_shipping_rounded,
                    anaRenk: const Color(0xFF6A1B9A),
                    yukleniyor:
                        snapshot.connectionState == ConnectionState.waiting,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const IhracatSevkiyatScreen())),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _kpiKarti({
    required String baslik,
    required String anaDeger,
    required String altBilgi,
    required IconData icon,
    required Color anaRenk,
    required bool yukleniyor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: anaRenk.withOpacity(0.25)),
            boxShadow: [
              BoxShadow(
                color: anaRenk.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: anaRenk.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: anaRenk, size: 22),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: Colors.black26),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                baslik,
                style: TextStyle(
                  color: hurmaKahvesi.withOpacity(0.75),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              if (yukleniyor)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                Text(
                  anaDeger,
                  style: const TextStyle(
                    color: hurmaKahvesiKoyu,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: 3),
              Text(
                altBilgi,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BİLEŞEN: HIZLI İŞLEM BUTONLARI
  // ============================================================

  Widget _hizliIslemButonlari() {
    return ResponsiveAksiyonButonlari(
      aralik: 10,
      butonlar: [
        _hizliAksiyonButonu(
          icon: Icons.point_of_sale_rounded,
          etiket: 'Yeni Fatura',
          renk: const Color(0xFF2E7D32),
          onTap: () => _yetkiliSayfayaGit('satis', const SatisFaturaScreen()),
        ),
        _hizliAksiyonButonu(
          icon: Icons.qr_code_scanner_rounded,
          etiket: 'Barkod Oku',
          renk: const Color(0xFF1565C0),
          onTap: () async {
            final sonuc =
                await MobilEntegrasyonServisi.barkodTaraModaliniAc(context);
            if (sonuc != null && mounted) {
              _barkodSonucDialogunuGoster(sonuc);
            }
          },
        ),
        _hizliAksiyonButonu(
          icon: Icons.analytics_rounded,
          etiket: 'Rapor Al',
          renk: hurmaKahvesi,
          onTap: () => _yetkiliSayfayaGit('rapor', const RaporlamaScreen()),
        ),
        _hizliAksiyonButonu(
          icon: Icons.add_business_rounded,
          etiket: 'Yeni Stok',
          renk: const Color(0xFFE65100),
          onTap: () => _yetkiliSayfayaGit('stok', const StokYonetimScreen()),
        ),
      ],
    );
  }

  Widget _hizliAksiyonButonu({
    required IconData icon,
    required String etiket,
    required Color renk,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(etiket,
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: renk,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }

  // ============================================================
  // BİLEŞEN: SON FATURALAR CANLI LİSTESİ
  // ============================================================

  Widget _sonFaturalarCanliListesi() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: SupabaseService.client
          .from('journal_entries')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .limit(3),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator()));
        }

        final docs = snapshot.data ?? [];

        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: const Center(
              child: Text(
                'Henüz kayıtlı fatura bulunmuyor. "Yeni Fatura" ile oluşturabilirsiniz.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final faturaNo =
                doc['faturaNo'] ?? doc['entry_number'] ?? 'FAT-???';
            final cari = doc['cariUnvani'] ?? doc['description'] ?? 'Cari';
            final toplam = (doc['genelToplam'] as num?)?.toDouble() ??
                (doc['total_debit'] as num?)?.toDouble() ??
                0.0;
            final pb = doc['paraBirimi'] ?? doc['currency'] ?? 'SAR';
            final durum = doc['durum'] ??
                (doc['status'] == 'POSTED' ? 'Onaylandı' : 'Taslak');
            final onayli = durum == 'Onaylandı';

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0.5,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      onayli ? Colors.green.shade100 : Colors.amber.shade100,
                  child: Icon(
                    onayli
                        ? Icons.verified_rounded
                        : Icons.pending_actions_rounded,
                    color:
                        onayli ? Colors.green.shade800 : Colors.amber.shade800,
                    size: 20,
                  ),
                ),
                title: Text(cari,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13.5)),
                subtitle: Text('$faturaNo  •  $durum',
                    style: const TextStyle(fontSize: 11)),
                trailing: Text(
                  '${toplam.toStringAsFixed(2)} $pb',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: hurmaKahvesi),
                ),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SatisFaturaScreen())),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ============================================================
  // BİLEŞEN: SON SEVKİYATLAR CANLI LİSTESİ
  // ============================================================

  Widget _sonSevkiyatlarCanliListesi() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: SupabaseService.client
          .from('shipments')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .limit(3),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator()));
        }

        final docs = snapshot.data ?? [];

        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: const Center(
              child: Text(
                'Kayıtlı sevkiyat bulunmuyor. "İhracat & Lojistik" ekranından ekleyebilirsiniz.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final musteri = doc['cariUnvani'] ??
                doc['carrier_name'] ??
                'Bilinmeyen Müşteri';
            final urun = doc['urunCesidi'] ?? 'Hurma';
            final durum =
                doc['sevkiyatDurumu'] ?? doc['status'] ?? 'Hazırlanıyor';
            final liman =
                doc['cikisLimani'] ?? doc['port_of_loading'] ?? 'Liman';
            final miktar = (doc['miktar'] as num?)?.toDouble() ?? 0.0;
            final birim = doc['birim'] ?? 'Ton';

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0.5,
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEDE7F6),
                  child: Icon(Icons.local_shipping_rounded,
                      color: Color(0xFF6A1B9A), size: 20),
                ),
                title: Text(musteri,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13.5)),
                subtitle: Text('$urun ($miktar $birim)  •  $liman',
                    style: const TextStyle(fontSize: 11)),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: Text(
                    durum,
                    style: TextStyle(
                        color: Colors.purple.shade900,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const IhracatSevkiyatScreen())),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ============================================================
  // BİLEŞEN: TİCARİ MODÜL MAĞAZASI & VERİ AKTARIMI HIZLI ERİŞİM
  // ============================================================

  Widget _ticariSaaSVeVeriAktarimBanneri() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: altinSarisi.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: altinSarisi.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: altinSarisi.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.rocket_launch_rounded,
                color: altinSarisi, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SaaS Paketleri & Veri Aktarımı',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: hurmaKahvesi),
                ),
                const SizedBox(height: 2),
                Text(
                  '18 ticari modül, çoklu para birimi ve Logo/Mikro/Excel aktarım sihirbazı.',
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: hurmaKahvesi,
              side: const BorderSide(color: hurmaKahvesi),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DataMigrationScreen()),
              );
            },
            icon: const Icon(Icons.drive_folder_upload_rounded, size: 16),
            label: const Text('Veri Aktar', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: hurmaKahvesi,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ModuleStoreScreen()),
              );
            },
            icon: const Icon(Icons.storefront_rounded, size: 16),
            label: const Text('Mağaza', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: hurmaKahvesi,
              side: const BorderSide(color: hurmaKahvesi),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LegislationLibraryScreen()),
              );
            },
            icon: const Icon(Icons.gavel_rounded, size: 16),
            label: const Text('Mevzuat', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BİLEŞEN: ALT NAVİGASYON MENÜSÜ (BOTTOM NAVIGATION)
  // ============================================================

  Widget _altNavigasyonBari() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _seciliAltIndeks,
        onTap: _altNavigasyonaGit,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: hurmaKahvesi,
        unselectedItemColor: Colors.grey.shade500,
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 10.5),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_rounded),
            label: context.tr('menu.dashboard', fallback: 'Panel'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people_alt_rounded),
            label: context.tr('menu.customers', fallback: 'Cariler'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_wallet_rounded),
            label: context.tr('menu.finance', fallback: 'Finans'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.inventory_2_rounded),
            label: context.tr('menu.product', fallback: 'Ürün'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.point_of_sale_rounded),
            label: context.tr('menu.sales', fallback: 'Satış'),
          ),
        ],

      ),
    );
  }
}
