// NAKHL & NAHL — Universal Integration Models & Domain Contracts
// Complies with Master Directive Sections 2-8, 37, 38

import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Normalized error codes across all integration providers
enum IntegrationErrorCode {
  authenticationError,
  certificateError,
  validationError,
  networkError,
  rateLimit,
  timeout,
  duplicateDocument,
  remoteRejection,
  invalidTaxId,
  configurationError,
  unknownError;

  String get userFriendlyTitle {
    switch (this) {
      case IntegrationErrorCode.authenticationError:
        return 'Kimlik Doğrulama Hatası (API / Token Geçersiz)';
      case IntegrationErrorCode.certificateError:
        return 'Sertifika / Mali Mühür Hatası';
      case IntegrationErrorCode.validationError:
        return 'Belge Doğrulama / Şema Hatası';
      case IntegrationErrorCode.networkError:
        return 'Ağ Bağlantı Hatası (Sunucuya Ulaşılamıyor)';
      case IntegrationErrorCode.rateLimit:
        return 'Hız Limiti Aşıldı (Lütfen Bekleyin)';
      case IntegrationErrorCode.timeout:
        return 'İstek Zaman Aşımı';
      case IntegrationErrorCode.duplicateDocument:
        return 'Mükerrer Belge Hatası';
      case IntegrationErrorCode.remoteRejection:
        return 'Resmi Makam / Alıcı Tarafından Reddedildi';
      case IntegrationErrorCode.invalidTaxId:
        return 'Geçersiz Vergi Numarası (VKN / TCKN / VAT)';
      case IntegrationErrorCode.configurationError:
        return 'Eksik veya Hatalı Entegrasyon Yapılandırması';
      case IntegrationErrorCode.unknownError:
        return 'Beklenmeyen Sistem Hatası';
    }
  }

  String get suggestedResolution {
    switch (this) {
      case IntegrationErrorCode.authenticationError:
        return 'Ayarlar > Entegrasyonlar menüsünden API anahtarınızı veya kullanıcı bilgilerinizi güncelleyin.';
      case IntegrationErrorCode.certificateError:
        return 'Mali mühür veya CSID sertifikanızın süresini ve şifresini kontrol edin.';
      case IntegrationErrorCode.validationError:
        return 'Fatura kalemlerindeki KDV oranlarını, birim kodlarını ve zorunlu alanları kontrol edin.';
      case IntegrationErrorCode.networkError:
        return 'İnternet bağlantınızı ve entegratör sunucu durumunu kontrol edin. Sistem otomatik tekrar deneyecektir.';
      case IntegrationErrorCode.rateLimit:
        return 'Entegratör istek kotanız doldu. Birkaç dakika sonra tekrar deneyin.';
      case IntegrationErrorCode.timeout:
        return 'Karşı sunucu yanıt vermedi. Belge kuyrukta bekletilmektedir.';
      case IntegrationErrorCode.duplicateDocument:
        return 'Bu belge numarası ile daha önce gönderim yapılmış. Yeni bir fatura numarası üretin.';
      case IntegrationErrorCode.remoteRejection:
        return 'Red sebebini faturanın loglarından inceleyin ve gerekli düzeltmeleri yapıp yeni belge oluşturun.';
      case IntegrationErrorCode.invalidTaxId:
        return 'Cari kartındaki vergi numarasını resmi sistemden teyit ederek güncelleyin.';
      case IntegrationErrorCode.configurationError:
        return 'Entegrasyon profilindeki zorunlu alanların eksiksiz doldurulduğundan emin olun.';
      case IntegrationErrorCode.unknownError:
        return 'Sistem yöneticiniz ile iletişime geçin veya entegrasyon loglarını inceleyin.';
    }
  }
}

class IntegrationException implements Exception {
  final IntegrationErrorCode code;
  final String message;
  final String? technicalDetails;
  final int? httpStatusCode;
  final String? correlationId;

  const IntegrationException({
    required this.code,
    required this.message,
    this.technicalDetails,
    this.httpStatusCode,
    this.correlationId,
  });

  @override
  String toString() => 'IntegrationException [${code.name}]: $message (Details: $technicalDetails)';
}

/// Country Integration Profile (Supported Country Catalog)
class CountryIntegrationProfile {
  final String id;
  final String countryCode;
  final String countryName;
  final String currency;
  final String taxSystem;
  final String invoiceFormat;
  final bool electronicInvoiceRequired;
  final bool electronicDocumentRequired;
  final String providerType;
  final String providerName;
  final String environment;
  final String endpoint;
  final String authenticationType;
  final bool certificateRequired;
  final bool signingRequired;
  final bool qrRequired;
  final bool clearanceRequired;
  final bool reportingRequired;
  final bool active;
  final Map<String, dynamic> configurationSchema;

  const CountryIntegrationProfile({
    required this.id,
    required this.countryCode,
    required this.countryName,
    required this.currency,
    required this.taxSystem,
    required this.invoiceFormat,
    this.electronicInvoiceRequired = true,
    this.electronicDocumentRequired = false,
    required this.providerType,
    required this.providerName,
    this.environment = 'sandbox',
    required this.endpoint,
    required this.authenticationType,
    this.certificateRequired = false,
    this.signingRequired = false,
    this.qrRequired = false,
    this.clearanceRequired = false,
    this.reportingRequired = false,
    this.active = true,
    this.configurationSchema = const {},
  });

  factory CountryIntegrationProfile.fromJson(Map<String, dynamic> json) {
    return CountryIntegrationProfile(
      id: json['id']?.toString() ?? '',
      countryCode: json['country_code'] ?? 'TR',
      countryName: json['country_name'] ?? 'Türkiye',
      currency: json['currency'] ?? 'TRY',
      taxSystem: json['tax_system'] ?? 'KDV',
      invoiceFormat: json['invoice_format'] ?? 'UBL-TR',
      electronicInvoiceRequired: json['electronic_invoice_required'] ?? true,
      electronicDocumentRequired: json['electronic_document_required'] ?? false,
      providerType: json['provider_type'] ?? 'GIB',
      providerName: json['provider_name'] ?? '',
      environment: json['environment'] ?? 'sandbox',
      endpoint: json['endpoint'] ?? '',
      authenticationType: json['authentication_type'] ?? 'API_KEY',
      certificateRequired: json['certificate_required'] ?? false,
      signingRequired: json['signing_required'] ?? false,
      qrRequired: json['qr_required'] ?? false,
      clearanceRequired: json['clearance_required'] ?? false,
      reportingRequired: json['reporting_required'] ?? false,
      active: json['active'] ?? true,
      configurationSchema: json['configuration_schema'] is Map ? json['configuration_schema'] : {},
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'country_code': countryCode,
    'country_name': countryName,
    'currency': currency,
    'tax_system': taxSystem,
    'invoice_format': invoiceFormat,
    'electronic_invoice_required': electronicInvoiceRequired,
    'electronic_document_required': electronicDocumentRequired,
    'provider_type': providerType,
    'provider_name': providerName,
    'environment': environment,
    'endpoint': endpoint,
    'authentication_type': authenticationType,
    'certificate_required': certificateRequired,
    'signing_required': signingRequired,
    'qr_required': qrRequired,
    'clearance_required': clearanceRequired,
    'reporting_required': reportingRequired,
    'active': active,
    'configuration_schema': configurationSchema,
  };
}

/// Tenant Integration Configuration
class IntegrationConfig {
  final String id;
  final String tenantId;
  final String? providerId;
  final String providerCode;
  final String countryCode;
  final String environment; // sandbox, simulation, production
  final bool isActive;
  final String apiEndpoint;
  final String? credentialsEncrypted;
  final Map<String, dynamic> settings;
  final String? taxIdentityNumber;
  final String? branchIdentifier;
  final String? certificateRef;
  final DateTime? lastConnectionTestAt;
  final String lastConnectionStatus; // SUCCESS, FAILED, UNTESTED, WARNING
  final String? lastErrorMessage;
  final bool productionCertified;

  const IntegrationConfig({
    required this.id,
    required this.tenantId,
    this.providerId,
    required this.providerCode,
    required this.countryCode,
    this.environment = 'sandbox',
    this.isActive = false,
    required this.apiEndpoint,
    this.credentialsEncrypted,
    this.settings = const {},
    this.taxIdentityNumber,
    this.branchIdentifier,
    this.certificateRef,
    this.lastConnectionTestAt,
    this.lastConnectionStatus = 'UNTESTED',
    this.lastErrorMessage,
    this.productionCertified = false,
  });

  bool get isProduction => environment == 'production';
  bool get isSandbox => environment == 'sandbox' || environment == 'simulation';

  factory IntegrationConfig.fromJson(Map<String, dynamic> json) {
    return IntegrationConfig(
      id: json['id']?.toString() ?? '',
      tenantId: json['tenant_id']?.toString() ?? '',
      providerId: json['provider_id']?.toString(),
      providerCode: json['provider_code'] ?? 'GIB',
      countryCode: json['country_code'] ?? 'TR',
      environment: json['environment'] ?? 'sandbox',
      isActive: json['is_active'] ?? false,
      apiEndpoint: json['api_endpoint'] ?? '',
      credentialsEncrypted: json['credentials_encrypted'],
      settings: json['settings'] is Map ? json['settings'] : {},
      taxIdentityNumber: json['tax_identity_number'],
      branchIdentifier: json['branch_identifier'],
      certificateRef: json['certificate_ref'],
      lastConnectionTestAt: json['last_connection_test_at'] != null
          ? DateTime.tryParse(json['last_connection_test_at'].toString())
          : null,
      lastConnectionStatus: json['last_connection_status'] ?? 'UNTESTED',
      lastErrorMessage: json['last_error_message'],
      productionCertified: json['production_certified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tenant_id': tenantId,
    'provider_id': providerId,
    'provider_code': providerCode,
    'country_code': countryCode,
    'environment': environment,
    'is_active': isActive,
    'api_endpoint': apiEndpoint,
    'credentials_encrypted': credentialsEncrypted,
    'settings': settings,
    'tax_identity_number': taxIdentityNumber,
    'branch_identifier': branchIdentifier,
    'certificate_ref': certificateRef,
    'last_connection_test_at': lastConnectionTestAt?.toIso8601String(),
    'last_connection_status': lastConnectionStatus,
    'last_error_message': lastErrorMessage,
    'production_certified': productionCertified,
  };
}

/// Universal Entity Mapping between NAKHL and External ERP
class IntegrationEntityMapping {
  final String id;
  final String tenantId;
  final String provider;
  final String localEntity; // customer, supplier, product, inventory, invoice, etc.
  final String localId;
  final String externalId;
  final String? externalStatus;
  final DateTime lastSyncedAt;
  final String syncDirection;
  final String? syncHash;
  final String? errorMessage;

  const IntegrationEntityMapping({
    required this.id,
    required this.tenantId,
    required this.provider,
    required this.localEntity,
    required this.localId,
    required this.externalId,
    this.externalStatus,
    required this.lastSyncedAt,
    this.syncDirection = 'bidirectional',
    this.syncHash,
    this.errorMessage,
  });

  factory IntegrationEntityMapping.fromJson(Map<String, dynamic> json) {
    return IntegrationEntityMapping(
      id: json['id']?.toString() ?? '',
      tenantId: json['tenant_id']?.toString() ?? '',
      provider: json['provider'] ?? '',
      localEntity: json['local_entity'] ?? '',
      localId: json['local_id']?.toString() ?? '',
      externalId: json['external_id']?.toString() ?? '',
      externalStatus: json['external_status'],
      lastSyncedAt: json['last_synced_at'] != null
          ? DateTime.parse(json['last_synced_at'].toString())
          : DateTime.now(),
      syncDirection: json['sync_direction'] ?? 'bidirectional',
      syncHash: json['sync_hash'],
      errorMessage: json['error_message'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tenant_id': tenantId,
    'provider': provider,
    'local_entity': localEntity,
    'local_id': localId,
    'external_id': externalId,
    'external_status': externalStatus,
    'last_synced_at': lastSyncedAt.toIso8601String(),
    'sync_direction': syncDirection,
    'sync_hash': syncHash,
    'error_message': errorMessage,
  };
}

/// Universal ERP Export/Import Standard Models
class CustomerExportModel {
  final String localId;
  final String unvan;
  final String? taxNumber;
  final String? identityNumber;
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final String? country;
  final String currency;
  final double currentBalance;

  const CustomerExportModel({
    required this.localId,
    required this.unvan,
    this.taxNumber,
    this.identityNumber,
    this.email,
    this.phone,
    this.address,
    this.city,
    this.country,
    this.currency = 'TRY',
    this.currentBalance = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'local_id': localId,
    'company_name': unvan,
    'tax_id': taxNumber ?? identityNumber ?? '',
    'email': email,
    'phone': phone,
    'address': address,
    'city': city,
    'country': country,
    'currency': currency,
    'balance': currentBalance,
  };

  String computeHash() => md5.convert(utf8.encode(jsonEncode(toJson()))).toString();
}

class ProductExportModel {
  final String localId;
  final String sku;
  final String name;
  final String? barcode;
  final String unit;
  final double vatRate;
  final double salePrice;
  final double purchasePrice;
  final String currency;

  const ProductExportModel({
    required this.localId,
    required this.sku,
    required this.name,
    this.barcode,
    this.unit = 'C62', // UN/ECE code for pieces
    this.vatRate = 20.0,
    this.salePrice = 0.0,
    this.purchasePrice = 0.0,
    this.currency = 'TRY',
  });

  Map<String, dynamic> toJson() => {
    'local_id': localId,
    'sku': sku,
    'name': name,
    'barcode': barcode,
    'unit': unit,
    'vat_rate': vatRate,
    'sale_price': salePrice,
    'purchase_price': purchasePrice,
    'currency': currency,
  };

  String computeHash() => md5.convert(utf8.encode(jsonEncode(toJson()))).toString();
}

class InvoiceExportModel {
  final String localId;
  final String invoiceNumber;
  final String uuid;
  final DateTime issueDate;
  final String customerExternalId;
  final double payableAmount;
  final double vatAmount;
  final String currency;
  final String invoiceType; // SATIS, IADE, TEVKIFAT, IHRACAT
  final List<Map<String, dynamic>> lines;

  const InvoiceExportModel({
    required this.localId,
    required this.invoiceNumber,
    required this.uuid,
    required this.issueDate,
    required this.customerExternalId,
    required this.payableAmount,
    required this.vatAmount,
    this.currency = 'TRY',
    this.invoiceType = 'SATIS',
    this.lines = const [],
  });

  Map<String, dynamic> toJson() => {
    'local_id': localId,
    'invoice_number': invoiceNumber,
    'uuid': uuid,
    'issue_date': issueDate.toIso8601String(),
    'customer_id': customerExternalId,
    'payable_amount': payableAmount,
    'vat_amount': vatAmount,
    'currency': currency,
    'type': invoiceType,
    'lines': lines,
  };

  String computeHash() => md5.convert(utf8.encode(jsonEncode(toJson()))).toString();
}

class JournalExportModel {
  final String localId;
  final String entryNumber;
  final DateTime entryDate;
  final String description;
  final double totalDebit;
  final double totalCredit;
  final List<Map<String, dynamic>> lines;

  const JournalExportModel({
    required this.localId,
    required this.entryNumber,
    required this.entryDate,
    required this.description,
    required this.totalDebit,
    required this.totalCredit,
    this.lines = const [],
  });

  Map<String, dynamic> toJson() => {
    'local_id': localId,
    'entry_number': entryNumber,
    'entry_date': entryDate.toIso8601String(),
    'description': description,
    'total_debit': totalDebit,
    'total_credit': totalCredit,
    'lines': lines,
  };

  String computeHash() => md5.convert(utf8.encode(jsonEncode(toJson()))).toString();
}
