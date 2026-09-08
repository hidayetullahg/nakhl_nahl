-- ============================================================
-- 061: Global Information Center & Dashboard Preferences
-- NAKHL & NAHL Global Enterprise ERP
-- ============================================================

-- 1. Kullanıcı Dünya Saatleri Listesi
CREATE TABLE IF NOT EXISTS public.user_world_clocks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    tenant_id UUID REFERENCES public.tenants(id) ON DELETE CASCADE,
    timezone_id VARCHAR(100) NOT NULL, -- IANA e.g. 'Asia/Riyadh', 'Europe/Istanbul'
    display_name VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL,
    country VARCHAR(100) NOT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    is_favorite BOOLEAN NOT NULL DEFAULT false,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_user_tz UNIQUE (user_id, timezone_id)
);

-- 2. Piyasa Verileri ve Döviz İzleme Tercihleri
CREATE TABLE IF NOT EXISTS public.user_market_watch_preferences (
    user_id UUID PRIMARY KEY,
    tenant_id UUID REFERENCES public.tenants(id) ON DELETE CASCADE,
    watched_currency_pairs JSONB NOT NULL DEFAULT '["USD/SAR", "USD/TRY", "EUR/TRY", "EUR/SAR"]'::jsonb,
    watched_gold_instruments JSONB NOT NULL DEFAULT '["GOLD/SAR", "GOLD/TRY", "GOLD/USD"]'::jsonb,
    refresh_interval_seconds INT NOT NULL DEFAULT 300,
    calendar_mode VARCHAR(30) NOT NULL DEFAULT 'dual', -- 'gregorian', 'hijri', 'dual'
    hijri_method VARCHAR(30) NOT NULL DEFAULT 'umm_al_qura', -- 'umm_al_qura', 'calculated'
    time_format VARCHAR(10) NOT NULL DEFAULT '24h',
    show_seconds BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Piyasa Veri Snapshot Cache (Piyasa kuru != Muhasebe kuru ayrımı)
CREATE TABLE IF NOT EXISTS public.market_rate_cache (
    pair VARCHAR(30) PRIMARY KEY, -- 'USD/SAR', 'GOLD/USD'
    provider VARCHAR(100) NOT NULL,
    quote_type VARCHAR(30) NOT NULL DEFAULT 'reference_market', -- 'reference_market', 'official_central_bank', 'accounting'
    bid_rate NUMERIC(18, 6),
    ask_rate NUMERIC(18, 6),
    mid_rate NUMERIC(18, 6) NOT NULL,
    daily_change_percent NUMERIC(8, 4),
    last_updated_at TIMESTAMPTZ NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.user_world_clocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_market_watch_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.market_rate_cache ENABLE ROW LEVEL SECURITY;

CREATE POLICY p_user_world_clocks ON public.user_world_clocks FOR ALL USING (true);
CREATE POLICY p_user_market_pref ON public.user_market_watch_preferences FOR ALL USING (true);
CREATE POLICY p_read_market_cache ON public.market_rate_cache FOR SELECT USING (true);
