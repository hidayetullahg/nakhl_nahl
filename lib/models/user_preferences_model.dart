/// Kullanıcı Parametreleri ve Tercihleri Modeli
class UserPreferencesModel {
  final String id;
  final String userId;
  final String tenantId;
  final String primaryLanguageCode; // tr, ar, en, ug, ur, fa, etc.
  final String primaryScriptCode; // Latn, Arab, Deva, etc.
  final String? secondaryLanguageCode;
  final String? secondaryScriptCode;
  final String? tertiaryLanguageCode;
  final String? tertiaryScriptCode;
  final String activeLocaleId; // tr-Latn, ar-Arab, ug-Arab, etc.
  final String textDirection; // ltr, rtl
  final String typographyScale; // standard, large, compact
  final String dateFormat; // DD/MM/YYYY, YYYY-MM-DD, etc.
  final String numberFormat; // #,##0.00, etc.
  final String currencyDisplayMode; // SYMBOL, CODE, NAME
  final String? defaultCompanyId;
  final String? defaultBranchId;
  final String? defaultWarehouseId;
  final String defaultWorkspace;
  final Map<String, dynamic> menuPreferences;

  const UserPreferencesModel({
    required this.id,
    required this.userId,
    required this.tenantId,
    this.primaryLanguageCode = 'tr',
    this.primaryScriptCode = 'Latn',
    this.secondaryLanguageCode,
    this.secondaryScriptCode,
    this.tertiaryLanguageCode,
    this.tertiaryScriptCode,
    this.activeLocaleId = 'tr-Latn',
    this.textDirection = 'ltr',
    this.typographyScale = 'standard',
    this.dateFormat = 'DD/MM/YYYY',
    this.numberFormat = '#,##0.00',
    this.currencyDisplayMode = 'SYMBOL',
    this.defaultCompanyId,
    this.defaultBranchId,
    this.defaultWarehouseId,
    this.defaultWorkspace = 'DASHBOARD',
    this.menuPreferences = const {},
  });

  bool get isRtl => textDirection.toLowerCase() == 'rtl';

  factory UserPreferencesModel.fromMap(Map<String, dynamic> map) {
    return UserPreferencesModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      tenantId: map['tenant_id']?.toString() ?? '',
      primaryLanguageCode: map['primary_language_code']?.toString() ?? 'tr',
      primaryScriptCode: map['primary_script_code']?.toString() ?? 'Latn',
      secondaryLanguageCode: map['secondary_language_code']?.toString(),
      secondaryScriptCode: map['secondary_script_code']?.toString(),
      tertiaryLanguageCode: map['tertiary_language_code']?.toString(),
      tertiaryScriptCode: map['tertiary_script_code']?.toString(),
      activeLocaleId: map['active_locale_id']?.toString() ?? 'tr-Latn',
      textDirection: map['text_direction']?.toString() ?? 'ltr',
      typographyScale: map['typography_scale']?.toString() ?? 'standard',
      dateFormat: map['date_format']?.toString() ?? 'DD/MM/YYYY',
      numberFormat: map['number_format']?.toString() ?? '#,##0.00',
      currencyDisplayMode: map['currency_display_mode']?.toString() ?? 'SYMBOL',
      defaultCompanyId: map['default_company_id']?.toString(),
      defaultBranchId: map['default_branch_id']?.toString(),
      defaultWarehouseId: map['default_warehouse_id']?.toString(),
      defaultWorkspace: map['default_workspace']?.toString() ?? 'DASHBOARD',
      menuPreferences: map['menu_preferences'] is Map<String, dynamic>
          ? map['menu_preferences'] as Map<String, dynamic>
          : {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty) 'id': id,
      'user_id': userId,
      'tenant_id': tenantId,
      'primary_language_code': primaryLanguageCode,
      'primary_script_code': primaryScriptCode,
      'secondary_language_code': secondaryLanguageCode,
      'secondary_script_code': secondaryScriptCode,
      'tertiary_language_code': tertiaryLanguageCode,
      'tertiary_script_code': tertiaryScriptCode,
      'active_locale_id': activeLocaleId,
      'text_direction': textDirection,
      'typography_scale': typographyScale,
      'date_format': dateFormat,
      'number_format': numberFormat,
      'currency_display_mode': currencyDisplayMode,
      'default_company_id': defaultCompanyId,
      'default_branch_id': defaultBranchId,
      'default_warehouse_id': defaultWarehouseId,
      'default_workspace': defaultWorkspace,
      'menu_preferences': menuPreferences,
    };
  }

  UserPreferencesModel copyWith({
    String? primaryLanguageCode,
    String? primaryScriptCode,
    String? secondaryLanguageCode,
    String? secondaryScriptCode,
    String? tertiaryLanguageCode,
    String? tertiaryScriptCode,
    String? activeLocaleId,
    String? textDirection,
    String? typographyScale,
    String? dateFormat,
    String? numberFormat,
    String? currencyDisplayMode,
    String? defaultCompanyId,
    String? defaultBranchId,
    String? defaultWarehouseId,
    String? defaultWorkspace,
    Map<String, dynamic>? menuPreferences,
  }) {
    return UserPreferencesModel(
      id: id,
      userId: userId,
      tenantId: tenantId,
      primaryLanguageCode: primaryLanguageCode ?? this.primaryLanguageCode,
      primaryScriptCode: primaryScriptCode ?? this.primaryScriptCode,
      secondaryLanguageCode: secondaryLanguageCode ?? this.secondaryLanguageCode,
      secondaryScriptCode: secondaryScriptCode ?? this.secondaryScriptCode,
      tertiaryLanguageCode: tertiaryLanguageCode ?? this.tertiaryLanguageCode,
      tertiaryScriptCode: tertiaryScriptCode ?? this.tertiaryScriptCode,
      activeLocaleId: activeLocaleId ?? this.activeLocaleId,
      textDirection: textDirection ?? this.textDirection,
      typographyScale: typographyScale ?? this.typographyScale,
      dateFormat: dateFormat ?? this.dateFormat,
      numberFormat: numberFormat ?? this.numberFormat,
      currencyDisplayMode: currencyDisplayMode ?? this.currencyDisplayMode,
      defaultCompanyId: defaultCompanyId ?? this.defaultCompanyId,
      defaultBranchId: defaultBranchId ?? this.defaultBranchId,
      defaultWarehouseId: defaultWarehouseId ?? this.defaultWarehouseId,
      defaultWorkspace: defaultWorkspace ?? this.defaultWorkspace,
      menuPreferences: menuPreferences ?? this.menuPreferences,
    );
  }
}
