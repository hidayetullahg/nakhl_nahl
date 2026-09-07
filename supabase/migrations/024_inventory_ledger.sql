-- ==============================================================================
-- NAKHL & NAHL — MIGRATION 024: STOK HAREKET DEFTERİ VE PARTİ/LOT TAKİBİ
-- Purpose: items, item_lots, stock_ledger_entries ve stok defteri immutability
-- ==============================================================================

-- 1. Stok Kartları (Items / Products)
CREATE TABLE IF NOT EXISTS items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    item_code VARCHAR(100) NOT NULL DEFAULT 'TEMP-CODE',
    item_name VARCHAR(255) NOT NULL DEFAULT 'Temp Item',
    category_name VARCHAR(100) DEFAULT 'Hurma',
    base_unit VARCHAR(20) NOT NULL DEFAULT 'Kg', -- Kg, Ton, Koli, Palet
    tracking_type VARCHAR(50) NOT NULL DEFAULT 'LOT_BASED', -- LOT_BASED, SERIAL_BASED, NONE
    default_vat_rate NUMERIC(5,2) DEFAULT 15.00,
    min_stock_level NUMERIC(15,3) DEFAULT 0.000,
    name VARCHAR(255),
    sku VARCHAR(100),
    unit_of_measure VARCHAR(20) DEFAULT 'Kg',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_item_company_code UNIQUE (company_id, item_code)
);

CREATE OR REPLACE FUNCTION sync_item_sku_name()
RETURNS TRIGGER AS $$
BEGIN
    IF (NEW.item_name = 'Temp Item' OR NEW.item_name IS NULL) AND NEW.name IS NOT NULL THEN
        NEW.item_name := NEW.name;
    ELSIF NEW.name IS NULL AND NEW.item_name IS NOT NULL THEN
        NEW.name := NEW.item_name;
    END IF;

    IF (NEW.item_code = 'TEMP-CODE' OR NEW.item_code IS NULL) AND NEW.sku IS NOT NULL THEN
        NEW.item_code := NEW.sku;
    ELSIF NEW.sku IS NULL AND NEW.item_code IS NOT NULL THEN
        NEW.sku := NEW.item_code;
    END IF;

    IF NEW.base_unit IS NULL AND NEW.unit_of_measure IS NOT NULL THEN
        NEW.base_unit := NEW.unit_of_measure;
    ELSIF NEW.unit_of_measure IS NULL AND NEW.base_unit IS NOT NULL THEN
        NEW.unit_of_measure := NEW.base_unit;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sync_item_sku_name ON items;
CREATE TRIGGER trg_sync_item_sku_name
BEFORE INSERT OR UPDATE ON items
FOR EACH ROW EXECUTE FUNCTION sync_item_sku_name();

-- 2. Parti ve Lot Kayıtları (Item Lots)
CREATE TABLE IF NOT EXISTS item_lots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    item_id UUID NOT NULL REFERENCES items(id) ON DELETE CASCADE,
    lot_number VARCHAR(100) NOT NULL,
    production_date DATE,
    expiration_date DATE,
    country_of_origin VARCHAR(5) DEFAULT 'SA',
    quality_status VARCHAR(50) NOT NULL DEFAULT 'APPROVED', -- QUARANTINE, APPROVED, REJECTED, HOLD
    halal_certified BOOLEAN NOT NULL DEFAULT TRUE,
    halal_certificate_number VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_lot_company_number UNIQUE (company_id, item_id, lot_number)
);

-- 3. Stok Hareket Defteri (Stock Ledger Entries - Append-Only)
CREATE TABLE IF NOT EXISTS stock_ledger_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    warehouse_id UUID NOT NULL REFERENCES warehouses(id) ON DELETE RESTRICT,
    location_id UUID REFERENCES warehouse_locations(id) ON DELETE SET NULL,
    item_id UUID NOT NULL REFERENCES items(id) ON DELETE RESTRICT,
    lot_id UUID REFERENCES item_lots(id) ON DELETE SET NULL,
    
    movement_type VARCHAR(50) NOT NULL, 
    -- PURCHASE_RECEIPT, SALES_ISSUE, TRANSFER_IN, TRANSFER_OUT, 
    -- COUNT_POSITIVE, COUNT_NEGATIVE, SCRAP_FIRE, PRODUCTION_IN, PRODUCTION_OUT, RETURN
    
    quantity NUMERIC(15,3) NOT NULL, -- Girişler pozitif, çıkışlar negatif
    unit VARCHAR(20) NOT NULL DEFAULT 'Kg',
    unit_cost NUMERIC(18,4) NOT NULL DEFAULT 0.0000,
    total_cost NUMERIC(18,4) NOT NULL DEFAULT 0.0000,
    
    document_type VARCHAR(50) NOT NULL, -- INVOICE, SHIPMENT, COUNT_SHEET, TRANSFER_ORDER
    document_reference VARCHAR(100),
    description TEXT,
    created_by UUID REFERENCES public.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. Stok Defteri Değiştirilemezlik (Immutability) Tetikleyicisi
CREATE OR REPLACE FUNCTION prevent_stock_ledger_modification()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'Stok hareket defteri (stock_ledger_entries) kayıtları kesinlikle silinemez veya güncellenemez! Hatalar için ters hareket fişi açılmalıdır.';
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_prevent_stock_ledger_modification ON stock_ledger_entries;
CREATE TRIGGER trg_prevent_stock_ledger_modification
BEFORE UPDATE OR DELETE ON stock_ledger_entries
FOR EACH ROW EXECUTE FUNCTION prevent_stock_ledger_modification();

-- 5. Anlık Stok Bakiyesi View'ı (Hesaplanan Gerçek Bakiye)
CREATE OR REPLACE VIEW view_current_stock AS
SELECT 
    tenant_id,
    company_id,
    warehouse_id,
    item_id,
    lot_id,
    SUM(quantity) AS current_quantity,
    unit,
    MAX(created_at) AS last_movement_at
FROM stock_ledger_entries
GROUP BY tenant_id, company_id, warehouse_id, item_id, lot_id, unit;

-- 6. RLS Aktifleştirme
ALTER TABLE items ENABLE ROW LEVEL SECURITY;
ALTER TABLE item_lots ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_ledger_entries ENABLE ROW LEVEL SECURITY;

ALTER TABLE items FORCE ROW LEVEL SECURITY;
ALTER TABLE item_lots FORCE ROW LEVEL SECURITY;
ALTER TABLE stock_ledger_entries FORCE ROW LEVEL SECURITY;

-- 7. RLS Politikaları
CREATE POLICY "items_select" ON items
    FOR SELECT USING (is_tenant_member(tenant_id) AND has_company_access(company_id));

CREATE POLICY "items_manage" ON items
    FOR ALL USING (is_tenant_member(tenant_id) AND has_company_access(company_id))
    WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(company_id));

CREATE POLICY "item_lots_select" ON item_lots
    FOR SELECT USING (is_tenant_member(tenant_id) AND has_company_access(company_id));

CREATE POLICY "item_lots_manage" ON item_lots
    FOR ALL USING (is_tenant_member(tenant_id) AND has_company_access(company_id))
    WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(company_id));

CREATE POLICY "stock_ledger_select" ON stock_ledger_entries
    FOR SELECT USING (is_tenant_member(tenant_id) AND has_company_access(company_id));

CREATE POLICY "stock_ledger_insert" ON stock_ledger_entries
    FOR INSERT WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(company_id));

-- 8. İndeksler
CREATE INDEX IF NOT EXISTS idx_items_tenant_comp ON items(tenant_id, company_id);
CREATE INDEX IF NOT EXISTS idx_item_lots_item ON item_lots(item_id, lot_number);
CREATE INDEX IF NOT EXISTS idx_stock_ledger_item ON stock_ledger_entries(item_id, warehouse_id);
CREATE INDEX IF NOT EXISTS idx_stock_ledger_lot ON stock_ledger_entries(lot_id);
CREATE INDEX IF NOT EXISTS idx_stock_ledger_created ON stock_ledger_entries(created_at DESC);
