-- ============================================================
-- 059: Çoklu Dil, Alfabe ve Hibrit Lokalizasyon Tabloları
-- NAKHL & NAHL Global Enterprise ERP
-- ============================================================

-- 1. Desteklenen Diller ve Alfabeler (Scripts)
CREATE TABLE IF NOT EXISTS public.supported_scripts (
    code VARCHAR(10) PRIMARY KEY, -- 'Latn', 'Arab'
    name VARCHAR(50) NOT NULL,
    direction VARCHAR(5) NOT NULL DEFAULT 'ltr', -- 'ltr', 'rtl'
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO public.supported_scripts (code, name, direction) VALUES
('Latn', 'Latin Alfabesi', 'ltr'),
('Arab', 'Arap Alfabesi', 'rtl')
ON CONFLICT (code) DO NOTHING;

-- 2. Sistem Locale Tanımları (tr-Latn, en-Latn, ar-Arab, ar-Latn, ug-Arab, ug-Latn, ota-Arab)
CREATE TABLE IF NOT EXISTS public.system_locales (
    code VARCHAR(20) PRIMARY KEY, -- 'tr-Latn', 'ar-Arab', 'ar-Latn', etc.
    language_code VARCHAR(10) NOT NULL,
    script_code VARCHAR(10) NOT NULL REFERENCES public.supported_scripts(code),
    native_name VARCHAR(100) NOT NULL,
    direction VARCHAR(5) NOT NULL DEFAULT 'ltr',
    is_active BOOLEAN NOT NULL DEFAULT true,
    is_default BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO public.system_locales (code, language_code, script_code, native_name, direction, is_active, is_default) VALUES
('tr-Latn', 'tr', 'Latn', 'Türkçe', 'ltr', true, true),
('en-Latn', 'en', 'Latn', 'English', 'ltr', true, false),
('ar-Arab', 'ar', 'Arab', 'العربية (Arapça)', 'rtl', true, false),
('ar-Latn', 'ar', 'Latn', 'Arabizi / Latinize Arapça', 'ltr', true, false),
('ug-Arab', 'ug', 'Arab', 'ئۇيغۇرچە (Uygurca)', 'rtl', true, false),
('ug-Latn', 'ug', 'Latn', 'Uyghurche (Latin)', 'ltr', true, false),
('ota-Arab', 'ota', 'Arab', 'لسان عثمانی (Osmanlıca)', 'rtl', true, false)
ON CONFLICT (code) DO NOTHING;

-- 3. Kurumsal Terminoloji ve Çeviri Kayıtları (Doğrulanmış & Makine Çevirisi Ayrımı)
CREATE TABLE IF NOT EXISTS public.enterprise_translations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    translation_key VARCHAR(100) NOT NULL,
    locale_code VARCHAR(20) NOT NULL REFERENCES public.system_locales(code),
    translated_text TEXT NOT NULL,
    is_verified BOOLEAN NOT NULL DEFAULT false,
    verified_by VARCHAR(100),
    verified_at TIMESTAMPTZ,
    version INT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_translation_key_locale UNIQUE (translation_key, locale_code)
);

CREATE INDEX IF NOT EXISTS idx_trans_key ON public.enterprise_translations(translation_key);
CREATE INDEX IF NOT EXISTS idx_trans_locale ON public.enterprise_translations(locale_code);

-- 4. Kullanıcı Çokdilli Dil Tercihleri (Primary, Secondary, Tertiary, Hybrid Mode)
CREATE TABLE IF NOT EXISTS public.user_multilingual_preferences (
    user_id UUID PRIMARY KEY,
    tenant_id UUID REFERENCES public.tenants(id) ON DELETE CASCADE,
    primary_locale VARCHAR(20) NOT NULL DEFAULT 'tr-Latn' REFERENCES public.system_locales(code),
    secondary_locale VARCHAR(20) DEFAULT 'ar-Arab' REFERENCES public.system_locales(code),
    tertiary_locale VARCHAR(20) DEFAULT 'en-Latn' REFERENCES public.system_locales(code),
    display_mode VARCHAR(30) NOT NULL DEFAULT 'single_language', -- 'single_language', 'multilingual_hybrid'
    ar_lat_enabled BOOLEAN NOT NULL DEFAULT true,
    font_size_level VARCHAR(20) NOT NULL DEFAULT 'medium', -- 'small', 'medium', 'large', 'extra_large'
    high_contrast BOOLEAN NOT NULL DEFAULT false,
    reduced_motion BOOLEAN NOT NULL DEFAULT false,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.supported_scripts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.system_locales ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.enterprise_translations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_multilingual_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY p_read_scripts ON public.supported_scripts FOR SELECT USING (true);
CREATE POLICY p_read_locales ON public.system_locales FOR SELECT USING (true);
CREATE POLICY p_read_translations ON public.enterprise_translations FOR SELECT USING (true);
CREATE POLICY p_user_multi_pref ON public.user_multilingual_preferences FOR ALL USING (true);
