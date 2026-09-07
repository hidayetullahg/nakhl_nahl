# NAKHL&NAHL ZATCA Integration (Saudi Arabia Phase 2)

## 1. Overview
NAKHL&NAHL includes native, end-to-end support for Saudi Arabia Zakat, Tax and Customs Authority (ZATCA) Phase 2 integration (Fatoora).

## 2. Features Implemented
- **UBL 2.1 XML Generation:** Generates valid UBL 2.1 invoices including mandatory ZATCA extensions (UUID, Invoice Counter, Previous Invoice Hash, Cryptographic Stamp).
- **TLV Base64 QR Code:** Encodes Tag-Length-Value QR data (Seller Name, VAT Number, Timestamp, Total with VAT, VAT Total, XML Hash, ECDSA Signature, Public Key).
- **Clearance vs Reporting:**
  - Standard Tax Invoices (B2B): Real-time Clearance API.
  - Simplified Tax Invoices (B2C): 24-hour Reporting API with TLV QR printed on POS receipts.
- **Onboarding Flow:** CSID generation (Compliance CSID & Production CSID) using OTP.
- **Environments Supported:** Sandbox, Simulation, and Production.

## 3. Production Verification Requirement
Per Saudi ZATCA regulations, moving to Production requires active merchant onboarding and issuance of a cryptographic stamp identifier (CSID). Until a live merchant CSID is provisioned, ZATCA Phase 2 operates under Sandbox/Simulation validation modes (`CONDITIONAL` production gate status).
