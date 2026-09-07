import '../services/supabase_service.dart';
import '../core/tenant/tenant_context.dart';

/// Denetim Eylemleri (10 Temel Ticari & Sistem Eylemi)
enum AuditAction {
  create,
  update,
  post,
  approve,
  reject,
  reverse,
  export,
  import,
  login,
  logout;

  String get dbValue {
    switch (this) {
      case AuditAction.create:
        return 'CREATE';
      case AuditAction.update:
        return 'UPDATE';
      case AuditAction.post:
        return 'POST';
      case AuditAction.approve:
        return 'APPROVE';
      case AuditAction.reject:
        return 'REJECT';
      case AuditAction.reverse:
        return 'REVERSE';
      case AuditAction.export:
        return 'EXPORT';
      case AuditAction.import:
        return 'IMPORT';
      case AuditAction.login:
        return 'LOGIN';
      case AuditAction.logout:
        return 'LOGOUT';
    }
  }

  static AuditAction fromDbValue(String val) {
    switch (val.toUpperCase()) {
      case 'CREATE':
        return AuditAction.create;
      case 'UPDATE':
        return AuditAction.update;
      case 'POST':
        return AuditAction.post;
      case 'APPROVE':
        return AuditAction.approve;
      case 'REJECT':
        return AuditAction.reject;
      case 'REVERSE':
        return AuditAction.reverse;
      case 'EXPORT':
        return AuditAction.export;
      case 'IMPORT':
        return AuditAction.import;
      case 'LOGIN':
        return AuditAction.login;
      case 'LOGOUT':
        return AuditAction.logout;
      default:
        return AuditAction.create;
    }
  }
}

/// Denetim Kaydı Modeli (Append-Only Audit Log)
class AuditLogModel {
  final int id;
  final String tenantId;
  final String? companyId;
  final String? userId;
  final AuditAction action;
  final String entityType;
  final String entityId;
  final Map<String, dynamic>? oldData;
  final Map<String, dynamic>? newData;
  final String actorRole;
  final String? ipAddress;
  final String? userAgent;
  final String? recordHash;
  final String? prevHash;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const AuditLogModel({
    required this.id,
    required this.tenantId,
    this.companyId,
    this.userId,
    required this.action,
    required this.entityType,
    required this.entityId,
    this.oldData,
    this.newData,
    required this.actorRole,
    this.ipAddress,
    this.userAgent,
    this.recordHash,
    this.prevHash,
    required this.metadata,
    required this.createdAt,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      tenantId: json['tenant_id']?.toString() ?? '',
      companyId: json['company_id']?.toString(),
      userId: json['user_id']?.toString(),
      action: AuditAction.fromDbValue(json['action']?.toString() ?? 'CREATE'),
      entityType: json['entity_type']?.toString() ?? '',
      entityId: json['entity_id']?.toString() ?? '',
      oldData: json['old_data'] != null
          ? Map<String, dynamic>.from(json['old_data'] as Map)
          : null,
      newData: json['new_data'] != null
          ? Map<String, dynamic>.from(json['new_data'] as Map)
          : null,
      actorRole: json['actor_role']?.toString() ?? 'USER',
      ipAddress: json['ip_address']?.toString(),
      userAgent: json['user_agent']?.toString(),
      recordHash: json['record_hash']?.toString(),
      prevHash: json['prev_hash']?.toString(),
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : {},
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'company_id': companyId,
      'user_id': userId,
      'action': action.dbValue,
      'entity_type': entityType,
      'entity_id': entityId,
      'old_data': oldData,
      'new_data': newData,
      'actor_role': actorRole,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'record_hash': recordHash,
      'prev_hash': prevHash,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Kriptografik Zincir Doğrulama Sonuç Modeli
class AuditIntegrityResultModel {
  final String tenantId;
  final int totalRecordsChecked;
  final bool isValid;
  final int? tamperedRecordId;
  final String? tamperReason;
  final DateTime verifiedAt;

  const AuditIntegrityResultModel({
    required this.tenantId,
    required this.totalRecordsChecked,
    required this.isValid,
    this.tamperedRecordId,
    this.tamperReason,
    required this.verifiedAt,
  });

  factory AuditIntegrityResultModel.fromJson(Map<String, dynamic> json) {
    return AuditIntegrityResultModel(
      tenantId: json['tenant_id']?.toString() ?? '',
      totalRecordsChecked:
          (json['total_records_checked'] as num?)?.toInt() ?? 0,
      isValid: json['is_valid'] as bool? ?? false,
      tamperedRecordId: (json['tampered_record_id'] as num?)?.toInt(),
      tamperReason: json['tamper_reason'] as String?,
      verifiedAt: DateTime.tryParse(json['verified_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

/// Denetim Saklama ve İmha Politikası Modeli
class AuditRetentionPolicyModel {
  final String tenantId;
  final int retentionPeriodYears;
  final String storageClass;
  final bool automatedPurgeEnabled;
  final List<String> legalFrameworks;
  final String destructionPolicy;

  const AuditRetentionPolicyModel({
    required this.tenantId,
    required this.retentionPeriodYears,
    required this.storageClass,
    required this.automatedPurgeEnabled,
    required this.legalFrameworks,
    required this.destructionPolicy,
  });

  factory AuditRetentionPolicyModel.fromJson(Map<String, dynamic> json) {
    return AuditRetentionPolicyModel(
      tenantId: json['tenant_id']?.toString() ?? '',
      retentionPeriodYears:
          (json['retention_period_years'] as num?)?.toInt() ?? 10,
      storageClass:
          json['storage_class']?.toString() ?? 'WORM_COMPLIANT_COLD_STORAGE',
      automatedPurgeEnabled: json['automated_purge_enabled'] as bool? ?? false,
      legalFrameworks: (json['legal_frameworks'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      destructionPolicy: json['destruction_policy']?.toString() ?? '',
    );
  }
}

/// NAKHL & NAHL — Denetim ve Uyumluluk Servisi (Audit + Compliance Hardening)
class AuditComplianceRepository {
  AuditComplianceRepository._();
  static final AuditComplianceRepository instance =
      AuditComplianceRepository._();

  String get _tenantId => TenantContext.instance.activeTenantId ?? '';
  String get _companyId => TenantContext.instance.activeCompanyId ?? '';
  String? get _userId => TenantContext.instance.userId;

  /// 1. Kritik Ticari İşlemi Audit Et
  Future<int?> logEvent({
    required AuditAction action,
    required String entityType,
    required String entityId,
    Map<String, dynamic>? oldData,
    Map<String, dynamic>? newData,
    String actorRole = 'USER',
    String? ipAddress,
    String? userAgent,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final res = await SupabaseService.client.rpc(
        'log_audit_event',
        params: {
          'p_action': action.dbValue,
          'p_entity_type': entityType,
          'p_entity_id': entityId,
          'p_tenant_id': _tenantId,
          'p_company_id': _companyId.isNotEmpty ? _companyId : null,
          'p_user_id': _userId,
          'p_old_data': oldData,
          'p_new_data': newData,
          'p_actor_role': actorRole,
          'p_ip_address': ipAddress,
          'p_user_agent': userAgent,
          'p_metadata': metadata ?? {},
        },
      );
      return (res as num?)?.toInt();
    } catch (_) {
      return null;
    }
  }

  /// 2. Tenant Denetim Kayıtlarını Listele
  Future<List<AuditLogModel>> getAuditLogs({
    AuditAction? action,
    String? entityType,
    int limit = 100,
  }) async {
    var query = SupabaseService.client
        .from('audit_logs')
        .select()
        .eq('tenant_id', _tenantId);

    if (action != null) {
      query = query.eq('action', action.dbValue);
    }
    if (entityType != null && entityType.isNotEmpty) {
      query = query.eq('entity_type', entityType);
    }

    final response =
        await query.order('created_at', ascending: false).limit(limit);
    return (response as List)
        .map((e) => AuditLogModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// 3. Kriptografik Zincir Değiştirilemezlik ve Bütünlük Doğrulaması
  Future<AuditIntegrityResultModel?> verifyChainIntegrity() async {
    try {
      final res = await SupabaseService.client.rpc(
        'verify_audit_log_chain_integrity',
        params: {'p_tenant_id': _tenantId},
      );
      if (res is Map<String, dynamic>) {
        return AuditIntegrityResultModel.fromJson(res);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// 4. Denetim Saklama Politikasını Getir
  Future<AuditRetentionPolicyModel?> getRetentionPolicy() async {
    try {
      final res = await SupabaseService.client
          .from('audit_retention_policies')
          .select()
          .eq('tenant_id', _tenantId)
          .maybeSingle();

      if (res != null) {
        return AuditRetentionPolicyModel.fromJson(
            Map<String, dynamic>.from(res));
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
