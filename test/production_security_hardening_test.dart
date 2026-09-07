import 'package:flutter_test/flutter_test.dart';
import 'package:nakhl_nahl/repositories/production_security_repository.dart';
import 'package:nakhl_nahl/services/auth_service.dart';

void main() {
  group('FAZ 31: Production Security Hardening Bounded Context Tests', () {
    test(
        'SecurityAuditReportModel parses clean production-ready audit correctly',
        () {
      final json = {
        'audit_timestamp': '2026-09-06T13:40:00.000Z',
        'schema': 'public',
        'metrics': {
          'unprotected_tables_count': 0,
          'unforced_tables_count': 0,
          'insecure_functions_count': 0,
        },
        'vulnerabilities': {
          'CRITICAL': 0,
          'HIGH': 0,
          'MEDIUM': 0,
          'LOW': 0,
        },
        'compliance_status': 'HARDENED_PRODUCTION_READY',
        'secrets_audit': {
          'service_role_leaked_to_client': false,
          'database_credentials_exposed': false,
          'hardcoded_passwords_detected': false,
        }
      };

      final report = SecurityAuditReportModel.fromJson(json);
      expect(report.criticalCount, 0);
      expect(report.highCount, 0);
      expect(report.mediumCount, 0);
      expect(report.lowCount, 0);
      expect(report.unprotectedTablesCount, 0);
      expect(report.serviceRoleLeakedToClient, false);
      expect(report.databaseCredentialsExposed, false);
      expect(report.complianceStatus, 'HARDENED_PRODUCTION_READY');
      expect(report.isProductionReady, true);
    });

    test(
        'SecurityAuditReportModel correctly detects compromised security state',
        () {
      final json = {
        'audit_timestamp': '2026-09-06T13:40:00.000Z',
        'schema': 'public',
        'metrics': {
          'unprotected_tables_count': 2,
          'unforced_tables_count': 1,
          'insecure_functions_count': 1,
        },
        'vulnerabilities': {
          'CRITICAL': 2,
          'HIGH': 1,
          'MEDIUM': 1,
          'LOW': 0,
        },
        'compliance_status': 'ACTION_REQUIRED',
        'secrets_audit': {
          'service_role_leaked_to_client': true,
          'database_credentials_exposed': false,
          'hardcoded_passwords_detected': false,
        }
      };

      final report = SecurityAuditReportModel.fromJson(json);
      expect(report.criticalCount, 2);
      expect(report.highCount, 1);
      expect(report.serviceRoleLeakedToClient, true);
      expect(report.isProductionReady, false);
    });

    test(
        'ProductionSecurityRepository sanitizes input from null bytes & control chars',
        () {
      final repo = ProductionSecurityRepository.instance;
      final dirtyInput = 'NormalText\x00InjectedString';
      final clean = repo.sanitizeInput(dirtyInput);
      expect(clean, 'NormalTextInjectedString');
    });

    test('AuthService session validity and demo PIN behavior', () {
      final auth = AuthService.instance;

      // Demo oturum aç
      auth.demoOturumAyarla(KullaniciRolu.admin, email: 'admin@nakhl.sa');
      expect(auth.aktifProfil, isNotNull);
      expect(auth.isSessionValid, true);

      // PIN doğrulama kontrolü
      expect(auth.pinDogrula('1453'), true);
      expect(auth.pinDogrula('9999'), false);

      // Çıkış yap
      auth.cikisYap();
      expect(auth.aktifProfil, isNull);
    });
  });
}
