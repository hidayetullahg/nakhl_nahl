import '../services/supabase_service.dart';
import '../core/tenant/tenant_context.dart';

/// Hesap Planı Kart Modeli (Chart of Accounts)
class ChartOfAccountModel {
  final String id;
  final String accountCode;
  final String accountName;
  final String accountType; // ASSET, LIABILITY, EQUITY, REVENUE, EXPENSE
  final String? parentId;
  final String balanceType; // DEBIT, CREDIT
  final String currencyCode;
  final bool postingAllowed; // true: Detay/Kayıt Hesabı, false: Ana/Grup Hesabı
  final bool isActive;

  const ChartOfAccountModel({
    required this.id,
    required this.accountCode,
    required this.accountName,
    required this.accountType,
    this.parentId,
    required this.balanceType,
    this.currencyCode = 'SAR',
    this.postingAllowed = true,
    this.isActive = true,
  });

  factory ChartOfAccountModel.fromMap(Map<String, dynamic> map) {
    return ChartOfAccountModel(
      id: map['id'] ?? '',
      accountCode: map['account_code'] ?? '',
      accountName: map['account_name'] ?? '',
      accountType: map['account_type'] ?? 'ASSET',
      parentId: map['parent_id'],
      balanceType: map['balance_type'] ?? 'DEBIT',
      currencyCode: map['currency_code'] ?? 'SAR',
      postingAllowed: map['posting_allowed'] ?? true,
      isActive: map['is_active'] ?? true,
    );
  }
}

/// Mali Dönem Modeli (Fiscal Period)
class FiscalPeriodModel {
  final String id;
  final String companyId;
  final int year;
  final int periodNo;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // OPEN, CLOSED, LOCKED

  const FiscalPeriodModel({
    required this.id,
    required this.companyId,
    required this.year,
    required this.periodNo,
    required this.startDate,
    required this.endDate,
    this.status = 'OPEN',
  });

  factory FiscalPeriodModel.fromMap(Map<String, dynamic> map) {
    return FiscalPeriodModel(
      id: map['id'] ?? '',
      companyId: map['company_id'] ?? '',
      year: map['year'] ?? DateTime.now().year,
      periodNo: map['period_no'] ?? 1,
      startDate: DateTime.parse(map['start_date'].toString()),
      endDate: DateTime.parse(map['end_date'].toString()),
      status: map['status'] ?? (map['is_closed'] == true ? 'CLOSED' : 'OPEN'),
    );
  }
}

/// Tarihsel Döviz Kuru Modeli (Exchange Rate)
class ExchangeRateModel {
  final String id;
  final String fromCurrency;
  final String toCurrency;
  final DateTime rateDate;
  final double rate;
  final String source;

  const ExchangeRateModel({
    required this.id,
    required this.fromCurrency,
    required this.toCurrency,
    required this.rateDate,
    required this.rate,
    this.source = 'CENTRAL_BANK',
  });

  factory ExchangeRateModel.fromMap(Map<String, dynamic> map) {
    return ExchangeRateModel(
      id: map['id'] ?? '',
      fromCurrency: map['from_currency'] ?? 'USD',
      toCurrency: map['to_currency'] ?? 'SAR',
      rateDate: DateTime.parse(map['rate_date'].toString()),
      rate: (map['rate'] as num?)?.toDouble() ?? 1.0,
      source: map['source'] ?? 'CENTRAL_BANK',
    );
  }
}

/// Yevmiye Fişi Satırı Modeli (Journal Line)
class JournalLine {
  final String accountId;
  final String? partyId;
  final String description;
  final double debitAmount;
  final double creditAmount;
  final String transactionCurrency;
  final double exchangeRate;

  const JournalLine({
    required this.accountId,
    this.partyId,
    required this.description,
    required this.debitAmount,
    required this.creditAmount,
    this.transactionCurrency = 'SAR',
    this.exchangeRate = 1.000000,
  });

  Map<String, dynamic> toMap() {
    return {
      'account_id': accountId,
      if (partyId != null) 'party_id': partyId,
      'description': description,
      'debit_amount': debitAmount,
      'credit_amount': creditAmount,
      'transaction_currency': transactionCurrency,
      'exchange_rate': exchangeRate,
    };
  }
}

class AccountingRepository {
  AccountingRepository._();
  static final AccountingRepository instance = AccountingRepository._();

  /// Şirketin hesap planını getirir
  Future<List<Map<String, dynamic>>> getChartOfAccounts(
      String companyId) async {
    try {
      final response = await SupabaseService.client
          .from('chart_of_accounts')
          .select()
          .eq('company_id', companyId)
          .eq('is_active', true)
          .order('account_code', ascending: true);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      return [];
    }
  }

  /// Hesap planı modelleri listesi
  Future<List<ChartOfAccountModel>> getAccounts(String companyId) async {
    final raw = await getChartOfAccounts(companyId);
    return raw.map((m) => ChartOfAccountModel.fromMap(m)).toList();
  }

  /// Şirketin mali dönemlerini listeler
  Future<List<FiscalPeriodModel>> getFiscalPeriods(String companyId) async {
    try {
      final res = await SupabaseService.client
          .from('fiscal_periods')
          .select()
          .eq('company_id', companyId)
          .order('year', ascending: false)
          .order('period_no', ascending: false);

      return (res as List<dynamic>)
          .map((m) => FiscalPeriodModel.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// ATOMİK TEK TRANSACTION: Yevmiye fişini ve satırlarını tek seferde oluşturur (RPC)
  Future<String> createCompleteJournalEntry({
    required String companyId,
    required DateTime entryDate,
    required String entryType,
    required String documentType,
    required String documentReference,
    required String description,
    required List<JournalLine> lines,
    bool autoPost = false,
  }) async {
    final tenantId = TenantContext.instance.activeTenantId;
    if (tenantId == null) throw Exception('Aktif tenant seçilmedi.');

    final linesPayload = lines.map((l) => l.toMap()).toList();

    final res = await SupabaseService.client.rpc(
      'create_complete_journal_entry_rpc',
      params: {
        'p_tenant_id': tenantId,
        'p_company_id': companyId,
        'p_entry_date': entryDate.toIso8601String().substring(0, 10),
        'p_entry_type': entryType,
        'p_document_type': documentType,
        'p_document_reference': documentReference,
        'p_description': description,
        'p_lines': linesPayload,
        'p_auto_post': autoPost,
      },
    );

    return res as String;
  }

  /// DRAFT yevmiye fişini onaylayarak POSTED aşamasına geçirir
  Future<void> postJournalEntry(String entryId) async {
    await SupabaseService.client.from('journal_entries').update({
      'status': 'POSTED',
      'posted_at': DateTime.now().toIso8601String()
    }).eq('id', entryId);
  }

  /// Kesinleşmiş (POSTED) fişi ters kayıt (reversal) ile iptal eder
  Future<String> reverseJournalEntry({
    required String entryId,
    required DateTime reversalDate,
    required String reason,
  }) async {
    final res = await SupabaseService.client.rpc(
      'reverse_journal_entry_rpc',
      params: {
        'p_journal_entry_id': entryId,
        'p_reversal_date': reversalDate.toIso8601String().substring(0, 10),
        'p_reversal_reason': reason,
      },
    );

    return res as String;
  }

  /// Çift taraflı muhasebe fişi kaydeder (Geriye dönük uyumlu)
  Future<String?> createJournalEntry({
    required String companyId,
    required DateTime entryDate,
    required String entryType,
    required String description,
    required String documentType,
    required String documentReference,
    required List<JournalLine> lines,
    bool autoPost = false,
  }) async {
    return createCompleteJournalEntry(
      companyId: companyId,
      entryDate: entryDate,
      entryType: entryType,
      documentType: documentType,
      documentReference: documentReference,
      description: description,
      lines: lines,
      autoPost: autoPost,
    );
  }

  /// Satış faturası için otomatik muhasebe kaydı oluşturur (120 Borç / 600 Alacak / 391 Alacak)
  Future<String?> createSalesInvoiceJournal({
    required String companyId,
    required String faturaNo,
    required DateTime faturaTarihi,
    required String cariId,
    required String cariUnvani,
    required double araToplam,
    required double kdvTutari,
    required double genelToplam,
    required String alicilarHesapId,
    required String satisGelirHesapId,
    required String kdvHesapId,
  }) async {
    final lines = [
      // 120 ALICILAR (BORÇ)
      JournalLine(
        accountId: alicilarHesapId,
        partyId: cariId,
        description: 'Satış Faturası: $faturaNo — $cariUnvani',
        debitAmount: genelToplam,
        creditAmount: 0.0,
      ),
      // 600 YURT İÇİ / DIŞI SATIŞLAR (ALACAK)
      JournalLine(
        accountId: satisGelirHesapId,
        partyId: cariId,
        description: 'Hurma Satış Geliri: $faturaNo',
        debitAmount: 0.0,
        creditAmount: araToplam,
      ),
      // 391 HESAPLANAN KDV / VAT (ALACAK)
      if (kdvTutari > 0)
        JournalLine(
          accountId: kdvHesapId,
          partyId: cariId,
          description: 'Hesaplanan KDV (%15): $faturaNo',
          debitAmount: 0.0,
          creditAmount: kdvTutari,
        ),
    ];

    return createCompleteJournalEntry(
      companyId: companyId,
      entryDate: faturaTarihi,
      entryType: 'SALES_INVOICE',
      documentType: 'INVOICE',
      documentReference: faturaNo,
      description: 'Satış Faturası Muhasebe Fişi: $faturaNo',
      lines: lines,
      autoPost: true,
    );
  }

  /// Döviz kurlarını sorgular
  Future<double> getExchangeRate({
    required String fromCurrency,
    required String toCurrency,
    DateTime? forDate,
  }) async {
    if (fromCurrency == toCurrency) return 1.0;
    try {
      final tenantId = TenantContext.instance.activeTenantId;
      if (tenantId == null) return 1.0;

      final dateStr =
          (forDate ?? DateTime.now()).toIso8601String().substring(0, 10);
      final res = await SupabaseService.client.rpc(
        'get_exchange_rate',
        params: {
          'p_tenant_id': tenantId,
          'p_from_currency': fromCurrency,
          'p_to_currency': toCurrency,
          'p_rate_date': dateStr,
        },
      );

      return (res as num?)?.toDouble() ?? 1.0;
    } catch (e) {
      return 1.0;
    }
  }

  /// Döviz kuru ekler
  Future<void> recordExchangeRate({
    required String fromCurrency,
    required String toCurrency,
    required DateTime rateDate,
    required double rate,
    String source = 'CENTRAL_BANK',
  }) async {
    final tenantId = TenantContext.instance.activeTenantId;
    if (tenantId == null) throw Exception('Aktif tenant seçilmedi.');

    await SupabaseService.client.from('exchange_rates').upsert({
      'tenant_id': tenantId,
      'from_currency': fromCurrency,
      'to_currency': toCurrency,
      'rate_date': rateDate.toIso8601String().substring(0, 10),
      'rate': rate,
      'source': source,
    }, onConflict: 'tenant_id,from_currency,to_currency,rate_date');
  }
}
