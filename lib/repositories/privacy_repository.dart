import '../core/tenant/tenant_context.dart';
import '../services/supabase_service.dart';

/// KVKK/GDPR/PDPL kayıtlarını tenant sınırları içinde yönetir.
class PrivacyRepository {
  PrivacyRepository._();
  static final PrivacyRepository instance = PrivacyRepository._();

  String _tenantId() {
    final tenantId = TenantContext.instance.activeTenantId;
    if (tenantId == null) {
      throw Exception('Aktif bir şirket/tenant seçilmedi.');
    }
    return tenantId;
  }

  Future<List<Map<String, dynamic>>> getNoticeTemplates({
    String? countryCode,
  }) async {
    var query = SupabaseService.client
        .from('privacy_notice_templates')
        .select()
        .eq('tenant_id', _tenantId())
        .eq('is_active', true);
    if (countryCode != null && countryCode.isNotEmpty) {
      query = query.eq('country_code', countryCode);
    }
    final response = await query.order('updated_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> saveProcessingRecord({
    required String subjectType,
    required String subjectId,
    required String legalBasis,
    required DateTime noticeInformedAt,
    required DateTime retentionEndsAt,
    bool consentGiven = false,
    DateTime? consentGivenAt,
    String? noticeTemplateId,
  }) async {
    if (legalBasis == 'EXPLICIT_CONSENT' &&
        (!consentGiven || consentGivenAt == null)) {
      throw ArgumentError('Açık rıza için onay ve onay tarihi zorunludur.');
    }
    if (legalBasis == 'CONTRACT_NECESSITY' && consentGiven) {
      throw ArgumentError('Sözleşme dayanağında açık rıza işaretlenemez.');
    }

    await SupabaseService.client.from('person_privacy_processing').upsert({
      'tenant_id': _tenantId(),
      'subject_type': subjectType,
      'subject_id': subjectId,
      'legal_basis': legalBasis,
      'notice_template_id': noticeTemplateId,
      'notice_informed_at': noticeInformedAt.toIso8601String(),
      'consent_given': consentGiven,
      'consent_given_at': consentGivenAt?.toIso8601String(),
      'retention_ends_at': retentionEndsAt.toIso8601String(),
      'recorded_by': SupabaseService.currentAuthUserId,
    }, onConflict: 'tenant_id,subject_type,subject_id,legal_basis');
  }

  Future<void> createDataSubjectRequest({
    required String subjectType,
    required String subjectId,
    required String requestType,
    String? notes,
  }) async {
    await SupabaseService.client.from('data_subject_requests').insert({
      'tenant_id': _tenantId(),
      'subject_type': subjectType,
      'subject_id': subjectId,
      'request_type': requestType,
      'requested_by': SupabaseService.currentAuthUserId,
      'notes': notes,
    });
  }
}
