import 'package:flutter_test/flutter_test.dart';
import 'package:nakhl_nahl/repositories/pos_repository.dart';

void main() {
  group('FAZ 25: POS / Operational Sales Bounded Context Tests', () {
    test('PosPaymentMethod abstraction maps correctly across all payment types',
        () {
      final methods = [
        PosPaymentMethod.cash,
        PosPaymentMethod.creditCard,
        PosPaymentMethod.madaDebit,
        PosPaymentMethod.bankTransfer,
        PosPaymentMethod.loyaltyPoints,
      ];

      for (final m in methods) {
        final dbVal = m.dbValue;
        final converted = PosPaymentMethod.fromDbValue(dbVal);
        expect(converted, m);
      }
    });

    test(
        'PosSaleLineInput and PosPaymentInput serialize correctly for RPC payload',
        () {
      final line = PosSaleLineInput(
        itemId: 'item-ajwa-01',
        lotId: 'lot-2026-001',
        quantity: 3.5,
        unitPrice: 60.0,
        taxRate: 15.0,
      );

      final lineJson = line.toJson();
      expect(lineJson['item_id'], 'item-ajwa-01');
      expect(lineJson['lot_id'], 'lot-2026-001');
      expect(lineJson['quantity'], 3.5);
      expect(lineJson['unit_price'], 60.0);
      expect(lineJson['tax_rate'], 15.0);

      final payment = PosPaymentInput(
        method: PosPaymentMethod.madaDebit,
        amount: 241.50,
        referenceCode: 'MADA-AUTH-9912',
      );

      final payJson = payment.toJson();
      expect(payJson['payment_method'], 'MADA_DEBIT');
      expect(payJson['amount'], 241.50);
      expect(payJson['reference_code'], 'MADA-AUTH-9912');
    });

    test('PosSaleResult parses atomic execution output and ZATCA QR code', () {
      final json = {
        'success': true,
        'is_replay': false,
        'pos_sale_id': 'pos-sale-001',
        'receipt_number': 'REC-20260906-12345',
        'journal_entry_id': 'jrn-pos-001',
        'subtotal': 200.0,
        'tax_amount': 30.0,
        'grand_total': 230.0,
        'zatca_qr': 'ZATCA-QR:REC-20260906-12345:230.0:30.0',
      };

      final res = PosSaleResult.fromJson(json);
      expect(res.success, isTrue);
      expect(res.isReplay, isFalse);
      expect(res.posSaleId, 'pos-sale-001');
      expect(res.receiptNumber, 'REC-20260906-12345');
      expect(res.journalEntryId, 'jrn-pos-001');
      expect(res.subtotal, 200.0);
      expect(res.taxAmount, 30.0);
      expect(res.grandTotal, 230.0);
      expect(res.zatcaQr, contains('ZATCA-QR:REC-20260906-12345'));
    });

    test(
        'Offline Replay Protection flag in PosSaleResult indicates idempotent response',
        () {
      final json = {
        'success': true,
        'is_replay': true,
        'pos_sale_id': 'pos-sale-001',
        'receipt_number': 'REC-20260906-12345',
        'grand_total': 230.0,
        'message': 'Mevcut POS satışı bulundu (Replay koruması etkin).',
      };

      final res = PosSaleResult.fromJson(json);
      expect(res.success, isTrue);
      expect(res.isReplay, isTrue);
      expect(res.posSaleId, 'pos-sale-001');
      expect(res.message, contains('Replay'));
    });

    test('PosRefundResult parses reversal details and journal link', () {
      final json = {
        'success': true,
        'pos_sale_id': 'pos-sale-001',
        'status': 'REFUNDED',
        'reverse_journal_id': 'jrn-ref-001',
        'refund_amount': 230.0,
      };

      final refund = PosRefundResult.fromJson(json);
      expect(refund.success, isTrue);
      expect(refund.posSaleId, 'pos-sale-001');
      expect(refund.status, 'REFUNDED');
      expect(refund.reverseJournalId, 'jrn-ref-001');
      expect(refund.refundAmount, 230.0);
    });

    test('PosTerminalModel and PosSessionModel parse status and balances', () {
      final termJson = {
        'id': 'term-01',
        'company_id': 'cmp-01',
        'warehouse_id': 'wh-01',
        'terminal_code': 'TERM-01',
        'name': 'Kasa 1 - Medine Mağaza',
        'status': 'ACTIVE',
      };

      final terminal = PosTerminalModel.fromJson(termJson);
      expect(terminal.terminalCode, 'TERM-01');
      expect(terminal.status, 'ACTIVE');

      final sessionJson = {
        'id': 'sess-01',
        'terminal_id': 'term-01',
        'cashier_user_id': 'usr-cashier-01',
        'opened_at': '2026-09-06T08:00:00.000Z',
        'closed_at': null,
        'opening_cash_balance': 500.0,
        'closing_cash_balance': null,
        'status': 'OPEN',
      };

      final session = PosSessionModel.fromJson(sessionJson);
      expect(session.isOpen, isTrue);
      expect(session.openingCashBalance, 500.0);
      expect(session.closingCashBalance, isNull);
    });
  });
}
