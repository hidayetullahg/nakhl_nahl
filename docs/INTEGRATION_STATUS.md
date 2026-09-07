# NAKHL & NAHL — Third-Party ERP Integration Status

## 1. Integration Status Matrix

| Integration Domain | Adapter / Service | Environment | Verification Status | Notes |
| :--- | :--- | :---: | :---: | :--- |
| **Türkiye GİB E-Fatura** | `MockSandboxEInvoiceAdapter` | Sandbox | ✅ PASS | Taxpayer validation & UBL TR XML generated. |
| **Türkiye Özel Entegratör** | `LogoAdapter`, `QnbAdapter`, `UyumsoftAdapter`, `SovosAdapter` | Staging / Prod | ⚠️ NOT VERIFIED | Requires live commercial production credentials. |
| **Suudi Arabistan ZATCA** | `ZatcaPhase2Adapter` (Phase 2 Fatoora) | Developer Sandbox | ✅ PASS | TLV Base64 QR code & UBL 2.1 XML verified. |
| **Suudi Arabistan ZATCA Prod** | `ZatcaPhase2Adapter` | Production | ⚠️ NOT VERIFIED | Requires official CSID X.509 Cryptographic Certificate. |
| **Supabase Cloud / Auth** | `SupabaseService` | Local / Staging | ✅ PASS | Clean initialization and session handling. |

---

## 2. Integration Key Security Standard (Section 32)
- All third-party private keys, CSID certificates, and integrator credentials must be stored encrypted server-side (`tenant_integration_keys` table with pgcrypto).
- Integration keys are **never** bundled into the Flutter client binary or exposed over anonymous APIs.
