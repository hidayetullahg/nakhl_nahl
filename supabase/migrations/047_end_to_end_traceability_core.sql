-- ==============================================================================
-- NAKHL & NAHL — FAZ 28: END-TO-END TRACEABILITY & RECALL BOUNDED CONTEXT
-- 22-Step Traceability Chain: Farm to Export Delivery & Emergency Batch Recall
-- ==============================================================================

-- 1. FABRİKA VE PROSES DETAY TABLOSU (Factory, Cleaning, Sorting, Waste, Packaging)
CREATE TABLE IF NOT EXISTS lot_factory_processings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    lot_id UUID NOT NULL REFERENCES item_lots(id) ON DELETE CASCADE,
    
    -- Fabrika & Tesis
    factory_name VARCHAR(150) NOT NULL DEFAULT 'Medine Ana Hurma İşleme ve Paketleme Tesisi',
    
    -- Yıkama / Temizleme (Cleaning)
    cleaning_date DATE NOT NULL DEFAULT CURRENT_DATE,
    cleaning_method VARCHAR(100) NOT NULL DEFAULT 'Ozonlu Su Yıkama ve Hava Kurutma',
    
    -- Sınıflandırma ve Boylama (Sorting)
    sorting_date DATE NOT NULL DEFAULT CURRENT_DATE,
    sorting_grade VARCHAR(50) NOT NULL DEFAULT 'GRADE_JUMBO_PREMIUM',
    
    -- Fire ve Atık Takibi (Waste)
    waste_quantity NUMERIC(15,3) NOT NULL DEFAULT 0.000,
    waste_reason VARCHAR(255) DEFAULT 'Kusurlu ve Ezik Meyve Ayrımı',
    waste_percentage NUMERIC(5,2) NOT NULL DEFAULT 2.50,
    
    -- İşleme ve Kurutma (Processing)
    processing_type VARCHAR(100) NOT NULL DEFAULT 'NEM_DENGELEME_VE_PASTÖRIZASYON',
    processing_date DATE NOT NULL DEFAULT CURRENT_DATE,
    
    -- Paketleme ve Ambalaj (Packaging)
    packaging_date DATE NOT NULL DEFAULT CURRENT_DATE,
    packaging_type VARCHAR(50) NOT NULL DEFAULT 'VACUUM_MAP_BOX_1KG',
    packaging_line VARCHAR(50) DEFAULT 'LINE-A1',
    
    -- Depo Raf ve Koridor Adresi (Shelf Location)
    shelf_location_code VARCHAR(100) NOT NULL DEFAULT 'WH-MED-01 / BLOK-B / RAF-04 / GÖZ-12',
    
    notes TEXT,
    created_by UUID REFERENCES public.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_lot_factory_process UNIQUE (lot_id)
);

-- ==============================================================================
-- 2. UÇTAN UCA İZLENEBİLİRLİK BÜYÜK GÖRÜNÜMÜ (view_end_to_end_traceability)
-- 22 Aşamalı Tedarik Zinciri
-- ==============================================================================
CREATE OR REPLACE VIEW view_end_to_end_traceability WITH (security_invoker = true) AS
SELECT 
    l.tenant_id,
    l.company_id,
    l.id AS lot_id,
    l.lot_number,
    i.item_name AS item_name,
    i.item_code AS item_sku,
    
    -- 1-2. Farm & Harvest
    COALESCE(fm.name, l.farm_name, 'Medine Al-Ula Hurma Çiftliği') AS farm_name,
    COALESCE(fd.code, 'PARSEL-A4') AS field_code,
    COALESCE(h.harvest_date, l.harvest_date) AS harvest_date,
    COALESCE(h.harvest_lot_number, l.harvest_batch_number) AS harvest_lot_number,
    
    -- 3-4. Supplier & Purchase
    p_sup.legal_name AS supplier_name,
    p_sup.country_code AS supplier_country,
    inv_purch.invoice_number AS purchase_invoice_number,
    inv_purch.invoice_date AS purchase_date,
    
    -- 5-6. Vehicle & Transport
    v.plate_number AS vehicle_plate,
    tord.carrier_name AS carrier_name,
    tord.order_number AS transport_order_number,
    
    -- 7-12. Factory, Cleaning, Sorting, Waste, Processing, Packaging
    lfp.factory_name,
    lfp.cleaning_method,
    lfp.sorting_grade,
    lfp.waste_quantity,
    lfp.waste_percentage,
    lfp.processing_type,
    lfp.packaging_date,
    lfp.packaging_type,
    lfp.shelf_location_code,
    
    -- 13-15. Warehouse & Quality & Halal
    w.name AS warehouse_name,
    COALESCE(qi.result, 'PASS') AS quality_inspection_result,
    COALESCE(hlc.compliance_status, 'COMPLIANT') AS halal_compliance_status,
    
    -- 16-17. Sale & Customer
    inv_sale.invoice_number AS sales_invoice_number,
    inv_sale.invoice_date AS sales_date,
    p_cust.legal_name AS customer_name,
    p_cust.country_code AS customer_country,
    
    -- 18-22. Export, Container, Customs, Shipment, Delivery
    ef.export_number,
    ef.destination_country_code AS export_destination,
    ec.container_number,
    ec.seal_number,
    cd.declaration_number AS customs_declaration_number,
    cd.status AS customs_status,
    s.shipment_number,
    s.status AS shipment_status,
    s.port_of_loading,
    s.port_of_discharge

FROM item_lots l
JOIN items i ON l.item_id = i.id
LEFT JOIN harvests h ON l.harvest_batch_number = h.harvest_lot_number
LEFT JOIN farms fm ON h.farm_id = fm.id
LEFT JOIN fields fd ON h.field_id = fd.id

-- Satın alma ve tedarikçi bağlantısı
LEFT JOIN invoice_lines il_purch ON il_purch.lot_id = l.id
LEFT JOIN invoices inv_purch ON il_purch.invoice_id = inv_purch.id AND inv_purch.invoice_type = 'PURCHASE'
LEFT JOIN parties p_sup ON inv_purch.party_id = p_sup.id

-- Lojistik ve taşıma
LEFT JOIN transport_orders tord ON tord.lot_id = l.id
LEFT JOIN vehicles v ON tord.vehicle_id = v.id

-- Fabrika işleme detayları
LEFT JOIN lot_factory_processings lfp ON lfp.lot_id = l.id

-- Depo, Kalite ve Helal
LEFT JOIN warehouses w ON l.company_id = w.company_id
LEFT JOIN quality_inspections qi ON qi.lot_id = l.id
LEFT JOIN halal_lot_compliance hlc ON hlc.lot_id = l.id

-- Satış ve müşteri bağlantısı
LEFT JOIN invoice_lines il_sale ON il_sale.lot_id = l.id
LEFT JOIN invoices inv_sale ON il_sale.invoice_id = inv_sale.id AND inv_sale.invoice_type = 'SALES'
LEFT JOIN parties p_cust ON inv_sale.party_id = p_cust.id

-- İhracat, Konteyner, Gümrük ve Sevkiyat
LEFT JOIN export_file_items efi ON efi.lot_id = l.id
LEFT JOIN export_files ef ON efi.export_file_id = ef.id
LEFT JOIN export_containers ec ON ec.export_file_id = ef.id
LEFT JOIN customs_declarations cd ON cd.export_file_id = ef.id
LEFT JOIN shipments s ON s.export_file_id = ef.id;

-- ==============================================================================
-- 3. FORWARD LOT TRACE RPC (Source -> Processing -> Movement -> Storage -> Sale -> Export)
-- ==============================================================================
CREATE OR REPLACE FUNCTION get_lot_forward_trace(
    p_lot_number TEXT,
    p_tenant_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_lot RECORD;
    v_proc RECORD;
    v_result JSONB;
BEGIN
    SELECT * INTO v_lot FROM item_lots WHERE lot_number = p_lot_number AND tenant_id = p_tenant_id LIMIT 1;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Parti/Lot numarası bulunamadı: %', p_lot_number;
    END IF;

    SELECT * INTO v_proc FROM lot_factory_processings WHERE lot_id = v_lot.id;

    SELECT jsonb_build_object(
        'lot_number', v_lot.lot_number,
        'item_id', v_lot.item_id,
        'expiry_date', v_lot.expiration_date,
        'status', v_lot.quality_status,

        -- 1. SOURCE
        'source', jsonb_build_object(
            'farm_name', COALESCE(v_lot.farm_name, 'Al-Ula Medine Çiftliği'),
            'harvest_date', v_lot.harvest_date,
            'harvest_batch_number', v_lot.harvest_batch_number,
            'supplier_name', (
                SELECT p.legal_name FROM invoices i 
                JOIN invoice_lines il ON il.invoice_id = i.id 
                JOIN parties p ON i.party_id = p.id
                WHERE il.lot_id = v_lot.id AND i.invoice_type = 'PURCHASE' LIMIT 1
            )
        ),

        -- 2. PROCESSING
        'processing', jsonb_build_object(
            'factory_name', COALESCE(v_proc.factory_name, v_lot.processing_facility, 'Medine Ana Hurma Tesisi'),
            'cleaning_method', COALESCE(v_proc.cleaning_method, 'Ozonlu Yıkama'),
            'sorting_grade', COALESCE(v_proc.sorting_grade, 'JUMBO_GRADE_1'),
            'waste_quantity', COALESCE(v_proc.waste_quantity, 0.0),
            'waste_percentage', COALESCE(v_proc.waste_percentage, 0.0),
            'processing_type', COALESCE(v_proc.processing_type, 'Nem Dengeleme'),
            'packaging_date', COALESCE(v_proc.packaging_date, v_lot.packaging_date),
            'packaging_type', COALESCE(v_proc.packaging_type, v_lot.packaging_type, 'BOX_1KG')
        ),

        -- 3. MOVEMENT
        'movement', (
            SELECT COALESCE(jsonb_agg(jsonb_build_object(
                'transport_order', t.order_number,
                'carrier_name', t.carrier_name,
                'vehicle_plate', v.plate_number,
                'status', t.status
            )), '[]'::jsonb)
            FROM transport_orders t
            LEFT JOIN vehicles v ON t.vehicle_id = v.id
            WHERE t.lot_id = v_lot.id
        ),

        -- 4. STORAGE
        'storage', jsonb_build_object(
            'shelf_location', COALESCE(v_proc.shelf_location_code, 'WH-MAIN / RAF-01'),
            'current_stock_quantity', (
                SELECT COALESCE(SUM(current_quantity), 0.0)
                FROM view_current_stock WHERE item_id = v_lot.item_id
            )
        ),

        -- 5. SALE
        'sale', (
            SELECT COALESCE(jsonb_agg(jsonb_build_object(
                'invoice_number', i.invoice_number,
                'invoice_date', i.invoice_date,
                'customer_name', p.legal_name,
                'quantity', il.quantity,
                'unit_price', il.unit_price
            )), '[]'::jsonb)
            FROM invoices i
            JOIN invoice_lines il ON il.invoice_id = i.id
            JOIN parties p ON i.party_id = p.id
            WHERE il.lot_id = v_lot.id AND i.invoice_type = 'SALES'
        ),

        -- 6. EXPORT
        'export', (
            SELECT COALESCE(jsonb_agg(jsonb_build_object(
                'export_number', ef.export_number,
                'destination_country', ef.destination_country_code,
                'container_number', ec.container_number,
                'customs_declaration', cd.declaration_number,
                'shipment_status', s.status
            )), '[]'::jsonb)
            FROM export_file_items efi
            JOIN export_files ef ON efi.export_file_id = ef.id
            LEFT JOIN export_containers ec ON ec.export_file_id = ef.id
            LEFT JOIN customs_declarations cd ON cd.export_file_id = ef.id
            LEFT JOIN shipments s ON s.export_file_id = ef.id
            WHERE efi.lot_id = v_lot.id
        )
    ) INTO v_result;

    RETURN v_result;
END;
$$;

-- ==============================================================================
-- 4. RECALL RPC (Acil Ürün Geri Çağırma & Karantina Analizi)
-- LOT -> CURRENT STOCK -> SALES -> CUSTOMERS -> SHIPMENTS -> CONTAINERS
-- ==============================================================================
CREATE OR REPLACE FUNCTION get_lot_recall_analysis(
    p_lot_number TEXT,
    p_tenant_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_lot RECORD;
    v_result JSONB;
BEGIN
    SELECT * INTO v_lot FROM item_lots WHERE lot_number = p_lot_number AND tenant_id = p_tenant_id LIMIT 1;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Parti/Lot numarası bulunamadı: %', p_lot_number;
    END IF;

    SELECT jsonb_build_object(
        'recall_timestamp', NOW(),
        'lot_number', v_lot.lot_number,
        'lot_id', v_lot.id,
        'item_id', v_lot.item_id,

        -- 1. Depolardaki Mevcut Kalan Stok ve Raf Konumu
        'current_stock_on_hand', (
            SELECT COALESCE(jsonb_agg(jsonb_build_object(
                'warehouse_id', vcs.warehouse_id,
                'warehouse_name', w.name,
                'quantity', vcs.current_quantity,
                'shelf_location', COALESCE((SELECT shelf_location_code FROM lot_factory_processings WHERE lot_id = v_lot.id), 'WH-GENERAL')
            )), '[]'::jsonb)
            FROM view_current_stock vcs
            JOIN warehouses w ON vcs.warehouse_id = w.id
            WHERE vcs.item_id = v_lot.item_id AND vcs.current_quantity > 0
        ),

        -- 2. Gerçekleşen Satışlar ve Faturalar
        'affected_sales', (
            SELECT COALESCE(jsonb_agg(jsonb_build_object(
                'invoice_id', i.id,
                'invoice_number', i.invoice_number,
                'invoice_date', i.invoice_date,
                'sold_quantity', il.quantity,
                'currency', i.currency,
                'total_amount', il.total_price
            )), '[]'::jsonb)
            FROM invoices i
            JOIN invoice_lines il ON il.invoice_id = i.id
            WHERE il.lot_id = v_lot.id AND i.invoice_type = 'SALES'
        ),

        -- 3. Etkilenen Müşteriler ve İletişim Bilgileri (Geri çağırma bildirimi için)
        'affected_customers', (
            SELECT COALESCE(jsonb_agg(DISTINCT jsonb_build_object(
                'customer_id', p.id,
                'customer_name', p.name,
                'country_code', p.country_code,
                'email', p.email,
                'phone', p.phone,
                'tax_number', p.tax_number
            )), '[]'::jsonb)
            FROM invoices i
            JOIN invoice_lines il ON il.invoice_id = i.id
            JOIN parties p ON i.party_id = p.id
            WHERE il.lot_id = v_lot.id AND i.invoice_type = 'SALES'
        ),

        -- 4. Etkilenen Uluslararası Sevkiyatlar
        'affected_shipments', (
            SELECT COALESCE(jsonb_agg(jsonb_build_object(
                'shipment_id', s.id,
                'shipment_number', s.shipment_number,
                'carrier_name', s.carrier_name,
                'status', s.status,
                'port_of_loading', s.port_of_loading,
                'port_of_discharge', s.port_of_discharge
            )), '[]'::jsonb)
            FROM export_file_items efi
            JOIN shipments s ON s.export_file_id = efi.export_file_id
            WHERE efi.lot_id = v_lot.id
        ),

        -- 5. Etkilenen Konteynerler ve Mühür Numaraları
        'affected_containers', (
            SELECT COALESCE(jsonb_agg(jsonb_build_object(
                'container_id', ec.id,
                'container_number', ec.container_number,
                'seal_number', ec.seal_number,
                'container_type', ec.container_type
            )), '[]'::jsonb)
            FROM export_file_items efi
            JOIN export_containers ec ON ec.export_file_id = efi.export_file_id
            WHERE efi.lot_id = v_lot.id
        )
    ) INTO v_result;

    RETURN v_result;
END;
$$;

-- ==============================================================================
-- 5. REVERSE TRACE RPC (Müşteriden Geriye Çiftliğe Doğru İzleme)
-- CUSTOMER -> SALE -> LOT -> PRODUCTION -> HARVEST -> FARM
-- ==============================================================================
CREATE OR REPLACE FUNCTION get_reverse_trace_from_customer(
    p_customer_name TEXT,
    p_invoice_number TEXT,
    p_tenant_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_inv RECORD;
    v_result JSONB;
BEGIN
    SELECT i.*, p.legal_name AS customer_name, p.country_code AS customer_country
    INTO v_inv
    FROM invoices i
    JOIN parties p ON i.party_id = p.id
    WHERE i.tenant_id = p_tenant_id 
      AND i.invoice_number = p_invoice_number
      AND p.legal_name ILIKE '%' || p_customer_name || '%'
    LIMIT 1;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Müşteri faturası bulunamadı: Müşteri %, Fatura %', p_customer_name, p_invoice_number;
    END IF;

    SELECT jsonb_build_object(
        'customer', jsonb_build_object(
            'customer_name', v_inv.customer_name,
            'customer_country', v_inv.customer_country
        ),
        'sale_invoice', jsonb_build_object(
            'invoice_number', v_inv.invoice_number,
            'invoice_date', v_inv.invoice_date,
            'currency', v_inv.currency,
            'grand_total', v_inv.grand_total
        ),
        'traced_lots', (
            SELECT COALESCE(jsonb_agg(jsonb_build_object(
                'lot_number', l.lot_number,
                'item_name', it.item_name,
                'production', jsonb_build_object(
                    'factory_name', COALESCE(lfp.factory_name, 'Medine Ana Hurma Tesisi'),
                    'cleaning_method', COALESCE(lfp.cleaning_method, 'Ozonlu Yıkama'),
                    'sorting_grade', COALESCE(lfp.sorting_grade, 'JUMBO_GRADE_1'),
                    'packaging_date', COALESCE(lfp.packaging_date, l.packaging_date)
                ),
                'harvest', jsonb_build_object(
                    'harvest_date', l.harvest_date,
                    'harvest_lot_number', l.harvest_batch_number,
                    'field_code', COALESCE(fd.code, 'PARSEL-A4')
                ),
                'farm', jsonb_build_object(
                    'farm_name', COALESCE(fm.name, l.farm_name, 'Medine Al-Ula Hurma Çiftliği'),
                    'location', COALESCE(fm.location, 'Al-Ula / Madinah'),
                    'cultivation_type', COALESCE(fm.cultivation_type, 'ORGANIC')
                )
            )), '[]'::jsonb)
            FROM invoice_lines il
            JOIN item_lots l ON il.lot_id = l.id
            JOIN items it ON l.item_id = it.id
            LEFT JOIN lot_factory_processings lfp ON lfp.lot_id = l.id
            LEFT JOIN harvests h ON l.harvest_batch_number = h.harvest_lot_number
            LEFT JOIN fields fd ON h.field_id = fd.id
            LEFT JOIN farms fm ON h.farm_id = fm.id
            WHERE il.invoice_id = v_inv.id
        )
    ) INTO v_result;

    RETURN v_result;
END;
$$;

-- ==============================================================================
-- 6. İNDEKSLER VE ROW LEVEL SECURITY (RLS)
-- ==============================================================================
CREATE INDEX IF NOT EXISTS idx_lot_factory_processings_lot 
    ON lot_factory_processings(tenant_id, company_id, lot_id);

ALTER TABLE lot_factory_processings ENABLE ROW LEVEL SECURITY;
ALTER TABLE lot_factory_processings FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "lot_factory_processings_access" ON lot_factory_processings;
CREATE POLICY "lot_factory_processings_access" ON lot_factory_processings
    FOR ALL TO authenticated
    USING (is_tenant_member(tenant_id) AND has_company_access(auth.uid(), company_id))
    WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(auth.uid(), company_id));
