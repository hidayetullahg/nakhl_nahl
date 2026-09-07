-- ==============================================================================
-- NAKHL & NAHL — MIGRATION 055: FAZ 11
-- DİNAMİK KULLANICI PARAMETRELERİ + ÇOK DİLLİ + ÇOK ALFABELİ ERP + DİNAMİK MENÜ/ÜRÜN/SEKTÖR
-- ==============================================================================

-- 1. KÜRESEL VE ÖZEL SEKTÖRLER (SECTORS MASTER)
CREATE TABLE IF NOT EXISTS sectors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(50) NOT NULL UNIQUE,
    name_key VARCHAR(100) NOT NULL,
    default_name VARCHAR(150) NOT NULL,
    icon_name VARCHAR(50) NOT NULL DEFAULT 'category_rounded',
    is_global BOOLEAN NOT NULL DEFAULT TRUE,
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE, -- Özel sektörler için
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. ŞİRKET / KİRACI SEKTÖR BAĞLANTISI (TENANT SECTORS - MULTI-SELECT)
CREATE TABLE IF NOT EXISTS tenant_sectors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    sector_id UUID NOT NULL REFERENCES sectors(id) ON DELETE CASCADE,
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_tenant_sector UNIQUE (tenant_id, sector_id)
);

-- 3. ÜRÜN KATEGORİSİNE SEKTÖR BAĞLANTISI (PRODUCT CATEGORIES -> SECTOR)
ALTER TABLE product_categories ADD COLUMN IF NOT EXISTS sector_id UUID REFERENCES sectors(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_product_categories_sector ON product_categories(sector_id);

-- 4. ÜRÜN KALİTE DERECELERİ (PRODUCT GRADES / QUALITIES)
CREATE TABLE IF NOT EXISTS product_grades (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE, -- NULL ise global standart sınıf
    sector_id UUID REFERENCES sectors(id) ON DELETE CASCADE,
    code VARCHAR(50) NOT NULL, -- PREMIUM, FIRST_GRADE, SECOND_GRADE, INDUSTRIAL
    name_key VARCHAR(100) NOT NULL,
    default_name VARCHAR(100) NOT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_tenant_sector_grade UNIQUE (tenant_id, sector_id, code)
);

-- 5. ÜRÜN DURUMU / KONDİSYON VE FİRE (PRODUCT CONDITIONS - FİRE AYRI BİR STATÜDÜR)
CREATE TABLE IF NOT EXISTS product_conditions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    code VARCHAR(50) NOT NULL, -- SOUND_NORMAL, DEFECTIVE, FIRE_REJECT, EXPIRED, BY_PRODUCT
    name_key VARCHAR(100) NOT NULL,
    default_name VARCHAR(100) NOT NULL,
    is_scrap_fire BOOLEAN NOT NULL DEFAULT FALSE, -- Fire / Hurda ayracı
    accounting_impact_type VARCHAR(50) NOT NULL DEFAULT 'STANDARD', -- STANDARD, WRITE_OFF, DISCOUNTED_SALE, SCRAP_EXPENSE
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_tenant_condition UNIQUE (tenant_id, code)
);

-- items tablosuna varsayılan kalite ve kondisyon sütunları ekleyelim
ALTER TABLE items ADD COLUMN IF NOT EXISTS default_grade_id UUID REFERENCES product_grades(id) ON DELETE SET NULL;
ALTER TABLE items ADD COLUMN IF NOT EXISTS condition_id UUID REFERENCES product_conditions(id) ON DELETE SET NULL;
ALTER TABLE items ADD COLUMN IF NOT EXISTS sector_id UUID REFERENCES sectors(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_items_sector_id ON items(sector_id);

-- 6. KULLANICI PARAMETRELERİ (USER PREFERENCES)
CREATE TABLE IF NOT EXISTS user_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    primary_language_code VARCHAR(10) NOT NULL DEFAULT 'tr',
    primary_script_code VARCHAR(10) NOT NULL DEFAULT 'Latn',
    secondary_language_code VARCHAR(10),
    secondary_script_code VARCHAR(10),
    tertiary_language_code VARCHAR(10),
    tertiary_script_code VARCHAR(10),
    active_locale_id VARCHAR(20) NOT NULL DEFAULT 'tr-Latn',
    text_direction VARCHAR(5) NOT NULL DEFAULT 'ltr', -- ltr, rtl
    typography_scale VARCHAR(20) NOT NULL DEFAULT 'standard', -- standard, large, compact
    date_format VARCHAR(30) NOT NULL DEFAULT 'DD/MM/YYYY',
    number_format VARCHAR(30) NOT NULL DEFAULT '#,##0.00',
    currency_display_mode VARCHAR(20) NOT NULL DEFAULT 'SYMBOL', -- SYMBOL, CODE, NAME
    default_company_id UUID REFERENCES companies(id) ON DELETE SET NULL,
    default_branch_id UUID REFERENCES branches(id) ON DELETE SET NULL,
    default_warehouse_id UUID REFERENCES warehouses(id) ON DELETE SET NULL,
    default_workspace VARCHAR(50) DEFAULT 'DASHBOARD',
    menu_preferences JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_user_tenant_preferences UNIQUE (user_id, tenant_id)
);

-- 7. ÇOKLU ÜLKE VE ADRES / LOKASYON HİYERARŞİSİ
CREATE TABLE IF NOT EXISTS tenant_countries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    country_code VARCHAR(2) NOT NULL REFERENCES countries(code) ON DELETE RESTRICT,
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_tenant_country UNIQUE (tenant_id, country_code)
);

CREATE TABLE IF NOT EXISTS regions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    country_code VARCHAR(2) NOT NULL REFERENCES countries(code) ON DELETE CASCADE,
    code VARCHAR(50) NOT NULL,
    name VARCHAR(150) NOT NULL,
    native_name VARCHAR(150),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_country_region UNIQUE (country_code, code)
);

CREATE TABLE IF NOT EXISTS cities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    region_id UUID NOT NULL REFERENCES regions(id) ON DELETE CASCADE,
    name VARCHAR(150) NOT NULL,
    native_name VARCHAR(150),
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS districts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    city_id UUID NOT NULL REFERENCES cities(id) ON DELETE CASCADE,
    name VARCHAR(150) NOT NULL,
    native_name VARCHAR(150),
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS neighborhoods (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    district_id UUID NOT NULL REFERENCES districts(id) ON DELETE CASCADE,
    name VARCHAR(150) NOT NULL,
    native_name VARCHAR(150),
    postal_code VARCHAR(20),
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS postal_addresses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    country_code VARCHAR(2) NOT NULL REFERENCES countries(code),
    region_id UUID REFERENCES regions(id),
    city_id UUID REFERENCES cities(id),
    district_id UUID REFERENCES districts(id),
    neighborhood_id UUID REFERENCES neighborhoods(id),
    street_address TEXT NOT NULL,
    building_no VARCHAR(50),
    door_no VARCHAR(50),
    postal_code VARCHAR(20),
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 8. DİL, YAZI SİSTEMİ VE LOCALES GENİŞLETMESİ (SEED DATA)
INSERT INTO languages (code, english_name, native_name, is_active)
VALUES
    ('bn', 'Bengali', 'বাংলা', TRUE),
    ('hi', 'Hindi', 'हिन्दी', TRUE),
    ('tl', 'Tagalog / Filipino', 'Tagalog', TRUE),
    ('am', 'Amharic', 'አማርኛ', TRUE),
    ('ur', 'Urdu', 'اردو', TRUE),
    ('fa', 'Persian', 'فارسی', TRUE)
ON CONFLICT (code) DO UPDATE 
SET is_active = TRUE;

INSERT INTO scripts (code, name, default_direction, is_active)
VALUES
    ('Deva', 'Devanagari Alfabesi', 'ltr', TRUE),
    ('Beng', 'Bengal Alfabesi', 'ltr', TRUE),
    ('Ethi', 'Ge''ez / Etiyopya Alfabesi', 'ltr', TRUE)
ON CONFLICT (code) DO NOTHING;

INSERT INTO locales (locale_id, language_code, script_code, direction, primary_font, fallback_font, is_active)
VALUES
    ('ur-Arab', 'ur', 'Arab', 'rtl', 'Noto Naskh Arabic', 'Amiri', TRUE),
    ('fa-Arab', 'fa', 'Arab', 'rtl', 'Amiri', 'Noto Naskh Arabic', TRUE),
    ('bn-Beng', 'bn', 'Beng', 'ltr', 'Noto Sans Bengali', 'Roboto', TRUE),
    ('hi-Deva', 'hi', 'Deva', 'ltr', 'Noto Sans Devanagari', 'Roboto', TRUE),
    ('tl-Latn', 'tl', 'Latn', 'ltr', 'Inter', 'Roboto', TRUE),
    ('am-Ethi', 'am', 'Ethi', 'ltr', 'Noto Sans Ethiopic', 'Roboto', TRUE)
ON CONFLICT (locale_id) DO NOTHING;

-- 9. 11 ÇEKİRDEK SEKTÖR (SEED DATA)
INSERT INTO sectors (code, name_key, default_name, icon_name, sort_order)
VALUES
    ('DATES', 'sector.dates', 'Hurma ve Hurma Ürünleri', 'eco_rounded', 1),
    ('FOOD', 'sector.food', 'Gıda & İçecek', 'restaurant_rounded', 2),
    ('AGRI', 'sector.agri', 'Tarım & Ziraat', 'agriculture_rounded', 3),
    ('BEEKEEPING', 'sector.beekeeping', 'Arıcılık & Bal', 'hive_rounded', 4),
    ('FURNITURE', 'sector.furniture', 'Mobilya & Dekorasyon', 'chair_rounded', 5),
    ('TEXTILE', 'sector.textile', 'Tekstil & Konfeksiyon', 'checkroom_rounded', 6),
    ('AUTOMOTIVE', 'sector.automotive', 'Otomotiv & Yedek Parça', 'directions_car_rounded', 7),
    ('CONSTRUCTION', 'sector.construction', 'İnşaat & Yapı Malzemeleri', 'handyman_rounded', 8),
    ('LOGISTICS', 'sector.logistics', 'Lojistik & Taşımacılık', 'local_shipping_rounded', 9),
    ('RETAIL', 'sector.retail', 'Perakende & Mağazacılık', 'storefront_rounded', 10),
    ('WHOLESALE', 'sector.wholesale', 'Toptan Ticaret', 'warehouse_rounded', 11)
ON CONFLICT (code) DO NOTHING;

-- 10. TEMEL KALİTE SINIFLARI VE FİRE / KONDİSYONLARI (SEED DATA)
INSERT INTO product_conditions (tenant_id, code, name_key, default_name, is_scrap_fire, accounting_impact_type)
VALUES
    (NULL, 'SOUND_NORMAL', 'condition.sound_normal', 'Normal Sağlam Mamul', FALSE, 'STANDARD'),
    (NULL, 'DEFECTIVE_CLASS_B', 'condition.defective_b', 'Kusurlu / İkinci Kalite Satış', FALSE, 'DISCOUNTED_SALE'),
    (NULL, 'FIRE_REJECT', 'condition.fire_reject', 'Fire / Üretim-Depo Kaybı', TRUE, 'WRITE_OFF'),
    (NULL, 'EXPIRED_SCRAP', 'condition.expired_scrap', 'Miadı Dolmuş Hurda', TRUE, 'SCRAP_EXPENSE'),
    (NULL, 'BY_PRODUCT', 'condition.by_product', 'Yan Ürün / İşleme Artığı', FALSE, 'STANDARD')
ON CONFLICT DO NOTHING;

-- 11. DİNAMİK MENÜ VE ARAYÜZ ÇEVİRİLERİ (SEED DATA)
INSERT INTO ui_translations (translation_key, locale_id, translation_value)
VALUES
    -- Türkçe Latin
    ('menu.product', 'tr-Latn', 'Ürün'),
    ('menu.customers', 'tr-Latn', 'Cariler & Müşteriler'),
    ('menu.finance', 'tr-Latn', 'Finans & Kasa'),
    ('menu.inventory', 'tr-Latn', 'Stok & Depo'),
    ('menu.sales', 'tr-Latn', 'Satış & Faturalandırma'),
    ('menu.shipments', 'tr-Latn', 'Sevkiyat & Lojistik'),
    ('menu.reports', 'tr-Latn', 'Raporlama'),
    ('menu.settings', 'tr-Latn', 'Ayarlar'),
    ('menu.user_parameters', 'tr-Latn', 'Kullanıcı Parametreleri'),
    ('btn.add_new_product', 'tr-Latn', '＋ Yeni Ürün Ekle'),
    ('btn.add_new_sector', 'tr-Latn', '＋ Başka Sektör Ekle'),

    -- Arapça
    ('menu.product', 'ar-Arab', 'المنتجات'),
    ('menu.customers', 'ar-Arab', 'الحسابات الجارية والعملاء'),
    ('menu.finance', 'ar-Arab', 'المالية والصندوق'),
    ('menu.inventory', 'ar-Arab', 'المخزون والمستودعات'),
    ('menu.sales', 'ar-Arab', 'المبيعات والفواتير'),
    ('menu.shipments', 'ar-Arab', 'الشحن والخدمات اللوجستية'),
    ('menu.reports', 'ar-Arab', 'التقارير'),
    ('menu.settings', 'ar-Arab', 'الإعدادات'),
    ('menu.user_parameters', 'ar-Arab', 'معلمات المستخدم'),
    ('btn.add_new_product', 'ar-Arab', '＋ إضافة منتج جديد'),
    ('btn.add_new_sector', 'ar-Arab', '＋ إضافة قطاع آخر'),

    -- İngilizce Latin
    ('menu.product', 'en-Latn', 'Products'),
    ('menu.customers', 'en-Latn', 'Parties & Customers'),
    ('menu.finance', 'en-Latn', 'Finance & Cash'),
    ('menu.inventory', 'en-Latn', 'Stock & Inventory'),
    ('menu.sales', 'en-Latn', 'Sales & Invoicing'),
    ('menu.shipments', 'en-Latn', 'Shipments & Logistics'),
    ('menu.reports', 'en-Latn', 'Reports'),
    ('menu.settings', 'en-Latn', 'Settings'),
    ('menu.user_parameters', 'en-Latn', 'User Parameters'),
    ('btn.add_new_product', 'en-Latn', '＋ Add New Product'),
    ('btn.add_new_sector', 'en-Latn', '＋ Add Custom Sector'),

    -- Uygurca Arap
    ('menu.product', 'ug-Arab', 'مەھسۇلات'),
    ('menu.customers', 'ug-Arab', 'ھېساباتلار ۋە خېرىدارلار'),
    ('menu.finance', 'ug-Arab', 'مالىيە ۋە خەزىنىچىلىك'),
    ('menu.inventory', 'ug-Arab', 'ئامبار ۋە زاپاس ساقلاش'),
    ('menu.sales', 'ug-Arab', 'سېتىش ۋە تالون كېسىش'),
    ('menu.shipments', 'ug-Arab', 'يۆتكەش ۋە ئەشيا ئوبوروتى'),
    ('menu.reports', 'ug-Arab', 'دوكلاتلار'),
    ('menu.settings', 'ug-Arab', 'تەڭشەكلەر'),
    ('menu.user_parameters', 'ug-Arab', 'ئىشلەتكۈچى پارامېتىرلىرى'),
    ('btn.add_new_product', 'ug-Arab', '＋ يېڭى مەھسۇلات قوشۇش'),
    ('btn.add_new_sector', 'ug-Arab', '＋ باشقا كەسىپ قوشۇش'),

    -- Urduca Arap
    ('menu.product', 'ur-Arab', 'مصنوعات'),
    ('menu.customers', 'ur-Arab', 'کھاتے اور گاہک'),
    ('menu.finance', 'ur-Arab', 'مالیات اور کیش'),
    ('menu.inventory', 'ur-Arab', 'اسٹاک اور گودام'),
    ('menu.sales', 'ur-Arab', 'سیلز اور انوائس'),
    ('menu.shipments', 'ur-Arab', 'ترسیل اور لاجسٹکس'),
    ('menu.reports', 'ur-Arab', 'رپورٹس'),
    ('menu.settings', 'ur-Arab', 'ترتیبات'),
    ('menu.user_parameters', 'ur-Arab', 'صارف کے پیرامیٹرز'),
    ('btn.add_new_product', 'ur-Arab', '＋ نئی مصنوعات شامل کریں'),
    ('btn.add_new_sector', 'ur-Arab', '＋ مزید شعبہ شامل کریں')
ON CONFLICT (translation_key, locale_id) DO UPDATE
SET translation_value = EXCLUDED.translation_value;

-- 12. RLS VE GÜVENLİK POLİTİKALARI (ROW LEVEL SECURITY)
ALTER TABLE sectors ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenant_sectors ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_grades ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_conditions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenant_countries ENABLE ROW LEVEL SECURITY;
ALTER TABLE postal_addresses ENABLE ROW LEVEL SECURITY;

-- Sectors: Global sektörler herkese açık (okuma), tenant özel sektörleri yalnızca ilgili tenanta
DROP POLICY IF EXISTS rls_sectors_select ON sectors;
CREATE POLICY rls_sectors_select ON sectors
    FOR SELECT USING (is_global = TRUE OR tenant_id = current_setting('app.current_tenant_id', true)::uuid);

DROP POLICY IF EXISTS rls_sectors_insert ON sectors;
CREATE POLICY rls_sectors_insert ON sectors
    FOR INSERT WITH CHECK (tenant_id = current_setting('app.current_tenant_id', true)::uuid);

-- Tenant Sectors: Tenant izolasyonu
DROP POLICY IF EXISTS rls_tenant_sectors_all ON tenant_sectors;
CREATE POLICY rls_tenant_sectors_all ON tenant_sectors
    FOR ALL USING (tenant_id = current_setting('app.current_tenant_id', true)::uuid);

-- User Preferences: Kullanıcı kendi tercihini okur/yazar, tenant izole
DROP POLICY IF EXISTS rls_user_preferences_all ON user_preferences;
CREATE POLICY rls_user_preferences_all ON user_preferences
    FOR ALL USING (tenant_id = current_setting('app.current_tenant_id', true)::uuid);

-- Tenant Countries:
DROP POLICY IF EXISTS rls_tenant_countries_all ON tenant_countries;
CREATE POLICY rls_tenant_countries_all ON tenant_countries
    FOR ALL USING (tenant_id = current_setting('app.current_tenant_id', true)::uuid);

-- Postal Addresses:
DROP POLICY IF EXISTS rls_postal_addresses_all ON postal_addresses;
CREATE POLICY rls_postal_addresses_all ON postal_addresses
    FOR ALL USING (tenant_id = current_setting('app.current_tenant_id', true)::uuid);

-- Product Grades & Conditions:
DROP POLICY IF EXISTS rls_product_grades_select ON product_grades;
CREATE POLICY rls_product_grades_select ON product_grades
    FOR SELECT USING (tenant_id IS NULL OR tenant_id = current_setting('app.current_tenant_id', true)::uuid);

DROP POLICY IF EXISTS rls_product_conditions_select ON product_conditions;
CREATE POLICY rls_product_conditions_select ON product_conditions
    FOR SELECT USING (tenant_id IS NULL OR tenant_id = current_setting('app.current_tenant_id', true)::uuid);
