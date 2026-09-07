-- ==============================================================================
-- NAKHL & NAHL — CORE DATABASE BUILD v1.0
-- Migration: 020_seed_system_data.sql
-- Purpose: Sistem başlangıç verileri (Paketler, Global Roller, Temel İzinler).
-- ==============================================================================

-- 1. SaaS Paketleri
INSERT INTO saas_plans (code, name, description, max_users, max_companies, max_warehouses, max_storage_gb)
VALUES 
    ('FREE_TRIAL', 'Ücretsiz Deneme', '14 Günlük Tüm Özellikler Açık Deneme', 3, 1, 1, 2),
    ('STARTER', 'Başlangıç Paketi', 'Küçük İşletmeler İçin Temel ERP', 5, 1, 2, 10),
    ('PROFESSIONAL', 'Profesyonel Paket', 'Büyüyen Dış Ticaret Şirketleri', 25, 3, 5, 50),
    ('ENTERPRISE', 'Kurumsal Grup', 'Çok Şirketli, Sınırsız Depo ve Ülke', 100, 10, 25, 500)
ON CONFLICT (code) DO NOTHING;

-- 2. Global Sistem Rolleri
INSERT INTO roles (tenant_id, code, name, description, is_system)
VALUES
    (NULL, 'SUPER_ADMIN', 'Platform Süper Yöneticisi', 'Tüm SaaS altyapısına tam erişim', TRUE),
    (NULL, 'TENANT_ADMIN', 'Şirket/Tenant Yöneticisi', 'Tenant içindeki tüm modüllere ve şirketlere tam yetki', TRUE),
    (NULL, 'COMPANY_ADMIN', 'Şirket Müdürü', 'Belirli bir tüzel şirkete tam yetki', TRUE),
    (NULL, 'ACCOUNTANT', 'Mali Müşavir / Muhasebeci', 'Kasa, banka, fatura ve defter kayıtları', TRUE),
    (NULL, 'WAREHOUSE_MANAGER', 'Depo ve Lojistik Şefi', 'Stok hareketleri, palet, raf ve sevkiyat', TRUE),
    (NULL, 'SALES_MANAGER', 'Satış ve İhracat Yöneticisi', 'Müşteri carileri, siparişler ve ihracat dosyaları', TRUE),
    (NULL, 'QUALITY_MANAGER', 'Helal ve Kalite Denetçisi', 'Laboratuvar analizleri, sertifikalar ve parti kontrolü', TRUE),
    (NULL, 'VIEWER', 'Salt Okunur İzleyici', 'Yalnızca rapor ve dashboard görüntüleme', TRUE)
ON CONFLICT (tenant_id, code) DO NOTHING;

-- 3. Çekirdek Sistem İzinleri (Permissions)
INSERT INTO permissions (code, name, module_code, action, description)
VALUES
    -- Tenant & IAM
    ('TENANT.MANAGE', 'Tenant Yönetimi', 'TENANT', 'MANAGE', 'Tenant ayarları ve modüller'),
    ('USER.MANAGE', 'Kullanıcı Yönetimi', 'IAM', 'MANAGE', 'Personel ekleme, rol atama'),
    ('COMPANY.MANAGE', 'Şirket ve Şube Yönetimi', 'ORGANIZATION', 'MANAGE', 'Tüzel kişilik ve şube ayarları'),
    
    -- Muhasebe
    ('ACCOUNTING.VIEW', 'Muhasebe Görüntüleme', 'ACCOUNTING', 'VIEW', 'Mizan, muavin ve yevmiye okuma'),
    ('ACCOUNTING.CREATE', 'Yevmiye Fişi Oluşturma', 'ACCOUNTING', 'CREATE', 'Taslak fiş girişi'),
    ('ACCOUNTING.POST', 'Yevmiye Onaylama', 'ACCOUNTING', 'POST', 'Muhasebe fişini kesinleştirme'),
    ('ACCOUNTING.REVERSE', 'Ters Kayıt Açma', 'ACCOUNTING', 'REVERSE', 'Hatalı fişi ters kayıtla düzeltme'),

    -- Stok & Depo
    ('INVENTORY.VIEW', 'Stok ve Envanter Görme', 'INVENTORY', 'VIEW', 'Depo ve parti miktarları'),
    ('INVENTORY.CREATE', 'Stok Hareketi Girişi', 'INVENTORY', 'CREATE', 'Giriş/çıkış/transfer fişi'),
    ('INVENTORY.POST', 'Stok Fişi Onaylama', 'INVENTORY', 'POST', 'Hareket defterine işleme'),
    ('INVENTORY.ADJUST', 'Sayım Farkı & Fire Düşümü', 'INVENTORY', 'ADJUST', 'Zayiat ve fire kaydı'),

    -- Dış Ticaret & İhracat
    ('EXPORT.VIEW', 'İhracat Dosyalarını Görme', 'EXPORT', 'VIEW', 'Sevkiyat ve gümrük takibi'),
    ('EXPORT.CREATE', 'İhracat Dosyası Açma', 'EXPORT', 'CREATE', 'Proforma ve sipariş hazırlama'),
    ('EXPORT.APPROVE', 'Sevkiyat Onaylama', 'EXPORT', 'APPROVE', 'Liman ve gümrük çıkış onayı'),

    -- Helal & Kalite
    ('HALAL.VIEW', 'Helal Sertifika Görme', 'HALAL', 'VIEW', 'Sertifika ve parti kapsamı'),
    ('HALAL.MANAGE', 'Helal Sertifika ve Denetim', 'HALAL', 'MANAGE', 'Sertifika yenileme, denetim kaydı')
ON CONFLICT (code) DO NOTHING;
