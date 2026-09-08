/// NAKHL & NAHL — AI PROVIDER ABSTRACTION & CAPABILITIES
/// Desteklenen Sağlayıcılar: OpenAI, Gemini, Claude, DeepSeek, Qwen, Kimi, Grok, Local AI.
/// Tek bir yapay zekâya bağımlılığı engelleyen adapter mimarisidir.

enum AIProviderType {
  openAI('OpenAI / ChatGPT'),
  gemini('Google Gemini'),
  claude('Anthropic Claude'),
  deepSeek('DeepSeek'),
  qwen('Alibaba Qwen'),
  kimi('Moonshot Kimi'),
  grok('xAI Grok'),
  localAI('Yerel / On-Premise AI (Ollama)'),
  custom('Özel OpenAI-Uyumlu Sağlayıcı');

  final String displayName;
  const AIProviderType(this.displayName);
}

class AICapabilities {
  final bool supportsChat;
  final bool supportsVision;
  final bool supportsOCR;
  final bool supportsTools;
  final bool supportsWebSearch;
  final bool supportsStructuredOutput;
  final bool supportsEmbeddings;
  final bool supportsStreaming;
  final bool supportsAgents;

  const AICapabilities({
    this.supportsChat = true,
    this.supportsVision = false,
    this.supportsOCR = false,
    this.supportsTools = false,
    this.supportsWebSearch = false,
    this.supportsStructuredOutput = true,
    this.supportsEmbeddings = false,
    this.supportsStreaming = true,
    this.supportsAgents = false,
  });
}

enum AIProviderStatus {
  notConfigured('YAPILANDIRILMADI'),
  connected('BAĞLI'),
  error('HATA'),
  rateLimited('KOTA AŞILDI'),
  maintenance('BAKIMDA');

  final String label;
  const AIProviderStatus(this.label);
}

class AIResponse {
  final String text;
  final String providerName;
  final String modelName;
  final int? promptTokens;
  final int? completionTokens;
  final double? estimatedCostUsd;
  final List<String> sourcesUsed;
  final Map<String, dynamic>? structuredData;
  final String? toolCallName;
  final Map<String, dynamic>? toolCallArguments;

  const AIResponse({
    required this.text,
    required this.providerName,
    required this.modelName,
    this.promptTokens,
    this.completionTokens,
    this.estimatedCostUsd,
    this.sourcesUsed = const [],
    this.structuredData,
    this.toolCallName,
    this.toolCallArguments,
  });
}

abstract class AIProvider {
  AIProviderType get type;
  String get name => type.displayName;
  AICapabilities get capabilities;
  AIProviderStatus get status;
  bool get isConfigured;

  Future<AIResponse> generateResponse({
    required String prompt,
    String? systemInstruction,
    List<Map<String, dynamic>>? tools,
    Map<String, dynamic>? contextMetadata,
  });
}

/// Generic Mock/Configured Provider Template
class GenericAIProvider implements AIProvider {
  @override
  final AIProviderType type;
  @override
  String get name => type.displayName;
  @override
  final AICapabilities capabilities;
  final String? apiKey;
  final String modelName;

  GenericAIProvider({
    required this.type,
    required this.capabilities,
    this.apiKey,
    required this.modelName,
  });

  @override
  bool get isConfigured => apiKey != null && apiKey!.trim().isNotEmpty;

  @override
  AIProviderStatus get status =>
      isConfigured ? AIProviderStatus.connected : AIProviderStatus.notConfigured;

  @override
  Future<AIResponse> generateResponse({
    required String prompt,
    String? systemInstruction,
    List<Map<String, dynamic>>? tools,
    Map<String, dynamic>? contextMetadata,
  }) async {
    if (!isConfigured) {
      return AIResponse(
        text: 'Bu AI sağlayıcısı ($name) henüz yapılandırılmamış. Lütfen Ayarlar > AI Entegrasyonları bölümünden API anahtarını girin.',
        providerName: name,
        modelName: modelName,
        sourcesUsed: const ['SYSTEM_FALLBACK'],
      );
    }

    // Provider simülasyonu / gerçek bağlantı yanıtı
    return AIResponse(
      text: '[$name ($modelName)]: Talebiniz başarıyla analiz edildi.\n$prompt',
      providerName: name,
      modelName: modelName,
      promptTokens: 120,
      completionTokens: 85,
      estimatedCostUsd: 0.0004,
      sourcesUsed: const ['NAKHL_INTERNAL_KNOWLEDGE'],
    );
  }
}
