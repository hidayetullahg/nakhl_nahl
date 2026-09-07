import 'package:flutter_test/flutter_test.dart';
import 'package:nakhl_nahl/repositories/accounting_repository.dart';

void main() {
  group('FAZ 14: Accounting & Finance Core Unit Tests', () {
    test('ChartOfAccountModel parsing and posting_allowed validation', () {
      final parentMap = {
        'id': 'coa-parent-01',
        'account_code': '100',
        'account_name': 'Kasa ve Bankalar Ana Hesap',
        'account_type': 'ASSET',
        'balance_type': 'DEBIT',
        'posting_allowed': false,
        'is_active': true,
      };

      final detailMap = {
        'id': 'coa-detail-01',
        'parent_id': 'coa-parent-01',
        'account_code': '100.01',
        'account_name': 'Medine Kasa SAR',
        'account_type': 'ASSET',
        'balance_type': 'DEBIT',
        'posting_allowed': true,
        'currency_code': 'SAR',
        'is_active': true,
      };

      final parent = ChartOfAccountModel.fromMap(parentMap);
      expect(parent.accountCode, '100');
      expect(parent.postingAllowed, isFalse);

      final detail = ChartOfAccountModel.fromMap(detailMap);
      expect(detail.accountCode, '100.01');
      expect(detail.postingAllowed, isTrue);
      expect(detail.parentId, 'coa-parent-01');
    });

    test('FiscalPeriodModel status (OPEN, CLOSED, LOCKED)', () {
      final periodMap = {
        'id': 'fp-01',
        'company_id': 'comp-01',
        'year': 2026,
        'period_no': 9,
        'start_date': '2026-09-01',
        'end_date': '2026-09-30',
        'status': 'OPEN',
      };

      final period = FiscalPeriodModel.fromMap(periodMap);
      expect(period.year, 2026);
      expect(period.periodNo, 9);
      expect(period.status, 'OPEN');

      final lockedPeriodMap = {
        'id': 'fp-02',
        'company_id': 'comp-01',
        'year': 2026,
        'period_no': 8,
        'start_date': '2026-08-01',
        'end_date': '2026-08-31',
        'status': 'LOCKED',
      };

      final lockedPeriod = FiscalPeriodModel.fromMap(lockedPeriodMap);
      expect(lockedPeriod.status, 'LOCKED');
    });

    test('Double-Entry Balance and Multi-Currency calculation', () {
      final lines = [
        const JournalLine(
          accountId: 'acc-cash',
          description: 'Kasa Girişi',
          debitAmount: 1000.0,
          creditAmount: 0.0,
          transactionCurrency: 'USD',
          exchangeRate: 3.75,
        ),
        const JournalLine(
          accountId: 'acc-rev',
          description: 'Gelir Tahakkuku',
          debitAmount: 0.0,
          creditAmount: 1000.0,
          transactionCurrency: 'USD',
          exchangeRate: 3.75,
        ),
      ];

      double totalDebit = 0.0;
      double totalCredit = 0.0;
      double totalBaseDebit = 0.0;
      double totalBaseCredit = 0.0;

      for (final line in lines) {
        totalDebit += line.debitAmount;
        totalCredit += line.creditAmount;
        totalBaseDebit += line.debitAmount * line.exchangeRate;
        totalBaseCredit += line.creditAmount * line.exchangeRate;
      }

      // Check balance equality: Total Debit == Total Credit
      expect(totalDebit, totalCredit);
      expect(totalDebit, 1000.0);

      // Check base currency conversion (USD -> SAR at 3.75)
      expect(totalBaseDebit, 3750.0);
      expect(totalBaseCredit, 3750.0);
      expect(totalBaseDebit, totalBaseCredit);
    });
  });
}
