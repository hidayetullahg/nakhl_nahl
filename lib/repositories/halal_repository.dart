import '../services/supabase_service.dart';
import '../core/tenant/tenant_context.dart';

class HalalCertificate {
  final String id;
  final String certificateNumber;
  final String bodyName;
  final DateTime issueDate;
  final DateTime expiryDate;
  final String status;
  final String? scopeDescription;
  final String? documentUrl;
  final String? notes;

  const HalalCertificate({
    required this.id,
    required this.certificateNumber,
    required this.bodyName,
    required this.issueDate,
    required this.expiryDate,
    required this.status,
    this.scopeDescription,
    this.documentUrl,
    this.notes,
  });

  /// Expiry kuralı: Geçerlilik tarihi geçmişse ASLA valid kabul edilmez
  bool get isValid =>
      (status == 'ACTIVE' || status == 'VALID') &&
      expiryDate.isAfter(DateTime.now());

  factory HalalCertificate.fromJson(Map<String, dynamic> json) {
    final bodyData =
        json['halal_certification_bodies'] as Map<String, dynamic>?;
    return HalalCertificate(
      id: json['id'] as String,
      certificateNumber: json['certificate_number'] as String? ?? '',
      bodyName: bodyData?['name'] as String? ??
          json['body_name'] as String? ??
          'Bilinmeyen Kurul',
      issueDate: DateTime.parse(json['issue_date'] as String),
      expiryDate: DateTime.parse(json['expiry_date'] as String),
      status: json['status'] as String? ?? 'ACTIVE',
      scopeDescription: json['scope_description'] as String?,
      documentUrl: json['document_url'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'certificate_number': certificateNumber,
        'issue_date': issueDate.toIso8601String().substring(0, 10),
        'expiry_date': expiryDate.toIso8601String().substring(0, 10),
        'status': status,
        'scope_description': scopeDescription,
        'document_url': documentUrl,
        'notes': notes,
      };
}

class SupplierHalalModel {
  final String id;
  final String supplierPartyId;
  final String? certificateId;
  final String
      complianceStatus; // COMPLIANT, NON_COMPLIANT, EXPIRED, PENDING_AUDIT
  final DateTime? auditDate;
  final DateTime validUntil;
  final String? notes;

  const SupplierHalalModel({
    required this.id,
    required this.supplierPartyId,
    this.certificateId,
    required this.complianceStatus,
    this.auditDate,
    required this.validUntil,
    this.notes,
  });

  bool get isValid =>
      complianceStatus == 'COMPLIANT' && validUntil.isAfter(DateTime.now());

  factory SupplierHalalModel.fromJson(Map<String, dynamic> json) {
    return SupplierHalalModel(
      id: json['id'] as String,
      supplierPartyId: json['supplier_party_id'] as String,
      certificateId: json['certificate_id'] as String?,
      complianceStatus: json['compliance_status'] as String? ?? 'COMPLIANT',
      auditDate: json['audit_date'] != null
          ? DateTime.parse(json['audit_date'] as String)
          : null,
      validUntil: DateTime.parse(json['valid_until'] as String),
      notes: json['notes'] as String?,
    );
  }
}

class FacilityHalalModel {
  final String id;
  final String businessUnitId;
  final String certificateId;
  final String processStep;
  final bool isHalalCertified;
  final DateTime verifiedAt;
  final String? inspectorName;
  final String? notes;

  const FacilityHalalModel({
    required this.id,
    required this.businessUnitId,
    required this.certificateId,
    required this.processStep,
    required this.isHalalCertified,
    required this.verifiedAt,
    this.inspectorName,
    this.notes,
  });

  factory FacilityHalalModel.fromJson(Map<String, dynamic> json) {
    return FacilityHalalModel(
      id: json['id'] as String,
      businessUnitId: json['business_unit_id'] as String,
      certificateId: json['certificate_id'] as String,
      processStep: json['process_step'] as String? ?? 'ALL',
      isHalalCertified: json['is_halal_certified'] as bool? ?? true,
      verifiedAt: DateTime.parse(json['verified_at'] as String),
      inspectorName: json['inspector_name'] as String?,
      notes: json['notes'] as String?,
    );
  }
}

class ShipmentHalalDocModel {
  final String id;
  final String? salesOrderId;
  final String certificateId;
  final String documentType;
  final String documentNumber;
  final DateTime issuedAt;
  final String? documentUrl;

  const ShipmentHalalDocModel({
    required this.id,
    this.salesOrderId,
    required this.certificateId,
    required this.documentType,
    required this.documentNumber,
    required this.issuedAt,
    this.documentUrl,
  });

  factory ShipmentHalalDocModel.fromJson(Map<String, dynamic> json) {
    return ShipmentHalalDocModel(
      id: json['id'] as String,
      salesOrderId: json['sales_order_id'] as String?,
      certificateId: json['certificate_id'] as String,
      documentType: json['document_type'] as String,
      documentNumber: json['document_number'] as String? ?? '',
      issuedAt: DateTime.parse(json['issued_at'] as String),
      documentUrl: json['document_url'] as String?,
    );
  }
}

class HalalAiAdvisoryModel {
  final String id;
  final String targetType; // LOT, PRODUCT, SUPPLIER, PROCESS, SHIPMENT
  final String targetId;
  final double riskScore;
  final String aiRecommendationText;
  final List<dynamic> aiFlags;
  final String humanDecision; // PENDING, APPROVED, REJECTED, CONDITIONAL
  final String? humanReviewerUserId;
  final String? humanDecisionNotes;
  final DateTime? decidedAt;
  final DateTime createdAt;

  const HalalAiAdvisoryModel({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.riskScore,
    required this.aiRecommendationText,
    this.aiFlags = const [],
    this.humanDecision = 'PENDING',
    this.humanReviewerUserId,
    this.humanDecisionNotes,
    this.decidedAt,
    required this.createdAt,
  });

  bool get isDecided => humanDecision != 'PENDING';
  bool get isApproved => humanDecision == 'APPROVED';

  factory HalalAiAdvisoryModel.fromJson(Map<String, dynamic> json) {
    return HalalAiAdvisoryModel(
      id: json['id'] as String,
      targetType: json['target_type'] as String,
      targetId: json['target_id'] as String,
      riskScore: (json['risk_score'] as num?)?.toDouble() ?? 0.0,
      aiRecommendationText: json['ai_recommendation_text'] as String? ?? '',
      aiFlags: json['ai_flags'] as List<dynamic>? ?? const [],
      humanDecision: json['human_decision'] as String? ?? 'PENDING',
      humanReviewerUserId: json['human_reviewer_user_id'] as String?,
      humanDecisionNotes: json['human_decision_notes'] as String?,
      decidedAt: json['decided_at'] != null
          ? DateTime.parse(json['decided_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class HalalRepository {
  HalalRepository._();
  static final HalalRepository instance = HalalRepository._();

  /// Şirketin tüm helal sertifikalarını listeler
  Future<List<HalalCertificate>> getCertificates(String companyId) async {
    try {
      final response = await SupabaseService.client
          .from('halal_certificates')
          .select('*, halal_certification_bodies(name)')
          .eq('company_id', companyId)
          .order('expiry_date', ascending: true);

      final List<HalalCertificate> list = [];
      for (final row in (response as List<dynamic>)) {
        list.add(HalalCertificate.fromJson(row as Map<String, dynamic>));
      }
      return list;
    } catch (e) {
      return [];
    }
  }

  /// Yalnızca geçerli (süresi dolmamış ve ACTIVE/VALID) sertifikaları listeler
  Future<List<HalalCertificate>> getValidCertificates(String companyId) async {
    try {
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final response = await SupabaseService.client
          .from('halal_certificates')
          .select('*, halal_certification_bodies(name)')
          .eq('company_id', companyId)
          .inFilter('status', ['ACTIVE', 'VALID'])
          .gte('expiry_date', todayStr)
          .order('expiry_date', ascending: true);

      final List<HalalCertificate> list = [];
      for (final row in (response as List<dynamic>)) {
        list.add(HalalCertificate.fromJson(row as Map<String, dynamic>));
      }
      return list;
    } catch (e) {
      return [];
    }
  }

  /// Bir ürünün veya partinin helal sertifikası kapsamında olup olmadığını doğrular
  Future<bool> isItemHalalCertified({
    required String itemId,
    String? businessUnitId,
  }) async {
    try {
      final tenantId = TenantContext.instance.activeTenantId;
      if (tenantId == null) return false;

      var query = SupabaseService.client
          .from('halal_scope_items')
          .select('id, halal_certificates!inner(status, expiry_date)')
          .eq('item_id', itemId)
          .inFilter('halal_certificates.status', ['ACTIVE', 'VALID']).gte(
              'halal_certificates.expiry_date',
              DateTime.now().toIso8601String().substring(0, 10));

      if (businessUnitId != null) {
        query = query.eq('business_unit_id', businessUnitId);
      }

      final res = await query;
      return (res as List).isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Tedarikçi helal durumunu getirir
  Future<SupplierHalalModel?> getSupplierHalalStatus(
      String supplierPartyId) async {
    try {
      final response = await SupabaseService.client
          .from('supplier_halal_compliance')
          .select()
          .eq('supplier_party_id', supplierPartyId)
          .order('valid_until', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return SupplierHalalModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Tesis ve proses adımlarının sertifikalarını getirir
  Future<List<FacilityHalalModel>> getFacilityProcessCertifications(
      String businessUnitId) async {
    try {
      final response = await SupabaseService.client
          .from('facility_halal_certifications')
          .select()
          .eq('business_unit_id', businessUnitId)
          .order('process_step', ascending: true);

      return (response as List<dynamic>)
          .map(
              (row) => FacilityHalalModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Sevkiyata ait helal evraklarını getirir
  Future<List<ShipmentHalalDocModel>> getShipmentHalalDocuments(
      String salesOrderId) async {
    try {
      final response = await SupabaseService.client
          .from('shipment_halal_documents')
          .select()
          .eq('sales_order_id', salesOrderId)
          .order('issued_at', ascending: false);

      return (response as List<dynamic>)
          .map((row) =>
              ShipmentHalalDocModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// AI Helal Öneri/Uyarı kaydı ekler (Nihai karar her zaman PENDING olarak başlar)
  Future<String?> createAiAdvisory({
    required String companyId,
    required String targetType,
    required String targetId,
    required double riskScore,
    required String aiRecommendationText,
    List<dynamic> aiFlags = const [],
  }) async {
    try {
      final tenantId = TenantContext.instance.activeTenantId;
      if (tenantId == null) throw Exception('Aktif tenant seçilmedi.');

      final res = await SupabaseService.client
          .from('halal_ai_advisories')
          .insert({
            'tenant_id': tenantId,
            'company_id': companyId,
            'target_type': targetType,
            'target_id': targetId,
            'risk_score': riskScore,
            'ai_recommendation_text': aiRecommendationText,
            'ai_flags': aiFlags,
            'human_decision': 'PENDING',
          })
          .select('id')
          .single();

      return res['id'] as String;
    } catch (e) {
      rethrow;
    }
  }

  /// Nihai Helal Uygunluk Kararını kaydeder (Zorunlu İnsan Denetçi)
  Future<void> submitHumanDecision({
    required String advisoryId,
    required String reviewerUserId,
    required String decision, // APPROVED, REJECTED, CONDITIONAL
    String? notes,
  }) async {
    if (reviewerUserId.trim().isEmpty) {
      throw ArgumentError(
          'Helal nihai kararı insan denetçi olmadan onaylanamaz!');
    }
    if (!['APPROVED', 'REJECTED', 'CONDITIONAL'].contains(decision)) {
      throw ArgumentError('Geçersiz karar tipi: $decision');
    }

    try {
      await SupabaseService.client.from('halal_ai_advisories').update({
        'human_decision': decision,
        'human_reviewer_user_id': reviewerUserId,
        'human_decision_notes': notes,
        'decided_at': DateTime.now().toIso8601String(),
      }).eq('id', advisoryId);
    } catch (e) {
      rethrow;
    }
  }

  /// Yeni Helal Sertifikası ekler
  Future<String?> addCertificate({
    required String companyId,
    required String bodyId,
    required String certificateNumber,
    required DateTime issueDate,
    required DateTime expiryDate,
    String? scopeDescription,
    String? documentUrl,
    String? notes,
  }) async {
    try {
      final tenantId = TenantContext.instance.activeTenantId;
      if (tenantId == null) throw Exception('Aktif tenant seçilmedi.');

      // Süresi geçmiş sertifikayı engelle
      if (expiryDate.isBefore(DateTime.now())) {
        throw ArgumentError('Süresi geçmiş sertifika eklenemez!');
      }

      final res = await SupabaseService.client
          .from('halal_certificates')
          .insert({
            'tenant_id': tenantId,
            'company_id': companyId,
            'body_id': bodyId,
            'certificate_number': certificateNumber.trim(),
            'issue_date': issueDate.toIso8601String().substring(0, 10),
            'expiry_date': expiryDate.toIso8601String().substring(0, 10),
            'status': 'VALID',
            'scope_description': scopeDescription,
            'document_url': documentUrl,
            'notes': notes,
          })
          .select('id')
          .single();

      return res['id'] as String;
    } catch (e) {
      rethrow;
    }
  }
}
