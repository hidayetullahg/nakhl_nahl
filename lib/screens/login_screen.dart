// ============================================================
// NAKHL & NAHL — KURUMSAL GÜVENLİ GİRİŞ EKRANI (LOGIN SCREEN)
// ============================================================
// Özellikler:
// 1. Supabase Authentication E-posta & Şifre doğrulaması
// 2. 2FA (İki Aşamalı Doğrulama / 4 Haneli Hızlı PIN)
// 3. Rol Seçimi ve Yetkilendirme (Yönetici, Muhasebe, Depo Sorumlusu)
// 4. Hurma Kahvesi (#5C4033) ve Krem (#FBF9F1) Lüks Tasarım
// ============================================================

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'tenant_selection_screen.dart';
import 'onboarding/first_time_setup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // Kurumsal Renk Paleti
  static const Color hurmaKahvesi = Color(0xFF5C4033);
  static const Color hurmaKahvesiKoyu = Color(0xFF3E2723);
  static const Color hurmaKahvesiAcik = Color(0xFF8D6E63);
  static const Color kremArkaplan = Color(0xFFFBF9F1);
  static const Color altinSarisi = Color(0xFFC89033);

  late TabController _tabController;

  // E-Posta Giriş Formu Denetleyicileri
  final _girisFormKey = GlobalKey<FormState>();
  final _emailController =
      TextEditingController(text: 'yonetici@nakhlnahl.com');
  final _sifreController = TextEditingController(text: '123456');
  bool _sifreGizli = true;
  bool _yukleniyor = false;

  // Hızlı PIN Giriş Denetleyicisi
  final _pinController = TextEditingController();
  bool _pinHatasi = false;

  // Yeni Personel Kayıt Denetleyicileri
  final _kayitFormKey = GlobalKey<FormState>();
  final _kayitAdSoyadController = TextEditingController();
  final _kayitEmailController = TextEditingController();
  final _kayitSifreController = TextEditingController();
  final _kayitPinController = TextEditingController();
  KullaniciRolu _seciliRol = KullaniciRolu.admin;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _sifreController.dispose();
    _pinController.dispose();
    _kayitAdSoyadController.dispose();
    _kayitEmailController.dispose();
    _kayitSifreController.dispose();
    _kayitPinController.dispose();
    super.dispose();
  }

  // ============================================================
  // GİRİŞ İŞLEMLERİ
  // ============================================================

  /// E-posta & Şifre ile Supabase Auth Girişi ve ardından 2FA PIN Doğrulaması
  Future<void> _emailIleGirisYap() async {
    if (!_girisFormKey.currentState!.validate()) return;

    setState(() => _yukleniyor = true);

    try {
      final profil = await AuthService.instance.emailIleGiris(
        email: _emailController.text.trim(),
        sifre: _sifreController.text,
      );

      if (!mounted) return;
      setState(() => _yukleniyor = false);

      // İki Aşamalı Güvenlik (2FA) PIN Giriş Modalı
      _pinDogrulamaDialogunuAc(profil);
    } catch (e) {
      if (!mounted) return;
      setState(() => _yukleniyor = false);
      _hataMesajiGoster(e.toString().replaceAll('Exception:', '').trim());
    }
  }

  /// Doğrudan 4 Haneli PIN ile Hızlı Giriş (Kayıtlı cihazlar / Güvenli tabletler için)
  void _hizliPinIleGiris() {
    final girilenPin = _pinController.text.trim();
    if (girilenPin.length < 4) {
      setState(() => _pinHatasi = true);
      return;
    }

    if (AuthService.instance.pinDogrula(girilenPin)) {
      setState(() => _pinHatasi = false);
      // Varsayılan Yönetici veya Aktif oturum
      AuthService.instance
          .demoOturumAyarla(KullaniciRolu.admin, adSoyad: 'Sistem Yöneticisi');
      _basariliGirisYonlendir();
    } else {
      setState(() => _pinHatasi = true);
      _hataMesajiGoster(
          'Hatalı 2FA PIN kodu.');
    }
  }

  /// Yeni Personel Kaydı ve Rol Ataması
  Future<void> _yeniPersonelKaydet() async {
    if (!_kayitFormKey.currentState!.validate()) return;

    setState(() => _yukleniyor = true);

    try {
      final profil = await AuthService.instance.kayitOl(
        email: _kayitEmailController.text.trim(),
        sifre: _kayitSifreController.text,
        adSoyad: _kayitAdSoyadController.text.trim(),
        rol: _seciliRol,
        pinKodu: _kayitPinController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _yukleniyor = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '✅ ${_seciliRol.baslik} rolüyle kullanıcı başarıyla oluşturuldu!'),
          backgroundColor: Colors.green.shade800,
        ),
      );

      _pinDogrulamaDialogunuAc(profil);
    } catch (e) {
      if (!mounted) return;
      setState(() => _yukleniyor = false);
      _hataMesajiGoster(e.toString().replaceAll('Exception:', '').trim());
    }
  }

  /// Hızlı Rol Demo Girişi (Tek tıkla rol test etme kolaylığı)
  void _hizliRolGiris(KullaniciRolu rol) {
    AuthService.instance.demoOturumAyarla(rol);
    _basariliGirisYonlendir();
  }

  /// 2FA PIN Doğrulama Penceresi
  void _pinDogrulamaDialogunuAc(KullaniciProfili profil) {
    final dialogPinController = TextEditingController();
    bool dialogPinHatasi = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: hurmaKahvesi.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.shield_outlined,
                        color: hurmaKahvesi, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('2FA Güvenlik Doğrulaması',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: hurmaKahvesiKoyu)),
                        Text('İkinci Aşama PIN Kodu',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Hoş geldiniz Sayın ${profil.adSoyad}.\nRolünüz: ${profil.rol.baslik}\nDevam etmek için 4 haneli PIN kodunuzu girin:',
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: dialogPinController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    textAlign: TextAlign.center,
                    autofocus: true,
                    style: const TextStyle(
                        fontSize: 26,
                        letterSpacing: 10,
                        fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '••••',
                      errorText: dialogPinHatasi ? 'Hatalı PIN' : null,
                      filled: true,
                      fillColor: kremArkaplan,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: hurmaKahvesi)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: hurmaKahvesi, width: 2)),
                    ),
                    onChanged: (val) {
                      if (val.length == 4) {
                        if (AuthService.instance.pinDogrula(val)) {
                          Navigator.pop(ctx);
                          _basariliGirisYonlendir();
                        } else {
                          setModalState(() => dialogPinHatasi = true);
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text('Lütfen Güvenlik PIN kodunuzu girin',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Vazgeç',
                      style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (AuthService.instance
                        .pinDogrula(dialogPinController.text)) {
                      Navigator.pop(ctx);
                      _basariliGirisYonlendir();
                    } else {
                      setModalState(() => dialogPinHatasi = true);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hurmaKahvesi,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Onayla ve Giriş Yap'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _basariliGirisYonlendir() {
    final rol = AuthService.instance.aktifProfil?.rol ?? KullaniciRolu.admin;
    final adSoyad = AuthService.instance.aktifProfil?.adSoyad ?? 'Yetkili';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('✨ Giriş Başarılı! Hoş geldiniz, $adSoyad (${rol.baslik})'),
        backgroundColor: hurmaKahvesiKoyu,
        duration: const Duration(seconds: 2),
      ),
    );

    // Giriş sonrası Tenant / Şirket Seçim Ekranı
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const TenantSelectionScreen()),
    );
  }

  void _hataMesajiGoster(String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $mesaj'),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // ARAYÜZ OLUŞTURMA
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final ekranBoyutu = MediaQuery.of(context).size;
    final genisEkran = ekranBoyutu.width > 750;

    return Scaffold(
      backgroundColor: kremArkaplan,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          child: Container(
            width: genisEkran ? 520 : double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: hurmaKahvesi.withOpacity(0.16),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── 1. LÜKS ÜST KURUMSAL BANNER ──
                _ustKurumsalBanner(),

                // ── 2. SEKMELER (TABBAR) ──
                Container(
                  color: Colors.grey.shade50,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: hurmaKahvesi,
                    indicatorWeight: 3,
                    labelColor: hurmaKahvesi,
                    unselectedLabelColor: Colors.grey.shade600,
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                    tabs: const [
                      Tab(
                          icon: Icon(Icons.email_outlined, size: 20),
                          text: 'E-Posta'),
                      Tab(
                          icon: Icon(Icons.dialpad_rounded, size: 20),
                          text: 'Hızlı PIN'),
                      Tab(
                          icon: Icon(Icons.person_add_alt_1_outlined, size: 20),
                          text: 'Yeni Personel'),
                    ],
                  ),
                ),

                // ── 3. SEKME İÇERİKLERİ ──
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    height: 380,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _emailGirisSekmesi(),
                        _hizliPinSekmesi(),
                        _yeniPersonelSekmesi(),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 1),

                // ── 4. HIZLI ROL TESTİ / DEMO ERİŞİMİ ──
                _hizliRolTestAlani(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BİLEŞEN: ÜST KURUMSAL BANNER
  // ============================================================

  Widget _ustKurumsalBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [hurmaKahvesi, hurmaKahvesiKoyu],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              shape: BoxShape.circle,
              border:
                  Border.all(color: altinSarisi.withOpacity(0.6), width: 1.5),
            ),
            child: const Icon(Icons.lock_person_rounded,
                color: altinSarisi, size: 36),
          ),
          const SizedBox(height: 12),
          const Text(
            'NAKHL & NAHL',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Kurumsal ERP & Yetkilendirme Giriş Portalı',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEKME 1: E-POSTA VE ŞİFRE İLE GİRİŞ
  // ============================================================

  Widget _emailGirisSekmesi() {
    return Form(
      key: _girisFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 6),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Kurumsal E-Posta',
              hintText: 'ad.soyad@nakhlnahl.com',
              prefixIcon:
                  const Icon(Icons.alternate_email, color: hurmaKahvesi),
              filled: true,
              fillColor: kremArkaplan,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) => (v == null || !v.contains('@'))
                ? 'Geçerli bir e-posta girin'
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _sifreController,
            obscureText: _sifreGizli,
            decoration: InputDecoration(
              labelText: 'Şifre',
              prefixIcon: const Icon(Icons.key_rounded, color: hurmaKahvesi),
              suffixIcon: IconButton(
                icon: Icon(
                    _sifreGizli ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey),
                onPressed: () => setState(() => _sifreGizli = !_sifreGizli),
              ),
              filled: true,
              fillColor: kremArkaplan,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) => (v == null || v.length < 6)
                ? 'Şifre en az 6 karakter olmalıdır'
                : null,
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _hataMesajiGoster(
                  'Şifre sıfırlama için Sistem Yöneticinize başvurun.'),
              child: const Text('Şifremi Unuttum',
                  style: TextStyle(color: hurmaKahvesiAcik, fontSize: 12)),
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _yukleniyor ? null : _emailIleGirisYap,
            icon: _yukleniyor
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.arrow_forward_rounded),
            label: Text(_yukleniyor
                ? 'Kimlik Doğrulanıyor...'
                : 'Güvenli Giriş Yap (2FA)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: hurmaKahvesi,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEKME 2: HIZLI 4 HANELİ PIN (2FA)
  // ============================================================

  Widget _hizliPinSekmesi() {
    return Column(
      children: [
        const SizedBox(height: 10),
        const Text(
          'Yetkili Cihazlar İçin Hızlı PIN Girişi',
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: hurmaKahvesiKoyu),
        ),
        const SizedBox(height: 4),
        const Text(
          'Daha önce eşleştirilmiş terminal veya şirket cihazınız için 4 haneli PIN girin:',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: 240,
          child: TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 30, letterSpacing: 16, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              counterText: '',
              hintText: '••••',
              errorText: _pinHatasi ? 'Hatalı PIN' : null,
              filled: true,
              fillColor: kremArkaplan,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: hurmaKahvesi, width: 2)),
            ),
            onChanged: (val) {
              if (val.length == 4) _hizliPinIleGiris();
              if (_pinHatasi) setState(() => _pinHatasi = false);
            },
          ),
        ),
        const SizedBox(height: 10),
        const Text('Güvenli PIN Kodunuz',
            style: TextStyle(fontSize: 11, color: Colors.grey)),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: _hizliPinIleGiris,
          icon: const Icon(Icons.fingerprint_rounded),
          label: const Text('PIN ile Oturum Aç'),
          style: ElevatedButton.styleFrom(
            backgroundColor: hurmaKahvesi,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SEKME 3: YENİ PERSONEL VE ROL ATAMA
  // ============================================================

  Widget _yeniPersonelSekmesi() {
    return Form(
      key: _kayitFormKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _kayitAdSoyadController,
              decoration: InputDecoration(
                labelText: 'Ad Soyad',
                prefixIcon:
                    const Icon(Icons.badge_outlined, color: hurmaKahvesi),
                isDense: true,
                filled: true,
                fillColor: kremArkaplan,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Ad Soyad zorunludur'
                  : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _kayitEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Kurumsal E-Posta',
                prefixIcon:
                    const Icon(Icons.email_outlined, color: hurmaKahvesi),
                isDense: true,
                filled: true,
                fillColor: kremArkaplan,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              validator: (v) => (v == null || !v.contains('@'))
                  ? 'Geçerli e-posta girin'
                  : null,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _kayitSifreController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Şifre (Min 6)',
                      prefixIcon:
                          const Icon(Icons.lock_outline, color: hurmaKahvesi),
                      isDense: true,
                      filled: true,
                      fillColor: kremArkaplan,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (v) =>
                        (v == null || v.length < 6) ? 'Min 6 hane' : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _kayitPinController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    decoration: InputDecoration(
                      labelText: '2FA PIN',
                      counterText: '',
                      prefixIcon:
                          const Icon(Icons.dialpad, color: hurmaKahvesi),
                      isDense: true,
                      filled: true,
                      fillColor: kremArkaplan,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (v) =>
                        (v == null || v.length < 4) ? '4 haneli' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // ROL SEÇİMİ
            DropdownButtonFormField<KullaniciRolu>(
              value: _seciliRol,
              decoration: InputDecoration(
                labelText: 'Atanacak Yetki Rolü',
                prefixIcon: const Icon(Icons.admin_panel_settings_outlined,
                    color: hurmaKahvesi),
                isDense: true,
                filled: true,
                fillColor: kremArkaplan,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: KullaniciRolu.values.map((r) {
                return DropdownMenuItem(
                  value: r,
                  child: Text(r.baslik, style: const TextStyle(fontSize: 13)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _seciliRol = val);
              },
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _yukleniyor ? null : _yeniPersonelKaydet,
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Personel Hesabı Oluştur'),
              style: ElevatedButton.styleFrom(
                backgroundColor: hurmaKahvesiKoyu,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BİLEŞEN: HIZLI ROL TEST ALANI (DEMO KOLAYLIĞI)
  // ============================================================

  Widget _hizliRolTestAlani() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt, color: altinSarisi, size: 18),
              SizedBox(width: 6),
              Text(
                'Hızlı Rol Simülasyonu & Yetki Testi:',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: hurmaKahvesiKoyu),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _rolButon(
                  rol: KullaniciRolu.admin,
                  ikon: Icons.admin_panel_settings,
                  renk: hurmaKahvesi,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _rolButon(
                  rol: KullaniciRolu.muhasebe,
                  ikon: Icons.account_balance,
                  renk: const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _rolButon(
                  rol: KullaniciRolu.depoSorumlusu,
                  ikon: Icons.warehouse,
                  renk: const Color(0xFFE65100),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: hurmaKahvesi,
              foregroundColor: altinSarisi,
              padding: const EdgeInsets.symmetric(vertical: 12),
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FirstTimeSetupScreen()),
              );
            },
            icon: const Icon(Icons.rocket_launch_rounded, size: 18),
            label: const Text(
              '✨ İlk Kez mi Kullanıyorsunuz? İlk Kurulum Sihirbazı',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rolButon(
      {required KullaniciRolu rol,
      required IconData ikon,
      required Color renk}) {
    return InkWell(
      onTap: () => _hizliRolGiris(rol),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: renk.withOpacity(0.1),
          border: Border.all(color: renk.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(ikon, size: 18, color: renk),
            const SizedBox(height: 3),
            Text(
              rol.name == 'admin'
                  ? '👑 Yönetici'
                  : rol.name == 'muhasebe'
                      ? '💼 Muhasebe'
                      : '📦 Depo',
              style: TextStyle(
                  fontSize: 10.5, fontWeight: FontWeight.bold, color: renk),
            ),
          ],
        ),
      ),
    );
  }
}
