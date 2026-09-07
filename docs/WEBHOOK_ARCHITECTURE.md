# NAKHL&NAHL Webhook Architecture & Ingestion

## 1. Overview
NAKHL&NAHL implements an asynchronous, tamper-proof webhook ingestion pipeline for external ERP, bank, e-invoice, and logistics status updates.

## 2. Security Guarantees
- **HMAC-SHA256 Signatures:** Every incoming webhook is authenticated via cryptographic signature verification (`X-Signature` header). Requests with invalid signatures are rejected immediately.
- **Replay Attack Protection:** Webhooks must include timestamp headers (`X-Timestamp`). Ingestion enforces a 300-second (5 minute) maximum drift tolerance.
- **Database Idempotency:** Unique constraints on `(tenant_id, webhook_id, event_id)` guarantee that duplicate delivery from external services is rejected at the database level.
- **Audit Trails:** All webhook deliveries and payload outcomes are recorded in `integration_webhook_events` under full tenant Row-Level Security.
