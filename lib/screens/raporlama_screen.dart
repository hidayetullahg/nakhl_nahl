// ============================================================
// RAPORLAMA & DIŞA AKTARIM EKRANI
// ============================================================
// NAKHL & NAHL Kurumsal ERP — Madde 10: Küresel Veri Aktarım Merkezi
//
// Bu ekran, sistemdeki tüm verileri (Cari, Finans, Stok, Sevkiyat)
// 11 küresel veri aktarım formatında (JSON, CSV, XML, PDF, DOCX,
// XLSX, XLS, TXT, HTML, PNG, JPG) ve seçilen çoklu dillerde (TR, AR,
// UG, FA, ES, FR, PT, DE, EN vb.) dışa aktarma yeteneği sunar.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/raporlama_servisi.dart';
import '../core/i18n/app_dictionary.dart';

class RaporlamaScreen extends StatefulWidget {
  const RaporlamaScreen({super.key});

  @override
  State<RaporlamaScreen> createState() => _RaporlamaScreenState();
}

class _RaporlamaScreenState extends State<RaporlamaScreen>
    with SingleTickerProviderStateMixin {
  // ── Tema Renkleri ──
  static const Color _hurmaKahvesi = Color(0xFF5C4033);
  static const Color _kremArkaplan = Color(0xFFFBF9F1);
  static const Color _altinSarisi = Color(0xFFC89033);
  static const Color _koyuKahve = Color(0xFF3E2723);

  // ── Durum Değişkenleri ──
  RaporModulu _secilenModul = RaporModulu.tumModuller;
  RaporKategorisi _secilenKategori = RaporKategorisi.veriEntegrasyon;
  final List<String> _secilenDiller = [
    'TR'
  ]; // Varsayılan Türkçe, kullanıcı çoklu seçebilir

  bool _islemDevamEdiyor = false;
  String? _sonSonucMesaji;
  bool? _sonSonucBasarili;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // Format butonları tanımları (11 Küresel Format)
  static const Map<RaporFormati, _FormatArayuzBilgisi> _formatDetaylari = {
    // 1. Veri Entegrasyon Formatları
    RaporFormati.json: _FormatArayuzBilgisi(
      icon: Icons.code_rounded,
      renk: Color(0xFFEF6C00), // Turuncu / Amber
      etiket: 'API & ERP',
    ),
    RaporFormati.csv: _FormatArayuzBilgisi(
      icon: Icons.grid_view_rounded,
      renk: Color(0xFF00897B), // Teal
      etiket: 'Tablo / Excel',
    ),
    RaporFormati.xml: _FormatArayuzBilgisi(
      icon: Icons.integration_instructions_rounded,
      renk: Color(0xFF6A1B9A), // Mor
      etiket: 'UBL-TR e-Fatura',
    ),

    // 2. Metin ve Doküman Formatları
    RaporFormati.pdf: _FormatArayuzBilgisi(
      icon: Icons.picture_as_pdf_rounded,
      renk: Color(0xFFD32F2F), // Kırmızı
      etiket: 'Resmi Rapor',
    ),
    RaporFormati.docx: _FormatArayuzBilgisi(
      icon: Icons.description_rounded,
      renk: Color(0xFF1565C0), // Mavi
      etiket: 'Word Belgesi',
    ),
    RaporFormati.xlsx: _FormatArayuzBilgisi(
      icon: Icons.table_chart_rounded,
      renk: Color(0xFF2E7D32), // Yeşil
      etiket: 'Excel 2007+',
    ),
    RaporFormati.xls: _FormatArayuzBilgisi(
      icon: Icons.border_all_rounded,
      renk: Color(0xFF1B5E20), // Koyu Yeşil
      etiket: 'Klasik Excel',
    ),
    RaporFormati.txt: _FormatArayuzBilgisi(
      icon: Icons.text_snippet_rounded,
      renk: Color(0xFF455A64), // Gri/Mavi
      etiket: 'Düz Metin',
    ),
    RaporFormati.html: _FormatArayuzBilgisi(
      icon: Icons.html_rounded,
      renk: Color(0xFFE65100), // Turuncu
      etiket: 'Web Sayfası',
    ),

    // 3. Resim ve Görsel Formatları
    RaporFormati.png: _FormatArayuzBilgisi(
      icon: Icons.receipt_long_rounded,
      renk: Color(0xFF00838F), // Cyan
      etiket: 'Dekont & Fiş',
    ),
    RaporFormati.jpg: _FormatArayuzBilgisi(
      icon: Icons.image_rounded,
      renk: Color(0xFFAD1457), // Pembe/Bordo
      etiket: 'Görsel Arşiv',
    ),
  };

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  /// Seçilen formatta ve dillerde dışa aktarımı başlatır.
  Future<void> _disaAktarBaslat(RaporFormati format) async {
    if (_islemDevamEdiyor) return;

    setState(() {
      _islemDevamEdiyor = true;
      _sonSonucMesaji = null;
      _sonSonucBasarili = null;
    });

    final sonuc = await RaporlamaServisi.raporDisaAktar(
      format: format,
      modul: _secilenModul,
      secilenDiller: _secilenDiller,
    );

    if (!mounted) return;

    setState(() {
      _islemDevamEdiyor = false;
      _sonSonucMesaji = sonuc.mesaj;
      _sonSonucBasarili = sonuc.basarili;
    });

    _animController.forward(from: 0);

    // Sonuç dialog'u göster
    _sonucDialoguGoster(sonuc);
  }

  void _sonucDialoguGoster(RaporSonucu sonuc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kremArkaplan,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              sonuc.basarili ? Icons.check_circle_rounded : Icons.error_rounded,
              color:
                  sonuc.basarili ? Colors.green.shade700 : Colors.red.shade700,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                sonuc.basarili
                    ? 'Rapor Başarıyla Oluşturuldu'
                    : 'Rapor Oluşturulamadı',
                style: const TextStyle(
                  color: _koyuKahve,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (sonuc.basarili) ...[
                _dialogBilgiSatiri('📄 Dosya', sonuc.dosyaAdi),
                _dialogBilgiSatiri('📦 Format',
                    '${sonuc.formatAdi} (.${sonuc.format.uzanti})'),
                _dialogBilgiSatiri('🏷️ Kategori', sonuc.kategori.baslik),
                _dialogBilgiSatiri('📊 Modül', _secilenModul.goruntulenenAd),
                _dialogBilgiSatiri(
                  '🌐 Diller',
                  sonuc.diller
                      .map((d) => desteklenenDiller[d.toUpperCase()] ?? d)
                      .join(' / '),
                ),
                _dialogBilgiSatiri('💾 Boyut', '${sonuc.byteBoyutu} Byte'),
                const SizedBox(height: 14),

                // İçerik Önizleme
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _koyuKahve.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _hurmaKahvesi.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'İçerik Önizleme',
                            style: TextStyle(
                              color: _hurmaKahvesi,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              if (sonuc.tamMetinIcerik != null) {
                                Clipboard.setData(
                                    ClipboardData(text: sonuc.tamMetinIcerik!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        '📋 Rapor içeriği panoya kopyalandı!'),
                                    backgroundColor: _hurmaKahvesi,
                                    behavior: SnackBarBehavior.floating,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Row(
                                children: [
                                  Icon(Icons.copy_rounded,
                                      size: 14, color: _hurmaKahvesi),
                                  SizedBox(width: 4),
                                  Text('Kopyala',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: _hurmaKahvesi,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        sonuc.icerikOzeti.length > 500
                            ? '${sonuc.icerikOzeti.substring(0, 500)}…'
                            : sonuc.icerikOzeti,
                        style: TextStyle(
                          color: _koyuKahve.withOpacity(0.85),
                          fontSize: 11,
                          fontFamily: 'monospace',
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Text(
                  sonuc.mesaj,
                  style: TextStyle(color: Colors.red.shade800, fontSize: 14),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: _hurmaKahvesi,
            ),
            child: const Text('Kapat'),
          ),
          if (sonuc.basarili)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: _hurmaKahvesi,
                    content: Text(
                        '📤 ${sonuc.dosyaAdi} paylaşıma ve dışa aktarıma hazır.'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              icon: const Icon(Icons.download_done_rounded, size: 18),
              label: const Text('Dışa Aktar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _hurmaKahvesi,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _dialogBilgiSatiri(String etiket, String deger) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              etiket,
              style: TextStyle(
                color: _hurmaKahvesi.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              deger,
              style: const TextStyle(
                color: _koyuKahve,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kremArkaplan,
      appBar: AppBar(
        title: const Text(
          'Küresel Veri & Rapor Merkezi',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 19,
          ),
        ),
        backgroundColor: _hurmaKahvesi,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'Format Standartları',
            onPressed: () => _bilgiDialoguGoster(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── KURUMSAL BAŞLIK KARTI ──
            _kurumsalBaslikKarti(),
            const SizedBox(height: 20),

            // ── MODÜL SEÇİMİ ──
            _bolumBasligi('📊 Rapor Kapsamı',
                'Dışa aktarılacak ERP modülünü belirleyin:'),
            const SizedBox(height: 10),
            _modulSecimKartlari(),
            const SizedBox(height: 22),

            // ── ÇOKLU DİL SEÇİMİ ──
            _bolumBasligi(
              '🌐 Çıktı & Başlık Dilleri',
              'Rapor başlıkları ve sütunlarının çevrileceği dilleri seçin (Eşzamanlı Çoklu Dil):',
            ),
            const SizedBox(height: 10),
            _dilSecimAlani(),
            const SizedBox(height: 24),

            // ── KATEGORİ SEKMELERİ ──
            _bolumBasligi('🗂️ Aktarım Format Kategorisi',
                'İhtiyacınıza uygun aktarım kategorisini seçin:'),
            const SizedBox(height: 10),
            _kategoriSecimBar(),
            const SizedBox(height: 16),

            // ── FORMAT SEÇİMİ & BUTONLARI ──
            _formatKartlariListesi(),
            const SizedBox(height: 24),

            // ── DURUM BİLDİRİMİ ──
            if (_islemDevamEdiyor) _yukleniyorGostergesi(),
            if (_sonSonucMesaji != null && !_islemDevamEdiyor)
              _sonucBildirimi(),
          ],
        ),
      ),
    );
  }

  Widget _kurumsalBaslikKarti() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_hurmaKahvesi, _koyuKahve],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _hurmaKahvesi.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.hub_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NAKHL & NAHL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Küresel Çok Dilli Raporlama Motoru',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.translate_rounded, color: Colors.amber, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Rapor çıktıları seçilen dillere (Türkçe, Arapça, Uygurca, Farsça, İspanyolca, Fransızca, Portekizce, Almanca, İngilizce) göre anlık çevrilir.',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 11.5, height: 1.35),
                  ),
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
            color: _koyuKahve,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          aciklama,
          style: TextStyle(
            color: _hurmaKahvesi.withOpacity(0.65),
            fontSize: 12.5,
          ),
        ),
      ],
    );
  }

  Widget _modulSecimKartlari() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: RaporModulu.values.map((modul) {
        final secili = _secilenModul == modul;
        return GestureDetector(
          onTap: () => setState(() => _secilenModul = modul),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: secili ? _hurmaKahvesi : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: secili ? _hurmaKahvesi : _hurmaKahvesi.withOpacity(0.2),
                width: secili ? 2 : 1,
              ),
              boxShadow: secili
                  ? [
                      BoxShadow(
                        color: _hurmaKahvesi.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _modulIkonu(modul),
                  color: secili ? Colors.white : _hurmaKahvesi,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  _modulKisaAd(modul),
                  style: TextStyle(
                    color: secili ? Colors.white : _koyuKahve,
                    fontWeight: secili ? FontWeight.bold : FontWeight.w500,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Çoklu dil seçim alanı
  Widget _dilSecimAlani() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _hurmaKahvesi.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: desteklenenDiller.entries.map((entry) {
              final secili = _secilenDiller.contains(entry.key);
              return FilterChip(
                label: Text(entry.value),
                selected: secili,
                selectedColor: _hurmaKahvesi,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: secili ? Colors.white : _koyuKahve,
                  fontSize: 12,
                  fontWeight: secili ? FontWeight.bold : FontWeight.w500,
                ),
                backgroundColor: _kremArkaplan,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: secili
                        ? _hurmaKahvesi
                        : _hurmaKahvesi.withOpacity(0.25),
                  ),
                ),
                onSelected: (bool selected) {
                  setState(() {
                    if (selected) {
                      if (!_secilenDiller.contains(entry.key)) {
                        _secilenDiller.add(entry.key);
                      }
                    } else {
                      if (_secilenDiller.length > 1) {
                        _secilenDiller.remove(entry.key);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                '⚠️ En az bir çıktı dili seçili olmalıdır.'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _koyuKahve.withOpacity(0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _altinSarisi.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.preview_rounded,
                    size: 16, color: _altinSarisi),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Başlık Örneği: ${metin('tutar', _secilenDiller)}  |  ${metin('cariUnvani', _secilenDiller)}',
                    style: const TextStyle(
                      color: _koyuKahve,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kategoriSecimBar() {
    return Row(
      children: RaporKategorisi.values.map((kat) {
        final secili = _secilenKategori == kat;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: GestureDetector(
              onTap: () => setState(() => _secilenKategori = kat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                decoration: BoxDecoration(
                  color: secili ? _hurmaKahvesi : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        secili ? _hurmaKahvesi : _hurmaKahvesi.withOpacity(0.2),
                    width: secili ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _kategoriIkonu(kat),
                      color: secili ? Colors.white : _hurmaKahvesi,
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _kategoriKisaBaslik(kat),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: secili ? Colors.white : _koyuKahve,
                        fontSize: 11,
                        fontWeight: secili ? FontWeight.bold : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _formatKartlariListesi() {
    final kategoriFormatlari = RaporFormati.values
        .where((f) => f.kategori == _secilenKategori)
        .toList();

    return Column(
      children: kategoriFormatlari.map((format) {
        final detay = _formatDetaylari[format]!;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _islemDevamEdiyor ? null : () => _disaAktarBaslat(format),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: detay.renk.withOpacity(0.25)),
                  boxShadow: [
                    BoxShadow(
                      color: detay.renk.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [detay.renk, detay.renk.withOpacity(0.75)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: detay.renk.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(detay.icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                format.goruntulenenAd,
                                style: const TextStyle(
                                  color: _koyuKahve,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: detay.renk.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '.${format.uzanti}',
                                  style: TextStyle(
                                    color: detay.renk,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            format.aciklama,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _hurmaKahvesi.withOpacity(0.7),
                              fontSize: 11.5,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _islemDevamEdiyor
                          ? null
                          : () => _disaAktarBaslat(format),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: detay.renk,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: const Text('Aktar',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _yukleniyorGostergesi() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _altinSarisi.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_hurmaKahvesi),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            "Veriler Supabase ERP'den çekiliyor…",
            style: TextStyle(
              color: _koyuKahve,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Çok dilli (${_secilenDiller.join(", ")}) kurumsal format çıktısı hazırlanıyor',
            style: TextStyle(
              color: _hurmaKahvesi.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sonucBildirimi() {
    final basarili = _sonSonucBasarili ?? false;
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: basarili ? Colors.green.shade50 : Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: basarili ? Colors.green.shade300 : Colors.red.shade300,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              basarili ? Icons.check_circle_rounded : Icons.error_rounded,
              color: basarili ? Colors.green.shade700 : Colors.red.shade700,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _sonSonucMesaji ?? '',
                style: TextStyle(
                  color: basarili ? Colors.green.shade900 : Colors.red.shade900,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _bilgiDialoguGoster() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kremArkaplan,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.schema_rounded, color: _hurmaKahvesi, size: 24),
            SizedBox(width: 10),
            Text(
              '11 Format & Çoklu Dil Standardı',
              style: TextStyle(
                  color: _koyuKahve, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              const Text(
                '🌐 Desteklenen Diller:',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _hurmaKahvesi,
                    fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text(
                desteklenenDiller.values.join(' • '),
                style: const TextStyle(fontSize: 12, color: _koyuKahve),
              ),
              const Divider(height: 20),
              ...RaporKategorisi.values.map((kat) {
                final katFormatlar =
                    RaporFormati.values.where((f) => f.kategori == kat);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kat.baslik,
                        style: const TextStyle(
                          color: _hurmaKahvesi,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...katFormatlar.map((f) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _hurmaKahvesi.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '.${f.uzanti}',
                                    style: const TextStyle(
                                      color: _hurmaKahvesi,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${f.goruntulenenAd}: ${f.aciklama}',
                                    style: const TextStyle(
                                        fontSize: 11.5,
                                        color: _koyuKahve,
                                        height: 1.3),
                                  ),
                                ),
                              ],
                            ),
                          )),
                      const Divider(height: 16),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: _hurmaKahvesi),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  IconData _modulIkonu(RaporModulu modul) {
    switch (modul) {
      case RaporModulu.tumModuller:
        return Icons.dashboard_rounded;
      case RaporModulu.finans:
        return Icons.account_balance_wallet_rounded;
      case RaporModulu.stok:
        return Icons.inventory_2_rounded;
      case RaporModulu.sevkiyat:
        return Icons.local_shipping_rounded;
    }
  }

  String _modulKisaAd(RaporModulu modul) {
    switch (modul) {
      case RaporModulu.tumModuller:
        return 'Tüm Modüller';
      case RaporModulu.finans:
        return 'Finans';
      case RaporModulu.stok:
        return 'Stok';
      case RaporModulu.sevkiyat:
        return 'Sevkiyat';
    }
  }

  IconData _kategoriIkonu(RaporKategorisi kat) {
    switch (kat) {
      case RaporKategorisi.veriEntegrasyon:
        return Icons.sync_alt_rounded;
      case RaporKategorisi.metinDokuman:
        return Icons.article_rounded;
      case RaporKategorisi.resimGorsel:
        return Icons.photo_library_rounded;
    }
  }

  String _kategoriKisaBaslik(RaporKategorisi kat) {
    switch (kat) {
      case RaporKategorisi.veriEntegrasyon:
        return 'Entegrasyon';
      case RaporKategorisi.metinDokuman:
        return 'Dokümanlar';
      case RaporKategorisi.resimGorsel:
        return 'Görsel Arşiv';
    }
  }
}

class _FormatArayuzBilgisi {
  final IconData icon;
  final Color renk;
  final String etiket;

  const _FormatArayuzBilgisi({
    required this.icon,
    required this.renk,
    required this.etiket,
  });
}
