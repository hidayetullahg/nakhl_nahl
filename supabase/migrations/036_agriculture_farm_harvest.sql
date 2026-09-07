-- ==============================================================================
-- NAKHL & NAHL — MIGRATION 036: AGRICULTURE / FARM / HARVEST CORE (FAZ 16)
-- Purpose:
-- 1. farms: Çiftlik / Vaha master tablosu
-- 2. fields: Tarla / Parsel yapısı
-- 3. crops: Mahsul / Hurma çeşidi ve kalite sınıfı master tablosu
-- 4. harvests: Hasat operasyonları tablosu
-- 5. item_lots: farm_id, field_id, harvest_id izlenebilirlik köprüsü
-- 6. process_farm_harvest_atomic: Hasat -> Lot -> Envanter Stok Girişi tek transaction RPC
-- 7. RLS politikaları ve indeksler
-- ==============================================================================

-- 1. ÇİFTLİK / VAHA MASTER (FARMS)
CREATE TABLE IF NOT EXISTS farms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    code VARCHAR(50) NOT NULL,
    name VARCHAR(150) NOT NULL,
    operator_party_id UUID REFERENCES parties(id) ON DELETE SET NULL,
    country_code VARCHAR(5) NOT NULL DEFAULT 'SA' REFERENCES countries(code),
    region VARCHAR(100),
    city VARCHAR(100),
    gps_coordinates VARCHAR(100),
    total_area_hectares NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    cultivation_type VARCHAR(50) NOT NULL DEFAULT 'ORGANIC', -- ORGANIC, CONVENTIONAL, BIODYNAMIC
    status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE', -- ACTIVE, INACTIVE, SUSPENDED
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_farm_company_code UNIQUE (company_id, code)
);

-- 2. TARLA / PARSEL YAPISI (FIELDS)
CREATE TABLE IF NOT EXISTS fields (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    field_code VARCHAR(50) NOT NULL,
    field_name VARCHAR(150) NOT NULL,
    area_hectares NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    soil_type VARCHAR(50) DEFAULT 'SANDY_LOAM', -- SANDY_LOAM, CLAY, ALLUVIAL
    irrigation_type VARCHAR(50) DEFAULT 'DRIP', -- DRIP, FLOOD, SPRINKLER
    tree_count INT NOT NULL DEFAULT 0,
    planting_year INT,
    status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_field_farm_code UNIQUE (farm_id, field_code)
);

ALTER TABLE fields ADD COLUMN IF NOT EXISTS code VARCHAR(50) GENERATED ALWAYS AS (field_code) STORED;

-- 3. MAHSUL / ÇEŞİT MASTER (CROPS)
CREATE TABLE IF NOT EXISTS crops (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    crop_code VARCHAR(50) NOT NULL,
    crop_name VARCHAR(100) NOT NULL DEFAULT 'HURMA', -- HURMA, DATE_PALM, ZEYTIN
    variety VARCHAR(100) NOT NULL, -- Medjoul, Sukkari, Ajwa, Mebrum, Safawi, Sagai, Barni
    grade VARCHAR(50) NOT NULL DEFAULT 'PREMIUM', -- JUMBO, PREMIUM, STANDARD, INDUSTRIAL
    growing_season VARCHAR(50) DEFAULT '2026-AUTUMN',
    item_id UUID REFERENCES items(id) ON DELETE SET NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_crop_tenant_code UNIQUE (tenant_id, crop_code)
);

-- 4. HASAT OPERASYONLARI (HARVESTS)
CREATE TABLE IF NOT EXISTS harvests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE RESTRICT,
    field_id UUID NOT NULL REFERENCES fields(id) ON DELETE RESTRICT,
    crop_id UUID NOT NULL REFERENCES crops(id) ON DELETE RESTRICT,
    harvest_number VARCHAR(100) NOT NULL,
    harvest_date DATE NOT NULL DEFAULT CURRENT_DATE,
    quantity_harvested NUMERIC(15,3) NOT NULL,
    uom VARCHAR(20) NOT NULL DEFAULT 'Kg',
    quality_grade VARCHAR(50) NOT NULL DEFAULT 'GRADE_A',
    humidity_percentage NUMERIC(5,2) DEFAULT 18.50,
    sugar_brix NUMERIC(5,2) DEFAULT 68.00,
    lot_id UUID, -- item_lots referansı aşağıda bağlanır
    warehouse_id UUID REFERENCES warehouses(id) ON DELETE RESTRICT,
    status VARCHAR(50) NOT NULL DEFAULT 'COMPLETED', -- DRAFT, COMPLETED, CANCELLED
    notes TEXT,
    created_by UUID REFERENCES public.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_harvest_company_number UNIQUE (company_id, harvest_number)
);

ALTER TABLE harvests ADD COLUMN IF NOT EXISTS harvest_lot_number VARCHAR(100) GENERATED ALWAYS AS (harvest_number) STORED;

-- 5. PARTİ / LOT İZLENEBİLİRLİK KÖPRÜSÜ (ITEM_LOTS EXPANSION)
ALTER TABLE item_lots ADD COLUMN IF NOT EXISTS farm_id UUID REFERENCES farms(id) ON DELETE SET NULL;
ALTER TABLE item_lots ADD COLUMN IF NOT EXISTS field_id UUID REFERENCES fields(id) ON DELETE SET NULL;
ALTER TABLE item_lots ADD COLUMN IF NOT EXISTS harvest_id UUID REFERENCES harvests(id) ON DELETE SET NULL;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_harvest_lot'
    ) THEN
        ALTER TABLE harvests 
        ADD CONSTRAINT fk_harvest_lot 
        FOREIGN KEY (lot_id) REFERENCES item_lots(id) ON DELETE SET NULL;
    END IF;
END $$;


-- 6. ATOMİK HASAT OPERASYONU VE STOK GİRİŞİ (RPC)
-- FARM -> FIELD -> CROP -> HARVEST -> LOT -> STOCK
CREATE OR REPLACE FUNCTION process_farm_harvest_atomic(
    p_tenant_id UUID,
    p_company_id UUID,
    p_farm_id UUID,
    p_field_id UUID,
    p_crop_id UUID,
    p_harvest_number VARCHAR(100),
    p_harvest_date DATE,
    p_quantity NUMERIC(15,3),
    p_uom VARCHAR(20),
    p_warehouse_id UUID,
    p_quality_grade VARCHAR(50) DEFAULT 'GRADE_A',
    p_humidity_percentage NUMERIC(5,2) DEFAULT 18.50,
    p_sugar_brix NUMERIC(5,2) DEFAULT 68.00,
    p_notes TEXT DEFAULT NULL,
    p_user_id UUID DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_user_id UUID;
    v_farm_name VARCHAR(150);
    v_farm_code VARCHAR(50);
    v_field_code VARCHAR(50);
    v_crop_variety VARCHAR(100);
    v_item_id UUID;
    v_harvest_id UUID;
    v_lot_id UUID;
    v_generated_lot_number VARCHAR(100);
    v_date_str VARCHAR(8);
    v_seq_no INT;
BEGIN
    -- A. Güvenlik ve Yetki Kontrolü
    IF NOT is_tenant_member(p_tenant_id) THEN
        RAISE EXCEPTION 'GÜVENLİK İHLALİ: Aktif kullanıcı bu tenant''a üye değildir!';
    END IF;

    IF NOT has_company_access(p_company_id) THEN
        RAISE EXCEPTION 'GÜVENLİK İHLALİ: Aktif kullanıcının bu şirkete işlem yetkisi yoktur!';
    END IF;

    IF p_quantity <= 0 THEN
        RAISE EXCEPTION 'GEÇERSİZ MİKTAR: Hasat miktarı 0 veya negatif olamaz! (Girilen: %)', p_quantity;
    END IF;

    v_user_id := COALESCE(p_user_id, get_current_user_id());

    -- B. Çiftlik, Parsel ve Mahsul Bilgilerini Çek
    SELECT name, code INTO v_farm_name, v_farm_code
    FROM farms
    WHERE id = p_farm_id AND company_id = p_company_id;

    IF v_farm_name IS NULL THEN
        RAISE EXCEPTION 'ÇİFTLİK BULUNAMADI: Belirtilen çiftlik mevcut değil veya bu şirkete ait değil!';
    END IF;

    SELECT field_code INTO v_field_code
    FROM fields
    WHERE id = p_field_id AND farm_id = p_farm_id;

    IF v_field_code IS NULL THEN
        RAISE EXCEPTION 'PARSEL BULUNAMADI: Belirtilen parsel bu çiftliğe ait değil!';
    END IF;

    SELECT variety, item_id INTO v_crop_variety, v_item_id
    FROM crops
    WHERE id = p_crop_id;

    IF v_crop_variety IS NULL THEN
        RAISE EXCEPTION 'MAHSUL BULUNAMADI: Belirtilen hurma çeşidi/mahsul mevcut değil!';
    END IF;

    -- Eğer crop doğrudan bir item_id'ye bağlı değilse, hurma çeşidine göre items tablosundan bul
    IF v_item_id IS NULL THEN
        SELECT id INTO v_item_id
        FROM items
        WHERE company_id = p_company_id
          AND (item_name ILIKE '%' || v_crop_variety || '%' OR category_name = 'Hurma')
        LIMIT 1;

        IF v_item_id IS NULL THEN
            RAISE EXCEPTION 'ÜRÜN KARTI EŞLEŞTİRİLEMEDİ: "%" mahsulü için şirkete ait stok kartı (items) bulunamadı!', v_crop_variety;
        END IF;
    END IF;

    -- C. Hasat Parti (Lot) Numarası Üretimi
    -- Format: LOT-HRV-{FARM_CODE}-{FIELD_CODE}-{YYYYMMDD}-{SEQ}
    v_date_str := TO_CHAR(p_harvest_date, 'YYYYMMDD');
    SELECT COUNT(*) + 1 INTO v_seq_no
    FROM harvests
    WHERE farm_id = p_farm_id AND harvest_date = p_harvest_date;

    v_generated_lot_number := 'LOT-HRV-' || v_farm_code || '-' || v_field_code || '-' || v_date_str || '-' || LPAD(v_seq_no::TEXT, 2, '0');

    -- D. Hasat Kaydı (harvests)
    INSERT INTO harvests (
        tenant_id, company_id, farm_id, field_id, crop_id,
        harvest_number, harvest_date, quantity_harvested, uom,
        quality_grade, humidity_percentage, sugar_brix,
        warehouse_id, status, notes, created_by
    ) VALUES (
        p_tenant_id, p_company_id, p_farm_id, p_field_id, p_crop_id,
        p_harvest_number, p_harvest_date, p_quantity, p_uom,
        p_quality_grade, p_humidity_percentage, p_sugar_brix,
        p_warehouse_id, 'COMPLETED', p_notes, v_user_id
    ) RETURNING id INTO v_harvest_id;

    -- E. Parti / Lot Kaydı (item_lots) - Derin Değer Zinciri ve İzlenebilirlik
    INSERT INTO item_lots (
        tenant_id, company_id, item_id, lot_number,
        farm_name, farm_id, field_id, harvest_id,
        harvest_date, harvest_batch_number,
        packaging_type, temperature_control_required, target_storage_temp_celsius,
        country_of_origin, production_date, expiration_date,
        halal_certified, quality_status, notes
    ) VALUES (
        p_tenant_id, p_company_id, v_item_id, v_generated_lot_number,
        v_farm_name, p_farm_id, p_field_id, v_harvest_id,
        p_harvest_date, p_harvest_number,
        'CRATE', TRUE, -18.00,
        'SA', p_harvest_date, p_harvest_date + INTERVAL '2 years',
        TRUE, 'APPROVED',
        CONCAT('Hasat: ', p_harvest_number, ' - Parsel: ', v_field_code, ' - Nem: %', p_humidity_percentage, ' - Briks: ', p_sugar_brix)
    ) RETURNING id INTO v_lot_id;

    -- Hasat kaydına lot_id bağla
    UPDATE harvests SET lot_id = v_lot_id WHERE id = v_harvest_id;

    -- F. Envanter Girişi (stock_ledger_entries: PRODUCTION / IN)
    -- Hasat sonucu depoya mamul/hammadde girişi yapılır
    INSERT INTO stock_ledger_entries (
        tenant_id, company_id, warehouse_id, item_id, lot_id,
        movement_type, quantity, direction, unit, unit_cost, total_cost,
        document_type, document_reference, description, created_by
    ) VALUES (
        p_tenant_id, p_company_id, p_warehouse_id, v_item_id, v_lot_id,
        'PRODUCTION', p_quantity, 'IN', p_uom, 0.0000, 0.0000,
        'HARVEST_SLIP', p_harvest_number,
        CONCAT('Zirai Hasat Depo Girişi: ', p_harvest_number, ' - Lot: ', v_generated_lot_number),
        v_user_id
    );

    -- G. Audit Log Kaydı
    INSERT INTO audit_logs (
        tenant_id, user_id, company_id, action, entity_type, entity_id, new_data
    ) VALUES (
        p_tenant_id, v_user_id, p_company_id, 'CREATE', 'farm_harvest', v_harvest_id,
        jsonb_build_object(
            'harvest_number', p_harvest_number,
            'lot_number', v_generated_lot_number,
            'farm_name', v_farm_name,
            'field_code', v_field_code,
            'quantity', p_quantity,
            'warehouse_id', p_warehouse_id
        )
    );

    RETURN jsonb_build_object(
        'success', true,
        'harvest_id', v_harvest_id,
        'lot_id', v_lot_id,
        'lot_number', v_generated_lot_number,
        'farm_name', v_farm_name,
        'quantity', p_quantity
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;


-- 7. RLS VE İNDEKSLER
ALTER TABLE farms ENABLE ROW LEVEL SECURITY;
ALTER TABLE fields ENABLE ROW LEVEL SECURITY;
ALTER TABLE crops ENABLE ROW LEVEL SECURITY;
ALTER TABLE harvests ENABLE ROW LEVEL SECURITY;

ALTER TABLE farms FORCE ROW LEVEL SECURITY;
ALTER TABLE fields FORCE ROW LEVEL SECURITY;
ALTER TABLE crops FORCE ROW LEVEL SECURITY;
ALTER TABLE harvests FORCE ROW LEVEL SECURITY;

CREATE POLICY "farms_select" ON farms
    FOR SELECT USING (is_tenant_member(tenant_id) AND has_company_access(company_id));

CREATE POLICY "farms_manage" ON farms
    FOR ALL USING (is_tenant_member(tenant_id) AND has_company_access(company_id))
    WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(company_id));

CREATE POLICY "fields_select" ON fields
    FOR SELECT USING (is_tenant_member(tenant_id) AND has_company_access(company_id));

CREATE POLICY "fields_manage" ON fields
    FOR ALL USING (is_tenant_member(tenant_id) AND has_company_access(company_id))
    WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(company_id));

CREATE POLICY "crops_select" ON crops
    FOR SELECT USING (is_tenant_member(tenant_id));

CREATE POLICY "crops_manage" ON crops
    FOR ALL USING (is_tenant_admin(tenant_id))
    WITH CHECK (is_tenant_admin(tenant_id));

CREATE POLICY "harvests_select" ON harvests
    FOR SELECT USING (is_tenant_member(tenant_id) AND has_company_access(company_id));

CREATE POLICY "harvests_manage" ON harvests
    FOR ALL USING (is_tenant_member(tenant_id) AND has_company_access(company_id))
    WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(company_id));

CREATE INDEX IF NOT EXISTS idx_farms_tenant_comp ON farms(tenant_id, company_id);
CREATE INDEX IF NOT EXISTS idx_fields_farm ON fields(farm_id);
CREATE INDEX IF NOT EXISTS idx_harvests_farm_date ON harvests(farm_id, harvest_date DESC);
CREATE INDEX IF NOT EXISTS idx_item_lots_harvest ON item_lots(harvest_id);
CREATE INDEX IF NOT EXISTS idx_item_lots_farm ON item_lots(farm_id);
