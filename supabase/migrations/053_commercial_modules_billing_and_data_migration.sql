-- ==============================================================================
-- NAKHL & NAHL — MIGRATION 053: COMMERCIAL MODULES, BILLING & DATA MIGRATION
-- Decoupled commercial SaaS engine, 18 billable modules, multi-currency pricing,
-- payment orders (Card & Wire Transfer), and Data Migration staging with RLS.
-- ==============================================================================

-- 1. TİCARİ MODÜL KATALOĞU (18 Resmi Modül)
CREATE TABLE IF NOT EXISTS commercial_modules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    description TEXT,
    dependencies TEXT[] DEFAULT '{}',
    trial_days INT NOT NULL DEFAULT 14,
    grace_period_days INT NOT NULL DEFAULT 7,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'BETA', 'DEPRECATED', 'INACTIVE')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. MODÜL FİYATLANDIRMA LİSTESİ (Çoklu Para Birimi: SAR, TRY, USD, EUR)
CREATE TABLE IF NOT EXISTS commercial_module_pricing (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    module_code VARCHAR(50) NOT NULL REFERENCES commercial_modules(code) ON DELETE CASCADE,
    currency VARCHAR(5) NOT NULL DEFAULT 'SAR',
    monthly_price NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    yearly_price NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    setup_price NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    training_price NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    data_migration_price NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_module_pricing_currency UNIQUE (module_code, currency)
);

-- 3. MÜŞTERİ / TENANT MODÜL ABONELİKLERİ
CREATE TABLE IF NOT EXISTS commercial_tenant_subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    module_code VARCHAR(50) NOT NULL REFERENCES commercial_modules(code) ON DELETE RESTRICT,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' 
        CHECK (status IN ('PENDING', 'TRIAL', 'ACTIVE', 'GRACE', 'EXPIRED', 'SUSPENDED', 'CANCELLED')),
    billing_cycle VARCHAR(20) NOT NULL DEFAULT 'YEARLY' CHECK (billing_cycle IN ('MONTHLY', 'YEARLY', 'LIFETIME', 'CUSTOM')),
    trial_started_at TIMESTAMPTZ,
    trial_expires_at TIMESTAMPTZ,
    purchased_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    activated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL,
    grace_period_until TIMESTAMPTZ NOT NULL,
    auto_renew BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_tenant_module_sub UNIQUE (tenant_id, module_code)
);

-- 4. TİCARİ ÖDEME VE SİPARİŞLER (Kredi Kartı ve Banka Havalesi / Dekont)
CREATE TABLE IF NOT EXISTS commercial_payment_orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    order_number VARCHAR(50) NOT NULL UNIQUE,
    payment_method VARCHAR(30) NOT NULL CHECK (payment_method IN ('CREDIT_CARD', 'BANK_WIRE', 'ADMIN_MANUAL')),
    currency VARCHAR(5) NOT NULL DEFAULT 'SAR',
    total_amount NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    payment_status VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK (payment_status IN ('PENDING', 'PAID', 'REJECTED', 'REFUNDED')),
    bank_account_title VARCHAR(100),
    bank_iban VARCHAR(50),
    bank_transfer_reference VARCHAR(100),
    receipt_document_url TEXT,
    notes TEXT,
    verified_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. ÖDEME SİPARİŞ DETAY SATIRLARI
CREATE TABLE IF NOT EXISTS commercial_payment_order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES commercial_payment_orders(id) ON DELETE CASCADE,
    module_code VARCHAR(50) NOT NULL REFERENCES commercial_modules(code),
    item_type VARCHAR(50) NOT NULL CHECK (item_type IN ('MODULE_LICENSE', 'SETUP_SERVICE', 'DATA_MIGRATION', 'TRAINING_PACKAGE')),
    unit_price NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    quantity INT NOT NULL DEFAULT 1,
    total_price NUMERIC(12,2) NOT NULL DEFAULT 0.00
);

-- 6. VERİ AKTARIMI MASTER İŞLERİ (DATA MIGRATION JOBS)
CREATE TABLE IF NOT EXISTS data_migration_jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    batch_id VARCHAR(50) NOT NULL,
    source_system VARCHAR(50) NOT NULL CHECK (source_system IN ('EXCEL', 'CSV', 'JSON', 'LOGO', 'MIKRO', 'NETSIS', 'PARASUT', 'SAP', 'ODOO', 'OTHER')),
    target_entity VARCHAR(50) NOT NULL CHECK (target_entity IN ('CUSTOMERS', 'SUPPLIERS', 'PRODUCTS', 'INVENTORY', 'OPENING_BALANCES', 'INVOICES')),
    file_name VARCHAR(255) NOT NULL,
    file_checksum VARCHAR(64) NOT NULL,
    total_rows INT NOT NULL DEFAULT 0,
    valid_rows INT NOT NULL DEFAULT 0,
    warning_rows INT NOT NULL DEFAULT 0,
    error_rows INT NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'STAGED' CHECK (status IN ('STAGED', 'VALIDATED', 'IMPORTING', 'COMPLETED', 'ROLLED_BACK', 'FAILED')),
    started_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    executed_at TIMESTAMPTZ,
    rollback_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 7. VERİ AKTARIMI GEÇİCİ STAGING ALANI (IMPORT STAGING BUFFER)
CREATE TABLE IF NOT EXISTS data_migration_staging (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    job_id UUID NOT NULL REFERENCES data_migration_jobs(id) ON DELETE CASCADE,
    row_number INT NOT NULL,
    external_id VARCHAR(100),
    raw_payload JSONB NOT NULL,
    mapped_payload JSONB DEFAULT '{}',
    validation_status VARCHAR(10) NOT NULL DEFAULT 'GREEN' CHECK (validation_status IN ('GREEN', 'YELLOW', 'RED')),
    validation_messages TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 8. VERİ AKTARIMI KOLON EŞLEŞTİRME PROFİLLERİ (SAVED MAPPINGS)
CREATE TABLE IF NOT EXISTS data_migration_mappings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    source_system VARCHAR(50) NOT NULL,
    target_entity VARCHAR(50) NOT NULL,
    mapping_profile_name VARCHAR(100) NOT NULL,
    column_rules JSONB NOT NULL DEFAULT '{}',
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_tenant_migration_profile UNIQUE (tenant_id, source_system, target_entity, mapping_profile_name)
);

-- ==============================================================================
-- 9. SEED 18 COMMERCIAL MODULES
-- ==============================================================================
INSERT INTO commercial_modules (code, name, category, description, dependencies, trial_days, grace_period_days) VALUES
('MOD_CORE', 'Temel Platform & Çekirdek ERP', 'CORE', 'Kullanıcı hesabı, şirket ve şube yönetimi, temel cari, temel kasa ve dashboard.', '{}', 14, 7),
('MOD_ACCOUNTING', 'Finans & Genel Muhasebe', 'FINANCE', 'Kasa, banka, cari hesaplar, yevmiye defteri ve bilanço raporları.', '{MOD_CORE}', 14, 7),
('MOD_INVENTORY', 'Stok & Depo Yönetimi', 'LOGISTICS', 'Depo, raf, lot/seri takibi, stok hareketleri ve mizan kontrolü.', '{MOD_CORE}', 14, 7),
('MOD_SALES', 'Satış & Müşteri Siparişleri', 'COMMERCIAL', 'Teklif, sipariş, irsaliye, faturalandırma ve müşteri risk kontrolü.', '{MOD_CORE}', 14, 7),
('MOD_PURCHASE', 'Satın Alma & Tedarik Zinciri', 'COMMERCIAL', 'Tedarikçi siparişleri, mal kabul, alış faturaları ve ödeme planları.', '{MOD_CORE}', 14, 7),
('MOD_POS', 'Hızlı Kasa & POS Satış', 'RETAIL', 'Barkodlu hızlı satış, dokunmatik kasa arayüzü, vardiya ve gün sonu mutabakatı.', '{MOD_SALES,MOD_INVENTORY}', 14, 7),
('MOD_EINVOICE_TR', 'Türkiye E-Fatura / E-Arşiv / GİB', 'FISCAL', 'GİB entegrasyonu, UBL-TR XML formatlama, e-arşiv portalı ve e-irsaliye.', '{MOD_SALES}', 14, 7),
('MOD_ZATCA_SA', 'Suudi Arabistan ZATCA Phase 2 Fatoora', 'FISCAL', 'UBL 2.1 e-invoicing, cryptographic stamp, TLV Base64 QR code ve clearance.', '{MOD_SALES}', 14, 7),
('MOD_DATA_MIGRATION', 'Kurumsal Veri Aktarımı & Taşıma', 'MIGRATION', 'Logo, Mikro, Netsis, Excel ve CSV eski ERP verilerini temizleyerek içeri aktarma.', '{MOD_CORE}', 0, 0),
('MOD_INITIAL_SETUP', 'İlk Kurulum & Veri Giriş Hizmeti', 'SERVICE', 'Uzman ekip desteğiyle sıfırdan şirket ve açılış bakiyesi kurulumu.', '{MOD_CORE}', 0, 0),
('MOD_TRAINING', 'Kapsamlı ERP & Muhasebe Eğitimi', 'EDUCATION', 'Adım adım etkileşimli eğitim modülleri, sınavlar ve tamamlama sertifikası.', '{MOD_CORE}', 14, 7),
('MOD_REPORTING_ADV', 'Gelişmiş Raporlama & BI Analitik', 'ANALYTICS', 'Grafiksel finansal dashboardlar, kârlılık matrisleri ve nakit akış tahminleri.', '{MOD_ACCOUNTING}', 14, 7),
('MOD_AI_OCR', 'Yapay Zekâ & Akıllı Belge OCR', 'AI', 'Fatura ve fişlerin OCR ile taranarak otomatik cari kaydına dönüştürülmesi.', '{MOD_CORE}', 7, 3),
('MOD_LOGISTICS_EXPORT', 'Uluslararası Ticaret & İhracat Lojistiği', 'GLOBAL', 'Konteyner sevkiyatları, gümrük beyannameleri, konşimento ve navlun takibi.', '{MOD_SALES,MOD_INVENTORY}', 14, 7),
('MOD_AGRICULTURE', 'Tarım & Hurma Bahçesi Yönetimi', 'SPECIAL', 'Ağaç envanteri, hasat rekolte takibi, tasnif, paketleme ve kantar entegrasyonu.', '{MOD_INVENTORY}', 14, 7),
('MOD_DOC_MANAGEMENT', 'Doküman Yönetimi & Arşivleme', 'STORAGE', 'Sözleşmeler, dekontlar, gümrük belgeleri ve WORM SHA256 dijital kasa.', '{MOD_CORE}', 14, 7),
('MOD_INTERCOMPANY', 'Grup Şirketleri & Intercompany Konsolidasyon', 'ENTERPRISE', 'Şirketler arası otomatik çift yönlü virman ve konsolide grup mizanı.', '{MOD_ACCOUNTING}', 14, 7),
('MOD_API_INTEGRATION', 'Açık API & Webhook Entegrasyon Portalı', 'DEVELOPER', 'Harici e-ticaret siteleri, mobil uygulamalar ve ERP sistemleri için güvenli REST API.', '{MOD_CORE}', 14, 7)
ON CONFLICT (code) DO UPDATE SET
    name = EXCLUDED.name,
    category = EXCLUDED.category,
    description = EXCLUDED.description,
    dependencies = EXCLUDED.dependencies;

-- ==============================================================================
-- 10. SEED MULTI-CURRENCY PRICING (SAR, TRY, USD)
-- ==============================================================================
INSERT INTO commercial_module_pricing (module_code, currency, monthly_price, yearly_price, setup_price, training_price, data_migration_price) VALUES
-- Suudi Arabistan (SAR)
('MOD_CORE', 'SAR', 0.00, 0.00, 200.00, 300.00, 500.00),
('MOD_ACCOUNTING', 'SAR', 150.00, 1500.00, 300.00, 400.00, 600.00),
('MOD_INVENTORY', 'SAR', 120.00, 1200.00, 250.00, 350.00, 500.00),
('MOD_SALES', 'SAR', 100.00, 1000.00, 200.00, 250.00, 400.00),
('MOD_PURCHASE', 'SAR', 100.00, 1000.00, 200.00, 250.00, 400.00),
('MOD_POS', 'SAR', 80.00, 800.00, 150.00, 200.00, 300.00),
('MOD_EINVOICE_TR', 'SAR', 150.00, 1500.00, 400.00, 300.00, 500.00),
('MOD_ZATCA_SA', 'SAR', 200.00, 2000.00, 500.00, 400.00, 700.00),
('MOD_DATA_MIGRATION', 'SAR', 0.00, 0.00, 0.00, 0.00, 1200.00),
('MOD_INITIAL_SETUP', 'SAR', 0.00, 0.00, 1500.00, 0.00, 0.00),
('MOD_TRAINING', 'SAR', 0.00, 0.00, 0.00, 800.00, 0.00),

-- Türkiye (TRY)
('MOD_CORE', 'TRY', 0.00, 0.00, 1500.00, 2000.00, 3000.00),
('MOD_ACCOUNTING', 'TRY', 750.00, 7500.00, 2000.00, 2500.00, 3500.00),
('MOD_INVENTORY', 'TRY', 600.00, 6000.00, 1800.00, 2000.00, 3000.00),
('MOD_SALES', 'TRY', 500.00, 5000.00, 1500.00, 1800.00, 2500.00),
('MOD_PURCHASE', 'TRY', 500.00, 5000.00, 1500.00, 1800.00, 2500.00),
('MOD_POS', 'TRY', 400.00, 4000.00, 1200.00, 1500.00, 2000.00),
('MOD_EINVOICE_TR', 'TRY', 800.00, 8000.00, 2500.00, 2000.00, 3500.00),
('MOD_ZATCA_SA', 'TRY', 1200.00, 12000.00, 3000.00, 2500.00, 4500.00),
('MOD_DATA_MIGRATION', 'TRY', 0.00, 0.00, 0.00, 0.00, 6000.00),
('MOD_INITIAL_SETUP', 'TRY', 0.00, 0.00, 8000.00, 0.00, 0.00),
('MOD_TRAINING', 'TRY', 0.00, 0.00, 0.00, 4000.00, 0.00)
ON CONFLICT (module_code, currency) DO UPDATE SET
    monthly_price = EXCLUDED.monthly_price,
    yearly_price = EXCLUDED.yearly_price,
    setup_price = EXCLUDED.setup_price,
    data_migration_price = EXCLUDED.data_migration_price;

-- ==============================================================================
-- 11. SECURITY HELPER FUNCTION: has_active_module
-- Backend-enforced entitlement check
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.has_active_module(p_tenant_id UUID, p_module_code VARCHAR)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_status VARCHAR;
    v_expires_at TIMESTAMPTZ;
    v_grace TIMESTAMPTZ;
BEGIN
    -- Core modül her zaman aktiftir
    IF p_module_code = 'MOD_CORE' THEN
        RETURN TRUE;
    END IF;

    SELECT status, expires_at, grace_period_until
    INTO v_status, v_expires_at, v_grace
    FROM commercial_tenant_subscriptions
    WHERE tenant_id = p_tenant_id AND module_code = p_module_code;

    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    -- Aktif veya Deneme durumunda süre dolmamış olmalı
    IF v_status IN ('ACTIVE', 'TRIAL') AND NOW() <= v_expires_at THEN
        RETURN TRUE;
    END IF;

    -- Grace period içindeyse modül hala çalışır (uyarı ile)
    IF v_status = 'GRACE' AND NOW() <= v_grace THEN
        RETURN TRUE;
    END IF;

    RETURN FALSE;
END;
$$;

-- ==============================================================================
-- 12. ROW LEVEL SECURITY (RLS) POLICIES FOR COMMERCIAL & MIGRATION TABLES
-- ==============================================================================

-- 12.1 commercial_modules & commercial_module_pricing (Global Read)
ALTER TABLE commercial_modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE commercial_modules FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "commercial_modules_read" ON commercial_modules;
CREATE POLICY "commercial_modules_read" ON commercial_modules
    FOR SELECT TO authenticated USING (TRUE);

ALTER TABLE commercial_module_pricing ENABLE ROW LEVEL SECURITY;
ALTER TABLE commercial_module_pricing FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "commercial_pricing_read" ON commercial_module_pricing;
CREATE POLICY "commercial_pricing_read" ON commercial_module_pricing
    FOR SELECT TO authenticated USING (TRUE);

-- 12.2 commercial_tenant_subscriptions
ALTER TABLE commercial_tenant_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE commercial_tenant_subscriptions FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "subscriptions_tenant_isolation" ON commercial_tenant_subscriptions;
CREATE POLICY "subscriptions_tenant_isolation" ON commercial_tenant_subscriptions
    FOR ALL TO authenticated
    USING (is_tenant_member(tenant_id))
    WITH CHECK (is_tenant_member(tenant_id));

-- 12.3 commercial_payment_orders & items
ALTER TABLE commercial_payment_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE commercial_payment_orders FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "payment_orders_tenant_isolation" ON commercial_payment_orders;
CREATE POLICY "payment_orders_tenant_isolation" ON commercial_payment_orders
    FOR ALL TO authenticated
    USING (is_tenant_member(tenant_id))
    WITH CHECK (is_tenant_member(tenant_id));

ALTER TABLE commercial_payment_order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE commercial_payment_order_items FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "payment_items_tenant_isolation" ON commercial_payment_order_items;
CREATE POLICY "payment_items_tenant_isolation" ON commercial_payment_order_items
    FOR ALL TO authenticated
    USING (order_id IN (SELECT id FROM commercial_payment_orders WHERE is_tenant_member(tenant_id)))
    WITH CHECK (order_id IN (SELECT id FROM commercial_payment_orders WHERE is_tenant_member(tenant_id)));

-- 12.4 data_migration_jobs & staging & mappings
ALTER TABLE data_migration_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE data_migration_jobs FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "migration_jobs_tenant_isolation" ON data_migration_jobs;
CREATE POLICY "migration_jobs_tenant_isolation" ON data_migration_jobs
    FOR ALL TO authenticated
    USING (is_tenant_member(tenant_id))
    WITH CHECK (is_tenant_member(tenant_id));

ALTER TABLE data_migration_staging ENABLE ROW LEVEL SECURITY;
ALTER TABLE data_migration_staging FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "migration_staging_tenant_isolation" ON data_migration_staging;
CREATE POLICY "migration_staging_tenant_isolation" ON data_migration_staging
    FOR ALL TO authenticated
    USING (is_tenant_member(tenant_id))
    WITH CHECK (is_tenant_member(tenant_id));

ALTER TABLE data_migration_mappings ENABLE ROW LEVEL SECURITY;
ALTER TABLE data_migration_mappings FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "migration_mappings_tenant_isolation" ON data_migration_mappings;
CREATE POLICY "migration_mappings_tenant_isolation" ON data_migration_mappings
    FOR ALL TO authenticated
    USING (is_tenant_member(tenant_id))
    WITH CHECK (is_tenant_member(tenant_id));

-- Grant execute on security helper
GRANT EXECUTE ON FUNCTION public.has_active_module TO authenticated;
