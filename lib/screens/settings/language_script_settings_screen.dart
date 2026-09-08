import 'package:flutter/material.dart';
import '../../core/i18n/locale_script_manager.dart';
import '../../core/theme/app_theme_tokens.dart';
import '../../core/accessibility/accessibility_manager.dart';

class LanguageScriptSettingsScreen extends StatefulWidget {
  const LanguageScriptSettingsScreen({super.key});

  @override
  State<LanguageScriptSettingsScreen> createState() =>
      _LanguageScriptSettingsScreenState();
}

class _LanguageScriptSettingsScreenState
    extends State<LanguageScriptSettingsScreen> {
  late String _primaryLang;
  late String _primaryScript;
  String? _secondaryLang;
  String? _secondaryScript;
  String? _tertiaryLang;
  String? _tertiaryScript;
  late DisplayMode _displayMode;
  late bool _enableRomanization;
  late AppThemeMode _selectedTheme;
  late FontSizeProfile _fontSize;
  late bool _largerControls;
  late bool _reducedMotion;

  @override
  void initState() {
    super.initState();
    final locManager = LocaleScriptManager.instance;
    _primaryLang = locManager.primaryLanguage;
    _primaryScript = locManager.primaryScript;
    _secondaryLang = locManager.secondaryLanguage;
    _secondaryScript = locManager.secondaryScript;
    _tertiaryLang = locManager.tertiaryLanguage;
    _tertiaryScript = locManager.tertiaryScript;
    _displayMode = locManager.displayMode;
    _enableRomanization = locManager.enableArabicRomanization;

    _selectedTheme = AppThemeManager.instance.currentMode;
    _fontSize = AccessibilityManager.instance.fontSizeProfile;
    _largerControls = AccessibilityManager.instance.largerControls;
    _reducedMotion = AccessibilityManager.instance.reducedMotion;
  }

  void _applySettings() {
    final locManager = LocaleScriptManager.instance;
    locManager.configureUserLanguages(
      primaryLanguage: _primaryLang,
      primaryScript: _primaryScript,
      secondaryLanguage: _secondaryLang,
      secondaryScript: _secondaryScript,
      tertiaryLanguage: _tertiaryLang,
      tertiaryScript: _tertiaryScript,
    );

    locManager.setDisplayMode(_displayMode);
    locManager.setArabicRomanization(_enableRomanization);

    AppThemeManager.instance.setTheme(_selectedTheme);

    final a11y = AccessibilityManager.instance;
    a11y.setFontSizeProfile(_fontSize);
    a11y.setLargerControls(_largerControls);
    a11y.setReducedMotion(_reducedMotion);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Ayarlar anında uygulandı. Yeniden başlatma gerekmez.'),
        backgroundColor: Color(0xFF10B981),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeManager.instance.tokens;
    final locManager = LocaleScriptManager.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dil, Alfabe ve Arayüz Tercihleri'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: ElevatedButton.icon(
              onPressed: _applySettings,
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Uygula & Kaydet'),
            ),
          ),
        ],
      ),
      body: Directionality(
        textDirection: locManager.direction,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            // 1. Çoklu Dil ve Alfabe Seçimi
            _buildSectionCard(
              title: '1. Çok Dilli Hiyerarşi & Alfabe (Script) Seçimi',
              description:
                  'Birincil dil tüm arayüzün temelini belirler. İkincil ve üçüncül diller hibrit görünümde eş zamanlı gösterilir.',
              tokens: tokens,
              child: Column(
                children: [
                  _buildLanguagePicker(
                    label: 'Birincil Dil (Primary Language)',
                    currentLang: _primaryLang,
                    currentScript: _primaryScript,
                    isPrimary: true,
                    onChanged: (lang, script) {
                      setState(() {
                        _primaryLang = lang;
                        _primaryScript = script;
                      });
                    },
                  ),
                  const Divider(height: 24),
                  _buildLanguagePicker(
                    label: 'İkincil Dil (Secondary Language — Opsiyonel)',
                    currentLang: _secondaryLang,
                    currentScript: _secondaryScript,
                    isPrimary: false,
                    onChanged: (lang, script) {
                      setState(() {
                        _secondaryLang = lang;
                        _secondaryScript = script;
                      });
                    },
                  ),
                  const Divider(height: 24),
                  _buildLanguagePicker(
                    label: 'Üçüncül Dil (Tertiary Language — Opsiyonel)',
                    currentLang: _tertiaryLang,
                    currentScript: _tertiaryScript,
                    isPrimary: false,
                    onChanged: (lang, script) {
                      setState(() {
                        _tertiaryLang = lang;
                        _tertiaryScript = script;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Hibrit Görünüm ve AR-LAT Ayarları
            _buildSectionCard(
              title: '2. Hibrit Görünüm & AR-LAT (Latinize Arapça)',
              description:
                  'Tek dil modunda yalnızca ana dil; hibrit modda ise birden çok dil hiyerarşik kartlarda birlikte sunulur.',
              tokens: tokens,
              child: Column(
                children: [
                  RadioListTile<DisplayMode>(
                    value: DisplayMode.singleLanguage,
                    groupValue: _displayMode,
                    title: const Text('Tek Dil Görünümü (Single Language)'),
                    subtitle: const Text('Arayüz yalnızca seçili birincil dili kullanır.'),
                    onChanged: (val) {
                      if (val != null) setState(() => _displayMode = val);
                    },
                  ),
                  RadioListTile<DisplayMode>(
                    value: DisplayMode.multilingualHybrid,
                    groupValue: _displayMode,
                    title: const Text('Çokdilli Hibrit Görünüm (Multilingual Hybrid)'),
                    subtitle: const Text(
                        'Başlık ve butonlarda: Ana dil (Büyük) + İkincil dil (Küçük) + Üçüncül dil (Daha küçük).'),
                    onChanged: (val) {
                      if (val != null) setState(() => _displayMode = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  // Canlı Önizleme Kutusu
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: tokens.surfaceVariant,
                      borderRadius: BorderRadius.circular(tokens.borderRadius),
                      border: Border.all(color: tokens.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Örnek Hibrit Önizleme:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: tokens.textMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Satış Faturası',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: tokens.textPrimary,
                          ),
                        ),
                        Text(
                          'فاتورة المبيعات',
                          style: TextStyle(
                            fontSize: 13,
                            color: tokens.textSecondary,
                            fontFamily: 'Amiri',
                          ),
                        ),
                        Text(
                          'Fatoorat Al-Mabee\'aat',
                          style: TextStyle(
                            fontSize: 11,
                            color: tokens.textMuted,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 24),
                  SwitchListTile(
                    value: _enableRomanization,
                    title: const Text('Arapça Latinizasyon (AR-LAT Engine)'),
                    subtitle: const Text(
                        'Arapça terimlerin fonetik Latin harfli karşılıklarını (AR-LAT) otomatik oluştur ve öner.'),
                    onChanged: (val) => setState(() => _enableRomanization = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. Tema Seçimi
            _buildSectionCard(
              title: '3. Kurumsal ERP Renk Teması',
              description: 'İşletmenizin kurumsal kimliğine ve ışık koşullarına uygun tema paleti.',
              tokens: tokens,
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: AppThemeMode.values.map((mode) {
                  final t = AppThemeTokens.tokensMap[mode]!;
                  final isSelected = _selectedTheme == mode;
                  return InkWell(
                    onTap: () => setState(() => _selectedTheme = mode),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 220,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: t.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? t.primary : t.border,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: t.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  t.displayName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: t.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _colorPip(t.background),
                              const SizedBox(width: 4),
                              _colorPip(t.surfaceVariant),
                              const SizedBox(width: 4),
                              _colorPip(t.success),
                              const SizedBox(width: 4),
                              _colorPip(t.info),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // 4. Erişilebilirlik ve Okunabilirlik
            _buildSectionCard(
              title: '4. Erişilebilirlik & Okunabilirlik',
              description: 'Göz yorgunluğunu azaltan font boyutları ve geniş dokunma hedefleri.',
              tokens: tokens,
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('Yazı Tipi Boyutu:'),
                      const SizedBox(width: 16),
                      DropdownButton<FontSizeProfile>(
                        value: _fontSize,
                        items: FontSizeProfile.values.map((p) {
                          return DropdownMenuItem(
                            value: p,
                            child: Text(p.label),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _fontSize = val);
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  SwitchListTile(
                    value: _largerControls,
                    title: const Text('Geniş Dokunma Alanları (Min 48px Touch Targets)'),
                    subtitle: const Text('Buton ve giriş alanlarını tablet ve dokunmatik ekranlar için büyüt.'),
                    onChanged: (val) => setState(() => _largerControls = val),
                  ),
                  SwitchListTile(
                    value: _reducedMotion,
                    title: const Text('Hareketi Azalt (Reduced Motion)'),
                    subtitle: const Text('Gereksiz animasyonları kapatarak performansı ve odaklanmayı artır.'),
                    onChanged: (val) => setState(() => _reducedMotion = val),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguagePicker({
    required String label,
    required String? currentLang,
    required String? currentScript,
    required bool isPrimary,
    required void Function(String lang, String script) onChanged,
  }) {
    final tokens = AppThemeManager.instance.tokens;
    final availableLangs = LocaleScriptManager.languagesCatalog;

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: tokens.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: currentLang,
                decoration: const InputDecoration(isDense: true),
                items: [
                  if (!isPrimary)
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Yok / Devre Dışı'),
                    ),
                  ...availableLangs.entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text('${entry.value.nativeName} (${entry.key.toUpperCase()})'),
                    );
                  }),
                ],
                onChanged: (newLang) {
                  if (newLang == null) {
                    onChanged('', '');
                  } else {
                    final defaultScript = availableLangs[newLang]?.supportedScriptCodes.first ?? 'Latn';
                    onChanged(newLang, defaultScript);
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Alfabe (Script)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: tokens.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: currentScript,
                decoration: const InputDecoration(isDense: true),
                items: (currentLang != null && availableLangs.containsKey(currentLang))
                    ? availableLangs[currentLang]!.supportedScriptCodes.map((s) {
                        final scriptObj = LocaleScriptManager.scriptsCatalog[s];
                        return DropdownMenuItem(
                          value: s,
                          child: Text(scriptObj?.name ?? s),
                        );
                      }).toList()
                    : const [
                        DropdownMenuItem(value: 'Latn', child: Text('Latin')),
                      ],
                onChanged: (newScript) {
                  if (newScript != null && currentLang != null) {
                    onChanged(currentLang, newScript);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String description,
    required AppThemeTokens tokens,
    required Widget child,
  }) {
    return Card(
      elevation: tokens.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.borderRadius),
        side: BorderSide(color: tokens.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: tokens.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _colorPip(Color color) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.black26, width: 0.5),
      ),
    );
  }
}
