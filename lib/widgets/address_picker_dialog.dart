// ==============================================================================
// NAKHL & NAHL — DİNAMİK LİSTE TABANLI ADRES SEÇİCİ (ADDRESS PICKER DIALOG)
// Ülke -> Bölge -> Şehir -> İlçe -> Mahalle Hiyerarşik Seçim Listesi
// Global Location Master (50.250 Şehir Verisi & KSA/TR Öncelikli Arama) Entegreli
// ==============================================================================

import 'package:flutter/material.dart';
import '../core/address/address_catalog.dart';
import '../models/location_master_model.dart';
import '../services/location_service.dart';

class AddressSelectionResult {
  final String countryCode;
  final String countryName;
  final String region;
  final String city;
  final String district;
  final String neighborhood;
  final String postalCode;
  final String fullAddress;

  const AddressSelectionResult({
    required this.countryCode,
    required this.countryName,
    required this.region,
    required this.city,
    required this.district,
    required this.neighborhood,
    required this.postalCode,
    required this.fullAddress,
  });
}

class AddressPickerDialog extends StatefulWidget {
  final String? initialCountryCode;
  final String? initialCity;
  final String? initialDistrict;

  const AddressPickerDialog({
    super.key,
    this.initialCountryCode,
    this.initialCity,
    this.initialDistrict,
  });

  static Future<AddressSelectionResult?> show(
    BuildContext context, {
    String? initialCountryCode,
    String? initialCity,
    String? initialDistrict,
  }) {
    return showModalBottomSheet<AddressSelectionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddressPickerDialog(
        initialCountryCode: initialCountryCode,
        initialCity: initialCity,
        initialDistrict: initialDistrict,
      ),
    );
  }

  @override
  State<AddressPickerDialog> createState() => _AddressPickerDialogState();
}

class _AddressPickerDialogState extends State<AddressPickerDialog> {
  static const Color hurmaKahvesi = Color(0xFF5C4033);
  static const Color altinSarisi = Color(0xFFD4AF37);

  List<CountryMasterModel> _countries = [];
  List<CityMasterModel> _availableCities = [];
  bool _isLoadingCountries = true;
  bool _isLoadingCities = false;

  late String _selectedCountryCode;
  String _selectedRegion = '';
  String _selectedCity = '';
  String _selectedDistrict = '';
  String _selectedNeighborhood = '';
  final TextEditingController _sokakBinaController = TextEditingController();
  final TextEditingController _citySearchController = TextEditingController();
  final TextEditingController _customDistrictController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedCountryCode = widget.initialCountryCode ?? 'SA';
    _selectedCity = widget.initialCity ?? '';
    _selectedDistrict = widget.initialDistrict ?? '';
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final countries = await LocationService.instance.getCountries();
    if (mounted) {
      setState(() {
        _countries = countries;
        _isLoadingCountries = false;
      });
      _loadCities();
    }
  }

  Future<void> _loadCities([String query = '']) async {
    setState(() => _isLoadingCities = true);
    final cities = await LocationService.instance.searchCities(
      _selectedCountryCode,
      query,
      limit: 30,
    );
    if (mounted) {
      setState(() {
        _availableCities = cities;
        _isLoadingCities = false;
      });
    }
  }

  @override
  void dispose() {
    _sokakBinaController.dispose();
    _citySearchController.dispose();
    _customDistrictController.dispose();
    super.dispose();
  }

  List<AddressRegion> get _availableRegions =>
      AddressCatalog.getRegionsByCountry(_selectedCountryCode);

  List<AddressDistrict> get _catalogDistricts =>
      AddressCatalog.getDistrictsByCity(_selectedCity);

  List<AddressNeighborhood> get _catalogNeighborhoods =>
      AddressCatalog.getNeighborhoodsByDistrict(_selectedDistrict);

  String get _currentCountryName {
    try {
      final match = _countries.firstWhere(
        (c) => c.iso2 == _selectedCountryCode,
      );
      return match.countryNameTr.isNotEmpty ? match.countryNameTr : match.countryName;
    } catch (_) {
      return _selectedCountryCode;
    }
  }

  String _generateFullAddress() {
    final parts = <String>[];
    if (_sokakBinaController.text.trim().isNotEmpty) {
      parts.add(_sokakBinaController.text.trim());
    }
    if (_selectedNeighborhood.isNotEmpty) {
      parts.add(_selectedNeighborhood);
    }
    final activeDistrict = _selectedDistrict.isNotEmpty
        ? _selectedDistrict
        : _customDistrictController.text.trim();
    if (activeDistrict.isNotEmpty) {
      parts.add(activeDistrict);
    }
    if (_selectedCity.isNotEmpty) {
      parts.add(_selectedCity);
    }
    if (_selectedRegion.isNotEmpty &&
        !_selectedRegion.toLowerCase().contains(_selectedCity.toLowerCase())) {
      parts.add(_selectedRegion);
    }
    parts.add(_currentCountryName);
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Başlık Çubuğu
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: hurmaKahvesi,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded, color: altinSarisi, size: 24),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Adres & Lokasyon Seçimi (Global Master)',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // İçerik
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. ÜLKE LİSTESİ
                  const Text('1. Ülke Seçimi (KSA & Türkiye Öncelikli)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: hurmaKahvesi)),
                  const SizedBox(height: 8),
                  if (_isLoadingCountries)
                    const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _countries.take(12).map((c) {
                        final isSelected = _selectedCountryCode == c.iso2;
                        return ChoiceChip(
                          avatar: Text(c.flag, style: const TextStyle(fontSize: 16)),
                          label: Text('${c.countryNameTr} (${c.iso2})'),
                          selected: isSelected,
                          selectedColor: altinSarisi.withOpacity(0.3),
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                _selectedCountryCode = c.iso2;
                                _selectedRegion = '';
                                _selectedCity = '';
                                _selectedDistrict = '';
                                _selectedNeighborhood = '';
                                _citySearchController.clear();
                              });
                              _loadCities();
                            }
                          },
                        );
                      }).toList(),
                    ),
                  const Divider(height: 28),

                  // 2. BÖLGE / EYALET LİSTESİ (Varsa)
                  if (_availableRegions.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('2. Bölge / İdari Bölge',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: hurmaKahvesi)),
                        if (_selectedRegion.isNotEmpty)
                          TextButton(
                            onPressed: () => setState(() => _selectedRegion = ''),
                            child: const Text('Temizle', style: TextStyle(fontSize: 11, color: Colors.red)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableRegions.map((r) {
                        final isSelected = _selectedRegion == r.name;
                        return ActionChip(
                          avatar: Icon(Icons.map_outlined, size: 16, color: isSelected ? hurmaKahvesi : Colors.grey),
                          label: Text('${r.name} (${r.nativeName})'),
                          backgroundColor: isSelected ? altinSarisi.withOpacity(0.3) : Colors.grey.shade100,
                          onPressed: () {
                            setState(() {
                              _selectedRegion = r.name;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const Divider(height: 28),
                  ],

                  // 3. ŞEHİR LİSTESİ & ARAMA (50.250 ŞEHİR LOKASYON MASTER)
                  Row(
                    children: [
                      const Text('3. Şehir Seçimi & Arama',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: hurmaKahvesi)),
                      const Spacer(),
                      if (_selectedCity.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Text('Seçilen: $_selectedCity',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Şehir Arama Kutusu
                  TextField(
                    controller: _citySearchController,
                    onChanged: (val) => _loadCities(val),
                    decoration: InputDecoration(
                      hintText: 'Şehir ara (Örn: Riyadh, Jeddah, Mekke, İstanbul, Ankara...)',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _citySearchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _citySearchController.clear();
                                _loadCities();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (_isLoadingCities)
                    const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
                  else if (_availableCities.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('Aranan kriterde şehir bulunamadı. Şehir adını serbest olarak ekleyebilirsiniz.',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableCities.map((c) {
                        final isSelected = _selectedCity == c.cityName || _selectedCity == c.cityNameAscii;
                        return ChoiceChip(
                          avatar: Icon(Icons.location_city_rounded, size: 16, color: isSelected ? hurmaKahvesi : Colors.grey),
                          label: Text(
                            c.adminName.isNotEmpty && c.adminName != c.cityName
                                ? '${c.cityName} (${c.adminName})'
                                : c.cityName,
                          ),
                          selected: isSelected,
                          selectedColor: altinSarisi.withOpacity(0.3),
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                _selectedCity = c.cityName;
                                if (_selectedRegion.isEmpty && c.adminName.isNotEmpty) {
                                  _selectedRegion = c.adminName;
                                }
                                _selectedDistrict = '';
                                _selectedNeighborhood = '';
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                  const Divider(height: 28),

                  // 4. İLÇE / BÖLGE LİSTESİ
                  if (_catalogDistricts.isNotEmpty) ...[
                    const Text('4. İlçe / Bölge Listesi',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: hurmaKahvesi)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _catalogDistricts.map((d) {
                        final isSelected = _selectedDistrict == d.name;
                        return ChoiceChip(
                          avatar: Icon(Icons.holiday_village_rounded, size: 16, color: isSelected ? hurmaKahvesi : Colors.grey),
                          label: Text('${d.name} (${d.nativeName})'),
                          selected: isSelected,
                          selectedColor: altinSarisi.withOpacity(0.3),
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                _selectedDistrict = d.name;
                                _selectedNeighborhood = '';
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const Divider(height: 28),
                  ] else ...[
                    const Text('4. İlçe / Semt (İsteğe Bağlı)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: hurmaKahvesi)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _customDistrictController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Örn: Olaya, Kadıköy, Nilüfer, vb.',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.holiday_village_outlined),
                      ),
                    ),
                    const Divider(height: 28),
                  ],

                  // 5. MAHALLE LİSTESİ (Varsa)
                  if (_catalogNeighborhoods.isNotEmpty) ...[
                    const Text('5. Mahalle Listesi',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: hurmaKahvesi)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _catalogNeighborhoods.map((n) {
                        final isSelected = _selectedNeighborhood == n.name;
                        return ChoiceChip(
                          avatar: Icon(Icons.signpost_rounded, size: 16, color: isSelected ? hurmaKahvesi : Colors.grey),
                          label: Text('${n.name} (PK: ${n.postalCode})'),
                          selected: isSelected,
                          selectedColor: altinSarisi.withOpacity(0.3),
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                _selectedNeighborhood = n.name;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const Divider(height: 28),
                  ],

                  // 6. SOKAK & BİNA NO
                  const Text('6. Cadde / Sokak / Bina / Kapı No',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: hurmaKahvesi)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _sokakBinaController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Örn: Kral Fahd Cad. No: 142 Kat: 3 veya Atatürk Bulvarı No: 54',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.home_work_outlined),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Önizleme Kutusu
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: altinSarisi.withOpacity(0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.check_circle_outline_rounded, size: 18, color: hurmaKahvesi),
                            SizedBox(width: 8),
                            Text('Oluşturulan Yapılandırılmış Adres:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: hurmaKahvesi)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _generateFullAddress().isEmpty ? 'Henüz seçim yapılmadı.' : _generateFullAddress(),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Onay Butonu
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hurmaKahvesi,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.check_rounded, color: altinSarisi),
                      label: const Text('Bu Adresi Kullan ve Aktar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        final effectiveDistrict = _selectedDistrict.isNotEmpty
                            ? _selectedDistrict
                            : _customDistrictController.text.trim();

                        String postalCode = '';
                        if (_selectedNeighborhood.isNotEmpty && _catalogNeighborhoods.isNotEmpty) {
                          final match = _catalogNeighborhoods.firstWhere(
                            (n) => n.name == _selectedNeighborhood,
                            orElse: () => const AddressNeighborhood(districtName: '', name: '', postalCode: ''),
                          );
                          postalCode = match.postalCode;
                        }

                        Navigator.of(context).pop(
                          AddressSelectionResult(
                            countryCode: _selectedCountryCode,
                            countryName: _currentCountryName,
                            region: _selectedRegion,
                            city: _selectedCity,
                            district: effectiveDistrict,
                            neighborhood: _selectedNeighborhood,
                            postalCode: postalCode,
                            fullAddress: _generateFullAddress(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
