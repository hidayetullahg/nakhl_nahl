-- ==============================================================================
-- NAKHL & NAHL — MIGRATION 022: CARİ KARTLAR VE HESAP PLANI ENTEGRASYONU
-- Purpose: 70+ kurumsal ERP alanını içeren cariler tablosu ve RLS izolasyonu.
-- ==============================================================================

CREATE TABLE IF NOT EXISTS cariler (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID REFERENCES companies(id) ON DELETE SET NULL,
    
    -- 1. Temel & Kimlik Bilgileri
    cari_kodu VARCHAR(100) NOT NULL,
    unvan VARCHAR(255) NOT NULL,
    cari_tipi VARCHAR(50) NOT NULL DEFAULT 'Musteri', -- Musteri, Tedarikci, AliciSatici, Personel, Ortak, Broker
    cari_grubu VARCHAR(50) NOT NULL DEFAULT 'Genel',  -- Toptanci, Perakendeci, YurtDisi, Uretici
    ozel_kod1 VARCHAR(50),
    ozel_kod2 VARCHAR(50),

    -- 2. Yasal ve Vergi Bilgileri
    vergi_dairesi VARCHAR(100),
    vergi_no VARCHAR(50),
    tckn VARCHAR(20),
    e_fatura_mukellefi BOOLEAN NOT NULL DEFAULT FALSE,
    e_fatura_senaryosu VARCHAR(50) DEFAULT 'Temel',
    e_fatura_alias VARCHAR(150),
    mersis_no VARCHAR(50),
    ticaret_sicil_no VARCHAR(50),
    ulke_kodu VARCHAR(5) NOT NULL DEFAULT 'SA',
    ulke_adi VARCHAR(100) NOT NULL DEFAULT 'Suudi Arabistan',
    vergi_tipi VARCHAR(50) DEFAULT 'TRN',
    kdv_orani VARCHAR(20) DEFAULT '%15',

    -- 3. İletişim ve Adres
    fatura_adresi TEXT,
    sevk_adresi TEXT,
    sirket_telefonu VARCHAR(50),
    cep_telefonu VARCHAR(50),
    alternatif_telefon VARCHAR(50),
    eposta citext,
    eposta2 citext,
    web_sitesi VARCHAR(150),
    sehir VARCHAR(100),
    ilce VARCHAR(100),
    posta_kodu VARCHAR(20),
    lokasyon VARCHAR(255),

    -- 4. Finansal ve Muhasebe Bilgileri
    para_birimi VARCHAR(5) NOT NULL DEFAULT 'SAR',
    muhasebe_kodu VARCHAR(50) DEFAULT '120.01.001',
    banka_adi VARCHAR(150),
    banka_sube VARCHAR(100),
    iban VARCHAR(50),
    iban2 VARCHAR(50),
    swift_kodu VARCHAR(50),
    kdv_muaf BOOLEAN NOT NULL DEFAULT FALSE,
    kdv_muafiyet_kodu VARCHAR(50),
    tevkifat_kodu VARCHAR(50),

    -- 5. Ticari ve Risk Yönetimi
    risk_limiti NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    risk_kontrol_tipi VARCHAR(50) NOT NULL DEFAULT 'Uyar', -- Durdur, Uyar, Serbest
    teminat_tutari NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    teminat_detayi TEXT,
    vade_gunu INT NOT NULL DEFAULT 30,
    fiyat_listesi VARCHAR(50) DEFAULT 'Standart',
    iskonto_orani NUMERIC(5,2) DEFAULT 0.00,
    odeme_plani VARCHAR(50) DEFAULT 'Havale',

    -- 6. Kurumsal Yetkili
    yetkili_kisi VARCHAR(150),
    yetkili_unvan VARCHAR(100),
    departman VARCHAR(100),
    plasiyer VARCHAR(100),
    aktif_mi BOOLEAN NOT NULL DEFAULT TRUE,

    -- 7. Takip & Meta
    notlar TEXT,
    kayit_dili VARCHAR(10) DEFAULT 'TR',
    olusturma_tarihi TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    guncelleme_tarihi TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_cari_tenant_kod UNIQUE (tenant_id, cari_kodu)
);

-- RLS Aktifleştirme
ALTER TABLE cariler ENABLE ROW LEVEL SECURITY;
ALTER TABLE cariler FORCE ROW LEVEL SECURITY;

-- RLS Politikaları
CREATE POLICY "cariler_select" ON cariler
    FOR SELECT USING (is_tenant_member(tenant_id));

CREATE POLICY "cariler_insert" ON cariler
    FOR INSERT WITH CHECK (is_tenant_member(tenant_id));

CREATE POLICY "cariler_update" ON cariler
    FOR UPDATE USING (is_tenant_member(tenant_id))
    WITH CHECK (is_tenant_member(tenant_id));

CREATE POLICY "cariler_delete_admin" ON cariler
    FOR DELETE USING (is_tenant_admin(tenant_id));

-- İndeksler
CREATE INDEX IF NOT EXISTS idx_cariler_tenant_id ON cariler(tenant_id);
CREATE INDEX IF NOT EXISTS idx_cariler_company_id ON cariler(company_id);
CREATE INDEX IF NOT EXISTS idx_cariler_unvan ON cariler(tenant_id, unvan);
CREATE INDEX IF NOT EXISTS idx_cariler_cari_tipi ON cariler(tenant_id, cari_tipi);
