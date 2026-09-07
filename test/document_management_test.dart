import 'package:flutter_test/flutter_test.dart';
import 'package:nakhl_nahl/repositories/document_repository.dart';

void main() {
  group('FAZ 21: Document Management Bounded Context Unit Tests', () {
    test('DocumentModel parsing and 10 document types support', () {
      final docTypes = [
        'INVOICE',
        'PACKING_LIST',
        'CERTIFICATE',
        'CUSTOMS_DOCUMENT',
        'TRANSPORT_DOCUMENT',
        'HALAL_CERTIFICATE',
        'QUALITY_CERTIFICATE',
        'PURCHASE_DOCUMENT',
        'SALES_DOCUMENT',
        'LEGAL_DOCUMENT',
      ];

      for (final type in docTypes) {
        final docMap = {
          'id': 'doc-uuid-$type',
          'document_type': type,
          'document_number': 'DOC-2026-$type',
          'title': 'Test $type Title',
          'entity_type': 'EXPORT_FILE',
          'entity_id': 'entity-uuid-001',
          'issue_date': '2026-09-01',
          'expiry_date': '2027-09-01',
          'status': 'APPROVED',
          'storage_reference': 'supabase://storage/docs/$type.pdf',
          'file_name': '$type.pdf',
          'file_size_bytes': 124000,
          'mime_type': 'application/pdf',
          'current_version': 1,
          'is_latest': true,
          'created_at': '2026-09-06T10:00:00.000Z',
        };

        final doc = DocumentModel.fromJson(docMap);
        expect(doc.documentType, type);
        expect(doc.documentNumber, 'DOC-2026-$type');
        expect(doc.status, 'APPROVED');
        expect(doc.isExpired, isFalse);
      }
    });

    test('DocumentVersionModel parsing and version replacement', () {
      final v1Map = {
        'id': 'ver-001',
        'document_id': 'doc-inv-001',
        'version_number': 1,
        'storage_reference': 'supabase://storage/docs/inv-v1.pdf',
        'file_name': 'inv_v1.pdf',
        'file_size_bytes': 100000,
        'mime_type': 'application/pdf',
        'change_summary': 'İlk versiyon',
        'created_at': '2026-09-01T10:00:00.000Z',
      };

      final v1 = DocumentVersionModel.fromJson(v1Map);
      expect(v1.versionNumber, 1);
      expect(v1.changeSummary, 'İlk versiyon');

      final v2Map = {
        'id': 'ver-002',
        'document_id': 'doc-inv-001',
        'version_number': 2,
        'storage_reference': 'supabase://storage/docs/inv-v2.pdf',
        'file_name': 'inv_v2.pdf',
        'file_size_bytes': 105000,
        'mime_type': 'application/pdf',
        'change_summary': 'Navlun bedeli güncellendi',
        'created_at': '2026-09-06T10:00:00.000Z',
      };

      final v2 = DocumentVersionModel.fromJson(v2Map);
      expect(v2.versionNumber, 2);
      expect(v2.changeSummary, 'Navlun bedeli güncellendi');
      expect(v2.fileSizeBytes, 105000);
    });

    test('DocumentAccessLogModel parsing across 6 audit actions', () {
      final actions = [
        'UPLOAD',
        'VIEW',
        'DOWNLOAD',
        'REPLACE',
        'APPROVE',
        'REJECT'
      ];

      for (int i = 0; i < actions.length; i++) {
        final action = actions[i];
        final logMap = {
          'id': i + 1,
          'document_id': 'doc-uuid-001',
          'user_id': 'user-auditor-01',
          'action': action,
          'version_number': 1,
          'notes': 'Denetim: $action işlemi gerçekleştirildi',
          'created_at': '2026-09-06T11:00:00.000Z',
        };

        final log = DocumentAccessLogModel.fromJson(logMap);
        expect(log.action, action);
        expect(log.versionNumber, 1);
      }
    });

    test('DocumentExpiryAlertModel parsing and alert levels', () {
      final expiredAlertMap = {
        'document_id': 'doc-exp-001',
        'document_type': 'QUALITY_CERTIFICATE',
        'document_number': 'ISO-OLD-01',
        'title': 'Eski ISO Sertifikası',
        'entity_type': 'COMPANY',
        'entity_id': 'comp-001',
        'expiry_date': '2026-08-01',
        'days_remaining': -36,
        'alert_level': 'EXPIRED',
        'status': 'EXPIRED',
      };

      final expiredAlert = DocumentExpiryAlertModel.fromJson(expiredAlertMap);
      expect(expiredAlert.alertLevel, 'EXPIRED');
      expect(expiredAlert.daysRemaining, -36);

      final criticalAlertMap = {
        'document_id': 'doc-halal-001',
        'document_type': 'HALAL_CERTIFICATE',
        'document_number': 'SMIIC-2026-99',
        'title': 'SMIIC Helal Sertifikası',
        'entity_type': 'LOT',
        'entity_id': 'lot-001',
        'expiry_date': '2026-09-26',
        'days_remaining': 20,
        'alert_level': 'CRITICAL_30_DAYS',
        'status': 'APPROVED',
      };

      final criticalAlert = DocumentExpiryAlertModel.fromJson(criticalAlertMap);
      expect(criticalAlert.alertLevel, 'CRITICAL_30_DAYS');
      expect(criticalAlert.daysRemaining, 20);
    });
  });
}
