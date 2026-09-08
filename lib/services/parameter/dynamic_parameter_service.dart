import 'package:flutter/foundation.dart';
import '../../core/parameter/parameter_model.dart';
import '../../core/parameter/parameter_scope.dart';
import '../supabase_service.dart';

/// NAKHL & NAHL — DİNAMİK PARAMETRE YÖNETİM SERVİSİ
/// Scope hiyerarşisi (USER -> WAREHOUSE -> BRANCH -> COMPANY -> TENANT -> COUNTRY -> GLOBAL)
/// ile parametreleri çözer ve yönetir.

class DynamicParameterService extends ChangeNotifier {
  DynamicParameterService._() {
    _loadDefaultParameters();
  }
  static final DynamicParameterService instance = DynamicParameterService._();

  final Map<String, ParameterDefinition> _definitions = {};
  // Key: "code|scope|entityId" -> value
  final Map<String, dynamic> _scopedValues = {};

  List<ParameterDefinition> get allDefinitions => _definitions.values.toList();

  void _loadDefaultParameters() {
    final defaults = [
      // Muhasebe
      const ParameterDefinition(
        id: 'acc_base_curr',
        code: 'ACC_CURRENCY_PRIMARY',
        name: 'Ana Muhasebe Para Birimi',
        domain: ParameterDomain.accounting,
        dataType: ParameterDataType.select,
        defaultValue: 'SAR',
        allowedValues: ['SAR', 'TRY', 'USD', 'EUR', 'AED'],
        isRequired: true,
        description: 'Mizan ve resmi defterlerin tutulacağı ana operasyonel para birimi.',
        scope: ParameterScope.company,
      ),
      const ParameterDefinition(
        id: 'acc_base_curr_legacy',
        code: 'ACCOUNTING_BASE_CURRENCY',
        name: 'Ana Muhasebe Para Birimi (Legacy)',
        domain: ParameterDomain.accounting,
        dataType: ParameterDataType.select,
        defaultValue: 'SAR',
        allowedValues: ['SAR', 'TRY', 'USD', 'EUR', 'AED'],
        isRequired: true,
        description: 'Mizan ve resmi defterlerin tutulacağı ana operasyonel para birimi.',
        scope: ParameterScope.company,
      ),
      const ParameterDefinition(
        id: 'acc_chart_type',
        code: 'CHART_OF_ACCOUNTS_STANDARD',
        name: 'Hesap Planı Standardı',
        domain: ParameterDomain.accounting,
        dataType: ParameterDataType.select,
        defaultValue: 'SAUDI_SOCPA',
        allowedValues: ['SAUDI_SOCPA', 'TURKISH_THP', 'IFRS_GLOBAL'],
        isRequired: true,
        description: 'Tüzel kişiliğin tabi olduğu tekdüzen veya uluslararası hesap planı.',
        scope: ParameterScope.company,
      ),

      // Vergi & Zakat
      const ParameterDefinition(
        id: 'tax_vat_default',
        code: 'TAX_DEFAULT_VAT_RATE',
        name: 'Standart KDV / VAT Oranı (%)',
        domain: ParameterDomain.tax,
        dataType: ParameterDataType.number,
        defaultValue: 15.0,
        isRequired: true,
        description: 'Ülke mevzuatına göre standart KDV/VAT oranı (KSA: %15, TR: %20).',
        scope: ParameterScope.country,
      ),
      const ParameterDefinition(
        id: 'tax_vat_default_legacy',
        code: 'DEFAULT_VAT_RATE',
        name: 'Standart KDV / VAT Oranı (%)',
        domain: ParameterDomain.tax,
        dataType: ParameterDataType.number,
        defaultValue: 15.0,
        isRequired: true,
        description: 'Ülke mevzuatına göre standart KDV/VAT oranı (KSA: %15, TR: %20).',
        scope: ParameterScope.country,
      ),
      const ParameterDefinition(
        id: 'tax_zatca_phase',
        code: 'ZATCA_INTEGRATION_PHASE',
        name: 'ZATCA E-Fatura Fazı',
        domain: ParameterDomain.tax,
        dataType: ParameterDataType.select,
        defaultValue: 'PHASE_2',
        allowedValues: ['PHASE_1', 'PHASE_2', 'SANDBOX'],
        isRequired: true,
        description: 'Suudi Arabistan ZATCA Fatoora entegrasyon seviyesi.',
        scope: ParameterScope.country,
      ),

      // Envanter & Depo
      const ParameterDefinition(
        id: 'inv_valuation_method',
        code: 'INVENTORY_VALUATION_METHOD',
        name: 'Stok Değerleme Yöntemi',
        domain: ParameterDomain.inventory,
        dataType: ParameterDataType.select,
        defaultValue: 'FIFO',
        allowedValues: ['FIFO', 'WEIGHTED_AVERAGE', 'LIFO'],
        isRequired: true,
        description: 'Hurma ve tarım ürünlerinin maliyet değerleme algoritması.',
        scope: ParameterScope.company,
      ),
      const ParameterDefinition(
        id: 'inv_lot_tracking',
        code: 'MANDATORY_LOT_TRACKING',
        name: 'Zorunlu Parti/Lot Takibi',
        domain: ParameterDomain.inventory,
        dataType: ParameterDataType.boolean,
        defaultValue: true,
        isRequired: true,
        description: 'Gıda güvenliği ve izlenebilirlik gereği her giriş-çıkışta lot numarası zorunludur.',
        scope: ParameterScope.tenant,
      ),

      // Dış Ticaret & Gümrük
      const ParameterDefinition(
        id: 'trade_default_incoterm',
        code: 'DEFAULT_INCOTERM',
        name: 'Varsayılan Teslim Şekli (Incoterm)',
        domain: ParameterDomain.trade,
        dataType: ParameterDataType.select,
        defaultValue: 'FOB',
        allowedValues: ['EXW', 'FOB', 'CIF', 'CFR', 'DAP', 'DDP'],
        isRequired: false,
        description: 'İhracat sözleşmelerinde önerilen varsayılan teslim şekli.',
        scope: ParameterScope.company,
      ),

      // Helal Uyumluluk
      const ParameterDefinition(
        id: 'halal_standard',
        code: 'HALAL_CERTIFICATION_STANDARD',
        name: 'Helal Sertifikasyon Standardı',
        domain: ParameterDomain.halal,
        dataType: ParameterDataType.select,
        defaultValue: 'SMIIC_1',
        allowedValues: ['SMIIC_1', 'GSO_993', 'JAKIM', 'SFDA_FD_24'],
        isRequired: true,
        description: 'İhracat ve yerel pazarda geçerli helal uyumluluk standardı.',
        scope: ParameterScope.country,
      ),

      // Tarım & Hasat
      const ParameterDefinition(
        id: 'agri_moisture_limit',
        code: 'DATES_MAX_MOISTURE_PERCENT',
        name: 'Hurma İhracatı Maksimum Nem Oranı (%)',
        domain: ParameterDomain.agriculture,
        dataType: ParameterDataType.number,
        defaultValue: 20.0,
        isRequired: true,
        description: 'İhracat sınıfı yaş/kuru hurma partilerinde kabul edilebilir üst nem sınırı.',
        scope: ParameterScope.global,
      ),

      // Sistem & Yerelleştirme
      const ParameterDefinition(
        id: 'sys_auto_save_interval',
        code: 'FORM_AUTOSAVE_INTERVAL_SEC',
        name: 'Form Otomatik Kaydetme Aralığı (Saniye)',
        domain: ParameterDomain.system,
        dataType: ParameterDataType.number,
        defaultValue: 30,
        isRequired: false,
        description: 'Kullanıcının veri girişlerinde arka plan taslak kaydetme sıklığı.',
        scope: ParameterScope.user,
      ),
    ];

    for (final def in defaults) {
      _definitions[def.code] = def;
    }
  }

  /// Yeni parametre tanımı ekler
  Future<void> addParameter(ParameterDefinition param) async {
    _definitions[param.code] = param;
    notifyListeners();

    try {
      await SupabaseService.client.from('parameter_definitions').upsert(param.toJson());
    } catch (_) {
      // Offline fallback
    }
  }

  /// Parametre değerini belirli bir kapsam için günceller
  Future<void> updateParameterValue(
    String code,
    dynamic value, {
    ParameterScope scope = ParameterScope.global,
    String? entityId,
  }) async {
    final key = '$code|${scope.code}|${entityId ?? "ALL"}';
    _scopedValues[key] = value;

    // Eğer global tanım ise currentValue'yu da güncelle
    if (_definitions.containsKey(code)) {
      _definitions[code] = _definitions[code]!.copyWith(currentValue: value);
    }

    notifyListeners();

    try {
      await SupabaseService.client.from('parameter_values').upsert({
        'parameter_code': code,
        'scope': scope.code,
        'entity_id': entityId ?? 'ALL',
        'value': value,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Offline fallback
    }
  }

  /// Hiyerarşik kapsam sırasına göre çözümlenmiş değeri döner:
  /// USER -> WAREHOUSE -> BRANCH -> COMPANY -> TENANT -> COUNTRY -> GLOBAL -> defaultValue
  dynamic resolveParameterValue(
    String code, {
    String? userId,
    String? warehouseId,
    String? branchId,
    String? companyId,
    String? tenantId,
    String? countryCode,
  }) {
    // 1. USER
    if (userId != null) {
      final val = _scopedValues['$code|USER|$userId'];
      if (val != null) return val;
    }

    // 2. WAREHOUSE
    if (warehouseId != null) {
      final val = _scopedValues['$code|WAREHOUSE|$warehouseId'];
      if (val != null) return val;
    }

    // 3. BRANCH
    if (branchId != null) {
      final val = _scopedValues['$code|BRANCH|$branchId'];
      if (val != null) return val;
    }

    // 4. COMPANY
    if (companyId != null) {
      final val = _scopedValues['$code|COMPANY|$companyId'];
      if (val != null) return val;
    }

    // 5. TENANT
    if (tenantId != null) {
      final val = _scopedValues['$code|TENANT|$tenantId'];
      if (val != null) return val;
    }

    // 6. COUNTRY
    if (countryCode != null) {
      final val = _scopedValues['$code|COUNTRY|$countryCode'];
      if (val != null) return val;
    }

    // 7. GLOBAL or definition current/default
    final globalVal = _scopedValues['$code|GLOBAL|ALL'];
    if (globalVal != null) return globalVal;

    final def = _definitions[code];
    return def?.effectiveValue;
  }

  void initializeDefaults() {
    _definitions.clear();
    _scopedValues.clear();
    _loadDefaultParameters();
    notifyListeners();
  }

  ParameterDefinition? getParameter(String code) => _definitions[code];

  dynamic resolveValue(String code, {
    String? userId,
    String? warehouseId,
    String? branchId,
    String? companyId,
    String? tenantId,
    String? countryCode,
  }) => resolveParameterValue(code,
    userId: userId,
    warehouseId: warehouseId,
    branchId: branchId,
    companyId: companyId,
    tenantId: tenantId,
    countryCode: countryCode,
  );

  void setScopedValue({
    required String parameterCode,
    required ParameterScope scope,
    required String scopeId,
    required dynamic value,
  }) {
    updateParameterValue(parameterCode, value, scope: scope, entityId: scopeId);
  }

  void registerParameter(ParameterDefinition param) {
    addParameter(param);
  }

  List<ParameterDefinition> getParametersByDomain(ParameterDomain domain) {
    return _definitions.values.where((p) => p.domain == domain).toList();
  }

  List<ParameterDefinition> searchParameters(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return allDefinitions;
    return _definitions.values
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.code.toLowerCase().contains(q) ||
            p.description.toLowerCase().contains(q))
        .toList();
  }
}
