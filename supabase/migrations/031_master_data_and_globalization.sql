-- ==============================================================================
-- NAKHL & NAHL — MIGRATION 031: MASTER DATA & GLOBALIZATION BUILD (FAZ 11)
-- Purpose:
-- 1. countries (Küresel Ülke Master)
-- 2. languages (ISO 639 standardı: TR, EN, AR, FA, UR)
-- 3. scripts (ISO 15924: Latn, Arab, vb.)
-- 4. regional_locales (tr-TR, en-US, ar-SA, ar-EG, fa-IR, ur-PK + BCP 47 biçimlendirme)
-- 5. currencies (ISO 4217: SAR, USD, TRY, EUR, AED, PKR vb.)
-- 6. uom_categories, units & unit_conversions (KG, G, TON, L, ML, PCS, BOX, PALLET, CONTAINER)
-- 7. product_categories (Hiyerarşik kategori ağacı)
-- 8. items (Ürün master genişletmesi: barkod, kategori, UOM, izlenebilirlik, helal)
-- 9. parties & party_roles (Tekilleştirilmiş Muhatap Master: Müşteri, Tedarikçi, Taşıyıcı vb.)
-- 10. tax_profiles (Ülke ve Şirket bazlı KDV/VAT, Stopaj, Sıfır Oranlı İhracat)
-- 11. item_lots (Gelişmiş tedarikçi ve menşe izlenebilirlik alanları)
-- ==============================================================================

-- 1. KÜRESEL ÜLKELER (COUNTRIES MASTER)
CREATE TABLE IF NOT EXISTS countries (
    code VARCHAR(2) PRIMARY KEY, -- ISO 3166-1 alpha-2 (SA, TR, AE, US, PK, IR, EG vb.)
    iso_alpha3 VARCHAR(3) NOT NULL UNIQUE,
    iso_numeric VARCHAR(3),
    name VARCHAR(150) NOT NULL,
    native_name VARCHAR(150),
    region VARCHAR(100), -- Middle East, Europe, Asia, Americas vb.
    phone_code VARCHAR(20),
    default_language_code VARCHAR(10),
    default_currency_code VARCHAR(5),
    timezone VARCHAR(50) DEFAULT 'UTC',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. DİLLER (LANGUAGES EXTENSION)
-- Eğer migration 027 languages tablosunu oluşturduysa eksik alanları tamamlayalım
ALTER TABLE languages ADD COLUMN IF NOT EXISTS iso_code VARCHAR(10);

-- Urdu (ur) dilini ekleyelim
INSERT INTO languages (code, english_name, native_name, is_active, iso_code)
VALUES
    ('ur', 'Urdu', 'اردو', TRUE, 'urd')
ON CONFLICT (code) DO UPDATE 
SET is_active = TRUE, iso_code = 'urd';

-- 3. YAZI SİSTEMLERİ (SCRIPTS)
-- scripts tablosu 027 ile oluşturulmuştu; kontrol edelim
CREATE TABLE IF NOT EXISTS scripts (
    code VARCHAR(10) PRIMARY KEY, -- Latn, Arab, Hans, Cyrl
    name VARCHAR(100) NOT NULL,
    default_direction VARCHAR(5) NOT NULL DEFAULT 'ltr',
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- 4. KÜRESEL PARA BİRİMLERİ (CURRENCIES MASTER)
CREATE TABLE IF NOT EXISTS currencies (
    code VARCHAR(5) PRIMARY KEY, -- ISO 4217 (SAR, USD, TRY, EUR, AED, PKR vb.)
    numeric_code VARCHAR(3) UNIQUE,
    name VARCHAR(100) NOT NULL,
    symbol VARCHAR(10) NOT NULL,
    decimal_places INT NOT NULL DEFAULT 2,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. BÖLGESEL YEREL AYARLAR (REGIONAL LOCALES / BCP 47)
CREATE TABLE IF NOT EXISTS regional_locales (
    locale_code VARCHAR(20) PRIMARY KEY, -- tr-TR, en-US, ar-SA, ar-EG, fa-IR, ur-PK
    language_code VARCHAR(10) NOT NULL REFERENCES languages(code),
    country_code VARCHAR(2) NOT NULL REFERENCES countries(code),
    script_code VARCHAR(10) NOT NULL REFERENCES scripts(code),
    direction VARCHAR(5) NOT NULL DEFAULT 'ltr', -- ltr, rtl
    date_format VARCHAR(30) NOT NULL DEFAULT 'DD/MM/YYYY',
    time_format VARCHAR(20) NOT NULL DEFAULT 'HH:mm:ss',
    decimal_separator VARCHAR(5) NOT NULL DEFAULT '.',
    thousands_separator VARCHAR(5) NOT NULL DEFAULT ',',
    currency_symbol_placement VARCHAR(10) NOT NULL DEFAULT 'AFTER', -- BEFORE, AFTER
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- 6. ÖLÇÜ BİRİMİ KATEGORİLERİ VE BİRİMLER (UOM & CONVERSIONS)
CREATE TABLE IF NOT EXISTS uom_categories (
    id VARCHAR(50) PRIMARY KEY, -- WEIGHT, VOLUME, COUNT, PACKAGING
    name VARCHAR(100) NOT NULL,
    description TEXT
);

CREATE TABLE IF NOT EXISTS units (
    code VARCHAR(20) PRIMARY KEY, -- KG, G, TON, L, ML, PCS, BOX, PALLET, CONTAINER
    category_id VARCHAR(50) NOT NULL REFERENCES uom_categories(id),
    name VARCHAR(100) NOT NULL,
    symbol VARCHAR(10) NOT NULL,
    is_base_unit BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS unit_conversions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    from_unit VARCHAR(20) NOT NULL REFERENCES units(code),
    to_unit VARCHAR(20) NOT NULL REFERENCES units(code),
    factor NUMERIC(18,8) NOT NULL,
    CONSTRAINT uq_conversion UNIQUE (from_unit, to_unit)
);

-- 7. ÜRÜN KATEGORİLERİ (PRODUCT CATEGORIES - HİYERARŞİK)
CREATE TABLE IF NOT EXISTS product_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    parent_id UUID REFERENCES product_categories(id) ON DELETE RESTRICT,
    code VARCHAR(50) NOT NULL,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_category_company_code UNIQUE (company_id, code)
);

-- 8. ÜRÜN KARTLARI GENİŞLETMESİ (ITEMS / PRODUCTS ENHANCEMENT)
ALTER TABLE items ADD COLUMN IF NOT EXISTS barcode VARCHAR(100);
ALTER TABLE items ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE items ADD COLUMN IF NOT EXISTS category_id UUID REFERENCES product_categories(id) ON DELETE SET NULL;
ALTER TABLE items ADD COLUMN IF NOT EXISTS sales_uom VARCHAR(20) REFERENCES units(code);
ALTER TABLE items ADD COLUMN IF NOT EXISTS purchase_uom VARCHAR(20) REFERENCES units(code);
ALTER TABLE items ADD COLUMN IF NOT EXISTS product_type VARCHAR(50) DEFAULT 'FINISHED_GOOD';
ALTER TABLE items ADD COLUMN IF NOT EXISTS traceability_required BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE items ADD COLUMN IF NOT EXISTS lot_required BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE items ADD COLUMN IF NOT EXISTS halal_required BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE items ADD COLUMN IF NOT EXISTS quality_required BOOLEAN NOT NULL DEFAULT TRUE;

CREATE INDEX IF NOT EXISTS idx_items_barcode ON items(barcode);
CREATE INDEX IF NOT EXISTS idx_items_category_id ON items(category_id);

-- 9. TEKİL MUHATAP MASTER (PARTIES & PARTY ROLES)
CREATE TABLE IF NOT EXISTS parties (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    code VARCHAR(50),
    party_type VARCHAR(20) NOT NULL DEFAULT 'ORGANIZATION', -- PERSON, ORGANIZATION
    legal_name VARCHAR(255) NOT NULL DEFAULT 'Party',
    name VARCHAR(255),
    trade_name VARCHAR(150),
    tax_number VARCHAR(50),
    country_code VARCHAR(2) REFERENCES countries(code),
    email citext,
    phone VARCHAR(50),
    website VARCHAR(150),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION sync_party_name()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.name IS NOT NULL AND (NEW.legal_name IS NULL OR NEW.legal_name = 'Party') THEN
        NEW.legal_name := NEW.name;
    ELSIF NEW.legal_name IS NOT NULL AND NEW.name IS NULL THEN
        NEW.name := NEW.legal_name;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sync_party_name ON parties;
CREATE TRIGGER trg_sync_party_name
BEFORE INSERT OR UPDATE ON parties
FOR EACH ROW EXECUTE FUNCTION sync_party_name();

CREATE TABLE IF NOT EXISTS party_roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    party_id UUID NOT NULL REFERENCES parties(id) ON DELETE CASCADE,
    role_type VARCHAR(50) NOT NULL, -- CUSTOMER, SUPPLIER, EMPLOYEE, CARRIER, BROKER, CUSTOMS_AGENT, BANK, OTHER
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_party_role UNIQUE (party_id, role_type)
);

-- cariler tablosuna party_id bağlantısı (geriye dönük tam uyumlu köprü)
ALTER TABLE cariler ADD COLUMN IF NOT EXISTS party_id UUID REFERENCES parties(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_parties_tenant_tax ON parties(tenant_id, tax_number);
CREATE INDEX IF NOT EXISTS idx_party_roles_party ON party_roles(party_id);
CREATE INDEX IF NOT EXISTS idx_cariler_party ON cariler(party_id);

-- 10. VERGİ PROFİLLERİ (TAX PROFILES MASTER)
CREATE TABLE IF NOT EXISTS tax_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    country_code VARCHAR(2) REFERENCES countries(code),
    code VARCHAR(50) NOT NULL,
    name VARCHAR(100) NOT NULL,
    tax_type VARCHAR(50) NOT NULL DEFAULT 'VAT', -- VAT, GST, WITHHOLDING, EXPORT_ZERO, CUSTOMS
    rate NUMERIC(5,2) NOT NULL DEFAULT 0.00,
    is_recoverable BOOLEAN NOT NULL DEFAULT TRUE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_tax_company_code UNIQUE (company_id, code)
);

-- 11. PARTİ / LOT İZLENEBİLİRLİK GENİŞLETMESİ (ITEM_LOTS ENHANCEMENT)
ALTER TABLE item_lots ADD COLUMN IF NOT EXISTS supplier_party_id UUID REFERENCES parties(id) ON DELETE SET NULL;
ALTER TABLE item_lots ADD COLUMN IF NOT EXISTS source_document_type VARCHAR(50); -- INVOICE, PURCHASE_ORDER, IMPORT_DECLARATION
ALTER TABLE item_lots ADD COLUMN IF NOT EXISTS source_document_ref VARCHAR(100);
ALTER TABLE item_lots ADD COLUMN IF NOT EXISTS initial_quantity NUMERIC(15,3) DEFAULT 0.000;
ALTER TABLE item_lots ADD COLUMN IF NOT EXISTS uom VARCHAR(20) REFERENCES units(code);

-- ==============================================================================
-- 12. BAŞLANGIÇ TEMEL VERİLERİ (SEED DATA)
-- ==============================================================================

-- Ülkeler
INSERT INTO countries (code, iso_alpha3, iso_numeric, name, native_name, region, phone_code, default_language_code, default_currency_code, timezone)
VALUES
    ('SA', 'SAU', '682', 'Saudi Arabia', 'المملكة العربية السعودية', 'Middle East', '+966', 'ar', 'SAR', 'Asia/Riyadh'),
    ('TR', 'TUR', '792', 'Turkey', 'Türkiye', 'Europe/Middle East', '+90', 'tr', 'TRY', 'Europe/Istanbul'),
    ('AE', 'ARE', '784', 'United Arab Emirates', 'الإمارات العربية المتحدة', 'Middle East', '+971', 'ar', 'AED', 'Asia/Dubai'),
    ('EG', 'EGY', '818', 'Egypt', 'مصر', 'North Africa', '+20', 'ar', 'EGP', 'Africa/Cairo'),
    ('IR', 'IRN', '364', 'Iran', 'ایران', 'Middle East', '+98', 'fa', 'IRR', 'Asia/Tehran'),
    ('PK', 'PAK', '586', 'Pakistan', 'پاکستان', 'South Asia', '+92', 'ur', 'PKR', 'Asia/Karachi'),
    ('US', 'USA', '840', 'United States', 'United States', 'Americas', '+1', 'en', 'USD', 'America/New_York'),
    ('GB', 'GBR', '826', 'United Kingdom', 'United Kingdom', 'Europe', '+44', 'en', 'GBP', 'Europe/London'),
    ('DE', 'DEU', '276', 'Germany', 'Deutschland', 'Europe', '+49', 'de', 'EUR', 'Europe/Berlin'),
    ('JO', 'JOR', '400', 'Jordan', 'الأردن', 'Middle East', '+962', 'ar', 'JOD', 'Asia/Amman')
ON CONFLICT (code) DO NOTHING;

-- Para Birimleri
INSERT INTO currencies (code, numeric_code, name, symbol, decimal_places)
VALUES
    ('SAR', '682', 'Saudi Riyal', '﷼', 2),
    ('USD', '840', 'US Dollar', '$', 2),
    ('EUR', '978', 'Euro', '€', 2),
    ('TRY', '949', 'Turkish Lira', '₺', 2),
    ('AED', '784', 'UAE Dirham', 'د.إ', 2),
    ('PKR', '586', 'Pakistani Rupee', '₨', 2),
    ('EGP', '818', 'Egyptian Pound', 'E£', 2),
    ('GBP', '826', 'British Pound', '£', 2)
ON CONFLICT (code) DO NOTHING;

-- Bölgesel Yerel Ayarlar
INSERT INTO regional_locales (locale_code, language_code, country_code, script_code, direction, date_format, time_format, decimal_separator, thousands_separator, currency_symbol_placement)
VALUES
    ('tr-TR', 'tr', 'TR', 'Latn', 'ltr', 'DD.MM.YYYY', 'HH:mm:ss', ',', '.', 'AFTER'),
    ('ar-SA', 'ar', 'SA', 'Arab', 'rtl', 'YYYY/MM/DD', 'HH:mm:ss', '٫', '٬', 'AFTER'),
    ('en-US', 'en', 'US', 'Latn', 'ltr', 'MM/DD/YYYY', 'hh:mm:ss A', '.', ',', 'BEFORE'),
    ('fa-IR', 'fa', 'IR', 'Arab', 'rtl', 'YYYY/MM/DD', 'HH:mm:ss', '٫', '٬', 'AFTER'),
    ('ur-PK', 'ur', 'PK', 'Arab', 'rtl', 'DD/MM/YYYY', 'hh:mm:ss A', '.', ',', 'BEFORE'),
    ('ar-EG', 'ar', 'EG', 'Arab', 'rtl', 'DD/MM/YYYY', 'HH:mm:ss', '٫', '٬', 'AFTER'),
    ('en-GB', 'en', 'GB', 'Latn', 'ltr', 'DD/MM/YYYY', 'HH:mm:ss', '.', ',', 'BEFORE')
ON CONFLICT (locale_code) DO NOTHING;

-- UOM Kategorileri
INSERT INTO uom_categories (id, name, description)
VALUES
    ('WEIGHT', 'Ağırlık Ölçüleri', 'Kilogram, Gram, Ton bazlı kütle ölçüleri'),
    ('VOLUME', 'Hacim Ölçüleri', 'Litre, Mililitre, Metreküp bazlı hacim ölçüleri'),
    ('COUNT', 'Adet/Sayım Ölçüleri', 'Adet, Düzine, Tane bazlı sayım ölçüleri'),
    ('PACKAGING', 'Paketleme & Lojistik Ölçüleri', 'Koli, Kutu, Palet, Konteyner bazlı lojistik birimler')
ON CONFLICT (id) DO NOTHING;

-- Ölçü Birimleri
INSERT INTO units (code, category_id, name, symbol, is_base_unit)
VALUES
    ('KG', 'WEIGHT', 'Kilogram', 'kg', TRUE),
    ('G', 'WEIGHT', 'Gram', 'g', FALSE),
    ('TON', 'WEIGHT', 'Metrik Ton', 't', FALSE),
    ('L', 'VOLUME', 'Litre', 'L', TRUE),
    ('ML', 'VOLUME', 'Mililitre', 'mL', FALSE),
    ('PCS', 'COUNT', 'Adet / Tane', 'adet', TRUE),
    ('BOX', 'PACKAGING', 'Koli / Kutu', 'koli', FALSE),
    ('PALLET', 'PACKAGING', 'Standart Euro Palet', 'plt', FALSE),
    ('CONTAINER', 'PACKAGING', '40ft Reefer Konteyner', 'cntr', FALSE)
ON CONFLICT (code) DO NOTHING;

-- Birim Dönüşüm Katsayıları
INSERT INTO unit_conversions (from_unit, to_unit, factor)
VALUES
    ('TON', 'KG', 1000.00000000),
    ('KG', 'TON', 0.00100000),
    ('KG', 'G', 1000.00000000),
    ('G', 'KG', 0.00100000),
    ('L', 'ML', 1000.00000000),
    ('ML', 'L', 0.00100000)
ON CONFLICT (from_unit, to_unit) DO NOTHING;

-- ==============================================================================
-- 13. ROW LEVEL SECURITY (RLS) POLİTİKALARI
-- ==============================================================================

-- Küresel Master Tablolarda RLS (Public Read-Only, Admin Write)
ALTER TABLE countries ENABLE ROW LEVEL SECURITY;
ALTER TABLE currencies ENABLE ROW LEVEL SECURITY;
ALTER TABLE regional_locales ENABLE ROW LEVEL SECURITY;
ALTER TABLE uom_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE units ENABLE ROW LEVEL SECURITY;
ALTER TABLE unit_conversions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "countries_public_select" ON countries FOR SELECT USING (true);
CREATE POLICY "currencies_public_select" ON currencies FOR SELECT USING (true);
CREATE POLICY "locales_public_select" ON regional_locales FOR SELECT USING (true);
CREATE POLICY "uom_cat_public_select" ON uom_categories FOR SELECT USING (true);
CREATE POLICY "units_public_select" ON units FOR SELECT USING (true);
CREATE POLICY "unit_conv_public_select" ON unit_conversions FOR SELECT USING (true);

-- Kiracı İzolasyonlu Master Tablolar (Tenant & Company Scoped)
ALTER TABLE product_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_categories FORCE ROW LEVEL SECURITY;

CREATE POLICY "product_categories_select" ON product_categories
    FOR SELECT USING (is_tenant_member(tenant_id) AND has_company_access(company_id));

CREATE POLICY "product_categories_manage" ON product_categories
    FOR ALL USING (is_tenant_member(tenant_id) AND has_company_access(company_id))
    WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(company_id));

ALTER TABLE parties ENABLE ROW LEVEL SECURITY;
ALTER TABLE parties FORCE ROW LEVEL SECURITY;

CREATE POLICY "parties_select" ON parties
    FOR SELECT USING (is_tenant_member(tenant_id));

CREATE POLICY "parties_manage" ON parties
    FOR ALL USING (is_tenant_member(tenant_id))
    WITH CHECK (is_tenant_member(tenant_id));

ALTER TABLE party_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE party_roles FORCE ROW LEVEL SECURITY;

CREATE POLICY "party_roles_select" ON party_roles
    FOR SELECT USING (is_tenant_member(tenant_id));

CREATE POLICY "party_roles_manage" ON party_roles
    FOR ALL USING (is_tenant_member(tenant_id))
    WITH CHECK (is_tenant_member(tenant_id));

ALTER TABLE tax_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE tax_profiles FORCE ROW LEVEL SECURITY;

CREATE POLICY "tax_profiles_select" ON tax_profiles
    FOR SELECT USING (is_tenant_member(tenant_id) AND has_company_access(company_id));

CREATE POLICY "tax_profiles_manage" ON tax_profiles
    FOR ALL USING (is_tenant_member(tenant_id) AND has_company_access(company_id))
    WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(company_id));
