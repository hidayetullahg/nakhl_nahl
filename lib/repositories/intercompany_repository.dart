import '../services/supabase_service.dart';
import '../core/tenant/tenant_context.dart';

/// Transfer Fiyatlandırması Yöntemleri
enum TransferPricingMethod {
  armLength,
  costPlus,
  resaleMinus,
  profitSplit,
  tnmm;

  String get dbValue {
    switch (this) {
      case TransferPricingMethod.armLength:
        return 'ARM_LENGTH';
      case TransferPricingMethod.costPlus:
        return 'COST_PLUS';
      case TransferPricingMethod.resaleMinus:
        return 'RESALE_MINUS';
      case TransferPricingMethod.profitSplit:
        return 'PROFIT_SPLIT';
      case TransferPricingMethod.tnmm:
        return 'TNMM';
    }
  }

  static TransferPricingMethod fromDbValue(String val) {
    switch (val.toUpperCase()) {
      case 'ARM_LENGTH':
        return TransferPricingMethod.armLength;
      case 'COST_PLUS':
        return TransferPricingMethod.costPlus;
      case 'RESALE_MINUS':
        return TransferPricingMethod.resaleMinus;
      case 'PROFIT_SPLIT':
        return TransferPricingMethod.profitSplit;
      case 'TNMM':
        return TransferPricingMethod.tnmm;
      default:
        return TransferPricingMethod.armLength;
    }
  }
}

/// Şirketler Arası Ticaret Sözleşmesi Modeli
class IntercompanyAgreementModel {
  final String id;
  final String sellerCompanyId;
  final String buyerCompanyId;
  final String agreementCode;
  final String title;
  final String currency;
  final TransferPricingMethod transferPricingMethod;
  final double markupPercentage;
  final String status;

  const IntercompanyAgreementModel({
    required this.id,
    required this.sellerCompanyId,
    required this.buyerCompanyId,
    required this.agreementCode,
    required this.title,
    required this.currency,
    required this.transferPricingMethod,
    required this.markupPercentage,
    required this.status,
  });

  factory IntercompanyAgreementModel.fromJson(Map<String, dynamic> json) {
    return IntercompanyAgreementModel(
      id: json['id'] as String,
      sellerCompanyId: json['seller_company_id'] as String,
      buyerCompanyId: json['buyer_company_id'] as String,
      agreementCode: json['agreement_code'] as String? ?? '',
      title: json['title'] as String? ?? '',
      currency: json['currency'] as String? ?? 'SAR',
      transferPricingMethod: TransferPricingMethod.fromDbValue(
          json['transfer_pricing_method'] as String? ?? 'ARM_LENGTH'),
      markupPercentage: (json['markup_percentage'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'ACTIVE',
    );
  }
}

/// Şirketler Arası İşlem Modeli
class IntercompanyTransactionModel {
  final String id;
  final String sellerCompanyId;
  final String buyerCompanyId;
  final String transactionNumber;
  final DateTime transactionDate;
  final String currency;
  final double subtotal;
  final double taxAmount;
  final double grandTotal;
  final TransferPricingMethod transferPricingMethod;
  final double markupPercentage;
  final String status;
  final String? sellerInvoiceId;
  final String? buyerInvoiceId;
  final String? sellerJournalId;
  final String? buyerJournalId;

  const IntercompanyTransactionModel({
    required this.id,
    required this.sellerCompanyId,
    required this.buyerCompanyId,
    required this.transactionNumber,
    required this.transactionDate,
    required this.currency,
    required this.subtotal,
    required this.taxAmount,
    required this.grandTotal,
    required this.transferPricingMethod,
    required this.markupPercentage,
    required this.status,
    this.sellerInvoiceId,
    this.buyerInvoiceId,
    this.sellerJournalId,
    this.buyerJournalId,
  });

  bool get isPosted => status == 'POSTED';

  factory IntercompanyTransactionModel.fromJson(Map<String, dynamic> json) {
    return IntercompanyTransactionModel(
      id: json['id'] as String,
      sellerCompanyId: json['seller_company_id'] as String,
      buyerCompanyId: json['buyer_company_id'] as String,
      transactionNumber: json['transaction_number'] as String? ?? '',
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      currency: json['currency'] as String? ?? 'SAR',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (json['grand_total'] as num?)?.toDouble() ?? 0.0,
      transferPricingMethod: TransferPricingMethod.fromDbValue(
          json['transfer_pricing_method'] as String? ?? 'ARM_LENGTH'),
      markupPercentage: (json['markup_percentage'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'DRAFT',
      sellerInvoiceId: json['seller_invoice_id'] as String?,
      buyerInvoiceId: json['buyer_invoice_id'] as String?,
      sellerJournalId: json['seller_journal_id'] as String?,
      buyerJournalId: json['buyer_journal_id'] as String?,
    );
  }
}

/// Şirketler Arası Muhasebe ve Faturalaşma Sonuç Modeli
class IntercompanyPostResult {
  final bool success;
  final String intercompanyTxId;
  final String? sellerInvoiceId;
  final String? buyerInvoiceId;
  final String? sellerJournalId;
  final String? buyerJournalId;
  final double dueFromAmount;
  final double dueToAmount;
  final bool isReconciled;

  const IntercompanyPostResult({
    required this.success,
    required this.intercompanyTxId,
    this.sellerInvoiceId,
    this.buyerInvoiceId,
    this.sellerJournalId,
    this.buyerJournalId,
    required this.dueFromAmount,
    required this.dueToAmount,
    required this.isReconciled,
  });

  factory IntercompanyPostResult.fromJson(Map<String, dynamic> json) {
    return IntercompanyPostResult(
      success: json['success'] as bool? ?? false,
      intercompanyTxId: json['intercompany_tx_id'] as String? ?? '',
      sellerInvoiceId: json['seller_invoice_id'] as String?,
      buyerInvoiceId: json['buyer_invoice_id'] as String?,
      sellerJournalId: json['seller_journal_id'] as String?,
      buyerJournalId: json['buyer_journal_id'] as String?,
      dueFromAmount: (json['due_from_amount'] as num?)?.toDouble() ?? 0.0,
      dueToAmount: (json['due_to_amount'] as num?)?.toDouble() ?? 0.0,
      isReconciled: json['is_reconciled'] as bool? ?? false,
    );
  }
}

/// Şirketler Arası Stok Transfer Sonuç Modeli
class IntercompanyStockTransferResult {
  final bool success;
  final String transferId;
  final String transferNumber;
  final double quantity;
  final String status;

  const IntercompanyStockTransferResult({
    required this.success,
    required this.transferId,
    required this.transferNumber,
    required this.quantity,
    required this.status,
  });

  factory IntercompanyStockTransferResult.fromJson(Map<String, dynamic> json) {
    return IntercompanyStockTransferResult(
      success: json['success'] as bool? ?? false,
      transferId: json['transfer_id'] as String? ?? '',
      transferNumber: json['transfer_number'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'RECEIVED',
    );
  }
}

/// NAKHL & NAHL — Şirketler Arası Ticaret ve Muhasebe Servisi
class IntercompanyRepository {
  IntercompanyRepository._();
  static final IntercompanyRepository instance = IntercompanyRepository._();

  /// Eşleşmiş Çift Fatura ve Due From / Due To Yevmiyelerini Atomik Olarak Oluşturur
  Future<IntercompanyPostResult?> postIntercompanyTransaction({
    required String intercompanyTxId,
    required String fromWarehouseId,
    required String toWarehouseId,
    String? userId,
  }) async {
    try {
      final res = await SupabaseService.client
          .rpc('post_intercompany_sale_purchase_transaction', params: {
        'p_intercompany_tx_id': intercompanyTxId,
        'p_from_warehouse_id': fromWarehouseId,
        'p_to_warehouse_id': toWarehouseId,
        'p_user_id': userId,
      });

      if (res is Map<String, dynamic>) {
        return IntercompanyPostResult.fromJson(res);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Şirketler Arası Stok Transferi (TRANSFER -> OUT -> IN)
  Future<IntercompanyStockTransferResult?> transferStock({
    required String fromCompanyId,
    required String fromWarehouseId,
    required String toCompanyId,
    required String toWarehouseId,
    required String itemId,
    String? lotId,
    required double quantity,
    required double transferPrice,
    String? userId,
  }) async {
    final tenantId = TenantContext.instance.activeTenantId;
    if (tenantId == null) return null;

    try {
      final res = await SupabaseService.client
          .rpc('execute_intercompany_stock_transfer', params: {
        'p_tenant_id': tenantId,
        'p_from_company_id': fromCompanyId,
        'p_from_warehouse_id': fromWarehouseId,
        'p_to_company_id': toCompanyId,
        'p_to_warehouse_id': toWarehouseId,
        'p_item_id': itemId,
        'p_lot_id': lotId,
        'p_quantity': quantity,
        'p_transfer_price': transferPrice,
        'p_user_id': userId,
      });

      if (res is Map<String, dynamic>) {
        return IntercompanyStockTransferResult.fromJson(res);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Şirketin Dahil Olduğu Şirketler Arası İşlemleri Getir
  Future<List<IntercompanyTransactionModel>> getTransactions(
      String companyId) async {
    try {
      final res = await SupabaseService.client
          .from('intercompany_transactions')
          .select()
          .or('seller_company_id.eq.$companyId,buyer_company_id.eq.$companyId')
          .order('transaction_date', ascending: false);

      return (res as List<dynamic>)
          .map((e) =>
              IntercompanyTransactionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
