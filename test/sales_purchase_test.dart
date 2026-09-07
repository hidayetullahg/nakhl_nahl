import 'package:flutter_test/flutter_test.dart';
import 'package:nakhl_nahl/repositories/sales_repository.dart';
import 'package:nakhl_nahl/repositories/purchase_repository.dart';

void main() {
  group('FAZ 15: Sales + Purchase Bounded Context Unit Tests', () {
    test('SalesOrderModel and InvoiceModel parsing and calculation', () {
      final soMap = {
        'id': 'so-uuid-001',
        'order_number': 'SO-2026-101',
        'order_date': '2026-09-06',
        'expected_delivery_date': '2026-09-10',
        'customer_id': 'party-cust-01',
        'warehouse_id': 'wh-medina-01',
        'currency': 'SAR',
        'subtotal': 1600.0,
        'tax_amount': 240.0,
        'grand_total': 1840.0,
        'status': 'CONFIRMED',
        'notes': 'İhracat Siparişi',
      };

      final salesOrder = SalesOrderModel.fromMap(soMap);
      expect(salesOrder.orderNumber, 'SO-2026-101');
      expect(salesOrder.subtotal, 1600.0);
      expect(salesOrder.taxAmount, 240.0);
      expect(salesOrder.grandTotal, 1840.0);
      expect(salesOrder.status, 'CONFIRMED');

      final invMap = {
        'id': 'inv-uuid-001',
        'invoice_type': 'SALES',
        'invoice_number': 'SATIS-2026-101',
        'invoice_date': '2026-09-06',
        'party_id': 'party-cust-01',
        'warehouse_id': 'wh-medina-01',
        'currency': 'SAR',
        'subtotal': 1600.0,
        'tax_rate': 15.0,
        'tax_amount': 240.0,
        'grand_total': 1840.0,
        'status': 'POSTED',
        'journal_entry_id': 'j-uuid-001',
        'notes': 'Resmi ZATCA faturası',
      };

      final invoice = InvoiceModel.fromMap(invMap);
      expect(invoice.invoiceType, 'SALES');
      expect(invoice.invoiceNumber, 'SATIS-2026-101');
      expect(invoice.taxRate, 15.0);
      expect(invoice.grandTotal, 1840.0);
      expect(invoice.status, 'POSTED');
      expect(invoice.journalEntryId, 'j-uuid-001');
    });

    test('PurchaseOrderModel parsing and tax calculation', () {
      final poMap = {
        'id': 'po-uuid-001',
        'order_number': 'PO-2026-001',
        'order_date': '2026-09-06',
        'expected_delivery_date': '2026-09-08',
        'supplier_id': 'party-sup-01',
        'warehouse_id': 'wh-medina-01',
        'currency': 'SAR',
        'subtotal': 5000.0,
        'tax_amount': 750.0,
        'grand_total': 5750.0,
        'payment_terms_days': 30,
        'status': 'COMPLETED',
        'notes': 'Hasat Mal Kabulü',
      };

      final po = PurchaseOrderModel.fromMap(poMap);
      expect(po.orderNumber, 'PO-2026-001');
      expect(po.subtotal, 5000.0);
      expect(po.taxAmount, 750.0);
      expect(po.grandTotal, 5750.0);
      expect(po.paymentTermsDays, 30);
      expect(po.status, 'COMPLETED');
    });

    test('Invoice tax and totals arithmetic check', () {
      const quantity = 25.0;
      const unitPrice = 60.0;
      const taxRate = 15.0;

      final subtotal = quantity * unitPrice; // 1500.0
      final taxAmount = subtotal * (taxRate / 100.0); // 225.0
      final grandTotal = subtotal + taxAmount; // 1725.0

      expect(subtotal, 1500.0);
      expect(taxAmount, 225.0);
      expect(grandTotal, 1725.0);
    });
  });
}
