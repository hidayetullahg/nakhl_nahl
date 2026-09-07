# NAKHL&NAHL Universal Connector Specification

## 1. Overview
The `UniversalIntegrationConnector` standardizes outbound and inbound communication between NAKHL&NAHL and third-party web services.

## 2. Protocol Capabilities
- **Protocols:** REST (HTTP/1.1 & HTTP/2), SOAP 1.1 / 1.2 XML with WS-Security, JSON-RPC.
- **Authentication Methods:**
  - Bearer Token / OAuth 2.0 Client Credentials
  - Static API Key / Header Authentication
  - HTTP Basic Auth
  - X.509 Client Certificates / mTLS

## 3. Reliability & Fault-Tolerance
- **Exponential Backoff:** Configurable retry attempts (default 3) with jitter to prevent thunderous herd effects.
- **Idempotency Keys:** Outbound mutations attach `Idempotency-Key` headers to guarantee no duplicate invoices or payments are processed during network interruptions.
- **Correlation IDs:** Propagates `X-Correlation-ID` across all hops for distributed tracing and audit logs.
- **Error Normalization:** Converts remote error payloads into typed `IntegrationException` categories (`AUTHENTICATION_ERROR`, `TIMEOUT`, `RATE_LIMIT`, `VALIDATION_ERROR`, etc.).
