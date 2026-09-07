import 'package:flutter/material.dart';
import '../../core/tenant/tenant_context.dart';
import '../../core/i18n/locale_script_manager.dart';
import '../../models/user_preferences_model.dart';
import '../../services/user_preferences_service.dart';
import '../../services/auth_service.dart';

class UserParametersScreen extends StatefulWidget {
  const UserParametersScreen({super.key});

  @override
  State<UserParametersScreen> createState() => _UserParametersScreenState();
}

class _UserParametersScreenState extends State<UserParametersScreen> {
  // Kurumsal Renk Paleti
  static const Color hurmaKahvesi = Color(0xFF5C4033);
  static const Color hurmaKahvesiKoyu = Color(0xFF3E2723);
  static const Color kremArkaplan = Color(0xFFFBF9F1);
  static const Color altinSarisi = Color(0xFFC89033);

  bool _isLoading = true;
  late UserPreferencesModel _preferences;

  // Form Seçimleri
  late String _primaryLang;
  late String _primaryScript;
  String? _secondaryLang;
  String? _secondaryScript;
  String? _tertiaryLang;
  String? _tertiaryScript;
  late String _direction;
  late String _dateFormat;
  late String _numberFormat;
  late String _currencyDisplayMode;

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    final userId = TenantContext.instance.userId ?? AuthService.instance.aktifProfil?.uid ?? 'guest-user';
    final tenantId = TenantContext.instance.activeTenantId ?? 'default-tenant';

    final prefs = await UserPreferencesService.instance.loadPreferences(
      userId: userId,
      tenantId: tenantId,
    );

    setState(() {
      _preferences = prefs;
      _primaryLang = prefs.primaryLanguageCode;
      _primaryScript = prefs.primaryScriptCode;
      _secondaryLang = prefs.secondaryLanguageCode;
      _secondaryScript = prefs.secondaryScriptCode;
      _tertiaryLang = prefs.tertiaryLanguageCode;
      _tertiaryScript = prefs.tertiaryScriptCode;
      _direction = prefs.textDirection;
      _dateFormat = prefs.dateFormat;
      _numberFormat = prefs.numberFormat;
      _currencyDisplayMode = prefs.currencyDisplayMode;
      _isLoading = false;
    });
  }

  Future<void> _savePreferences() async {
    setState(() => _isLoading = true);

    final updated = _preferences.copyWith(
      primaryLanguageCode: _primaryLang,
      primaryScriptCode: _primaryScript,
      secondaryLanguageCode: _secondaryLang,
      secondaryScriptCode: _secondaryScript,
      tertiaryLanguageCode: _tertiaryLang,
      tertiaryScriptCode: _tertiaryScript,
      activeLocaleId: '$_primaryLang-$_primaryScript',
      textDirection: _direction,
      dateFormat: _dateFormat,
      numberFormat: _numberFormat,
      currencyDisplayMode: _currencyDisplayMode,
    );

    await UserPreferencesService.instance.savePreferences(updated);

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Kullanıcı parametreleri başarıyla güncellendi.'),
          backgroundColor: hurmaKahvesiKoyu,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: context.direction,
      child: Scaffold(
        backgroundColor: kremArkaplan,
        appBar: AppBar(
          backgroundColor: hurmaKahvesi,
          foregroundColor: Colors.white,
          title: Text(
            context.tr('menu.user_parameters', fallback: 'Kullanıcı Parametreleri'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          actions: [
            if (!_isLoading)
              IconButton(
                icon: const Icon(Icons.check_rounded, color: altinSarisi),
                tooltip: 'Kaydet',
                onPressed: _savePreferences,
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: hurmaKahvesi))
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // 1. Bilgilendirme Kartı
                  _buildSecurityInfoBanner(),
                  const SizedBox(height: 18),

                  // 2. Çok Dilli ve Çok Alfabeli Dil Tercihleri
                  _buildSectionHeader(
                    '🌐 Dil ve Alfabe (Language ≠ Script)',
                    'Arayüz dilinizi ve alfabenizi bağımsız olarak özelleştirin (Maksimum 3 dil)',
                  ),
                  const SizedBox(height: 12),
                  _buildLanguageAndScriptCard(),
                  const SizedBox(height: 24),

                  // 3. Yazı Yönü ve Tipografi
                  _buildSectionHeader(
                    '📐 Yazı Yönü & Tipografi',
                    'RTL (Sağdan Sola) / LTR ve dinamik yazı boyutu optimizasyonu',
                  ),
                  const SizedBox(height: 12),
                  _buildTypographyCard(),
                  const SizedBox(height: 24),

                  // 4. Biçimlendirme & Görüntüleme Formatları
                  _buildSectionHeader(
                    '📅 Tarih, Sayı ve Para Formatı',
                    'Bölgesel muhasebe ve raporlama görüntüleme formatları',
                  ),
                  const SizedBox(height: 12),
                  _buildFormattingCard(),
                  const SizedBox(height: 32),

                  // Kaydet Butonu
                  ElevatedButton.icon(
                    onPressed: _savePreferences,
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Tercihlerimi Kaydet & Uygula'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hurmaKahvesi,
                      foregroundColor: altinSarisi,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSecurityInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: const Row(
        children: [
          Icon(Icons.shield_outlined, color: hurmaKahvesi, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kişiselleştirilmiş Kullanıcı Alanı',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: hurmaKahvesiKoyu),
                ),
                SizedBox(height: 2),
                Text(
                  'Buradaki ayarlar yalnızca sizin kullanıcı arayüzünüzü etkiler. Şirket yetkileri ve RLS güvenliği PostgreSQL tarafından korunur.',
                  style: TextStyle(fontSize: 11, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: hurmaKahvesiKoyu,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
      ],
    );
  }

  Widget _buildLanguageAndScriptCard() {
    final catalog = LocaleScriptManager.languagesCatalog;

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            // 1. Ana Dil
            _buildDropdownRow(
              title: '1. Ana Dil (Zorunlu)',
              value: _primaryLang,
              items: catalog.keys.map((k) {
                final l = catalog[k]!;
                return DropdownMenuItem(value: k, child: Text('${l.nativeName} (${l.englishName})'));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _primaryLang = val;
                    final allowed = catalog[val]?.supportedScriptCodes ?? ['Latn'];
                    if (!allowed.contains(_primaryScript)) {
                      _primaryScript = allowed.first;
                    }
                    _direction = (_primaryScript == 'Arab') ? 'rtl' : 'ltr';
                  });
                }
              },
            ),
            const SizedBox(height: 10),

            // 1. Ana Dil Alfabesi
            _buildDropdownRow(
              title: '1. Dil Alfabesi (Script)',
              value: _primaryScript,
              items: (catalog[_primaryLang]?.supportedScriptCodes ?? ['Latn']).map((s) {
                final sc = LocaleScriptManager.scriptsCatalog[s];
                return DropdownMenuItem(value: s, child: Text(sc?.name ?? s));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _primaryScript = val;
                    _direction = (val == 'Arab') ? 'rtl' : 'ltr';
                  });
                }
              },
            ),
            const Divider(height: 28),

            // 2. İkincil Dil (Opsiyonel)
            _buildDropdownRow(
              title: '2. Alternatif Dil (İsteğe Bağlı)',
              value: _secondaryLang,
              isOptional: true,
              items: [
                const DropdownMenuItem(value: null, child: Text('(Seçilmedi)')),
                ...catalog.keys.map((k) {
                  final l = catalog[k]!;
                  return DropdownMenuItem(value: k, child: Text('${l.nativeName} (${l.englishName})'));
                }),
              ],
              onChanged: (val) {
                setState(() {
                  _secondaryLang = val;
                  if (val != null) {
                    _secondaryScript = catalog[val]?.supportedScriptCodes.first;
                  } else {
                    _secondaryScript = null;
                  }
                });
              },
            ),
            const Divider(height: 28),

            // 3. Üçüncül Dil (Opsiyonel)
            _buildDropdownRow(
              title: '3. Alternatif Dil (İsteğe Bağlı)',
              value: _tertiaryLang,
              isOptional: true,
              items: [
                const DropdownMenuItem(value: null, child: Text('(Seçilmedi)')),
                ...catalog.keys.map((k) {
                  final l = catalog[k]!;
                  return DropdownMenuItem(value: k, child: Text('${l.nativeName} (${l.englishName})'));
                }),
              ],
              onChanged: (val) {
                setState(() {
                  _tertiaryLang = val;
                  if (val != null) {
                    _tertiaryScript = catalog[val]?.supportedScriptCodes.first;
                  } else {
                    _tertiaryScript = null;
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypographyCard() {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.format_textdirection_l_to_r_rounded, color: hurmaKahvesi),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Yazı Yönü (Directionality)',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'ltr', label: Text('LTR (Soldan)')),
                    ButtonSegment(value: 'rtl', label: Text('RTL (Sağdan)')),
                  ],
                  selected: {_direction},
                  onSelectionChanged: (val) {
                    setState(() => _direction = val.first);
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.text_fields_rounded, size: 20, color: Colors.grey),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _primaryScript == 'Arab'
                          ? 'Arapça tabanlı alfabelerde okunabilirlik için 15.5px taban yazı boyutu ve geniş satır aralığı otomatik devrededir.'
                          : 'Latin alfabesinde kompakt kurumsal düzen için 13px taban yazı boyutu devrededir.',
                      style: const TextStyle(fontSize: 11, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormattingCard() {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _buildDropdownRow(
              title: 'Tarih Formatı',
              value: _dateFormat,
              items: const [
                DropdownMenuItem(value: 'DD/MM/YYYY', child: Text('DD/MM/YYYY (Örn: 07/09/2026)')),
                DropdownMenuItem(value: 'YYYY-MM-DD', child: Text('YYYY-MM-DD (Örn: 2026-09-07)')),
                DropdownMenuItem(value: 'DD.MM.YYYY', child: Text('DD.MM.YYYY (Örn: 07.09.2026)')),
              ],
              onChanged: (val) => setState(() => _dateFormat = val ?? 'DD/MM/YYYY'),
            ),
            const Divider(height: 24),
            _buildDropdownRow(
              title: 'Sayı Formatı',
              value: _numberFormat,
              items: const [
                DropdownMenuItem(value: '#,##0.00', child: Text('1,234.56 (Virgül binlik, nokta kuruş)')),
                DropdownMenuItem(value: '#.##0,00', child: Text('1.234,56 (Nokta binlik, virgül kuruş)')),
                DropdownMenuItem(value: '#0.00', child: Text('1234.56 (Ayraçsız)')),
              ],
              onChanged: (val) => setState(() => _numberFormat = val ?? '#,##0.00'),
            ),
            const Divider(height: 24),
            _buildDropdownRow(
              title: 'Para Birimi Gösterimi',
              value: _currencyDisplayMode,
              items: const [
                DropdownMenuItem(value: 'SYMBOL', child: Text('Sembol ile (﷼, ₺, \$, €)')),
                DropdownMenuItem(value: 'CODE', child: Text('ISO Kodu ile (SAR, TRY, USD, EUR)')),
                DropdownMenuItem(value: 'NAME', child: Text('Tam Adı ile (Riyal, Türk Lirası)')),
              ],
              onChanged: (val) => setState(() => _currencyDisplayMode = val ?? 'SYMBOL'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownRow<T>({
    required String title,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    bool isOptional = false,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: hurmaKahvesiKoyu),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 6,
          child: DropdownButtonFormField<T>(
            value: value,
            items: items,
            onChanged: onChanged,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }
}
