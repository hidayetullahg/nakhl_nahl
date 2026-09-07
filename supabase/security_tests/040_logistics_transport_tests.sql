-- ==============================================================================
-- NAKHL & NAHL — FAZ 20 TEST SUITE: LOGISTICS & TRANSPORT BOUNDED CONTEXT
-- File: supabase/security_tests/040_logistics_transport_tests.sql
-- Purpose:
-- 1. Carrier & Vehicle Master (Reefer Truck, Capacity, Plate)
-- 2. Driver Registration & Carrier Assignment
-- 3. Transport Order Creation (Pickup Warehouse -> Delivery Port, Route)
-- 4. Lot Traceability Link (LOT -> VEHICLE -> TRANSPORT -> WAREHOUSE -> SHIPMENT)
-- 5. Cold Chain Temperature: Normal Logging vs Critical Excursion Breach Trigger
-- 6. Transport Order Delivery Completion (SHIPMENT -> TO -> VEHICLE -> DELIVERY)
-- 7. Multi-Tenant Security & Unauthorized Access Protection (RLS)
-- ==============================================================================

DO $$
DECLARE
    v_tenant_a UUID;
    v_tenant_b UUID;
    v_company_a UUID;
    v_company_b UUID;
    v_user_officer UUID;
    v_user_stranger UUID;
    v_role_admin UUID;
    v_wh_pickup UUID;
    v_wh_delivery UUID;
    v_carrier_party UUID;
    v_vehicle_id UUID;
    v_driver_id UUID;
    v_item_id UUID;
    v_lot_id UUID;
    v_shipment_id UUID;
    v_transport_order_id UUID;
    v_temp_normal_id UUID;
    v_temp_breach_id UUID;
    
    v_is_breached BOOLEAN;
    v_severity VARCHAR(30);
    v_audit_count INT;
    v_trace_count INT;
    v_unauthorized_rows INT;
    v_test_count INT := 0;
    v_pass_count INT := 0;
BEGIN
    RAISE NOTICE '====================================================================';
    RAISE NOTICE '=== FAZ 20: LOGISTICS / TRANSPORT BOUNDED CONTEXT TESTLERİ BAŞLIYOR ===';
    RAISE NOTICE '====================================================================';

    -- 0. KURULUM (SETUP)
    SELECT id INTO v_role_admin FROM roles WHERE code = 'TENANT_ADMIN' AND tenant_id IS NULL LIMIT 1;

    -- Kiracı A (Yetkili)
    INSERT INTO tenants (code, legal_name, display_name)
    VALUES ('TRP_TENANT_A', 'Logistics Operations Tenant A', 'LOTA')
    RETURNING id INTO v_tenant_a;

    INSERT INTO public.users (display_name, email)
    VALUES ('Transport Dispatcher', 'dispatcher@nakhl-test.com')
    RETURNING id INTO v_user_officer;

    INSERT INTO tenant_users (tenant_id, user_id, role_id, status)
    VALUES (v_tenant_a, v_user_officer, v_role_admin, 'ACTIVE');

    INSERT INTO companies (tenant_id, code, legal_name)
    VALUES (v_tenant_a, 'TRP_COMP_A', 'NAKHL Soğuk Zincir Lojistik A.Ş.')
    RETURNING id INTO v_company_a;

    -- Kiracı B (Yetkisiz Saldırgan)
    INSERT INTO tenants (code, legal_name, display_name)
    VALUES ('TRP_TENANT_B', 'Unauthorized Tenant B', 'UTB')
    RETURNING id INTO v_tenant_b;

    INSERT INTO public.users (display_name, email)
    VALUES ('Unauthorized Intruder', 'intruder@nakhl-test.com')
    RETURNING id INTO v_user_stranger;

    INSERT INTO tenant_users (tenant_id, user_id, role_id, status)
    VALUES (v_tenant_b, v_user_stranger, v_role_admin, 'ACTIVE');

    INSERT INTO companies (tenant_id, code, legal_name)
    VALUES (v_tenant_b, 'TRP_COMP_B', 'Competitor Logistics Inc.')
    RETURNING id INTO v_company_b;

    -- Depolar (Yükleme ve Teslim)
    INSERT INTO warehouses (tenant_id, company_id, code, name, allow_negative_stock)
    VALUES (v_tenant_a, v_company_a, 'DEP-MED-01', 'Medine Hurma Soğuk Hava Deposu', TRUE)
    RETURNING id INTO v_wh_pickup;

    INSERT INTO warehouses (tenant_id, company_id, code, name, allow_negative_stock)
    VALUES (v_tenant_a, v_company_a, 'DEP-JED-PORT', 'Cidde Limanı Reefer Terminali', TRUE)
    RETURNING id INTO v_wh_delivery;

    -- Taşıyıcı Firma Partisi (CARRIER)
    INSERT INTO parties (tenant_id, party_type, legal_name, trade_name)
    VALUES (v_tenant_a, 'CARRIER', 'Kızıldeniz Frigofirik Nakliyat Ltd.', 'Red Sea Cold Logistics')
    RETURNING id INTO v_carrier_party;

    -- Ürün & Lot Master
    INSERT INTO items (
        tenant_id, company_id, item_code, sku, item_name,
        category_name, base_unit, product_type, halal_required
    ) VALUES (
        v_tenant_a, v_company_a, 'TRP-SUG-01', 'SKU-SUG-5KG', 'Sugai Medine Hurması (Dondurulmuş)',
        'Hurma', 'Kg', 'FINISHED_GOOD', TRUE
    ) RETURNING id INTO v_item_id;

    INSERT INTO item_lots (
        tenant_id, company_id, item_id, lot_number,
        initial_quantity, remaining_quantity,
        halal_certified, halal_compliance_status, quality_status,
        farm_name, harvest_date, temperature_control_required, target_storage_temp_celsius
    ) VALUES (
        v_tenant_a, v_company_a, v_item_id, 'LOT-TRP-2026-001',
        18000, 18000,
        TRUE, 'COMPLIANT', 'APPROVED',
        'Vadi-i Akik Medine Çiftliği', CURRENT_DATE - INTERVAL '5 days',
        TRUE, -18.00
    ) RETURNING id INTO v_lot_id;


    -- =========================================================================
    -- TEST 1: TAŞIYICI & FRİGOFİRİK ARAÇ TANIMLAMA (VEHICLE MASTER)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    RAISE NOTICE 'TEST 1: Taşıyıcı ve Frigofirik Araç Tanımlama (Reefer Truck)...';

    INSERT INTO vehicles (
        tenant_id, company_id, carrier_party_id, registration_plate,
        vehicle_type, capacity_payload_kg, capacity_volume_cbm,
        is_temperature_controlled, min_temp_celsius, max_temp_celsius, status
    ) VALUES (
        v_tenant_a, v_company_a, v_carrier_party, '4321-JED',
        'REEFER_TRUCK', 22000.00, 65.00,
        TRUE, -25.00, 10.00, 'AVAILABLE'
    ) RETURNING id INTO v_vehicle_id;

    IF EXISTS (
        SELECT 1 FROM vehicles
        WHERE id = v_vehicle_id 
          AND registration_plate = '4321-JED'
          AND is_temperature_controlled = TRUE
    ) THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL (Araç kaydedilemedi)';
    END IF;


    -- =========================================================================
    -- TEST 2: SÜRÜCÜ KAYDI & TAŞIYICI ATAMASI (DRIVER MASTER)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    RAISE NOTICE 'TEST 2: Sürücü Kaydı ve Taşıyıcı İlişkilendirme...';

    INSERT INTO drivers (
        tenant_id, company_id, carrier_party_id, full_name,
        license_number, phone_number, national_id, status
    ) VALUES (
        v_tenant_a, v_company_a, v_carrier_party, 'Halid bin Velid Mansur',
        'DL-SA-982145', '+966 50 123 4567', 'NID-108923412', 'ACTIVE'
    ) RETURNING id INTO v_driver_id;

    IF EXISTS (
        SELECT 1 FROM drivers
        WHERE id = v_driver_id 
          AND license_number = 'DL-SA-982145'
          AND carrier_party_id = v_carrier_party
    ) THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL (Sürücü kaydedilemedi)';
    END IF;


    -- =========================================================================
    -- TEST 3: TAŞIMA EMRİ OLUŞTURMA & ROTA (TRANSPORT ORDER)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    RAISE NOTICE 'TEST 3: Taşıma Emri (Medine Depo -> Cidde Liman Rotası)...';

    -- Dış ticaret sevkiyatı oluştur
    INSERT INTO shipments (
        tenant_id, company_id, shipment_number, transport_mode,
        carrier_company, vessel_or_plate, departure_date, status
    ) VALUES (
        v_tenant_a, v_company_a, 'SHP-TRP-2026-001', 'ROAD',
        'Kızıldeniz Frigofirik Nakliyat', '4321-JED', CURRENT_DATE, 'PREPARING'
    ) RETURNING id INTO v_shipment_id;

    -- Taşıma Emri (Transport Order)
    INSERT INTO transport_orders (
        tenant_id, company_id, transport_order_number, shipment_id,
        carrier_party_id, vehicle_id, driver_id,
        pickup_location_type, pickup_warehouse_id, pickup_address, pickup_time,
        delivery_location_type, delivery_warehouse_id, delivery_address,
        scheduled_delivery_time, route_code, route_description, distance_km, status
    ) VALUES (
        v_tenant_a, v_company_a, 'TO-2026-001', v_shipment_id,
        v_carrier_party, v_vehicle_id, v_driver_id,
        'WAREHOUSE', v_wh_pickup, 'Medine Sanayi Bölgesi Hurma Soğuk Hava Deposu No:14',
        NOW() + INTERVAL '2 hours',
        'PORT', v_wh_delivery, 'Cidde İslam Limanı Gümrüklü Reefer Sahası Rıhtım 5',
        NOW() + INTERVAL '8 hours',
        'MEDINA-JEDDAH-EXPRESS', 'Otoyol 15 ve Otoyol 40 Üzeri Frigo Koridoru', 420.00, 'DISPATCHED'
    ) RETURNING id INTO v_transport_order_id;

    IF EXISTS (
        SELECT 1 FROM transport_orders
        WHERE id = v_transport_order_id 
          AND vehicle_id = v_vehicle_id
          AND driver_id = v_driver_id
          AND status = 'DISPATCHED'
    ) THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL (Taşıma emri oluşturulamadı)';
    END IF;


    -- =========================================================================
    -- TEST 4: TAŞIMA EMRİNE LOT BAĞLANTISI (LOT TRACEABILITY)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    RAISE NOTICE 'TEST 4: Taşıma Kalemine Lot ve Miktar Bağlantısı...';

    INSERT INTO transport_order_items (
        tenant_id, transport_order_id, lot_id, item_id,
        quantity, uom, package_count, pallet_count
    ) VALUES (
        v_tenant_a, v_transport_order_id, v_lot_id, v_item_id,
        15000.00, 'Kg', 3000, 20
    );

    IF EXISTS (
        SELECT 1 FROM transport_order_items
        WHERE transport_order_id = v_transport_order_id 
          AND lot_id = v_lot_id
          AND quantity = 15000.00
    ) THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS (Taşıma kalemi lot iziyle bağlandı)';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL (Taşıma lot bağlantısı başarısız)';
    END IF;


    -- =========================================================================
    -- TEST 5: SOĞUK ZİNCİR SICAKLIK TAKİBİ: NORMAL VS KRİTİK SAPMA (EXCURSION)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    RAISE NOTICE 'TEST 5: Soğuk Zincir Sıcaklık Takibi ve Otomatik Sapma Alarm Tetikleyicisi...';

    -- 5a: Normal Ölçüm (-18.2 °C, Eşikler: -22.0 ile -14.0 arası)
    INSERT INTO cold_chain_temperature_logs (
        tenant_id, company_id, context_type, transport_order_id,
        recorded_temperature, target_temperature, min_threshold, max_threshold,
        sensor_id, notes
    ) VALUES (
        v_tenant_a, v_company_a, 'TRANSPORT_ORDER', v_transport_order_id,
        -18.20, -18.00, -22.00, -14.00, 'SENS-REEFER-01', 'Normal seyir sıcaklığı'
    ) RETURNING id, is_breached, severity INTO v_temp_normal_id, v_is_breached, v_severity;

    IF v_is_breached = FALSE AND v_severity = 'NORMAL' THEN
        RAISE NOTICE '  5a: Normal ölçüm doğrulandı (is_breached=FALSE)';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL (Normal ölçümde sapma algılandı!)';
    END IF;

    -- 5b: Kritik Sıcaklık Sapması (-8.5 °C, Maksimum eşik olan -14.0 °C aşıldı!)
    INSERT INTO cold_chain_temperature_logs (
        tenant_id, company_id, context_type, transport_order_id,
        recorded_temperature, target_temperature, min_threshold, max_threshold,
        sensor_id, notes
    ) VALUES (
        v_tenant_a, v_company_a, 'TRANSPORT_ORDER', v_transport_order_id,
        -8.50, -18.00, -22.00, -14.00, 'SENS-REEFER-01', 'Frigo kompresör arıza alarmı!'
    ) RETURNING id, is_breached, severity INTO v_temp_breach_id, v_is_breached, v_severity;

    SELECT COUNT(*) INTO v_audit_count
    FROM audit_logs
    WHERE tenant_id = v_tenant_a 
      AND entity_type = 'cold_chain_excursion_alert'
      AND entity_id = v_temp_breach_id;

    RAISE NOTICE '  5b: Kritik sapma tespiti: is_breached=%, severity=%, audit_logs_count=%',
        v_is_breached, v_severity, v_audit_count;

    IF v_is_breached = TRUE AND v_severity = 'CRITICAL_EXCURSION' AND v_audit_count = 1 THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS (Kritik soğuk zincir sapması tetiklendi ve audit_logs tablosuna işlendi)';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL (Kritik sapma tetikleyicisi çalışmadı!)';
    END IF;


    -- =========================================================================
    -- TEST 6: SEVKİYAT VE TESLİMAT ZİNCİRİ TAMAMLAMA
    -- (SHIPMENT -> TRANSPORT ORDER -> VEHICLE -> DELIVERY)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    RAISE NOTICE 'TEST 6: Taşıma Emri ve Sevkiyat Teslimat Tamamlama...';

    -- Taşıma emrini ve sevkiyatı DELIVERED yap
    UPDATE transport_orders
    SET status = 'DELIVERED',
        actual_delivery_time = NOW()
    WHERE id = v_transport_order_id;

    UPDATE shipments
    SET status = 'DELIVERED',
        actual_arrival_date = CURRENT_DATE
    WHERE id = v_shipment_id;

    SELECT COUNT(*) INTO v_trace_count
    FROM view_transport_lot_traceability
    WHERE transport_order_id = v_transport_order_id
      AND lot_id = v_lot_id
      AND registration_plate = '4321-JED'
      AND driver_name = 'Halid bin Velid Mansur'
      AND transport_status = 'DELIVERED';

    RAISE NOTICE '  EXPECTED: trace_count = 1';
    RAISE NOTICE '  ACTUAL:   trace_count = %', v_trace_count;

    IF v_trace_count = 1 THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS (Uçtan uca LOT -> VEHICLE -> TRANSPORT -> DELIVERY izlenebilirliği doğrulandı)';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL (Taşıma izlenebilirlik görünümü eşleşmedi)';
    END IF;


    -- =========================================================================
    -- TEST 7: ÇOK KİRACILI GÜVENLİK & YETKİSİZ ERİŞİM ENGELİ (RLS ISOLATION)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    RAISE NOTICE 'TEST 7: Kiracı İzolasyonu ve Yetkisiz Erişim Denetimi (RLS)...';

    -- Kiracı B oturumu simülasyonu
    SET LOCAL ROLE authenticated;
    EXECUTE 'SET LOCAL "request.jwt.claim.sub" TO ''' || v_user_stranger::text || '''';

    SELECT COUNT(*) INTO v_unauthorized_rows
    FROM transport_orders
    WHERE tenant_id = v_tenant_a;

    RESET ROLE;

    RAISE NOTICE '  Kiracı B tarafından görülebilen Kiracı A sipariş sayısı: % (Beklenen: 0)', v_unauthorized_rows;

    IF v_unauthorized_rows = 0 THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '  RESULT:   PASS (Yetkisiz kiracı erişimi RLS tarafından tamamen engellendi)';
    ELSE
        RAISE EXCEPTION '  RESULT:   FAIL (Yetkisiz kiracı verilere erişebildi!)';
    END IF;


    -- =========================================================================
    -- TEST RAPORU
    -- =========================================================================
    RAISE NOTICE '====================================================================';
    RAISE NOTICE '=== FAZ 20 TEST SONUÇLARI: % / % TEST BAŞARIYLA GEÇTİ (PASS)     ===', v_pass_count, v_test_count;
    RAISE NOTICE '====================================================================';

    -- Temizlik (Test verilerini temizle)
    DELETE FROM audit_logs WHERE tenant_id = v_tenant_a;
    DELETE FROM cold_chain_temperature_logs WHERE tenant_id = v_tenant_a;
    DELETE FROM transport_order_items WHERE tenant_id = v_tenant_a;
    DELETE FROM transport_orders WHERE tenant_id = v_tenant_a;
    DELETE FROM shipments WHERE tenant_id = v_tenant_a;
    DELETE FROM item_lots WHERE tenant_id = v_tenant_a;
    DELETE FROM items WHERE tenant_id = v_tenant_a;
    DELETE FROM vehicles WHERE tenant_id = v_tenant_a;
    DELETE FROM drivers WHERE tenant_id = v_tenant_a;
    DELETE FROM warehouses WHERE tenant_id = v_tenant_a;
    DELETE FROM parties WHERE tenant_id = v_tenant_a;
    DELETE FROM companies WHERE tenant_id IN (v_company_a, v_company_b);
    DELETE FROM tenant_users WHERE tenant_id IN (v_tenant_a, v_tenant_b);
    DELETE FROM public.users WHERE id IN (v_user_officer, v_user_stranger);
    DELETE FROM tenants WHERE id IN (v_tenant_a, v_tenant_b);

    RAISE NOTICE '=== TEST VERİLERİ BAŞARIYLA TEMİZLENDİ ===';
END $$;
