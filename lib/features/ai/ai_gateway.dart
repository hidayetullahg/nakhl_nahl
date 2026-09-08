import 'package:flutter/foundation.dart';
import 'ai_provider.dart';

/// NAKHL & NAHL — AI GATEWAY, AUDIT & MULTI-TENANT GÜVENLİK MERKEZİ
/// Tenant izolasyonunu garanti eder, harici sağlayıcı fallback zincirini yönetir,
/// token ve maliyet kullanımını denetler.

class AIUsageRecord {
  final String id;
  final String tenantId;
  final String userId;
  final String providerName;
  final String modelName;
  final String taskType;
  final int totalTokens;
  final double costUsd;
  final DateTime timestamp;

  const AIUsageRecord({
    required this.id,
    required this.tenantId,
    required this.userId,
    required this.providerName,
    required this.modelName,
    required this.taskType,
    required this.totalTokens,
    required this.costUsd,
    required this.timestamp,
  });
}

class AIAuditLog {
  final String id;
  final String tenantId;
  final String userId;
  final String action;
  final String providerName;
  final String taskClassification;
  final bool isSuccess;
  final String? errorMessage;
  final DateTime timestamp;

  const AIAuditLog({
    required this.id,
    required this.tenantId,
    required this.userId,
    required this.action,
    required this.providerName,
    required this.taskClassification,
    required this.isSuccess,
    this.errorMessage,
    required this.timestamp,
  });
}

class AIGateway extends ChangeNotifier {
  AIGateway._() {
    _initDefaultProviders();
  }
  static final AIGateway instance = AIGateway._();

  final Map<AIProviderType, AIProvider> _providers = {};
  final List<AIUsageRecord> _usageHistory = [];
  final List<AIAuditLog> _auditLogs = [];

  AIProviderType _primaryProviderType = AIProviderType.gemini;
  final List<AIProviderType> _fallbackChain = [
    AIProviderType.gemini,
    AIProviderType.openAI,
    AIProviderType.claude,
    AIProviderType.deepSeek,
    AIProviderType.qwen,
  ];

  AIProviderType get primaryProviderType => _primaryProviderType;
  List<AIUsageRecord> get usageHistory => List.unmodifiable(_usageHistory);
  List<AIAuditLog> get auditLogs => List.unmodifiable(_auditLogs);
  Map<AIProviderType, AIProvider> get providers => Map.unmodifiable(_providers);

  void initializeDefaults() {
    _providers.clear();
    _initDefaultProviders();
    notifyListeners();
  }

  AIProvider? getProvider(dynamic typeOrName) {
    if (typeOrName is AIProviderType) return _providers[typeOrName];
    if (typeOrName is String) {
      final clean = typeOrName.toLowerCase();
      for (final entry in _providers.entries) {
        if (entry.key.name.toLowerCase() == clean ||
            entry.key.displayName.toLowerCase().contains(clean)) {
          return entry.value;
        }
      }
    }
    return null;
  }

  void _initDefaultProviders() {
    _providers[AIProviderType.gemini] = GenericAIProvider(
      type: AIProviderType.gemini,
      capabilities: const AICapabilities(
        supportsChat: true,
        supportsVision: true,
        supportsOCR: true,
        supportsTools: true,
        supportsWebSearch: true,
        supportsStructuredOutput: true,
        supportsAgents: true,
      ),
      modelName: 'gemini-1.5-pro',
      apiKey: null, // Yapılandırılınca set edilir
    );

    _providers[AIProviderType.openAI] = GenericAIProvider(
      type: AIProviderType.openAI,
      capabilities: const AICapabilities(
        supportsChat: true,
        supportsVision: true,
        supportsOCR: true,
        supportsTools: true,
        supportsStructuredOutput: true,
        supportsAgents: true,
      ),
      modelName: 'gpt-4o',
      apiKey: null,
    );

    _providers[AIProviderType.claude] = GenericAIProvider(
      type: AIProviderType.claude,
      capabilities: const AICapabilities(
        supportsChat: true,
        supportsVision: true,
        supportsOCR: true,
        supportsTools: true,
        supportsStructuredOutput: true,
      ),
      modelName: 'claude-3-5-sonnet',
      apiKey: null,
    );

    _providers[AIProviderType.deepSeek] = GenericAIProvider(
      type: AIProviderType.deepSeek,
      capabilities: const AICapabilities(
        supportsChat: true,
        supportsTools: true,
        supportsStructuredOutput: true,
      ),
      modelName: 'deepseek-chat',
      apiKey: null,
    );

    _providers[AIProviderType.qwen] = GenericAIProvider(
      type: AIProviderType.qwen,
      capabilities: const AICapabilities(
        supportsChat: true,
        supportsVision: true,
        supportsTools: true,
      ),
      modelName: 'qwen-max',
      apiKey: null,
    );
  }

  void registerProvider(AIProvider provider) {
    _providers[provider.type] = provider;
    notifyListeners();
  }

  void setPrimaryProvider(AIProviderType type) {
    _primaryProviderType = type;
    notifyListeners();
  }

  /// Multi-Tenant Güvenli AI İsteği Gönderimi (Fallback zinciriyle)
  Future<AIResponse> executeRequest({
    required String tenantId,
    required String userId,
    required String prompt,
    required String taskType,
    String? systemInstruction,
    List<Map<String, dynamic>>? tools,
    Map<String, dynamic>? contextMetadata,
  }) async {
    // 1. Tenant İzolasyonu ve Boşluk Kontrolü
    if (tenantId.trim().isEmpty || userId.trim().isEmpty) {
      throw ArgumentError('Tenant ID veya User ID boş olamaz. Güvenlik ihlali.');
    }

    AIResponse? finalResponse;
    String? lastError;
    AIProvider? usedProvider;

    // 2. Birincil Sağlayıcı ve Fallback Zinciri
    final chain = [_primaryProviderType, ..._fallbackChain.where((t) => t != _primaryProviderType)];

    for (final providerType in chain) {
      final provider = _providers[providerType];
      if (provider == null) continue;

      try {
        usedProvider = provider;
        finalResponse = await provider.generateResponse(
          prompt: prompt,
          systemInstruction: systemInstruction,
          tools: tools,
          contextMetadata: contextMetadata,
        );
        break;
      } catch (e) {
        lastError = e.toString();
      }
    }

    final now = DateTime.now();

    // 3. Kullanım ve Maliyet Kaydı
    if (finalResponse != null) {
      final usage = AIUsageRecord(
        id: 'use_${now.millisecondsSinceEpoch}',
        tenantId: tenantId,
        userId: userId,
        providerName: finalResponse.providerName,
        modelName: finalResponse.modelName,
        taskType: taskType,
        totalTokens: (finalResponse.promptTokens ?? 0) + (finalResponse.completionTokens ?? 0),
        costUsd: finalResponse.estimatedCostUsd ?? 0.0,
        timestamp: now,
      );
      _usageHistory.add(usage);

      // Audit Log
      _auditLogs.add(AIAuditLog(
        id: 'aud_${now.millisecondsSinceEpoch}',
        tenantId: tenantId,
        userId: userId,
        action: 'AI_PROMPT_EXECUTE',
        providerName: finalResponse.providerName,
        taskClassification: taskType,
        isSuccess: true,
        timestamp: now,
      ));

      notifyListeners();
      return finalResponse;
    }

    // 4. Tüm zincir başarısız olursa
    _auditLogs.add(AIAuditLog(
      id: 'aud_${now.millisecondsSinceEpoch}',
      tenantId: tenantId,
      userId: userId,
      action: 'AI_PROMPT_FAILED',
      providerName: usedProvider?.name ?? 'UNKNOWN',
      taskClassification: taskType,
      isSuccess: false,
      errorMessage: lastError,
      timestamp: now,
    ));
    notifyListeners();

    return AIResponse(
      text: 'AI servislerine geçici olarak ulaşılamıyor: ${lastError ?? "Tüm sağlayıcılar meşgul"}',
      providerName: 'GATEWAY_ERROR',
      modelName: 'none',
      sourcesUsed: const ['SYSTEM_FALLBACK'],
    );
  }
}
