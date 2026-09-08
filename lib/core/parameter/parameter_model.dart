import 'parameter_scope.dart';

/// NAKHL & NAHL — PARAMETRE ALAN (DOMAIN) SINIFLANDIRMASI
enum ParameterDomain {
  system('SYSTEM', 'Sistem Parametreleri'),
  localization('LOCALIZATION', 'Yerelleştirme & Dil Parametreleri'),
  accounting('ACCOUNTING', 'Muhasebe Parametreleri'),
  inventory('INVENTORY', 'Stok & Envanter Parametreleri'),
  trade('TRADE', 'Dış Ticaret & Gümrük Parametreleri'),
  tax('TAX', 'Vergi & Zakat Parametreleri'),
  warehouse('WAREHOUSE', 'Depo & Lojistik Parametreleri'),
  halal('HALAL', 'Helal Uyumluluk Parametreleri'),
  quality('QUALITY', 'Kalite Güvence Parametreleri'),
  agriculture('AGRICULTURE', 'Tarım & Hasat Parametreleri'),
  logistics('LOGISTICS', 'Sevkiyat & Nakliye Parametreleri');

  final String code;
  final String label;
  const ParameterDomain(this.code, this.label);
}

enum ParameterDataType {
  string('Metin'),
  number('Sayısal / Tutar'),
  boolean('Evet / Hayır (Mantıksal)'),
  select('Tekli Seçim (Dropdown)'),
  multiselect('Çoklu Seçim'),
  json('Yapılandırılmış JSON');

  final String label;
  const ParameterDataType(this.label);
}

class ParameterDefinition {
  final String id;
  final String code;
  final String name;
  final ParameterDomain domain;
  final ParameterDataType dataType;
  final dynamic defaultValue;
  final dynamic currentValue;
  final List<String> allowedValues;
  final bool isRequired;
  final String description;
  final ParameterScope scope;
  final bool isActive;
  final String? countryCode;
  final String? companyId;
  final String? branchId;
  final String? tenantId;
  final DateTime? effectiveDate;

  const ParameterDefinition({
    this.id = '',
    required this.code,
    required this.name,
    required this.domain,
    required this.dataType,
    required this.defaultValue,
    this.currentValue,
    this.allowedValues = const [],
    this.isRequired = false,
    this.description = '',
    this.scope = ParameterScope.global,
    this.isActive = true,
    this.countryCode,
    this.companyId,
    this.branchId,
    this.tenantId,
    this.effectiveDate,
  });

  dynamic get effectiveValue => currentValue ?? defaultValue;

  ParameterDefinition copyWith({
    String? id,
    String? code,
    String? name,
    ParameterDomain? domain,
    ParameterDataType? dataType,
    dynamic defaultValue,
    dynamic currentValue,
    List<String>? allowedValues,
    bool? isRequired,
    String? description,
    ParameterScope? scope,
    bool? isActive,
    String? countryCode,
    String? companyId,
    String? branchId,
    String? tenantId,
    DateTime? effectiveDate,
  }) {
    return ParameterDefinition(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      domain: domain ?? this.domain,
      dataType: dataType ?? this.dataType,
      defaultValue: defaultValue ?? this.defaultValue,
      currentValue: currentValue ?? this.currentValue,
      allowedValues: allowedValues ?? this.allowedValues,
      isRequired: isRequired ?? this.isRequired,
      description: description ?? this.description,
      scope: scope ?? this.scope,
      isActive: isActive ?? this.isActive,
      countryCode: countryCode ?? this.countryCode,
      companyId: companyId ?? this.companyId,
      branchId: branchId ?? this.branchId,
      tenantId: tenantId ?? this.tenantId,
      effectiveDate: effectiveDate ?? this.effectiveDate,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'domain': domain.code,
        'data_type': dataType.name,
        'default_value': defaultValue,
        'current_value': currentValue,
        'allowed_values': allowedValues,
        'is_required': isRequired,
        'description': description,
        'scope': scope.code,
        'is_active': isActive,
        'country_code': countryCode,
        'company_id': companyId,
        'branch_id': branchId,
        'tenant_id': tenantId,
        'effective_date': effectiveDate?.toIso8601String(),
      };

  factory ParameterDefinition.fromJson(Map<String, dynamic> json) {
    return ParameterDefinition(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      domain: ParameterDomain.values.firstWhere(
        (d) => d.code == json['domain'],
        orElse: () => ParameterDomain.system,
      ),
      dataType: ParameterDataType.values.firstWhere(
        (t) => t.name == json['data_type'],
        orElse: () => ParameterDataType.string,
      ),
      defaultValue: json['default_value'],
      currentValue: json['current_value'],
      allowedValues: (json['allowed_values'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isRequired: json['is_required'] ?? false,
      description: json['description'] ?? '',
      scope: ParameterScope.values.firstWhere(
        (s) => s.code == json['scope'],
        orElse: () => ParameterScope.global,
      ),
      isActive: json['is_active'] ?? true,
      countryCode: json['country_code'],
      companyId: json['company_id'],
      branchId: json['branch_id'],
      tenantId: json['tenant_id'],
      effectiveDate: json['effective_date'] != null
          ? DateTime.tryParse(json['effective_date'])
          : null,
    );
  }
}

typedef ParameterModel = ParameterDefinition;
