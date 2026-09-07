-- ==============================================================================
-- NAKHL & NAHL — MIGRATION 039: EXPORT & INTERNATIONAL TRADE BOUNDED CONTEXT (FAZ 19)
-- Purpose:
-- 1. export_files: İhracat dosyası master kaydı
-- 2. export_file_items: İhracat ürün kalemleri, HS kodu (GTİP) ve zorunlu LOT bağlantısı
-- 3. customs_declarations: Gümrük beyannamesi (GÇB), gümrük idaresi, vergi ve muayene
-- 4. export_containers: Konteyner, mühür no, sıcaklık kontrolü ve mükerrer konteyner engeli
-- 5. export_documents: Commercial invoice, packing list, certificate of origin, B/L, halal
-- 6. view_export_lot_traceability: LOT -> FARM -> PROCESS -> EXPORT FILE -> CONTAINER -> CUSTOMS -> SHIPMENT -> DELIVERY
-- 7. RLS Politikaları ve Performans İndeksleri
-- ==============================================================================

-- 1. İHRACAT DOSYALARI (EXPORT FILES MASTER)
CREATE TABLE IF NOT EXISTS export_files (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    export_number VARCHAR(100) NOT NULL,
    customer_party_id UUID NOT NULL REFERENCES parties(id) ON DELETE RESTRICT,
    sales_order_id UUID REFERENCES sales_orders(id) ON DELETE SET NULL,
    invoice_id UUID REFERENCES invoices(id) ON DELETE SET NULL,
    
    origin_country_code VARCHAR(10) NOT NULL DEFAULT 'SA',
    destination_country_code VARCHAR(10) NOT NULL DEFAULT 'TR',
    origin_port VARCHAR(100) DEFAULT 'Cidde İslam Limanı (KSA)',
    destination_port VARCHAR(100) DEFAULT 'Mersin Uluslararası Limanı (TR)',
    incoterm VARCHAR(10) NOT NULL DEFAULT 'FOB' 
        CHECK (incoterm IN ('EXW', 'FCA', 'CPT', 'CIP', 'DAP', 'DPU', 'DDP', 'FAS', 'FOB', 'CFR', 'CIF')),
    currency_code VARCHAR(5) NOT NULL DEFAULT 'USD',
    
    fob_value NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    freight_value NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    insurance_value NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    cif_value NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    
    status VARCHAR(50) NOT NULL DEFAULT 'DRAFT' 
        CHECK (status IN ('DRAFT', 'CONFIRMED', 'UNDER_CUSTOMS', 'LOADED', 'IN_TRANSIT', 'CLEARED_AT_DESTINATION', 'DELIVERED', 'CLOSED', 'CANCELLED')),
    
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_export_file_company_number UNIQUE (company_id, export_number)
);

-- 2. İHRACAT ÜRÜN KALEMLERİ & LOT BAĞLANTISI (EXPORT FILE ITEMS)
CREATE TABLE IF NOT EXISTS export_file_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    export_file_id UUID NOT NULL REFERENCES export_files(id) ON DELETE CASCADE,
    item_id UUID NOT NULL REFERENCES items(id) ON DELETE RESTRICT,
    lot_id UUID NOT NULL REFERENCES item_lots(id) ON DELETE RESTRICT, -- Kesintisiz Lot İzlenebilirliği!
    hs_code VARCHAR(50) NOT NULL DEFAULT '0804.10.00.00', -- Hurma GTİP / HS Code
    quantity NUMERIC(15,3) NOT NULL,
    uom VARCHAR(20) NOT NULL DEFAULT 'Kg',
    unit_price NUMERIC(15,2) NOT NULL,
    total_price NUMERIC(15,2) NOT NULL,
    net_weight_kg NUMERIC(12,2),
    gross_weight_kg NUMERIC(12,2),
    pallet_count INT DEFAULT 1,
    package_count INT DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. GÜMRÜK BEYANNAMESİ & BİLGİLERİ (CUSTOMS DECLARATIONS)
CREATE TABLE IF NOT EXISTS customs_declarations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    export_file_id UUID NOT NULL REFERENCES export_files(id) ON DELETE CASCADE,
    declaration_number VARCHAR(100) NOT NULL, -- Gümrük Çıkış Beyanname (GÇB) No
    declaration_date DATE NOT NULL DEFAULT CURRENT_DATE,
    customs_office VARCHAR(150) NOT NULL,
    hs_code VARCHAR(50) NOT NULL DEFAULT '0804.10.00.00',
    country_of_origin VARCHAR(10) NOT NULL DEFAULT 'SA',
    customs_value NUMERIC(15,2) NOT NULL,
    currency_code VARCHAR(5) NOT NULL DEFAULT 'USD',
    duties_and_taxes NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    clearance_date DATE,
    status VARCHAR(50) NOT NULL DEFAULT 'SUBMITTED' 
        CHECK (status IN ('DRAFT', 'SUBMITTED', 'INSPECTION_REQUIRED', 'INSPECTION_PASSED', 'CLEARED', 'REJECTED')),
    customs_broker_party_id UUID REFERENCES parties(id),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_customs_declaration UNIQUE (company_id, declaration_number)
);

-- 4. KONTEYNER YÖNETİMİ (EXPORT CONTAINERS)
CREATE TABLE IF NOT EXISTS export_containers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    export_file_id UUID NOT NULL REFERENCES export_files(id) ON DELETE CASCADE,
    shipment_id UUID REFERENCES shipments(id) ON DELETE SET NULL,
    container_number VARCHAR(50) NOT NULL, -- ISO 6346 standardı
    seal_number VARCHAR(50) NOT NULL, -- Mühür No
    container_type VARCHAR(50) NOT NULL DEFAULT '40_REEFER'
        CHECK (container_type IN ('20_DRY', '40_DRY', '40_HC', '20_REEFER', '40_REEFER')),
    tare_weight_kg NUMERIC(12,2) DEFAULT 0.00,
    gross_weight_kg NUMERIC(12,2) DEFAULT 0.00,
    max_payload_kg NUMERIC(12,2),
    volume_cbm NUMERIC(10,2),
    temperature_setting_celsius NUMERIC(5,2) DEFAULT -18.0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- DUPLICATE CONTAINER NUMBER KONTROLÜ TETİKLEYİCİSİ
CREATE OR REPLACE FUNCTION prevent_duplicate_active_container()
RETURNS TRIGGER AS $$
BEGIN
    -- Eğer konteyner aktifse ve aynı kiracı altında henüz teslim edilmemiş/aktif başka bir ihracat dosyasında varsa hata ver
    IF NEW.is_active = TRUE THEN
        IF EXISTS (
            SELECT 1 FROM export_containers
            WHERE tenant_id = NEW.tenant_id
              AND container_number = NEW.container_number
              AND is_active = TRUE
              AND id <> COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid)
        ) THEN
            RAISE EXCEPTION 'MÜKERRER KONTEYNER ENGELİ: "%" numaralı konteyner şu anda başka bir aktif/transit ihracat dosyasında kullanılmaktadır! Aynı konteyner teslim edilmeden başka bir sevkiyata yüklenemez.',
                NEW.container_number;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_prevent_duplicate_active_container ON export_containers;
CREATE TRIGGER trg_prevent_duplicate_active_container
BEFORE INSERT OR UPDATE OF container_number, is_active ON export_containers
FOR EACH ROW EXECUTE FUNCTION prevent_duplicate_active_container();


-- 5. SEVKİYAT İLİŞKİSİ
ALTER TABLE shipments ADD COLUMN IF NOT EXISTS export_file_id UUID REFERENCES export_files(id) ON DELETE SET NULL;


-- 6. DIŞ TİCARET BELGELERİ (EXPORT DOCUMENTS CONTEXT)
CREATE TABLE IF NOT EXISTS export_documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    export_file_id UUID NOT NULL REFERENCES export_files(id) ON DELETE CASCADE,
    shipment_id UUID REFERENCES shipments(id) ON DELETE SET NULL,
    invoice_id UUID REFERENCES invoices(id) ON DELETE SET NULL,
    document_type VARCHAR(50) NOT NULL CHECK (document_type IN (
        'COMMERCIAL_INVOICE',
        'PACKING_LIST',
        'CERTIFICATE_OF_ORIGIN',
        'HALAL_CERTIFICATE',
        'PHYTOSANITARY_CERTIFICATE',
        'CUSTOMS_DECLARATION',
        'BILL_OF_LADING',
        'CMR',
        'AIR_WAYBILL',
        'FUMIGATION_CERTIFICATE',
        'OTHER'
    )),
    document_number VARCHAR(100) NOT NULL,
    issue_date DATE NOT NULL DEFAULT CURRENT_DATE,
    document_url TEXT,
    is_verified BOOLEAN NOT NULL DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- 7. UÇTAN UCA LOT VE İHRACAT İZLENEBİLİRLİK GÖRÜNÜMÜ
CREATE OR REPLACE VIEW view_export_lot_traceability AS
SELECT 
    ef.id AS export_file_id,
    ef.export_number,
    ef.status AS export_status,
    ef.incoterm,
    ef.origin_port,
    ef.destination_port,
    cust.trade_name AS customer_trade_name,
    cust.legal_name AS customer_legal_name,
    item.item_code,
    item.item_name,
    efi.hs_code,
    efi.quantity AS export_quantity,
    efi.uom,
    lot.id AS lot_id,
    lot.lot_number,
    lot.farm_name,
    lot.harvest_date,
    lot.quality_status,
    lot.halal_certified,
    cd.declaration_number AS customs_declaration_no,
    cd.status AS customs_status,
    ec.container_number,
    ec.seal_number,
    ec.container_type,
    ec.temperature_setting_celsius,
    sh.shipment_number,
    sh.status AS shipment_status,
    sh.transport_mode,
    sh.vessel_or_plate,
    sh.bill_of_lading_no,
    sh.departure_date,
    sh.actual_arrival_date
FROM export_files ef
JOIN export_file_items efi ON efi.export_file_id = ef.id
JOIN item_lots lot ON lot.id = efi.lot_id
JOIN items item ON item.id = efi.item_id
JOIN parties cust ON cust.id = ef.customer_party_id
LEFT JOIN customs_declarations cd ON cd.export_file_id = ef.id
LEFT JOIN export_containers ec ON ec.export_file_id = ef.id
LEFT JOIN shipments sh ON sh.export_file_id = ef.id;


-- 8. İNDEKSLER
CREATE INDEX IF NOT EXISTS idx_export_files_company ON export_files(company_id, status);
CREATE INDEX IF NOT EXISTS idx_export_files_customer ON export_files(customer_party_id);
CREATE INDEX IF NOT EXISTS idx_export_file_items_file ON export_file_items(export_file_id);
CREATE INDEX IF NOT EXISTS idx_export_file_items_lot ON export_file_items(lot_id);
CREATE INDEX IF NOT EXISTS idx_customs_declarations_file ON customs_declarations(export_file_id);
CREATE INDEX IF NOT EXISTS idx_export_containers_file ON export_containers(export_file_id);
CREATE INDEX IF NOT EXISTS idx_export_containers_active_no ON export_containers(container_number) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_export_documents_file ON export_documents(export_file_id, document_type);


-- 9. ROW LEVEL SECURITY (RLS)
ALTER TABLE export_files ENABLE ROW LEVEL SECURITY;
ALTER TABLE export_file_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE customs_declarations ENABLE ROW LEVEL SECURITY;
ALTER TABLE export_containers ENABLE ROW LEVEL SECURITY;
ALTER TABLE export_documents ENABLE ROW LEVEL SECURITY;

ALTER TABLE export_files FORCE ROW LEVEL SECURITY;
ALTER TABLE export_file_items FORCE ROW LEVEL SECURITY;
ALTER TABLE customs_declarations FORCE ROW LEVEL SECURITY;
ALTER TABLE export_containers FORCE ROW LEVEL SECURITY;
ALTER TABLE export_documents FORCE ROW LEVEL SECURITY;

-- Politikalar: export_files
DROP POLICY IF EXISTS "export_files_select" ON export_files;
CREATE POLICY "export_files_select" ON export_files
    FOR SELECT USING (is_tenant_member(tenant_id) AND has_company_access(company_id));

DROP POLICY IF EXISTS "export_files_manage" ON export_files;
CREATE POLICY "export_files_manage" ON export_files
    FOR ALL USING (is_tenant_member(tenant_id) AND has_company_access(company_id))
    WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(company_id));

-- Politikalar: export_file_items
DROP POLICY IF EXISTS "export_file_items_select" ON export_file_items;
CREATE POLICY "export_file_items_select" ON export_file_items
    FOR SELECT USING (is_tenant_member(tenant_id));

DROP POLICY IF EXISTS "export_file_items_manage" ON export_file_items;
CREATE POLICY "export_file_items_manage" ON export_file_items
    FOR ALL USING (is_tenant_member(tenant_id))
    WITH CHECK (is_tenant_member(tenant_id));

-- Politikalar: customs_declarations
DROP POLICY IF EXISTS "customs_declarations_select" ON customs_declarations;
CREATE POLICY "customs_declarations_select" ON customs_declarations
    FOR SELECT USING (is_tenant_member(tenant_id) AND has_company_access(company_id));

DROP POLICY IF EXISTS "customs_declarations_manage" ON customs_declarations;
CREATE POLICY "customs_declarations_manage" ON customs_declarations
    FOR ALL USING (is_tenant_member(tenant_id) AND has_company_access(company_id))
    WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(company_id));

-- Politikalar: export_containers
DROP POLICY IF EXISTS "export_containers_select" ON export_containers;
CREATE POLICY "export_containers_select" ON export_containers
    FOR SELECT USING (is_tenant_member(tenant_id) AND has_company_access(company_id));

DROP POLICY IF EXISTS "export_containers_manage" ON export_containers;
CREATE POLICY "export_containers_manage" ON export_containers
    FOR ALL USING (is_tenant_member(tenant_id) AND has_company_access(company_id))
    WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(company_id));

-- Politikalar: export_documents
DROP POLICY IF EXISTS "export_documents_select" ON export_documents;
CREATE POLICY "export_documents_select" ON export_documents
    FOR SELECT USING (is_tenant_member(tenant_id) AND has_company_access(company_id));

DROP POLICY IF EXISTS "export_documents_manage" ON export_documents;
CREATE POLICY "export_documents_manage" ON export_documents
    FOR ALL USING (is_tenant_member(tenant_id) AND has_company_access(company_id))
    WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(company_id));
