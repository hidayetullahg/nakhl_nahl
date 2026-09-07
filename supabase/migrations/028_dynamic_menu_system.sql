-- ==============================================================================
-- NAKHL & NAHL — MIGRATION 028: DİNAMİK MENÜ VE MODÜLER NAVİGASYON
-- Purpose: modules, menu_definitions ve menü ağacı başlangıç verileri
-- ==============================================================================

-- 1. Modüller (Modules)
CREATE TABLE IF NOT EXISTS modules (
    code VARCHAR(50) PRIMARY KEY, -- ACCOUNTING, INVENTORY, HALAL, EXPORT, AGRI, CRM, HR
    name VARCHAR(100) NOT NULL,
    description TEXT,
    is_core BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- 2. Menü Tanımları (Menu Definitions)
CREATE TABLE IF NOT EXISTS menu_definitions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    module_code VARCHAR(50) NOT NULL REFERENCES modules(code) ON DELETE CASCADE,
    parent_id UUID REFERENCES menu_definitions(id) ON DELETE CASCADE,
    menu_key VARCHAR(100) NOT NULL, -- Çeviri sözlük anahtarı (Örn: 'menu.journal_entries')
    route_path VARCHAR(150) NOT NULL,
    icon_name VARCHAR(50) NOT NULL, -- IconData veya SVG anahtarı
    required_permission VARCHAR(100), -- Yetki kontrolü (Örn: 'ACCOUNTING.VIEW')
    sort_order INT NOT NULL DEFAULT 0,
    is_visible BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Çekirdek Modüller (Seed Data)
INSERT INTO modules (code, name, is_core, sort_order)
VALUES
    ('DASHBOARD', 'Genel Yönetim Paneli', TRUE, 1),
    ('CARI', 'Cari Hesap Yönetimi', TRUE, 2),
    ('ACCOUNTING', 'Çift Taraflı Muhasebe & Kasa', TRUE, 3),
    ('INVENTORY', 'Stok & Depo Yönetimi', TRUE, 4),
    ('EXPORT', 'Dış Ticaret & İhracat', FALSE, 5),
    ('HALAL', 'Helal Uygunluk & Kalite', FALSE, 6),
    ('AGRI', 'Tarım & Hurma Tedarik', FALSE, 7),
    ('REPORTING', 'Küresel Raporlama Merkezi', TRUE, 8)
ON CONFLICT (code) DO NOTHING;

-- 4. Çekirdek Menü Ağacı (Seed Data)
INSERT INTO menu_definitions (module_code, parent_id, menu_key, route_path, icon_name, required_permission, sort_order)
VALUES
    ('DASHBOARD', NULL, 'menu.dashboard', '/dashboard', 'dashboard_rounded', NULL, 1),
    ('CARI', NULL, 'menu.cariler', '/cariler', 'contacts_rounded', 'USER.MANAGE', 2),
    ('ACCOUNTING', NULL, 'menu.accounting', '/accounting', 'account_balance_rounded', 'ACCOUNTING.VIEW', 3),
    ('INVENTORY', NULL, 'menu.inventory', '/inventory', 'inventory_2_rounded', 'INVENTORY.VIEW', 4),
    ('EXPORT', NULL, 'menu.export', '/export', 'local_shipping_rounded', 'EXPORT.VIEW', 5),
    ('HALAL', NULL, 'menu.halal', '/halal', 'verified_rounded', 'HALAL.VIEW', 6),
    ('REPORTING', NULL, 'menu.reporting', '/reporting', 'assessment_rounded', NULL, 7)
ON CONFLICT DO NOTHING;

-- 5. İndeksler
CREATE INDEX IF NOT EXISTS idx_menu_module ON menu_definitions(module_code);
CREATE INDEX IF NOT EXISTS idx_menu_parent ON menu_definitions(parent_id);
