# NAKHL&NAHL Integration Administrator Guide

## 1. Overview
The Integration Administration interface (`/integrations/settings` and `/integrations/health`) gives system administrators complete control over outbound fiscal connectors and bidirectional ERP data synchronization.

## 2. Configuration Workflow
1. **Navigate to:** `Ayarlar` → `Entegrasyonlar`
2. **Select Country:** Choose between 🇹🇷 Turkey, 🇸🇦 Saudi Arabia, 🇦🇪 UAE, 🇪🇺 European Union, 🇩🇪 Germany, or 🇺🇸 USA.
3. **Select Integration Provider:** Choose the official or certified regional provider (e.g. GİB, Logo, QNB eFinans, ZATCA Phase 2, Peppol).
4. **Environment Gating:**
   - Always start in `🟡 SANDBOX` mode.
   - Enter API endpoints, Sandbox API Key, and Test VKN/VAT number.
   - Click `[Bağlantıyı Test Et]`.
   - The system initiates an automated connectivity probe, payload validation, and ping test.
5. **Switching to Production:**
   - Production mode (`🔴 PRODUCTION`) strictly requires:
     - Verified merchant Tax ID / VKN.
     - Production CSID cryptographic stamp or official client certificate.
     - Live endpoint authorization token.
     - Successful health-check clearance.

## 3. Integration Health Center (`/integrations/health`)
Monitor real-time connector operational state:
- **Status Indicators:**
  - 🟢 **Connected:** Zero errors in last 24h, ping latency < 500ms.
  - 🟡 **Warning:** Intermittent rate limits or retry backoffs occurring.
  - 🔴 **Error:** Invalid credentials, expired certificate, or endpoint down.
  - ⚪ **Not Configured:** Tenant has not yet provisioned credentials for this provider.
- **Diagnostics & Actions:**
  - `[Şimdi Senkronize Et]`: Triggers an immediate bidirectional sync delta.
  - `[Hataları Yeniden Dene]`: Re-queues failed documents using exponential backoff.
  - `[Logları İncele]`: Shows correlated request/response payloads with masked credentials.
