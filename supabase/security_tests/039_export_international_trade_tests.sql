-- ==============================================================================
-- NAKHL & NAHL — FAZ 19 TEST SUITE: EXPORT / INTERNATIONAL TRADE BOUNDED CONTEXT
-- File: supabase/security_tests/039_export_international_trade_tests.sql
-- Purpose:
-- 1. Customer -> Sales Order -> Export File (CIF Mersin)
-- 2. Export File Item -> Lot Traceability & HS Code (0804.10.00.00)
-- 3. Customs Declaration (GÇB) & Customs Clearance
-- 4. ISO Container & Duplicate Active Container Prevention Test
-- 5. Shipment & Delivery Chain (EXPORT FILE -> CONTAINER -> SHIPMENT -> DELIVERY)
-- 6. Export Documents Context (Commercial Invoice, Packing List, COO, Halal, B/L)
-- 7. End-to-End Lot Traceability View (view_export_lot_traceability)
-- ==============================================================================

DO $$
DECLARE
    v_tenant_id UUID;
    v_company_id UUID;
    v_user_officer UUID;
    v_role_admin UUID;
    v_wh_id UUID;
    v_party_customer UUID;
    v_party_broker UUID;
    v_item_id UUID;
    v_lot_id UUID;
    v_so_id UUID;
    v_invoice_id UUID;
    v_export_file_id UUID;
    v_export_item_id UUID;
    v_customs_id UUID;
    v_container_id UUID;
    v_shipment_id UUID;
    
    v_trace_count INT;
    v_doc_count INT;
    v_exception_caught BOOLEAN;
    v_test_count INT := 0;
    v_pass_count INT := 0;
BEGIN
    RAISE NOTICE '====================================================================';
    RAISE NOTICE '=== FAZ 19: EXPORT / INTERNATIONAL TRADE TESTLERİ BAŞLIYOR       ===';
    RAISE NOTICE '====================================================================';

    -- 0. KURULUM (SETUP)
    SELECT id INTO v_role_admin FROM roles WHERE code = 'TENANT_ADMIN' AND tenant_id IS NULL LIMIT 1;

    INSERT INTO tenants (code, legal_name, display_name)
    VALUES ('EXP_TENANT', 'Export & Logistics Tenant', 'ELT')
    RETURNING id INTO v_tenant_id;

    INSERT INTO public.users (display_name, email)
    VALUES ('Export Operations Officer', 'export_officer@nakhl-test.com')
    RETURNING id INTO v_user_officer;

    INSERT INTO tenant_users (tenant_id, user_id, role_id, status)
    VALUES (v_tenant_id, v_user_officer, v_role_admin, 'ACTIVE');

    INSERT INTO companies (tenant_id, code, legal_name)
    VALUES (v_tenant_id, 'EXP_COMP', 'NAKHL Dış Ticaret ve Uluslararası İhracat A.Ş.')
    RETURNING id INTO v_company_id;

    INSERT INTO warehouses (tenant_id, company_id, code, name, allow_negative_stock)
    VALUES (v_tenant_id, v_company_id, 'WH-EXP-01', 'Cidde Liman İhracat Antreposu', TRUE)
    RETURNING id INTO v_wh_id;

    -- Müşteri Partisi (Uluslararası Alıcı)
    INSERT INTO parties (tenant_id, party_type, legal_name, trade_name)
    VALUES (v_tenant_id, 'CUSTOMER', 'Anadolu Hurma İthalat ve Dağıtım A.Ş.', 'Anadolu Hurma TR')
    RETURNING id INTO v_party_customer;

    -- Gümrük Müşaviri Partisi (Customs Broker)
    INSERT INTO parties (tenant_id, party_type, legal_name, trade_name)
    VALUES (v_tenant_id, 'CUSTOMS_AGENT', 'Kızıldeniz Global Gümrükleme Müşavirliği', 'Red Sea Customs')
    RETURNING id INTO v_party_broker;

    -- Ürün Master (Acve Hurması)
    INSERT INTO items (
        tenant_id, company_id, item_code, sku, item_name,
        category_name, base_unit, product_type, halal_required
    ) VALUES (
        v_tenant_id, v_company_id, 'EXP-AJW-01', 'SKU-EXP-AJW-1KG', 'Acve Medine Hurması (İhracat Kalite)',
        'Hurma', 'Kg', 'FINISHED_GOOD', TRUE
    ) RETURNING id INTO v_item_id;

    -- Parti / Lot (Al-Ula Medine Hasadı)
    INSERT INTO item_lots (
        tenant_id, company_id, item_id, lot_number,
        initial_quantity, remaining_quantity,
        halal_certified, halal_compliance_status, quality_status,
        farm_name, harvest_date
    ) VALUES (
        v_tenant_id, v_company_id, v_item_id, 'LOT-EXP-2026-001',
        25000, 25000,
        TRUE, 'COMPLIANT', 'APPROVED',
        'Al-Ula Medine Vaha Çiftliği', CURRENT_DATE - INTERVAL '10 days'
    ) RETURNING id INTO v_lot_id;


    -- =========================================================================
    -- TEST 1: CUSTOMER -> SALES ORDER -> EXPORT FILE (CIF MERSİN)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    RAISE NOTICE 'TEST 1: Müşteri ve Satış Siparişinden İhracat Dosyası Açma...';

    -- Satış Siparişi
    INSERT INTO sales_orders (
        tenant_id, company_id, order_number, customer_party_id,
        order_date, total_amount, currency
    ) VALUES (
        v_tenant_id, v_company_id, 'SO-EXP-2026-888', v_party_customer,
        CURRENT_DATE, 125000.00, 'USD'
    ) RETURNING id INTO v_so_id;

    -- İhracat Dosyası
    INSERT INTO export_files (
        tenant_id, company_id, export_number, customer_party_id, sales_order_id,
        origin_country_code, destination_country_code, origin_port, destination_port,
        incoterm, currency_code, fob_value, freight_value, insurance_value, cif_value,
        status, notes
    ) VALUES (
        v_tenant_id, v_company_id, 'EXP-2026-TR-001', v_party_customer, v_so_id,
        'SA', 'TR', 'Cidde İslam Limanı (KSA)', 'Mersin Uluslararası Limanı (TR)',
        'CIF', 'USD', 115000.00, 8500.00, 1500.00, 125000.00,
        'CONFIRMED', '2026 Sezonu Acve İhracat Kontratı'
    ) RETURNING id INTO v_export_file_id;

    IF EXISTS (
        SELECT 1 FROM export_files
        WHERE id = v_export_file_id 
          AND export_number = 'EXP-2026-TR-001'
          AND incoterm = 'CIF'
    ) THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL (İhracat dosyası açılamadı!)';
    END IF;


    -- =========================================================================
    -- TEST 2: İHRACAT KALEMİNE LOT & HS CODE BAĞLANTISI (0804.10.00.00)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    RAISE NOTICE 'TEST 2: İhracat Kalemine Lot ve GTİP/HS Kodu Bağlama...';

    INSERT INTO export_file_items (
        tenant_id, export_file_id, item_id, lot_id, hs_code,
        quantity, uom, unit_price, total_price,
        net_weight_kg, gross_weight_kg, pallet_count, package_count
    ) VALUES (
        v_tenant_id, v_export_file_id, v_item_id, v_lot_id, '0804.10.00.00',
        20000, 'Kg', 5.75, 115000.00,
        20000.00, 21200.00, 20, 2000
    ) RETURNING id INTO v_export_item_id;

    IF EXISTS (
        SELECT 1 FROM export_file_items
        WHERE id = v_export_item_id 
          AND lot_id = v_lot_id
          AND hs_code = '0804.10.00.00'
    ) THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS (İhracat kalemi lot izlenebilirliği ile bağlandı)';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL (İhracat kalemi lot bağlantısı kurulamadı)';
    END IF;


    -- =========================================================================
    -- TEST 3: GÜMRÜK BEYANNAMESİ (GÇB) & GÜMRÜK ONAYI
    -- =========================================================================
    v_test_count := v_test_count + 1;
    RAISE NOTICE 'TEST 3: Gümrük Çıkış Beyannamesi (GÇB) ve Muayene Kaydı...';

    INSERT INTO customs_declarations (
        tenant_id, company_id, export_file_id, declaration_number,
        declaration_date, customs_office, hs_code, country_of_origin,
        customs_value, currency_code, duties_and_taxes, clearance_date,
        status, customs_broker_party_id, notes
    ) VALUES (
        v_tenant_id, v_company_id, v_export_file_id, 'GCB-2026-JED-94812',
        CURRENT_DATE, 'Cidde Liman Gümrük Müdürlüğü (Zakat, Tax and Customs Authority - ZATCA)',
        '0804.10.00.00', 'SA', 115000.00, 'USD', 0.00, CURRENT_DATE,
        'CLEARED', v_party_broker, 'Yeşil hat çıkış izni verildi'
    ) RETURNING id INTO v_customs_id;

    IF EXISTS (
        SELECT 1 FROM customs_declarations
        WHERE id = v_customs_id 
          AND status = 'CLEARED'
    ) THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS (GÇB başarıyla onaylandı ve gümrük temizlendi)';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL (Gümrük beyannamesi kaydedilemedi)';
    END IF;


    -- =========================================================================
    -- TEST 4: SOĞUK ZİNCİR KONTEYNER TANIMLAMA & DUPLICATE ENGELİ
    -- =========================================================================
    v_test_count := v_test_count + 1;
    RAISE NOTICE 'TEST 4: ISO Konteyner Tanımlama ve Mükerrer Aktif Konteyner Engeli...';

    -- İlk Konteyner Ataması
    INSERT INTO export_containers (
        tenant_id, company_id, export_file_id, container_number,
        seal_number, container_type, tare_weight_kg, gross_weight_kg,
        volume_cbm, temperature_setting_celsius, is_active
    ) VALUES (
        v_tenant_id, v_company_id, v_export_file_id, 'MSKU-948123-0',
        'SEAL-ZATCA-98124', '40_REEFER', 4600.00, 25800.00,
        67.50, -18.00, TRUE
    ) RETURNING id INTO v_container_id;

    -- Duplicate Konteyner No Denemesi (Aynı konteyner aktif iken tekrar eklenemez!)
    v_exception_caught := FALSE;
    BEGIN
        INSERT INTO export_containers (
            tenant_id, company_id, export_file_id, container_number,
            seal_number, container_type, is_active
        ) VALUES (
            v_tenant_id, v_company_id, v_export_file_id, 'MSKU-948123-0',
            'SEAL-DUPLICATE-001', '40_REEFER', TRUE
        );
    EXCEPTION WHEN OTHERS THEN
        v_exception_caught := TRUE;
        RAISE NOTICE '  YAKALANAN HATA (BEKLENEN): %', SQLERRM;
    END;

    RAISE NOTICE '  EXPECTED: Exception caught = TRUE (Duplicate active container blocked)';
    RAISE NOTICE '  ACTUAL:   Exception caught = %', v_exception_caught;

    IF v_exception_caught THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS (Mükerrer aktif konteyner kullanımı başarıyla engellendi)';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL (Aynı konteyner mükerrer aktif eklenebildi!)';
    END IF;


    -- =========================================================================
    -- TEST 5: SEVKİYAT VE TESLİMAT ZİNCİRİ
    -- (EXPORT FILE -> CONTAINER -> SHIPMENT -> DELIVERY)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    RAISE NOTICE 'TEST 5: EXPORT FILE -> CONTAINER -> SHIPMENT -> DELIVERY Zinciri...';

    -- Sevkiyat Kaydı
    INSERT INTO shipments (
        tenant_id, company_id, export_file_id, shipment_number,
        transport_mode, carrier_company, vessel_or_plate,
        customs_declaration_no, bill_of_lading_no,
        departure_date, estimated_arrival_date, status
    ) VALUES (
        v_tenant_id, v_company_id, v_export_file_id, 'SHP-2026-EXP-001',
        'SEA', 'Maersk Line A/S', 'MSC PALOMA / V.2601',
        'GCB-2026-JED-94812', 'MSK-MED-TR-098234',
        CURRENT_DATE, CURRENT_DATE + INTERVAL '12 days', 'IN_TRANSIT'
    ) RETURNING id INTO v_shipment_id;

    -- Konteynere sevkiyatı bağla
    UPDATE export_containers
    SET shipment_id = v_shipment_id
    WHERE id = v_container_id;

    -- Teslim Edildi durumuna geçiş (DELIVERED)
    UPDATE shipments
    SET status = 'DELIVERED',
        actual_arrival_date = CURRENT_DATE + INTERVAL '11 days'
    WHERE id = v_shipment_id;

    UPDATE export_files
    SET status = 'DELIVERED'
    WHERE id = v_export_file_id;

    IF EXISTS (
        SELECT 1 FROM shipments
        WHERE id = v_shipment_id 
          AND status = 'DELIVERED'
          AND actual_arrival_date IS NOT NULL
    ) AND EXISTS (
        SELECT 1 FROM export_files
        WHERE id = v_export_file_id AND status = 'DELIVERED'
    ) THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS (Sevkiyat ve dosya teslimat zinciri doğrulandı)';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL (Teslimat statü geçişi başarısız)';
    END IF;


    -- =========================================================================
    -- TEST 6: DIŞ TİCARET BELGELERİ BAĞLANTISI (DOCUMENT CONTEXT)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    RAISE NOTICE 'TEST 6: Commercial Invoice, Packing List, COO, Halal, B/L Evrakları...';

    INSERT INTO export_documents (
        tenant_id, company_id, export_file_id, shipment_id,
        document_type, document_number, document_url, is_verified
    ) VALUES 
        (v_tenant_id, v_company_id, v_export_file_id, v_shipment_id, 'COMMERCIAL_INVOICE', 'INV-EXP-2026-001', 'https://docs.nakhl.com/exp/inv-001.pdf', TRUE),
        (v_tenant_id, v_company_id, v_export_file_id, v_shipment_id, 'PACKING_LIST', 'PL-EXP-2026-001', 'https://docs.nakhl.com/exp/pl-001.pdf', TRUE),
        (v_tenant_id, v_company_id, v_export_file_id, v_shipment_id, 'CERTIFICATE_OF_ORIGIN', 'COO-SA-2026-99', 'https://docs.nakhl.com/exp/coo-99.pdf', TRUE),
        (v_tenant_id, v_company_id, v_export_file_id, v_shipment_id, 'HALAL_CERTIFICATE', 'SMIIC-EXP-2026-44', 'https://docs.nakhl.com/exp/halal-44.pdf', TRUE),
        (v_tenant_id, v_company_id, v_export_file_id, v_shipment_id, 'BILL_OF_LADING', 'MSK-MED-TR-098234', 'https://docs.nakhl.com/exp/bl-098234.pdf', TRUE);

    SELECT COUNT(*) INTO v_doc_count
    FROM export_documents
    WHERE export_file_id = v_export_file_id;

    RAISE NOTICE '  EXPECTED: doc_count = 5';
    RAISE NOTICE '  ACTUAL:   doc_count = %', v_doc_count;

    IF v_doc_count = 5 THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS (Tüm dış ticaret evrakları bağlandı)';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL (Dış ticaret evrakları eksik)';
    END IF;


    -- =========================================================================
    -- TEST 7: UÇTAN UCA LOT İZLENEBİLİRLİK GÖRÜNÜMÜ DOĞRULAMA
    -- =========================================================================
    v_test_count := v_test_count + 1;
    RAISE NOTICE 'TEST 7: Uçtan Uca Lot İzlenebilirlik Görünümünün Denetlenmesi...';

    SELECT COUNT(*) INTO v_trace_count
    FROM view_export_lot_traceability
    WHERE export_file_id = v_export_file_id
      AND lot_id = v_lot_id
      AND hs_code = '0804.10.00.00'
      AND container_number = 'MSKU-948123-0'
      AND customs_declaration_no = 'GCB-2026-JED-94812'
      AND shipment_status = 'DELIVERED';

    RAISE NOTICE '  EXPECTED: trace_count = 1';
    RAISE NOTICE '  ACTUAL:   trace_count = %', v_trace_count;

    IF v_trace_count = 1 THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS (Uçtan uca izlenebilirlik görünümü başarıyla doğrulandı)';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL (İzlenebilirlik görünümünde eksik veya hatalı alanlar var!)';
    END IF;


    -- =========================================================================
    -- TEST RAPORU
    -- =========================================================================
    RAISE NOTICE '====================================================================';
    RAISE NOTICE '=== FAZ 19 TEST SONUÇLARI: % / % TEST BAŞARIYLA GEÇTİ (PASS)     ===', v_pass_count, v_test_count;
    RAISE NOTICE '====================================================================';

    -- Temizlik (Test verilerini temizle)
    DELETE FROM export_documents WHERE tenant_id = v_tenant_id;
    DELETE FROM export_containers WHERE tenant_id = v_tenant_id;
    DELETE FROM shipments WHERE tenant_id = v_tenant_id;
    DELETE FROM customs_declarations WHERE tenant_id = v_tenant_id;
    DELETE FROM export_file_items WHERE tenant_id = v_tenant_id;
    DELETE FROM export_files WHERE tenant_id = v_tenant_id;
    DELETE FROM sales_orders WHERE tenant_id = v_tenant_id;
    DELETE FROM item_lots WHERE tenant_id = v_tenant_id;
    DELETE FROM items WHERE tenant_id = v_tenant_id;
    DELETE FROM warehouses WHERE tenant_id = v_tenant_id;
    DELETE FROM parties WHERE tenant_id = v_tenant_id;
    DELETE FROM companies WHERE tenant_id = v_tenant_id;
    DELETE FROM tenant_users WHERE tenant_id = v_tenant_id;
    DELETE FROM public.users WHERE id = v_user_officer;
    DELETE FROM tenants WHERE id = v_tenant_id;

    RAISE NOTICE '=== TEST VERİLERİ BAŞARIYLA TEMİZLENDİ ===';
END $$;
