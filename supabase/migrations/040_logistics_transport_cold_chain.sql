-- ==============================================================================
-- NAKHL & NAHL — MIGRATION 040: LOGISTICS & TRANSPORT BOUNDED CONTEXT (FAZ 20)
-- Purpose:
-- 1. vehicles: Araç master tablosu (plaka, tip, taşıyıcı cari, kapasite, reefer aralığı)
-- 2. drivers: Sürücü kayıtları (ehliyet, taşıyıcı, kimlik)
-- 3. transport_orders: Sevk / nakliye emirleri (pickup, delivery, route, shipment)
-- 4. transport_order_items: Nakliye kalemleri ve zorunlu lot izlenebilirliği
-- 5. cold_chain_temperature_logs: Sıcaklık sensör logları ve otomatik sapma tetikleyicisi
-- 6. view_transport_lot_traceability: LOT -> VEHICLE -> TRANSPORT -> WAREHOUSE -> SHIPMENT
-- 7. RLS Politikaları ve İndeksler
-- ==============================================================================

-- 1. ARAÇLAR (VEHICLES MASTER)
CREATE TABLE IF NOT EXISTS vehicles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    carrier_party_id UUID NOT NULL REFERENCES parties(id) ON DELETE RESTRICT,
    registration_plate VARCHAR(50) NOT NULL, -- Örn: '4321-JED', '34-NAK-2026'
    vehicle_type VARCHAR(50) NOT NULL DEFAULT 'REEFER_TRUCK'
        CHECK (vehicle_type IN ('REEFER_TRUCK', 'DRY_TRUCK', 'TRAILER', 'VAN', 'CONTAINER_CHASSIS')),
    capacity_payload_kg NUMERIC(12,2) NOT NULL DEFAULT 20000.00,
    capacity_volume_cbm NUMERIC(10,2) DEFAULT 60.00,
    is_temperature_controlled BOOLEAN NOT NULL DEFAULT TRUE,
    min_temp_celsius NUMERIC(5,2) DEFAULT -25.00,
    max_temp_celsius NUMERIC(5,2) DEFAULT 10.00,
    status VARCHAR(50) NOT NULL DEFAULT 'AVAILABLE'
        CHECK (status IN ('AVAILABLE', 'ON_ROUTE', 'MAINTENANCE', 'INACTIVE')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_vehicle_tenant_plate UNIQUE (tenant_id, registration_plate)
);

ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS plate_number VARCHAR(50) GENERATED ALWAYS AS (registration_plate) STORED;

-- 2. SÜRÜCÜLER (DRIVERS MASTER)
CREATE TABLE IF NOT EXISTS drivers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    carrier_party_id UUID NOT NULL REFERENCES parties(id) ON DELETE RESTRICT,
    full_name VARCHAR(150) NOT NULL,
    license_number VARCHAR(100) NOT NULL,
    phone_number VARCHAR(50),
    national_id VARCHAR(50),
    status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE'
        CHECK (status IN ('ACTIVE', 'ON_TRIP', 'OFF_DUTY', 'SUSPENDED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_driver_tenant_license UNIQUE (tenant_id, license_number)
);

-- 3. TAŞIMA EMİRLERİ (TRANSPORT ORDERS)
CREATE TABLE IF NOT EXISTS transport_orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    transport_order_number VARCHAR(100) NOT NULL,
    shipment_id UUID REFERENCES shipments(id) ON DELETE SET NULL,
    export_file_id UUID REFERENCES export_files(id) ON DELETE SET NULL,
    carrier_party_id UUID NOT NULL REFERENCES parties(id) ON DELETE RESTRICT,
    vehicle_id UUID REFERENCES vehicles(id) ON DELETE SET NULL,
    driver_id UUID REFERENCES drivers(id) ON DELETE SET NULL,
    
    -- Yükleme Noktası (Pickup)
    pickup_location_type VARCHAR(50) NOT NULL DEFAULT 'WAREHOUSE'
        CHECK (pickup_location_type IN ('FARM', 'FACTORY', 'WAREHOUSE', 'PORT')),
    pickup_warehouse_id UUID REFERENCES warehouses(id) ON DELETE SET NULL,
    pickup_address TEXT NOT NULL,
    pickup_time TIMESTAMPTZ NOT NULL,
    
    -- Teslim Noktası (Delivery)
    delivery_location_type VARCHAR(50) NOT NULL DEFAULT 'PORT'
        CHECK (delivery_location_type IN ('WAREHOUSE', 'FACTORY', 'PORT', 'CUSTOMER')),
    delivery_warehouse_id UUID REFERENCES warehouses(id) ON DELETE SET NULL,
    delivery_address TEXT NOT NULL,
    scheduled_delivery_time TIMESTAMPTZ NOT NULL,
    actual_delivery_time TIMESTAMPTZ,
    
    -- Rota
    route_code VARCHAR(100) DEFAULT 'MEDINA-JEDDAH-EXPRESS',
    route_description TEXT,
    distance_km NUMERIC(8,2) DEFAULT 420.00,
    
    status VARCHAR(50) NOT NULL DEFAULT 'DRAFT'
        CHECK (status IN ('DRAFT', 'DISPATCHED', 'PICKED_UP', 'IN_TRANSIT', 'DELIVERED', 'CANCELLED')),
        
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_transport_order_company UNIQUE (company_id, transport_order_number)
);

ALTER TABLE transport_orders ADD COLUMN IF NOT EXISTS lot_id UUID REFERENCES item_lots(id) ON DELETE SET NULL;
ALTER TABLE transport_orders ADD COLUMN IF NOT EXISTS order_number VARCHAR(100) GENERATED ALWAYS AS (transport_order_number) STORED;
ALTER TABLE transport_orders ADD COLUMN IF NOT EXISTS carrier_name VARCHAR(150);

-- 4. TAŞIMA EMİR KALEMLERİ & LOT İZLENEBİLİRLİĞİ
CREATE TABLE IF NOT EXISTS transport_order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    transport_order_id UUID NOT NULL REFERENCES transport_orders(id) ON DELETE CASCADE,
    lot_id UUID NOT NULL REFERENCES item_lots(id) ON DELETE RESTRICT, -- Kesintisiz Lot Takibi!
    item_id UUID NOT NULL REFERENCES items(id) ON DELETE RESTRICT,
    quantity NUMERIC(15,3) NOT NULL,
    uom VARCHAR(20) NOT NULL DEFAULT 'Kg',
    package_count INT DEFAULT 1,
    pallet_count INT DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. SOĞUK ZİNCİR SICAKLIK TAKİBİ VE SAPMA ALARMI (COLD CHAIN MONITORING)
CREATE TABLE IF NOT EXISTS cold_chain_temperature_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    context_type VARCHAR(50) NOT NULL 
        CHECK (context_type IN ('TRANSPORT_ORDER', 'SHIPMENT', 'WAREHOUSE', 'CONTAINER')),
    transport_order_id UUID REFERENCES transport_orders(id) ON DELETE CASCADE,
    warehouse_id UUID REFERENCES warehouses(id) ON DELETE CASCADE,
    container_id UUID REFERENCES export_containers(id) ON DELETE CASCADE,
    
    recorded_temperature NUMERIC(5,2) NOT NULL, -- Ölçülen Değer °C
    target_temperature NUMERIC(5,2) NOT NULL DEFAULT -18.00,
    min_threshold NUMERIC(5,2) NOT NULL DEFAULT -22.00,
    max_threshold NUMERIC(5,2) NOT NULL DEFAULT -14.00,
    
    is_breached BOOLEAN NOT NULL DEFAULT FALSE,
    severity VARCHAR(30) NOT NULL DEFAULT 'NORMAL'
        CHECK (severity IN ('NORMAL', 'WARNING', 'CRITICAL_EXCURSION')),
        
    sensor_id VARCHAR(100) DEFAULT 'SENS-REEFER-01',
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    notes TEXT
);

-- SOĞUK ZİNCİR SAPMA TESPİT TETİKLEYİCİSİ
CREATE OR REPLACE FUNCTION detect_cold_chain_excursion()
RETURNS TRIGGER AS $$
BEGIN
    -- Eşik kontrolü: Ölçülen sıcaklık min altında veya max üstünde ise sapma (breach) tespit edilir
    IF NEW.recorded_temperature > NEW.max_threshold OR NEW.recorded_temperature < NEW.min_threshold THEN
        NEW.is_breached := TRUE;
        NEW.severity := 'CRITICAL_EXCURSION';
        
        -- Sapma durumunda audit_logs tablosuna otomatik kritik güvenlik alarmı yaz
        INSERT INTO audit_logs (
            tenant_id, company_id, action, entity_type, entity_id, new_data
        ) VALUES (
            NEW.tenant_id, NEW.company_id, 'CREATE', 'cold_chain_excursion_alert', NEW.id,
            jsonb_build_object(
                'alert', 'SOĞUK ZİNCİR KRİTİK SICAKLIK SAPMASI',
                'context_type', NEW.context_type,
                'transport_order_id', NEW.transport_order_id,
                'recorded_temp', NEW.recorded_temperature,
                'target_temp', NEW.target_temperature,
                'min_threshold', NEW.min_threshold,
                'max_threshold', NEW.max_threshold,
                'sensor_id', NEW.sensor_id,
                'recorded_at', NEW.recorded_at
            )
        );
    ELSE
        NEW.is_breached := FALSE;
        NEW.severity := 'NORMAL';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS trg_detect_cold_chain_excursion ON cold_chain_temperature_logs;
CREATE TRIGGER trg_detect_cold_chain_excursion
BEFORE INSERT OR UPDATE OF recorded_temperature, min_threshold, max_threshold ON cold_chain_temperature_logs
FOR EACH ROW EXECUTE FUNCTION detect_cold_chain_excursion();


-- 6. UÇTAN UCA LOT VE NAKLİYE İZLENEBİLİRLİK GÖRÜNÜMÜ
-- LOT -> VEHICLE -> TRANSPORT -> FACTORY/WAREHOUSE -> SHIPMENT
CREATE OR REPLACE VIEW view_transport_lot_traceability AS
SELECT 
    toi.id AS transport_item_id,
    lot.id AS lot_id,
    lot.lot_number,
    lot.farm_name,
    lot.harvest_date,
    lot.quality_status,
    lot.halal_certified,
    item.item_code,
    item.item_name,
    toi.quantity AS transported_quantity,
    toi.uom,
    tor.id AS transport_order_id,
    tor.transport_order_number,
    tor.status AS transport_status,
    tor.route_code,
    tor.distance_km,
    tor.pickup_location_type,
    tor.pickup_address,
    tor.pickup_time,
    tor.delivery_location_type,
    tor.delivery_address,
    tor.scheduled_delivery_time,
    tor.actual_delivery_time,
    carrier.trade_name AS carrier_name,
    veh.registration_plate,
    veh.vehicle_type,
    veh.is_temperature_controlled,
    drv.full_name AS driver_name,
    drv.phone_number AS driver_phone,
    sh.shipment_number,
    sh.status AS shipment_status,
    sh.bill_of_lading_no
FROM transport_order_items toi
JOIN item_lots lot ON lot.id = toi.lot_id
JOIN items item ON item.id = toi.item_id
JOIN transport_orders tor ON tor.id = toi.transport_order_id
JOIN parties carrier ON carrier.id = tor.carrier_party_id
LEFT JOIN vehicles veh ON veh.id = tor.vehicle_id
LEFT JOIN drivers drv ON drv.id = tor.driver_id
LEFT JOIN shipments sh ON sh.id = tor.shipment_id;


-- 7. İNDEKSLER
CREATE INDEX IF NOT EXISTS idx_vehicles_carrier ON vehicles(carrier_party_id, status);
CREATE INDEX IF NOT EXISTS idx_drivers_carrier ON drivers(carrier_party_id, status);
CREATE INDEX IF NOT EXISTS idx_transport_orders_shipment ON transport_orders(shipment_id);
CREATE INDEX IF NOT EXISTS idx_transport_orders_vehicle ON transport_orders(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_transport_orders_status ON transport_orders(company_id, status);
CREATE INDEX IF NOT EXISTS idx_transport_items_order ON transport_order_items(transport_order_id);
CREATE INDEX IF NOT EXISTS idx_transport_items_lot ON transport_order_items(lot_id);
CREATE INDEX IF NOT EXISTS idx_cold_chain_order ON cold_chain_temperature_logs(transport_order_id, recorded_at DESC);


-- 8. ROW LEVEL SECURITY (RLS)
ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE transport_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE transport_order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE cold_chain_temperature_logs ENABLE ROW LEVEL SECURITY;

ALTER TABLE vehicles FORCE ROW LEVEL SECURITY;
ALTER TABLE drivers FORCE ROW LEVEL SECURITY;
ALTER TABLE transport_orders FORCE ROW LEVEL SECURITY;
ALTER TABLE transport_order_items FORCE ROW LEVEL SECURITY;
ALTER TABLE cold_chain_temperature_logs FORCE ROW LEVEL SECURITY;

-- Politikalar: vehicles
DROP POLICY IF EXISTS "vehicles_select" ON vehicles;
CREATE POLICY "vehicles_select" ON vehicles
    FOR SELECT USING (is_tenant_member(tenant_id) AND has_company_access(company_id));

DROP POLICY IF EXISTS "vehicles_manage" ON vehicles;
CREATE POLICY "vehicles_manage" ON vehicles
    FOR ALL USING (is_tenant_member(tenant_id) AND has_company_access(company_id))
    WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(company_id));

-- Politikalar: drivers
DROP POLICY IF EXISTS "drivers_select" ON drivers;
CREATE POLICY "drivers_select" ON drivers
    FOR SELECT USING (is_tenant_member(tenant_id) AND has_company_access(company_id));

DROP POLICY IF EXISTS "drivers_manage" ON drivers;
CREATE POLICY "drivers_manage" ON drivers
    FOR ALL USING (is_tenant_member(tenant_id) AND has_company_access(company_id))
    WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(company_id));

-- Politikalar: transport_orders
DROP POLICY IF EXISTS "transport_orders_select" ON transport_orders;
CREATE POLICY "transport_orders_select" ON transport_orders
    FOR SELECT USING (is_tenant_member(tenant_id) AND has_company_access(company_id));

DROP POLICY IF EXISTS "transport_orders_manage" ON transport_orders;
CREATE POLICY "transport_orders_manage" ON transport_orders
    FOR ALL USING (is_tenant_member(tenant_id) AND has_company_access(company_id))
    WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(company_id));

-- Politikalar: transport_order_items
DROP POLICY IF EXISTS "transport_order_items_select" ON transport_order_items;
CREATE POLICY "transport_order_items_select" ON transport_order_items
    FOR SELECT USING (is_tenant_member(tenant_id));

DROP POLICY IF EXISTS "transport_order_items_manage" ON transport_order_items;
CREATE POLICY "transport_order_items_manage" ON transport_order_items
    FOR ALL USING (is_tenant_member(tenant_id))
    WITH CHECK (is_tenant_member(tenant_id));

-- Politikalar: cold_chain_temperature_logs
DROP POLICY IF EXISTS "cold_chain_select" ON cold_chain_temperature_logs;
CREATE POLICY "cold_chain_select" ON cold_chain_temperature_logs
    FOR SELECT USING (is_tenant_member(tenant_id) AND has_company_access(company_id));

DROP POLICY IF EXISTS "cold_chain_manage" ON cold_chain_temperature_logs;
CREATE POLICY "cold_chain_manage" ON cold_chain_temperature_logs
    FOR ALL USING (is_tenant_member(tenant_id) AND has_company_access(company_id))
    WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(company_id));
