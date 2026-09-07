// ============================================================
// STOK YÖNETİM MODÜLÜ  (Depo & Hurma Envanteri)
// ============================================================
// NAKHL & NAHL Kurumsal Renk Paleti:
//   - Hurma Kahvesi: #5C4033
//   - Krem: #FBF9F1
//
// Supabase PostgreSQL: 'items' ve 'stock_ledger_entries' tabloları üzerinden
// gerçek zamanlı envanter takibi, hurma çeşitleri, tonaj/koli/çuval
// ve birim maliyet (SAR / TRY) hesaplaması.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/supabase_service.dart';
import '../core/tenant/tenant_context.dart';

class StokYonetimScreen extends StatefulWidget {
  const StokYonetimScreen({super.key});

  @override
  State<StokYonetimScreen> createState() => _StokYonetimScreenState();
}

class _StokYonetimScreenState extends State<StokYonetimScreen>
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
  final _urunCesidiController = TextEditingController();
  final _miktarController = TextEditingController();
  final _birimMaliyetController = TextEditingController();
  final _partiNoController = TextEditingController();
  final _depoAdiController = TextEditingController(text: 'Medine Merkez Depo');
  final _notlarController = TextEditingController();

  // Seçili Değerler
  String _secilenBirim = 'Ton'; // Ton, Koli, Çuval, Kg
  String _secilenParaBirimi = 'SAR'; // SAR, TRY, USD, EUR
  bool _kaydediliyor = false;
  late TabController _tabController;

  // Popüler / Standart Ürün Çeşitleri (Çok Sektörlü ERP)
  final List<String> _populerHurmaCesitleri = [
    'Acve Hurması (VIP Duble)',
    'Medine Mebrûm',
    'Sukkari (Yaş/Kuru)',
    'Safawî',
    'Karakovan Balı (Organik)',
    'Zeytinyağı (Soğuk Sıkım)',
    'Masif Meşe Masa',
    'Pamuklu Kumaş Topu',
  ];


  // Birim Listesi
  final List<String> _birimler = ['Ton', 'Koli', 'Çuval', 'Kg'];

  // Para Birimleri
  final List<Map<String, String>> _paraBirimleri = [
    {'kod': 'SAR', 'ad': 'Suudi Arabistan Riyali', 'sembol': '﷼'},
    {'kod': 'TRY', 'ad': 'Türk Lirası', 'sembol': '₺'},
    {'kod': 'USD', 'ad': 'Amerikan Doları', 'sembol': '\$'},
    {'kod': 'EUR', 'ad': 'Euro', 'sembol': '€'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _urunCesidiController.dispose();
    _miktarController.dispose();
    _birimMaliyetController.dispose();
    _partiNoController.dispose();
    _depoAdiController.dispose();
    _notlarController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ============================================================
  // FİREBASE FİRESTORE STOK KAYIT FONKSİYONU
  // ============================================================
  Future<void> _stokKaydet() async {
    if (!_formKey.currentState!.validate()) return;

    final String urunCesidi = _urunCesidiController.text.trim();
    final double? miktar =
        double.tryParse(_miktarController.text.replaceAll(',', '.'));
    final double? birimMaliyet =
        double.tryParse(_birimMaliyetController.text.replaceAll(',', '.'));

    if (miktar == null || miktar <= 0) {
      _hataMesajiGoster('Lütfen geçerli ve pozitif bir miktar giriniz.');
      return;
    }

    if (birimMaliyet == null || birimMaliyet < 0) {
      _hataMesajiGoster('Lütfen geçerli bir birim maliyet giriniz.');
      return;
    }

    final double toplamDeger = miktar * birimMaliyet;

    setState(() => _kaydediliyor = true);

    try {
      final tenantId = TenantContext.instance.activeTenantId ??
          '00000000-0000-0000-0000-000000000001';
      final stokVerisi = {
        'tenant_id': tenantId,
        'item_code':
            'ITM-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        'name': urunCesidi,
        'urunCesidi': urunCesidi,
        'category': 'Hurma',
        'unit_of_measure': _secilenBirim,
        'birim': _secilenBirim,
        'miktar': miktar,
        'birimMaliyet': birimMaliyet,
        'paraBirimi': _secilenParaBirimi,
        'toplamDeger': toplamDeger,
        'depoAdi': _depoAdiController.text.trim().isNotEmpty
            ? _depoAdiController.text.trim()
            : 'Medine Merkez Depo',
        'partiNo': _partiNoController.text.trim().isNotEmpty
            ? _partiNoController.text.trim()
            : 'PRT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        'notlar': _notlarController.text.trim(),
        'status': 'ACTIVE',
      };

      // Supabase tablosuna kayıt
      await SupabaseService.client.from('items').insert(stokVerisi);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$urunCesidi — $miktar $_secilenBirim başarıyla depoya kaydedildi.',
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

      // Formu sıfırla ve listeye geç
      _formuSifirla();
      _tabController.animateTo(0);
    } catch (e) {
      if (!mounted) return;
      _hataMesajiGoster('Stok kaydı sırasında bir hata oluştu: $e');
    } finally {
      if (mounted) setState(() => _kaydediliyor = false);
    }
  }

  void _formuSifirla() {
    _urunCesidiController.clear();
    _miktarController.clear();
    _birimMaliyetController.clear();
    _partiNoController.clear();
    _notlarController.clear();
    setState(() {
      _secilenBirim = 'Ton';
      _secilenParaBirimi = 'SAR';
    });
  }

  void _hataMesajiGoster(String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mesaj),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Stok Silme Fonksiyonu
  Future<void> _stokSil(String docId, String cesit) async {
    final bool? onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kremArkaplan,
        title: const Text('Stok Kaydını Sil',
            style: TextStyle(
                color: hurmaKahvesiKoyu, fontWeight: FontWeight.bold)),
        content: Text(
            '$cesit stoğunu depodan silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:
                  const Text('Vazgeç', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade800,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Evet, Sil'),
          ),
        ],
      ),
    );

    if (onay == true) {
      try {
        await SupabaseService.client.from('items').delete().eq('id', docId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('$cesit stoğu silindi.'),
                backgroundColor: hurmaKahvesi),
          );
        }
      } catch (e) {
        if (mounted) _hataMesajiGoster('Silme hatası: $e');
      }
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
              'Stok & Envanter Yönetimi',
              style: TextStyle(
                color: kremArkaplan,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'NAKHL & NAHL — Hurma Depo ve Maliyet Takibi',
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
            Tab(icon: Icon(Icons.inventory_2_rounded), text: 'Depo & Envanter'),
            Tab(
                icon: Icon(Icons.add_circle_outline),
                text: 'Yeni Hurma Stoğu Ekle'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDepoEnvanterSekmesi(),
          _buildYeniStokFormuSekmesi(),
        ],
      ),
    );
  }

  // ============================================================
  // 1. SEKME: DEPO & GERÇEK ZAMANLI ENVANTER LİSTESİ
  // ============================================================
  Widget _buildDepoEnvanterSekmesi() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: SupabaseService.client
          .from('items')
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
                    'Stok verileri çekilirken hata oluştu:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: hurmaKahvesiKoyu),
                  ),
                ],
              ),
            ),
          );
        }

        final docs = snapshot.data ?? [];

        // Özet Metrikleri Hesapla
        double toplamTonaj = 0.0;
        double toplamKoli = 0.0;
        double toplamCuval = 0.0;
        double toplamDegerSar = 0.0;
        double toplamDegerTry = 0.0;

        for (var doc in docs) {
          final data = doc;
          final double miktar = (data['miktar'] as num?)?.toDouble() ?? 0.0;
          final String birim = (data['birim'] as String?) ??
              (data['unit_of_measure'] as String?) ??
              'Ton';
          final double toplamDeger =
              (data['toplamDeger'] as num?)?.toDouble() ?? 0.0;
          final String pb = (data['paraBirimi'] as String?) ?? 'SAR';

          if (birim == 'Ton') toplamTonaj += miktar;
          if (birim == 'Koli') toplamKoli += miktar;
          if (birim == 'Çuval') toplamCuval += miktar;

          if (pb == 'SAR') {
            toplamDegerSar += toplamDeger;
          } else if (pb == 'TRY') {
            toplamDegerTry += toplamDeger;
          } else {
            toplamDegerSar += toplamDeger;
          }
        }

        return Column(
          children: [
            // Üst Kısım: Şık Toplam Envanter Özet Kartı
            _buildEnvanterOzetKarti(
              toplamCesit: docs.length,
              toplamTonaj: toplamTonaj,
              toplamKoli: toplamKoli,
              toplamCuval: toplamCuval,
              toplamDegerSar: toplamDegerSar,
              toplamDegerTry: toplamDegerTry,
            ),

            // Liste Alanı
            Expanded(
              child: docs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 64,
                              color: hurmaKahvesiAcik.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          const Text(
                            'Depoda henüz kayıtlı hurma stoğu bulunmuyor.',
                            style: TextStyle(
                                color: hurmaKahvesiKoyu,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Yeni stok eklemek için ikinci sekmeyi kullanabilirsiniz.',
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
                            label: const Text('Yeni Stok Girişi Yap'),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final data = docs[index];
                        final String docId = data['id']?.toString() ?? '';

                        final String cesit =
                            data['urunCesidi'] ?? data['name'] ?? 'Hurma';
                        final double miktar =
                            (data['miktar'] as num?)?.toDouble() ?? 0.0;
                        final String birim =
                            data['birim'] ?? data['unit_of_measure'] ?? 'Ton';
                        final double birimMaliyet =
                            (data['birimMaliyet'] as num?)?.toDouble() ?? 0.0;
                        final String paraBirimi = data['paraBirimi'] ?? 'SAR';
                        final double toplamDeger =
                            (data['toplamDeger'] as num?)?.toDouble() ??
                                (miktar * birimMaliyet);
                        final String depoAdi =
                            data['depoAdi'] ?? 'Medine Merkez Depo';
                        final String partiNo = data['partiNo'] ?? '-';
                        final DateTime tarih = DateTime.tryParse(
                                data['created_at']?.toString() ?? '') ??
                            DateTime.now();

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: kremKoyu),
                            boxShadow: [
                              BoxShadow(
                                color: hurmaKahvesi.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: hurmaKahvesi.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.eco_rounded,
                                          color: hurmaKahvesi, size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cesit,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: hurmaKahvesiKoyu,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '$depoAdi • Parti: $partiNo',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: Colors.grey,
                                          size: 20),
                                      tooltip: 'Stoğu Sil',
                                      onPressed: () => _stokSil(docId, cesit),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(height: 1, color: kremKoyu),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Miktar & Birim
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Mevcut Stok',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey)),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${miktar.toStringAsFixed(2)} $birim',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: hurmaKahvesiKoyu,
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Birim Maliyet
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Ort. Birim Maliyet',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey)),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${birimMaliyet.toStringAsFixed(2)} $paraBirimi / $birim',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: Color(0xFF424242),
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Toplam Envanter Değeri
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        const Text('Toplam Değer',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey)),
                                        const SizedBox(height: 2),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color:
                                                altinSarisi.withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '${toplamDeger.toStringAsFixed(2)} $paraBirimi',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Color(0xFF7A4A00),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    'Kayıt: ${tarih.day.toString().padLeft(2, '0')}.${tarih.month.toString().padLeft(2, '0')}.${tarih.year}',
                                    style: const TextStyle(
                                        fontSize: 10, color: Colors.grey),
                                  ),
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

  // ============================================================
  // ÖZET ENVANTER KARTI (HURMA KAHVESİ & KREM)
  // ============================================================
  Widget _buildEnvanterOzetKarti({
    required int toplamCesit,
    required double toplamTonaj,
    required double toplamKoli,
    required double toplamCuval,
    required double toplamDegerSar,
    required double toplamDegerTry,
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
                  Icon(Icons.pie_chart_outline_rounded,
                      color: altinSarisi, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Genel Envanter & Maliyet Özeti',
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
                  '$toplamCesit Çeşit Hurma',
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
          const SizedBox(height: 14),
          Row(
            children: [
              // Tonaj / Miktar Kırılımı
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Depodaki Toplam Hacim',
                        style:
                            TextStyle(color: Color(0xFFD7CCC8), fontSize: 11)),
                    const SizedBox(height: 4),
                    Text(
                      '${toplamTonaj.toStringAsFixed(2)} Ton',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    if (toplamKoli > 0 || toplamCuval > 0)
                      Text(
                        '${toplamKoli > 0 ? '${toplamKoli.toStringAsFixed(0)} Koli ' : ''}${toplamCuval > 0 ? '• ${toplamCuval.toStringAsFixed(0)} Çuval' : ''}',
                        style:
                            const TextStyle(color: altinSarisi, fontSize: 11),
                      ),
                  ],
                ),
              ),
              Container(width: 1, height: 44, color: Colors.white24),
              // Toplam Envanter Değeri (SAR & TRY)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Toplam Envanter Değeri',
                          style: TextStyle(
                              color: Color(0xFFD7CCC8), fontSize: 11)),
                      const SizedBox(height: 4),
                      Text(
                        '${toplamDegerSar.toStringAsFixed(2)} SAR',
                        style: const TextStyle(
                            color: altinSarisi,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                      if (toplamDegerTry > 0)
                        Text(
                          '+ ${toplamDegerTry.toStringAsFixed(2)} TRY',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 2. SEKME: YENİ HURMA STOĞU GİRİŞ FORMU
  // ============================================================
  Widget _buildYeniStokFormuSekmesi() {
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
                // Popüler Hurma Çeşitleri Hızlı Seçici
                _buildHurmaCesitSecici(),
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
                      // Hurma Çeşidi Adı (Seçilebilir veya Yeni Yazılabilir)
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
                          hint:
                              'Örn: Medine İbrâhimî, Kudsî, Mebrûm veya yeni çeşit',
                          icon: Icons.eco_rounded,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Hurma çeşidi girilmesi zorunludur.'
                            : null,
                      ),
                      const SizedBox(height: 20),

                      // Miktar ve Birim (Ton / Koli / Çuval)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Miktar
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Giriş Miktarı *',
                                  style: TextStyle(
                                    color: hurmaKahvesiKoyu,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _miktarController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d+[\.,]?\d{0,3}')),
                                  ],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: hurmaKahvesiKoyu,
                                  ),
                                  decoration: _inputDecoration(
                                    hint: '0.00',
                                    icon: Icons.scale_rounded,
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty)
                                      return 'Miktar zorunludur.';
                                    final n =
                                        double.tryParse(v.replaceAll(',', '.'));
                                    if (n == null || n <= 0)
                                      return 'Geçerli bir miktar girin.';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Birim Seçimi (Ton, Koli, Çuval)
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
                                    fontSize: 14,
                                  ),
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
                                        fontSize: 14,
                                      ),
                                      items: _birimler.map((b) {
                                        return DropdownMenuItem(
                                            value: b, child: Text(b));
                                      }).toList(),
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

                      // Birim Maliyet ve Para Birimi (SAR / TRY)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Ortalama Birim Maliyet
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Ortalama Birim Maliyet *',
                                  style: TextStyle(
                                    color: hurmaKahvesiKoyu,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _birimMaliyetController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d+[\.,]?\d{0,2}')),
                                  ],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: hurmaKahvesiKoyu,
                                  ),
                                  decoration: _inputDecoration(
                                    hint: '0.00',
                                    icon: Icons.payments_rounded,
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty)
                                      return 'Maliyet zorunludur.';
                                    final n =
                                        double.tryParse(v.replaceAll(',', '.'));
                                    if (n == null || n < 0)
                                      return 'Geçerli bir maliyet girin.';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Para Birimi Seçimi (SAR, TRY, USD, EUR)
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Maliyet Para Birimi *',
                                  style: TextStyle(
                                    color: hurmaKahvesiKoyu,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
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
                                      value: _secilenParaBirimi,
                                      isExpanded: true,
                                      icon: const Icon(Icons.arrow_drop_down,
                                          color: hurmaKahvesi),
                                      style: const TextStyle(
                                        color: hurmaKahvesiKoyu,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      items: _paraBirimleri.map((pb) {
                                        return DropdownMenuItem<String>(
                                          value: pb['kod'],
                                          child: Text(
                                              '${pb['kod']} (${pb['sembol']})'),
                                        );
                                      }).toList(),
                                      onChanged: (v) {
                                        if (v != null)
                                          setState(
                                              () => _secilenParaBirimi = v);
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

                      // Depo Adı & Parti / Seri No
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Depo Konumu',
                                  style: TextStyle(
                                      color: hurmaKahvesiKoyu,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _depoAdiController,
                                  decoration: _inputDecoration(
                                    hint: 'Örn: Medine Soğuk Hava Deposu',
                                    icon: Icons.store_mall_directory_rounded,
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
                                const Text(
                                  'Parti / Lot No (Opsiyonel)',
                                  style: TextStyle(
                                      color: hurmaKahvesiKoyu,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _partiNoController,
                                  decoration: _inputDecoration(
                                    hint: 'Örn: PRT-2026/04',
                                    icon: Icons.tag_rounded,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Ek Notlar
                      const Text(
                        'Kalite & Menşei Notları (Opsiyonel)',
                        style: TextStyle(
                            color: hurmaKahvesiKoyu,
                            fontWeight: FontWeight.w700,
                            fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _notlarController,
                        maxLines: 2,
                        decoration: _inputDecoration(
                          hint:
                              'Örn: 2026 Hasadı, 1. Kalite jumbo boy, nem oranı %18',
                          icon: Icons.note_alt_rounded,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Kaydet Butonu
                ElevatedButton(
                  onPressed: _kaydediliyor ? null : _stokKaydet,
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
                                  color: kremArkaplan, strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('ERP Envanterine Kaydediliyor...',
                                style: TextStyle(fontSize: 16)),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_shopping_cart_rounded,
                                size: 22, color: altinSarisi),
                            SizedBox(width: 10),
                            Text(
                              'Stoğu ERP Envanterine Kaydet',
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
  // HURMA ÇEŞİDİ HIZLI SEÇİCİ BİLEŞENİ (ÇİPLER)
  // ============================================================
  Widget _buildHurmaCesitSecici() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ürün / Çeşitler (Hızlı Seçim)',
          style: TextStyle(
            color: hurmaKahvesiKoyu,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),

        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _populerHurmaCesitleri.map((cesit) {
            final secili = _urunCesidiController.text.trim() == cesit;
            return ChoiceChip(
              label: Text(cesit),
              selected: secili,
              selectedColor: hurmaKahvesi,
              labelStyle: TextStyle(
                color: secili ? Colors.white : hurmaKahvesiKoyu,
                fontWeight: secili ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color:
                      secili ? hurmaKahvesi : hurmaKahvesiAcik.withOpacity(0.3),
                ),
              ),
              onSelected: (val) {
                if (val) {
                  setState(() => _urunCesidiController.text = cesit);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // ============================================================
  // YARDIMCI GÖRSEL ELEMANLAR
  // ============================================================
  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
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
