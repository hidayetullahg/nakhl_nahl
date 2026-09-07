# NAKHL&NAHL Universal E-Invoice Integration (GİB & Regional)

## 1. Overview
The `UniversalEInvoiceAdapter` handles electronic invoice generation, schema validation, submission, status polling, cancellation, and rejection across international tax authorities.

## 2. Supported Standards
- **Turkey (GİB):** UBL-TR 1.2 XML with XAdES digital signatures. Supports e-Fatura, e-Arşiv, e-İrsaliye, and private integrators (Logo, QNB eFinans, Uyumsoft, Sovos).
- **European Union:** Peppol BIS Billing 3.0 / EN16931 UBL format.
- **Germany:** XRechnung / ZUGFeRD hybrid formats.

## 3. Workflow & Processing Sequence
1. **Model Normalization:** ERP Invoice entities are mapped into standard `InvoiceExportModel`.
2. **XML Generation:** `generateDocumentXml()` generates compliant UBL 2.1 / UBL-TR documents including currency codes, tax exemptions, and line item tax breakdowns.
3. **Tax ID Validation:** Validates format (10-digit VKN for Turkish legal entities, 11-digit TCKN for individuals, or EU VAT number).
4. **Adapter Dispatch:** Dispatches to the active provider configured in `integration_configs`.
5. **Idempotent Submission:** Uses invoice UUID as `Idempotency-Key` to prevent duplicate billing.
