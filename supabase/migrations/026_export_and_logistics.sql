-- ==============================================================================
-- NAKHL & NAHL — MIGRATION 026: DIŞ TİCARET, İHRACAT VE LOJİSTİK
-- Purpose: Siparişler, Sevkiyatlar, Konteynerler, Çeki Listesi ve Gümrük Belgeleri
-- ==============================================================================

-- 1. Dış Ticaret Siparişleri (Trade Orders / Proforma Invoices)
CREATE TABLE IF NOT EXISTS trade_orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    party_id UUID NOT NULL REFERENCES cariler(id),
    order_number VARCHAR(100) NOT NULL,
    order_type VARCHAR(50) NOT NULL DEFAULT 'EXPORT', -- EXPORT, IMPORT
    incoterm VARCHAR(10) NOT NULL DEFAULT 'FOB', -- FOB, CIF, CFR, EXW, DDP
    payment_terms VARCHAR(100) DEFAULT 'CASH_AGAINST_DOCUMENTS',
    currency_code VARCHAR(5) NOT NULL DEFAULT 'USD',
    order_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expected_shipment_date DATE,
    origin_port VARCHAR(100) DEFAULT 'Cidde İslam Limanı (KSA)',
    destination_port VARCHAR(100) DEFAULT 'Mersin Uluslararası Limanı (TR)',
    total_amount NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    status VARCHAR(50) NOT NULL DEFAULT 'CONFIRMED', -- DRAFT, CONFIRMED, PROCESSING, SHIPPED, DELIVERED, CANCELLED
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_trade_order_company UNIQUE (company_id, order_number)
);

-- 2. Sipariş Kalemleri (Trade Order Lines)
CREATE TABLE IF NOT EXISTS trade_order_lines (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    trade_order_id UUID NOT NULL REFERENCES trade_orders(id) ON DELETE CASCADE,
    item_id UUID NOT NULL REFERENCES items(id),
    lot_id UUID REFERENCES item_lots(id),
    quantity NUMERIC(15,3) NOT NULL,
    unit VARCHAR(20) NOT NULL DEFAULT 'Ton',
    unit_price NUMERIC(15,2) NOT NULL,
    total_price NUMERIC(15,2) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Lojistik Sevkiyatlar (Shipments)
CREATE TABLE IF NOT EXISTS shipments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    trade_order_id UUID REFERENCES trade_orders(id) ON DELETE SET NULL,
    shipment_number VARCHAR(100) NOT NULL,
    transport_mode VARCHAR(50) NOT NULL DEFAULT 'SEA', -- SEA, ROAD, AIR
    carrier_company VARCHAR(150),
    vessel_or_plate VARCHAR(100), -- Gemi adı veya TIR Plaka No
    customs_declaration_no VARCHAR(100), -- Gümrük Beyanname No (GÇB)
    bill_of_lading_no VARCHAR(100), -- Konşimento / CMR No
    departure_date DATE NOT NULL,
    estimated_arrival_date DATE,
    actual_arrival_date DATE,
    status VARCHAR(50) NOT NULL DEFAULT 'PREPARING', -- PREPARING, AT_CUSTOMS, IN_TRANSIT, DELIVERED
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_shipment_company UNIQUE (company_id, shipment_number)
);

ALTER TABLE shipments ADD COLUMN IF NOT EXISTS port_of_loading VARCHAR(100) DEFAULT 'Jeddah Islamic Port';
ALTER TABLE shipments ADD COLUMN IF NOT EXISTS port_of_discharge VARCHAR(100) DEFAULT 'Mersin International Port';

-- 4. Konteynerler (Shipment Containers)
CREATE TABLE IF NOT EXISTS shipment_containers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    shipment_id UUID NOT NULL REFERENCES shipments(id) ON DELETE CASCADE,
    container_number VARCHAR(50) NOT NULL, -- Örn: MSKU-948123-0
    seal_number VARCHAR(50), -- Gümrük Mühür No
    container_type VARCHAR(20) DEFAULT '40_REEFER', -- 20_DRY, 40_DRY, 40_REEFER
    temperature_setting_celsius NUMERIC(5,2) DEFAULT -18.0,
    tare_weight_kg NUMERIC(10,2) DEFAULT 0.00,
    gross_weight_kg NUMERIC(10,2) DEFAULT 0.00,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. Çeki Listesi / Paketler (Shipment Packages / Packing List)
CREATE TABLE IF NOT EXISTS shipment_packages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    container_id UUID NOT NULL REFERENCES shipment_containers(id) ON DELETE CASCADE,
    item_id UUID NOT NULL REFERENCES items(id),
    lot_id UUID REFERENCES item_lots(id),
    pallet_number VARCHAR(50),
    package_count INT NOT NULL DEFAULT 1,
    net_weight_kg NUMERIC(10,2) NOT NULL,
    gross_weight_kg NUMERIC(10,2) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 6. RLS Aktifleştirme
ALTER TABLE trade_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE trade_order_lines ENABLE ROW LEVEL SECURITY;
ALTER TABLE shipments ENABLE ROW LEVEL SECURITY;
ALTER TABLE shipment_containers ENABLE ROW LEVEL SECURITY;
ALTER TABLE shipment_packages ENABLE ROW LEVEL SECURITY;

ALTER TABLE trade_orders FORCE ROW LEVEL SECURITY;
ALTER TABLE trade_order_lines FORCE ROW LEVEL SECURITY;
ALTER TABLE shipments FORCE ROW LEVEL SECURITY;
ALTER TABLE shipment_containers FORCE ROW LEVEL SECURITY;
ALTER TABLE shipment_packages FORCE ROW LEVEL SECURITY;

-- 7. RLS Politikaları
CREATE POLICY "trade_orders_select" ON trade_orders
    FOR SELECT USING (is_tenant_member(tenant_id) AND has_company_access(company_id));

CREATE POLICY "trade_orders_manage" ON trade_orders
    FOR ALL USING (is_tenant_member(tenant_id) AND has_company_access(company_id))
    WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(company_id));

CREATE POLICY "trade_order_lines_select" ON trade_order_lines
    FOR SELECT USING (is_tenant_member(tenant_id));

CREATE POLICY "trade_order_lines_manage" ON trade_order_lines
    FOR ALL USING (is_tenant_member(tenant_id))
    WITH CHECK (is_tenant_member(tenant_id));

CREATE POLICY "shipments_select" ON shipments
    FOR SELECT USING (is_tenant_member(tenant_id) AND has_company_access(company_id));

CREATE POLICY "shipments_manage" ON shipments
    FOR ALL USING (is_tenant_member(tenant_id) AND has_company_access(company_id))
    WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(company_id));

CREATE POLICY "shipment_containers_select" ON shipment_containers
    FOR SELECT USING (is_tenant_member(tenant_id));

CREATE POLICY "shipment_containers_manage" ON shipment_containers
    FOR ALL USING (is_tenant_member(tenant_id))
    WITH CHECK (is_tenant_member(tenant_id));

CREATE POLICY "shipment_packages_select" ON shipment_packages
    FOR SELECT USING (is_tenant_member(tenant_id));

CREATE POLICY "shipment_packages_manage" ON shipment_packages
    FOR ALL USING (is_tenant_member(tenant_id))
    WITH CHECK (is_tenant_member(tenant_id));

-- 8. İndeksler
CREATE INDEX IF NOT EXISTS idx_trade_orders_company ON trade_orders(company_id, order_number);
CREATE INDEX IF NOT EXISTS idx_shipments_order ON shipments(trade_order_id);
CREATE INDEX IF NOT EXISTS idx_shipment_containers_shipment ON shipment_containers(shipment_id);
CREATE INDEX IF NOT EXISTS idx_shipment_packages_container ON shipment_packages(container_id);
