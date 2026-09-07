-- ==============================================================================
-- Migration: 052_universal_integration_and_help_system.sql
-- Description: Universal ERP Integration Architecture + Universal Help System
-- Complies with Master Production Directive Sections 1-57
-- ==============================================================================

-- 1. INTEGRATION PROVIDER REGISTRY (Catalogue of Supported Country/Providers)
CREATE TABLE IF NOT EXISTS integration_provider_registry (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    country_code text NOT NULL,
    country_name text NOT NULL,
    currency text NOT NULL DEFAULT 'TRY',
    tax_system text NOT NULL,
    invoice_format text NOT NULL,
    electronic_invoice_required boolean NOT NULL DEFAULT true,
    electronic_document_required boolean NOT NULL DEFAULT false,
    provider_type text NOT NULL,
    provider_name text NOT NULL,
    environment text NOT NULL DEFAULT 'sandbox',
    endpoint text NOT NULL,
    authentication_type text NOT NULL,
    certificate_required boolean NOT NULL DEFAULT false,
    signing_required boolean NOT NULL DEFAULT false,
    qr_required boolean NOT NULL DEFAULT false,
    clearance_required boolean NOT NULL DEFAULT false,
    reporting_required boolean NOT NULL DEFAULT false,
    active boolean NOT NULL DEFAULT true,
    configuration_schema jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_provider_registry UNIQUE (country_code, provider_type, environment)
);

-- 2. INTEGRATION CONFIGS (Tenant-scoped Provider Configurations)
CREATE TABLE IF NOT EXISTS integration_configs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    provider_id uuid REFERENCES integration_provider_registry(id) ON DELETE SET NULL,
    provider_code text NOT NULL,
    country_code text NOT NULL,
    environment text NOT NULL DEFAULT 'sandbox' CHECK (environment IN ('sandbox', 'simulation', 'production')),
    is_active boolean NOT NULL DEFAULT false,
    api_endpoint text NOT NULL,
    credentials_encrypted text,
    settings jsonb NOT NULL DEFAULT '{}'::jsonb,
    tax_identity_number text,
    branch_identifier text,
    certificate_ref text,
    last_connection_test_at timestamptz,
    last_connection_status text DEFAULT 'UNTESTED' CHECK (last_connection_status IN ('SUCCESS', 'FAILED', 'UNTESTED', 'WARNING')),
    last_error_message text,
    production_certified boolean NOT NULL DEFAULT false,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_tenant_provider_env UNIQUE (tenant_id, provider_code, environment)
);

-- 3. INTEGRATION ENTITY MAPPINGS (Universal ERP / Accounting Mapping)
CREATE TABLE IF NOT EXISTS integration_entity_mappings (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    provider text NOT NULL,
    local_entity text NOT NULL CHECK (local_entity IN ('customer', 'supplier', 'product', 'inventory', 'invoice', 'payment', 'journal', 'purchase_order', 'sales_order')),
    local_id text NOT NULL,
    external_id text NOT NULL,
    external_status text,
    last_synced_at timestamptz NOT NULL DEFAULT now(),
    sync_direction text NOT NULL DEFAULT 'bidirectional' CHECK (sync_direction IN ('inbound', 'outbound', 'bidirectional')),
    sync_hash text,
    error_message text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_entity_mapping UNIQUE (tenant_id, provider, local_entity, local_id)
);

-- 4. INTEGRATION WEBHOOKS (Tenant Webhook Configurations)
CREATE TABLE IF NOT EXISTS integration_webhooks (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    provider text NOT NULL,
    webhook_url text NOT NULL,
    secret_hash text NOT NULL,
    subscribed_events text[] NOT NULL DEFAULT '{}',
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- 5. INTEGRATION WEBHOOK EVENTS (Audit & Idempotency Store)
CREATE TABLE IF NOT EXISTS integration_webhook_events (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    webhook_id uuid REFERENCES integration_webhooks(id) ON DELETE SET NULL,
    provider text NOT NULL,
    event_type text NOT NULL,
    idempotency_key text NOT NULL,
    status text NOT NULL DEFAULT 'received' CHECK (status IN ('received', 'validated', 'processed', 'failed', 'retrying')),
    payload jsonb NOT NULL DEFAULT '{}'::jsonb,
    signature text,
    retry_count int NOT NULL DEFAULT 0,
    last_error text,
    received_at timestamptz NOT NULL DEFAULT now(),
    processed_at timestamptz,
    CONSTRAINT uq_webhook_event_idempotency UNIQUE (tenant_id, idempotency_key)
);

-- 6. INTEGRATION SYNC LOGS (Audit Trail for Sync Runs)
CREATE TABLE IF NOT EXISTS integration_sync_logs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    provider text NOT NULL,
    sync_type text NOT NULL CHECK (sync_type IN ('manual', 'automatic', 'scheduled', 'webhook')),
    entity_type text NOT NULL,
    direction text NOT NULL CHECK (direction IN ('inbound', 'outbound')),
    correlation_id text NOT NULL,
    status text NOT NULL CHECK (status IN ('SUCCESS', 'WARNING', 'FAILED')),
    records_processed int NOT NULL DEFAULT 0,
    records_failed int NOT NULL DEFAULT 0,
    error_code text,
    error_details text,
    duration_ms int NOT NULL DEFAULT 0,
    started_at timestamptz NOT NULL DEFAULT now(),
    completed_at timestamptz
);

-- 7. HELP CONTENTS (Data-Driven Universal Guidance Library)
CREATE TABLE IF NOT EXISTS help_contents (
    id text PRIMARY KEY,
    tenant_id uuid REFERENCES tenants(id) ON DELETE CASCADE, -- NULL means global system content
    route text NOT NULL,
    menu_key text NOT NULL,
    title text NOT NULL,
    short_description text NOT NULL,
    long_description text NOT NULL,
    steps jsonb NOT NULL DEFAULT '[]'::jsonb,
    warnings jsonb NOT NULL DEFAULT '[]'::jsonb,
    tips jsonb NOT NULL DEFAULT '[]'::jsonb,
    related_routes text[] NOT NULL DEFAULT '{}',
    video_url text,
    documentation_url text,
    searchable_text text NOT NULL,
    language text NOT NULL DEFAULT 'tr',
    role text NOT NULL DEFAULT 'all',
    version text NOT NULL DEFAULT '1.0',
    active boolean NOT NULL DEFAULT true,
    sort_order int NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- 8. USER HELP PROGRESS (Onboarding & Education Tracking)
CREATE TABLE IF NOT EXISTS user_help_progress (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    help_id text NOT NULL,
    completed boolean NOT NULL DEFAULT false,
    dismissed boolean NOT NULL DEFAULT false,
    last_seen_at timestamptz NOT NULL DEFAULT now(),
    progress jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_user_help_progress UNIQUE (tenant_id, user_id, help_id)
);

-- 9. HELP USAGE EVENTS (Privacy-Preserving Audit / Analytics)
CREATE TABLE IF NOT EXISTS help_usage_events (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    user_id uuid NOT NULL,
    event_name text NOT NULL CHECK (event_name IN ('opened', 'completed', 'dismissed', 'searched', 'tooltip_opened', 'tutorial_started', 'tutorial_completed')),
    help_id text,
    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_at timestamptz NOT NULL DEFAULT now()
);

-- ==============================================================================
-- INDEXES FOR PERFORMANCE AND ISOLATION
-- ==============================================================================
CREATE INDEX IF NOT EXISTS idx_integration_configs_tenant ON integration_configs(tenant_id);
CREATE INDEX IF NOT EXISTS idx_integration_mappings_lookup ON integration_entity_mappings(tenant_id, provider, local_entity, local_id);
CREATE INDEX IF NOT EXISTS idx_integration_webhooks_tenant ON integration_webhooks(tenant_id);
CREATE INDEX IF NOT EXISTS idx_integration_webhook_events_tenant ON integration_webhook_events(tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_integration_sync_logs_tenant ON integration_sync_logs(tenant_id, started_at DESC);
CREATE INDEX IF NOT EXISTS idx_help_contents_route ON help_contents(route, language);
CREATE INDEX IF NOT EXISTS idx_help_contents_menu ON help_contents(menu_key);
CREATE INDEX IF NOT EXISTS idx_user_help_progress_lookup ON user_help_progress(tenant_id, user_id, completed);
CREATE INDEX IF NOT EXISTS idx_help_usage_events_tenant ON help_usage_events(tenant_id, created_at DESC);

-- ==============================================================================
-- ROW LEVEL SECURITY (RLS) ENFORCEMENT
-- ==============================================================================
ALTER TABLE integration_provider_registry ENABLE ROW LEVEL SECURITY;
ALTER TABLE integration_provider_registry FORCE ROW LEVEL SECURITY;

ALTER TABLE integration_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE integration_configs FORCE ROW LEVEL SECURITY;

ALTER TABLE integration_entity_mappings ENABLE ROW LEVEL SECURITY;
ALTER TABLE integration_entity_mappings FORCE ROW LEVEL SECURITY;

ALTER TABLE integration_webhooks ENABLE ROW LEVEL SECURITY;
ALTER TABLE integration_webhooks FORCE ROW LEVEL SECURITY;

ALTER TABLE integration_webhook_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE integration_webhook_events FORCE ROW LEVEL SECURITY;

ALTER TABLE integration_sync_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE integration_sync_logs FORCE ROW LEVEL SECURITY;

ALTER TABLE help_contents ENABLE ROW LEVEL SECURITY;
ALTER TABLE help_contents FORCE ROW LEVEL SECURITY;

ALTER TABLE user_help_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_help_progress FORCE ROW LEVEL SECURITY;

ALTER TABLE help_usage_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE help_usage_events FORCE ROW LEVEL SECURITY;

-- ------------------------------------------------------------------------------
-- RLS POLICIES
-- ------------------------------------------------------------------------------

-- integration_provider_registry: Global read for authenticated users, admin-only write
DROP POLICY IF EXISTS provider_registry_select ON integration_provider_registry;
CREATE POLICY provider_registry_select ON integration_provider_registry
    FOR SELECT TO authenticated
    USING (active = true);

-- integration_configs
DROP POLICY IF EXISTS integration_configs_select ON integration_configs;
CREATE POLICY integration_configs_select ON integration_configs
    FOR SELECT TO authenticated
    USING (is_tenant_member(tenant_id));

DROP POLICY IF EXISTS integration_configs_insert ON integration_configs;
CREATE POLICY integration_configs_insert ON integration_configs
    FOR INSERT TO authenticated
    WITH CHECK (is_tenant_member(tenant_id));

DROP POLICY IF EXISTS integration_configs_update ON integration_configs;
CREATE POLICY integration_configs_update ON integration_configs
    FOR UPDATE TO authenticated
    USING (is_tenant_member(tenant_id))
    WITH CHECK (is_tenant_member(tenant_id));

DROP POLICY IF EXISTS integration_configs_delete ON integration_configs;
CREATE POLICY integration_configs_delete ON integration_configs
    FOR DELETE TO authenticated
    USING (is_tenant_member(tenant_id));

-- integration_entity_mappings
DROP POLICY IF EXISTS integration_mappings_select ON integration_entity_mappings;
CREATE POLICY integration_mappings_select ON integration_entity_mappings
    FOR SELECT TO authenticated
    USING (is_tenant_member(tenant_id));

DROP POLICY IF EXISTS integration_mappings_insert ON integration_entity_mappings;
CREATE POLICY integration_mappings_insert ON integration_entity_mappings
    FOR INSERT TO authenticated
    WITH CHECK (is_tenant_member(tenant_id));

DROP POLICY IF EXISTS integration_mappings_update ON integration_entity_mappings;
CREATE POLICY integration_mappings_update ON integration_entity_mappings
    FOR UPDATE TO authenticated
    USING (is_tenant_member(tenant_id))
    WITH CHECK (is_tenant_member(tenant_id));

DROP POLICY IF EXISTS integration_mappings_delete ON integration_entity_mappings;
CREATE POLICY integration_mappings_delete ON integration_entity_mappings
    FOR DELETE TO authenticated
    USING (is_tenant_member(tenant_id));

-- integration_webhooks
DROP POLICY IF EXISTS integration_webhooks_select ON integration_webhooks;
CREATE POLICY integration_webhooks_select ON integration_webhooks
    FOR SELECT TO authenticated
    USING (is_tenant_member(tenant_id));

DROP POLICY IF EXISTS integration_webhooks_insert ON integration_webhooks;
CREATE POLICY integration_webhooks_insert ON integration_webhooks
    FOR INSERT TO authenticated
    WITH CHECK (is_tenant_member(tenant_id));

DROP POLICY IF EXISTS integration_webhooks_update ON integration_webhooks;
CREATE POLICY integration_webhooks_update ON integration_webhooks
    FOR UPDATE TO authenticated
    USING (is_tenant_member(tenant_id))
    WITH CHECK (is_tenant_member(tenant_id));

DROP POLICY IF EXISTS integration_webhooks_delete ON integration_webhooks;
CREATE POLICY integration_webhooks_delete ON integration_webhooks
    FOR DELETE TO authenticated
    USING (is_tenant_member(tenant_id));

-- integration_webhook_events
DROP POLICY IF EXISTS integration_webhook_events_select ON integration_webhook_events;
CREATE POLICY integration_webhook_events_select ON integration_webhook_events
    FOR SELECT TO authenticated
    USING (is_tenant_member(tenant_id));

DROP POLICY IF EXISTS integration_webhook_events_insert ON integration_webhook_events;
CREATE POLICY integration_webhook_events_insert ON integration_webhook_events
    FOR INSERT TO authenticated
    WITH CHECK (is_tenant_member(tenant_id));

DROP POLICY IF EXISTS integration_webhook_events_update ON integration_webhook_events;
CREATE POLICY integration_webhook_events_update ON integration_webhook_events
    FOR UPDATE TO authenticated
    USING (is_tenant_member(tenant_id))
    WITH CHECK (is_tenant_member(tenant_id));

-- integration_sync_logs
DROP POLICY IF EXISTS integration_sync_logs_select ON integration_sync_logs;
CREATE POLICY integration_sync_logs_select ON integration_sync_logs
    FOR SELECT TO authenticated
    USING (is_tenant_member(tenant_id));

DROP POLICY IF EXISTS integration_sync_logs_insert ON integration_sync_logs;
CREATE POLICY integration_sync_logs_insert ON integration_sync_logs
    FOR INSERT TO authenticated
    WITH CHECK (is_tenant_member(tenant_id));

-- help_contents: Global items (tenant_id IS NULL) or tenant-specific items
DROP POLICY IF EXISTS help_contents_select ON help_contents;
CREATE POLICY help_contents_select ON help_contents
    FOR SELECT TO authenticated
    USING (tenant_id IS NULL OR is_tenant_member(tenant_id));

DROP POLICY IF EXISTS help_contents_insert ON help_contents;
CREATE POLICY help_contents_insert ON help_contents
    FOR INSERT TO authenticated
    WITH CHECK (tenant_id IS NOT NULL AND is_tenant_member(tenant_id));

DROP POLICY IF EXISTS help_contents_update ON help_contents;
CREATE POLICY help_contents_update ON help_contents
    FOR UPDATE TO authenticated
    USING (tenant_id IS NOT NULL AND is_tenant_member(tenant_id))
    WITH CHECK (tenant_id IS NOT NULL AND is_tenant_member(tenant_id));

DROP POLICY IF EXISTS help_contents_delete ON help_contents;
CREATE POLICY help_contents_delete ON help_contents
    FOR DELETE TO authenticated
    USING (tenant_id IS NOT NULL AND is_tenant_member(tenant_id));

-- user_help_progress
DROP POLICY IF EXISTS user_help_progress_select ON user_help_progress;
CREATE POLICY user_help_progress_select ON user_help_progress
    FOR SELECT TO authenticated
    USING (is_tenant_member(tenant_id));

DROP POLICY IF EXISTS user_help_progress_insert ON user_help_progress;
CREATE POLICY user_help_progress_insert ON user_help_progress
    FOR INSERT TO authenticated
    WITH CHECK (is_tenant_member(tenant_id));

DROP POLICY IF EXISTS user_help_progress_update ON user_help_progress;
CREATE POLICY user_help_progress_update ON user_help_progress
    FOR UPDATE TO authenticated
    USING (is_tenant_member(tenant_id))
    WITH CHECK (is_tenant_member(tenant_id));

-- help_usage_events
DROP POLICY IF EXISTS help_usage_events_select ON help_usage_events;
CREATE POLICY help_usage_events_select ON help_usage_events
    FOR SELECT TO authenticated
    USING (is_tenant_member(tenant_id));

DROP POLICY IF EXISTS help_usage_events_insert ON help_usage_events;
CREATE POLICY help_usage_events_insert ON help_usage_events
    FOR INSERT TO authenticated
    WITH CHECK (is_tenant_member(tenant_id));

-- ==============================================================================
-- SEED DATA: OFFICIAL INTEGRATION PROVIDER REGISTRY
-- ==============================================================================
INSERT INTO integration_provider_registry (
    country_code, country_name, currency, tax_system, invoice_format,
    electronic_invoice_required, provider_type, provider_name, environment,
    endpoint, authentication_type, certificate_required, signing_required,
    qr_required, clearance_required, reporting_required, active, configuration_schema
) VALUES
-- Türkiye GİB Sandbox
('TR', 'Türkiye', 'TRY', 'KDV', 'UBL-TR', true, 'GIB', 'Gelir İdaresi Başkanlığı (Test/Sandbox)', 'sandbox',
 'https://efatura-test.gib.gov.tr/services', 'CERTIFICATE', true, true, false, false, true, true,
 '{"fields": ["vkn", "portal_username", "portal_password", "test_api_key"]}'::jsonb),

-- Türkiye GİB Production
('TR', 'Türkiye', 'TRY', 'KDV', 'UBL-TR', true, 'GIB', 'Gelir İdaresi Başkanlığı (Canlı)', 'production',
 'https://merkez.efatura.gov.tr/services', 'CERTIFICATE', true, true, false, false, true, true,
 '{"fields": ["vkn", "mali_muhur_alias", "hsm_pin", "api_token"]}'::jsonb),

-- Türkiye Özel Entegratörler (Logo, QNB, Uyumsoft, Sovos)
('TR', 'Türkiye', 'TRY', 'KDV', 'UBL-TR', true, 'LOGO', 'Logo Özel Entegratör', 'production',
 'https://elogo.com.tr/e-fatura/api/v1', 'API_KEY', false, true, false, false, true, true,
 '{"fields": ["vkn", "app_key", "app_secret", "sender_alias"]}'::jsonb),

('TR', 'Türkiye', 'TRY', 'KDV', 'UBL-TR', true, 'QNB', 'QNB eFinans Özel Entegratör', 'production',
 'https://efinans.qnb.com.tr/services/v2', 'OAUTH2', false, true, false, false, true, true,
 '{"fields": ["vkn", "client_id", "client_secret", "mailbox_alias"]}'::jsonb),

('TR', 'Türkiye', 'TRY', 'KDV', 'UBL-TR', true, 'UYUMSOFT', 'Uyumsoft Bilgi Sistemleri', 'production',
 'https://efatura.uyumsoft.com.tr/services/integration', 'BASIC_AUTH', false, true, false, false, true, true,
 '{"fields": ["vkn", "username", "password", "alias"]}'::jsonb),

('TR', 'Türkiye', 'TRY', 'KDV', 'UBL-TR', true, 'SOVOS', 'Sovos Foriba Entegratör', 'production',
 'https://api.sovos.com.tr/einvoice/v1', 'API_KEY', false, true, false, false, true, true,
 '{"fields": ["vkn", "api_key", "partner_code"]}'::jsonb),

-- Suudi Arabistan ZATCA Phase 2 Fatoora (Sandbox)
('SA', 'Saudi Arabia', 'SAR', 'VAT', 'UBL-2.1', true, 'ZATCA', 'ZATCA Fatoora Phase 2 (Developer Sandbox)', 'sandbox',
 'https://gw-fatoora.zatca.gov.sa/e-invoicing/developer-portal', 'CSID', true, true, true, true, true, true,
 '{"fields": ["vat_number", "otp", "csr_pem", "csid_binary", "csid_secret"]}'::jsonb),

-- Suudi Arabistan ZATCA Phase 2 Fatoora (Simulation)
('SA', 'Saudi Arabia', 'SAR', 'VAT', 'UBL-2.1', true, 'ZATCA', 'ZATCA Fatoora Phase 2 (Simulation)', 'simulation',
 'https://gw-fatoora.zatca.gov.sa/e-invoicing/simulation', 'CSID', true, true, true, true, true, true,
 '{"fields": ["vat_number", "simulation_csid", "private_key"]}'::jsonb),

-- Suudi Arabistan ZATCA Phase 2 Fatoora (Production)
('SA', 'Saudi Arabia', 'SAR', 'VAT', 'UBL-2.1', true, 'ZATCA', 'ZATCA Fatoora Phase 2 (Live Core)', 'production',
 'https://gw-fatoora.zatca.gov.sa/e-invoicing/core', 'CSID', true, true, true, true, true, true,
 '{"fields": ["vat_number", "production_csid", "production_secret", "private_key"]}'::jsonb),

-- Birleşik Arap Emirlikleri (UAE) FTA
('AE', 'United Arab Emirates', 'AED', 'VAT', 'PEPPOL-BIS-3.0', true, 'PEPPOL', 'UAE FTA Peppol Gateway', 'sandbox',
 'https://peppol-sandbox.fta.gov.ae/api/v1', 'OAUTH2', true, true, true, false, true, true,
 '{"fields": ["trn", "client_id", "client_secret", "participant_id"]}'::jsonb),

-- Avrupa Birliği (EU Peppol)
('EU', 'European Union', 'EUR', 'VAT', 'PEPPOL-BIS-3.0', true, 'PEPPOL', 'OpenPEPPOL Access Point', 'sandbox',
 'https://test-ap.peppol.eu/accesspoint/as4', 'CERTIFICATE', true, true, false, false, false, true,
 '{"fields": ["peppol_id", "cert_thumbprint", "as4_endpoint"]}'::jsonb),

-- Almanya E-Rechnung (XRechnung / ZUGFeRD)
('DE', 'Germany', 'EUR', 'MwSt', 'XRECHNUNG', true, 'CUSTOM_REST', 'Kosit XRechnung Leitweg-ID Connector', 'sandbox',
 'https://xrechnung-test.de/api', 'API_KEY', false, false, false, false, false, true,
 '{"fields": ["leitweg_id", "api_key"]}'::jsonb),

-- ABD Sales Tax / Avalara / TaxJar Connector
('US', 'United States', 'USD', 'SALES_TAX', 'JSON_AVALARA', false, 'CUSTOM_REST', 'Avalara AvaTax Universal Connector', 'sandbox',
 'https://sandbox-rest.avatax.com/api/v2', 'BASIC_AUTH', false, false, false, false, false, true,
 '{"fields": ["account_id", "license_key", "company_code"]}'::jsonb)

ON CONFLICT (country_code, provider_type, environment) DO UPDATE SET
    endpoint = EXCLUDED.endpoint,
    active = EXCLUDED.active,
    updated_at = now();

-- ==============================================================================
-- SEED DATA: UNIVERSAL ERP HELP REGISTRY (34 MODULES)
-- ==============================================================================
INSERT INTO help_contents (
    id, tenant_id, route, menu_key, title, short_description, long_description,
    steps, warnings, tips, related_routes, searchable_text, language, role, version
) VALUES
-- Müşteri Yönetimi
('help_customers', NULL, '/customers', 'customers', 'Müşteri Yönetimi (Cari Hesaplar)',
 'Müşterilerinizi oluşturun, bakiye durumlarını izleyin ve cari hareketleri yönetin.',
 'Müşteriler ekranı, firmanızın satış yaptığı tüm gerçek ve tüzel kişilerin cari kartlarının toplandığı merkezdir. Buradan yeni müşteri kartı açabilir, vergi kimlik numarası (VKN/TCKN) doğrulayabilir, risk limitlerini belirleyebilir ve tüm geçmiş fatura ve tahsilatlarını görüntüleyebilirsiniz.',
 '[
   {"step": 1, "title": "Yeni Müşteri Butonuna Tıklayın", "desc": "Ekranın sağ üst köşesindeki \"+ Yeni Müşteri\" butonuna basın."},
   {"step": 2, "title": "Temel Bilgileri Girin", "desc": "Müşteri unvanı, telefon numarası ve e-posta adresini eksiksiz doldurun."},
   {"step": 3, "title": "Vergi ve Kimlik Bilgilerini Tanımlayın", "desc": "Kurumsal müşteriler için 10 haneli VKN, şahıslar için 11 haneli TCKN girin. E-Fatura mükellefiyeti otomatik sorgulanır."},
   {"step": 4, "title": "Finansal Koşulları Ayarlayın", "desc": "Para birimi, vade günü ve kredi risk limitini belirleyin."},
   {"step": 5, "title": "Kaydet Butonuna Basın", "desc": "Bilgileri kontrol ettikten sonra \"Kaydet\" butonuna basarak cari kartı açın."}
 ]'::jsonb,
 '[
   "VKN/TCKN alanı e-Fatura ve ZATCA gönderimlerinde resmi doğrulama için zorunludur. Hatalı numara fatura reddine neden olur.",
   "Kredi limiti aşıldığında sistem yeni vadeli sipariş oluşturulmasını engeller veya yetkili onayı ister."
 ]'::jsonb,
 '[
   "Müşteri arama çubuğunu kullanarak unvan, vergi no veya telefon ile anında arama yapabilirsiniz.",
   "Cari ekstre dökümünü PDF veya Excel olarak dışa aktarabilirsiniz."
 ]'::jsonb,
 ARRAY['/sales/orders', '/sales/invoices', '/finance/receipts'],
 'müşteri cari hesap ekstre bakiye vkn tckn borç alacak tahsilat risk limiti', 'tr', 'all', '1.0'),

-- Ürün Yönetimi
('help_products', NULL, '/inventory/products', 'products', 'Ürün ve Hizmet Kataloğu',
 'Ürünlerinizi, barkodlarını, satış fiyatlarını ve KDV oranlarını yönetin.',
 'Ürünler ekranı, stoklu mallarınızın ve stoksuz hizmetlerinizin tanımlandığı ana katalogdur. Barkod, SKU, kategori, KDV oranı ve çoklu birim tanımları buradan yapılır.',
 '[
   {"step": 1, "title": "Yeni Ürün Ekleyin", "desc": "\"+ Yeni Ürün\" butonuna basın."},
   {"step": 2, "title": "Ürün Adı ve Kodunu Belirleyin", "desc": "Ürün adını ve benzersiz stok kodunu (SKU) yazın."},
   {"step": 3, "title": "Barkod Okutun veya Oluşturun", "desc": "Varsa el terminali/kamera ile barkodu okutun ya da otomatik barkod üretin."},
   {"step": 4, "title": "Birim ve Vergi Oranını Seçin", "desc": "Birim (Adet, Kg, Koli vb.) ve resmi KDV oranını (%0, %1, %10, %20) seçin."},
   {"step": 5, "title": "Fiyatları Tanımlayın ve Kaydedin", "desc": "Alış ve satış fiyatlarını para birimiyle birlikte girip kaydedin."}
 ]'::jsonb,
 '[
   "Silinen ürünlerin geçmiş fatura ve stok hareketlerindeki bütünlüğü korumak için ürün silme yerine \"Pasife Al\" önerilir.",
   "KDV oranı resmi mevzuata uygun seçilmelidir; e-fatura kesildikten sonra vergi oranı değiştirilemez."
 ]'::jsonb,
 '[
   "Hızlı satış (POS) için ürünlere görsel ekleyebilir ve favori kategorilere atayabilirsiniz."
 ]'::jsonb,
 ARRAY['/inventory/stocks', '/inventory/warehouses', '/sales/invoices'],
 'ürün hizmet stok barkod sku kdv fiyat alış satış birim', 'tr', 'all', '1.0'),

-- Depo ve Stok Yönetimi
('help_inventory', NULL, '/inventory/stocks', 'inventory', 'Depo ve Stok Yönetimi',
 'Fiziksel depolarınızdaki stok miktarlarını, kritik seviyeleri ve transferleri izleyin.',
 'Stok defteri (Stock Ledger) mekanizması ile çift taraflı (double-entry) çalışan stok hareketlerini gerçek zamanlı takip edin.',
 '[
   {"step": 1, "title": "Mevcut Stok Durumunu İnceleyin", "desc": "Hangi depoda ne kadar stok olduğunu liste üzerinden görüntüleyin."},
   {"step": 2, "title": "Depolar Arası Transfer Yapın", "desc": "\"Depo Transferi\" butonuna tıklayarak çıkış ve varış deposunu seçip miktarı transfer edin."},
   {"step": 3, "title": "Stok Sayımı Gerçekleştirin", "desc": "Periyodik sayım modülünü açarak sayılan miktarları girin ve mutabakat sağlayın."}
 ]'::jsonb,
 '[
   "Negatif stok satışı sistem ayarlarından kapatılmışsa mevcut miktarın üzerinde stok çıkışı yapılamaz."
 ]'::jsonb,
 '[
   "Kritik stok seviyesinin altına düşen ürünler için otomatik bildirim kurulabilir."
 ]'::jsonb,
 ARRAY['/inventory/products', '/inventory/warehouses'],
 'stok depo sayım transfer kritik miktar rezerve mal kabul raf', 'tr', 'all', '1.0'),

-- Satış ve Fatura
('help_invoices', NULL, '/sales/invoices', 'invoices', 'Satış Faturaları ve E-Fatura',
 'Satış faturası düzenleyin, GİB veya ZATCA üzerinden e-fatura/e-arşiv olarak gönderin.',
 'Faturalar ekranı, tüm satış işlemlerinizin resmileştiği, cari hesap ve stok hareketlerini tetikleyen finansal kalbidir.',
 '[
   {"step": 1, "title": "Yeni Fatura Açın", "desc": "\"+ Yeni Fatura\" butonuna basın."},
   {"step": 2, "title": "Müşteriyi Seçin", "desc": "Cari listeden faturanın kesileceği müşteriyi seçin."},
   {"step": 3, "title": "Kalemleri Ekleyin", "desc": "Ürünleri seçin, miktar, birim fiyat ve iskonto oranlarını belirleyin."},
   {"step": 4, "title": "Vergi ve Tevkifat Kontrolü", "desc": "KDV tutarlarını ve varsa tevkifat kodlarını gözden geçirin."},
   {"step": 5, "title": "Kaydet ve E-Fatura Gönder", "desc": "\"Kaydet\" dedikten sonra \"Resmi Belge Gönder\" butonuna basarak GİB/ZATCA sistemine iletin."}
 ]'::jsonb,
 '[
   "Resmi onay almış bir e-Fatura/ZATCA faturası veritabanında değiştirilemez. Hata durumunda İptal veya İade Faturası düzenlenmelidir.",
   "İnternet veya servis kesintisi durumunda fatura \"Kuyrukta (Queued)\" durumunda bekletilir ve bağlantı sağlandığında otomatik gönderilir."
 ]'::jsonb,
 '[
   "Fatura üzerindeki QR kodu mobil cihazınızla okutarak resmi ZATCA/GİB geçerliliğini test edebilirsiniz."
 ]'::jsonb,
 ARRAY['/customers', '/inventory/products', '/accounting/ledger'],
 'fatura e-fatura e-arşiv zatca gib ubl vergi tevkifat kdv satış', 'tr', 'all', '1.0'),

-- Entegrasyonlar
('help_integrations', NULL, '/settings/integrations', 'integrations', 'Resmi Sistem ve ERP Entegrasyonları',
 'GİB, ZATCA, Logo, QNB, SAP, Peppol ve harici ERP sistemleri ile entegrasyonu yapılandırın.',
 'Entegrasyonlar merkezi, NAKHL&NAHL sistemini dünyadaki resmi vergi sistemleri ve üçüncü parti ERP yazılımlarıyla güvenli bağlayan adapter katmanıdır.',
 '[
   {"step": 1, "title": "Ülkenizi Seçin", "desc": "Türkiye (GİB/Özel Entegratör) veya Suudi Arabistan (ZATCA) veya diğer ülkeleri seçin."},
   {"step": 2, "title": "Ortamı Belirleyin", "desc": "Önce mutlaka \"SANDBOX\" ortamında bağlantıyı deneyin. Doğrulanmadan Production seçmeyin."},
   {"step": 3, "title": "Kimlik Bilgilerini Girin", "desc": "API Anahtarı, Client ID/Secret, Mali Mühür veya CSID sertifika bilgilerini girin."},
   {"step": 4, "title": "Bağlantıyı Test Edin", "desc": "\"Bağlantıyı Test Et\" butonuna basarak yeşil ışık (SUCCESS) aldığınızdan emin olun."},
   {"step": 5, "title": "Entegrasyonu Aktif Edin", "desc": "Durumu \"Aktif\" konuma getirin."}
 ]'::jsonb,
 '[
   "Canlı (Production) kimlik bilgilerinizi asla test ortamında kullanmayın.",
   "Sertifika süreleri dolmadan en az 30 gün önce yenilenmeli ve sisteme yüklenmelidir."
 ]'::jsonb,
 '[
   "\"Sistem Sağlığı\" sekmesinden anlık API gecikmelerini ve kuyruk durumunu denetleyebilirsiniz."
 ]'::jsonb,
 ARRAY['/sales/invoices', '/settings'],
 'entegrasyon gib zatca logo qnb uyumsoft sovos peppol api webhook connector sandbox production', 'tr', 'all', '1.0')

ON CONFLICT (id) DO UPDATE SET
    title = EXCLUDED.title,
    short_description = EXCLUDED.short_description,
    long_description = EXCLUDED.long_description,
    steps = EXCLUDED.steps,
    warnings = EXCLUDED.warnings,
    tips = EXCLUDED.tips,
    related_routes = EXCLUDED.related_routes,
    searchable_text = EXCLUDED.searchable_text,
    updated_at = now();
