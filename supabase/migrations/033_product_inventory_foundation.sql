-- ==============================================================================
-- NAKHL & NAHL — MIGRATION 033: PRODUCT & INVENTORY FOUNDATION (FAZ 13)
-- Purpose:
-- 1. items (Product Master): SKU, Product Types, Traceability, Halal, Quality
-- 2. item_lots (Lot Traceability): Farm -> Harvest -> Supplier -> Factory -> Processing -> Packaging -> Lot -> Warehouse -> Sale
-- 3. stock_ledger_entries: Standardize movement types (PURCHASE, RECEIPT, TRANSFER, SALE, CONSUMPTION, PRODUCTION, WASTE, ADJUSTMENT, RETURN) & direction (IN/OUT)
-- 4. warehouses: allow_negative_stock policy flag
-- 5. Negatif stok kontrol ve override audit tetikleyicisi (trg_check_negative_stock_policy)
-- ==============================================================================

-- 1. PRODUCT MASTER GENİŞLETMESİ (SKU & PRODUCT TYPES)
ALTER TABLE items ADD COLUMN IF NOT EXISTS sku VARCHAR(100);
CREATE INDEX IF NOT EXISTS idx_items_sku ON items(company_id, sku);

-- 2. PARTİ / LOT DERİN İZLENEBİLİRLİK ZİNCİRİ (FARM -> HARVEST -> PROCESSING -> PACKAGING -> LOT)
ALTER TABLE item_lots ADD COLUMN IF NOT EXISTS farm_name VARCHAR(150);
ALTER TABLE item_lots ADD COLUMN IF NOT EXISTS harvest_date DATE;
ALTER TABLE item_lots ADD COLUMN IF NOT EXISTS harvest_batch_number VARCHAR(100);
ALTER TABLE item_lots ADD COLUMN IF NOT EXISTS processing_facility VARCHAR(150);
ALTER TABLE item_lots ADD COLUMN IF NOT EXISTS processing_date DATE;
ALTER TABLE item_lots ADD COLUMN IF NOT EXISTS packaging_date DATE;
ALTER TABLE item_lots ADD COLUMN IF NOT EXISTS packaging_type VARCHAR(50) DEFAULT 'BOX';
ALTER TABLE item_lots ADD COLUMN IF NOT EXISTS temperature_control_required BOOLEAN DEFAULT TRUE;
ALTER TABLE item_lots ADD COLUMN IF NOT EXISTS target_storage_temp_celsius NUMERIC(5,2) DEFAULT -18.0;

-- 3. DEPO BAZLI NEGATİF STOK POLİTİKASI
ALTER TABLE warehouses ADD COLUMN IF NOT EXISTS allow_negative_stock BOOLEAN NOT NULL DEFAULT FALSE;

-- 4. STOK HAREKET DEFTERİ GELİŞMİŞ ALANLARI & YÖN BELİRLEME
ALTER TABLE stock_ledger_entries ADD COLUMN IF NOT EXISTS direction VARCHAR(5) DEFAULT 'IN';

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_stock_ledger_direction'
    ) THEN
        ALTER TABLE stock_ledger_entries 
        ADD CONSTRAINT chk_stock_ledger_direction 
        CHECK (direction IN ('IN', 'OUT'));
    END IF;
END $$;

-- Yönün (direction) otomatik belirlenmesi
CREATE OR REPLACE FUNCTION set_stock_movement_direction()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.quantity >= 0 THEN
        NEW.direction := 'IN';
    ELSE
        NEW.direction := 'OUT';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_set_stock_movement_direction ON stock_ledger_entries;
CREATE TRIGGER trg_set_stock_movement_direction
BEFORE INSERT ON stock_ledger_entries
FOR EACH ROW EXECUTE FUNCTION set_stock_movement_direction();

-- 5. NEGATİF STOK KONTROL VE OVERRIDE AUDIT TETİKLEYİCİSİ
CREATE OR REPLACE FUNCTION check_negative_stock_policy()
RETURNS TRIGGER AS $$
DECLARE
    v_allow_negative BOOLEAN;
    v_current_balance NUMERIC(15,3);
    v_warehouse_name VARCHAR(150);
    v_item_code VARCHAR(100);
    v_user_role VARCHAR(50);
    v_norm_movement VARCHAR(50);
BEGIN
    -- Sadece çıkış (negatif miktar) hareketlerinde kontrol edilir
    IF NEW.quantity < 0 THEN
        -- Deponun negatif stok politikasını çek
        SELECT allow_negative_stock, name INTO v_allow_negative, v_warehouse_name
        FROM warehouses
        WHERE id = NEW.warehouse_id;

        -- Mevcut kümülatif bakiye
        SELECT COALESCE(SUM(quantity), 0) INTO v_current_balance
        FROM stock_ledger_entries
        WHERE tenant_id = NEW.tenant_id
          AND company_id = NEW.company_id
          AND warehouse_id = NEW.warehouse_id
          AND item_id = NEW.item_id;

        -- Eğer çıkış sonrası bakiye 0'ın altına düşüyorsa:
        IF (v_current_balance + NEW.quantity) < 0 THEN
            SELECT item_code INTO v_item_code FROM items WHERE id = NEW.item_id;

            -- KONTROL 1: Depo bazlı izin kontrolü
            IF v_allow_negative = FALSE OR v_allow_negative IS NULL THEN
                RAISE EXCEPTION 'NEGATİF STOK ENGELİ: "%" deposunda "%" kodlu ürün için yetersiz stok! Mevcut: %, Çıkış Talebi: %, Oluşacak Bakiye: %. Bu depoda negatif stoka izin verilmemektedir.',
                    v_warehouse_name, v_item_code, v_current_balance, NEW.quantity, (v_current_balance + NEW.quantity);
            END IF;

            -- KONTROL 2: Hareket türü kontrolü (Negatif stoka sadece belirli operasyonel hareketlerde izin verilir)
            v_norm_movement := UPPER(TRIM(NEW.movement_type));
            IF v_norm_movement NOT IN ('SALE', 'SALES_ISSUE', 'ADJUSTMENT', 'TRANSFER', 'TRANSFER_OUT', 'CONSUMPTION') THEN
                RAISE EXCEPTION 'NEGATİF STOK HAREKET TÜRÜ ENGELİ: "%" hareket türü negatif stok bakiyesi oluşturamaz! Sadece SALE, ADJUSTMENT, CONSUMPTION, TRANSFER türlerinde override geçerlidir.',
                    v_norm_movement;
            END IF;

            -- KONTROL 3: Rol kontrolü (Kullanıcı belirtilmişse denetlenir)
            IF NEW.created_by IS NOT NULL THEN
                SELECT r.code INTO v_user_role
                FROM tenant_users tu
                JOIN roles r ON r.id = tu.role_id
                WHERE tu.tenant_id = NEW.tenant_id AND tu.user_id = NEW.created_by
                LIMIT 1;

                IF v_user_role IS NOT NULL AND v_user_role NOT IN ('SUPER_ADMIN', 'TENANT_ADMIN', 'COMPANY_ADMIN', 'WAREHOUSE_MANAGER') THEN
                    RAISE EXCEPTION 'NEGATİF STOK YETKİ ENGELİ: Kullanıcı rolü ("%") negatif stok override yetkisine sahip değildir. Yalnızca Depo Şefi veya Yönetici izin verebilir.',
                        v_user_role;
                END IF;
            END IF;

            -- KONTROL 4: Override Audit Kaydı
            INSERT INTO audit_logs (
                tenant_id,
                user_id,
                company_id,
                action,
                entity_type,
                entity_id,
                new_data
            ) VALUES (
                NEW.tenant_id,
                NEW.created_by,
                NEW.company_id,
                'CREATE',
                'negative_stock_override',
                NEW.id,
                jsonb_build_object(
                    'warehouse_id', NEW.warehouse_id,
                    'warehouse_name', v_warehouse_name,
                    'item_id', NEW.item_id,
                    'item_code', v_item_code,
                    'lot_id', NEW.lot_id,
                    'movement_type', NEW.movement_type,
                    'previous_balance', v_current_balance,
                    'exit_quantity', NEW.quantity,
                    'new_negative_balance', (v_current_balance + NEW.quantity),
                    'document_reference', NEW.document_reference,
                    'user_role', v_user_role,
                    'timestamp', NOW()
                )
            );
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS trg_check_negative_stock_policy ON stock_ledger_entries;
CREATE TRIGGER trg_check_negative_stock_policy
BEFORE INSERT ON stock_ledger_entries
FOR EACH ROW EXECUTE FUNCTION check_negative_stock_policy();
