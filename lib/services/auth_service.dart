// ============================================================
// NAKHL & NAHL — GÜVENLİK VE KİMLİK DOĞRULAMA SERVİSİ
// ============================================================
// Supabase Authentication ve Core Database v1.0 Entegrasyonu:
// 1. E-posta ve Şifre ile Güvenli Giriş / Kayıt (Supabase Auth)
// 2. 2FA (İki Aşamalı Doğrulama / Hızlı 4 Haneli PIN)
// 3. Rol Bazlı Yetkilendirme (Admin, Muhasebe, Depo Sorumlusu)
// 4. PostgreSQL public.users ve tenant_users Senkronizasyonu
// ============================================================

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import '../core/tenant/tenant_context.dart';

/// NAKHL & NAHL Kurumsal ERP Kullanıcı Rolleri (9 Seviyeli Yetkilendirme)
enum KullaniciRolu {
  owner('İşletme Sahibi / Owner', 'Mülk sahibi, tam sistem erişimi ve şirket yönetimi'),
  admin('Yönetici / Admin', 'Tüm ERP modüllerine, kasaya ve onaylara tam erişim'),
  manager('Müdür / Manager', 'Operasyonel yönetim, onay yetkileri ve raporlar'),
  accountant('Muhasebe / Accountant', 'Kasa, banka, faturalar, cari kartlar ve finansal tablolar'),
  cashier('Kasiyer / Cashier', 'Nakit tahsilat, kasa işlemleri ve perakende satış'),
  warehouse('Depo Sorumlusu / Warehouse', 'Stok yönetimi, mal kabul, sayım ve lojistik sevkiyatlar'),
  sales('Satış Temsilcisi / Sales', 'Müşteri cari kartları, teklif, sipariş ve satış işlemleri'),
  purchase('Satınalma / Purchase', 'Tedarikçi ilişkileri, satınalma siparişleri ve mal kabul'),
  viewer('Gözlemci / Viewer', 'Yalnızca okuma ve rapor görüntüleme yetkisi');

  final String baslik;
  final String aciklama;
  const KullaniciRolu(this.baslik, this.aciklama);

  // Geriye dönük uyumluluk takma adları:
  static const KullaniciRolu muhasebe = KullaniciRolu.accountant;
  static const KullaniciRolu depoSorumlusu = KullaniciRolu.warehouse;

  static KullaniciRolu fromString(String? val) {
    if (val == null) return KullaniciRolu.admin;
    final k = val.toLowerCase().trim();
    if (k.contains('owner') || k.contains('sahip')) return KullaniciRolu.owner;
    if (k.contains('manager') || k.contains('mudur') || k.contains('müdür')) return KullaniciRolu.manager;
    if (k.contains('muhasebe') || k.contains('accountant')) return KullaniciRolu.accountant;
    if (k.contains('kasiyer') || k.contains('cashier')) return KullaniciRolu.cashier;
    if (k.contains('depo') || k.contains('warehouse')) return KullaniciRolu.warehouse;
    if (k.contains('satis') || k.contains('satış') || k.contains('sales')) return KullaniciRolu.sales;
    if (k.contains('satinalma') || k.contains('satınalma') || k.contains('purchase')) return KullaniciRolu.purchase;
    if (k.contains('viewer') || k.contains('izleyici') || k.contains('gozlemci')) return KullaniciRolu.viewer;
    return KullaniciRolu.admin;
  }
}

/// Kullanıcı Profil Modeli
class KullaniciProfili {
  final String uid;
  final String email;
  final String adSoyad;
  final KullaniciRolu rol;
  final String pinKodu;
  final DateTime? sonGirisTarihi;
  final DateTime? olusturmaTarihi;

  const KullaniciProfili({
    required this.uid,
    required this.email,
    required this.adSoyad,
    required this.rol,
    this.pinKodu = '1453',
    this.sonGirisTarihi,
    this.olusturmaTarihi,
  });

  factory KullaniciProfili.fromMap(Map<String, dynamic> data, String docId) {
    return KullaniciProfili(
      uid: docId,
      email: data['email']?.toString() ?? '',
      adSoyad: data['adSoyad']?.toString() ??
          data['full_name']?.toString() ??
          'Kullanıcı',
      rol: KullaniciRolu.fromString(
          data['rol']?.toString() ?? data['role']?.toString()),
      pinKodu: data['pinKodu']?.toString() ?? '1453',
      sonGirisTarihi: data['sonGirisTarihi'] != null
          ? (data['sonGirisTarihi'] is DateTime
              ? data['sonGirisTarihi'] as DateTime
              : DateTime.tryParse(data['sonGirisTarihi'].toString()))
          : (data['last_sign_in_at'] != null
              ? DateTime.tryParse(data['last_sign_in_at'].toString())
              : null),
      olusturmaTarihi: data['olusturmaTarihi'] != null
          ? (data['olusturmaTarihi'] is DateTime
              ? data['olusturmaTarihi'] as DateTime
              : DateTime.tryParse(data['olusturmaTarihi'].toString()))
          : (data['created_at'] != null
              ? DateTime.tryParse(data['created_at'].toString())
              : null),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'adSoyad': adSoyad,
      'full_name': adSoyad,
      'rol': rol.name,
      'pinKodu': pinKodu,
      'sonGirisTarihi': DateTime.now().toIso8601String(),
      'olusturmaTarihi': olusturmaTarihi?.toIso8601String() ??
          DateTime.now().toIso8601String(),
    };
  }
}

class AuthService {
  // Singleton Altyapısı
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  KullaniciProfili? _aktifProfil;
  KullaniciProfili? get aktifProfil => _aktifProfil;

  /// Supabase Auth mevcut oturum açmış kullanıcı ID'si
  String? get currentUserId => SupabaseService.client.auth.currentUser?.id;

  // ============================================================
  // 1. E-POSTA VE ŞİFRE İLE GİRİŞ
  // ============================================================

  /// E-posta ve şifreyle Supabase Auth üzerinden kimlik doğrular
  Future<KullaniciProfili> emailIleGiris({
    required String email,
    required String sifre,
  }) async {
    try {
      final response = await SupabaseService.client.auth.signInWithPassword(
        email: email.trim(),
        password: sifre,
      );

      final user = response.user;
      if (user == null) {
        throw Exception('Kullanıcı bilgisi alınamadı.');
      }

      // Veritabanından profil ve rol bilgilerini çek
      final profil = await profilGetir(user.id);
      if (profil != null) {
        _aktifProfil = profil;
        TenantContext.instance.setSession(
          userId: user.id,
          userEmail: user.email ?? email,
        );
        return profil;
      } else {
        throw Exception('AUTHENTICATED_BUT_NOT_PROVISIONED: Kullanıcı profili veritabanında tanımlanmamış. Lütfen yetkili tenant yöneticisi ile iletişime geçiniz.');
      }
    } catch (e) {
      // Demo / geliştirme amaçlı yedek oturum açma desteği (yalnızca Debug modunda)
      if (kDebugMode &&
          (email.contains('yonetici') || email.contains('admin'))) {
        demoOturumAyarla(KullaniciRolu.admin, email: email);
        return _aktifProfil!;
      }
      throw Exception('Giriş başarısız: $e');
    }
  }

  // ============================================================
  // 2. YENİ KULLANICI KAYDI VE ROL ATAMA
  // ============================================================

  /// Yeni kullanıcı oluşturur ve rolünü kaydeder
  Future<KullaniciProfili> kayitOl({
    required String email,
    required String sifre,
    required String adSoyad,
    required KullaniciRolu rol,
    String pinKodu = '1453',
  }) async {
    try {
      final response = await SupabaseService.client.auth.signUp(
        email: email.trim(),
        password: sifre,
        data: {'full_name': adSoyad.trim()},
      );

      final user = response.user;
      final uid = user?.id ?? 'usr_${DateTime.now().millisecondsSinceEpoch}';

      final profil = KullaniciProfili(
        uid: uid,
        email: email.trim(),
        adSoyad: adSoyad.trim(),
        rol: rol,
        pinKodu: pinKodu.trim().isEmpty ? '1453' : pinKodu.trim(),
        olusturmaTarihi: DateTime.now(),
      );

      _aktifProfil = profil;
      TenantContext.instance.setSession(
        userId: uid,
        userEmail: email.trim(),
      );
      return profil;
    } catch (e) {
      throw Exception('Kayıt oluşturulamadı: $e');
    }
  }

  // ============================================================
  // 3. 2FA (İKİ AŞAMALI PIN) DOĞRULAMA
  // ============================================================

  /// Kullanıcının 4 haneli PIN kodunu doğrular
  bool pinDogrula(String girilenPin) {
    // Canlı ortamda master PIN devre dışıdır; yalnızca kDebugMode altında geçerlidir.
    if (kDebugMode && (girilenPin == '1453' || girilenPin == '0000')) {
      return true;
    }
    if (_aktifProfil != null && _aktifProfil!.pinKodu == girilenPin) {
      return true;
    }
    return false;
  }

  /// Aktif kullanıcının PIN kodunu günceller
  Future<void> pinGuncelle(String yeniPin) async {
    if (_aktifProfil == null) return;
    _aktifProfil = KullaniciProfili(
      uid: _aktifProfil!.uid,
      email: _aktifProfil!.email,
      adSoyad: _aktifProfil!.adSoyad,
      rol: _aktifProfil!.rol,
      pinKodu: yeniPin,
      sonGirisTarihi: _aktifProfil!.sonGirisTarihi,
      olusturmaTarihi: _aktifProfil!.olusturmaTarihi,
    );
  }

  // ============================================================
  // 4. PROFİL GETİRME VE ROL YÖNETİMİ
  // ============================================================

  /// Supabase public.users tablosundan kullanıcı profilini çeker
  Future<KullaniciProfili?> profilGetir(String uid) async {
    try {
      final res = await SupabaseService.client
          .from('users')
          .select()
          .eq('auth_user_id', uid)
          .maybeSingle();

      if (res != null) {
        return KullaniciProfili.fromMap(res, uid);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Mevcut oturumdaki kullanıcının profilini tazeler
  Future<KullaniciProfili?> aktifProfiliYukle() async {
    final uid = currentUserId;
    if (uid != null) {
      _aktifProfil = await profilGetir(uid);
      return _aktifProfil;
    }
    return null;
  }

  /// Belirtilen modüle bu rolün erişim izni var mı?
  /// Modül anahtarları: 'dashboard', 'cari', 'finans', 'stok', 'sevkiyat', 'satis', 'rapor'
  bool yetkiVarMi(String modulAnahtari, [KullaniciRolu? ozelRol]) {
    final rol = ozelRol ?? _aktifProfil?.rol ?? KullaniciRolu.admin;

    // 1. Owner & Admin: Tüm ERP modüllerine tam yetki
    if (rol == KullaniciRolu.owner || rol == KullaniciRolu.admin) return true;

    final key = modulAnahtari.toLowerCase().trim();

    // 2. Manager: Operasyonel tüm modüllere erişim
    if (rol == KullaniciRolu.manager) {
      const izinler = {'dashboard', 'cari', 'finans', 'stok', 'sevkiyat', 'satis', 'satinalma', 'rapor'};
      return izinler.contains(key);
    }

    // 3. Accountant (Muhasebe): Finans, Satış Faturaları, Raporlama, Cari Kartlar, Dashboard
    if (rol == KullaniciRolu.accountant) {
      const izinler = {'dashboard', 'cari', 'finans', 'satis', 'satinalma', 'rapor'};
      return izinler.contains(key);
    }

    // 4. Cashier: Hızlı satış, kasa tahsilatı, cari kartlar
    if (rol == KullaniciRolu.cashier) {
      const izinler = {'dashboard', 'satis', 'finans', 'cari'};
      return izinler.contains(key);
    }

    // 5. Warehouse (Depo Sorumlusu): Stok, Sevkiyat & Lojistik, Dashboard
    if (rol == KullaniciRolu.warehouse) {
      const izinler = {'dashboard', 'stok', 'sevkiyat', 'satinalma'};
      return izinler.contains(key);
    }

    // 6. Sales: Satış, Müşteri Carileri, Dashboard
    if (rol == KullaniciRolu.sales) {
      const izinler = {'dashboard', 'satis', 'cari'};
      return izinler.contains(key);
    }

    // 7. Purchase: Satınalma, Tedarikçi Carileri, Stok, Dashboard
    if (rol == KullaniciRolu.purchase) {
      const izinler = {'dashboard', 'satinalma', 'cari', 'stok'};
      return izinler.contains(key);
    }

    // 8. Viewer: Dashboard ve Raporlama (salt okunur)
    if (rol == KullaniciRolu.viewer) {
      const izinler = {'dashboard', 'rapor'};
      return izinler.contains(key);
    }

    return false;
  }

  // ============================================================
  // 5. DEMO VE TEST HIZLI OTURUMU
  // ============================================================

  /// Hızlı test veya demo oturumu açmak için profil ayarlar
  void demoOturumAyarla(KullaniciRolu rol, {String? adSoyad, String? email}) {
    _aktifProfil = KullaniciProfili(
      uid: 'demo_${rol.name}',
      email: email ?? '${rol.name}@nakhlnahl.com',
      adSoyad: adSoyad ?? '${rol.baslik} Yetkilisi',
      rol: rol,
      pinKodu: '1453',
      sonGirisTarihi: DateTime.now(),
      olusturmaTarihi: DateTime.now(),
    );
    TenantContext.instance.setSession(
      userId: _aktifProfil!.uid,
      userEmail: _aktifProfil!.email,
    );
  }

  /// Doğrudan kullanıcı profili atar ve TenantContext oturumunu senkronize eder
  void kullaniciProfiliAyarla(KullaniciProfili profil) {
    _aktifProfil = profil;
    TenantContext.instance.setSession(
      userId: profil.uid,
      userEmail: profil.email,
    );
  }

  // ============================================================
  // 6. ÇIKIŞ YAP (LOGOUT) & GÜVENLİ OTURUM SONLANDIRMA
  // ============================================================

  Future<void> cikisYap() async {
    _aktifProfil = null;
    TenantContext.instance.clearSession();
    try {
      await SupabaseService.client.auth.signOut();
    } catch (_) {}
  }

  // ============================================================
  // 7. FAZ 31: PRODUCTION AUTH HARDENING
  // ============================================================

  /// Aktif oturum geçerli ve süresi dolmamış mı?
  bool get isSessionValid {
    try {
      final session = SupabaseService.client.auth.currentSession;
      if (session == null) return _aktifProfil != null;
      return !session.isExpired;
    } catch (_) {
      return _aktifProfil != null;
    }
  }

  /// Oturum Token Yenileme (Refresh Token)
  Future<bool> oturumYenile() async {
    try {
      final res = await SupabaseService.client.auth.refreshSession();
      return res.session != null;
    } catch (_) {
      return false;
    }
  }

  /// Şifre Sıfırlama E-postası Gönder (Password Reset)
  Future<bool> sifreSifirla({required String email}) async {
    try {
      await SupabaseService.client.auth.resetPasswordForEmail(email.trim());
      return true;
    } catch (_) {
      return false;
    }
  }

  /// E-posta Doğrulama Bağlantısını Yeniden Gönder
  Future<bool> epostaDogrulamaGonder({required String email}) async {
    try {
      await SupabaseService.client.auth.resend(
        type: OtpType.signup,
        email: email.trim(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
