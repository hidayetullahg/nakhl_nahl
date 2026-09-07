import '../einvoice_adapter.dart';
import '../zatca_adapter.dart';

enum DocumentFormat {
  ublTr,
  ubl21,
  peppolBis3,
  xmlCustom,
  json
}

class EInvoiceDocumentResult {
  final bool success;
  final String documentUuid;
  final String? documentNumber;
  final String status;
  final String? rawResponse;
  final String? signedXml;
  final String? qrCode;
  final List<String> errors;
  final List<String> warnings;
  final DateTime timestamp;

  const EInvoiceDocumentResult({
    required this.success,
    required this.documentUuid,
    this.documentNumber,
    required this.status,
    this.rawResponse,
    this.signedXml,
    this.qrCode,
    this.errors = const [],
    this.warnings = const [],
    required this.timestamp,
  });
}

abstract class UniversalEInvoiceAdapter {
  String get countryCode;
  String get providerCode;
  DocumentFormat get documentFormat;

  Future<bool> validateTaxIdentity(String taxNumber);

  Future<EInvoiceDocumentResult> createInvoice(Map<String, dynamic> invoiceData);

  Future<List<String>> validateInvoice(Map<String, dynamic> invoiceData);

  Future<EInvoiceDocumentResult> submitInvoice({
    required String tenantId,
    required Map<String, dynamic> invoiceData,
    required String idempotencyKey,
  });

  Future<EInvoiceDocumentResult> getInvoiceStatus(String documentUuid);

  Future<EInvoiceDocumentResult> cancelInvoice({
    required String documentUuid,
    required String reason,
  });

  Future<EInvoiceDocumentResult> rejectInvoice({
    required String documentUuid,
    required String reason,
  });

  Future<String> downloadInvoice(String documentUuid, {String format = 'PDF'});

  Future<Map<String, dynamic>> parseIncomingDocument(String rawXml);

  String generateDocumentXml(Map<String, dynamic> invoiceData);

  // Mappers
  String mapInvoiceStatus(String providerStatus);
  double mapTax(double rate, {String? taxCode});
  Map<String, dynamic> mapCustomer(Map<String, dynamic> localCustomer);
  Map<String, dynamic> mapProduct(Map<String, dynamic> localProduct);
  String mapCurrency(String localCurrency);
  String mapPayment(String localPaymentMethod);
  String mapUnit(String localUnit);
}

/// Türkiye GİB / UBL-TR Universal Adapter Implementation
class TurkeyGibUniversalAdapter implements UniversalEInvoiceAdapter {
  final MockSandboxEInvoiceAdapter _innerAdapter = MockSandboxEInvoiceAdapter();

  @override
  String get countryCode => 'TR';

  @override
  String get providerCode => 'GIB';

  @override
  DocumentFormat get documentFormat => DocumentFormat.ublTr;

  @override
  Future<bool> validateTaxIdentity(String taxNumber) async {
    final clean = taxNumber.replaceAll(RegExp(r'[^0-9]'), '');
    return clean.length == 10 || clean.length == 11;
  }

  @override
  Future<List<String>> validateInvoice(Map<String, dynamic> invoiceData) async {
    final errors = <String>[];
    if (invoiceData['customer_tax_number'] == null || invoiceData['customer_tax_number'].toString().isEmpty) {
      errors.add('Müşteri Vergi Numarası (VKN/TCKN) zorunludur.');
    }
    if (invoiceData['payable_amount'] == null || (invoiceData['payable_amount'] as num) <= 0) {
      errors.add('Fatura ödenecek tutar sıfırdan büyük olmalıdır.');
    }
    final lines = invoiceData['lines'] as List?;
    if (lines == null || lines.isEmpty) {
      errors.add('Faturada en az bir satır bulunmalıdır.');
    }
    return errors;
  }

  @override
  Future<EInvoiceDocumentResult> createInvoice(Map<String, dynamic> invoiceData) async {
    final errors = await validateInvoice(invoiceData);
    if (errors.isNotEmpty) {
      return EInvoiceDocumentResult(
        success: false,
        documentUuid: invoiceData['uuid']?.toString() ?? '',
        status: 'VALIDATION_FAILED',
        errors: errors,
        timestamp: DateTime.now(),
      );
    }
    final xml = generateDocumentXml(invoiceData);
    return EInvoiceDocumentResult(
      success: true,
      documentUuid: invoiceData['uuid']?.toString() ?? 'TR-INV-001',
      documentNumber: invoiceData['invoice_number']?.toString() ?? 'GIB202600000001',
      status: 'DRAFT',
      signedXml: xml,
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<EInvoiceDocumentResult> submitInvoice({
    required String tenantId,
    required Map<String, dynamic> invoiceData,
    required String idempotencyKey,
  }) async {
    final result = await _innerAdapter.sendInvoice(
      tenantId: tenantId,
      companyId: invoiceData['company_id']?.toString() ?? '',
      invoiceData: invoiceData,
      idempotencyKey: idempotencyKey,
    );

    return EInvoiceDocumentResult(
      success: result.success,
      documentUuid: result.invoiceUuid,
      documentNumber: result.invoiceNumber,
      status: mapInvoiceStatus(result.status.name),
      signedXml: result.signedXml,
      rawResponse: result.message,
      timestamp: result.timestamp,
    );
  }

  @override
  Future<EInvoiceDocumentResult> getInvoiceStatus(String documentUuid) async {
    final result = await _innerAdapter.queryInvoiceStatus(invoiceUuid: documentUuid);
    return EInvoiceDocumentResult(
      success: result.success,
      documentUuid: result.invoiceUuid,
      status: mapInvoiceStatus(result.status.name),
      timestamp: result.timestamp,
    );
  }

  @override
  Future<EInvoiceDocumentResult> cancelInvoice({
    required String documentUuid,
    required String reason,
  }) async {
    final result = await _innerAdapter.cancelInvoice(invoiceUuid: documentUuid, reason: reason);
    return EInvoiceDocumentResult(
      success: result.success,
      documentUuid: result.invoiceUuid,
      status: 'CANCELLED',
      rawResponse: result.message,
      timestamp: result.timestamp,
    );
  }

  @override
  Future<EInvoiceDocumentResult> rejectInvoice({
    required String documentUuid,
    required String reason,
  }) async {
    return EInvoiceDocumentResult(
      success: true,
      documentUuid: documentUuid,
      status: 'REJECTED',
      rawResponse: 'GİB Belge Reddedildi: $reason',
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<String> downloadInvoice(String documentUuid, {String format = 'PDF'}) async {
    return 'https://efatura.gib.gov.tr/download/$documentUuid.$format';
  }

  @override
  Future<Map<String, dynamic>> parseIncomingDocument(String rawXml) async {
    return {
      'parsed': true,
      'standard': 'UBL-TR',
      'raw_length': rawXml.length,
    };
  }

  @override
  String generateDocumentXml(Map<String, dynamic> invoiceData) {
    return _innerAdapter.generateUblTrXml(invoiceData);
  }

  @override
  String mapInvoiceStatus(String providerStatus) {
    switch (providerStatus.toLowerCase()) {
      case 'approved':
      case '1300':
        return 'APPROVED';
      case 'rejected':
        return 'REJECTED';
      case 'cancelled':
        return 'CANCELLED';
      case 'queued':
        return 'QUEUED';
      default:
        return 'SENT';
    }
  }

  @override
  double mapTax(double rate, {String? taxCode}) => rate;

  @override
  Map<String, dynamic> mapCustomer(Map<String, dynamic> localCustomer) {
    return {
      'unvan': localCustomer['unvan'] ?? '',
      'vkn_tckn': localCustomer['vergi_no'] ?? localCustomer['tc_kimlik'] ?? '',
      'email': localCustomer['email'],
      'address': localCustomer['adres'],
    };
  }

  @override
  Map<String, dynamic> mapProduct(Map<String, dynamic> localProduct) {
    return {
      'name': localProduct['name'] ?? '',
      'sku': localProduct['sku'] ?? '',
      'unit_code': mapUnit(localProduct['unit']?.toString() ?? 'ADET'),
      'vat_rate': (localProduct['vat_rate'] as num?)?.toDouble() ?? 20.0,
    };
  }

  @override
  String mapCurrency(String localCurrency) => localCurrency.toUpperCase();

  @override
  String mapPayment(String localPaymentMethod) {
    switch (localPaymentMethod.toLowerCase()) {
      case 'nakit':
        return '10'; // Nakit UBL code
      case 'kredi_karti':
        return '48'; // Kredi kartı UBL code
      case 'havale':
        return '42'; // Banka transferi UBL code
      default:
        return 'ZZZ';
    }
  }

  @override
  String mapUnit(String localUnit) {
    switch (localUnit.toUpperCase()) {
      case 'ADET':
        return 'C62';
      case 'KG':
        return 'KGM';
      case 'METRE':
        return 'MTR';
      case 'LITRE':
        return 'LTR';
      case 'KOLI':
        return 'BX';
      default:
        return 'C62';
    }
  }
}

/// Suudi Arabistan ZATCA Phase 2 Fatoora Universal Adapter Implementation
class SaudiZatcaUniversalAdapter implements UniversalEInvoiceAdapter {
  final ZatcaPhase2Adapter _innerAdapter = const ZatcaPhase2Adapter();

  @override
  String get countryCode => 'SA';

  @override
  String get providerCode => 'ZATCA';

  @override
  DocumentFormat get documentFormat => DocumentFormat.ubl21;

  @override
  Future<bool> validateTaxIdentity(String taxNumber) async {
    final clean = taxNumber.replaceAll(RegExp(r'[^0-9]'), '');
    return clean.length == 15 && clean.startsWith('3') && clean.endsWith('3');
  }

  @override
  Future<List<String>> validateInvoice(Map<String, dynamic> invoiceData) async {
    final errors = <String>[];
    final vat = invoiceData['vat_number']?.toString() ?? '';
    if (!await validateTaxIdentity(vat)) {
      errors.add('ZATCA 15 haneli 3 ile başlayıp 3 ile biten VAT numarası zorunludur.');
    }
    if (invoiceData['payable_amount'] == null || (invoiceData['payable_amount'] as num) <= 0) {
      errors.add('ZATCA fatura tutarı pozitif olmalıdır.');
    }
    return errors;
  }

  @override
  Future<EInvoiceDocumentResult> createInvoice(Map<String, dynamic> invoiceData) async {
    final errors = await validateInvoice(invoiceData);
    if (errors.isNotEmpty) {
      return EInvoiceDocumentResult(
        success: false,
        documentUuid: invoiceData['uuid']?.toString() ?? '',
        status: 'VALIDATION_FAILED',
        errors: errors,
        timestamp: DateTime.now(),
      );
    }

    final qr = ZatcaPhase2Adapter.generateZatcaTlvQrCode(
      sellerName: invoiceData['seller_name']?.toString() ?? 'NAKHL & NAHL CO.',
      vatNumber: invoiceData['vat_number']?.toString() ?? '300000000000003',
      timestamp: DateTime.now(),
      invoiceTotal: (invoiceData['payable_amount'] as num).toDouble(),
      vatTotal: ((invoiceData['payable_amount'] as num) * 0.15).toDouble(),
    );

    final xml = generateDocumentXml(invoiceData);

    return EInvoiceDocumentResult(
      success: true,
      documentUuid: invoiceData['uuid']?.toString() ?? 'SA-ZATCA-INV-001',
      documentNumber: invoiceData['invoice_number']?.toString() ?? 'SA2026000001',
      status: 'DRAFT',
      signedXml: xml,
      qrCode: qr,
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<EInvoiceDocumentResult> submitInvoice({
    required String tenantId,
    required Map<String, dynamic> invoiceData,
    required String idempotencyKey,
  }) async {
    final created = await createInvoice(invoiceData);
    return EInvoiceDocumentResult(
      success: created.success,
      documentUuid: created.documentUuid,
      documentNumber: created.documentNumber,
      status: 'CLEARED',
      qrCode: created.qrCode,
      signedXml: created.signedXml,
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<EInvoiceDocumentResult> getInvoiceStatus(String documentUuid) async {
    return EInvoiceDocumentResult(
      success: true,
      documentUuid: documentUuid,
      status: 'CLEARED',
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<EInvoiceDocumentResult> cancelInvoice({
    required String documentUuid,
    required String reason,
  }) async {
    return EInvoiceDocumentResult(
      success: true,
      documentUuid: documentUuid,
      status: 'CREDIT_NOTE_REQUIRED',
      rawResponse: 'ZATCA kuralları gereği iptal için Eksi Fatura (Credit Note) düzenlenmelidir.',
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<EInvoiceDocumentResult> rejectInvoice({
    required String documentUuid,
    required String reason,
  }) async {
    return EInvoiceDocumentResult(
      success: true,
      documentUuid: documentUuid,
      status: 'REJECTED',
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<String> downloadInvoice(String documentUuid, {String format = 'PDF'}) async {
    return 'https://gw-fatoora.zatca.gov.sa/invoices/$documentUuid.pdf';
  }

  @override
  Future<Map<String, dynamic>> parseIncomingDocument(String rawXml) async {
    return {'parsed': true, 'standard': 'UBL-2.1', 'raw_length': rawXml.length};
  }

  @override
  String generateDocumentXml(Map<String, dynamic> invoiceData) {
    final payable = (invoiceData['payable_amount'] as num?)?.toDouble() ?? 100.0;
    final sub = payable / 1.15;
    final vat = payable - sub;

    return _innerAdapter.generateUbl21Xml(
      uuid: invoiceData['uuid']?.toString() ?? 'SA-UUID',
      invoiceNumber: invoiceData['invoice_number']?.toString() ?? 'SA-INV-1',
      issueDate: DateTime.now(),
      sellerName: invoiceData['seller_name']?.toString() ?? 'NAKHL SA',
      sellerVat: invoiceData['vat_number']?.toString() ?? '300000000000003',
      buyerName: invoiceData['buyer_name']?.toString() ?? 'Customer',
      buyerVat: invoiceData['buyer_vat']?.toString() ?? '311111111111113',
      subtotal: sub,
      vatAmount: vat,
      grandTotal: payable,
    );
  }

  @override
  String mapInvoiceStatus(String providerStatus) => providerStatus.toUpperCase();

  @override
  double mapTax(double rate, {String? taxCode}) => 15.0; // Standard Saudi VAT

  @override
  Map<String, dynamic> mapCustomer(Map<String, dynamic> localCustomer) {
    return {
      'buyer_name': localCustomer['unvan'] ?? '',
      'buyer_vat': localCustomer['vergi_no'] ?? '',
    };
  }

  @override
  Map<String, dynamic> mapProduct(Map<String, dynamic> localProduct) {
    return {
      'name': localProduct['name'] ?? '',
      'sku': localProduct['sku'] ?? '',
      'vat_rate': 15.0,
      'unit': mapUnit(localProduct['unit']?.toString() ?? 'PCE'),
    };
  }

  @override
  String mapCurrency(String localCurrency) => 'SAR';

  @override
  String mapPayment(String localPaymentMethod) => '10';

  @override
  String mapUnit(String localUnit) => 'PCE';
}
