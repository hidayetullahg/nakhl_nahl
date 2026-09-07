-- ==============================================================================
-- NAKHL & NAHL — MIGRATION 027: DİL VE YAZI SİSTEMİ (SCRIPT DECOUPLING)
-- Purpose: languages, scripts, locales (ug-Arab, ug-Latn, tr-Latn, tr-Arab, ota-Arab) ve ui_translations
-- ==============================================================================

-- 1. Diller (Languages)
CREATE TABLE IF NOT EXISTS languages (
    code VARCHAR(10) PRIMARY KEY, -- tr, ar, en, ug, ota, fa, zh, uz
    english_name VARCHAR(100) NOT NULL,
    native_name VARCHAR(100) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- 2. Yazı Sistemleri / Alfabeler (Scripts)
CREATE TABLE IF NOT EXISTS scripts (
    code VARCHAR(10) PRIMARY KEY, -- Latn, Arab, Hans, Cyrl
    name VARCHAR(100) NOT NULL,
    default_direction VARCHAR(5) NOT NULL DEFAULT 'ltr', -- ltr, rtl
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- 3. Kombinasyon ve Tipografi (Locales)
CREATE TABLE IF NOT EXISTS locales (
    locale_id VARCHAR(20) PRIMARY KEY, -- tr-Latn, tr-Arab, ug-Arab, ug-Latn, ota-Arab, en-Latn, ar-Arab
    language_code VARCHAR(10) NOT NULL REFERENCES languages(code),
    script_code VARCHAR(10) NOT NULL REFERENCES scripts(code),
    direction VARCHAR(5) NOT NULL DEFAULT 'ltr', -- ltr, rtl
    primary_font VARCHAR(100) NOT NULL,
    fallback_font VARCHAR(100),
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- 4. Dinamik Arayüz Çevirileri (UI Translations)
CREATE TABLE IF NOT EXISTS ui_translations (
    translation_key VARCHAR(150) NOT NULL,
    locale_id VARCHAR(20) NOT NULL REFERENCES locales(locale_id) ON DELETE CASCADE,
    translation_value TEXT NOT NULL,
    PRIMARY KEY (translation_key, locale_id)
);

-- 5. Başlangıç Dilleri (Seed Data)
INSERT INTO languages (code, english_name, native_name)
VALUES
    ('tr', 'Turkish', 'Türkçe'),
    ('ar', 'Arabic', 'العربية'),
    ('en', 'English', 'English'),
    ('ug', 'Uyghur', 'ئۇيغۇرچە / Uyghurche'),
    ('ota', 'Ottoman Turkish', 'لسان عثمانی / Osmanlıca'),
    ('fa', 'Persian', 'فارسی'),
    ('zh', 'Chinese', '中文')
ON CONFLICT (code) DO NOTHING;

-- 6. Başlangıç Yazı Sistemleri (Seed Data)
INSERT INTO scripts (code, name, default_direction)
VALUES
    ('Latn', 'Latin Alfabesi', 'ltr'),
    ('Arab', 'Arap Harfli Yazı Sistemi', 'rtl'),
    ('Hans', 'Basitleştirilmiş Çin Yazısı', 'ltr'),
    ('Cyrl', 'Kiril Alfabesi', 'ltr')
ON CONFLICT (code) DO NOTHING;

-- 7. 7 Çekirdek Kombinasyon (Seed Data)
INSERT INTO locales (locale_id, language_code, script_code, direction, primary_font, fallback_font)
VALUES
    ('tr-Latn', 'tr', 'Latn', 'ltr', 'Inter', 'Roboto'),
    ('tr-Arab', 'tr', 'Arab', 'rtl', 'Amiri', 'Scheherazade New'),
    ('ug-Arab', 'ug', 'Arab', 'rtl', 'Noto Naskh Arabic', 'Amiri'),
    ('ug-Latn', 'ug', 'Latn', 'ltr', 'Inter', 'Roboto'),
    ('ar-Arab', 'ar', 'Arab', 'rtl', 'Amiri', 'Cairo'),
    ('en-Latn', 'en', 'Latn', 'ltr', 'Inter', 'Roboto'),
    ('ota-Arab', 'ota', 'Arab', 'rtl', 'Amiri', 'Scheherazade New')
ON CONFLICT (locale_id) DO NOTHING;

-- 8. Örnek Temel Çeviriler (Seed Data)
INSERT INTO ui_translations (translation_key, locale_id, translation_value)
VALUES
    -- tr-Latn
    ('app.title', 'tr-Latn', 'NAKHL & NAHL — Küresel SaaS ERP'),
    ('menu.dashboard', 'tr-Latn', 'Yönetim Paneli'),
    ('menu.accounting', 'tr-Latn', 'Muhasebe & Finans'),
    ('menu.inventory', 'tr-Latn', 'Stok & Depo'),
    ('menu.halal', 'tr-Latn', 'Helal & Kalite'),
    ('menu.export', 'tr-Latn', 'Dış Ticaret & İhracat'),
    
    -- ar-Arab
    ('app.title', 'ar-Arab', 'نخل ونحل — نظام تخطيط موارد المؤسسات العالمي'),
    ('menu.dashboard', 'ar-Arab', 'لوحة القيادة'),
    ('menu.accounting', 'ar-Arab', 'المحاسبة والمالية'),
    ('menu.inventory', 'ar-Arab', 'المخزون والمستودعات'),
    ('menu.halal', 'ar-Arab', 'الحلال والجودة'),
    ('menu.export', 'ar-Arab', 'التجارة الخارجية والتصدير'),

    -- ug-Arab
    ('app.title', 'ug-Arab', 'نەخل ۋە نەھل — دۇنياۋى كارخانا باشقۇرۇش سىستېمىسى'),
    ('menu.dashboard', 'ug-Arab', 'باشقۇرۇش كۆزنىكى'),
    ('menu.accounting', 'ug-Arab', 'مالىيە ۋە ھېسابات'),
    ('menu.inventory', 'ug-Arab', 'ئامبار ۋە زاپاس'),
    ('menu.halal', 'ug-Arab', 'ھالال ۋە سۈپەت'),
    ('menu.export', 'ug-Arab', 'تاشقى سودا ۋە ئېكسپورت'),

    -- ug-Latn
    ('app.title', 'ug-Latn', 'Nakhl & Nahl — Dunyawi Karkhana Bashqurush Sistémisi'),
    ('menu.dashboard', 'ug-Latn', 'Bashqurush Közniki'),
    ('menu.accounting', 'ug-Latn', 'Maliye we Hésabat'),
    ('menu.inventory', 'ug-Latn', 'Ambar we Zapas'),
    ('menu.halal', 'ug-Latn', 'Halal we Süpet'),
    ('menu.export', 'ug-Latn', 'Tashqi Soda we Éksport'),

    -- ota-Arab
    ('app.title', 'ota-Arab', 'نخل و نحل — نظام ضبط تجارت عمومی'),
    ('menu.dashboard', 'ota-Arab', 'دیوان ضبط'),
    ('menu.accounting', 'ota-Arab', 'محاسبه و مالیه'),
    ('menu.inventory', 'ota-Arab', 'انبار و ذخیره'),
    ('menu.halal', 'ota-Arab', 'حلال و نظافت'),
    ('menu.export', 'ota-Arab', 'خارجه تجارت و ارسال')
ON CONFLICT (translation_key, locale_id) DO NOTHING;

-- 9. İndeksler
CREATE INDEX IF NOT EXISTS idx_locales_lang ON locales(language_code);
CREATE INDEX IF NOT EXISTS idx_locales_script ON locales(script_code);
CREATE INDEX IF NOT EXISTS idx_ui_trans_locale ON ui_translations(locale_id);
