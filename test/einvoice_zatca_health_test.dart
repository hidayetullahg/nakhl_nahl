import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:nakhl_nahl/services/einvoice_adapter.dart';
import 'package:nakhl_nahl/services/zatca_adapter.dart';
import 'package:nakhl_nahl/services/health_check_service.dart';

void main() {
  group('FAZ 29 & 30: Türkiye E-Fatura Adapter Tests', () {
    test('EInvoiceFactory resolves correct provider adapters', () {
      final logo = EInvoiceFactory.getAdapter(providerType: EInvoiceProviderType.logo);
      final qnb = EInvoiceFactory.getAdapter(providerType: EInvoiceProviderType.qnb);
      final uyum = EInvoiceFactory.getAdapter(providerType: EInvoiceProviderType.uyumsoft);
      final sovos = EInvoiceFactory.getAdapter(providerType: EInvoiceProviderType.sovos);
      final sandbox = EInvoiceFactory.getAdapter(providerType: EInvoiceProviderType.mockSandbox);

      expect(logo.providerType, equals(EInvoiceProviderType.logo));
      expect(qnb.providerType, equals(EInvoiceProviderType.qnb));
      expect(uyum.providerType, equals(EInvoiceProviderType.uyumsoft));
      expect(sovos.providerType, equals(EInvoiceProviderType.sovos));
      expect(sandbox.providerType, equals(EInvoiceProviderType.mockSandbox));
    });

    test('MockSandboxEInvoiceAdapter validates VKN/TCKN and sends invoice with UBL XML', () async {
      final adapter = MockSandboxEInvoiceAdapter();
      
      final validVkn = await adapter.validateTaxpayer(vknTckn: '1234567890');
      final invalidVkn = await adapter.validateTaxpayer(vknTckn: '123');
      expect(validVkn, isTrue);
      expect(invalidVkn, isFalse);

      final sendResult = await adapter.sendInvoice(
        tenantId: 'tenant-001',
        companyId: 'company-001',
        invoiceData: {
          'uuid': 'TEST-INV-UUID-999',
          'invoice_number': 'GIB2026000000001',
          'grand_total': 1200.50,
        },
        idempotencyKey: 'idemp-key-12345',
      );

      expect(sendResult.success, isTrue);
      expect(sendResult.status, equals(EInvoiceStatus.approved));
      expect(sendResult.signedXml, contains('<cbc:UBLVersionID>2.1</cbc:UBLVersionID>'));
      expect(sendResult.signedXml, contains('TEST-INV-UUID-999'));
    });
  });

  group('FAZ 31: Suudi Arabistan ZATCA Phase 2 Fatoora Tests', () {
    test('ZatcaPhase2Adapter generates compliant TLV Base64 QR Code', () {
      final timestamp = DateTime(2026, 9, 6, 12, 0, 0);
      final qrBase64 = ZatcaPhase2Adapter.generateZatcaTlvQrCode(
        sellerName: 'NAKHL & NAHL Date Trading Co',
        vatNumber: '300000000000003',
        timestamp: timestamp,
        invoiceTotal: 1150.00,
        vatTotal: 150.00,
      );

      expect(qrBase64, isNotEmpty);
      final decodedBytes = base64.decode(qrBase64);
      // Tag 1 should be 1
      expect(decodedBytes[0], equals(1));
    });

    test('ZatcaPhase2Adapter generates UBL 2.1 XML and simulates clearance', () async {
      const adapter = ZatcaPhase2Adapter(environment: ZatcaEnvironment.developerSandbox);
      
      final result = await adapter.submitInvoice(
        invoicePayload: {
          'uuid': 'ZATCA-TEST-UUID-001',
          'invoice_number': 'INV-SA-001',
          'seller_name': 'Al-Madina Dates',
          'seller_vat': '300000000000003',
          'grand_total': 230.00,
          'tax_amount': 30.00,
        },
        invoiceType: ZatcaInvoiceType.standardTaxInvoice,
      );

      expect(result.success, isTrue);
      expect(result.status, equals('CLEARED'));
      expect(result.signedXml, contains('<cbc:DocumentCurrencyCode>SAR</cbc:DocumentCurrencyCode>'));
      expect(result.qrCodePayload, isNotNull);
    });
  });

  group('FAZ 33: Production Health Check & Observability Tests', () {
    test('HealthCheckService runs all component probes', () async {
      final report = await HealthCheckService.runHealthCheck();
      
      expect(report.components.length, greaterThanOrEqualTo(4));
      expect(report.components.any((c) => c.name == 'database_connectivity'), isTrue);
      expect(report.components.any((c) => c.name == 'storage_service'), isTrue);
      expect(report.components.any((c) => c.name == 'backup_system'), isTrue);
    });
  });
}
