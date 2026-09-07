import 'package:flutter_test/flutter_test.dart';
import 'package:nakhl_nahl/repositories/halal_repository.dart';

void main() {
  group('FAZ 18: Halal Compliance Bounded Context Unit Tests', () {
    test('HalalCertificate parsing and expiry enforcement logic', () {
      final validCertMap = {
        'id': 'cert-uuid-001',
        'certificate_number': 'CERT-GIMDES-2026-001',
        'halal_certification_bodies': {'name': 'GİMDES'},
        'issue_date': '2026-01-01',
        'expiry_date': '2027-01-01',
        'status': 'VALID',
        'scope_description': 'Hurma işleme ve paketleme',
      };

      final validCert = HalalCertificate.fromJson(validCertMap);
      expect(validCert.certificateNumber, 'CERT-GIMDES-2026-001');
      expect(validCert.bodyName, 'GİMDES');
      expect(validCert.isValid, isTrue);

      // Süresi geçmiş sertifika
      final expiredCertMap = {
        'id': 'cert-uuid-002',
        'certificate_number': 'CERT-EXPIRED-002',
        'halal_certification_bodies': {'name': 'JAKIM'},
        'issue_date': '2024-01-01',
        'expiry_date': '2025-01-01',
        'status': 'VALID',
      };

      final expiredCert = HalalCertificate.fromJson(expiredCertMap);
      // Süresi geçmiş olduğu için VALID olsa dahi isValid false dönmeli
      expect(expiredCert.isValid, isFalse);

      // Durumu REVOKED olan sertifika
      final revokedCertMap = {
        'id': 'cert-uuid-003',
        'certificate_number': 'CERT-REVOKED-003',
        'halal_certification_bodies': {'name': 'SASO'},
        'issue_date': '2026-01-01',
        'expiry_date': '2027-01-01',
        'status': 'REVOKED',
      };

      final revokedCert = HalalCertificate.fromJson(revokedCertMap);
      expect(revokedCert.isValid, isFalse);
    });

    test('SupplierHalalModel parsing and compliance status', () {
      final supplierMap = {
        'id': 'supp-halal-001',
        'supplier_party_id': 'party-supp-001',
        'certificate_id': 'cert-uuid-001',
        'compliance_status': 'COMPLIANT',
        'audit_date': '2026-05-01',
        'valid_until': '2027-05-01',
        'notes': 'Yıllık denetim uygun',
      };

      final supplierHalal = SupplierHalalModel.fromJson(supplierMap);
      expect(supplierHalal.supplierPartyId, 'party-supp-001');
      expect(supplierHalal.complianceStatus, 'COMPLIANT');
      expect(supplierHalal.isValid, isTrue);

      final expiredSupplierMap = {
        'id': 'supp-halal-002',
        'supplier_party_id': 'party-supp-002',
        'compliance_status': 'EXPIRED',
        'valid_until': '2025-01-01',
      };
      final expiredSupplier = SupplierHalalModel.fromJson(expiredSupplierMap);
      expect(expiredSupplier.isValid, isFalse);
    });

    test('FacilityHalalModel and ShipmentHalalDocModel parsing', () {
      final facilityMap = {
        'id': 'fac-halal-001',
        'business_unit_id': 'bu-fac-01',
        'certificate_id': 'cert-uuid-001',
        'process_step': 'WASHING',
        'is_halal_certified': true,
        'verified_at': '2026-08-01T09:00:00.000Z',
        'inspector_name': 'Ahmet Yılmaz',
      };

      final facility = FacilityHalalModel.fromJson(facilityMap);
      expect(facility.processStep, 'WASHING');
      expect(facility.isHalalCertified, isTrue);
      expect(facility.inspectorName, 'Ahmet Yılmaz');

      final shipmentDocMap = {
        'id': 'ship-doc-001',
        'sales_order_id': 'so-exp-001',
        'certificate_id': 'cert-uuid-001',
        'document_type': 'BATCH_HALAL_CERTIFICATE',
        'document_number': 'BATCH-HL-2026-981',
        'issued_at': '2026-09-01T12:00:00.000Z',
        'document_url': 'https://docs.nakhl.com/batch.pdf',
      };

      final doc = ShipmentHalalDocModel.fromJson(shipmentDocMap);
      expect(doc.documentType, 'BATCH_HALAL_CERTIFICATE');
      expect(doc.documentNumber, 'BATCH-HL-2026-981');
      expect(doc.salesOrderId, 'so-exp-001');
    });

    test('HalalAiAdvisoryModel & Human Final Decision Enforcement', () {
      final pendingAdvisoryMap = {
        'id': 'advisory-001',
        'target_type': 'LOT',
        'target_id': 'lot-meb-01',
        'risk_score': 15.5,
        'ai_recommendation_text':
            'Tedarikçi ve tesis sertifikası güncel. Uygunluk onaylanabilir.',
        'ai_flags': [
          {'code': 'SMIIC_VERIFIED', 'level': 'INFO'}
        ],
        'human_decision': 'PENDING',
        'created_at': '2026-09-06T10:00:00.000Z',
      };

      final advisory = HalalAiAdvisoryModel.fromJson(pendingAdvisoryMap);
      expect(advisory.riskScore, 15.5);
      expect(advisory.isDecided, isFalse);
      expect(advisory.isApproved, isFalse);

      final approvedAdvisoryMap = {
        'id': 'advisory-002',
        'target_type': 'LOT',
        'target_id': 'lot-meb-01',
        'risk_score': 5.0,
        'ai_recommendation_text': 'Tüm koşullar sağlandı.',
        'human_decision': 'APPROVED',
        'human_reviewer_user_id': 'user-auditor-99',
        'human_decision_notes':
            'GİMDES standardı doğrulanarak ihraç partisi onaylandı.',
        'decided_at': '2026-09-06T11:00:00.000Z',
        'created_at': '2026-09-06T10:00:00.000Z',
      };

      final approved = HalalAiAdvisoryModel.fromJson(approvedAdvisoryMap);
      expect(approved.isDecided, isTrue);
      expect(approved.isApproved, isTrue);
      expect(approved.humanReviewerUserId, 'user-auditor-99');

      // Human review olmadan onay verme denemesi hata fırlatmalıdır
      expect(
        () => HalalRepository.instance.submitHumanDecision(
          advisoryId: 'advisory-001',
          reviewerUserId: '', // BOŞ İNSAN DENETÇİ ID
          decision: 'APPROVED',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
