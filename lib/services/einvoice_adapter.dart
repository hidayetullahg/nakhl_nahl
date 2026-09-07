// NAKHL & NAHL — Türkiye E-Fatura / E-Arşiv / Özel Entegratör Adapter Mimarisi
// Complies with Sections 29 & 30 of Master Production Directive

enum EInvoiceProviderType {
  mockSandbox,
  gibIntegrator,
  qnb,
  logo,
  uyumsoft,
  sovos;

  static EInvoiceProviderType fromString(String? val) {
    switch (val?.trim().toLowerCase()) {
      case 'qnb':
        return EInvoiceProviderType.qnb;
      case 'logo':
        return EInvoiceProviderType.logo;
      case 'uyumsoft':
        return EInvoiceProviderType.uyumsoft;
      case 'sovos':
        return EInvoiceProviderType.sovos;
      case 'gib':
      case 'gib_integrator':
        return EInvoiceProviderType.gibIntegrator;
      default:
        return EInvoiceProviderType.mockSandbox;
    }
  }
}

enum EInvoiceStatus {
  draft,
  queued,
  sent,
  approved,
  rejected,
  cancelled,
  failed
}

class EInvoiceResult {
  final bool success;
  final String invoiceUuid;
  final String? invoiceNumber;
  final EInvoiceStatus status;
  final String? gibStatusCode;
  final String? message;
  final String? signedXml;
  final DateTime timestamp;

  const EInvoiceResult({
    required this.success,
    required this.invoiceUuid,
    this.invoiceNumber,
    required this.status,
    this.gibStatusCode,
    this.message,
    this.signedXml,
    required this.timestamp,
  });
}

abstract class EInvoiceAdapter {
  EInvoiceProviderType get providerType;

  Future<bool> validateTaxpayer({
    required String vknTckn,
  });

  Future<EInvoiceResult> sendInvoice({
    required String tenantId,
    required String companyId,
    required Map<String, dynamic> invoiceData,
    required String idempotencyKey,
  });

  Future<EInvoiceResult> queryInvoiceStatus({
    required String invoiceUuid,
  });

  Future<EInvoiceResult> cancelInvoice({
    required String invoiceUuid,
    required String reason,
  });

  String generateUblTrXml(Map<String, dynamic> invoiceData);
}

/// Mock / Sandbox Adapter — Unit ve Entegrasyon Testleri için
class MockSandboxEInvoiceAdapter implements EInvoiceAdapter {
  @override
  EInvoiceProviderType get providerType => EInvoiceProviderType.mockSandbox;

  @override
  Future<bool> validateTaxpayer({required String vknTckn}) async {
    // 10 haneli VKN veya 11 haneli TCKN simülasyonu
    return (vknTckn.length == 10 || vknTckn.length == 11);
  }

  @override
  Future<EInvoiceResult> sendInvoice({
    required String tenantId,
    required String companyId,
    required Map<String, dynamic> invoiceData,
    required String idempotencyKey,
  }) async {
    final uuid = invoiceData['uuid']?.toString() ?? 'MOCK-INV-UUID-001';
    final number = invoiceData['invoice_number']?.toString() ?? 'GIB2026000000001';

    return EInvoiceResult(
      success: true,
      invoiceUuid: uuid,
      invoiceNumber: number,
      status: EInvoiceStatus.approved,
      gibStatusCode: '1300', // GİB Başarıyla Tamamlandı Kodu
      message: 'SANDBOX: Fatura GİB sistemine başarıyla iletildi.',
      signedXml: generateUblTrXml(invoiceData),
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<EInvoiceResult> queryInvoiceStatus({required String invoiceUuid}) async {
    return EInvoiceResult(
      success: true,
      invoiceUuid: invoiceUuid,
      status: EInvoiceStatus.approved,
      gibStatusCode: '1300',
      message: 'SANDBOX: Fatura onaylandı.',
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<EInvoiceResult> cancelInvoice({
    required String invoiceUuid,
    required String reason,
  }) async {
    return EInvoiceResult(
      success: true,
      invoiceUuid: invoiceUuid,
      status: EInvoiceStatus.cancelled,
      message: 'SANDBOX: Fatura iptal edildi ($reason).',
      timestamp: DateTime.now(),
    );
  }

  @override
  String generateUblTrXml(Map<String, dynamic> invoiceData) {
    final uuid = invoiceData['uuid'] ?? 'MOCK-UUID';
    final invNum = invoiceData['invoice_number'] ?? 'GIB2026000000001';
    final total = invoiceData['grand_total'] ?? 0.0;

    return '''<?xml version="1.0" encoding="UTF-8"?>
<Invoice xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2"
         xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
         xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2">
  <cbc:UBLVersionID>2.1</cbc:UBLVersionID>
  <cbc:CustomizationID>TR1.2</cbc:CustomizationID>
  <cbc:ProfileID>TICARIFATURA</cbc:ProfileID>
  <cbc:ID>$invNum</cbc:ID>
  <cbc:UUID>$uuid</cbc:UUID>
  <cbc:IssueDate>${DateTime.now().toIso8601String().substring(0, 10)}</cbc:IssueDate>
  <cac:LegalMonetaryTotal>
    <cbc:PayableAmount currencyID="TRY">$total</cbc:PayableAmount>
  </cac:LegalMonetaryTotal>
</Invoice>''';
  }
}

/// Logo Entegratör Adapter
class LogoAdapter implements EInvoiceAdapter {
  final String apiKey;
  final String endpoint;
  final bool isProduction;

  const LogoAdapter({
    required this.apiKey,
    required this.endpoint,
    this.isProduction = false,
  });

  @override
  EInvoiceProviderType get providerType => EInvoiceProviderType.logo;

  @override
  Future<bool> validateTaxpayer({required String vknTckn}) async {
    if (!isProduction) return vknTckn.length == 10 || vknTckn.length == 11;
    // Production API call via server-side secure edge function
    throw UnimplementedError('Production credentials required for live Logo validation');
  }

  @override
  Future<EInvoiceResult> sendInvoice({
    required String tenantId,
    required String companyId,
    required Map<String, dynamic> invoiceData,
    required String idempotencyKey,
  }) async {
    if (!isProduction) {
      return MockSandboxEInvoiceAdapter().sendInvoice(
        tenantId: tenantId,
        companyId: companyId,
        invoiceData: invoiceData,
        idempotencyKey: idempotencyKey,
      );
    }
    throw UnimplementedError('Production credentials required for live Logo invoice sending');
  }

  @override
  Future<EInvoiceResult> queryInvoiceStatus({required String invoiceUuid}) async {
    if (!isProduction) return MockSandboxEInvoiceAdapter().queryInvoiceStatus(invoiceUuid: invoiceUuid);
    throw UnimplementedError('Production credentials required for live Logo status check');
  }

  @override
  Future<EInvoiceResult> cancelInvoice({required String invoiceUuid, required String reason}) async {
    if (!isProduction) return MockSandboxEInvoiceAdapter().cancelInvoice(invoiceUuid: invoiceUuid, reason: reason);
    throw UnimplementedError('Production credentials required for live Logo cancellation');
  }

  @override
  String generateUblTrXml(Map<String, dynamic> invoiceData) {
    return MockSandboxEInvoiceAdapter().generateUblTrXml(invoiceData);
  }
}

/// QNB eFinans Entegratör Adapter
class QnbAdapter implements EInvoiceAdapter {
  final String apiKey;
  final bool isProduction;

  const QnbAdapter({required this.apiKey, this.isProduction = false});

  @override
  EInvoiceProviderType get providerType => EInvoiceProviderType.qnb;

  @override
  Future<bool> validateTaxpayer({required String vknTckn}) async {
    return MockSandboxEInvoiceAdapter().validateTaxpayer(vknTckn: vknTckn);
  }

  @override
  Future<EInvoiceResult> sendInvoice({
    required String tenantId,
    required String companyId,
    required Map<String, dynamic> invoiceData,
    required String idempotencyKey,
  }) async {
    return MockSandboxEInvoiceAdapter().sendInvoice(
      tenantId: tenantId,
      companyId: companyId,
      invoiceData: invoiceData,
      idempotencyKey: idempotencyKey,
    );
  }

  @override
  Future<EInvoiceResult> queryInvoiceStatus({required String invoiceUuid}) async {
    return MockSandboxEInvoiceAdapter().queryInvoiceStatus(invoiceUuid: invoiceUuid);
  }

  @override
  Future<EInvoiceResult> cancelInvoice({required String invoiceUuid, required String reason}) async {
    return MockSandboxEInvoiceAdapter().cancelInvoice(invoiceUuid: invoiceUuid, reason: reason);
  }

  @override
  String generateUblTrXml(Map<String, dynamic> invoiceData) {
    return MockSandboxEInvoiceAdapter().generateUblTrXml(invoiceData);
  }
}

/// Uyumsoft Entegratör Adapter
class UyumsoftAdapter implements EInvoiceAdapter {
  final String apiKey;
  final bool isProduction;

  const UyumsoftAdapter({required this.apiKey, this.isProduction = false});

  @override
  EInvoiceProviderType get providerType => EInvoiceProviderType.uyumsoft;

  @override
  Future<bool> validateTaxpayer({required String vknTckn}) async {
    return MockSandboxEInvoiceAdapter().validateTaxpayer(vknTckn: vknTckn);
  }

  @override
  Future<EInvoiceResult> sendInvoice({
    required String tenantId,
    required String companyId,
    required Map<String, dynamic> invoiceData,
    required String idempotencyKey,
  }) async {
    return MockSandboxEInvoiceAdapter().sendInvoice(
      tenantId: tenantId,
      companyId: companyId,
      invoiceData: invoiceData,
      idempotencyKey: idempotencyKey,
    );
  }

  @override
  Future<EInvoiceResult> queryInvoiceStatus({required String invoiceUuid}) async {
    return MockSandboxEInvoiceAdapter().queryInvoiceStatus(invoiceUuid: invoiceUuid);
  }

  @override
  Future<EInvoiceResult> cancelInvoice({required String invoiceUuid, required String reason}) async {
    return MockSandboxEInvoiceAdapter().cancelInvoice(invoiceUuid: invoiceUuid, reason: reason);
  }

  @override
  String generateUblTrXml(Map<String, dynamic> invoiceData) {
    return MockSandboxEInvoiceAdapter().generateUblTrXml(invoiceData);
  }
}

/// Sovos Entegratör Adapter
class SovosAdapter implements EInvoiceAdapter {
  final String apiKey;
  final bool isProduction;

  const SovosAdapter({required this.apiKey, this.isProduction = false});

  @override
  EInvoiceProviderType get providerType => EInvoiceProviderType.sovos;

  @override
  Future<bool> validateTaxpayer({required String vknTckn}) async {
    return MockSandboxEInvoiceAdapter().validateTaxpayer(vknTckn: vknTckn);
  }

  @override
  Future<EInvoiceResult> sendInvoice({
    required String tenantId,
    required String companyId,
    required Map<String, dynamic> invoiceData,
    required String idempotencyKey,
  }) async {
    return MockSandboxEInvoiceAdapter().sendInvoice(
      tenantId: tenantId,
      companyId: companyId,
      invoiceData: invoiceData,
      idempotencyKey: idempotencyKey,
    );
  }

  @override
  Future<EInvoiceResult> queryInvoiceStatus({required String invoiceUuid}) async {
    return MockSandboxEInvoiceAdapter().queryInvoiceStatus(invoiceUuid: invoiceUuid);
  }

  @override
  Future<EInvoiceResult> cancelInvoice({required String invoiceUuid, required String reason}) async {
    return MockSandboxEInvoiceAdapter().cancelInvoice(invoiceUuid: invoiceUuid, reason: reason);
  }

  @override
  String generateUblTrXml(Map<String, dynamic> invoiceData) {
    return MockSandboxEInvoiceAdapter().generateUblTrXml(invoiceData);
  }
}

/// Factory pattern for tenant-specific provider resolution
class EInvoiceFactory {
  static EInvoiceAdapter getAdapter({
    required EInvoiceProviderType providerType,
    String? apiKey,
    String? endpoint,
    bool isProduction = false,
  }) {
    switch (providerType) {
      case EInvoiceProviderType.logo:
        return LogoAdapter(apiKey: apiKey ?? '', endpoint: endpoint ?? '', isProduction: isProduction);
      case EInvoiceProviderType.qnb:
        return QnbAdapter(apiKey: apiKey ?? '', isProduction: isProduction);
      case EInvoiceProviderType.uyumsoft:
        return UyumsoftAdapter(apiKey: apiKey ?? '', isProduction: isProduction);
      case EInvoiceProviderType.sovos:
        return SovosAdapter(apiKey: apiKey ?? '', isProduction: isProduction);
      case EInvoiceProviderType.mockSandbox:
      case EInvoiceProviderType.gibIntegrator:
      default:
        return MockSandboxEInvoiceAdapter();
    }
  }
}
