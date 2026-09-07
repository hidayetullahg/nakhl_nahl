// ============================================================
// İHRACAT VE LOJİSTİK TAKİP MODÜLÜ
// ============================================================
// NAKHL & NAHL Kurumsal Renk Paleti:
//   - Hurma Kahvesi: #5C4033
//   - Krem: #FBF9F1
//
// Supabase PostgreSQL: 'export_files', 'export_containers', 'shipments' tabloları üzerinden
// konteyner, sefer, gümrük limanı ve sevkiyat durumu
// (Hazırlanıyor, Gümrükte, Yolda, Teslim Edildi) gerçek zamanlı takibi.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/supabase_service.dart';
import '../core/tenant/tenant_context.dart';
import '../services/mobil_entegrasyon_servisi.dart';

class IhracatSevkiyatScreen extends StatefulWidget {
  const IhracatSevkiyatScreen({super.key});

  @override
  State<IhracatSevkiyatScreen> createState() => _IhracatSevkiyatScreenState();
}

class _IhracatSevkiyatScreenState extends State<IhracatSevkiyatScreen>
    with SingleTickerProviderStateMixin {
  // Kurumsal Renkler
  static const Color hurmaKahvesi = Color(0xFF5C4033);
  static const Color hurmaKahvesiKoyu = Color(0xFF3E2723);
  static const Color hurmaKahvesiAcik = Color(0xFF8D6E63);
  static const Color kremArkaplan = Color(0xFFFBF9F1);
  static const Color kremKoyu = Color(0xFFF0EAE1);
  static const Color altinSarisi = Color(0xFFC89033);

  // Form Kontrolcüleri
  final _formKey = GlobalKey<FormState>();
  final _cariUnvanController = TextEditingController();
  final _urunCesidiController = TextEditingController();
  final _miktarController = TextEditingController();
  final _konteynerNoController = TextEditingController();
  final _plakaSeferController = TextEditingController();
  final _cikisLimaniController =
      TextEditingController(text: 'Cidde İslam Limanı (Jeddah Islamic Port)');
  final _varisNoktasiController = TextEditingController();
  final _aciklamaController = TextEditingController();

  // Seçili Değerler
  String _secilenBirim = 'Ton'; // Ton, Koli, Palet, Konteyner
  String _secilenDurum =
      'Hazırlanıyor'; // Hazırlanıyor, Gümrükte, Yolda, Teslim Edildi
  DateTime _sevkTarihi = DateTime.now();
  DateTime _tahminiVarisTarihi = DateTime.now().add(const Duration(days: 10));

  bool _kaydediliyor = false;
  late TabController _tabController;

  // Sevkiyat Durumları & Renkleri
  final List<Map<String, dynamic>> _durumListesi = [
    {
      'id': 'Hazırlanıyor',
      'label': 'Hazırlanıyor',
      'icon': Icons.inventory_2_outlined,
      'color': const Color(0xFF1565C0), // Mavi
      'bg': const Color(0xFFE3F2FD),
      'aciklama': 'Depoda paletleme ve paketleme aşamasında',
    },
    {
      'id': 'Gümrükte',
      'label': 'Gümrükte',
      'icon': Icons.assignment_turned_in_outlined,
      'color': const Color(0xFFE65100), // Turuncu
      'bg': const Color(0xFFFFF3E0),
      'aciklama': 'İhracat gümrük muayenesi ve beyanname işlemleri',
    },
    {
      'id': 'Yolda',
      'label': 'Yolda (Transit)',
      'icon': Icons.directions_boat_outlined,
      'color': const Color(0xFF6A1B9A), // Mor
      'bg': const Color(0xFFF3E5F5),
      'aciklama': 'Denizyolu / Karayolu seferinde uluslararası transit',
    },
    {
      'id': 'Teslim Edildi',
      'label': 'Teslim Edildi',
      'icon': Icons.check_circle_outline,
      'color': const Color(0xFF2E7D32), // Yeşil
      'bg': const Color(0xFFE8F5E9),
      'aciklama': 'Müşteriye ve varış deposuna başarıyla ulaştı',
    },
  ];

  // Popüler Hurma Çeşitleri
  final List<String> _populerHurmaCesitleri = [
    'Medine İbrâhimî',
    'Kudsî',
    'Sukkari',
    'Mebrûm',
    'Medjoul',
    'Aclî (Ajwa)',
    'Safawî',
  ];

  // Birimler
  final List<String> _birimler = ['Ton', 'Koli', 'Palet', 'Konteyner'];

  // Sık Kullanılan Çıkış Limanları
  final List<String> _limanOnerileri = [
    'Cidde İslam Limanı (KSA)',
    'Dammam Kral Abdülaziz Limanı (KSA)',
    'Riyad Kuru Limanı (KSA)',
    'Mersin Uluslararası Limanı (TR)',
    'Ambarlı Limanı (TR)',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _cariUnvanController.dispose();
    _urunCesidiController.dispose();
    _miktarController.dispose();
    _konteynerNoController.dispose();
    _plakaSeferController.dispose();
    _cikisLimaniController.dispose();
    _varisNoktasiController.dispose();
    _aciklamaController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ============================================================
  // FİREBASE FİRESTORE SEVKİYAT KAYIT FONKSİYONU
  // ============================================================
  Future<void> _sevkiyatKaydet() async {
    if (!_formKey.currentState!.validate()) return;

    final double? miktar =
        double.tryParse(_miktarController.text.replaceAll(',', '.'));
    if (miktar == null || miktar <= 0) {
      _hataGoster('Lütfen geçerli ve pozitif bir sevk miktarı giriniz.');
      return;
    }

    setState(() => _kaydediliyor = true);

    try {
      final tenantId = TenantContext.instance.activeTenantId ??
          '00000000-0000-0000-0000-000000000001';
      final sevkiyatVerisi = {
        'tenant_id': tenantId,
        'shipment_number':
            'SHP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        'status': _secilenDurum,
        'carrier_name': _cariUnvanController.text.trim(),
        'cariUnvani': _cariUnvanController.text.trim(),
        'urunCesidi': _urunCesidiController.text.trim(),
        'miktar': miktar,
        'birim': _secilenBirim,
        'konteynerNo': _konteynerNoController.text.trim().toUpperCase(),
        'plakaSeferNo': _plakaSeferController.text.trim(),
        'port_of_loading': _cikisLimaniController.text.trim(),
        'cikisLimani': _cikisLimaniController.text.trim(),
        'port_of_discharge': _varisNoktasiController.text.trim(),
        'varisNoktasi': _varisNoktasiController.text.trim(),
        'sevkiyatDurumu': _secilenDurum,
        'actual_departure_date': _sevkTarihi.toIso8601String().split('T').first,
        'estimated_arrival_date':
            _tahminiVarisTarihi.toIso8601String().split('T').first,
        'aciklama': _aciklamaController.text.trim(),
      };

      await SupabaseService.client.from('shipments').insert(sevkiyatVerisi);

      // Ortakların telefonuna anlık bildirim (FCM) ilet
      await MobilEntegrasyonServisi.instance.sevkiyatBildirimiGonder(
        musteriUnvan: _cariUnvanController.text.trim(),
        hurmaCesidi: _urunCesidiController.text.trim(),
        tonaj: miktar,
        seferPlaka: _plakaSeferController.text.trim(),
        cikisLimani: _cikisLimaniController.text.trim(),
        sevkiyatDurumu: _secilenDurum,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${_cariUnvanController.text.trim()} sevkiyatı başarıyla kaydedildi.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      _formuTemizle();
      _tabController.animateTo(0);
    } catch (e) {
      if (!mounted) return;
      _hataGoster('Sevkiyat kaydı sırasında hata oluştu: $e');
    } finally {
      if (mounted) setState(() => _kaydediliyor = false);
    }
  }

  void _formuTemizle() {
    _cariUnvanController.clear();
    _urunCesidiController.clear();
    _miktarController.clear();
    _konteynerNoController.clear();
    _plakaSeferController.clear();
    _varisNoktasiController.clear();
    _aciklamaController.clear();
    setState(() {
      _secilenBirim = 'Ton';
      _secilenDurum = 'Hazırlanıyor';
      _sevkTarihi = DateTime.now();
      _tahminiVarisTarihi = DateTime.now().add(const Duration(days: 10));
    });
  }

  void _hataGoster(String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mesaj),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Durum Güncelleme
  Future<void> _durumGuncelle(String docId, String yeniDurum) async {
    try {
      await SupabaseService.client.from('shipments').update({
        'status': yeniDurum,
        'sevkiyatDurumu': yeniDurum,
      }).eq('id', docId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sevkiyat durumu "$yeniDurum" olarak güncellendi.'),
            backgroundColor: hurmaKahvesi,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) _hataGoster('Durum güncellenemedi: $e');
    }
  }

  // Tarih Seçimi
  Future<void> _tarihSec(bool isSevkTarihi) async {
    final DateTime suan = isSevkTarihi ? _sevkTarihi : _tahminiVarisTarihi;
    final DateTime? secilen = await showDatePicker(
      context: context,
      initialDate: suan,
      firstDate: DateTime(2023),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: hurmaKahvesi,
              onPrimary: Colors.white,
              onSurface: hurmaKahvesiKoyu,
            ),
          ),
          child: child!,
        );
      },
    );

    if (secilen != null) {
      setState(() {
        if (isSevkTarihi) {
          _sevkTarihi = secilen;
        } else {
          _tahminiVarisTarihi = secilen;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kremArkaplan,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: hurmaKahvesi,
        iconTheme: const IconThemeData(color: kremArkaplan),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'İhracat & Sevkiyat Yönetimi',
              style: TextStyle(
                color: kremArkaplan,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'NAKHL & NAHL — Uluslararası Lojistik & Konteyner Takibi',
              style: TextStyle(color: Color(0xFFD7CCC8), fontSize: 11),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: altinSarisi,
          indicatorWeight: 3.5,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFFD7CCC8),
          tabs: const [
            Tab(
                icon: Icon(Icons.local_shipping_rounded),
                text: 'Aktif Sevkiyatlar'),
            Tab(
                icon: Icon(Icons.add_location_alt_rounded),
                text: 'Yeni Sevkiyat Aç'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSevkiyatTakipSekmesi(),
          _buildYeniSevkiyatFormuSekmesi(),
        ],
      ),
    );
  }

  // ============================================================
  // 1. SEKME: SEVKİYAT LİSTESİ VE GERÇEK ZAMANLI TAKİP
  // ============================================================
  Widget _buildSevkiyatTakipSekmesi() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: SupabaseService.client
          .from('shipments')
          .stream(primaryKey: ['id']).order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: hurmaKahvesi),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off_rounded,
                      size: 54, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  Text(
                    'Sevkiyat verileri çekilirken hata oluştu:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: hurmaKahvesiKoyu),
                  ),
                ],
              ),
            ),
          );
        }

        final docs = snapshot.data ?? [];

        // İstatistikler
        int hazirlaniyorSayisi = 0;
        int gumrukteSayisi = 0;
        int yoldaSayisi = 0;
        int teslimEdildiSayisi = 0;
        double toplamSevkTonaj = 0.0;

        for (var doc in docs) {
          final data = doc;
          final String durum =
              data['sevkiyatDurumu'] ?? data['status'] ?? 'Hazırlanıyor';
          final double miktar = (data['miktar'] as num?)?.toDouble() ?? 0.0;
          final String birim = data['birim'] ?? 'Ton';

          if (durum == 'Hazırlanıyor') hazirlaniyorSayisi++;
          if (durum == 'Gümrükte') gumrukteSayisi++;
          if (durum == 'Yolda') yoldaSayisi++;
          if (durum == 'Teslim Edildi') teslimEdildiSayisi++;

          if (birim == 'Ton') toplamSevkTonaj += miktar;
        }

        return Column(
          children: [
            // Lojistik Durum Özeti Kartı
            _buildLojistikOzetKarti(
              toplamSevkiyat: docs.length,
              hazirlaniyor: hazirlaniyorSayisi,
              gumrukte: gumrukteSayisi,
              yolda: yoldaSayisi,
              teslimEdildi: teslimEdildiSayisi,
              toplamTonaj: toplamSevkTonaj,
            ),

            // Sevkiyat Kartları Listesi
            Expanded(
              child: docs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.local_shipping_outlined,
                              size: 64,
                              color: hurmaKahvesiAcik.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          const Text(
                            'Henüz kayıtlı bir sevkiyat bulunmuyor.',
                            style: TextStyle(
                                color: hurmaKahvesiKoyu,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Yeni ihracat veya konteyner sevkiyatı başlatmak için ikinci sekmeyi kullanabilirsiniz.',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () => _tabController.animateTo(1),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: hurmaKahvesi,
                              foregroundColor: kremArkaplan,
                            ),
                            icon: const Icon(Icons.add, color: altinSarisi),
                            label: const Text('Yeni Sevkiyat Oluştur'),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final data = docs[index];
                        final String docId = data['id']?.toString() ?? '';

                        final String cari = data['cariUnvani'] ??
                            data['carrier_name'] ??
                            'Cari Belirtilmedi';
                        final String urun = data['urunCesidi'] ?? 'Hurma';
                        final double miktar =
                            (data['miktar'] as num?)?.toDouble() ?? 0.0;
                        final String birim = data['birim'] ?? 'Ton';
                        final String konteynerNo = data['konteynerNo'] ?? '-';
                        final String plakaSefer = data['plakaSeferNo'] ?? '-';
                        final String cikisLimani = data['cikisLimani'] ??
                            data['port_of_loading'] ??
                            '-';
                        final String varisNoktasi = data['varisNoktasi'] ??
                            data['port_of_discharge'] ??
                            '-';
                        final String durum = data['sevkiyatDurumu'] ??
                            data['status'] ??
                            'Hazırlanıyor';
                        final String aciklama = data['aciklama'] ?? '';

                        final DateTime sevkDate = DateTime.tryParse(
                                data['actual_departure_date']?.toString() ??
                                    '') ??
                            DateTime.now();
                        final DateTime? varisDate = DateTime.tryParse(
                            data['estimated_arrival_date']?.toString() ?? '');

                        final Map<String, dynamic> durumMeta =
                            _getDurumMeta(durum);
                        final Color durumColor = durumMeta['color'] as Color;

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: kremKoyu),
                            boxShadow: [
                              BoxShadow(
                                color: hurmaKahvesi.withOpacity(0.06),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Üst Bar: Müşteri & Durum Rozeti
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor:
                                          durumColor.withOpacity(0.12),
                                      child: Icon(durumMeta['icon'] as IconData,
                                          color: durumColor, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cari,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: hurmaKahvesiKoyu,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '$urun • ${miktar.toStringAsFixed(2)} $birim',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              color: altinSarisi,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Durum Değiştirme Menüsü
                                    PopupMenuButton<String>(
                                      initialValue: durum,
                                      tooltip: 'Durumu Güncelle',
                                      onSelected: (val) =>
                                          _durumGuncelle(docId, val),
                                      itemBuilder: (context) =>
                                          _durumListesi.map((d) {
                                        return PopupMenuItem<String>(
                                          value: d['id'] as String,
                                          child: Row(
                                            children: [
                                              Icon(d['icon'] as IconData,
                                                  color: d['color'] as Color,
                                                  size: 18),
                                              const SizedBox(width: 10),
                                              Text(d['label'] as String),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: (durumMeta['bg'] as Color?) ??
                                              durumColor.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color:
                                                  durumColor.withOpacity(0.3)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              durum,
                                              style: TextStyle(
                                                color: durumColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(Icons.arrow_drop_down,
                                                color: durumColor, size: 16),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                const Divider(height: 1, color: kremKoyu),
                                const SizedBox(height: 12),

                                // Lojistik Detayları (Konteyner, Sefer, Liman)
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildBilgiSatiri(
                                        icon: Icons
                                            .directions_boat_filled_rounded,
                                        baslik: 'Konteyner No',
                                        deger: konteynerNo,
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildBilgiSatiri(
                                        icon: Icons.local_shipping_rounded,
                                        baslik: 'Plaka / Sefer No',
                                        deger: plakaSefer,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildBilgiSatiri(
                                        icon: Icons.anchor_rounded,
                                        baslik: 'Çıkış Limanı',
                                        deger: cikisLimani,
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildBilgiSatiri(
                                        icon: Icons.place_rounded,
                                        baslik: 'Varış / Teslim',
                                        deger: varisNoktasi,
                                      ),
                                    ),
                                  ],
                                ),

                                if (aciklama.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: kremArkaplan,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.notes_rounded,
                                            size: 16, color: Colors.grey),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            aciklama,
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.black87),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 12),
                                // Alt Bar: Tarihler
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Sevk: ${sevkDate.day.toString().padLeft(2, '0')}.${sevkDate.month.toString().padLeft(2, '0')}.${sevkDate.year}',
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.grey),
                                    ),
                                    if (varisDate != null)
                                      Text(
                                        'Tahmini Varış: ${varisDate.day.toString().padLeft(2, '0')}.${varisDate.month.toString().padLeft(2, '0')}.${varisDate.year}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: durum == 'Teslim Edildi'
                                              ? const Color(0xFF2E7D32)
                                              : hurmaKahvesiAcik,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBilgiSatiri({
    required IconData icon,
    required String baslik,
    required String deger,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: hurmaKahvesiAcik),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(baslik,
                  style: const TextStyle(fontSize: 10, color: Colors.grey)),
              Text(
                deger,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: hurmaKahvesiKoyu,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LOJİSTİK ÖZET KARTI
  // ============================================================
  Widget _buildLojistikOzetKarti({
    required int toplamSevkiyat,
    required int hazirlaniyor,
    required int gumrukte,
    required int yolda,
    required int teslimEdildi,
    required double toplamTonaj,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [hurmaKahvesi, hurmaKahvesiKoyu],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: hurmaKahvesi.withOpacity(0.3),
            blurRadius: 12,
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
              const Row(
                children: [
                  Icon(Icons.public_rounded, color: altinSarisi, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'İhracat & Sefer Durum Özeti',
                    style: TextStyle(
                      color: kremArkaplan,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${toplamTonaj.toStringAsFixed(1)} Ton Sevk Edildi',
                  style: const TextStyle(
                      color: altinSarisi,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Colors.white24),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOzetSayac(
                  'Hazırlanıyor', hazirlaniyor, const Color(0xFF90CAF9)),
              _buildOzetSayac('Gümrükte', gumrukte, const Color(0xFFFFCC80)),
              _buildOzetSayac('Yolda', yolda, const Color(0xFFCE93D8)),
              _buildOzetSayac('Teslim', teslimEdildi, const Color(0xFFA5D6A7)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOzetSayac(String baslik, int sayi, Color renk) {
    return Column(
      children: [
        Text(
          '$sayi',
          style: TextStyle(
            color: renk,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          baslik,
          style: const TextStyle(color: Color(0xFFD7CCC8), fontSize: 11),
        ),
      ],
    );
  }

  // ============================================================
  // 2. SEKME: YENİ SEVKİYAT OLUŞTURMA FORMU
  // ============================================================
  Widget _buildYeniSevkiyatFormuSekmesi() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Sevkiyat Durumu Seçimi (Başlangıç Durumu)
                _buildDurumSecici(),
                const SizedBox(height: 20),

                // Form Kartı
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kremKoyu),
                    boxShadow: [
                      BoxShadow(
                        color: hurmaKahvesi.withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Müşteri / Cari Seçimi
                      const Text(
                        'Müşteri / Cari Unvanı *',
                        style: TextStyle(
                          color: hurmaKahvesiKoyu,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _cariUnvanController,
                        decoration: _inputDecoration(
                          hint:
                              'Örn: İstanbul Hurma Toptan Ltd. / Al-Barakah Trading',
                          icon: Icons.business_rounded,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Müşteri/Cari bilgisi zorunludur.'
                            : null,
                      ),
                      const SizedBox(height: 20),

                      // Hurma Çeşidi Hızlı Seçim ve Giriş
                      const Text(
                        'Hurma Çeşidi *',
                        style: TextStyle(
                          color: hurmaKahvesiKoyu,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _urunCesidiController,
                        decoration: _inputDecoration(
                          hint: 'Örn: Medine İbrâhimî, Kudsî, Mebrûm',
                          icon: Icons.eco_rounded,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Hurma çeşidi girilmelidir.'
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        children: _populerHurmaCesitleri.map((c) {
                          return ActionChip(
                            label:
                                Text(c, style: const TextStyle(fontSize: 11)),
                            backgroundColor: kremArkaplan,
                            onPressed: () =>
                                setState(() => _urunCesidiController.text = c),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Miktar ve Birim (Ton / Koli / Palet)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Sevk Edilecek Miktar *',
                                  style: TextStyle(
                                      color: hurmaKahvesiKoyu,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _miktarController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d+[\.,]?\d{0,2}'))
                                  ],
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: hurmaKahvesiKoyu),
                                  decoration: _inputDecoration(
                                      hint: '0.00', icon: Icons.scale_rounded),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty)
                                      return 'Miktar zorunludur.';
                                    final n =
                                        double.tryParse(v.replaceAll(',', '.'));
                                    if (n == null || n <= 0)
                                      return 'Geçerli miktar girin.';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Birim Türü *',
                                  style: TextStyle(
                                      color: hurmaKahvesiKoyu,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 52,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: kremArkaplan,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color:
                                            hurmaKahvesiAcik.withOpacity(0.3)),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _secilenBirim,
                                      isExpanded: true,
                                      icon: const Icon(Icons.arrow_drop_down,
                                          color: hurmaKahvesi),
                                      style: const TextStyle(
                                          color: hurmaKahvesiKoyu,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                      items: _birimler
                                          .map((b) => DropdownMenuItem(
                                              value: b, child: Text(b)))
                                          .toList(),
                                      onChanged: (v) {
                                        if (v != null)
                                          setState(() => _secilenBirim = v);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      const Divider(color: kremKoyu),
                      const SizedBox(height: 16),

                      // Konteyner No & Plaka / Sefer No
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Konteyner Numarası',
                                    style: TextStyle(
                                        color: hurmaKahvesiKoyu,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13)),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _konteynerNoController,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  decoration: _inputDecoration(
                                    hint: 'Örn: MSKU 904218-3',
                                    icon: Icons.view_in_ar_rounded,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Plaka / Sefer Bilgisi',
                                    style: TextStyle(
                                        color: hurmaKahvesiKoyu,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13)),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _plakaSeferController,
                                  decoration: _inputDecoration(
                                    hint: 'Örn: 34 NKL 1453 / MSC V.2401',
                                    icon: Icons.local_shipping_rounded,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Gümrük Çıkış Limanı & Varış Noktası
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Gümrük Çıkış Limanı *',
                                    style: TextStyle(
                                        color: hurmaKahvesiKoyu,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13)),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _cikisLimaniController,
                                  decoration: _inputDecoration(
                                    hint: 'Örn: Cidde İslam Limanı',
                                    icon: Icons.anchor_rounded,
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'Çıkış limanı girilmelidir.'
                                          : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Varış Noktası / Limanı',
                                    style: TextStyle(
                                        color: hurmaKahvesiKoyu,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13)),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _varisNoktasiController,
                                  decoration: _inputDecoration(
                                    hint: 'Örn: Mersin Limanı (TR)',
                                    icon: Icons.place_rounded,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Liman Öneri Çipleri
                      Wrap(
                        spacing: 6,
                        children: _limanOnerileri.map((liman) {
                          return ActionChip(
                            label: Text(liman,
                                style: const TextStyle(fontSize: 10)),
                            backgroundColor: kremArkaplan,
                            onPressed: () => setState(
                                () => _cikisLimaniController.text = liman),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Sevk Tarihi & Tahmini Varış
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Sevk / Çıkış Tarihi',
                                    style: TextStyle(
                                        color: hurmaKahvesiKoyu,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13)),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () => _tarihSec(true),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    height: 50,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: kremArkaplan,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: hurmaKahvesiAcik
                                              .withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_month_rounded,
                                            size: 18, color: hurmaKahvesi),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${_sevkTarihi.day.toString().padLeft(2, '0')}.${_sevkTarihi.month.toString().padLeft(2, '0')}.${_sevkTarihi.year}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: hurmaKahvesiKoyu),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Tahmini Varış Tarihi',
                                    style: TextStyle(
                                        color: hurmaKahvesiKoyu,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13)),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () => _tarihSec(false),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    height: 50,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: kremArkaplan,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: hurmaKahvesiAcik
                                              .withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                            Icons.event_available_rounded,
                                            size: 18,
                                            color: hurmaKahvesi),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${_tahminiVarisTarihi.day.toString().padLeft(2, '0')}.${_tahminiVarisTarihi.month.toString().padLeft(2, '0')}.${_tahminiVarisTarihi.year}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: hurmaKahvesiKoyu),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Ek Notlar & Gümrük Beyannamesi
                      const Text('Gümrük & Lojistik Notları (Opsiyonel)',
                          style: TextStyle(
                              color: hurmaKahvesiKoyu,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _aciklamaController,
                        maxLines: 2,
                        decoration: _inputDecoration(
                          hint:
                              'Örn: Soğutuculu konteyner reefer +4°C, fitosaniter sertifika no: SA-2026/894',
                          icon: Icons.receipt_long_rounded,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Kaydet Butonu
                ElevatedButton(
                  onPressed: _kaydediliyor ? null : _sevkiyatKaydet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hurmaKahvesi,
                    foregroundColor: kremArkaplan,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _kaydediliyor
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: kremArkaplan, strokeWidth: 2)),
                            SizedBox(width: 12),
                            Text('Sevkiyat Kaydediliyor...',
                                style: TextStyle(fontSize: 16)),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_rounded,
                                size: 22, color: altinSarisi),
                            SizedBox(width: 10),
                            Text(
                              'Sevkiyatı ERP Sistemine Kaydet',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DURUM SEÇİCİ BİLEŞENİ
  // ============================================================
  Widget _buildDurumSecici() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Başlangıç Sevkiyat Durumu *',
          style: TextStyle(
              color: hurmaKahvesiKoyu,
              fontWeight: FontWeight.w700,
              fontSize: 14),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _durumListesi.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isMobile ? 2 : 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: isMobile ? 1.7 : 1.6,
              ),
              itemBuilder: (context, index) {
                final d = _durumListesi[index];
                final secili = _secilenDurum == d['id'];
                final Color anaRenk = d['color'] as Color;

                return InkWell(
                  onTap: () =>
                      setState(() => _secilenDurum = d['id'] as String),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: secili ? anaRenk.withOpacity(0.12) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: secili ? anaRenk : kremKoyu,
                          width: secili ? 2 : 1),
                      boxShadow: [
                        if (secili)
                          BoxShadow(
                              color: anaRenk.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: anaRenk.withOpacity(0.15),
                              child: Icon(d['icon'] as IconData,
                                  size: 16, color: anaRenk),
                            ),
                            const Spacer(),
                            if (secili)
                              Icon(Icons.check_circle,
                                  size: 16, color: anaRenk),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          d['label'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: secili ? anaRenk : hurmaKahvesiKoyu,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  // ============================================================
  // YARDIMCI METODLAR
  // ============================================================
  Map<String, dynamic> _getDurumMeta(String durum) {
    return _durumListesi.firstWhere(
      (e) => e['id'] == durum,
      orElse: () => _durumListesi.first,
    );
  }

  InputDecoration _inputDecoration(
      {required String hint, required IconData icon}) {
    return InputDecoration(
      filled: true,
      fillColor: kremArkaplan,
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      prefixIcon: Icon(icon, color: hurmaKahvesi),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: hurmaKahvesiAcik.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: hurmaKahvesiAcik.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: hurmaKahvesi, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}
