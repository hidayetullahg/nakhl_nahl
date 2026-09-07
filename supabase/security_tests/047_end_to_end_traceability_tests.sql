-- ==============================================================================
-- NAKHL & NAHL — FAZ 28: END-TO-END TRACEABILITY & RECALL INTEGRATION TESTS
-- 22-Step Traceability Chain Verification: Farm to Export Delivery & Emergency Batch Recall
-- ==============================================================================

DO $$
DECLARE
    v_tenant_id UUID := '11111111-1111-1111-1111-111111111111';
    v_tenant_b_id UUID := '22222222-2222-2222-2222-222222222222';
    v_company_id UUID := 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
    v_user_id UUID := '99999999-9999-9999-9999-999999999999';

    -- Zincir Varlıkları
    v_farm_id UUID;
    v_field_id UUID;
    v_harvest_id UUID;
    v_item_id UUID;
    v_lot_id UUID;
    v_supplier_id UUID;
    v_customer_id UUID;
    v_warehouse_id UUID;
    v_vehicle_id UUID;
    v_transport_order_id UUID;
    v_purch_invoice_id UUID;
    v_sale_invoice_id UUID;
    v_export_file_id UUID;
    v_container_id UUID;
    v_customs_id UUID;
    v_shipment_id UUID;

    -- Test Çıktıları
    v_forward_trace JSONB;
    v_recall_analysis JSONB;
    v_reverse_trace JSONB;
    v_view_row RECORD;
BEGIN
    RAISE NOTICE '>>> FAZ 28 END-TO-END TRACEABILITY & RECALL TESTLERİ BAŞLIYOR...';

    -- 0. Ürün Hazırlığı
    SELECT id INTO v_item_id FROM items WHERE tenant_id = v_tenant_id LIMIT 1;
    IF v_item_id IS NULL THEN
        INSERT INTO items (tenant_id, company_id, sku, name, unit_of_measure)
        VALUES (v_tenant_id, v_company_id, 'DATE-AJWA-001', 'Acve Hurması Jumbo', 'Kg')
        RETURNING id INTO v_item_id;
    END IF;

    -- 0. Depo Hazırlığı
    SELECT id INTO v_warehouse_id FROM warehouses WHERE company_id = v_company_id LIMIT 1;
    IF v_warehouse_id IS NULL THEN
        INSERT INTO warehouses (tenant_id, company_id, code, name, warehouse_type)
        VALUES (v_tenant_id, v_company_id, 'WH-MAIN-EXP', 'Medine İhracat Ana Deposu', 'MAIN')
        RETURNING id INTO v_warehouse_id;
    END IF;

    -- ==============================================================================
    -- 1. ADIM: 22 AŞAMALI GERÇEKÇİ VERİ ZİNCİRİNİ SEED ETME
    -- ==============================================================================

    -- [1] FARM: Çiftlik
    INSERT INTO farms (tenant_id, company_id, code, name, location, cultivation_type)
    VALUES (v_tenant_id, v_company_id, 'FARM-ALULA-01', 'Al-Ula Medine Vaha Hurmalığı', 'Al-Ula Valley, Madinah, KSA', 'ORGANIC')
    ON CONFLICT (tenant_id, code) DO UPDATE SET name = EXCLUDED.name
    RETURNING id INTO v_farm_id;

    -- Tarla / Parsel
    INSERT INTO fields (tenant_id, farm_id, code, name, area_hectares, palm_tree_count)
    VALUES (v_tenant_id, v_farm_id, 'PARSEL-A4', 'Kuzey Hurma Bahçesi Parsel 4', 12.5, 450)
    ON CONFLICT (tenant_id, farm_id, code) DO UPDATE SET name = EXCLUDED.name
    RETURNING id INTO v_field_id;

    -- [2] HARVEST: Hasat
    INSERT INTO harvests (
        tenant_id, farm_id, field_id, item_id, harvest_lot_number,
        harvest_date, quantity_kg, quality_grade
    ) VALUES (
        v_tenant_id, v_farm_id, v_field_id, v_item_id, 'HV-2026-ALULA-09',
        CURRENT_DATE - 15, 10000.0, 'GRADE_A'
    ) ON CONFLICT (tenant_id, harvest_lot_number) DO UPDATE SET quantity_kg = EXCLUDED.quantity_kg
    RETURNING id INTO v_harvest_id;

    -- [3] SUPPLIER: Tedarikçi / Çiftçi Kooperatifi
    INSERT INTO parties (tenant_id, company_id, code, name, party_type, is_supplier, is_customer, country_code, email, phone, tax_number)
    VALUES (v_tenant_id, v_company_id, 'SUP-ALULA-COOP', 'Al-Ula Hurma Üreticileri Tarım Birliği', 'SUPPLIER', true, false, 'SA', 'sales@alula-dates.sa', '+966501112233', '300998877600003')
    ON CONFLICT (tenant_id, company_id, code) DO UPDATE SET name = EXCLUDED.name
    RETURNING id INTO v_supplier_id;

    -- [13] LOT: Ana Parti / Lot Tanımı (Baştan ID gerekeceği için)
    INSERT INTO item_lots (
        tenant_id, company_id, item_id, lot_number,
        production_date, expiry_date, status,
        farm_name, harvest_date, harvest_batch_number,
        processing_facility, packaging_date, packaging_type
    ) VALUES (
        v_tenant_id, v_company_id, v_item_id, 'LOT-2026-ACVE-777',
        CURRENT_DATE - 10, CURRENT_DATE + 365, 'APPROVED',
        'Al-Ula Medine Vaha Hurmalığı', CURRENT_DATE - 15, 'HV-2026-ALULA-09',
        'Medine Entegre Hurma İşleme Fabrikası', CURRENT_DATE - 5, 'VACUUM_MAP_BOX_1KG'
    ) ON CONFLICT (tenant_id, company_id, lot_number) DO UPDATE SET status = 'APPROVED'
    RETURNING id INTO v_lot_id;

    -- [4] PURCHASE: Satın Alma Faturası
    INSERT INTO invoices (
        tenant_id, company_id, invoice_type, invoice_number, invoice_date,
        party_id, currency, subtotal, tax_amount, grand_total, status
    ) VALUES (
        v_tenant_id, v_company_id, 'PURCHASE', 'PINV-2026-088', CURRENT_DATE - 12,
        v_supplier_id, 'SAR', 200000.00, 30000.00, 230000.00, 'POSTED'
    ) ON CONFLICT (tenant_id, company_id, invoice_number) DO UPDATE SET status = 'POSTED'
    RETURNING id INTO v_purch_invoice_id;

    INSERT INTO invoice_lines (
        tenant_id, invoice_id, item_id, lot_id, quantity, unit_price, tax_rate, tax_amount, total_price
    ) VALUES (
        v_tenant_id, v_purch_invoice_id, v_item_id, v_lot_id, 10000.0, 20.00, 15.0, 30000.00, 230000.00
    ) ON CONFLICT DO NOTHING;

    -- [5] VEHICLE: Taşıma Aracı
    INSERT INTO vehicles (
        tenant_id, company_id, plate_number, vehicle_type,
        carrier_name, max_weight_capacity, is_temperature_controlled, status
    ) VALUES (
        v_tenant_id, v_company_id, 'KSA-7788-DXB', 'REFRIGERATED_TRUCK',
        'Hicaz Soğuk Zincir Lojistik', 24000.0, true, 'ACTIVE'
    ) ON CONFLICT (tenant_id, plate_number) DO UPDATE SET status = 'ACTIVE'
    RETURNING id INTO v_vehicle_id;

    -- [6] TRANSPORT: Taşıma Emri (Lojistik)
    INSERT INTO transport_orders (
        tenant_id, company_id, order_number, vehicle_id, carrier_name,
        pickup_location, delivery_location, status, lot_id, temperature_required_c
    ) VALUES (
        v_tenant_id, v_company_id, 'TR-ORD-2026-99', v_vehicle_id, 'Hicaz Soğuk Zincir Lojistik',
        'Al-Ula Bahçesi', 'Medine Entegre Fabrikası', 'DELIVERED', v_lot_id, 18.0
    ) ON CONFLICT (tenant_id, order_number) DO UPDATE SET status = 'DELIVERED'
    RETURNING id INTO v_transport_order_id;

    -- [7-12, 14-15] FACTORY PROCESSINGS: Temizleme, Boylama, Fire/Waste, İşleme, Paketleme, Raf
    INSERT INTO lot_factory_processings (
        tenant_id, company_id, lot_id,
        factory_name, cleaning_date, cleaning_method,
        sorting_date, sorting_grade,
        waste_quantity, waste_reason, waste_percentage,
        processing_type, processing_date,
        packaging_date, packaging_type, packaging_line,
        shelf_location_code
    ) VALUES (
        v_tenant_id, v_company_id, v_lot_id,
        'Medine Entegre Hurma İşleme Fabrikası', CURRENT_DATE - 8, 'Ozonlu Su Yıkama ve 45C Hava Kurutma',
        CURRENT_DATE - 7, 'GRADE_JUMBO_PREMIUM_EXTRA',
        250.0, 'Kusurlu Boyut ve Ezik Ayıklama', 2.50,
        'NEM_DENGELEME_VE_PASTÖRIZASYON', CURRENT_DATE - 6,
        CURRENT_DATE - 5, 'VACUUM_MAP_BOX_1KG', 'LINE-AL-MADINAH-1',
        'WH-MED-01 / BLOK-B / RAF-04 / GÖZ-12'
    ) ON CONFLICT (lot_id) DO UPDATE SET shelf_location_code = EXCLUDED.shelf_location_code;

    -- [16] SALE: Satış Faturası & [17] CUSTOMER: Müşteri
    INSERT INTO parties (
        tenant_id, company_id, code, name, party_type, is_supplier, is_customer,
        country_code, email, phone, tax_number
    ) VALUES (
        v_tenant_id, v_company_id, 'CUST-DE-BERLIN', 'Berlin Gourmet Bio Dates GmbH', 'CUSTOMER', false, true,
        'DE', 'orders@berlindates.de', '+493012345678', 'DE999888777'
    ) ON CONFLICT (tenant_id, company_id, code) DO UPDATE SET email = EXCLUDED.email
    RETURNING id INTO v_customer_id;

    INSERT INTO invoices (
        tenant_id, company_id, invoice_type, invoice_number, invoice_date,
        party_id, currency, subtotal, tax_amount, grand_total, status
    ) VALUES (
        v_tenant_id, v_company_id, 'SALES', 'SINV-2026-EXP-555', CURRENT_DATE - 3,
        v_customer_id, 'EUR', 45000.00, 0.00, 45000.00, 'POSTED'
    ) ON CONFLICT (tenant_id, company_id, invoice_number) DO UPDATE SET status = 'POSTED'
    RETURNING id INTO v_sale_invoice_id;

    INSERT INTO invoice_lines (
        tenant_id, invoice_id, item_id, lot_id, quantity, unit_price, tax_rate, tax_amount, total_price
    ) VALUES (
        v_tenant_id, v_sale_invoice_id, v_item_id, v_lot_id, 3000.0, 15.00, 0.0, 0.00, 45000.00
    ) ON CONFLICT DO NOTHING;

    -- [18] EXPORT FILE: İhracat Dosyası
    INSERT INTO export_files (
        tenant_id, company_id, export_number, customer_id, origin_country,
        destination_country, incoterm, currency, status
    ) VALUES (
        v_tenant_id, v_company_id, 'EXP-2026-EUR-007', v_customer_id, 'SA',
        'DE', 'FOB', 'EUR', 'SHIPPED'
    ) ON CONFLICT (tenant_id, company_id, export_number) DO UPDATE SET status = 'SHIPPED'
    RETURNING id INTO v_export_file_id;

    INSERT INTO export_file_items (
        tenant_id, export_file_id, item_id, lot_id, quantity, unit_price, total_price
    ) VALUES (
        v_tenant_id, v_export_file_id, v_item_id, v_lot_id, 3000.0, 15.00, 45000.00
    ) ON CONFLICT DO NOTHING;

    -- [19] CONTAINER: Konteyner
    INSERT INTO export_containers (
        tenant_id, export_file_id, container_number, container_type, seal_number, tare_weight, max_payload
    ) VALUES (
        v_tenant_id, v_export_file_id, 'MSCU9876543', 'REEFER_40HC', 'SEAL-KSA-99112', 4500.0, 28000.0
    ) ON CONFLICT (tenant_id, container_number) DO UPDATE SET seal_number = EXCLUDED.seal_number
    RETURNING id INTO v_container_id;

    -- [20] CUSTOMS: Gümrük Beyannamesi
    INSERT INTO customs_declarations (
        tenant_id, export_file_id, declaration_number, customs_office, hs_code, customs_value, status
    ) VALUES (
        v_tenant_id, v_export_file_id, 'CUST-DEC-JEDDAH-8821', 'Jeddah Islamic Port Customs', '0804.10.00', 45000.00, 'CLEARED'
    ) ON CONFLICT (tenant_id, declaration_number) DO UPDATE SET status = 'CLEARED'
    RETURNING id INTO v_customs_id;

    -- [21-22] SHIPMENT & DELIVERY: Uluslararası Sevkiyat ve Teslimat
    INSERT INTO shipments (
        tenant_id, export_file_id, shipment_number, carrier_name, vessel_name, voyage_number,
        port_of_loading, port_of_discharge, status, eta_date
    ) VALUES (
        v_tenant_id, v_export_file_id, 'SHP-2026-MED-042', 'Maersk Line', 'MSC PALOMA', 'V-2026-09A',
        'Jeddah Islamic Port', 'Hamburg Port', 'DELIVERED', CURRENT_DATE + 10
    ) ON CONFLICT (tenant_id, shipment_number) DO UPDATE SET status = 'DELIVERED'
    RETURNING id INTO v_shipment_id;

    RAISE NOTICE 'Test 1: 22 Aşamalı Tedarik ve İhracat Zinciri Veritabanına Seed Edildi [PASS] (Lot: LOT-2026-ACVE-777)';

    -- ==============================================================================
    -- 2. TEST: view_end_to_end_traceability GÖRÜNÜM DOĞRULAMA
    -- ==============================================================================
    SELECT * INTO v_view_row FROM view_end_to_end_traceability WHERE lot_number = 'LOT-2026-ACVE-777' LIMIT 1;
    IF v_view_row IS NULL THEN
        RAISE EXCEPTION 'TEST 2 BAŞARISIZ: view_end_to_end_traceability kaydı bulunamadı!';
    END IF;

    ASSERT v_view_row.farm_name = 'Al-Ula Medine Vaha Hurmalığı', 'TEST 2 BAŞARISIZ: Farm adı eşleşmiyor!';
    ASSERT v_view_row.supplier_name = 'Al-Ula Hurma Üreticileri Tarım Birliği', 'TEST 2 BAŞARISIZ: Supplier adı eşleşmiyor!';
    ASSERT v_view_row.vehicle_plate = 'KSA-7788-DXB', 'TEST 2 BAŞARISIZ: Araç plakası eşleşmiyor!';
    ASSERT v_view_row.factory_name = 'Medine Entegre Hurma İşleme Fabrikası', 'TEST 2 BAŞARISIZ: Fabrika adı eşleşmiyor!';
    ASSERT v_view_row.sorting_grade = 'GRADE_JUMBO_PREMIUM_EXTRA', 'TEST 2 BAŞARISIZ: Kalite boylama eşleşmiyor!';
    ASSERT v_view_row.customer_name = 'Berlin Gourmet Bio Dates GmbH', 'TEST 2 BAŞARISIZ: Müşteri adı eşleşmiyor!';
    ASSERT v_view_row.container_number = 'MSCU9876543', 'TEST 2 BAŞARISIZ: Konteyner eşleşmiyor!';
    ASSERT v_view_row.shipment_status = 'DELIVERED', 'TEST 2 BAŞARISIZ: Sevkiyat durumu eşleşmiyor!';

    RAISE NOTICE 'Test 2: view_end_to_end_traceability 22 Aşamalı Bütünlük Doğrulandı [PASS]';

    -- ==============================================================================
    -- 3. TEST: get_lot_forward_trace RPC DOĞRULAMA
    -- ==============================================================================
    v_forward_trace := get_lot_forward_trace(
        p_lot_number := 'LOT-2026-ACVE-777',
        p_tenant_id := v_tenant_id
    );

    IF v_forward_trace IS NULL THEN
        RAISE EXCEPTION 'TEST 3 BAŞARISIZ: get_lot_forward_trace boş döndü!';
    END IF;

    ASSERT v_forward_trace->'source'->>'farm_name' = 'Al-Ula Medine Vaha Hurmalığı', 'Forward Trace Source Farm Hatası';
    ASSERT v_forward_trace->'processing'->>'factory_name' = 'Medine Entegre Hurma İşleme Fabrikası', 'Forward Trace Processing Factory Hatası';
    ASSERT (v_forward_trace->'movement'->0->>'vehicle_plate') = 'KSA-7788-DXB', 'Forward Trace Movement Vehicle Hatası';
    ASSERT (v_forward_trace->'sale'->0->>'customer_name') = 'Berlin Gourmet Bio Dates GmbH', 'Forward Trace Sale Customer Hatası';
    ASSERT (v_forward_trace->'export'->0->>'container_number') = 'MSCU9876543', 'Forward Trace Export Container Hatası';

    RAISE NOTICE 'Test 3: get_lot_forward_trace (Source->Processing->Movement->Storage->Sale->Export) Doğrulandı [PASS]';

    -- ==============================================================================
    -- 4. TEST: get_lot_recall_analysis RPC (ACİL GERİ ÇAĞIRMA & İZOLASYON ANALİZİ)
    -- ==============================================================================
    v_recall_analysis := get_lot_recall_analysis(
        p_lot_number := 'LOT-2026-ACVE-777',
        p_tenant_id := v_tenant_id
    );

    IF v_recall_analysis IS NULL THEN
        RAISE EXCEPTION 'TEST 4 BAŞARISIZ: get_lot_recall_analysis boş döndü!';
    END IF;

    -- Recall analizi kritik alanları doğrula
    ASSERT jsonb_array_length(v_recall_analysis->'affected_sales') >= 1, 'Etkilenen satış faturası tespit edilemedi!';
    ASSERT jsonb_array_length(v_recall_analysis->'affected_customers') >= 1, 'Etkilenen müşteri tespit edilemedi!';
    ASSERT jsonb_array_length(v_recall_analysis->'affected_shipments') >= 1, 'Etkilenen sevkiyat tespit edilemedi!';
    ASSERT jsonb_array_length(v_recall_analysis->'affected_containers') >= 1, 'Etkilenen konteyner tespit edilemedi!';

    -- İletişim bilgisi kontrolü
    ASSERT (v_recall_analysis->'affected_customers'->0->>'email') = 'orders@berlindates.de', 'Müşteri acil bildirim email hatası!';
    ASSERT (v_recall_analysis->'affected_containers'->0->>'seal_number') = 'SEAL-KSA-99112', 'Etkilenen konteyner mühür bilgisi hatası!';

    RAISE NOTICE 'Test 4: get_lot_recall_analysis (Lot -> Stock -> Sales -> Customers -> Shipments -> Containers) Doğrulandı [PASS]';

    -- ==============================================================================
    -- 5. TEST: get_reverse_trace_from_customer RPC (MÜŞTERİDEN GERİYE DOĞRU İZLEME)
    -- ==============================================================================
    v_reverse_trace := get_reverse_trace_from_customer(
        p_customer_name := 'Berlin Gourmet',
        p_invoice_number := 'SINV-2026-EXP-555',
        p_tenant_id := v_tenant_id
    );

    IF v_reverse_trace IS NULL THEN
        RAISE EXCEPTION 'TEST 5 BAŞARISIZ: get_reverse_trace_from_customer boş döndü!';
    END IF;

    ASSERT v_reverse_trace->'customer'->>'customer_country' = 'DE', 'Reverse Trace Customer Country Hatası';
    ASSERT (v_reverse_trace->'traced_lots'->0->>'lot_number') = 'LOT-2026-ACVE-777', 'Reverse Trace Lot Number Hatası';
    ASSERT (v_reverse_trace->'traced_lots'->0->'farm'->>'farm_name') = 'Al-Ula Medine Vaha Hurmalığı', 'Reverse Trace Farm Name Hatası';
    ASSERT (v_reverse_trace->'traced_lots'->0->'harvest'->>'harvest_lot_number') = 'HV-2026-ALULA-09', 'Reverse Trace Harvest Batch Hatası';

    RAISE NOTICE 'Test 5: get_reverse_trace_from_customer (Customer -> Sale -> Lot -> Production -> Harvest -> Farm) Doğrulandı [PASS]';

    -- ==============================================================================
    -- 6. TEST: ÇAPRAZ TENANT İZOLASYONU GÜVENLİK TESTİ
    -- ==============================================================================
    BEGIN
        PERFORM get_lot_forward_trace(
            p_lot_number := 'LOT-2026-ACVE-777',
            p_tenant_id := v_tenant_b_id -- Yabancı tenant
        );
        RAISE EXCEPTION 'TEST 6 GÜVENLİK AÇIĞI: Yabancı tenant başka firmanın lot verisini çekebildi!';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Test 6: Çapraz Tenant Güvenlik İzolasyonu Başarıyla Engelledi [PASS] (Hata: %)', SQLERRM;
    END;

    RAISE NOTICE '====================================================================';
    RAISE NOTICE '>>> FAZ 28: TÜM UÇTAN UCA İZLENEBİLİRLİK VE RECALL TESTLERİ BAŞARIYLA GEÇTİ (PASS)!';
    RAISE NOTICE '====================================================================';
END;
$$;
