import 'package:flutter_test/flutter_test.dart';
import 'package:nakhl_nahl/repositories/audit_compliance_repository.dart';

void main() {
  group('FAZ 29: Audit + Compliance Hardening Bounded Context Tests', () {
    test('AuditAction enum maps all 10 critical commercial actions correctly',
        () {
      final actions = [
        AuditAction.create,
        AuditAction.update,
        AuditAction.post,
        AuditAction.approve,
        AuditAction.reject,
        AuditAction.reverse,
        AuditAction.export,
        AuditAction.import,
        AuditAction.login,
        AuditAction.logout,
      ];

      for (final a in actions) {
        final dbVal = a.dbValue;
        final fromDb = AuditAction.fromDbValue(dbVal);
        expect(fromDb, a, reason: 'Action $a did not match converted $fromDb');
      }

      expect(actions.length, 10);
    });

    test(
        'AuditLogModel serialization & deserialization with cryptographic fields',
        () {
      final json = {
        'id': 1052,
        'tenant_id': 'tenant-test-01',
        'company_id': 'company-test-01',
        'user_id': 'user-super-admin',
        'action': 'POST',
        'entity_type': 'JOURNAL_ENTRY',
        'entity_id': 'jrn-uuid-001',
        'old_data': {'status': 'DRAFT'},
        'new_data': {'status': 'POSTED', 'total_debit': 50000.0},
        'actor_role': 'SUPER_ADMIN',
        'ip_address': '192.168.1.100',
        'user_agent': 'NAKHL_ERP_FLUTTER_CLIENT_V2',
        'record_hash':
            'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        'prev_hash':
            'ca978112ca1bbdcafac231b39a23dc4da786eff8147c4e72b9807785afee48bb',
        'metadata': {'compliance_note': 'Maliye denetimi için mühürlendi'},
        'created_at': '2026-09-06T12:30:00.000Z',
      };

      final log = AuditLogModel.fromJson(json);
      expect(log.id, 1052);
      expect(log.action, AuditAction.post);
      expect(log.entityType, 'JOURNAL_ENTRY');
      expect(log.actorRole, 'SUPER_ADMIN');
      expect(log.recordHash,
          'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855');
      expect(log.prevHash,
          'ca978112ca1bbdcafac231b39a23dc4da786eff8147c4e72b9807785afee48bb');
      expect(
          log.metadata['compliance_note'], 'Maliye denetimi için mühürlendi');

      final serialized = log.toJson();
      expect(serialized['action'], 'POST');
      expect(serialized['actor_role'], 'SUPER_ADMIN');
      expect(serialized['record_hash'], log.recordHash);
    });

    test('AuditIntegrityResultModel parses cryptographic verification response',
        () {
      final validJson = {
        'tenant_id': 'tenant-test-01',
        'total_records_checked': 1500,
        'is_valid': true,
        'tampered_record_id': null,
        'tamper_reason': null,
        'verified_at': '2026-09-06T12:32:00.000Z',
      };

      final validResult = AuditIntegrityResultModel.fromJson(validJson);
      expect(validResult.isValid, true);
      expect(validResult.totalRecordsChecked, 1500);
      expect(validResult.tamperedRecordId, isNull);

      final tamperedJson = {
        'tenant_id': 'tenant-test-01',
        'total_records_checked': 842,
        'is_valid': false,
        'tampered_record_id': 843,
        'tamper_reason':
            'Zincir kırılması: prev_hash beklenen hash ile uyuşmuyor!',
        'verified_at': '2026-09-06T12:33:00.000Z',
      };

      final tamperedResult = AuditIntegrityResultModel.fromJson(tamperedJson);
      expect(tamperedResult.isValid, false);
      expect(tamperedResult.tamperedRecordId, 843);
      expect(tamperedResult.tamperReason, contains('Zincir kırılması'));
    });

    test('AuditRetentionPolicyModel enforces 10-year WORM compliance standard',
        () {
      final json = {
        'tenant_id': 'tenant-test-01',
        'retention_period_years': 10,
        'storage_class': 'WORM_COMPLIANT_COLD_STORAGE',
        'automated_purge_enabled': false,
        'legal_frameworks': [
          'ZATCA Electronic Invoicing & Tax Audit Regulations (10 Years)',
          'KSA Corporate Tax & Commercial Law',
          'GCC Common Customs Law (International Trade Records)',
          'EU Traceability & Food Safety General Food Law Reg (EC) 178/2002',
          'IFRS / GAAP Financial Audit Standards',
          'ISO 27001 (Information Security) & ISO 9001 (Quality Assurance)',
        ],
        'destruction_policy':
            'Herhangi bir otomatik silme işlemi yasaktır. 10 yıllık yasal süre sonunda dahi sadece çoklu imza protokolü ile arşivleme yapılabilir.',
      };

      final policy = AuditRetentionPolicyModel.fromJson(json);
      expect(policy.retentionPeriodYears, 10);
      expect(policy.storageClass, 'WORM_COMPLIANT_COLD_STORAGE');
      expect(policy.automatedPurgeEnabled, false);
      expect(policy.legalFrameworks.length, 6);
      expect(
          policy.destructionPolicy, contains('otomatik silme işlemi yasaktır'));
    });
  });
}
