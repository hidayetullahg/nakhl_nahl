import '../services/supabase_service.dart';
import '../core/tenant/tenant_context.dart';

/// POS Ödeme Yöntemleri Soyutlaması
enum PosPaymentMethod {
  cash,
  creditCard,
  madaDebit,
  bankTransfer,
  loyaltyPoints;

  String get dbValue {
    switch (this) {
      case PosPaymentMethod.cash:
        return 'CASH';
      case PosPaymentMethod.creditCard:
        return 'CREDIT_CARD';
      case PosPaymentMethod.madaDebit:
        return 'MADA_DEBIT';
      case PosPaymentMethod.bankTransfer:
        return 'BANK_TRANSFER';
      case PosPaymentMethod.loyaltyPoints:
        return 'LOYALTY_POINTS';
    }
  }

  static PosPaymentMethod fromDbValue(String val) {
    switch (val.toUpperCase()) {
      case 'CASH':
        return PosPaymentMethod.cash;
      case 'CREDIT_CARD':
        return PosPaymentMethod.creditCard;
      case 'MADA_DEBIT':
        return PosPaymentMethod.madaDebit;
      case 'BANK_TRANSFER':
        return PosPaymentMethod.bankTransfer;
      case 'LOYALTY_POINTS':
        return PosPaymentMethod.loyaltyPoints;
      default:
        return PosPaymentMethod.cash;
    }
  }
}

/// POS Satış Kalem Girdisi
class PosSaleLineInput {
  final String itemId;
  final String? lotId;
  final double quantity;
  final double unitPrice;
  final double taxRate;

  const PosSaleLineInput({
    required this.itemId,
    this.lotId,
    required this.quantity,
    required this.unitPrice,
    this.taxRate = 15.0,
  });

  Map<String, dynamic> toJson() => {
        'item_id': itemId,
        if (lotId != null) 'lot_id': lotId,
        'quantity': quantity,
        'unit_price': unitPrice,
        'tax_rate': taxRate,
      };
}

/// POS Ödeme Girdisi
class PosPaymentInput {
  final PosPaymentMethod method;
  final double amount;
  final String? referenceCode;

  const PosPaymentInput({
    required this.method,
    required this.amount,
    this.referenceCode,
  });

  Map<String, dynamic> toJson() => {
        'payment_method': method.dbValue,
        'amount': amount,
        if (referenceCode != null) 'reference_code': referenceCode,
      };
}

/// POS Satış Sonuç Modeli
class PosSaleResult {
  final bool success;
  final bool isReplay;
  final String posSaleId;
  final String receiptNumber;
  final String? journalEntryId;
  final double subtotal;
  final double taxAmount;
  final double grandTotal;
  final String? zatcaQr;
  final String? message;

  const PosSaleResult({
    required this.success,
    this.isReplay = false,
    required this.posSaleId,
    required this.receiptNumber,
    this.journalEntryId,
    required this.subtotal,
    required this.taxAmount,
    required this.grandTotal,
    this.zatcaQr,
    this.message,
  });

  factory PosSaleResult.fromJson(Map<String, dynamic> json) {
    return PosSaleResult(
      success: json['success'] as bool? ?? false,
      isReplay: json['is_replay'] as bool? ?? false,
      posSaleId: json['pos_sale_id'] as String? ?? '',
      receiptNumber: json['receipt_number'] as String? ?? '',
      journalEntryId: json['journal_entry_id'] as String?,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (json['grand_total'] as num?)?.toDouble() ?? 0.0,
      zatcaQr: json['zatca_qr'] as String?,
      message: json['message'] as String?,
    );
  }
}

/// POS İade Sonuç Modeli
class PosRefundResult {
  final bool success;
  final String posSaleId;
  final String status;
  final String? reverseJournalId;
  final double refundAmount;

  const PosRefundResult({
    required this.success,
    required this.posSaleId,
    required this.status,
    this.reverseJournalId,
    required this.refundAmount,
  });

  factory PosRefundResult.fromJson(Map<String, dynamic> json) {
    return PosRefundResult(
      success: json['success'] as bool? ?? false,
      posSaleId: json['pos_sale_id'] as String? ?? '',
      status: json['status'] as String? ?? 'REFUNDED',
      reverseJournalId: json['reverse_journal_id'] as String?,
      refundAmount: (json['refund_amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// POS Terminal Modeli
class PosTerminalModel {
  final String id;
  final String companyId;
  final String warehouseId;
  final String terminalCode;
  final String name;
  final String status;

  const PosTerminalModel({
    required this.id,
    required this.companyId,
    required this.warehouseId,
    required this.terminalCode,
    required this.name,
    required this.status,
  });

  factory PosTerminalModel.fromJson(Map<String, dynamic> json) {
    return PosTerminalModel(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      warehouseId: json['warehouse_id'] as String,
      terminalCode: json['terminal_code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? 'ACTIVE',
    );
  }
}

/// POS Session Modeli
class PosSessionModel {
  final String id;
  final String terminalId;
  final String cashierUserId;
  final DateTime openedAt;
  final DateTime? closedAt;
  final double openingCashBalance;
  final double? closingCashBalance;
  final String status;

  const PosSessionModel({
    required this.id,
    required this.terminalId,
    required this.cashierUserId,
    required this.openedAt,
    this.closedAt,
    required this.openingCashBalance,
    this.closingCashBalance,
    required this.status,
  });

  bool get isOpen => status == 'OPEN';

  factory PosSessionModel.fromJson(Map<String, dynamic> json) {
    return PosSessionModel(
      id: json['id'] as String,
      terminalId: json['terminal_id'] as String,
      cashierUserId: json['cashier_user_id'] as String,
      openedAt: DateTime.parse(json['opened_at'] as String),
      closedAt: json['closed_at'] != null
          ? DateTime.tryParse(json['closed_at'] as String)
          : null,
      openingCashBalance:
          (json['opening_cash_balance'] as num?)?.toDouble() ?? 0.0,
      closingCashBalance: (json['closing_cash_balance'] as num?)?.toDouble(),
      status: json['status'] as String? ?? 'OPEN',
    );
  }
}

/// NAKHL & NAHL — POS / Operasyonel Satış Servisi
class PosRepository {
  PosRepository._();
  static final PosRepository instance = PosRepository._();

  /// ATOMİK POS SATIŞI (PRODUCT -> SALE -> PAYMENT -> STOCK -> JOURNAL)
  /// Çevrimdışı replay koruması için clientTransactionId kullanılır.
  Future<PosSaleResult?> executeSaleTransaction({
    required String companyId,
    required String terminalId,
    required String sessionId,
    required String clientTransactionId,
    required String warehouseId,
    String? customerPartyId,
    required List<PosSaleLineInput> lines,
    required List<PosPaymentInput> payments,
    String currency = 'SAR',
    String? userId,
  }) async {
    final tenantId = TenantContext.instance.activeTenantId;
    if (tenantId == null) return null;

    try {
      final res = await SupabaseService.client
          .rpc('execute_pos_sale_transaction', params: {
        'p_tenant_id': tenantId,
        'p_company_id': companyId,
        'p_terminal_id': terminalId,
        'p_session_id': sessionId,
        'p_client_transaction_id': clientTransactionId,
        'p_warehouse_id': warehouseId,
        'p_customer_party_id': customerPartyId,
        'p_lines': lines.map((l) => l.toJson()).toList(),
        'p_payments': payments.map((p) => p.toJson()).toList(),
        'p_currency': currency,
        'p_user_id': userId,
      });

      if (res is Map<String, dynamic>) {
        return PosSaleResult.fromJson(res);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// ATOMİK POS İADESİ (REFUND -> STOCK REVERSAL -> REVERSAL JOURNAL)
  Future<PosRefundResult?> executeRefundTransaction({
    required String posSaleId,
    String reason = 'Müşteri Talebi',
    String? userId,
  }) async {
    try {
      final res = await SupabaseService.client
          .rpc('execute_pos_refund_transaction', params: {
        'p_pos_sale_id': posSaleId,
        'p_refund_reason': reason,
        'p_user_id': userId,
      });

      if (res is Map<String, dynamic>) {
        return PosRefundResult.fromJson(res);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Şirketin POS Terminallerini Listele
  Future<List<PosTerminalModel>> getTerminals(String companyId) async {
    try {
      final res = await SupabaseService.client
          .from('pos_terminals')
          .select()
          .eq('company_id', companyId)
          .order('terminal_code');

      return (res as List<dynamic>)
          .map((e) => PosTerminalModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
