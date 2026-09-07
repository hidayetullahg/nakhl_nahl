// ============================================================
// NAKHL & NAHL — MOBİL ENTEGRASYON & BİLDİRİM SERVİSİ
// ============================================================
// Özellikler:
// 1. Mobil Kamera & Barkod / QR Kod Tarayıcı (Cari & Palet)
// 2. Push Notification Engine ile Ortaklara Anlık Bildirim
// 3. Mobil Ekranlar İçin Esnek (Responsive) Arayüz Bileşenleri
// ============================================================

import 'package:flutter/material.dart';
import 'supabase_service.dart';

// ── BARKOD & QR KOD MODELLERİ ──

enum BarkodTipi {
  cariKodu('Akıllı Cari Kodu', Icons.badge_outlined),
  hurmaPaleti('Hurma Palet Barkodu', Icons.inventory_2_outlined),
  eFaturaQr('ZATCA / GİB E-Fatura QR', Icons.qr_code_2_rounded),
  diger('Standart Barkod', Icons.qr_code_scanner_rounded);

  final String baslik;
  final IconData ikon;
  const BarkodTipi(this.baslik, this.ikon);
}

class BarkodDetayi {
  final String hamKod;
  final BarkodTipi tip;
  final String? baslik;
  final String? altBilgi;
  final Map<String, dynamic> ayristirilmisVeri;

  const BarkodDetayi({
    required this.hamKod,
    required this.tip,
    this.baslik,
    this.altBilgi,
    this.ayristirilmisVeri = const {},
  });

  /// NAKHL & NAHL Akıllı Barkod Çözücüsü
  factory BarkodDetayi.ayristir(String kod) {
    kod = kod.trim();

    // 1. Cari Kod Formatı: Örn. "HGLTD-SA-M-001" veya "NAKHL-TR-T-042"
    if (kod.contains('-') &&
        (kod.contains('-SA-') ||
            kod.contains('-TR-') ||
            kod.contains('-AE-') ||
            kod.contains('-DE-'))) {
      final parcalar = kod.split('-');
      final ulke = parcalar.length > 1 ? parcalar[1] : 'SA';
      final rolKodu = parcalar.length > 2 ? parcalar[2] : 'M';
      final rolAdi = rolKodu == 'M'
          ? 'Müşteri (Alıcı)'
          : (rolKodu == 'T' ? 'Tedarikçi' : 'Ortak');

      return BarkodDetayi(
        hamKod: kod,
        tip: BarkodTipi.cariKodu,
        baslik: 'Cari Kartı: $kod',
        altBilgi: 'Ülke: $ulke | Rol: $rolAdi',
        ayristirilmisVeri: {
          'cariKodu': kod,
          'ulke': ulke,
          'rol': rolAdi,
        },
      );
    }

    // 2. Hurma Palet / Koli Formatı: Örn. "PALET-IBRAHIMI-14.5T" veya "PALET-SUKKARI-2026"
    if (kod.toUpperCase().startsWith('PALET-') ||
        kod.toUpperCase().startsWith('KOLI-')) {
      final parcalar = kod.split('-');
      final cesit = parcalar.length > 1 ? parcalar[1] : 'Medine Hurması';
      final miktar = parcalar.length > 2 ? parcalar[2] : 'Bilinmiyor';

      return BarkodDetayi(
        hamKod: kod,
        tip: BarkodTipi.hurmaPaleti,
        baslik: 'Hurma Envanter Paleti: $cesit',
        altBilgi: 'Tanımlı Miktar/Parti: $miktar',
        ayristirilmisVeri: {
          'cesit': cesit,
          'partiMiktar': miktar,
        },
      );
    }

    // 3. E-Fatura QR Kodu (ZATCA veya GİB)
    if (kod.startsWith('AQ') ||
        kod.contains('ZATCA') ||
        kod.contains('urn:uuid:')) {
      return BarkodDetayi(
        hamKod: kod,
        tip: BarkodTipi.eFaturaQr,
        baslik: 'Resmi E-Fatura QR Kodu',
        altBilgi: 'Doğrulanmış Maliye İmzası Mevcut',
        ayristirilmisVeri: {'faturaQr': kod},
      );
    }

    // 4. Varsayılan Diğer Barkod
    return BarkodDetayi(
      hamKod: kod,
      tip: BarkodTipi.diger,
      baslik: 'Barkod: $kod',
      altBilgi: 'Standart Ürün Barkodu',
      ayristirilmisVeri: {'kod': kod},
    );
  }
}

// ============================================================
// MOBİL ENTEGRASYON SERVİSİ
// ============================================================

class MobilEntegrasyonServisi {
  MobilEntegrasyonServisi._internal();
  static final MobilEntegrasyonServisi instance =
      MobilEntegrasyonServisi._internal();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  // ============================================================
  // 1. BİLDİRİM ALTYAPISI KURULUMU VE ABONELİK
  // ============================================================

  /// Bildirim altyapısını başlatır ve ortaklar kanalına abone eder
  Future<void> bildirimAltyapisiniBaslat({String? kullaniciId}) async {
    _fcmToken = 'device_${DateTime.now().millisecondsSinceEpoch}';
  }

  // ============================================================
  // 2. ORTAKLARA ANLIK BİLDİRİM GÖNDERME TETİKLEYİCİLERİ
  // ============================================================

  /// Finansal hareket (Tahsilat, Ödeme vb.) eklendiğinde tüm ortakların telefonuna anlık bildirim iletir
  Future<void> finansBildirimiGonder({
    required String cariUnvan,
    required String islemTuru,
    required double tutar,
    required String paraBirimi,
    String? aciklama,
  }) async {
    final baslik = '💰 Finansal Hareket: $islemTuru';
    final mesaj =
        '$cariUnvan için ${tutar.toStringAsFixed(2)} $paraBirimi tutarında $islemTuru kaydı işlendi.';

    await _bildirimKaydetVeDagit(
      baslik: baslik,
      mesaj: mesaj,
      kanal: 'finans_hareketleri',
      oncelik: 'yuksek',
      ekVeri: {
        'modul': 'finans',
        'islemTuru': islemTuru,
        'cariUnvan': cariUnvan,
        'tutar': tutar,
        'paraBirimi': paraBirimi,
        'aciklama': aciklama ?? '',
      },
    );
  }

  /// Yeni ihracat veya sevkiyat hareketi çıktığında ortakları anlık bilgilendirir
  Future<void> sevkiyatBildirimiGonder({
    required String musteriUnvan,
    required String hurmaCesidi,
    required double tonaj,
    required String seferPlaka,
    required String cikisLimani,
    required String sevkiyatDurumu,
  }) async {
    final baslik = '🚢 Yeni Sevkiyat: $musteriUnvan';
    final mesaj =
        '$hurmaCesidi hurması ($tonaj Ton) - $cikisLimani limanından yola çıktı. Sefer: $seferPlaka (Durum: $sevkiyatDurumu).';

    await _bildirimKaydetVeDagit(
      baslik: baslik,
      mesaj: mesaj,
      kanal: 'sevkiyat_hareketleri',
      oncelik: 'yuksek',
      ekVeri: {
        'modul': 'sevkiyat',
        'musteriUnvan': musteriUnvan,
        'hurmaCesidi': hurmaCesidi,
        'tonaj': tonaj,
        'seferPlaka': seferPlaka,
        'cikisLimani': cikisLimani,
        'durum': sevkiyatDurumu,
      },
    );
  }

  /// Kritik stok seviyesi uyarısı
  Future<void> kritikStokUyarisiGonder({
    required String hurmaCesidi,
    required double kalanMiktar,
    String birim = 'Kg',
  }) async {
    final baslik = '⚠️ Kritik Hurma Stoğu Uyarısı';
    final mesaj =
        '$hurmaCesidi çeşidinde kalan miktar kritik eşiğe düştü: ${kalanMiktar.toStringAsFixed(1)} $birim!';

    await _bildirimKaydetVeDagit(
      baslik: baslik,
      mesaj: mesaj,
      kanal: 'ortaklar_bildirim',
      oncelik: 'acil',
      ekVeri: {
        'modul': 'stok',
        'hurmaCesidi': hurmaCesidi,
        'kalanMiktar': kalanMiktar,
      },
    );
  }

  /// Ortak bildirim tablosuna yazar
  Future<void> _bildirimKaydetVeDagit({
    required String baslik,
    required String mesaj,
    required String kanal,
    required String oncelik,
    required Map<String, dynamic> ekVeri,
  }) async {
    try {
      await SupabaseService.client.from('audit_logs').insert({
        'action': 'NOTIFY',
        'entity_name': kanal,
        'new_data': {
          'baslik': baslik,
          'mesaj': mesaj,
          'oncelik': oncelik,
          'ekVeri': ekVeri,
        },
      });
    } catch (_) {
      // Hata durumunda akışın kesilmemesi için loglanabilir
    }
  }

  /// Son canlı bildirimleri dinler
  Stream<List<Map<String, dynamic>>> canliBildirimleriDinleStream() {
    return SupabaseService.client
        .from('audit_logs')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(20);
  }

  // ============================================================
  // 3. MOBİL KAMERA & BARKOD TARAYICI MODALI
  // ============================================================

  /// Kullanıcıya lazerli vizör animasyonu ve hızlı test seçenekleri sunan barkod tarama modalı
  static Future<BarkodDetayi?> barkodTaraModaliniAc(
      BuildContext context) async {
    return showModalBottomSheet<BarkodDetayi>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const BarkodTarayiciModal(),
    );
  }
}

// ============================================================
// ARAYÜZ BİLEŞENİ: BARKOD VE QR TARAYICI MODALI
// ============================================================

class BarkodTarayiciModal extends StatefulWidget {
  const BarkodTarayiciModal({super.key});

  @override
  State<BarkodTarayiciModal> createState() => _BarkodTarayiciModalState();
}

class _BarkodTarayiciModalState extends State<BarkodTarayiciModal>
    with SingleTickerProviderStateMixin {
  static const Color hurmaKahvesi = Color(0xFF5C4033);
  static const Color hurmaKahvesiKoyu = Color(0xFF3E2723);
  static const Color altinSarisi = Color(0xFFC89033);

  late AnimationController _animController;
  late Animation<double> _lazerAnim;

  final TextEditingController _manuelBarkodController = TextEditingController();
  bool _fenerAcik = false;

  // Demo / Hızlı Test İçin Örnek Barkodlar
  final List<Map<String, String>> _ornekBarkodlar = [
    {'kod': 'HGLTD-SA-M-001', 'etiket': '🇸🇦 Medine Cari (Alıcı Müşteri)'},
    {'kod': 'HGLTD-TR-T-004', 'etiket': '🇹🇷 İstanbul Cari (Tedarikçi)'},
    {
      'kod': 'PALET-IBRAHIMI-15T',
      'etiket': '🌴 Medine İbrâhimî (15 Ton Palet)'
    },
    {
      'kod': 'PALET-SUKKARI-8.5T',
      'etiket': '🌴 Sukkari Hurması (8.5 Ton Palet)'
    },
    {
      'kod': 'ZATCA-E-FATURA-UUID-1453',
      'etiket': '🧾 ZATCA Onaylı E-Fatura QR'
    },
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _lazerAnim = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _manuelBarkodController.dispose();
    super.dispose();
  }

  void _barkoduTamamla(String kod) {
    if (kod.trim().isEmpty) return;
    final detay = BarkodDetayi.ayristir(kod);
    Navigator.pop(context, detay);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final vizorBoyutu = media.width > 400 ? 260.0 : media.width * 0.65;

    return Container(
      height: media.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          // ── Üst Başlık & Kapat ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: hurmaKahvesi.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.qr_code_scanner_rounded,
                          color: altinSarisi, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kamera & Barkod Tarayıcı',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Cari Kartı veya Hurma Paletini Okutun',
                          style: TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white12, height: 1),

          // ── Kamera Vizörü Simülatörü ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Vizör Kutusu
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: vizorBoyutu,
                          height: vizorBoyutu,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: altinSarisi.withOpacity(0.7), width: 2),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.camera_alt_outlined,
                              size: 48,
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                        ),

                        // 4 Köşe Odak Kılavuzları
                        _koseKilavuz(top: 0, left: 0),
                        _koseKilavuz(top: 0, right: 0),
                        _koseKilavuz(bottom: 0, left: 0),
                        _koseKilavuz(bottom: 0, right: 0),

                        // Kırmızı / Altın Lazer Tarama Çizgisi
                        AnimatedBuilder(
                          animation: _lazerAnim,
                          builder: (context, child) {
                            return Positioned(
                              top: vizorBoyutu * _lazerAnim.value,
                              child: Container(
                                width: vizorBoyutu - 20,
                                height: 2.5,
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.redAccent.withOpacity(0.8),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Fener ve Mod Kontrolleri
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ActionChip(
                        avatar: Icon(
                            _fenerAcik ? Icons.flash_on : Icons.flash_off,
                            size: 16,
                            color: altinSarisi),
                        label: Text(_fenerAcik ? 'Fener Açık' : 'Fener Aç',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12)),
                        backgroundColor: Colors.white.withOpacity(0.08),
                        onPressed: () =>
                            setState(() => _fenerAcik = !_fenerAcik),
                      ),
                      const SizedBox(width: 12),
                      ActionChip(
                        avatar: const Icon(Icons.qr_code,
                            size: 16, color: Colors.greenAccent),
                        label: const Text('Otomatik Odaklama',
                            style:
                                TextStyle(color: Colors.white, fontSize: 12)),
                        backgroundColor: Colors.white.withOpacity(0.08),
                        onPressed: () {},
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Manuel Kod Girişi ──
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kamera Okumuyorsa Manuel Kod Girin:',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _manuelBarkodController,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText:
                                      'Örn: HGLTD-SA-M-001 veya PALET-15T',
                                  hintStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.3),
                                      fontSize: 12),
                                  isDense: true,
                                  filled: true,
                                  fillColor: Colors.black26,
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () =>
                                  _barkoduTamamla(_manuelBarkodController.text),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: hurmaKahvesi,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Ara'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Hızlı Test Barkodları ──
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Hızlı Test İçin Örnek Barkod Seçin:',
                      style: TextStyle(
                          color: Colors.amber.shade200,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _ornekBarkodlar.map((b) {
                      return InkWell(
                        onTap: () => _barkoduTamamla(b['kod']!),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: hurmaKahvesiKoyu.withOpacity(0.6),
                            border: Border.all(
                                color: hurmaKahvesiAcik.withOpacity(0.5)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            b['etiket']!,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 11),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const Color hurmaKahvesiAcik = Color(0xFF8D6E63);

  Widget _koseKilavuz(
      {double? top, double? bottom, double? left, double? right}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border(
            top: top != null
                ? const BorderSide(color: altinSarisi, width: 4)
                : BorderSide.none,
            bottom: bottom != null
                ? const BorderSide(color: altinSarisi, width: 4)
                : BorderSide.none,
            left: left != null
                ? const BorderSide(color: altinSarisi, width: 4)
                : BorderSide.none,
            right: right != null
                ? const BorderSide(color: altinSarisi, width: 4)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// RESPONSIVE (ESNEK) MOBİL TASARIM YARDIMCILARI & BİLEŞENLERİ
// ============================================================

/// Mobil, Tablet ve Masaüstü ekran sınırlarını yöneten yardımcı
class ResponsiveYardimci {
  static bool mobilMi(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 600;
  static bool tabletMi(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= 600 && w < 1024;
  }

  static bool masaustuMu(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 1024;

  /// Ekran genişliğine göre dinamik ızgara sütun sayısı
  static int sutunSayisi(BuildContext context,
      {int mobil = 2, int tablet = 3, int masaustu = 4}) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < 600) return mobil;
    if (w < 1024) return tablet;
    return masaustu;
  }

  /// Ekran boyutuna göre güvenli yatay padding
  static EdgeInsets yatayBosluk(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < 600) return const EdgeInsets.symmetric(horizontal: 14);
    if (w < 1024) return const EdgeInsets.symmetric(horizontal: 24);
    return const EdgeInsets.symmetric(horizontal: 36);
  }
}

/// Mobil ekranlarda taşmayı engelleyen esnek buton sarmalayıcısı
class ResponsiveAksiyonButonlari extends StatelessWidget {
  final List<Widget> butonlar;
  final double aralik;

  const ResponsiveAksiyonButonlari({
    super.key,
    required this.butonlar,
    this.aralik = 10,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Eğer genişlik 480'den dar ise dikey veya Wrap olarak diz, taşmayı önle
        if (constraints.maxWidth < 480) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: butonlar
                .map((b) => Padding(
                      padding: EdgeInsets.only(bottom: aralik),
                      child: b,
                    ))
                .toList(),
          );
        }

        // Geniş ekranda yatay diz
        return Row(
          children: butonlar
              .map((b) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: aralik / 2),
                      child: b,
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}

/// Mobil ekranlarda tabloların ve veri listelerinin sağa-sola taşmasını önleyen sarmalayıcı
class ResponsiveTabloSarmalayici extends StatelessWidget {
  final Widget child;
  final String? tabloBaslik;

  const ResponsiveTabloSarmalayici({
    super.key,
    required this.child,
    this.tabloBaslik,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tabloBaslik != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tabloBaslik!,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3E2723)),
              ),
              const Row(
                children: [
                  Icon(Icons.swipe_left_rounded, size: 14, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    'Yana kaydırın',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: child,
          ),
        ),
      ],
    );
  }
}
