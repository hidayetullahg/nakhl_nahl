// NAKHL & NAHL — Universal Integration Architecture Unit & Integration Tests
// Complies with Master Directive Sections 2-10, 40

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:crypto/crypto.dart';
import 'package:nakhl_nahl/models/integration_models.dart';
import 'package:nakhl_nahl/services/integration/country_provider_registry.dart';
import 'package:nakhl_nahl/services/integration/universal_einvoice_adapter.dart';
import 'package:nakhl_nahl/services/integration/integration_webhook_handler.dart';

void main() {
  group('1. Country & Provider Registry Tests', () {
    final registry = IntegrationProviderRegistry();

    test('Registry returns default supported countries', () async {
      final countries = await registry.getSupportedCountries();
      expect(countries.isNotEmpty, isTrue);
      expect(countries.any((c) => c['code'] == 'TR'), isTrue);
      expect(countries.any((c) => c['code'] == 'SA'), isTrue);
      expect(countries.any((c) => c['code'] == 'AE'), isTrue);
      expect(countries.any((c) => c['code'] == 'EU'), isTrue);
    });

    test('Turkey GİB Sandbox and Production profiles are defined', () async {
      final trProfiles = await registry.getProfilesForCountry('TR');
      expect(trProfiles.isNotEmpty, isTrue);

      final gibSandbox = trProfiles.firstWhere((p) => p.providerType == 'GIB' && p.environment == 'sandbox');
      expect(gibSandbox.countryCode, 'TR');
      expect(gibSandbox.invoiceFormat, 'UBL-TR');
      expect(gibSandbox.certificateRequired, isTrue);

      final gibProd = trProfiles.firstWhere((p) => p.providerType == 'GIB' && p.environment == 'production');
      expect(gibProd.environment, 'production');
    });

    test('Saudi Arabia ZATCA Phase 2 profiles are defined', () async {
      final saProfiles = await registry.getProfilesForCountry('SA');
      expect(saProfiles.isNotEmpty, isTrue);

      final zatcaSandbox = saProfiles.firstWhere((p) => p.providerType == 'ZATCA' && p.environment == 'sandbox');
      expect(zatcaSandbox.currency, 'SAR');
      expect(zatcaSandbox.invoiceFormat, 'UBL-2.1');
      expect(zatcaSandbox.qrRequired, isTrue);
      expect(zatcaSandbox.authenticationType, 'CSID');
    });
  });

  group('2. Universal E-Invoice Adapter Tests', () {
    test('Turkey GIB Adapter validates VKN (10) and TCKN (11)', () async {
      final adapter = TurkeyGibUniversalAdapter();
      expect(await adapter.validateTaxIdentity('1234567890'), isTrue); // 10 digit VKN
      expect(await adapter.validateTaxIdentity('12345678901'), isTrue); // 11 digit TCKN
      expect(await adapter.validateTaxIdentity('12345'), isFalse); // Invalid
      expect(await adapter.validateTaxIdentity(''), isFalse);
    });

    test('Saudi ZATCA Adapter validates 15-digit VAT format', () async {
      final adapter = SaudiZatcaUniversalAdapter();
      expect(await adapter.validateTaxIdentity('300000000000003'), isTrue);
      expect(await adapter.validateTaxIdentity('100000000000003'), isFalse); // Does not start with 3
      expect(await adapter.validateTaxIdentity('300000000000001'), isFalse); // Does not end with 3
      expect(await adapter.validateTaxIdentity('30000000003'), isFalse); // Length not 15
    });

    test('Turkey GIB Adapter creates UBL-TR XML', () async {
      final adapter = TurkeyGibUniversalAdapter();
      final invoiceData = {
        'uuid': 'TEST-INV-UUID-001',
        'invoice_number': 'GIB2026000000001',
        'customer_tax_number': '1234567890',
        'payable_amount': 1500.0,
        'lines': [
          {'name': 'Medjool Hurma', 'quantity': 10, 'price': 150.0}
        ]
      };

      final result = await adapter.createInvoice(invoiceData);
      expect(result.success, isTrue);
      expect(result.documentUuid, 'TEST-INV-UUID-001');
      expect(result.signedXml, isNotNull);
      expect(result.signedXml!.contains('Invoice'), isTrue);
    });

    test('Saudi ZATCA Adapter creates UBL 2.1 XML and QR code', () async {
      final adapter = SaudiZatcaUniversalAdapter();
      final invoiceData = {
        'uuid': 'ZATCA-INV-UUID-001',
        'invoice_number': 'SA2026000001',
        'vat_number': '300000000000003',
        'payable_amount': 2300.0,
        'seller_name': 'NAKHL & NAHL CO.',
      };

      final result = await adapter.createInvoice(invoiceData);
      expect(result.success, isTrue);
      expect(result.documentUuid, 'ZATCA-INV-UUID-001');
      expect(result.qrCode, isNotNull);
      expect(result.qrCode!.isNotEmpty, isTrue);
      expect(result.signedXml!.contains('reporting:1.0'), isTrue);
    });

    test('Validation failure on missing mandatory fields', () async {
      final adapter = TurkeyGibUniversalAdapter();
      final invalidInvoice = {
        'uuid': 'TEST-INVALID',
        'payable_amount': 0.0, // Zero amount
        'lines': [] // No lines
      };

      final result = await adapter.createInvoice(invalidInvoice);
      expect(result.success, isFalse);
      expect(result.status, 'VALIDATION_FAILED');
      expect(result.errors.isNotEmpty, isTrue);
    });
  });

  group('3. ERP Export Models & Hashing Tests', () {
    test('CustomerExportModel serialization and hash calculation', () {
      const customer = CustomerExportModel(
        localId: 'cust-101',
        unvan: 'Al-Madinah Trading Ltd',
        taxNumber: '300011122200003',
        currency: 'SAR',
        currentBalance: 45000.0,
      );

      final json = customer.toJson();
      expect(json['local_id'], 'cust-101');
      expect(json['company_name'], 'Al-Madinah Trading Ltd');

      final hash = customer.computeHash();
      expect(hash.isNotEmpty, isTrue);
      expect(hash, equals(customer.computeHash())); // Deterministic
    });

    test('ProductExportModel serialization and hash calculation', () {
      const product = ProductExportModel(
        localId: 'prod-501',
        sku: 'HUR-MED-01',
        name: 'Medjool Jumbo Hurma',
        salePrice: 180.0,
        vatRate: 20.0,
      );

      final json = product.toJson();
      expect(json['sku'], 'HUR-MED-01');
      expect(json['vat_rate'], 20.0);

      final hash = product.computeHash();
      expect(hash.isNotEmpty, isTrue);
    });
  });

  group('4. Universal Webhook Security Tests', () {
    test('HMAC-SHA256 signature verification passes with valid key', () {
      const secret = 'my_super_secret_webhook_key_2026';
      const payload = '{"event": "invoice.approved", "id": "INV-001"}';

      final hmac = Hmac(sha256, utf8.encode(secret));
      final validSignature = hmac.convert(utf8.encode(payload)).toString();

      final verified = IntegrationWebhookHandler.verifySignature(
        rawPayload: payload,
        secret: secret,
        headerSignature: validSignature,
      );
      expect(verified, isTrue);

      // With sha256= prefix
      final verifiedWithPrefix = IntegrationWebhookHandler.verifySignature(
        rawPayload: payload,
        secret: secret,
        headerSignature: 'sha256=$validSignature',
      );
      expect(verifiedWithPrefix, isTrue);
    });

    test('HMAC-SHA256 signature verification fails with tampered payload or secret', () {
      const secret = 'my_super_secret_webhook_key_2026';
      const payload = '{"event": "invoice.approved", "id": "INV-001"}';

      final verifiedWrongSecret = IntegrationWebhookHandler.verifySignature(
        rawPayload: payload,
        secret: 'wrong_secret',
        headerSignature: 'some_hash',
      );
      expect(verifiedWrongSecret, isFalse);

      final verifiedTampered = IntegrationWebhookHandler.verifySignature(
        rawPayload: '{"event": "invoice.approved", "id": "INV-TAMPERED"}',
        secret: secret,
        headerSignature: 'some_hash',
      );
      expect(verifiedTampered, isFalse);
    });
  });

  group('5. Normalized Error Hierarchy Tests', () {
    test('All IntegrationErrorCode items have user-friendly titles and resolutions', () {
      for (final code in IntegrationErrorCode.values) {
        expect(code.userFriendlyTitle.isNotEmpty, isTrue);
        expect(code.suggestedResolution.isNotEmpty, isTrue);
      }
    });

    test('IntegrationException formats correctly', () {
      const ex = IntegrationException(
        code: IntegrationErrorCode.certificateError,
        message: 'Mali mühür süresi dolmuş.',
        technicalDetails: 'CERT_HAS_EXPIRED_2026',
        correlationId: 'CORR-1234',
      );

      expect(ex.code, IntegrationErrorCode.certificateError);
      expect(ex.toString().contains('certificateError'), isTrue);
      expect(ex.toString().contains('CERT_HAS_EXPIRED_2026'), isTrue);
    });
  });
}
