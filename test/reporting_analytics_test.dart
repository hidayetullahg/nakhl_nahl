import 'package:flutter_test/flutter_test.dart';
import 'package:nakhl_nahl/repositories/analytics_reporting_repository.dart';

void main() {
  group('FAZ 23: Reporting + Analytics Bounded Context Tests', () {
    test(
        'SalesReportRow & PurchaseReportRow parse correctly from database views',
        () {
      final salesJson = {
        'company_id': 'cmp-001',
        'company_name': 'NAKHL & NAHL Madinah LLC',
        'invoice_number': 'INV-2026-001',
        'invoice_date': '2026-09-01',
        'customer_name': 'Al-Noor Gourmet Dates',
        'customer_country': 'SA',
        'currency': 'SAR',
        'net_sales': 10000.00,
        'tax_sales': 1500.00,
        'gross_sales': 11500.00,
        'status': 'POSTED',
      };

      final salesRow = SalesReportRow.fromJson(salesJson);
      expect(salesRow.invoiceNumber, 'INV-2026-001');
      expect(salesRow.customerName, 'Al-Noor Gourmet Dates');
      expect(salesRow.netSales, 10000.00);
      expect(salesRow.taxSales, 1500.00);
      expect(salesRow.grossSales, 11500.00);
      expect(salesRow.status, 'POSTED');

      final purchaseJson = {
        'company_id': 'cmp-001',
        'company_name': 'NAKHL & NAHL Madinah LLC',
        'invoice_number': 'PINV-2026-005',
        'invoice_date': '2026-08-20',
        'supplier_name': 'Qassim Agro Palms Ltd.',
        'supplier_country': 'SA',
        'currency': 'SAR',
        'net_purchase': 50000.00,
        'tax_purchase': 7500.00,
        'gross_purchase': 57500.00,
        'status': 'PAID',
      };

      final purchaseRow = PurchaseReportRow.fromJson(purchaseJson);
      expect(purchaseRow.invoiceNumber, 'PINV-2026-005');
      expect(purchaseRow.supplierName, 'Qassim Agro Palms Ltd.');
      expect(purchaseRow.netPurchase, 50000.00);
      expect(purchaseRow.grossPurchase, 57500.00);
    });

    test(
        'InventoryReportRow and StockMovementReportRow parse valuation and direction',
        () {
      final invJson = {
        'company_id': 'cmp-001',
        'company_name': 'NAKHL & NAHL Madinah LLC',
        'warehouse_name': 'Medine Soğuk Hava Deposu',
        'warehouse_code': 'WH-MED-01',
        'item_sku': 'MED-AJW-JUMBO',
        'item_name': 'Medine Acve Jumbo Hurma',
        'unit_of_measure': 'Kg',
        'current_quantity': 1500.0,
        'estimated_valuation_sar': 37500.0,
      };

      final invRow = InventoryReportRow.fromJson(invJson);
      expect(invRow.itemSku, 'MED-AJW-JUMBO');
      expect(invRow.currentQuantity, 1500.0);
      expect(invRow.estimatedValuationSar, 37500.0);

      final movJson = {
        'company_id': 'cmp-001',
        'company_name': 'NAKHL & NAHL Madinah LLC',
        'movement_type': 'PURCHASE_RECEIPT',
        'direction': 'IN',
        'warehouse_name': 'Medine Soğuk Hava Deposu',
        'item_sku': 'MED-AJW-JUMBO',
        'item_name': 'Medine Acve Jumbo Hurma',
        'quantity': 500.0,
        'total_cost': 12500.0,
        'movement_timestamp': '2026-09-02T10:30:00.000Z',
      };

      final movRow = StockMovementReportRow.fromJson(movJson);
      expect(movRow.movementType, 'PURCHASE_RECEIPT');
      expect(movRow.direction, 'IN');
      expect(movRow.quantity, 500.0);
    });

    test('LotTraceabilityReportRow validates full chain linkage', () {
      final lotJson = {
        'company_id': 'cmp-001',
        'company_name': 'NAKHL & NAHL Madinah LLC',
        'lot_number': 'LOT-2026-AJW-001',
        'item_name': 'Medine Acve Jumbo Hurma',
        'harvest_date': '2026-08-15',
        'expiry_date': '2028-08-15',
        'lot_status': 'RELEASED',
        'latest_quality_result': 'PASS',
        'halal_compliance_status': 'COMPLIANT',
      };

      final lotRow = LotTraceabilityReportRow.fromJson(lotJson);
      expect(lotRow.lotNumber, 'LOT-2026-AJW-001');
      expect(lotRow.lotStatus, 'RELEASED');
      expect(lotRow.latestQualityResult, 'PASS');
      expect(lotRow.halalComplianceStatus, 'COMPLIANT');
    });

    test('QualityReportRow and HalalReportRow parse compliance KPIs', () {
      final qualityJson = {
        'company_id': 'cmp-001',
        'company_name': 'NAKHL & NAHL Madinah LLC',
        'inspection_type': 'FINAL',
        'total_inspections': 50,
        'pass_count': 48,
        'fail_count': 1,
        'conditional_count': 1,
        'quarantine_count': 0,
        'pass_percentage': 96.0,
      };

      final qRow = QualityReportRow.fromJson(qualityJson);
      expect(qRow.totalInspections, 50);
      expect(qRow.passCount, 48);
      expect(qRow.passPercentage, 96.0);

      final halalJson = {
        'company_id': 'cmp-001',
        'company_name': 'NAKHL & NAHL Madinah LLC',
        'certification_body': 'GSO / SMIIC Accredited Body',
        'total_certificates_count': 3,
        'valid_certificates_count': 3,
        'expired_or_invalid_count': 0,
        'certified_lots_count': 142,
      };

      final hRow = HalalReportRow.fromJson(halalJson);
      expect(hRow.validCertificatesCount, 3);
      expect(hRow.certifiedLotsCount, 142);
    });

    test(
        'ExecutiveDashboardSummary parses single-roundtrip JSON (N+1 query prevention)',
        () {
      final summaryJson = {
        'generated_at': '2026-09-06T12:00:00.000Z',
        'company_id': 'cmp-001',
        'tenant_id': 'ten-001',
        'sales_summary': {
          'total_orders': 120,
          'net_sales': 1450000.00,
          'tax_sales': 217500.00,
          'gross_sales': 1667500.00,
          'currency': 'SAR',
        },
        'purchase_summary': {
          'total_orders': 45,
          'net_purchase': 820000.00,
          'tax_purchase': 123000.00,
          'gross_purchase': 943000.00,
          'currency': 'SAR',
        },
        'inventory_summary': {
          'total_sku_count': 28,
          'total_quantity_on_hand': 45000.0,
          'estimated_valuation_sar': 1125000.00,
        },
        'quality_summary': {
          'total_inspections': 64,
          'pass_count': 62,
          'fail_count': 2,
          'quarantine_count': 1,
          'pass_rate': 96.88,
        },
        'halal_summary': {
          'active_certificates': 4,
          'expiring_in_30_days': 0,
          'expired_certificates': 0,
        },
        'trade_and_logistics_summary': {
          'active_export_files': 6,
          'in_transit_shipments': 4,
          'cold_chain_alerts': 0,
        },
        'finance_summary': {
          'total_cash_and_bank_sar': 2340000.00,
          'active_accounts_count': 5,
        },
      };

      final summary = ExecutiveDashboardSummary.fromJson(summaryJson);
      expect(summary.companyId, 'cmp-001');
      expect(summary.tenantId, 'ten-001');
      expect(summary.salesSummary['total_orders'], 120);
      expect(summary.salesSummary['net_sales'], 1450000.00);
      expect(summary.purchaseSummary['total_orders'], 45);
      expect(summary.inventorySummary['total_quantity_on_hand'], 45000.0);
      expect(summary.qualitySummary['pass_rate'], 96.88);
      expect(summary.halalSummary['active_certificates'], 4);
      expect(summary.tradeAndLogisticsSummary['in_transit_shipments'], 4);
      expect(summary.financeSummary['total_cash_and_bank_sar'], 2340000.00);
    });

    test('Preserved RaporlamaServisi export format integrity check', () {
      // Check that all 11 formats and 3 categories are intact
      expect(RaporFormati.values.length, 11);
      expect(RaporKategorisi.values.length, 3);
      expect(RaporFormati.csv.kategori, RaporKategorisi.veriEntegrasyon);
      expect(RaporFormati.pdf.kategori, RaporKategorisi.metinDokuman);
      expect(RaporFormati.xlsx.kategori, RaporKategorisi.metinDokuman);
      expect(RaporFormati.json.kategori, RaporKategorisi.veriEntegrasyon);
    });
  });
}
