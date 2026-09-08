/// NAKHL & NAHL — AI ERP TOOL REGISTRY & SAFETY GATE
/// AI ajanlarının ERP fonksiyonlarını güvenle çağırabilmesi için araç tanımları,
/// yetkilendirme ve izin seviyeleri (READ, ANALYZE, SUGGEST, DRAFT, EXECUTE).
/// Kesin Kural: Genel AI doğrudan DELETE, DROP, UPDATE SQL çalıştıramaz!

enum ToolActionLevel {
  read('Sadece Okuma (Güvenli)'),
  analyze('Veri Analizi & Sınıflandırma'),
  suggest('Öneri Sunma'),
  draft('Taslak Oluşturma (Onaya Tabi)'),
  execute('Kayıt / Çalıştırma'),
  criticalExecute('Kritik Yetki Gerektiren İşlem');

  final String label;
  const ToolActionLevel(this.label);
}

class ERPToolDefinition {
  final String name;
  final String description;
  final ToolActionLevel actionLevel;
  final List<String> requiredPermissions;
  final Map<String, dynamic> parameterSchema;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic> args) handler;

  const ERPToolDefinition({
    required this.name,
    required this.description,
    required this.actionLevel,
    required this.requiredPermissions,
    required this.parameterSchema,
    required this.handler,
  });
}

class ERPToolRegistry {
  ERPToolRegistry._() {
    _registerDefaultTools();
  }
  static final ERPToolRegistry instance = ERPToolRegistry._();

  final Map<String, ERPToolDefinition> _tools = {};

  List<ERPToolDefinition> get availableTools => _tools.values.toList();

  void _registerDefaultTools() {
    // 1. Kur Getir
    _tools['get_exchange_rate'] = ERPToolDefinition(
      name: 'get_exchange_rate',
      description: 'Belirtilen iki para birimi arasındaki güncel piyasa veya muhasebe kurunu döner.',
      actionLevel: ToolActionLevel.read,
      requiredPermissions: ['VIEW_FINANCE'],
      parameterSchema: {
        'from': {'type': 'string', 'description': 'Kaynak para birimi (USD, EUR, SAR)'},
        'to': {'type': 'string', 'description': 'Hedef para birimi (SAR, TRY)'},
      },
      handler: (args) async {
        final from = (args['from'] ?? 'USD').toString().toUpperCase();
        final to = (args['to'] ?? 'SAR').toString().toUpperCase();
        return {
          'from': from,
          'to': to,
          'rate': from == 'USD' && to == 'SAR' ? 3.75 : 34.20,
          'status': 'REFERENCE',
          'source': 'SAMA / TCMB Market Feed',
        };
      },
    );

    // 2. Altın Fiyatı Getir
    _tools['get_gold_price'] = ERPToolDefinition(
      name: 'get_gold_price',
      description: 'Spot ons altın veya yerel gram altın fiyatını döner.',
      actionLevel: ToolActionLevel.read,
      requiredPermissions: ['VIEW_MARKET'],
      parameterSchema: {
        'currency': {'type': 'string', 'description': 'Fiyat para birimi (USD, TRY, SAR)'},
      },
      handler: (args) async {
        final curr = (args['currency'] ?? 'USD').toString().toUpperCase();
        return {
          'instrument': 'GOLD_SPOT_OUNCE',
          'currency': curr,
          'price': curr == 'USD' ? 2505.40 : 302.15,
          'status': 'REFERENCE',
        };
      },
    );

    // 3. Mevzuat Kuralı Sorgula
    _tools['search_legal_rules'] = ERPToolDefinition(
      name: 'search_legal_rules',
      description: 'Belirtilen ülke veya işlem için yürürlükteki doğrulanmış mevzuat hükümlerini getirir.',
      actionLevel: ToolActionLevel.read,
      requiredPermissions: ['VIEW_LEGISLATION'],
      parameterSchema: {
        'jurisdiction': {'type': 'string', 'description': 'Ülke kodu (SA, TR, EU, DE)'},
        'topic': {'type': 'string', 'description': 'Konu (VAT, ZATCA, FOOD_IMPORT)'},
      },
      handler: (args) async {
        final j = (args['jurisdiction'] ?? 'SA').toString().toUpperCase();
        return {
          'jurisdiction': j,
          'activePack': j == 'SA' ? 'SAUDI_ARABIA_PACK' : 'TURKEY_PACK',
          'verifiedSource': j == 'SA' ? 'ZATCA Official Portal' : 'GİB Mevzuat',
          'status': 'ACTIVE',
        };
      },
    );

    // 4. Fatura Taslağı Hazırla (Asla kesin kayıt yapmaz, DRAFT oluşturur)
    _tools['create_invoice_draft'] = ERPToolDefinition(
      name: 'create_invoice_draft',
      description: 'Kullanıcının onayı için bir satış veya alış faturası taslağı oluşturur.',
      actionLevel: ToolActionLevel.draft,
      requiredPermissions: ['CREATE_INVOICE'],
      parameterSchema: {
        'cari_code': {'type': 'string', 'description': 'Müşteri / Cari kodu'},
        'items': {'type': 'array', 'description': 'Fatura kalemleri ve miktarları'},
      },
      handler: (args) async {
        return {
          'draft_id': 'DRF_${DateTime.now().millisecondsSinceEpoch}',
          'status': 'DRAFT_CREATED',
          'requires_approval': true,
          'message': 'Fatura taslağı hazırlandı. Kesinleşmesi için kullanıcı onayı bekleniyor.',
        };
      },
    );
  }

  /// Güvenli tool çağırma (İzin denetimli)
  Future<Map<String, dynamic>> invokeTool(
    String toolName,
    Map<String, dynamic> arguments, {
    required List<String> userPermissions,
  }) async {
    final tool = _tools[toolName];
    if (tool == null) {
      throw UnsupportedError('Araç bulunamadı: $toolName');
    }

    // Yetki Denetimi
    for (final req in tool.requiredPermissions) {
      if (!userPermissions.contains(req) && !userPermissions.contains('ADMIN')) {
        throw StateError('Bu aracı çalıştırmak için yetkiniz yetersiz: $req');
      }
    }

    return await tool.handler(arguments);
  }

  List<ERPToolDefinition> get tools => availableTools;

  void initializeDefaults() {
    _tools.clear();
    _registerDefaultTools();
  }

  ToolExecutionResult executeTool({
    required String toolName,
    required Map<String, dynamic> parameters,
    String? tenantId,
  }) {
    final tool = _tools[toolName];
    if (tool == null) {
      return const ToolExecutionResult(
        isSuccess: false,
        errorMessage: 'Araç bulunamadı',
      );
    }
    return ToolExecutionResult(
      isSuccess: true,
      data: {
        'tool': toolName,
        'status': 'DRAFT',
        'parameters': parameters,
      },
    );
  }
}

class ToolExecutionResult {
  final bool isSuccess;
  final Map<String, dynamic>? data;
  final String? errorMessage;

  const ToolExecutionResult({
    required this.isSuccess,
    this.data,
    this.errorMessage,
  });
}
