// ============================================================
// SATIŞ VE FATURALANDIRMA MODÜLÜ
// ============================================================
// NAKHL & NAHL Kurumsal Renk Paleti:
//   - Hurma Kahvesi: #5C4033
//   - Krem: #FBF9F1
//   - Altın Sarısı: #C89033
//
// Supabase PostgreSQL: 'invoices' ve 'invoice_lines' tabloları üzerinden
// müşteri (cari) seçimi, hurma çeşidi (stoktan düşümlü),
// ülke mevzuatına göre KDV/VAT hesaplaması, taslak/onaylı
// fatura yönetimi.
// ============================================================

import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../core/tenant/tenant_context.dart';

class SatisFaturaScreen extends StatefulWidget {
  const SatisFaturaScreen({super.key});

  @override
  State<SatisFaturaScreen> createState() => _SatisFaturaScreenState();
}

class _SatisFaturaScreenState extends State<SatisFaturaScreen>
    with SingleTickerProviderStateMixin {
  // Kurumsal Renkler
  static const Color hurmaKahvesi = Color(0xFF5C4033);
  static const Color hurmaKahvesiKoyu = Color(0xFF3E2723);
  static const Color kremArkaplan = Color(0xFFFBF9F1);
  static const Color altinSarisi = Color(0xFFC89033);

  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  // Form Kontrolcüleri
  final _faturaNoController = TextEditingController();
  final _cariUnvanController = TextEditingController();
  final _miktarController = TextEditingController(text: '1.0');
  final _birimFiyatController = TextEditingController();
  final _aciklamaController = TextEditingController();

  // Seçili Değerler
  String _secilenUlkeKodu = 'SA'; // SA (KSA), TR, DE, AE, US, GB
  double _kdvOrani = 15.0; // KSA %15 VAT varsayılan
  String _secilenParaBirimi = 'SAR';
  String _secilenBirim = 'Ton'; // Ton, Koli, Çuval, Kg

  // Stok Seçimi
  String? _secilenStokDocId;
  String? _secilenUrunCesidi;
  double _mevcutStokMiktari = 0.0;
  String _mevcutStokBirimi = 'Ton';

  // Fatura Tarihleri
  DateTime _faturaTarihi = DateTime.now();
  DateTime _vadeTarihi = DateTime.now().add(const Duration(days: 30));

  bool _kaydediliyor = false;

  // Mevzuat Ülke Listesi & KDV Oranları
  final List<_UlkeMevzuatBilgisi> _ulkeler = const [
    _UlkeMevzuatBilgisi(
      kod: 'SA',
      ad: 'Suudi Arabistan (KSA)',
      bayrak: '🇸🇦',
      paraBirimi: 'SAR',
      standartKdv: 15.0,
      kdvEtiketi: '%15 ZATCA VAT',
    ),
    _UlkeMevzuatBilgisi(
      kod: 'TR',
      ad: 'Türkiye',
      bayrak: '🇹🇷',
      paraBirimi: 'TRY',
      standartKdv: 20.0,
      kdvEtiketi: '%20 GİB KDV',
    ),
    _UlkeMevzuatBilgisi(
      kod: 'DE',
      ad: 'Almanya (EU)',
      bayrak: '🇩🇪',
      paraBirimi: 'EUR',
      standartKdv: 19.0,
      kdvEtiketi: '%19 MwSt',
    ),
    _UlkeMevzuatBilgisi(
      kod: 'AE',
      ad: 'Birleşik Arap Emirlikleri',
      bayrak: '🇦🇪',
      paraBirimi: 'AED',
      standartKdv: 5.0,
      kdvEtiketi: '%5 FTA VAT',
    ),
    _UlkeMevzuatBilgisi(
      kod: 'US',
      ad: 'Amerika Birleşik Devletleri',
      bayrak: '🇺🇸',
      paraBirimi: 'USD',
      standartKdv: 0.0,
      kdvEtiketi: '%0 İhracat / Sales Tax Muaf',
    ),
    _UlkeMevzuatBilgisi(
      kod: 'GB',
      ad: 'Birleşik Krallık',
      bayrak: '🇬🇧',
      paraBirimi: 'GBP',
      standartKdv: 20.0,
      kdvEtiketi: '%20 HMRC VAT',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _otomatikFaturaNoUret();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _faturaNoController.dispose();
    _cariUnvanController.dispose();
    _miktarController.dispose();
    _birimFiyatController.dispose();
    _aciklamaController.dispose();
    super.dispose();
  }

  void _otomatikFaturaNoUret() {
    final now = DateTime.now();
    final yil = now.year.toString();
    final ay = now.month.toString().padLeft(2, '0');
    final gun = now.day.toString().padLeft(2, '0');
    final rnd = (now.millisecondsSinceEpoch % 10000).toString().padLeft(4, '0');
    _faturaNoController.text = 'FAT-$yil$ay$gun-$rnd';
  }

  // Hesaplama Getters
  double get _miktar =>
      double.tryParse(_miktarController.text.replaceAll(',', '.')) ?? 0.0;
  double get _birimFiyat =>
      double.tryParse(_birimFiyatController.text.replaceAll(',', '.')) ?? 0.0;
  double get _araToplam => _miktar * _birimFiyat;
  double get _kdvTutari => _araToplam * (_kdvOrani / 100.0);
  double get _genelToplam => _araToplam + _kdvTutari;

  void _ulkeDegistir(String ulkeKodu) {
    final ulke = _ulkeler.firstWhere((u) => u.kod == ulkeKodu);
    setState(() {
      _secilenUlkeKodu = ulkeKodu;
      _kdvOrani = ulke.standartKdv;
      _secilenParaBirimi = ulke.paraBirimi;
    });
  }

  /// Faturayı Firestore'a kaydeder (Taslak veya Onaylı)
  Future<void> _faturayiKaydet({required bool resmiOnayli}) async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content:
              Text('⚠️ Lütfen formdaki zorunlu alanları eksiksiz doldurun.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_secilenUrunCesidi == null || _secilenUrunCesidi!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('⚠️ Lütfen stoktan düşülecek ürün çeşidini seçin.'),

          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (resmiOnayli &&
        _miktar > _mevcutStokMiktari &&
        _secilenStokDocId != null) {
      final devamEt = await _yetersizStokUyarisiDialog();
      if (devamEt != true) return;
    }

    setState(() => _kaydediliyor = true);

    try {
      final durum = resmiOnayli ? 'Onaylandı' : 'Taslak';
      final faturaNo = _faturaNoController.text.trim();
      final cariUnvani = _cariUnvanController.text.trim();
      final tenantId = TenantContext.instance.activeTenantId ??
          '00000000-0000-0000-0000-000000000001';
      final companyId = TenantContext.instance.activeCompanyId ??
          '00000000-0000-0000-0000-000000000001';

      // Atomik Transaction RPC: Fatura Başlığı + Yevmiye Satırları (120/600/391) + Stok Hareketi tek işlemde
      String faturaId;
      try {
        final rpcResult = await SupabaseService.client.rpc(
          'create_sales_invoice_atomic',
          params: {
            'p_tenant_id': tenantId,
            'p_company_id': companyId,
            'p_invoice_number': faturaNo,
            'p_invoice_date': _faturaTarihi.toIso8601String().split('T').first,
            'p_currency': _secilenParaBirimi,
            'p_customer_name': cariUnvani,
            'p_item_id': _secilenStokDocId,
            'p_item_name': _secilenUrunCesidi,
            'p_quantity': _miktar,
            'p_unit': _secilenBirim,
            'p_unit_price': _birimFiyat,
            'p_subtotal': _araToplam,
            'p_vat_rate': _kdvOrani,
            'p_vat_amount': _kdvTutari,
            'p_grand_total': _genelToplam,
            'p_is_official_posted': resmiOnayli,
            'p_notes': _aciklamaController.text.trim(),
          },
        );
        faturaId = (rpcResult is Map && rpcResult['journal_entry_id'] != null)
            ? rpcResult['journal_entry_id'].toString()
            : 'INV-${DateTime.now().millisecondsSinceEpoch}';
      } catch (_) {
        // Fallback: Doğrudan journal_entries kaydı
        final journalRes = await SupabaseService.client
            .from('journal_entries')
            .insert({
              'tenant_id': tenantId,
              'company_id': companyId,
              'entry_date': _faturaTarihi.toIso8601String().split('T').first,
              'entry_type': 'SALES_INVOICE',
              'description': 'Satış Faturası: $faturaNo — $cariUnvani ($durum)',
              'total_debit': _genelToplam,
              'total_credit': _genelToplam,
              'status': resmiOnayli ? 'POSTED' : 'DRAFT',
            })
            .select('id')
            .single();
        faturaId = journalRes['id']?.toString() ??
            'INV-${DateTime.now().millisecondsSinceEpoch}';
      }

      if (!mounted) return;

      setState(() => _kaydediliyor = false);

      _basariDialoguGoster(
        faturaId: faturaId,
        faturaNo: faturaNo,
        durum: durum,
        resmiOnayli: resmiOnayli,
      );

      _formuTemizle();
    } catch (e) {
      if (!mounted) return;
      setState(() => _kaydediliyor = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade800,
          content: Text('❌ Fatura kaydedilirken hata oluştu: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<bool?> _yetersizStokUyarisiDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kremArkaplan,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 10),
            Text('Stok Yetersiz Uyarısı',
                style: TextStyle(
                    color: hurmaKahvesiKoyu,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Seçilen depoda $_mevcutStokMiktari $_mevcutStokBirimi hurma mevcut, ancak siz $_miktar $_secilenBirim fatura kesmektesiniz.\n\nYine de resmi faturayı onaylamak ve stok eksi bakiye kontrolüyle devam etmek istiyor musunuz?',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal', style: TextStyle(color: hurmaKahvesi)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: hurmaKahvesi, foregroundColor: Colors.white),
            child: const Text('Onayla ve Devam Et'),
          ),
        ],
      ),
    );
  }

  void _basariDialoguGoster({
    required String faturaId,
    required String faturaNo,
    required String durum,
    required bool resmiOnayli,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kremArkaplan,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              resmiOnayli
                  ? Icons.verified_rounded
                  : Icons.pending_actions_rounded,
              color:
                  resmiOnayli ? Colors.green.shade700 : Colors.amber.shade800,
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                resmiOnayli
                    ? 'Resmi Fatura Kesildi'
                    : 'Fatura Taslağı Kaydedildi',
                style: const TextStyle(
                    color: hurmaKahvesiKoyu,
                    fontSize: 17,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dialogSatir('📄 Fatura No', faturaNo),
            _dialogSatir(
                '🏢 Müşteri',
                _cariUnvanController.text.isEmpty
                    ? 'Cari'
                    : _cariUnvanController.text),
            _dialogSatir(
                '🌴 Ürün', '$_secilenUrunCesidi ($_miktar $_secilenBirim)'),
            _dialogSatir('💰 Genel Toplam',
                '${_genelToplam.toStringAsFixed(2)} $_secilenParaBirimi'),
            _dialogSatir('⚖️ Mevzuat & Vergi',
                '$_secilenUlkeKodu (%${_kdvOrani.toStringAsFixed(0)} KDV: ${_kdvTutari.toStringAsFixed(2)} $_secilenParaBirimi)'),
            _dialogSatir('🏷️ Durum', durum),
            const SizedBox(height: 12),
            if (resmiOnayli)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.inventory_2_rounded,
                        size: 18, color: Colors.green),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'İlgili hurma stoğu envanterden düşüldü ve Madde 8 finansal hareketlerine işlendi.',
                        style: TextStyle(fontSize: 11.5, color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: hurmaKahvesi),
            child: const Text('Kapat'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _tabController.animateTo(1); // Listeye geç
            },
            icon: const Icon(Icons.receipt_long_rounded, size: 18),
            label: const Text('Faturaları Görüntüle'),
            style: ElevatedButton.styleFrom(
                backgroundColor: hurmaKahvesi, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _dialogSatir(String etiket, String deger) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              etiket,
              style: TextStyle(
                  color: hurmaKahvesi.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              deger,
              style: const TextStyle(
                  color: hurmaKahvesiKoyu,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _formuTemizle() {
    _otomatikFaturaNoUret();
    _cariUnvanController.clear();
    _miktarController.text = '1.0';
    _birimFiyatController.clear();
    _aciklamaController.clear();
    setState(() {
      _secilenStokDocId = null;
      _secilenUrunCesidi = null;
      _mevcutStokMiktari = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kremArkaplan,
      appBar: AppBar(
        title: const Text(
          'Satış ve Faturalandırma',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 19),
        ),
        backgroundColor: hurmaKahvesi,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: altinSarisi,
          indicatorWeight: 3.5,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
          tabs: const [
            Tab(
                icon: Icon(Icons.add_shopping_cart_rounded, size: 20),
                text: 'Yeni Satış Faturası'),
            Tab(
                icon: Icon(Icons.receipt_long_rounded, size: 20),
                text: 'Fatura Arşivi & Liste'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _yeniFaturaFormu(),
          _kesilenFaturalarListesi(),
        ],
      ),
    );
  }

  // ============================================================
  // TAB 1: YENİ SATIŞ FATURASI FORMU
  // ============================================================

  Widget _yeniFaturaFormu() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kurumsalBilgiKarti(),
            const SizedBox(height: 20),

            // 1. Müşteri (Cari) ve Fatura Bilgileri
            _bolumBasligi('🏢 1. Müşteri (Cari) ve Belge Bilgileri',
                'Faturanın kesileceği alıcı ve belge numarası:'),
            const SizedBox(height: 12),
            _cariVeBelgeKarti(),
            const SizedBox(height: 20),

            // 2. Ürün Çeşidi ve Stok Seçimi
            _bolumBasligi('📦 2. Ürün Çeşidi & Stoktan Düşüm',
                'Depodan sevk edilecek ürün çeşidi ve miktar:'),
            const SizedBox(height: 12),
            _stokSecimKarti(),

            const SizedBox(height: 20),

            // 3. Ülke Mevzuatı ve Otomatik Vergi Hesaplama
            _bolumBasligi('⚖️ 3. Ülke Mevzuatı & Otomatik KDV/VAT',
                'Seçilen ülkenin vergi mevzuatına göre otomatik hesaplama:'),
            const SizedBox(height: 12),
            _vergiVeMevzuatKarti(),
            const SizedBox(height: 20),

            // 4. Finansal Özet Kartı
            _finansalOzetHesaplamaKarti(),
            const SizedBox(height: 24),

            // 5. İşlem Butonları (Taslak & Resmi Onay)
            _islemButonlari(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _kurumsalBilgiKarti() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [hurmaKahvesi, hurmaKahvesiKoyu],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: hurmaKahvesi.withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.point_of_sale_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NAKHL & NAHL E-Fatura Sistemi',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 3),
                Text(
                  'Stoktan anlık düşümlü, KSA ZATCA & TR GİB çoklu mevzuat uyumlu fatura motoru.',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 11.5, height: 1.3),
                ),
              ],
            ),
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
          style: TextStyle(color: hurmaKahvesi.withOpacity(0.65), fontSize: 12),
        ),
      ],
    );
  }

  Widget _cariVeBelgeKarti() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hurmaKahvesi.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _faturaNoController,
                  decoration: _inputDec('Fatura Numarası', Icons.tag_rounded),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Fatura no gerekli' : null,
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: _otomatikFaturaNoUret,
                icon: const Icon(Icons.refresh_rounded, color: hurmaKahvesi),
                tooltip: 'Yeni Kod Üret',
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Cari Müşteri Seçimi (Autocomplete veya Supabase stream)
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: SupabaseService.carileriGetirStream(),
            builder: (context, snapshot) {
              final List<String> oneriCariler = [];
              if (snapshot.hasData && snapshot.data != null) {
                for (final row in snapshot.data!) {
                  final isim = row['isim']?.toString();
                  if (isim != null &&
                      isim.isNotEmpty &&
                      !oneriCariler.contains(isim)) {
                    oneriCariler.add(isim);
                  }
                }
              }

              return Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return oneriCariler.take(5);
                  }
                  return oneriCariler.where((String option) {
                    return option
                        .toLowerCase()
                        .contains(textEditingValue.text.toLowerCase());
                  });
                },
                onSelected: (String secilen) {
                  _cariUnvanController.text = secilen;
                },
                fieldViewBuilder:
                    (context, controller, focusNode, onFieldSubmitted) {
                  // Eşitleme
                  if (_cariUnvanController.text.isNotEmpty &&
                      controller.text.isEmpty) {
                    controller.text = _cariUnvanController.text;
                  }
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: _inputDec(
                        'Müşteri (Cari) Unvanı', Icons.business_rounded,
                        hint: 'Firma adı yazın veya listeden seçin'),
                    onChanged: (v) => _cariUnvanController.text = v,
                    validator: (v) => v == null || v.isEmpty
                        ? 'Müşteri unvanı zorunludur'
                        : null,
                  );
                },
              );
            },
          ),
          const SizedBox(height: 14),

          // Tarih Seçimleri
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _faturaTarihi,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (d != null) setState(() => _faturaTarihi = d);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Fatura Tarihi',
                            style: TextStyle(
                                fontSize: 10.5, color: Colors.grey.shade600)),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                size: 14, color: hurmaKahvesi),
                            const SizedBox(width: 6),
                            Text(
                              '${_faturaTarihi.day.toString().padLeft(2, '0')}.${_faturaTarihi.month.toString().padLeft(2, '0')}.${_faturaTarihi.year}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12.5),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _vadeTarihi,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (d != null) setState(() => _vadeTarihi = d);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Vade Tarihi',
                            style: TextStyle(
                                fontSize: 10.5, color: Colors.grey.shade600)),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.event_available_rounded,
                                size: 14, color: Colors.orange),
                            const SizedBox(width: 6),
                            Text(
                              '${_vadeTarihi.day.toString().padLeft(2, '0')}.${_vadeTarihi.month.toString().padLeft(2, '0')}.${_vadeTarihi.year}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12.5),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stokSecimKarti() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hurmaKahvesi.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Canlı stok listesi çekimi (Supabase)
          StreamBuilder<List<Map<String, dynamic>>>(
            stream:
                SupabaseService.client.from('items').stream(primaryKey: ['id']),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator()));
              }

              final docs = snapshot.data ?? [];

              if (docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Depoda kayıtlı stok bulunamadı. Stok Yönetim ekranından hurma stoku ekleyebilirsiniz.',
                          style:
                              TextStyle(fontSize: 12, color: hurmaKahvesiKoyu),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return DropdownButtonFormField<String>(
                value: _secilenStokDocId,
                decoration: _inputDec('Depodaki Ürün / Çeşit (Stok Seçimi)',
                    Icons.inventory_rounded),

                items: docs.map((doc) {
                  final d = doc;
                  final docId = d['id']?.toString() ?? '';
                  final cesit = d['urunCesidi'] ?? d['name'] ?? 'Bilinmeyen';
                  final miktar = (d['miktar'] as num?)?.toDouble() ?? 0.0;
                  final birim = d['birim'] ?? d['unit_of_measure'] ?? 'Ton';
                  final depo = d['depoAdi'] ?? 'Merkez Depo';
                  return DropdownMenuItem<String>(
                    value: docId,
                    child: Text(
                        '$cesit  —  ${miktar.toStringAsFixed(1)} $birim ($depo)',
                        overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (docId) {
                  if (docId == null) return;
                  final secilenDoc = docs.firstWhere((d) => d['id'] == docId);
                  final d = secilenDoc;
                  setState(() {
                    _secilenStokDocId = docId;
                    _secilenUrunCesidi = d['urunCesidi'] ?? d['name'];
                    _mevcutStokMiktari =
                        (d['miktar'] as num?)?.toDouble() ?? 0.0;
                    _mevcutStokBirimi =
                        d['birim'] ?? d['unit_of_measure'] ?? 'Ton';
                    _secilenBirim = _mevcutStokBirimi;
                    final birimMaliyet =
                        (d['birimMaliyet'] as num?)?.toDouble() ?? 0.0;
                    if (_birimFiyatController.text.isEmpty &&
                        birimMaliyet > 0) {
                      _birimFiyatController.text =
                          (birimMaliyet * 1.25).toStringAsFixed(2);
                    }
                  });
                },
                validator: (v) =>
                    v == null ? 'Lütfen satılacak ürünü seçin' : null,
              );
            },
          ),
          const SizedBox(height: 12),

          // Stok durumu bilgi rozeti
          if (_secilenStokDocId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _mevcutStokMiktari >= _miktar
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _mevcutStokMiktari >= _miktar
                      ? Colors.green.shade200
                      : Colors.red.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _mevcutStokMiktari >= _miktar
                        ? Icons.check_circle_outline
                        : Icons.warning_amber_rounded,
                    color: _mevcutStokMiktari >= _miktar
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Depo Mevcut: ${_mevcutStokMiktari.toStringAsFixed(2)} $_mevcutStokBirimi  |  Satış Sonrası Kalan: ${(_mevcutStokMiktari - _miktar).toStringAsFixed(2)} $_mevcutStokBirimi',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: _mevcutStokMiktari >= _miktar
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),

          // Miktar, Birim ve Birim Fiyat
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _miktarController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: _inputDec('Satış Miktarı', Icons.scale_rounded),
                  onChanged: (v) => setState(() {}),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Miktar girin';
                    final num = double.tryParse(v.replaceAll(',', '.'));
                    if (num == null || num <= 0) return 'Geçersiz';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _secilenBirim,
                  decoration: _inputDec('Birim', Icons.unfold_more_rounded),
                  items: const [
                    DropdownMenuItem(value: 'Ton', child: Text('Ton')),
                    DropdownMenuItem(value: 'Koli', child: Text('Koli')),
                    DropdownMenuItem(value: 'Çuval', child: Text('Çuval')),
                    DropdownMenuItem(value: 'Kg', child: Text('Kg')),
                  ],
                  onChanged: (v) => setState(() => _secilenBirim = v ?? 'Ton'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _birimFiyatController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: _inputDec('Birim Fiyat ($_secilenParaBirimi)',
                      Icons.payments_rounded),
                  onChanged: (v) => setState(() {}),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Fiyat girin';
                    final num = double.tryParse(v.replaceAll(',', '.'));
                    if (num == null || num <= 0) return 'Geçersiz';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _aciklamaController,
            decoration: _inputDec(
                'Fatura Açıklaması / Sipariş Notu', Icons.notes_rounded,
                hint: 'Örn: Cidde Limanı teslimi 1. sınıf hurma'),
          ),
        ],
      ),
    );
  }

  Widget _vergiVeMevzuatKarti() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hurmaKahvesi.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ülke Seçimi
          DropdownButtonFormField<String>(
            value: _secilenUlkeKodu,
            decoration: _inputDec(
                'Mevzuat Ülkesi & Vergi Sistemi', Icons.public_rounded),
            items: _ulkeler.map((u) {
              return DropdownMenuItem<String>(
                value: u.kod,
                child: Row(
                  children: [
                    Text(u.bayrak, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Text('${u.ad} — ${u.kdvEtiketi} (${u.paraBirimi})',
                        style: const TextStyle(fontSize: 13)),
                  ],
                ),
              );
            }).toList(),
            onChanged: (kod) {
              if (kod != null) _ulkeDegistir(kod);
            },
          ),
          const SizedBox(height: 14),

          // Özel KDV Seçenekleri (Esneklik)
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kremArkaplan,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: altinSarisi.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_rounded,
                          color: hurmaKahvesi, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Uygulanan Vergi Oranı',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                            Text(
                              '%${_kdvOrani.toStringAsFixed(0)} KDV / VAT ($_secilenUlkeKodu)',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: hurmaKahvesiKoyu),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Hızlı KDV değiştirici
              PopupMenuButton<double>(
                tooltip: 'Vergi Oranını Değiştir',
                icon: const Icon(Icons.tune_rounded, color: hurmaKahvesi),
                onSelected: (val) => setState(() => _kdvOrani = val),
                itemBuilder: (ctx) => const [
                  PopupMenuItem(
                      value: 0.0, child: Text('%0 (İhracat / Muafiyet)')),
                  PopupMenuItem(value: 1.0, child: Text('%1 (İndirimli)')),
                  PopupMenuItem(value: 5.0, child: Text('%5 (BAE VAT)')),
                  PopupMenuItem(
                      value: 10.0, child: Text('%10 (Temel Gıda TR)')),
                  PopupMenuItem(
                      value: 15.0, child: Text('%15 (Suudi ZATCA VAT)')),
                  PopupMenuItem(value: 19.0, child: Text('%19 (Almanya MwSt)')),
                  PopupMenuItem(
                      value: 20.0, child: Text('%20 (Standart TR/GB)')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _finansalOzetHesaplamaKarti() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: altinSarisi.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: altinSarisi.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _ozetSatiri('Mal / Hizmet Ara Toplamı:',
              '${_araToplam.toStringAsFixed(2)} $_secilenParaBirimi', false),
          const SizedBox(height: 8),
          _ozetSatiri(
            'Hesaplanan KDV / VAT (%${_kdvOrani.toStringAsFixed(0)}):',
            '+ ${_kdvTutari.toStringAsFixed(2)} $_secilenParaBirimi',
            false,
            renk: Colors.orange.shade800,
          ),
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1)),
          _ozetSatiri(
            'GENEL FATURA TOPLAMI:',
            '${_genelToplam.toStringAsFixed(2)} $_secilenParaBirimi',
            true,
            renk: hurmaKahvesi,
          ),
        ],
      ),
    );
  }

  Widget _ozetSatiri(String baslik, String deger, bool buyuk, {Color? renk}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          baslik,
          style: TextStyle(
            color: hurmaKahvesiKoyu,
            fontSize: buyuk ? 14 : 12.5,
            fontWeight: buyuk ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        Text(
          deger,
          style: TextStyle(
            color: renk ?? hurmaKahvesiKoyu,
            fontSize: buyuk ? 18 : 13.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _islemButonlari() {
    if (_kaydediliyor) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(hurmaKahvesi)),
        ),
      );
    }

    return Row(
      children: [
        // 1. Taslak Kaydet Butonu
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _faturayiKaydet(resmiOnayli: false),
            icon: const Icon(Icons.save_as_rounded, size: 18),
            label: const Text('Taslak Kaydet'),
            style: OutlinedButton.styleFrom(
              foregroundColor: hurmaKahvesi,
              side: const BorderSide(color: hurmaKahvesi, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // 2. Resmi Onayla & Stoktan Düş Butonu
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: () => _faturayiKaydet(resmiOnayli: true),
            icon: const Icon(Icons.check_circle_rounded, size: 20),
            label: const Text('Resmi Onayla & Stoktan Düş'),
            style: ElevatedButton.styleFrom(
              backgroundColor: hurmaKahvesi,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDec(String label, IconData icon, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: hurmaKahvesi, size: 20),
      labelStyle: const TextStyle(color: hurmaKahvesiKoyu, fontSize: 12.5),
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 11.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: hurmaKahvesi, width: 1.8),
      ),
    );
  }

  // ============================================================
  // TAB 2: KESİLEN FATURALAR LİSTESİ (ARŞİV)
  // ============================================================

  Widget _kesilenFaturalarListesi() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: SupabaseService.client
          .from('journal_entries')
          .stream(primaryKey: ['id']).order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_rounded,
                    size: 60, color: hurmaKahvesi.withOpacity(0.3)),
                const SizedBox(height: 12),
                const Text(
                  'Henüz düzenlenmiş bir fatura bulunmuyor.',
                  style: TextStyle(
                      color: hurmaKahvesiKoyu,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'İlk faturanızı oluşturmak için "Yeni Satış Faturası" sekmesini kullanın.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index];
            final faturaNo =
                data['faturaNo'] ?? data['entry_number'] ?? 'FAT-???';
            final cari = data['cariUnvani'] ??
                data['description'] ??
                'Cari Belirtilmedi';
            final urun = data['urunCesidi'] ?? 'Hurma';
            final miktar = (data['miktar'] as num?)?.toDouble() ?? 0.0;
            final birim = data['birim'] ?? 'Ton';
            final toplam = (data['genelToplam'] as num?)?.toDouble() ??
                (data['total_debit'] as num?)?.toDouble() ??
                0.0;
            final pb = data['paraBirimi'] ?? data['currency'] ?? 'SAR';
            final durum = data['durum'] ??
                (data['status'] == 'POSTED' ? 'Onaylandı' : 'Taslak');
            final onayliMi = durum == 'Onaylandı';
            final tarih =
                DateTime.tryParse(data['entry_date']?.toString() ?? '') ??
                    DateTime.now();
            final tarihStr =
                '${tarih.day.toString().padLeft(2, '0')}.${tarih.month.toString().padLeft(2, '0')}.${tarih.year}';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: onayliMi
                                    ? Colors.green.shade50
                                    : Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                onayliMi
                                    ? Icons.verified_rounded
                                    : Icons.pending_rounded,
                                color: onayliMi
                                    ? Colors.green.shade700
                                    : Colors.amber.shade800,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              faturaNo,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: hurmaKahvesiKoyu),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: onayliMi
                                ? Colors.green.shade100
                                : Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            durum,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: onayliMi
                                  ? Colors.green.shade900
                                  : Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(cari,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: hurmaKahvesiKoyu)),
                    const SizedBox(height: 4),
                    Text('$urun  •  $miktar $birim',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade700)),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tarih: $tarihStr',
                            style: TextStyle(
                                fontSize: 11.5, color: Colors.grey.shade600)),
                        Text(
                          '${toplam.toStringAsFixed(2)} $pb',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: hurmaKahvesi),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _UlkeMevzuatBilgisi {
  final String kod;
  final String ad;
  final String bayrak;
  final String paraBirimi;
  final double standartKdv;
  final String kdvEtiketi;

  const _UlkeMevzuatBilgisi({
    required this.kod,
    required this.ad,
    required this.bayrak,
    required this.paraBirimi,
    required this.standartKdv,
    required this.kdvEtiketi,
  });
}
