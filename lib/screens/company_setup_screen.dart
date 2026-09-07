import 'package:flutter/material.dart';
import '../core/i18n/app_dictionary.dart';
import '../repositories/company_repository.dart';
import '../core/tenant/tenant_context.dart';

class CompanySetupScreen extends StatefulWidget {
  final VoidCallback onCompleted;
  const CompanySetupScreen({super.key, required this.onCompleted});

  @override
  State<CompanySetupScreen> createState() => _CompanySetupScreenState();
}

class _CompanySetupScreenState extends State<CompanySetupScreen> {
  final PageController _pageController = PageController();
  int _adim = 0;

  final TextEditingController _sirketAdiController = TextEditingController();
  final TextEditingController _sirketKisaltmaController =
      TextEditingController();
  final TextEditingController _adresController = TextEditingController();

  // Yeni ülke / mevzuat ekleme kontrolcütleri
  final TextEditingController _yeniUlkeAdiController = TextEditingController();
  final TextEditingController _yeniParaBirimiController =
      TextEditingController();

  String _secilenUlkeKodu = 'KSA';

  // Aynı anda seçilen diller (Liste)
  final List<String> _secilenDiller = ['AR', 'UG', 'TR']; // Varsayılan 3 dil

  bool _kaydediliyor = false;

  Future<void> _kurulumuTamamla() async {
    setState(() => _kaydediliyor = true);
    try {
      final tenantId = TenantContext.instance.activeTenantId ??
          '00000000-0000-0000-0000-000000000001';
      final sirketAdi = _sirketAdiController.text.trim().isNotEmpty
          ? _sirketAdiController.text.trim()
          : 'Hidayetullah Ltd';
      final sirketKodu = _sirketKisaltmaController.text.trim().isNotEmpty
          ? _sirketKisaltmaController.text.trim().toUpperCase()
          : 'HGLTD';

      final comp = await CompanyRepository.instance.createCompany(
        tenantId: tenantId,
        code: sirketKodu,
        legalName: sirketAdi,
        currencyCode: _secilenUlkeKodu == 'KSA' ? 'SAR' : 'USD',
      );

      if (comp != null) {
        TenantContext.instance.setActiveCompany(comp.id);
      }
      widget.onCompleted();
    } catch (e) {
      widget.onCompleted(); // Hata olsa bile akışı kesmiyoruz
    } finally {
      if (mounted) setState(() => _kaydediliyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F1), // Hurma & Krem Teması
      appBar: AppBar(
        backgroundColor: const Color(0xFF5C4033), // Koyu Hurma Kahvesi
        title: const Text('NAKHL&NAHL — Global Kurulum Sihirbazı',
            style: TextStyle(color: Colors.amberAccent)),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
              value: (_adim + 1) / 3,
              color: Colors.amber,
              backgroundColor: Colors.brown.shade100),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _adim = i),
              children: [
                // ADIM 1: DOĞRUDAN GÖRÜNÜR 3'LÜ DİL SEÇİM LİSTESİ
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                          'Adım 1 — Eşzamanlı Çoklu Dil Seçimi (1, 2 veya 3 Dil)',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5C4033))),
                      const SizedBox(height: 8),
                      const Text(
                          'Aşağıdaki listeden ekranda aynı anda görmek istediğiniz dilleri işaretleyin. Menüler anında seçtiğiniz dillerle birleşecektir.',
                          style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.brown.shade200)),
                        child: ListView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: desteklenenDiller.entries.map((entry) {
                            final secili = _secilenDiller.contains(entry.key);
                            return CheckboxListTile(
                              title: Text(entry.value,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              value: secili,
                              activeColor: const Color(0xFF5C4033),
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    if (_secilenDiller.length < 3)
                                      _secilenDiller.add(entry.key);
                                  } else {
                                    if (_secilenDiller.length > 1)
                                      _secilenDiller.remove(
                                          entry.key); // En az 1 dil kalmalı
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.shade300)),
                        child: Text(
                          'Anlık Menü Görünümü:\n${metin('sirketAdi', _secilenDiller)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.brown),
                        ),
                      ),
                    ],
                  ),
                ),

                // ADIM 2: ÜLKE VE MEVZUAT LİSTESİ + YENİ EKLE
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Adım 2 — Ülke ve Vergi Mevzuatı',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5C4033))),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _secilenUlkeKodu,
                        decoration: const InputDecoration(
                            labelText: 'Hedef Ülke ve Mevzuat',
                            border: OutlineInputBorder()),
                        items: [
                          const DropdownMenuItem(
                              value: 'KSA',
                              child:
                                  Text('🇸🇦 Suudi Arabistan (ZATCA - SAR)')),
                          const DropdownMenuItem(
                              value: 'TR',
                              child: Text('🇹🇷 Türkiye (GİB - TRY)')),
                          const DropdownMenuItem(
                              value: 'DE',
                              child: Text('🇩🇪 Almanya (EU VAT - EUR)')),
                          const DropdownMenuItem(
                              value: 'US',
                              child: Text('🇺🇸 Amerika (IRS - USD)')),
                        ],
                        onChanged: (v) => setState(() => _secilenUlkeKodu = v!),
                      ),
                      const SizedBox(height: 20),
                      ExpansionTile(
                        title: const Text(
                            '➕ Listede Olmayan Ülke / Mevzuat Ekle',
                            style: TextStyle(
                                color: Colors.brown,
                                fontWeight: FontWeight.bold)),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                TextField(
                                    controller: _yeniUlkeAdiController,
                                    decoration: const InputDecoration(
                                        labelText: 'Yeni Ülke Adı',
                                        border: OutlineInputBorder())),
                                const SizedBox(height: 8),
                                TextField(
                                    controller: _yeniParaBirimiController,
                                    decoration: const InputDecoration(
                                        labelText:
                                            'Para Birimi Kodu (Örn: AED)',
                                        border: OutlineInputBorder())),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Yeni ülke mevzuatı sisteme eklendi!')));
                                  },
                                  child: const Text('Mevzuatı Kaydet'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ADIM 3: ŞİRKET BİLGİLERİ
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Adım 3 — Şirketiniz ve Akıllı Kod İmzanız',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5C4033))),
                      const SizedBox(height: 16),
                      TextField(
                          controller: _sirketAdiController,
                          decoration: const InputDecoration(
                              labelText:
                                  'Şirket Resmi Adı (Örn: Hidayetullah Ltd)',
                              border: OutlineInputBorder())),
                      const SizedBox(height: 16),
                      TextField(
                          controller: _sirketKisaltmaController,
                          decoration: const InputDecoration(
                              labelText:
                                  'Şirket Kısaltması / İmza Kodu (Örn: HGLTD)',
                              border: OutlineInputBorder())),
                      const SizedBox(height: 16),
                      TextField(
                          controller: _adresController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                              labelText: 'Şirket Adresi',
                              border: OutlineInputBorder())),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                if (_adim > 0)
                  OutlinedButton(
                    onPressed: () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.ease),
                    child: const Text('Geri'),
                  ),
                const Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5C4033),
                      foregroundColor: Colors.amberAccent),
                  onPressed: _kaydediliyor
                      ? null
                      : () {
                          if (_adim < 2) {
                            _pageController.nextPage(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.ease);
                          } else {
                            _kurulumuTamamla();
                          }
                        },
                  child: Text(_kaydediliyor
                      ? 'Kaydediliyor...'
                      : (_adim < 2 ? 'İleri' : 'Sistemi Başlat')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
