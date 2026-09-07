import 'package:flutter_test/flutter_test.dart';
import 'package:nakhl_nahl/repositories/intercompany_repository.dart';

void main() {
  group('FAZ 27: Multi-Company + Intercompany Bounded Context Tests', () {
    test('TransferPricingMethod abstraction maps all OECD methods correctly',
        () {
      final methods = [
        TransferPricingMethod.armLength,
        TransferPricingMethod.costPlus,
        TransferPricingMethod.resaleMinus,
        TransferPricingMethod.profitSplit,
        TransferPricingMethod.tnmm,
      ];

      for (final m in methods) {
        final dbVal = m.dbValue;
        final converted = TransferPricingMethod.fromDbValue(dbVal);
        expect(converted, m);
      }
    });

    test(
        'IntercompanyAgreementModel parses transfer pricing agreement correctly',
        () {
      final json = {
        'id': 'agr-001',
        'seller_company_id': 'cmp-riyadh',
        'buyer_company_id': 'cmp-madinah',
        'agreement_code': 'IC-AGR-SA-01',
        'title': 'Hurma Tedarik ve Dağıtım Sözleşmesi',
        'currency': 'SAR',
        'transfer_pricing_method': 'COST_PLUS',
        'markup_percentage': 5.00,
        'status': 'ACTIVE',
      };

      final agreement = IntercompanyAgreementModel.fromJson(json);
      expect(agreement.agreementCode, 'IC-AGR-SA-01');
      expect(agreement.sellerCompanyId, 'cmp-riyadh');
      expect(agreement.buyerCompanyId, 'cmp-madinah');
      expect(agreement.transferPricingMethod, TransferPricingMethod.costPlus);
      expect(agreement.markupPercentage, 5.00);
      expect(agreement.status, 'ACTIVE');
    });

    test(
        'IntercompanyTransactionModel parses paired transaction header and lines',
        () {
      final json = {
        'id': 'ictx-001',
        'seller_company_id': 'cmp-b-seller',
        'buyer_company_id': 'cmp-a-buyer',
        'transaction_number': 'ICTX-2026-0001',
        'transaction_date': '2026-09-06',
        'currency': 'SAR',
        'subtotal': 100000.0,
        'tax_amount': 15000.0,
        'grand_total': 115000.0,
        'transfer_pricing_method': 'COST_PLUS',
        'markup_percentage': 5.0,
        'status': 'POSTED',
        'seller_invoice_id': 'inv-sale-001',
        'buyer_invoice_id': 'inv-purch-001',
        'seller_journal_id': 'jrn-due-from-001',
        'buyer_journal_id': 'jrn-due-to-001',
      };

      final tx = IntercompanyTransactionModel.fromJson(json);
      expect(tx.transactionNumber, 'ICTX-2026-0001');
      expect(tx.isPosted, isTrue);
      expect(tx.subtotal, 100000.0);
      expect(tx.taxAmount, 15000.0);
      expect(tx.grandTotal, 115000.0);
      expect(tx.sellerInvoiceId, 'inv-sale-001');
      expect(tx.buyerInvoiceId, 'inv-purch-001');
      expect(tx.sellerJournalId, 'jrn-due-from-001');
      expect(tx.buyerJournalId, 'jrn-due-to-001');
    });

    test(
        'IntercompanyPostResult validates Due From / Due To reconciliation equality',
        () {
      final json = {
        'success': true,
        'intercompany_tx_id': 'ictx-001',
        'seller_invoice_id': 'inv-sale-001',
        'buyer_invoice_id': 'inv-purch-001',
        'seller_journal_id': 'jrn-due-from-001',
        'buyer_journal_id': 'jrn-due-to-001',
        'due_from_amount': 115000.0,
        'due_to_amount': 115000.0,
        'is_reconciled': true,
      };

      final res = IntercompanyPostResult.fromJson(json);
      expect(res.success, isTrue);
      expect(res.dueFromAmount, 115000.0);
      expect(res.dueToAmount, 115000.0);
      expect(res.dueFromAmount, res.dueToAmount);
      expect(res.isReconciled, isTrue);
    });

    test(
        'IntercompanyStockTransferResult parses transfer details (TRANSFER -> OUT -> IN)',
        () {
      final json = {
        'success': true,
        'transfer_id': 'trf-001',
        'transfer_number': 'TRF-IC-20260906-001',
        'quantity': 500.0,
        'status': 'RECEIVED',
      };

      final trf = IntercompanyStockTransferResult.fromJson(json);
      expect(trf.success, isTrue);
      expect(trf.transferNumber, 'TRF-IC-20260906-001');
      expect(trf.quantity, 500.0);
      expect(trf.status, 'RECEIVED');
    });
  });
}
