// ==============================================================================
// NAKHL & NAHL — ÇAPRAZ SINIR MEVZUAT DEĞERLENDİRME EKRANI (CROSS BORDER ASSESSMENT)
// Master Directive: Multi-Jurisdiction Isolated Evaluation Simulator
// ==============================================================================

import 'package:flutter/material.dart';
import '../../models/legislation/product_legal_profile_model.dart';
import '../../models/legislation/cross_border_evaluation_model.dart';
import '../../services/legislation/cross_border_legal_engine_service.dart';

class CrossBorderAssessmentScreen extends StatefulWidget {
  const CrossBorderAssessmentScreen({super.key});

  @override
  State<CrossBorderAssessmentScreen> createState() => _CrossBorderAssessmentScreenState();
}

class _CrossBorderAssessmentScreenState extends State<CrossBorderAssessmentScreen> {
  final _engineService = CrossBorderLegalEngineService.instance;

  String _seciliCikisUlke = 'SA';
  String _seciliVarisUlke = 'DE';
  String _seciliUrun = 'Medjool Hurma (Kuru)';
  String _seciliHsKod = '080410';
  bool _isOrganik = false;
  bool _isHelal = true;
  double _miktarKg = 5000.0;

  CrossBorderEvaluationResult? _sonuc;

  static const Color hurmaKahvesi = Color(0xFF5C4033);
  static const Color hurmaKahvesiKoyu = Color(0xFF3E2723);
  static const Color altinSarisi = Color(0xFFC89033);
  static const Color zeytinYesili = Color(0xFF2E7D32);
  static const Color kremArkaplan = Color(0xFFFBF9F1);

  @override
  void initState() {
    super.initState();
    _hesapla();
  }

  void _hesapla() {
    final profile = ProductLegalProfileModel(
      productName: _seciliUrun,
      hsCode: _seciliHsKod,
      sourceCountry: _seciliCikisUlke,
      destinationCountry: _seciliVarisUlke,
      isOrganic: _isOrganik,
      isHalalCertified: _isHelal,
      quantityKg: _miktarKg,
      isFood: true,
      isAnimalOrigin: false,
      isPlantOrigin: true,
      isProcessed: true,
    );

    setState(() {
      _sonuc = _engineService.resolveApplicableLegalFramework(profile);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kremArkaplan,
      appBar: AppBar(
        title: const Text('Çapraz Sınır Mevzuat Değerlendirmesi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: hurmaKahvesiKoyu,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildParametreKarti(),
            const SizedBox(height: 16),
            if (_sonuc != null) _buildSonucAlani(_sonuc!),
          ],
        ),
      ),
    );
  }

  Widget _buildParametreKarti() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.tune, color: hurmaKahvesi),
                SizedBox(width: 8),
                Text('Operasyon Parametreleri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _seciliCikisUlke,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Çıkış Ülkesi',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'SA', child: Text('🇸🇦 Suudi Arabistan')),
                      DropdownMenuItem(value: 'TR', child: Text('🇹🇷 Türkiye')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _seciliCikisUlke = val);
                        _hesapla();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.arrow_forward, color: hurmaKahvesi),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _seciliVarisUlke,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Varış Ülkesi',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'DE', child: Text('🇩🇪 Almanya (AB)')),
                      DropdownMenuItem(value: 'TR', child: Text('🇹🇷 Türkiye')),
                      DropdownMenuItem(value: 'SA', child: Text('🇸🇦 Suudi Arabistan')),
                      DropdownMenuItem(value: 'CN', child: Text('🇨🇳 Çin (Boş Raf)')),
                      DropdownMenuItem(value: 'IN', child: Text('🇮🇳 Hindistan (Boş Raf)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _seciliVarisUlke = val);
                        _hesapla();
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _seciliUrun,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Ürün',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Medjool Hurma (Kuru)', child: Text('Medjool Hurma (Kuru)')),
                      DropdownMenuItem(value: 'Sukkari Hurma (Taze/Kuru)', child: Text('Sukkari Hurma (Taze/Kuru)')),
                      DropdownMenuItem(value: 'Hurma Ezmesi & Yan Ürün', child: Text('Hurma Ezmesi & Yan Ürün')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _seciliUrun = val;
                          _seciliHsKod = val.contains('Ezmesi') ? '200899' : '080410';
                        });
                        _hesapla();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: _miktarKg.toStringAsFixed(0),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Miktar (Kg)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    onChanged: (val) {
                      final parsed = double.tryParse(val);
                      if (parsed != null && parsed > 0) {
                        _miktarKg = parsed;
                        _hesapla();
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilterChip(
                  label: const Text('Organik Ürün'),
                  selected: _isOrganik,
                  selectedColor: zeytinYesili.withOpacity(0.2),
                  checkmarkColor: zeytinYesili,
                  onSelected: (val) {
                    setState(() => _isOrganik = val);
                    _hesapla();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Helal Sertifikalı'),
                  selected: _isHelal,
                  selectedColor: altinSarisi.withOpacity(0.2),
                  checkmarkColor: altinSarisi,
                  onSelected: (val) {
                    setState(() => _isHelal = val);
                    _hesapla();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSonucAlani(CrossBorderEvaluationResult res) {
    if (res.isShelfEmpty) {
      return Card(
        color: Colors.red.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.red.shade300),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                  SizedBox(width: 10),
                  Text('BOŞ MEVZUAT RAFI (NOT_LOADED)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 12),
              ...res.riskAlerts.map((a) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(a, style: const TextStyle(fontSize: 13, color: Colors.black87)),
              )),
              const SizedBox(height: 12),
              Text(
                res.legalDisclaimer,
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.red),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Özet Başlık Kartı
        Card(
          elevation: 2,
          color: hurmaKahvesiKoyu,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${res.sourceCountry} ➔ ${res.destinationCountry} Değerlendirmesi',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: zeytinYesili,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'RİSK: ${res.riskLevel}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Ürün: ${res.productName} (HS: ${res.hsCode})',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // 2. Tespit Edilen Bağımsız Hukuk Havuzları (Jurisdiction Isolation)
        const Text('1. Tespit Edilen Hukuk Havuzları (İzole)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: hurmaKahvesiKoyu)),
        const SizedBox(height: 8),
        _buildHavuzKarti('Kaynak Ülke Çıkış & İhracat Hukuku (${res.sourceCountry})', res.sourceExportObligations, Colors.blue.shade50, Colors.blue.shade800),
        if (res.supranationalObligations.isNotEmpty)
          _buildHavuzKarti('Üst-Ulusal Çerçeve (Avrupa Birliği Gıda İthalatı)', res.supranationalObligations, Colors.amber.shade50, Colors.amber.shade900),
        if (res.destinationNationalObligations.isNotEmpty)
          _buildHavuzKarti('Varış Ülkesi Ulusal Hukuku (${res.destinationCountry})', res.destinationNationalObligations, Colors.green.shade50, Colors.green.shade900),

        const SizedBox(height: 14),

        // 3. Kontrol Mekanizmaları (TRACES, BCP, Lab)
        const Text('2. Resmi Kontrol & Dijital Sistemler', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: hurmaKahvesiKoyu)),
        const SizedBox(height: 8),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _buildKontrolSatir(
                  icon: Icons.cloud_done,
                  title: 'TRACES NT Dijital Ön Bildirim',
                  durum: res.isTracesNtRequired ? 'ZORUNLU (${res.tracesNtType})' : 'GEREKMİYOR',
                  isOk: res.isTracesNtRequired,
                ),
                const Divider(height: 16),
                _buildKontrolSatir(
                  icon: Icons.storefront,
                  title: 'Sınır Kontrol Noktası (BCP) Denetimi',
                  durum: res.isBorderControlPostRequired ? 'ZORUNLU (Belge + Kimlik Kontrolü)' : 'STANDART',
                  isOk: res.isBorderControlPostRequired,
                ),
                const Divider(height: 16),
                _buildKontrolSatir(
                  icon: Icons.biotech,
                  title: 'Laboratuvar Analizi (Aflatoksin/Pestisit)',
                  durum: res.isLabAnalysisRequired ? 'GEREKLİ (Risk Bazlı Numune Alma)' : 'STANDART',
                  isOk: res.isLabAnalysisRequired,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // 4. Gerekli Belgeler ve Sertifikalar
        const Text('3. Zorunlu Belgeler & Sertifikalar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: hurmaKahvesiKoyu)),
        const SizedBox(height: 8),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...res.requiredDocuments.map((d) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.description, size: 16, color: hurmaKahvesi),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d.documentName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Text('Veren: ${d.issuingAuthority} • ${d.purpose}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
                const Divider(height: 16),
                const Text('Zorunlu Sertifikalar:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: res.requiredCertificates.map((c) => Chip(
                    avatar: const Icon(Icons.workspace_premium, size: 16, color: altinSarisi),
                    label: Text(c, style: const TextStyle(fontSize: 11)),
                    backgroundColor: kremArkaplan,
                  )).toList(),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // 5. Etiketleme ve Ambalaj (LUCID VerpackG)
        const Text('4. Etiketleme & Ambalaj Gereklilikleri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: hurmaKahvesiKoyu)),
        const SizedBox(height: 8),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Zorunlu Etiket Unsurları:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                ...res.mandatoryLabelingElements.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.check, size: 14, color: zeytinYesili),
                      const SizedBox(width: 6),
                      Expanded(child: Text(e, style: const TextStyle(fontSize: 12))),
                    ],
                  ),
                )),
                const Divider(height: 16),
                const Text('Ambalaj & Geri Dönüşüm Yükümlülükleri:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                ...res.packagingAndRecyclingObligations.map((p) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.recycling, size: 14, color: zeytinYesili),
                      const SizedBox(width: 6),
                      Expanded(child: Text(p, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // 6. Gümrük Vergisi & KDV
        const Text('5. Gümrük Vergisi & İthalat KDV', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: hurmaKahvesiKoyu)),
        const SizedBox(height: 8),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('Gümrük Vergisi', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text('%${res.customsDutyRate.toStringAsFixed(1)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: hurmaKahvesiKoyu)),
                    Text(res.customsTariffCitation, style: const TextStyle(fontSize: 10, color: Colors.black54)),
                  ],
                ),
                Container(height: 40, width: 1, color: Colors.grey.shade300),
                Column(
                  children: [
                    const Text('İthalat KDV Oranı', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text('%${res.importVatRate.toStringAsFixed(1)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: hurmaKahvesiKoyu)),
                    const Text('İndirimli Gıda Oranı', style: TextStyle(fontSize: 10, color: Colors.black54)),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // 7. Risk Uyarıları & Son Tarihler
        const Text('6. Kritik Süreler & Risk Uyarıları', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: hurmaKahvesiKoyu)),
        const SizedBox(height: 8),
        Card(
          elevation: 1,
          color: Colors.amber.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.amber.shade300),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...res.criticalDeadlines.map((d) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.timer, size: 15, color: Colors.amber),
                      const SizedBox(width: 6),
                      Expanded(child: Text(d, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                    ],
                  ),
                )),
                const Divider(height: 16),
                ...res.riskAlerts.map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(r, style: const TextStyle(fontSize: 12)),
                )),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // 8. Hukuki Sorumluluk Reddi (Disclaimer)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.gavel, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  res.legalDisclaimer,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildHavuzKarti(String title, List<LegalObligationItem> items, Color bg, Color headerColor) {
    return Card(
      elevation: 1,
      color: bg,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: headerColor)),
            const SizedBox(height: 8),
            ...items.map((it) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ${it.title}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  Text('${it.description} (${it.officialCitation})', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildKontrolSatir({
    required IconData icon,
    required String title,
    required String durum,
    required bool isOk,
  }) {
    return Row(
      children: [
        Icon(icon, color: isOk ? zeytinYesili : Colors.grey, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isOk ? zeytinYesili.withOpacity(0.1) : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            durum,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isOk ? zeytinYesili : Colors.black54,
            ),
          ),
        ),
      ],
    );
  }
}
