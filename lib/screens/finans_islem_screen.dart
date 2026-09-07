// ============================================================
// MUHASEBE VE FİNANS MODÜLÜ  (Madde 8 — Finansal İşlemler)
// ============================================================
// NAKHL & NAHL Kurumsal Renk Paleti:
//   - Hurma Kahvesi: #5C4033
//   - Krem: #FBF9F1
//
// Supabase PostgreSQL: 'journal_entries' ve 'journal_lines' tabloları üzerinden
// güvenli çift yönlü kayıt (Tahsilat, Ödeme, Kâr Payı Çekişi, Masraf).
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/supabase_service.dart';
import '../core/tenant/tenant_context.dart';
import '../services/mobil_entegrasyon_servisi.dart';

class FinansIslemScreen extends StatefulWidget {
  const FinansIslemScreen({super.key});

  @override
  State<FinansIslemScreen> createState() => _FinansIslemScreenState();
}

class _FinansIslemScreenState extends State<FinansIslemScreen>
    with SingleTickerProviderStateMixin {
  // Kurumsal Renk Kodları
  static const Color hurmaKahvesi = Color(0xFF5C4033);
  static const Color hurmaKahvesiKoyu = Color(0xFF3E2723);
  static const Color hurmaKahvesiAcik = Color(0xFF8D6E63);
  static const Color kremArkaplan = Color(0xFFFBF9F1);
  static const Color kremKoyu = Color(0xFFF0EAE1);
  static const Color altinSarisi = Color(0xFFC89033);

  // Form Anahtarı ve Kontrolcüler
  final _formKey = GlobalKey<FormState>();
  final _cariUnvanController = TextEditingController();
  final _tutarController = TextEditingController();
  final _belgeNoController = TextEditingController();
  final _aciklamaController = TextEditingController();

  // Seçili Değerler
  String _secilenIslemTuru =
      'Tahsilat'; // Tahsilat, Ödeme, Kâr Payı Çekişi, Masraf
  String _secilenParaBirimi = 'SAR'; // SAR, TRY, USD, EUR
  String _secilenOdemeYontemi =
      'Banka Havalesi'; // Banka Havalesi, Nakit Kasa, Çek / Senet, Kredi Kartı
  DateTime _islemTarihi = DateTime.now();

  bool _kaydediliyor = false;
  late TabController _tabController;

  // Desteklenen İşlem Türleri
  final List<Map<String, dynamic>> _islemTurleri = [
    {
      'id': 'Tahsilat',
      'label': 'Tahsilat',
      'aciklama': 'Cari hesaptan / Müşteriden nakit veya banka girişi',
      'icon': Icons.arrow_downward_rounded,
      'color': const Color(0xFF2E7D32), // Yeşil
      'bg': const Color(0xFFE8F5E9),
    },
    {
      'id': 'Ödeme',
      'label': 'Ödeme',
      'aciklama': 'Tedarikçiye veya cariye yapılan nakit / banka çıkışı',
      'icon': Icons.arrow_upward_rounded,
      'color': const Color(0xFFC62828), // Kırmızı
      'bg': const Color(0xFFFFEBEE),
    },
    {
      'id': 'Kâr Payı Çekişi',
      'label': 'Kâr Payı Çekişi',
      'aciklama': 'Şirket ortaklarına kâr payı dağıtımı / çekişi',
      'icon': Icons.account_balance_wallet_rounded,
      'color': const Color(0xFF6A1B9A), // Mor
      'bg': const Color(0xFFF3E5F5),
    },
    {
      'id': 'Masraf',
      'label': 'Masraf / Gider',
      'aciklama': 'Genel yönetim, gümrük, navlun, depo ve ofis masrafları',
      'icon': Icons.receipt_long_rounded,
      'color': const Color(0xFFE65100), // Turuncu
      'bg': const Color(0xFFFFF3E0),
    },
  ];

  // Desteklenen Para Birimleri
  final List<Map<String, String>> _paraBirimleri = [
    {'kod': 'SAR', 'ad': 'Suudi Arabistan Riyali', 'sembol': '﷼'},
    {'kod': 'TRY', 'ad': 'Türk Lirası', 'sembol': '₺'},
    {'kod': 'USD', 'ad': 'Amerikan Doları', 'sembol': '\$'},
    {'kod': 'EUR', 'ad': 'Euro', 'sembol': '€'},
  ];

  // Ödeme Yöntemleri
  final List<String> _odemeYontemleri = [
    'Banka Havalesi',
    'Nakit Kasa',
    'Kredi Kartı / POS',
    'Çek / Senet',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _cariUnvanController.dispose();
    _tutarController.dispose();
    _belgeNoController.dispose();
    _aciklamaController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ============================================================
  // FİREBASE FİRESTORE KAYIT FONKSİYONU
  // ============================================================
  Future<void> _finansalHareketiKaydet() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final double? tutar =
        double.tryParse(_tutarController.text.replaceAll(',', '.'));
    if (tutar == null || tutar <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen geçerli ve sıfırdan büyük bir tutar giriniz.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _kaydediliyor = true);

    try {
      final hareketVerisi = {
        'tenant_id': TenantContext.instance.activeTenantId ??
            '00000000-0000-0000-0000-000000000001',
        'company_id': TenantContext.instance.activeCompanyId,
        'entry_number': _belgeNoController.text.trim().isNotEmpty
            ? _belgeNoController.text.trim()
            : 'JRN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        'entry_date': _islemTarihi.toIso8601String().split('T').first,
        'entry_type': _secilenIslemTuru,
        'description':
            '${_cariUnvanController.text.trim()} - ${_aciklamaController.text.trim()}',
        'currency': _secilenParaBirimi,
        'total_debit': tutar,
        'total_credit': tutar,
        'status': 'POSTED',
        'cariUnvani': _cariUnvanController.text.trim(),
        'islemTuru': _secilenIslemTuru,
        'tutar': tutar,
        'paraBirimi': _secilenParaBirimi,
        'odemeYontemi': _secilenOdemeYontemi,
        'belgeNo': _belgeNoController.text.trim(),
        'aciklama': _aciklamaController.text.trim(),
        'kayitKaynagi': 'NAKHL&NAHL Mobil/ERP',
        'durum': 'Onaylandı',
      };

      await SupabaseService.client
          .from('journal_entries')
          .insert(hareketVerisi);

      // Ortakların telefonuna anlık bildirim (FCM) ilet
      await MobilEntegrasyonServisi.instance.finansBildirimiGonder(
        cariUnvan: _cariUnvanController.text.trim(),
        islemTuru: _secilenIslemTuru,
        tutar: tutar,
        paraBirimi: _secilenParaBirimi,
        aciklama: _aciklamaController.text.trim(),
      );

      if (!mounted) return;

      // Başarılı Bilgilendirme
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$_secilenIslemTuru işlemi ($tutar $_secilenParaBirimi) başarıyla kaydedildi.',
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

      // Formu Sıfırla
      _formuTemizle();

      // İsteğe bağlı olarak liste sekmesine geçir
      _tabController.animateTo(1);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kayıt sırasında hata oluştu: $e'),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _kaydediliyor = false);
    }
  }

  void _formuTemizle() {
    _cariUnvanController.clear();
    _tutarController.clear();
    _belgeNoController.clear();
    _aciklamaController.clear();
    setState(() {
      _secilenIslemTuru = 'Tahsilat';
      _secilenParaBirimi = 'SAR';
      _secilenOdemeYontemi = 'Banka Havalesi';
      _islemTarihi = DateTime.now();
    });
  }

  Future<void> _tarihSec() async {
    final DateTime? secilen = await showDatePicker(
      context: context,
      initialDate: _islemTarihi,
      firstDate: DateTime(2020),
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
      setState(() => _islemTarihi = secilen);
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
              'Madde 8: Muhasebe & Finans',
              style: TextStyle(
                color: kremArkaplan,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'NAKHL & NAHL — Kasa, Banka ve Cari Hareketleri',
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
            Tab(icon: Icon(Icons.add_circle_outline), text: 'Yeni İşlem Ekle'),
            Tab(icon: Icon(Icons.history_rounded), text: 'Hareket Geçmişi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildYeniIslemFormu(),
          _buildHareketGecmisi(),
        ],
      ),
    );
  }

  // ============================================================
  // 1. SEKME: YENİ FİNANSAL İŞLEM GİRİŞ FORMU
  // ============================================================
  Widget _buildYeniIslemFormu() {
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
                // Bilgi Kartı / Başlık Alanı
                _buildKurumsalBilgiBandi(),
                const SizedBox(height: 20),

                // 1. İşlem Türü Seçimi
                _buildIslemTuruSecici(),
                const SizedBox(height: 20),

                // Form Kartı (Cari, Tutar, Para Birimi, Yöntem)
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
                      // Cari / Firma Unvanı
                      const Text(
                        'Cari / Firma Unvanı *',
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
                              'Örn: Medine Hurma Pazarı A.Ş. veya Hidayetullah Ltd.',
                          icon: Icons.business_rounded,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Lütfen cari veya firma unvanı giriniz.'
                            : null,
                      ),
                      const SizedBox(height: 20),

                      // Tutar ve Para Birimi (Yan yana)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tutar
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'İşlem Tutarı *',
                                  style: TextStyle(
                                    color: hurmaKahvesiKoyu,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _tutarController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d+[\.,]?\d{0,2}')),
                                  ],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: hurmaKahvesiKoyu,
                                  ),
                                  decoration: _inputDecoration(
                                    hint: '0.00',
                                    icon: Icons.payments_rounded,
                                    prefixText:
                                        _getSecilenParaBirimiSembolu() + ' ',
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Tutar zorunludur.';
                                    }
                                    final n =
                                        double.tryParse(v.replaceAll(',', '.'));
                                    if (n == null || n <= 0) {
                                      return 'Pozitif bir tutar girin.';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Para Birimi Seçimi
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Para Birimi *',
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
                                        fontSize: 15,
                                      ),
                                      items: _paraBirimleri.map((pb) {
                                        return DropdownMenuItem<String>(
                                          value: pb['kod'],
                                          child: Text(
                                              '${pb['kod']} (${pb['sembol']})'),
                                        );
                                      }).toList(),
                                      onChanged: (v) {
                                        if (v != null) {
                                          setState(
                                              () => _secilenParaBirimi = v);
                                        }
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

                      // Hızlı Para Birimi Butonları
                      Wrap(
                        spacing: 8,
                        children: _paraBirimleri.map((pb) {
                          final secili = _secilenParaBirimi == pb['kod'];
                          return ChoiceChip(
                            label: Text('${pb['kod']} - ${pb['ad']}'),
                            selected: secili,
                            selectedColor: hurmaKahvesi,
                            labelStyle: TextStyle(
                              color: secili ? Colors.white : hurmaKahvesiKoyu,
                              fontWeight:
                                  secili ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                            backgroundColor: kremArkaplan,
                            onSelected: (val) {
                              if (val)
                                setState(() => _secilenParaBirimi = pb['kod']!);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      const Divider(color: kremKoyu),
                      const SizedBox(height: 16),

                      // İşlem Tarihi & Ödeme Yöntemi
                      Row(
                        children: [
                          // İşlem Tarihi
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'İşlem Tarihi',
                                  style: TextStyle(
                                    color: hurmaKahvesiKoyu,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: _tarihSec,
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    height: 50,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14),
                                    decoration: BoxDecoration(
                                      color: kremArkaplan,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: hurmaKahvesiAcik
                                              .withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today_rounded,
                                            size: 18, color: hurmaKahvesi),
                                        const SizedBox(width: 10),
                                        Text(
                                          '${_islemTarihi.day.toString().padLeft(2, '0')}.${_islemTarihi.month.toString().padLeft(2, '0')}.${_islemTarihi.year}',
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

                          // Ödeme Yöntemi / Kasa
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Hesap / Ödeme Türü',
                                  style: TextStyle(
                                    color: hurmaKahvesiKoyu,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 50,
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
                                      value: _secilenOdemeYontemi,
                                      isExpanded: true,
                                      icon: const Icon(Icons.arrow_drop_down,
                                          color: hurmaKahvesi),
                                      style: const TextStyle(
                                        color: hurmaKahvesiKoyu,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                      items: _odemeYontemleri.map((y) {
                                        return DropdownMenuItem(
                                            value: y, child: Text(y));
                                      }).toList(),
                                      onChanged: (v) {
                                        if (v != null)
                                          setState(
                                              () => _secilenOdemeYontemi = v);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Belge / Makbuz No
                      const Text(
                        'Belge / Fatura / Makbuz No (Opsiyonel)',
                        style: TextStyle(
                          color: hurmaKahvesiKoyu,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _belgeNoController,
                        decoration: _inputDecoration(
                          hint: 'Örn: MAK-2026/089 veya FTR-4821',
                          icon: Icons.tag_rounded,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Açıklama
                      const Text(
                        'Açıklama / İşlem Notu (Opsiyonel)',
                        style: TextStyle(
                          color: hurmaKahvesiKoyu,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _aciklamaController,
                        maxLines: 2,
                        decoration: _inputDecoration(
                          hint:
                              'Örn: Medjoul 1. Kalite sevkiyatı peşin ödemesi / Kâr payı aktarımı',
                          icon: Icons.edit_note_rounded,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Kaydet Butonu
                ElevatedButton(
                  onPressed: _kaydediliyor ? null : _finansalHareketiKaydet,
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
                            Text('ERP Sistemine Kaydediliyor...',
                                style: TextStyle(fontSize: 16)),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.save_rounded,
                                size: 22, color: altinSarisi),
                            const SizedBox(width: 10),
                            Text(
                              '$_secilenIslemTuru İşlemini Güvenle Kaydet',
                              style: const TextStyle(
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
  // İŞLEM TÜRÜ SEÇİCİ BİLEŞENİ
  // ============================================================
  Widget _buildIslemTuruSecici() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'İşlem Türü *',
          style: TextStyle(
            color: hurmaKahvesiKoyu,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _islemTurleri.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isMobile ? 2 : 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: isMobile ? 1.6 : 1.5,
              ),
              itemBuilder: (context, index) {
                final tur = _islemTurleri[index];
                final secili = _secilenIslemTuru == tur['id'];
                final Color anaRenk = tur['color'] as Color;

                return InkWell(
                  onTap: () =>
                      setState(() => _secilenIslemTuru = tur['id'] as String),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: secili ? anaRenk.withOpacity(0.12) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: secili ? anaRenk : kremKoyu,
                        width: secili ? 2 : 1,
                      ),
                      boxShadow: [
                        if (secili)
                          BoxShadow(
                            color: anaRenk.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: anaRenk.withOpacity(0.15),
                              child: Icon(tur['icon'] as IconData,
                                  size: 18, color: anaRenk),
                            ),
                            const Spacer(),
                            if (secili)
                              Icon(Icons.check_circle,
                                  size: 18, color: anaRenk),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          tur['label'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: secili ? anaRenk : hurmaKahvesiKoyu,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tur['id'] == 'Tahsilat'
                              ? '+ Kasa Girişi'
                              : '- Kasa Çıkışı',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: anaRenk,
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
  // KURUMSAL BİLGİ BANDI (HURMA & KREM)
  // ============================================================
  Widget _buildKurumsalBilgiBandi() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [hurmaKahvesi, hurmaKahvesiKoyu],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: hurmaKahvesi.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: altinSarisi.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.account_balance_wallet,
                color: altinSarisi, size: 26),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NAKHL & NAHL — Finansal Hareket Kaydı',
                  style: TextStyle(
                    color: kremArkaplan,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Kayıtlar doğrudan Supabase Core Database journal_entries tablosunda arşivlenir.',
                  style: TextStyle(color: Color(0xFFD7CCC8), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 2. SEKME: FİRESTORE HAREKET GEÇMİŞİ (GERÇEK ZAMANLI LİSTE)
  // ============================================================
  Widget _buildHareketGecmisi() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: SupabaseService.client
          .from('journal_entries')
          .stream(primaryKey: ['id']).order('created_at', ascending: false),
      builder: (context, snapshot) {
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
                    'Veriler çekilirken bir hata oluştu:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: hurmaKahvesiKoyu),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: hurmaKahvesi),
          );
        }

        final docs = snapshot.data ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_outlined,
                    size: 64, color: hurmaKahvesiAcik.withOpacity(0.5)),
                const SizedBox(height: 16),
                const Text(
                  'Henüz kayıtlı bir finansal hareket bulunmuyor.',
                  style: TextStyle(
                    color: hurmaKahvesiKoyu,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Yeni bir tahsilat, ödeme veya masraf eklemek için ilk sekmeyi kullanabilirsiniz.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _tabController.animateTo(0),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hurmaKahvesi,
                    foregroundColor: kremArkaplan,
                  ),
                  icon: const Icon(Icons.add, color: altinSarisi),
                  label: const Text('Yeni İşlem Ekle'),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final data = docs[index];
            final String islemTuru =
                data['islemTuru'] ?? data['entry_type'] ?? 'İşlem';
            final String cariUnvani =
                data['cariUnvani'] ?? data['description'] ?? '-';
            final num tutarNum = data['tutar'] ?? data['total_debit'] ?? 0;
            final double tutar = tutarNum.toDouble();
            final String paraBirimi =
                data['paraBirimi'] ?? data['currency'] ?? 'SAR';
            final String belgeNo =
                data['belgeNo'] ?? data['entry_number'] ?? '-';
            final String odemeYontemi = data['odemeYontemi'] ?? 'Kasa / Banka';
            final String aciklama =
                data['aciklama'] ?? data['description'] ?? '';
            final DateTime tarih =
                DateTime.tryParse(data['entry_date']?.toString() ?? '') ??
                    DateTime.now();

            final bool isGiris = islemTuru == 'Tahsilat';
            final Color turRengi = _getIslemRengi(islemTuru);
            final IconData turIcon = _getIslemIcon(islemTuru);

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kremKoyu),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: turRengi.withOpacity(0.12),
                  child: Icon(turIcon, color: turRengi, size: 24),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        cariUnvani,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: hurmaKahvesiKoyu,
                        ),
                      ),
                    ),
                    Text(
                      '${isGiris ? '+' : '-'} ${tutar.toStringAsFixed(2)} $paraBirimi',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: turRengi,
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: turRengi.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            islemTuru,
                            style: TextStyle(
                              color: turRengi,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          odemeYontemi,
                          style:
                              const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const Spacer(),
                        Text(
                          '${tarih.day.toString().padLeft(2, '0')}.${tarih.month.toString().padLeft(2, '0')}.${tarih.year}',
                          style:
                              const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                    if (belgeNo.isNotEmpty && belgeNo != '-') ...[
                      const SizedBox(height: 4),
                      Text(
                        'Belge No: $belgeNo',
                        style: const TextStyle(
                            fontSize: 11, color: hurmaKahvesiAcik),
                      ),
                    ],
                    if (aciklama.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        aciklama,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black87),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // YARDIMCI GÖRSEL FONKSİYONLAR
  // ============================================================
  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    String? prefixText,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: kremArkaplan,
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      prefixIcon: Icon(icon, color: hurmaKahvesi),
      prefixText: prefixText,
      prefixStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        color: hurmaKahvesiKoyu,
        fontSize: 16,
      ),
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

  String _getSecilenParaBirimiSembolu() {
    final pb = _paraBirimleri.firstWhere(
      (e) => e['kod'] == _secilenParaBirimi,
      orElse: () => {'sembol': ''},
    );
    return pb['sembol'] ?? '';
  }

  Color _getIslemRengi(String islemTuru) {
    switch (islemTuru) {
      case 'Tahsilat':
        return const Color(0xFF2E7D32);
      case 'Ödeme':
        return const Color(0xFFC62828);
      case 'Kâr Payı Çekişi':
        return const Color(0xFF6A1B9A);
      case 'Masraf':
        return const Color(0xFFE65100);
      default:
        return hurmaKahvesi;
    }
  }

  IconData _getIslemIcon(String islemTuru) {
    switch (islemTuru) {
      case 'Tahsilat':
        return Icons.arrow_downward_rounded;
      case 'Ödeme':
        return Icons.arrow_upward_rounded;
      case 'Kâr Payı Çekişi':
        return Icons.account_balance_wallet_rounded;
      case 'Masraf':
        return Icons.receipt_long_rounded;
      default:
        return Icons.monetization_on_rounded;
    }
  }
}
