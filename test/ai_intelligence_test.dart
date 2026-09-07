import 'package:flutter_test/flutter_test.dart';
import 'package:nakhl_nahl/repositories/ai_intelligence_repository.dart';

void main() {
  group('FAZ 24: AI + OCR + Intelligence Bounded Context Tests', () {
    test('OcrExtractionModel parses fields and ensures draft suggestion status',
        () {
      final json = {
        'id': 'ocr-001',
        'company_id': 'cmp-001',
        'document_id': 'doc-123',
        'image_storage_ref': 'storage/invoices/scan_001.pdf',
        'extracted_invoice_number': 'INV-2026-0099',
        'extracted_date': '2026-09-01',
        'extracted_supplier_name': 'Medina Date Orchards Co.',
        'extracted_customer_name': 'NAKHL & NAHL Trading LLC',
        'extracted_product_name': 'Acve Hurması 1. Sınıf',
        'extracted_quantity': 2500.0,
        'extracted_price': 35.0,
        'extracted_tax_rate': 15.0,
        'extracted_tax_amount': 13125.0,
        'extracted_currency': 'SAR',
        'confidence_score': 0.9850,
        'model_name': 'nakhl-ocr-engine',
        'model_version': 'v2.4',
        'status': 'DRAFT_SUGGESTION',
        'created_at': '2026-09-01T10:00:00.000Z',
      };

      final ocr = OcrExtractionModel.fromJson(json);
      expect(ocr.invoiceNumber, 'INV-2026-0099');
      expect(ocr.supplierName, 'Medina Date Orchards Co.');
      expect(ocr.customerName, 'NAKHL & NAHL Trading LLC');
      expect(ocr.productName, 'Acve Hurması 1. Sınıf');
      expect(ocr.quantity, 2500.0);
      expect(ocr.price, 35.0);
      expect(ocr.taxRate, 15.0);
      expect(ocr.taxAmount, 13125.0);
      expect(ocr.currency, 'SAR');
      expect(ocr.confidenceScore, 0.9850);
      expect(ocr.isDraft, isTrue);
      expect(ocr.isApproved, isFalse);
    });

    test('DocumentClassificationModel maps 8 document types and secondary tags',
        () {
      for (final docClass in AiDocumentClass.values) {
        final json = {
          'id': 'class-${docClass.name}',
          'company_id': 'cmp-001',
          'document_id': 'doc-999',
          'predicted_class': docClass.dbValue,
          'confidence_score': 0.9750,
          'secondary_tags': ['EXPEDITED', 'VERIFIED'],
          'model_name': 'nakhl-doc-classifier',
          'model_version': 'v1.5',
        };

        final model = DocumentClassificationModel.fromJson(json);
        expect(model.predictedClass, docClass);
        expect(model.secondaryTags, contains('EXPEDITED'));
        expect(model.confidenceScore, 0.9750);
      }
    });

    test('CommercialSuggestionModel handles 5 suggestion types with payload',
        () {
      final types = [
        AiSuggestionType.accountSuggestion,
        AiSuggestionType.productMatching,
        AiSuggestionType.partyMatching,
        AiSuggestionType.anomalySuggestion,
        AiSuggestionType.forecast,
      ];

      for (final type in types) {
        final json = {
          'id': 'sugg-${type.name}',
          'company_id': 'cmp-001',
          'suggestion_type': type.dbValue,
          'target_entity_type': 'INVOICE_LINE',
          'target_entity_id': 'line-001',
          'suggestion_payload': {'suggested_code': '600.01.001'},
          'explanation_text': 'Matching explanation',
          'confidence_score': 0.92,
          'model_version': 'v2.1',
          'status': 'PENDING_HUMAN_REVIEW',
        };

        final model = CommercialSuggestionModel.fromJson(json);
        expect(model.suggestionType, type);
        expect(model.status, 'PENDING_HUMAN_REVIEW');
        expect(model.confidenceScore, 0.92);
        expect(model.payload['suggested_code'], '600.01.001');
      }
    });

    test(
        'Human-in-the-Loop strictly blocks critical actions without human user id',
        () async {
      final repo = AiIntelligenceRepository.instance;

      // Null or empty user ID MUST be rejected for all 5 critical commercial actions
      final criticalActions = [
        'ACCOUNTING_POST',
        'STOCK_POST',
        'PAYMENT',
        'EXPORT_FINALIZATION',
        'LEGAL_DOCUMENT_FINALIZATION',
      ];

      for (final action in criticalActions) {
        final resultNull = await repo.validateCriticalAction(
          actionType: action,
          humanUserId: null,
        );
        expect(resultNull, isFalse,
            reason: 'Action $action must fail without human user ID');

        final resultEmpty = await repo.validateCriticalAction(
          actionType: action,
          humanUserId: '',
        );
        expect(resultEmpty, isFalse,
            reason: 'Action $action must fail with empty human user ID');
      }
    });

    test('AiAuditLogModel tracks complete traceability information', () {
      final json = {
        'id': 'audit-001',
        'company_id': 'cmp-001',
        'action_type': 'OCR_EXTRACTION',
        'model_name': 'nakhl-ocr-engine',
        'model_version': 'v2.4',
        'input_reference': 'doc_file_001.pdf',
        'output_summary': 'Extracted invoice header and lines',
        'confidence_score': 0.9850,
        'approving_user_id': 'usr-human-01',
        'created_at': '2026-09-01T12:00:00.000Z',
      };

      final audit = AiAuditLogModel.fromJson(json);
      expect(audit.actionType, 'OCR_EXTRACTION');
      expect(audit.modelName, 'nakhl-ocr-engine');
      expect(audit.modelVersion, 'v2.4');
      expect(audit.confidenceScore, 0.9850);
      expect(audit.approvingUserId, 'usr-human-01');
      expect(audit.inputReference, 'doc_file_001.pdf');
    });
  });
}
