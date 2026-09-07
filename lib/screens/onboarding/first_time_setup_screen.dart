// ==============================================================================
// NAKHL & NAHL — İLK KURULUM SİHİRBAZI (FIRST-TIME SETUP WIZARD - FAZ 11)
// 16 ADIMLI DİNAMİK KURULUM AKIŞI:
// 1. Dil (Maks 3 Dil)          9. Sektörler (Multi-Select + Özel Ekle)
// 2. Alfabe / Script           10. Ürün Kategorileri
// 3. Ülke / Ülkeler            11. Ürünler (Dinamik + Yeni Ürün Ekle)
// 4. Bölge                     12. Kalite / Sınıf & Fire Ayrımı
// 5. Şehir                     13. Şirket Bilgileri
// 6. İlçe                      14. Kullanıcı Bilgileri
// 7. Mahalle                   15. Rol / Yetki
// 8. Açık Adres                16. ERP Ana Ekranı ve Özet
// ==============================================================================

import 'package:flutter/material.dart';
import '../../core/tenant/tenant_context.dart';
import '../../core/i18n/locale_script_manager.dart';
import '../../core/address/address_catalog.dart';
import '../../widgets/address_picker_dialog.dart';
import '../../models/sector_model.dart';
import '../../models/user_preferences_model.dart';
import '../../services/sector_service.dart';
import '../../services/user_preferences_service.dart';
import '../../services/opening_balance_service.dart';
import '../../models/location_master_model.dart';
import '../../services/location_service.dart';
import '../dashboard_screen.dart';

class FirstTimeSetupScreen extends StatefulWidget {
  final VoidCallback? onSetupCompleted;

  const FirstTimeSetupScreen({super.key, this.onSetupCompleted});

  @override
  State<FirstTimeSetupScreen> createState() => _FirstTimeSetupScreenState();
}

class _FirstTimeSetupScreenState extends State<FirstTimeSetupScreen> {
  // Kurumsal Renk Paleti
  static const Color hurmaKahvesi = Color(0xFF5C4033);
  static const Color hurmaKahvesiKoyu = Color(0xFF3E2723);
  static const Color kremArkaplan = Color(0xFFFBF9F1);
  static const Color altinSarisi = Color(0xFFC89033);

  final PageController _pageController = PageController();
  int _currentStep = 0;
  static const int _totalSteps = 16;

  // 1. Dil Seçimi (Maks 3 dil: 1 ana dil zorunlu, 2. ve 3. opsiyonel)
  final Set<String> _selectedLanguages = {'tr'};
  String _primaryLanguage = 'tr';

  // 2. Alfabe / Script Seçimi
  String _primaryScript = 'Latn';
  final Map<String, String> _languageScripts = {'tr': 'Latn'};

  // 3. Ülke / Ülkeler (Multi-select)
  final Set<String> _selectedCountries = {'SA', 'TR'};

  // 4-8. Lokasyon ve Adres Hiyerarşisi
  final _bolgeController = TextEditingController(text: 'Riyad Bölgesi');
  final _sehirController = TextEditingController(text: 'Riyad');
  final _ilceController = TextEditingController(text: 'El-Olaya');
  final _mahalleController = TextEditingController(text: 'Kral Fahd Mahallesi');
  final _acikAdresController = TextEditingController(text: 'Kral Fahd Cad. Bina No: 142');

  // 9. Sektörler (Multi-select + Özel Sektör Ekleme)
  List<SectorModel> _allSectors = [];
  final Set<String> _selectedSectorCodes = {'DATES', 'FOOD'};
  final _ozelSektorController = TextEditingController();

  // 10. Ürün Kategorileri
  final List<String> _productCategories = [
    'Taze ve Yaş Hurma',
    'Kuru Hurma Çeşitleri',
    'Organik Bal & Arı Ürünleri',
    'Zeytinyağı ve Gurme Gıda',
    'Ambalaj & Koli Malzemeleri',
  ];
  final _yeniKategoriController = TextEditingController();

  // 11. Ürünler
  final List<Map<String, String>> _dynamicProducts = [
    {
      'name': 'Acve Hurması (VIP Duble)',
      'category': 'Taze ve Yaş Hurma',
      'sector': 'Hurma ve Hurma Ürünleri',
      'unit': 'Kg',
      'sku': 'ACV-001',
      'grade': 'Premium',
    },
    {
      'name': 'Medine Mebrum Hurma',
      'category': 'Kuru Hurma Çeşitleri',
      'sector': 'Hurma ve Hurma Ürünleri',
      'unit': 'Kg',
      'sku': 'MBR-002',
      'grade': '1. Sınıf',
    },
  ];
  final _urunAdiController = TextEditingController(text: 'Acve Hurması (VIP Duble)');
  final _urunSkuController = TextEditingController(text: 'ACV-001');
  final _urunBirimController = TextEditingController(text: 'Kg');
  final _urunAlisFiyatController = TextEditingController(text: '85.00');
  final _urunSatisFiyatController = TextEditingController(text: '145.00');
  final _urunMiktarController = TextEditingController(text: '1500');

  // 12. Kalite / Sınıf & Fire Ayrımı
  String _secilenKaliteSinifi = 'PREMIUM';
  String _fireKondisyonTuru = 'FIRE_REJECT';

  // 13. Şirket Bilgileri
  final _sirketAdiController = TextEditingController(text: 'NAKHL & NAHL Global Ticaret A.Ş.');
  final _ticariUnvanController = TextEditingController(text: 'Nakhl & Nahl Gıda ve Dış Tic. Ltd. Şti.');
  final _vknController = TextEditingController(text: '310123456700003');
  final _vergiDairesiController = TextEditingController(text: 'Riyad Merkez / Beyoğlu VD');
  String _selectedCurrency = 'SAR';

  // 14. Kullanıcı Bilgileri
  final _yetkiliAdController = TextEditingController(text: 'Hidayetullah');
  final _yetkiliSoyadController = TextEditingController(text: 'Hoca');
  final _emailController = TextEditingController(text: 'yonetici@nakhlnahl.com');
  final _telefonController = TextEditingController(text: '+966 50 123 4567');
  final _pinController = TextEditingController(text: '1234');

  // 15. Rol / Yetki
  String _selectedRole = 'Admin';

  // 16. Kasa / Bilanço Açılışı
  final _kasaBakiyeController = TextEditingController(text: '50000');
  final _bankaBakiyeController = TextEditingController(text: '200000');
  final _alacakController = TextEditingController(text: '120000');
  final _borcController = TextEditingController(text: '65000');

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSectors();
  }

  Future<void> _loadSectors() async {
    final sectors = await SectorService.instance.getAllSectors();
    if (mounted) {
      setState(() => _allSectors = sectors);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bolgeController.dispose();
    _sehirController.dispose();
    _ilceController.dispose();
    _mahalleController.dispose();
    _acikAdresController.dispose();
    _ozelSektorController.dispose();
    _yeniKategoriController.dispose();
    _urunAdiController.dispose();
    _urunSkuController.dispose();
    _urunBirimController.dispose();
    _urunAlisFiyatController.dispose();
    _urunSatisFiyatController.dispose();
    _urunMiktarController.dispose();
    _sirketAdiController.dispose();
    _ticariUnvanController.dispose();
    _vknController.dispose();
    _vergiDairesiController.dispose();
    _yetkiliAdController.dispose();
    _yetkiliSoyadController.dispose();
    _emailController.dispose();
    _telefonController.dispose();
    _pinController.dispose();
    _kasaBakiyeController.dispose();
    _bankaBakiyeController.dispose();
    _alacakController.dispose();
    _borcController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _tamamlaVeBaslat();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _tamamlaVeBaslat() async {
    setState(() => _isSaving = true);

    try {
      final tenantId = '00000000-0000-0000-0000-000000000001';
      final companyId = '00000000-0000-0000-0000-000000000002';
      final userId = '00000000-0000-0000-0000-000000000003';
      final sirketKodu = _sirketAdiController.text.trim().isNotEmpty
          ? _sirketAdiController.text.trim().substring(0, 3).toUpperCase()
          : 'NNG';

      // 1. Kullanıcı Dil ve Tercihlerini Senkronize Et
      final langList = _selectedLanguages.toList();
      final secLang = langList.length > 1 ? langList[1] : null;
      final terLang = langList.length > 2 ? langList[2] : null;

      final userPrefs = UserPreferencesModel(
        id: '',
        userId: userId,
        tenantId: tenantId,
        primaryLanguageCode: _primaryLanguage,
        primaryScriptCode: _primaryScript,
        secondaryLanguageCode: secLang,
        secondaryScriptCode: secLang != null ? _languageScripts[secLang] : null,
        tertiaryLanguageCode: terLang,
        tertiaryScriptCode: terLang != null ? _languageScripts[terLang] : null,
        activeLocaleId: '$_primaryLanguage-$_primaryScript',
        textDirection: _primaryScript == 'Arab' ? 'rtl' : 'ltr',
      );

      await UserPreferencesService.instance.savePreferences(userPrefs);

      // 2. Seçili Sektörleri Kaydet
      final selectedSectorIds = _allSectors
          .where((s) => _selectedSectorCodes.contains(s.code))
          .map((s) => s.id)
          .toList();
      await SectorService.instance.saveTenantSectors(tenantId, selectedSectorIds);

      // 3. Açılış Bilançosu Snapshot'ı
      final double kasa = double.tryParse(_kasaBakiyeController.text) ?? 50000;
      final double banka = double.tryParse(_bankaBakiyeController.text) ?? 200000;
      final double alacak = double.tryParse(_alacakController.text) ?? 120000;
      final double borc = double.tryParse(_borcController.text) ?? 65000;
      final double stokMiktari = double.tryParse(_urunMiktarController.text) ?? 1500;
      final double stokFiyat = double.tryParse(_urunAlisFiyatController.text) ?? 85;

      final snapshot = BusinessSnapshot(
        totalCash: kasa,
        totalBank: banka,
        pocketCash: 5000,
        totalReceivables: alacak,
        totalPayables: borc,
        totalInventoryValue: stokMiktari * stokFiyat,
        customerCount: 2,
        supplierCount: 2,
        productCount: _dynamicProducts.length,
        warehouseCount: 1,
        branchCount: 1,
        openingDate: DateTime.now(),
        currency: _selectedCurrency,
      );
      OpeningBalanceService.instance.saveSnapshot(snapshot);

      // 4. Tenant Context Ayarla
      TenantContext.instance.setActiveTenant(
        tenantId: tenantId,
        tenantCode: sirketKodu,
        companyId: companyId,
        companyName: _sirketAdiController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 "${_sirketAdiController.text.trim()}" çok sektörlü ERP başarıyla kuruldu!'),
            backgroundColor: const Color(0xFF2E7D32),
            duration: const Duration(seconds: 2),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;

        if (widget.onSetupCompleted != null) {
          widget.onSetupCompleted!();
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => DashboardScreen(
                sirketVerisi: {
                  'sirketKisaltmasi': sirketKodu,
                  'sirketAdi': _sirketAdiController.text.trim(),
                  'ulkeKodu': _selectedCountries.first,
                  'paraBirimi': _selectedCurrency,
                  'birincilDil': _primaryLanguage.toUpperCase(),
                  'ikincilDil': secLang?.toUpperCase() ?? 'AR',
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _kurulumRehberiDialoguGoster() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: hurmaKahvesi),
            SizedBox(width: 8),
            Text('Kurulum Rehberi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '16 Adımlı NAKHL & NAHL ERP Kurulumu:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              SizedBox(height: 8),
              Text(
                '1-2: Çok Dilli ve Çok Alfabeli Yapılandırma (Arapça, Latin, Kiril vb.)\n'
                '3-4: Faaliyet Ülkeleri ve Şirket / Şube Bilgileri\n'
                '5-6: Çok Sektörlü Yapı (Gıda, Hurma, Tarım, Arıcılık, Mobilya vb.)\n'
                '7-8: Vergi, Para Birimleri ve Muhasebe Hesap Planı\n'
                '9-10: E-Fatura / E-İrsaliye ve ZATCA Entegrasyonları\n'
                '11-12: Ürün Kalite Derecelendirme (Grade) ve Yangın / Fire / Iskonto\n'
                '13-14: İhracat, Gümrük, GTİP ve Lojistik Ayarları\n'
                '15-16: Güvenlik, RLS Yetkilendirme ve Sistem Özeti',
                style: TextStyle(fontSize: 12, height: 1.4),
              ),
              SizedBox(height: 12),
              Text(
                'Bu sihirbaz tamamlandığında tüm ayarlarınız PostgreSQL veritabanınıza güvenle kaydedilir.',
                style: TextStyle(fontSize: 11.5, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: hurmaKahvesi, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Anladım'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _primaryScript == 'Arab' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: kremArkaplan,
        appBar: AppBar(
          backgroundColor: hurmaKahvesi,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Row(
            children: [
              const Icon(Icons.rocket_launch_rounded, color: altinSarisi, size: 20),
              const SizedBox(width: 8),
              Text(
                '16 Adımlı ERP Kurulum Sihirbazı (${_currentStep + 1} / $_totalSteps)',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: _kurulumRehberiDialoguGoster,
              icon: const Icon(Icons.help_outline_rounded, color: altinSarisi, size: 18),
              label: const Text('Yardım Al', style: TextStyle(color: altinSarisi, fontSize: 12)),
            ),
          ],
        ),


        body: Column(
          children: [
            // İlerleme Çubuğu
            LinearProgressIndicator(
              value: (_currentStep + 1) / _totalSteps,
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation<Color>(altinSarisi),
              minHeight: 4,
            ),

            // Sayfa İçeriği
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (idx) => setState(() => _currentStep = idx),
                children: [
                  _adim1DilSecimi(),
                  _adim2AlfabeScriptSecimi(),
                  _adim3UlkeSecimi(),
                  _adim4BolgeSecimi(),
                  _adim5SehirSecimi(),
                  _adim6IlceSecimi(),
                  _adim7MahalleSecimi(),
                  _adim8AdresDetay(),
                  _adim9SektorlerSecimi(),
                  _adim10UrunKategorileri(),
                  _adim11Urunler(),
                  _adim12KaliteVeFire(),
                  _adim13SirketBilgileri(),
                  _adim14KullaniciBilgileri(),
                  _adim15RolVeYetki(),
                  _adim16OzetVeBaslat(),
                ],
              ),
            ),

            // Alt Navigasyon Butonları
            _altNavigasyonKontrolleri(),
          ],
        ),
      ),
    );
  }

  Widget _altNavigasyonKontrolleri() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -3)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            OutlinedButton.icon(
              onPressed: _prevStep,
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Geri'),
              style: OutlinedButton.styleFrom(
                foregroundColor: hurmaKahvesi,
                side: const BorderSide(color: hurmaKahvesi),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            )
          else
            const SizedBox(width: 80),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _nextStep,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Icon(_currentStep == _totalSteps - 1 ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                    size: 18),
            label: Text(_currentStep == _totalSteps - 1 ? 'Sistemi Başlat' : 'Devam Et'),
            style: ElevatedButton.styleFrom(
              backgroundColor: hurmaKahvesi,
              foregroundColor: altinSarisi,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _adimWrapper({
    required String title,
    required String subtitle,
    required Widget content,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: hurmaKahvesiKoyu),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700)),
          const Divider(height: 32),
          content,
        ],
      ),
    );
  }

  // ── 1. DİL SEÇİMİ (MAKS 3 DİL) ──
  Widget _adim1DilSecimi() {
    final catalog = LocaleScriptManager.languagesCatalog;

    return _adimWrapper(
      title: '1. Hangi Dillerde Kullanmak İstiyorsunuz?',
      subtitle: 'En az 1 ana dil zorunludur. İsteğe bağlı 2. ve 3. dili seçebilirsiniz (Maksimum 3 dil).',
      content: Column(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: catalog.keys.map((langKey) {
              final lang = catalog[langKey]!;
              final isSelected = _selectedLanguages.contains(langKey);
              final isPrimary = _primaryLanguage == langKey;

              return InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      if (_selectedLanguages.length > 1) {
                        _selectedLanguages.remove(langKey);
                        if (isPrimary) {
                          _primaryLanguage = _selectedLanguages.first;
                        }
                      }
                    } else {
                      if (_selectedLanguages.length < 3) {
                        _selectedLanguages.add(langKey);
                        _languageScripts[langKey] = lang.supportedScriptCodes.first;
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('En fazla 3 dil seçebilirsiniz.')),
                        );
                      }
                    }
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 170,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? hurmaKahvesi.withOpacity(0.08) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? hurmaKahvesi : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                        color: isSelected ? hurmaKahvesi : Colors.grey,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lang.nativeName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isSelected ? hurmaKahvesiKoyu : Colors.black87,
                              ),
                            ),
                            Text(
                              lang.englishName,
                              style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          if (_selectedLanguages.length > 1)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Text('Varsayılan Ana Dil:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(width: 16),
                  DropdownButton<String>(
                    value: _primaryLanguage,
                    items: _selectedLanguages.map((l) {
                      return DropdownMenuItem(
                        value: l,
                        child: Text(catalog[l]?.nativeName ?? l),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _primaryLanguage = val);
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── 2. ALFABE / SCRIPT SEÇİMİ ──
  Widget _adim2AlfabeScriptSecimi() {
    final catalog = LocaleScriptManager.languagesCatalog;
    final scripts = LocaleScriptManager.scriptsCatalog;

    return _adimWrapper(
      title: '2. Dil Alfabesi ve Yazı Sistemi Seçimi',
      subtitle: 'Language ≠ Script prensibi: Diliniz ile kullanmak istediğiniz yazı sistemini belirleyin.',
      content: Column(
        children: _selectedLanguages.map((langKey) {
          final lang = catalog[langKey]!;
          final allowedScripts = lang.supportedScriptCodes;
          final currentScript = _languageScripts[langKey] ?? allowedScripts.first;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.translate_rounded, color: hurmaKahvesi, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${lang.nativeName} (${lang.englishName}) Alfabesi:',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    children: allowedScripts.map((sCode) {
                      final s = scripts[sCode];
                      final isSelected = currentScript == sCode;

                      return ChoiceChip(
                        label: Text('${s?.name ?? sCode} (${s?.defaultDirection.name.toUpperCase()})'),
                        selected: isSelected,
                        selectedColor: hurmaKahvesi.withOpacity(0.18),
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _languageScripts[langKey] = sCode;
                              if (langKey == _primaryLanguage) {
                                _primaryScript = sCode;
                              }
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── 3. ÜLKE / ÜLKELER (MULTI-SELECT) ──
  Widget _adim3UlkeSecimi() {
    final countries = [
      {'code': 'SA', 'name': 'Suudi Arabistan (KSA)', 'flag': '🇸🇦'},
      {'code': 'TR', 'name': 'Türkiye', 'flag': '🇹🇷'},
      {'code': 'AE', 'name': 'Birleşik Arap Emirlikleri (BAE)', 'flag': '🇦🇪'},
      {'code': 'EG', 'name': 'Mısır', 'flag': '🇪🇬'},
      {'code': 'DE', 'name': 'Almanya', 'flag': '🇩🇪'},
      {'code': 'US', 'name': 'Amerika Birleşik Devletleri', 'flag': '🇺🇸'},
      {'code': 'QA', 'name': 'Katar', 'flag': '🇶🇦'},
      {'code': 'PK', 'name': 'Pakistan', 'flag': '🇵🇰'},
    ];

    return _adimWrapper(
      title: '3. Faaliyet Gösterilen Ülkeler',
      subtitle: 'Şirketiniz birden fazla ülkede eşzamanlı faaliyet gösterebilir (Çoklu Ülke Desteği).',
      content: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: countries.map((c) {
          final code = c['code']!;
          final isSelected = _selectedCountries.contains(code);

          return FilterChip(
            avatar: Text(c['flag']!, style: const TextStyle(fontSize: 16)),
            label: Text(c['name']!),
            selected: isSelected,
            selectedColor: altinSarisi.withOpacity(0.2),
            checkmarkColor: hurmaKahvesi,
            onSelected: (val) {
              setState(() {
                if (val) {
                  _selectedCountries.add(code);
                  _applyCountryBusinessRules(code);
                } else if (_selectedCountries.length > 1) {
                  _selectedCountries.remove(code);
                  _applyCountryBusinessRules(_selectedCountries.first);
                }
              });
            },
          );
        }).toList(),
      ),
    );
  }

  void _applyCountryBusinessRules(String countryCode) {
    final profile = LocationService.instance.getBusinessProfile(countryCode);
    _selectedCurrency = profile.currencyCode;
    if (countryCode == 'SA') {
      _bolgeController.text = 'Riyad Bölgesi';
      _sehirController.text = 'Riyadh';
      _ilceController.text = 'El-Olaya';
      _mahalleController.text = 'Kral Fahd Mahallesi';
      _acikAdresController.text = 'Kral Fahd Cad. Bina No: 142';
      _vergiDairesiController.text = 'ZATCA Riyad Vergi Dairesi';
      _vknController.text = '310123456700003';
    } else if (countryCode == 'TR') {
      _bolgeController.text = 'Marmara Bölgesi';
      _sehirController.text = 'İstanbul';
      _ilceController.text = 'Kadıköy';
      _mahalleController.text = 'Moda Mah.';
      _acikAdresController.text = 'Bağdat Cad. No: 12 Kat: 2';
      _vergiDairesiController.text = 'Kadıköy Vergi Dairesi';
      _vknController.text = '1234567890';
    }
  }

  // ── 4-8. ADRES VE LOKASYON HİYERARŞİSİ (LİSTE TABANLI) ──
  String get _currentCountryCode => _selectedCountries.isNotEmpty ? _selectedCountries.first : 'SA';

  Widget _adim4BolgeSecimi() {
    final regions = AddressCatalog.getRegionsByCountry(_currentCountryCode);
    return _adresListeSecimAdimi(
      adimNo: 4,
      baslik: 'Bölge / Eyalet Seçimi',
      altBaslik: 'Merkez şubenizin bulunduğu ana idari bölgeyi listeden seçiniz veya arayınız.',
      controller: _bolgeController,
      label: 'Bölge / Eyalet',
      icon: Icons.map_rounded,
      onerilenListe: regions.map((r) => r.name).toList(),
      nativeAdlar: {for (var r in regions) r.name: r.nativeName},
    );
  }

  Widget _adim5SehirSecimi() {
    final catalogCities = AddressCatalog.getCities(
      countryCode: _currentCountryCode,
      regionName: _bolgeController.text.trim().isNotEmpty ? _bolgeController.text.trim() : null,
    );
    // Merge LocationService master cities (106 KSA / 720 TR)
    final cityNames = <String>[];
    final nativeAdlar = <String, String>{};

    for (final c in catalogCities) {
      if (!cityNames.contains(c.name)) {
        cityNames.add(c.name);
        nativeAdlar[c.name] = c.nativeName;
      }
    }

    return FutureBuilder<List<CityMasterModel>>(
      future: LocationService.instance.getCitiesByCountry(_currentCountryCode, limit: 30),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          for (final c in snapshot.data!) {
            if (!cityNames.contains(c.cityName)) {
              cityNames.add(c.cityName);
              nativeAdlar[c.cityName] = c.adminName.isNotEmpty ? c.adminName : c.cityNameAscii;
            }
          }
        }

        return _adresListeSecimAdimi(
          adimNo: 5,
          baslik: 'Şehir Seçimi (Global Lokasyon Master)',
          altBaslik: 'Merkez ofis veya deponuzun bulunduğu şehri listeden seçiniz (KSA & TR 50.250 Şehir Verisi Entegreli).',
          controller: _sehirController,
          label: 'Şehir',
          icon: Icons.location_city_rounded,
          onerilenListe: cityNames,
          nativeAdlar: nativeAdlar,
        );
      },
    );
  }

  Widget _adim6IlceSecimi() {
    final districts = AddressCatalog.getDistrictsByCity(_sehirController.text.trim());
    return _adresListeSecimAdimi(
      adimNo: 6,
      baslik: 'İlçe / Bölge Seçimi',
      altBaslik: 'Şehrinize bağlı ilçe veya belediyeyi listeden seçiniz.',
      controller: _ilceController,
      label: 'İlçe',
      icon: Icons.holiday_village_rounded,
      onerilenListe: districts.map((d) => d.name).toList(),
      nativeAdlar: {for (var d in districts) d.name: d.nativeName},
    );
  }

  Widget _adim7MahalleSecimi() {
    final neighborhoods = AddressCatalog.getNeighborhoodsByDistrict(_ilceController.text.trim());
    return _adresListeSecimAdimi(
      adimNo: 7,
      baslik: 'Mahalle / Semt Seçimi',
      altBaslik: 'Merkez adresin yer aldığı mahalleyi listeden seçiniz.',
      controller: _mahalleController,
      label: 'Mahalle',
      icon: Icons.signpost_rounded,
      onerilenListe: neighborhoods.map((n) => n.name).toList(),
      nativeAdlar: {for (var n in neighborhoods) n.name: 'PK: ${n.postalCode}'},
    );
  }

  Widget _adim8AdresDetay() {
    return _adimWrapper(
      title: '8. Açık Adres Detayı',
      subtitle: 'Cadde, sokak, bina numarası ve kapı bilgisini giriniz.',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  TextField(
                    controller: _acikAdresController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.home_work_rounded, color: hurmaKahvesi),
                      labelText: 'Cadde, Bina ve Kapı No',
                      hintText: 'Örn: Kral Fahd Cad. No: 142 Kat: 3 veya Fatih Cad. No: 12',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.auto_fix_high_rounded, size: 16, color: hurmaKahvesi),
                        label: const Text('Hızlı Adres Sihirbazından Doldur', style: TextStyle(color: hurmaKahvesi, fontSize: 12)),
                        onPressed: () async {
                          final res = await AddressPickerDialog.show(
                            context,
                            initialCountryCode: _currentCountryCode,
                            initialCity: _sehirController.text,
                            initialDistrict: _ilceController.text,
                          );
                          if (res != null) {
                            setState(() {
                              _bolgeController.text = res.region;
                              _sehirController.text = res.city;
                              _ilceController.text = res.district;
                              _mahalleController.text = res.neighborhood;
                              _acikAdresController.text = res.fullAddress;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9E6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: altinSarisi.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.location_city_rounded, size: 18, color: hurmaKahvesi),
                    SizedBox(width: 8),
                    Text('Seçilen Hiyerarşik Adres Özeti:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: hurmaKahvesi)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${_mahalleController.text.isNotEmpty ? "${_mahalleController.text}, " : ""}'
                  '${_ilceController.text.isNotEmpty ? "${_ilceController.text}, " : ""}'
                  '${_sehirController.text.isNotEmpty ? "${_sehirController.text}, " : ""}'
                  '${_bolgeController.text.isNotEmpty ? "${_bolgeController.text}, " : ""}'
                  '$_currentCountryCode',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _adresListeSecimAdimi({
    required int adimNo,
    required String baslik,
    required String altBaslik,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required List<String> onerilenListe,
    required Map<String, String> nativeAdlar,
    VoidCallback? onSecildi,
  }) {
    final currentValue = controller.text.trim();

    return _adimWrapper(
      title: '$adimNo. $baslik',
      subtitle: altBaslik,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seçili Değer & Arama / Manuel Yazma Kutusu
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      prefixIcon: Icon(icon, color: hurmaKahvesi),
                      labelText: label,
                      suffixIcon: controller.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                setState(() => controller.clear());
                              },
                            )
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'İpucu: Aşağıdaki hazır listeden tek tıkla seçebilir veya yukarıdaki alana serbest yazabilirsiniz.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Önerilen Liste Kartı
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.list_alt_rounded, color: hurmaKahvesi, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Hazır Listeden Seçiniz (${onerilenListe.length} Kayıt):',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: hurmaKahvesiKoyu),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  if (onerilenListe.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Bu seçim için tanımlı alt liste bulunamadı. Lütfen yukarıdaki alana manuel yazınız.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: onerilenListe.map((item) {
                        final isSelected = currentValue.toLowerCase() == item.toLowerCase();
                        final nativeName = nativeAdlar[item];

                        return ChoiceChip(
                          avatar: Icon(
                            isSelected ? Icons.check_circle_rounded : icon,
                            size: 16,
                            color: isSelected ? hurmaKahvesi : Colors.grey.shade600,
                          ),
                          label: Text(
                            nativeName != null && nativeName.isNotEmpty && nativeName != item
                                ? '$item ($nativeName)'
                                : item,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? hurmaKahvesiKoyu : Colors.black87,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: altinSarisi.withOpacity(0.28),
                          backgroundColor: Colors.grey.shade100,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                controller.text = item;
                              });
                              onSecildi?.call();
                            }
                          },
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

  // ── 9. SEKTÖRLER (MULTI-SELECT + ÖZEL SEKTÖR) ──
  Widget _adim9SektorlerSecimi() {
    return _adimWrapper(
      title: '9. Sektörünüzü / Sektörlerinizi Seçin (Multi-Select)',
      subtitle: 'NAKHL & NAHL çok sektörlü bir ERP\'dir. Faaliyet gösterdiğiniz tüm sektörleri işaretleyiniz.',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _allSectors.map((sector) {
              final isChecked = _selectedSectorCodes.contains(sector.code);

              return FilterChip(
                avatar: Icon(sector.icon, size: 18, color: isChecked ? hurmaKahvesi : Colors.grey),
                label: Text(sector.defaultName),
                selected: isChecked,
                selectedColor: altinSarisi.withOpacity(0.2),
                checkmarkColor: hurmaKahvesi,
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _selectedSectorCodes.add(sector.code);
                    } else if (_selectedSectorCodes.length > 1) {
                      _selectedSectorCodes.remove(sector.code);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          // ＋ Başka Sektör Ekle Butonu ve Formu
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: hurmaKahvesi.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ozelSektorController,
                    decoration: const InputDecoration(
                      hintText: 'Yeni Özel Sektör Adı (Örn: Güneş Enerjisi, Medikal)',
                      isDense: true,
                      border: InputBorder.none,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final name = _ozelSektorController.text.trim();
                    if (name.isNotEmpty) {
                      final newSec = await SectorService.instance.addCustomSector(
                        tenantId: '00000000-0000-0000-0000-000000000001',
                        name: name,
                      );
                      setState(() {
                        _allSectors.add(newSec);
                        _selectedSectorCodes.add(newSec.code);
                        _ozelSektorController.clear();
                      });
                    }
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Sektör Ekle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hurmaKahvesi,
                    foregroundColor: altinSarisi,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 10. ÜRÜN KATEGORİLERİ ──
  Widget _adim10UrunKategorileri() {
    return _adimWrapper(
      title: '10. Ürün Kategorileri',
      subtitle: 'Sektörlerinize bağlı başlangıç ürün kategorilerini düzenleyin veya yenilerini ekleyin.',
      content: Column(
        children: [
          ..._productCategories.map((cat) {
            return ListTile(
              leading: const Icon(Icons.folder_special_rounded, color: hurmaKahvesi),
              title: Text(cat, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                onPressed: () => setState(() => _productCategories.remove(cat)),
              ),
            );
          }),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _yeniKategoriController,
                  decoration: InputDecoration(
                    hintText: 'Yeni Kategori Adı...',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () {
                  final txt = _yeniKategoriController.text.trim();
                  if (txt.isNotEmpty) {
                    setState(() {
                      _productCategories.add(txt);
                      _yeniKategoriController.clear();
                    });
                  }
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Kategori Ekle'),
                style: ElevatedButton.styleFrom(backgroundColor: hurmaKahvesi, foregroundColor: altinSarisi),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 11. ÜRÜNLER (DİNAMİK + YENİ ÜRÜN EKLE) ──
  Widget _adim11Urunler() {
    return _adimWrapper(
      title: '11. Başlangıç Ürünleri (Dinamik Ürün Sistemi)',
      subtitle: 'Sisteme ilk ürünlerinizi tanımlayın. Hurma, bal, mobilya veya dilediğiniz her ürün desteklenir.',
      content: Column(
        children: [
          ..._dynamicProducts.map((p) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              color: Colors.white,
              child: ListTile(
                leading: const Icon(Icons.inventory_2_rounded, color: hurmaKahvesi),
                title: Text(p['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                subtitle: Text('Sektör: ${p['sector']} | Birim: ${p['unit']} | SKU: ${p['sku']}'),
                trailing: Text(p['grade'] ?? '', style: const TextStyle(color: altinSarisi, fontWeight: FontWeight.bold)),
              ),
            );
          }),
          const SizedBox(height: 16),
          Card(
            color: Colors.grey.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('＋ Hızlı Ürün Tanımla', style: TextStyle(fontWeight: FontWeight.bold, color: hurmaKahvesiKoyu)),
                  const SizedBox(height: 12),
                  TextField(controller: _urunAdiController, decoration: const InputDecoration(labelText: 'Ürün Adı', isDense: true)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _urunSkuController, decoration: const InputDecoration(labelText: 'SKU / Kod', isDense: true))),
                      const SizedBox(width: 10),
                      Expanded(child: TextField(controller: _urunBirimController, decoration: const InputDecoration(labelText: 'Birim (Kg, Koli, Adet)', isDense: true))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _urunAlisFiyatController, decoration: const InputDecoration(labelText: 'Alış Maliyeti', isDense: true))),
                      const SizedBox(width: 10),
                      Expanded(child: TextField(controller: _urunSatisFiyatController, decoration: const InputDecoration(labelText: 'Satış Fiyatı', isDense: true))),
                      const SizedBox(width: 10),
                      Expanded(child: TextField(controller: _urunMiktarController, decoration: const InputDecoration(labelText: 'Açılış Miktarı', isDense: true))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 12. KALİTE / SINIF & FİRE AYRIMI (MADDE 16) ──
  Widget _adim12KaliteVeFire() {
    return _adimWrapper(
      title: '12. Kalite Seviyeleri ve Fire / Kondisyon Ayrımı',
      subtitle: 'ÖNEMLİ: "Fire", bir kalite derecesi değildir; ayrı muhasebe ve stok etki statüsünde tutulur.',
      content: Column(
        children: [
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('1. Standart Kalite Sınıfları (Grades)', style: TextStyle(fontWeight: FontWeight.bold, color: hurmaKahvesiKoyu)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _secilenKaliteSinifi,
                    items: const [
                      DropdownMenuItem(value: 'PREMIUM', child: Text('Premium / VIP Seçme')),
                      DropdownMenuItem(value: 'FIRST_GRADE', child: Text('1. Sınıf Standart')),
                      DropdownMenuItem(value: 'SECOND_GRADE', child: Text('2. Sınıf')),
                      DropdownMenuItem(value: 'INDUSTRIAL', child: Text('Sanayi / Endüstriyel Sınıf')),
                    ],
                    onChanged: (val) => setState(() => _secilenKaliteSinifi = val ?? 'PREMIUM'),
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.amber.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('2. Ürün Kondisyonu ve Fire Statüsü (Conditions)', style: TextStyle(fontWeight: FontWeight.bold, color: hurmaKahvesiKoyu)),
                  const SizedBox(height: 4),
                  const Text('Fire, kusur ve hurda durumları normal stoktan ayrı muhasebeleştirilir.', style: TextStyle(fontSize: 11.5, color: Colors.black87)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _fireKondisyonTuru,
                    items: const [
                      DropdownMenuItem(value: 'FIRE_REJECT', child: Text('Fire / Depo-Üretim Kaybı (Gider Yazılır)')),
                      DropdownMenuItem(value: 'DEFECTIVE_CLASS_B', child: Text('Kusurlu Ürün (İskontolu Satılabilir)')),
                      DropdownMenuItem(value: 'EXPIRED_SCRAP', child: Text('Miadı Dolmuş Hurda (Maliyetten Düşülür)')),
                      DropdownMenuItem(value: 'BY_PRODUCT', child: Text('Yan Ürün / İşleme Artığı')),
                    ],
                    onChanged: (val) => setState(() => _fireKondisyonTuru = val ?? 'FIRE_REJECT'),
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 13. ŞİRKET BİLGİLERİ ──
  Widget _adim13SirketBilgileri() {
    return _adimWrapper(
      title: '13. Şirket ve Resmî Kayıt Bilgileri',
      subtitle: 'Ticari unvan, vergi kimlik numarası ve ana para birimi.',
      content: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              TextField(controller: _sirketAdiController, decoration: const InputDecoration(labelText: 'Şirket Kısa Adı', isDense: true)),
              const SizedBox(height: 12),
              TextField(controller: _ticariUnvanController, decoration: const InputDecoration(labelText: 'Resmî Ticari Unvan', isDense: true)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: _vknController, decoration: const InputDecoration(labelText: 'Vergi No / VKN', isDense: true))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: _vergiDairesiController, decoration: const InputDecoration(labelText: 'Vergi Dairesi', isDense: true))),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCurrency,
                items: const [
                  DropdownMenuItem(value: 'SAR', child: Text('SAR — Suudi Arabistan Riyali (﷼)')),
                  DropdownMenuItem(value: 'TRY', child: Text('TRY — Türk Lirası (₺)')),
                  DropdownMenuItem(value: 'USD', child: Text('USD — Amerikan Doları (\$)')),
                  DropdownMenuItem(value: 'EUR', child: Text('EUR — Euro (€)')),
                ],
                onChanged: (val) => setState(() => _selectedCurrency = val ?? 'SAR'),
                decoration: const InputDecoration(labelText: 'Ana Para Birimi', isDense: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 14. KULLANICI BİLGİLERİ ──
  Widget _adim14KullaniciBilgileri() {
    return _adimWrapper(
      title: '14. İlk Yönetici Kullanıcı Bilgileri',
      subtitle: 'Sisteme giriş yapacak kurucu yönetici bilgileri.',
      content: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: TextField(controller: _yetkiliAdController, decoration: const InputDecoration(labelText: 'Ad', isDense: true))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: _yetkiliSoyadController, decoration: const InputDecoration(labelText: 'Soyad', isDense: true))),
                ],
              ),
              const SizedBox(height: 12),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'E-Posta Adresi', isDense: true)),
              const SizedBox(height: 12),
              TextField(controller: _telefonController, decoration: const InputDecoration(labelText: 'Telefon Numarası', isDense: true)),
              const SizedBox(height: 12),
              TextField(
                controller: _pinController,
                obscureText: true,
                maxLength: 4,
                decoration: const InputDecoration(labelText: '4 Haneli Hızlı PIN Kodu', isDense: true, counterText: ''),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 15. ROL VE YETKİ ──
  Widget _adim15RolVeYetki() {
    return _adimWrapper(
      title: '15. Rol ve Yetkilendirme (RBAC)',
      subtitle: 'İlk kullanıcıya atanacak güvenlik rolünü seçiniz. (RLS güvenlik seviyesi)',
      content: Column(
        children: [
          RadioListTile<String>(
            value: 'Admin',
            groupValue: _selectedRole,
            activeColor: hurmaKahvesi,
            title: const Text('Sistem Yöneticisi (Admin)', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Tüm finansal, muhasebe, stok ve kullanıcı ayarlarına tam yetki.'),
            onChanged: (val) => setState(() => _selectedRole = val!),
          ),
          RadioListTile<String>(
            value: 'Muhasebe',
            groupValue: _selectedRole,
            activeColor: hurmaKahvesi,
            title: const Text('Mali İşler & Muhasebe', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Kasa, banka, fatura, cari hesaplar ve defter kayıtları yönetimi.'),
            onChanged: (val) => setState(() => _selectedRole = val!),
          ),
          RadioListTile<String>(
            value: 'DepoSorumlusu',
            groupValue: _selectedRole,
            activeColor: hurmaKahvesi,
            title: const Text('Depo ve Sevkiyat Sorumlusu', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Stok giriş/çıkış, parti/lot takibi ve lojistik sevkiyatlar.'),
            onChanged: (val) => setState(() => _selectedRole = val!),
          ),
        ],
      ),
    );
  }

  // ── 16. ÖZET VE BAŞLAT ──
  Widget _adim16OzetVeBaslat() {
    return _adimWrapper(
      title: '16. ERP Kurulum Özeti ve Açılış Bilançosu',
      subtitle: 'Tüm adımlar başarıyla tamamlandı. Aşağıdaki başlangıç bilançosu ile sistemi devreye alabilirsiniz.',
      content: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🏢 ${_sirketAdiController.text}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: hurmaKahvesiKoyu)),
              const SizedBox(height: 6),
              Text('🌐 Seçilen Diller: ${_selectedLanguages.join(", ").toUpperCase()} (Ana Dil: $_primaryLanguage-$_primaryScript)'),
              Text('📦 Faaliyet Sektörleri: ${_selectedSectorCodes.join(", ")}'),
              const Divider(height: 24),
              const Text('Açılış Bakiye Parametreleri:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: TextField(controller: _kasaBakiyeController, decoration: InputDecoration(labelText: 'Kasa Nakit ($_selectedCurrency)', isDense: true))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: _bankaBakiyeController, decoration: InputDecoration(labelText: 'Banka Mevduat ($_selectedCurrency)', isDense: true))),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: TextField(controller: _alacakController, decoration: InputDecoration(labelText: 'Alacaklar ($_selectedCurrency)', isDense: true))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: _borcController, decoration: InputDecoration(labelText: 'Borçlar ($_selectedCurrency)', isDense: true))),
                ],
              ),

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.green.shade200)),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.green, size: 24),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tüm veriler PostgreSQL RLS ve çift taraflı defter mimarisiyle canlı ortama kaydedilecektir.',
                        style: TextStyle(fontSize: 11.5, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
