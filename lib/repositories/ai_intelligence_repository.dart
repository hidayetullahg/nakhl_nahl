import '../services/supabase_service.dart';
import '../core/tenant/tenant_context.dart';

/// 8 Standart Doküman Sınıfı
enum AiDocumentClass {
  invoice,
  packingList,
  certificate,
  customs,
  transport,
  quality,
  halal,
  other;

  String get dbValue {
    switch (this) {
      case AiDocumentClass.invoice:
        return 'INVOICE';
      case AiDocumentClass.packingList:
        return 'PACKING_LIST';
      case AiDocumentClass.certificate:
        return 'CERTIFICATE';
      case AiDocumentClass.customs:
        return 'CUSTOMS';
      case AiDocumentClass.transport:
        return 'TRANSPORT';
      case AiDocumentClass.quality:
        return 'QUALITY';
      case AiDocumentClass.halal:
        return 'HALAL';
      case AiDocumentClass.other:
        return 'OTHER';
    }
  }

  static AiDocumentClass fromDbValue(String val) {
    switch (val.toUpperCase()) {
      case 'INVOICE':
        return AiDocumentClass.invoice;
      case 'PACKING_LIST':
        return AiDocumentClass.packingList;
      case 'CERTIFICATE':
        return AiDocumentClass.certificate;
      case 'CUSTOMS':
        return AiDocumentClass.customs;
      case 'TRANSPORT':
        return AiDocumentClass.transport;
      case 'QUALITY':
        return AiDocumentClass.quality;
      case 'HALAL':
        return AiDocumentClass.halal;
      default:
        return AiDocumentClass.other;
    }
  }
}

/// AI Ticari Öneri Türleri
enum AiSuggestionType {
  accountSuggestion,
  productMatching,
  partyMatching,
  anomalySuggestion,
  forecast;

  String get dbValue {
    switch (this) {
      case AiSuggestionType.accountSuggestion:
        return 'ACCOUNT_SUGGESTION';
      case AiSuggestionType.productMatching:
        return 'PRODUCT_MATCHING';
      case AiSuggestionType.partyMatching:
        return 'PARTY_MATCHING';
      case AiSuggestionType.anomalySuggestion:
        return 'ANOMALY_SUGGESTION';
      case AiSuggestionType.forecast:
        return 'FORECAST';
    }
  }

  static AiSuggestionType fromDbValue(String val) {
    switch (val.toUpperCase()) {
      case 'ACCOUNT_SUGGESTION':
        return AiSuggestionType.accountSuggestion;
      case 'PRODUCT_MATCHING':
        return AiSuggestionType.productMatching;
      case 'PARTY_MATCHING':
        return AiSuggestionType.partyMatching;
      case 'ANOMALY_SUGGESTION':
        return AiSuggestionType.anomalySuggestion;
      case 'FORECAST':
        return AiSuggestionType.forecast;
      default:
        return AiSuggestionType.accountSuggestion;
    }
  }
}

/// 1. OCR Fatura ve Ticari Belge Taslak Modeli
class OcrExtractionModel {
  final String id;
  final String companyId;
  final String? documentId;
  final String? imageStorageRef;
  final String invoiceNumber;
  final DateTime? date;
  final String? supplierName;
  final String? customerName;
  final String? productName;
  final double quantity;
  final double price;
  final double taxRate;
  final double taxAmount;
  final String currency;
  final double confidenceScore;
  final String modelName;
  final String modelVersion;
  final String status; // DRAFT_SUGGESTION, APPROVED, REJECTED, MODIFIED
  final String? reviewedByUserId;
  final String? reviewNotes;
  final DateTime? reviewedAt;
  final DateTime createdAt;

  const OcrExtractionModel({
    required this.id,
    required this.companyId,
    this.documentId,
    this.imageStorageRef,
    required this.invoiceNumber,
    this.date,
    this.supplierName,
    this.customerName,
    this.productName,
    required this.quantity,
    required this.price,
    required this.taxRate,
    required this.taxAmount,
    required this.currency,
    required this.confidenceScore,
    required this.modelName,
    required this.modelVersion,
    required this.status,
    this.reviewedByUserId,
    this.reviewNotes,
    this.reviewedAt,
    required this.createdAt,
  });

  bool get isDraft => status == 'DRAFT_SUGGESTION';
  bool get isApproved => status == 'APPROVED';

  factory OcrExtractionModel.fromJson(Map<String, dynamic> json) {
    return OcrExtractionModel(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      documentId: json['document_id'] as String?,
      imageStorageRef: json['image_storage_ref'] as String?,
      invoiceNumber: json['extracted_invoice_number'] as String? ?? '',
      date: json['extracted_date'] != null
          ? DateTime.tryParse(json['extracted_date'] as String)
          : null,
      supplierName: json['extracted_supplier_name'] as String?,
      customerName: json['extracted_customer_name'] as String?,
      productName: json['extracted_product_name'] as String?,
      quantity: (json['extracted_quantity'] as num?)?.toDouble() ?? 0.0,
      price: (json['extracted_price'] as num?)?.toDouble() ?? 0.0,
      taxRate: (json['extracted_tax_rate'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['extracted_tax_amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['extracted_currency'] as String? ?? 'SAR',
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.0,
      modelName: json['model_name'] as String? ?? 'nakhl-ocr-engine',
      modelVersion: json['model_version'] as String? ?? 'v2.4',
      status: json['status'] as String? ?? 'DRAFT_SUGGESTION',
      reviewedByUserId: json['reviewed_by_user_id'] as String?,
      reviewNotes: json['review_notes'] as String?,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.tryParse(json['reviewed_at'] as String)
          : null,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

/// 2. Belge Sınıflandırma Modeli
class DocumentClassificationModel {
  final String id;
  final String companyId;
  final String documentId;
  final AiDocumentClass predictedClass;
  final double confidenceScore;
  final List<String> secondaryTags;
  final String modelName;
  final String modelVersion;
  final String? verifiedByUserId;
  final AiDocumentClass? verifiedClass;

  const DocumentClassificationModel({
    required this.id,
    required this.companyId,
    required this.documentId,
    required this.predictedClass,
    required this.confidenceScore,
    required this.secondaryTags,
    required this.modelName,
    required this.modelVersion,
    this.verifiedByUserId,
    this.verifiedClass,
  });

  factory DocumentClassificationModel.fromJson(Map<String, dynamic> json) {
    return DocumentClassificationModel(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      documentId: json['document_id'] as String,
      predictedClass: AiDocumentClass.fromDbValue(
          json['predicted_class'] as String? ?? 'OTHER'),
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.0,
      secondaryTags: (json['secondary_tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      modelName: json['model_name'] as String? ?? 'nakhl-doc-classifier',
      modelVersion: json['model_version'] as String? ?? 'v1.5',
      verifiedByUserId: json['verified_by_user_id'] as String?,
      verifiedClass: json['verified_class'] != null
          ? AiDocumentClass.fromDbValue(json['verified_class'] as String)
          : null,
    );
  }
}

/// 3. Ticari Öneri Modeli
class CommercialSuggestionModel {
  final String id;
  final String companyId;
  final AiSuggestionType suggestionType;
  final String targetEntityType;
  final String? targetEntityId;
  final Map<String, dynamic> payload;
  final String? explanationText;
  final double confidenceScore;
  final String modelVersion;
  final String status;
  final String? humanReviewerUserId;

  const CommercialSuggestionModel({
    required this.id,
    required this.companyId,
    required this.suggestionType,
    required this.targetEntityType,
    this.targetEntityId,
    required this.payload,
    this.explanationText,
    required this.confidenceScore,
    required this.modelVersion,
    required this.status,
    this.humanReviewerUserId,
  });

  factory CommercialSuggestionModel.fromJson(Map<String, dynamic> json) {
    return CommercialSuggestionModel(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      suggestionType: AiSuggestionType.fromDbValue(
          json['suggestion_type'] as String? ?? 'ACCOUNT_SUGGESTION'),
      targetEntityType: json['target_entity_type'] as String? ?? '',
      targetEntityId: json['target_entity_id'] as String?,
      payload: json['suggestion_payload'] as Map<String, dynamic>? ?? {},
      explanationText: json['explanation_text'] as String?,
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.0,
      modelVersion: json['model_version'] as String? ?? 'v2.1',
      status: json['status'] as String? ?? 'PENDING_HUMAN_REVIEW',
      humanReviewerUserId: json['human_reviewer_user_id'] as String?,
    );
  }
}

/// 4. AI Denetim İzi Modeli
class AiAuditLogModel {
  final String id;
  final String companyId;
  final String actionType;
  final String modelName;
  final String modelVersion;
  final String? inputReference;
  final String? outputSummary;
  final double? confidenceScore;
  final String? approvingUserId;
  final DateTime createdAt;

  const AiAuditLogModel({
    required this.id,
    required this.companyId,
    required this.actionType,
    required this.modelName,
    required this.modelVersion,
    this.inputReference,
    this.outputSummary,
    this.confidenceScore,
    this.approvingUserId,
    required this.createdAt,
  });

  factory AiAuditLogModel.fromJson(Map<String, dynamic> json) {
    return AiAuditLogModel(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      actionType: json['action_type'] as String? ?? '',
      modelName: json['model_name'] as String? ?? '',
      modelVersion: json['model_version'] as String? ?? '',
      inputReference: json['input_reference'] as String?,
      outputSummary: json['output_summary'] as String?,
      confidenceScore: (json['confidence_score'] as num?)?.toDouble(),
      approvingUserId: json['approving_user_id'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

/// NAKHL & NAHL — AI & Intelligence Yönetim Servisi
class AiIntelligenceRepository {
  AiIntelligenceRepository._();
  static final AiIntelligenceRepository instance = AiIntelligenceRepository._();

  /// OCR Çıkarımı Oluştur (Her zaman taslak öneri olarak üretilir!)
  Future<OcrExtractionModel?> createOcrDraft({
    required String companyId,
    String? documentId,
    String? imageStorageRef,
    required String invoiceNumber,
    DateTime? date,
    String? supplierName,
    String? customerName,
    String? productName,
    required double quantity,
    required double price,
    required double taxRate,
    required double taxAmount,
    String currency = 'SAR',
    double confidenceScore = 0.95,
  }) async {
    final tenantId = TenantContext.instance.activeTenantId;
    if (tenantId == null) return null;

    try {
      final res = await SupabaseService.client
          .from('ai_ocr_extractions')
          .insert({
            'tenant_id': tenantId,
            'company_id': companyId,
            'document_id': documentId,
            'image_storage_ref': imageStorageRef,
            'extracted_invoice_number': invoiceNumber,
            'extracted_date': date?.toIso8601String().substring(0, 10),
            'extracted_supplier_name': supplierName,
            'extracted_customer_name': customerName,
            'extracted_product_name': productName,
            'extracted_quantity': quantity,
            'extracted_price': price,
            'extracted_tax_rate': taxRate,
            'extracted_tax_amount': taxAmount,
            'extracted_currency': currency,
            'confidence_score': confidenceScore,
            'model_name': 'nakhl-ocr-engine',
            'model_version': 'v2.4',
            'status': 'DRAFT_SUGGESTION', // Doğrudan POST engellidir!
          })
          .select()
          .single();

      return OcrExtractionModel.fromJson(res);
    } catch (_) {
      return null;
    }
  }

  /// OCR Taslağını İnsan Onayı ile Onayla (Human-in-the-Loop)
  Future<bool> approveOcrDraft({
    required String ocrId,
    required String humanUserId,
    String? notes,
  }) async {
    try {
      await SupabaseService.client.from('ai_ocr_extractions').update({
        'status': 'APPROVED',
        'reviewed_by_user_id': humanUserId,
        'review_notes': notes ?? 'İnsan denetçi tarafından onaylandı',
        'reviewed_at': DateTime.now().toIso8601String(),
      }).eq('id', ocrId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Belge Sınıflandırma
  Future<DocumentClassificationModel?> classifyDocument({
    required String companyId,
    required String documentId,
    required AiDocumentClass predictedClass,
    double confidenceScore = 0.95,
    List<String> secondaryTags = const [],
  }) async {
    final tenantId = TenantContext.instance.activeTenantId;
    if (tenantId == null) return null;

    try {
      final res = await SupabaseService.client
          .from('ai_document_classifications')
          .insert({
            'tenant_id': tenantId,
            'company_id': companyId,
            'document_id': documentId,
            'predicted_class': predictedClass.dbValue,
            'confidence_score': confidenceScore,
            'secondary_tags': secondaryTags,
            'model_name': 'nakhl-doc-classifier',
            'model_version': 'v1.5',
          })
          .select()
          .single();

      return DocumentClassificationModel.fromJson(res);
    } catch (_) {
      return null;
    }
  }

  /// Ticari Öneri Kaydet
  Future<CommercialSuggestionModel?> createCommercialSuggestion({
    required String companyId,
    required AiSuggestionType suggestionType,
    required String targetEntityType,
    String? targetEntityId,
    required Map<String, dynamic> payload,
    String? explanationText,
    double confidenceScore = 0.90,
  }) async {
    final tenantId = TenantContext.instance.activeTenantId;
    if (tenantId == null) return null;

    try {
      final res = await SupabaseService.client
          .from('ai_commercial_suggestions')
          .insert({
            'tenant_id': tenantId,
            'company_id': companyId,
            'suggestion_type': suggestionType.dbValue,
            'target_entity_type': targetEntityType,
            'target_entity_id': targetEntityId,
            'suggestion_payload': payload,
            'explanation_text': explanationText,
            'confidence_score': confidenceScore,
            'model_name': 'nakhl-commercial-intelligence',
            'model_version': 'v2.1',
            'status': 'PENDING_HUMAN_REVIEW',
          })
          .select()
          .single();

      return CommercialSuggestionModel.fromJson(res);
    } catch (_) {
      return null;
    }
  }

  /// Kritik Ticari İşlem Doğrulaması (İnsan Onayı Kontrolü)
  /// ACCOUNTING_POST, STOCK_POST, PAYMENT, EXPORT_FINALIZATION, LEGAL_DOCUMENT_FINALIZATION
  Future<bool> validateCriticalAction({
    required String actionType,
    required String? humanUserId,
    String? notes,
  }) async {
    if (humanUserId == null || humanUserId.isEmpty) {
      return false; // İnsan onayı olmadan otonom AI işlemi kesinlikle engellenir!
    }

    try {
      final res = await SupabaseService.client
          .rpc('validate_critical_commercial_action', params: {
        'p_action_type': actionType,
        'p_human_user_id': humanUserId,
        'p_action_notes': notes,
      });
      return res == true;
    } catch (_) {
      return false;
    }
  }

  /// AI Denetim İzi Kaydı
  Future<bool> logAiAction({
    required String companyId,
    required String actionType,
    required String modelName,
    required String modelVersion,
    String? inputReference,
    String? outputSummary,
    double? confidenceScore,
    String? approvingUserId,
  }) async {
    final tenantId = TenantContext.instance.activeTenantId;
    if (tenantId == null) return false;

    try {
      await SupabaseService.client.from('ai_audit_logs').insert({
        'tenant_id': tenantId,
        'company_id': companyId,
        'action_type': actionType,
        'model_name': modelName,
        'model_version': modelVersion,
        'input_reference': inputReference,
        'output_summary': outputSummary,
        'confidence_score': confidenceScore,
        'approving_user_id': approvingUserId,
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}
