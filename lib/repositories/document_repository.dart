import '../services/supabase_service.dart';
import '../core/tenant/tenant_context.dart';

class DocumentModel {
  final String id;
  final String documentType;
  final String documentNumber;
  final String title;
  final String entityType;
  final String entityId;
  final DateTime issueDate;
  final DateTime? expiryDate;
  final String status;
  final String storageReference;
  final String fileName;
  final int fileSizeBytes;
  final String mimeType;
  final int currentVersion;
  final bool isLatest;
  final Map<String, dynamic> metadata;
  final String? createdByUserId;
  final DateTime createdAt;

  const DocumentModel({
    required this.id,
    required this.documentType,
    required this.documentNumber,
    required this.title,
    required this.entityType,
    required this.entityId,
    required this.issueDate,
    this.expiryDate,
    required this.status,
    required this.storageReference,
    required this.fileName,
    required this.fileSizeBytes,
    required this.mimeType,
    required this.currentVersion,
    required this.isLatest,
    this.metadata = const {},
    this.createdByUserId,
    required this.createdAt,
  });

  bool get isExpired =>
      expiryDate != null && expiryDate!.isBefore(DateTime.now());

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] as String,
      documentType: json['document_type'] as String,
      documentNumber: json['document_number'] as String? ?? '',
      title: json['title'] as String? ?? '',
      entityType: json['entity_type'] as String? ?? '',
      entityId: json['entity_id'] as String? ?? '',
      issueDate: DateTime.parse(json['issue_date'] as String),
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'] as String)
          : null,
      status: json['status'] as String? ?? 'DRAFT',
      storageReference: json['storage_reference'] as String? ?? '',
      fileName: json['file_name'] as String? ?? '',
      fileSizeBytes: (json['file_size_bytes'] as num?)?.toInt() ?? 0,
      mimeType: json['mime_type'] as String? ?? 'application/pdf',
      currentVersion: (json['current_version'] as num?)?.toInt() ?? 1,
      isLatest: json['is_latest'] as bool? ?? true,
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
      createdByUserId: json['created_by_user_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class DocumentVersionModel {
  final String id;
  final String documentId;
  final int versionNumber;
  final String storageReference;
  final String fileName;
  final int fileSizeBytes;
  final String mimeType;
  final String? changeSummary;
  final String? uploadedByUserId;
  final DateTime createdAt;

  const DocumentVersionModel({
    required this.id,
    required this.documentId,
    required this.versionNumber,
    required this.storageReference,
    required this.fileName,
    required this.fileSizeBytes,
    required this.mimeType,
    this.changeSummary,
    this.uploadedByUserId,
    required this.createdAt,
  });

  factory DocumentVersionModel.fromJson(Map<String, dynamic> json) {
    return DocumentVersionModel(
      id: json['id'] as String,
      documentId: json['document_id'] as String,
      versionNumber: (json['version_number'] as num).toInt(),
      storageReference: json['storage_reference'] as String? ?? '',
      fileName: json['file_name'] as String? ?? '',
      fileSizeBytes: (json['file_size_bytes'] as num?)?.toInt() ?? 0,
      mimeType: json['mime_type'] as String? ?? 'application/pdf',
      changeSummary: json['change_summary'] as String?,
      uploadedByUserId: json['uploaded_by_user_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class DocumentAccessLogModel {
  final int id;
  final String documentId;
  final String? userId;
  final String action; // UPLOAD, VIEW, DOWNLOAD, REPLACE, APPROVE, REJECT
  final int versionNumber;
  final String? notes;
  final DateTime createdAt;

  const DocumentAccessLogModel({
    required this.id,
    required this.documentId,
    this.userId,
    required this.action,
    required this.versionNumber,
    this.notes,
    required this.createdAt,
  });

  factory DocumentAccessLogModel.fromJson(Map<String, dynamic> json) {
    return DocumentAccessLogModel(
      id: (json['id'] as num).toInt(),
      documentId: json['document_id'] as String,
      userId: json['user_id'] as String?,
      action: json['action'] as String? ?? 'VIEW',
      versionNumber: (json['version_number'] as num?)?.toInt() ?? 1,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class DocumentExpiryAlertModel {
  final String documentId;
  final String documentType;
  final String documentNumber;
  final String title;
  final String entityType;
  final String entityId;
  final DateTime? expiryDate;
  final int daysRemaining;
  final String alertLevel; // EXPIRED, CRITICAL_30_DAYS, WARNING_60_DAYS, VALID
  final String status;

  const DocumentExpiryAlertModel({
    required this.documentId,
    required this.documentType,
    required this.documentNumber,
    required this.title,
    required this.entityType,
    required this.entityId,
    this.expiryDate,
    required this.daysRemaining,
    required this.alertLevel,
    required this.status,
  });

  factory DocumentExpiryAlertModel.fromJson(Map<String, dynamic> json) {
    return DocumentExpiryAlertModel(
      documentId: json['document_id'] as String,
      documentType: json['document_type'] as String,
      documentNumber: json['document_number'] as String? ?? '',
      title: json['title'] as String? ?? '',
      entityType: json['entity_type'] as String? ?? '',
      entityId: json['entity_id'] as String? ?? '',
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'] as String)
          : null,
      daysRemaining: (json['days_remaining'] as num?)?.toInt() ?? 0,
      alertLevel: json['alert_level'] as String? ?? 'VALID',
      status: json['status'] as String? ?? 'APPROVED',
    );
  }
}

class DocumentRepository {
  DocumentRepository._();
  static final DocumentRepository instance = DocumentRepository._();

  /// Şirketin dokümanlarını listeler (İsteğe bağlı tip veya entity filtresi ile)
  Future<List<DocumentModel>> getDocuments(
    String companyId, {
    String? documentType,
    String? entityType,
    String? entityId,
  }) async {
    try {
      var query = SupabaseService.client
          .from('documents')
          .select()
          .eq('company_id', companyId);

      if (documentType != null) {
        query = query.eq('document_type', documentType);
      }
      if (entityType != null) {
        query = query.eq('entity_type', entityType);
      }
      if (entityId != null) {
        query = query.eq('entity_id', entityId);
      }

      final response = await query.order('created_at', ascending: false);
      return (response as List<dynamic>)
          .map((data) => DocumentModel.fromJson(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Yeni Doküman Yükler (v1 versiyon kaydı ve UPLOAD audit logu ile)
  Future<String?> uploadDocument({
    required String companyId,
    required String documentType,
    required String documentNumber,
    required String title,
    required String entityType,
    required String entityId,
    DateTime? issueDate,
    DateTime? expiryDate,
    required String storageReference,
    required String fileName,
    int fileSizeBytes = 0,
    String mimeType = 'application/pdf',
    String? userId,
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      final tenantId = TenantContext.instance.activeTenantId;
      if (tenantId == null) throw Exception('Aktif tenant seçilmedi.');

      // 1. Doküman Master Kaydı
      final docRes = await SupabaseService.client
          .from('documents')
          .insert({
            'tenant_id': tenantId,
            'company_id': companyId,
            'document_type': documentType,
            'document_number': documentNumber.trim(),
            'title': title.trim(),
            'entity_type': entityType,
            'entity_id': entityId,
            'issue_date': (issueDate ?? DateTime.now())
                .toIso8601String()
                .substring(0, 10),
            'expiry_date': expiryDate?.toIso8601String().substring(0, 10),
            'status': 'APPROVED',
            'storage_reference': storageReference,
            'file_name': fileName,
            'file_size_bytes': fileSizeBytes,
            'mime_type': mimeType,
            'current_version': 1,
            'is_latest': true,
            'metadata': metadata,
            'created_by_user_id': userId,
          })
          .select('id')
          .single();

      final docId = docRes['id'] as String;

      // 2. v1 Versiyon Kaydı
      await SupabaseService.client.from('document_versions').insert({
        'tenant_id': tenantId,
        'company_id': companyId,
        'document_id': docId,
        'version_number': 1,
        'storage_reference': storageReference,
        'file_name': fileName,
        'file_size_bytes': fileSizeBytes,
        'mime_type': mimeType,
        'change_summary': 'İlk versiyon (v1) yüklendi',
        'uploaded_by_user_id': userId,
      });

      // 3. Denetim İzi (Audit Logger RPC)
      await SupabaseService.client.rpc('log_document_access', params: {
        'p_doc_id': docId,
        'p_action': 'UPLOAD',
        'p_user_id': userId,
        'p_notes': 'Doküman v1 başarıyla yüklendi: $fileName',
      });

      return docId;
    } catch (e) {
      rethrow;
    }
  }

  /// Dokümanı Yeniler / Yeni Versiyon Ekler (REPLACE)
  Future<int> replaceDocumentVersion({
    required String documentId,
    required String companyId,
    required String newStorageReference,
    required String newFileName,
    int newFileSizeBytes = 0,
    String newMimeType = 'application/pdf',
    required String changeSummary,
    String? userId,
  }) async {
    try {
      final tenantId = TenantContext.instance.activeTenantId;
      if (tenantId == null) throw Exception('Aktif tenant seçilmedi.');

      // Mevcut dokümanı getir
      final currentDoc = await SupabaseService.client
          .from('documents')
          .select('current_version')
          .eq('id', documentId)
          .single();

      final nextVersion =
          ((currentDoc['current_version'] as num?)?.toInt() ?? 1) + 1;

      // Yeni versiyon kaydı
      await SupabaseService.client.from('document_versions').insert({
        'tenant_id': tenantId,
        'company_id': companyId,
        'document_id': documentId,
        'version_number': nextVersion,
        'storage_reference': newStorageReference,
        'file_name': newFileName,
        'file_size_bytes': newFileSizeBytes,
        'mime_type': newMimeType,
        'change_summary': changeSummary,
        'uploaded_by_user_id': userId,
      });

      // Master dokümanı güncelle
      await SupabaseService.client.from('documents').update({
        'storage_reference': newStorageReference,
        'file_name': newFileName,
        'file_size_bytes': newFileSizeBytes,
        'mime_type': newMimeType,
        'current_version': nextVersion,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', documentId);

      // Audit Logger
      await SupabaseService.client.rpc('log_document_access', params: {
        'p_doc_id': documentId,
        'p_action': 'REPLACE',
        'p_user_id': userId,
        'p_notes':
            'Doküman v$nextVersion versiyonuna güncellendi: $changeSummary',
      });

      return nextVersion;
    } catch (e) {
      rethrow;
    }
  }

  /// Doküman Erişimini (VIEW veya DOWNLOAD) Denetim Kütüğüne Kaydeder
  Future<void> logDocumentAccess({
    required String documentId,
    required String action, // VIEW, DOWNLOAD, APPROVE, REJECT
    String? userId,
    String? notes,
  }) async {
    try {
      await SupabaseService.client.rpc('log_document_access', params: {
        'p_doc_id': documentId,
        'p_action': action,
        'p_user_id': userId,
        'p_notes': notes,
      });
    } catch (e) {
      // Hata fırlatma arayüz akışını kesmesin
    }
  }

  /// Dokümanı Onayla (APPROVE)
  Future<void> approveDocument({
    required String documentId,
    String? userId,
    String? notes,
  }) async {
    try {
      await SupabaseService.client.from('documents').update({
        'status': 'APPROVED',
        'updated_at': DateTime.now().toIso8601String()
      }).eq('id', documentId);

      await logDocumentAccess(
        documentId: documentId,
        action: 'APPROVE',
        userId: userId,
        notes: notes ?? 'Doküman onaylandı',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Dokümanı Reddet (REJECT)
  Future<void> rejectDocument({
    required String documentId,
    String? userId,
    String? notes,
  }) async {
    try {
      await SupabaseService.client.from('documents').update({
        'status': 'REJECTED',
        'updated_at': DateTime.now().toIso8601String()
      }).eq('id', documentId);

      await logDocumentAccess(
        documentId: documentId,
        action: 'REJECT',
        userId: userId,
        notes: notes ?? 'Doküman reddedildi',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Süreli Belgeler için Expiry Uyarılarını Listeler
  Future<List<DocumentExpiryAlertModel>> getDocumentExpiryAlerts(
      String companyId) async {
    try {
      final response = await SupabaseService.client
          .from('view_document_expiry_alerts')
          .select()
          .eq('company_id', companyId)
          .order('days_remaining', ascending: true);

      return (response as List<dynamic>)
          .map((data) =>
              DocumentExpiryAlertModel.fromJson(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
