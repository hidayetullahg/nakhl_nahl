-- ==============================================================================
-- NAKHL & NAHL — GLOBAL COUNTRY, CITY & LOCATION MASTER DATA (MIGRATION 057)
-- Normalized ISO-standard countries, 50,250 world cities support, multilingual names (TR/EN/AR),
-- search RPC functions, performance B-Tree indexes, and strict RLS protection.
-- ==============================================================================

-- 1. COUNTRIES TABLOSU GENİŞLETMESİ
ALTER TABLE countries ADD COLUMN IF NOT EXISTS country_name_en VARCHAR(150);
ALTER TABLE countries ADD COLUMN IF NOT EXISTS country_name_tr VARCHAR(150);
ALTER TABLE countries ADD COLUMN IF NOT EXISTS country_name_ar VARCHAR(150);
ALTER TABLE countries ADD COLUMN IF NOT EXISTS currency_name VARCHAR(100);
ALTER TABLE countries ADD COLUMN IF NOT EXISTS sort_order INT DEFAULT 100;
ALTER TABLE countries ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- 2. CITIES TABLOSU NORMALİZASYONU VE GENİŞLETMESİ
-- region_id foreign key zorunluluğunu esnetelim (dünya şehirleri doğrudan country_code ile bağlanabilir)
ALTER TABLE cities ALTER COLUMN region_id DROP NOT NULL;

ALTER TABLE cities ADD COLUMN IF NOT EXISTS country_code VARCHAR(2) REFERENCES countries(code) ON DELETE CASCADE;
ALTER TABLE cities ADD COLUMN IF NOT EXISTS city_name VARCHAR(150);
ALTER TABLE cities ADD COLUMN IF NOT EXISTS city_name_ascii VARCHAR(150);
ALTER TABLE cities ADD COLUMN IF NOT EXISTS admin_name VARCHAR(150);
ALTER TABLE cities ADD COLUMN IF NOT EXISTS latitude NUMERIC(10, 6);
ALTER TABLE cities ADD COLUMN IF NOT EXISTS longitude NUMERIC(10, 6);
ALTER TABLE cities ADD COLUMN IF NOT EXISTS capital_type VARCHAR(50);
ALTER TABLE cities ADD COLUMN IF NOT EXISTS population BIGINT DEFAULT 0;
ALTER TABLE cities ADD COLUMN IF NOT EXISTS source_id VARCHAR(50);

-- Geriye dönük uyumluluk: name alanı boşsa city_name'den doldurulsun
UPDATE cities SET city_name = name WHERE city_name IS NULL AND name IS NOT NULL;
UPDATE cities SET name = city_name WHERE name IS NULL AND city_name IS NOT NULL;

-- 3. PERFORMANS İNDEKSLERİ (B-TREE & FULL TEXT SEARCH)
CREATE INDEX IF NOT EXISTS idx_cities_country_code ON cities(country_code);
CREATE INDEX IF NOT EXISTS idx_cities_name_ascii ON cities(city_name_ascii);
CREATE INDEX IF NOT EXISTS idx_cities_name ON cities(city_name);
CREATE INDEX IF NOT EXISTS idx_cities_population ON cities(population DESC);
CREATE INDEX IF NOT EXISTS idx_cities_admin_name ON cities(admin_name);
CREATE INDEX IF NOT EXISTS idx_countries_iso3 ON countries(iso_alpha3);
CREATE INDEX IF NOT EXISTS idx_countries_sort ON countries(sort_order ASC, name ASC);

-- 4. KÜRESEL ÖNCELİKLİ ÜLKE VERİLERİ (SEED & MULTILINGUAL NORMALIZATION)
INSERT INTO countries (
    code, iso_alpha3, iso_numeric, name, country_name_en, country_name_tr, country_name_ar,
    native_name, region, phone_code, default_language_code, default_currency_code, currency_name, timezone, sort_order, is_active
) VALUES
    ('SA', 'SAU', '682', 'Saudi Arabia', 'Saudi Arabia', 'Suudi Arabistan', 'المملكة العربية السعودية', 'العربية السعودية', 'Middle East', '+966', 'ar', 'SAR', 'Suudi Arabistan Riyali', 'Asia/Riyadh', 1, TRUE),
    ('TR', 'TUR', '792', 'Turkey', 'Turkey', 'Türkiye', 'تركيا', 'Türkiye', 'Middle East / Europe', '+90', 'tr', 'TRY', 'Türk Lirası', 'Europe/Istanbul', 2, TRUE),
    ('AE', 'ARE', '784', 'United Arab Emirates', 'United Arab Emirates', 'Birleşik Arap Emirlikleri', 'الإمارات العربية المتحدة', 'الإمارات', 'Middle East', '+971', 'ar', 'AED', 'BAE Dirhemi', 'Asia/Dubai', 3, TRUE),
    ('EG', 'EGY', '818', 'Egypt', 'Egypt', 'Mısır', 'مصر', 'مصر', 'North Africa', '+20', 'ar', 'EGP', 'Mısır Lirası', 'Africa/Cairo', 4, TRUE),
    ('DE', 'DEU', '276', 'Germany', 'Germany', 'Almanya', 'ألمانيا', 'Deutschland', 'Europe', '+49', 'de', 'EUR', 'Euro', 'Europe/Berlin', 5, TRUE),
    ('US', 'USA', '840', 'United States', 'United States', 'Amerika Birleşik Devletleri', 'الولايات المتحدة الأمريكية', 'United States', 'Americas', '+1', 'en', 'USD', 'ABD Doları', 'America/New_York', 6, TRUE),
    ('GB', 'GBR', '826', 'United Kingdom', 'United Kingdom', 'Birleşik Krallık', 'المملكة المتحدة', 'United Kingdom', 'Europe', '+44', 'en', 'GBP', 'İngiliz Sterlini', 'Europe/London', 7, TRUE),
    ('QA', 'QAT', '634', 'Qatar', 'Qatar', 'Katar', 'قطر', 'قطر', 'Middle East', '+974', 'ar', 'QAR', 'Katar Riyali', 'Asia/Qatar', 8, TRUE),
    ('KW', 'KWT', '414', 'Kuwait', 'Kuwait', 'Kuveyt', 'الكويت', 'الكويت', 'Middle East', '+965', 'ar', 'KWD', 'Kuveyt Dinarı', 'Asia/Kuwait', 9, TRUE),
    ('OM', 'OMN', '512', 'Oman', 'Oman', 'Umman', 'عمان', 'عُمان', 'Middle East', '+968', 'ar', 'OMR', 'Umman Riyali', 'Asia/Muscat', 10, TRUE),
    ('BH', 'BHR', '048', 'Bahrain', 'Bahrain', 'Bahreyn', 'البحرين', 'البحرين', 'Middle East', '+973', 'ar', 'BHD', 'Bahreyn Dinarı', 'Asia/Bahrain', 11, TRUE),
    ('PK', 'PAK', '586', 'Pakistan', 'Pakistan', 'Pakistan', 'باكستان', 'پاکستان', 'South Asia', '+92', 'ur', 'PKR', 'Pakistan Rupisi', 'Asia/Karachi', 12, TRUE),
    ('CN', 'CHN', '156', 'China', 'China', 'Çin', 'الصين', '中国', 'East Asia', '+86', 'zh', 'CNY', 'Çin Yuanı', 'Asia/Shanghai', 13, TRUE),
    ('IN', 'IND', '356', 'India', 'India', 'Hindistan', 'الهند', 'भारत', 'South Asia', '+91', 'hi', 'INR', 'Hindistan Rupisi', 'Asia/Kolkata', 14, TRUE)
ON CONFLICT (code) DO UPDATE SET
    iso_alpha3 = EXCLUDED.iso_alpha3,
    country_name_en = EXCLUDED.country_name_en,
    country_name_tr = EXCLUDED.country_name_tr,
    country_name_ar = EXCLUDED.country_name_ar,
    phone_code = EXCLUDED.phone_code,
    default_currency_code = EXCLUDED.default_currency_code,
    currency_name = EXCLUDED.currency_name,
    timezone = EXCLUDED.timezone,
    sort_order = EXCLUDED.sort_order,
    is_active = TRUE;

-- 5. RLS VE GÜVENLİK İZOLASYONU (GLOBAL MASTER DATA POLİTİKALARI)
ALTER TABLE countries ENABLE ROW LEVEL SECURITY;
ALTER TABLE cities ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS rls_countries_public_read ON countries;
CREATE POLICY rls_countries_public_read ON countries FOR SELECT USING (TRUE);

DROP POLICY IF EXISTS rls_cities_public_read ON cities;
CREATE POLICY rls_cities_public_read ON cities FOR SELECT USING (TRUE);

-- 6. ARAMA VE AUTOCOMPLETE RPC FONKSİYONLARI (MULTILINGUAL SEARCH)
CREATE OR REPLACE FUNCTION search_countries(
    p_query TEXT,
    p_limit INT DEFAULT 20
)
RETURNS TABLE (
    code VARCHAR(2),
    iso_alpha3 VARCHAR(3),
    name VARCHAR(150),
    country_name_en VARCHAR(150),
    country_name_tr VARCHAR(150),
    country_name_ar VARCHAR(150),
    phone_code VARCHAR(20),
    default_currency_code VARCHAR(5),
    currency_name VARCHAR(100),
    timezone VARCHAR(50)
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.code,
        c.iso_alpha3,
        c.name,
        c.country_name_en,
        c.country_name_tr,
        c.country_name_ar,
        c.phone_code,
        c.default_currency_code,
        c.currency_name,
        c.timezone
    FROM countries c
    WHERE c.is_active = TRUE
      AND (
          p_query IS NULL 
          OR p_query = ''
          OR c.code ILIKE p_query || '%'
          OR c.iso_alpha3 ILIKE p_query || '%'
          OR c.name ILIKE '%' || p_query || '%'
          OR c.country_name_en ILIKE '%' || p_query || '%'
          OR c.country_name_tr ILIKE '%' || p_query || '%'
          OR c.country_name_ar ILIKE '%' || p_query || '%'
          OR c.native_name ILIKE '%' || p_query || '%'
      )
    ORDER BY c.sort_order ASC, c.name ASC
    LIMIT p_limit;
END;
$$;

CREATE OR REPLACE FUNCTION search_cities(
    p_country_code VARCHAR(2),
    p_query TEXT DEFAULT NULL,
    p_limit INT DEFAULT 30
)
RETURNS TABLE (
    id UUID,
    country_code VARCHAR(2),
    city_name VARCHAR(150),
    city_name_ascii VARCHAR(150),
    admin_name VARCHAR(150),
    latitude NUMERIC(10,6),
    longitude NUMERIC(10,6),
    capital_type VARCHAR(50),
    population BIGINT,
    source_id VARCHAR(50)
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ci.id,
        ci.country_code,
        COALESCE(ci.city_name, ci.name) AS city_name,
        COALESCE(ci.city_name_ascii, ci.city_name, ci.name) AS city_name_ascii,
        ci.admin_name,
        ci.latitude,
        ci.longitude,
        ci.capital_type,
        ci.population,
        ci.source_id
    FROM cities ci
    WHERE ci.is_active = TRUE
      AND (p_country_code IS NULL OR ci.country_code = UPPER(p_country_code))
      AND (
          p_query IS NULL 
          OR p_query = ''
          OR ci.city_name ILIKE p_query || '%'
          OR ci.city_name_ascii ILIKE p_query || '%'
          OR ci.name ILIKE p_query || '%'
          OR ci.admin_name ILIKE '%' || p_query || '%'
      )
    ORDER BY ci.population DESC, ci.city_name ASC
    LIMIT p_limit;
END;
$$;
