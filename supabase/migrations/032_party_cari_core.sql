-- ==============================================================================
-- NAKHL & NAHL — MIGRATION 032: PARTY / CARİ / CUSTOMER / SUPPLIER CORE (FAZ 12)
-- Purpose:
-- 1. party_addresses (Billing, Shipping, Legal, Warehouse, Contact adresleri)
-- 2. party_contacts (Yetkili kişiler, unvan, e-posta, telefon, tercih edilen dil)
-- 3. commercial_accounts (Şirket ve döviz bazlı cari ticari koşul ve limitler)
-- 4. customers (Müşteri master kaydı: parti, müşteri kodu, vergi profili, kredi limiti)
-- 5. suppliers (Tedarikçi master kaydı: parti, tedarikçi kodu, teslimat süresi, ödeme vadesi)
-- 6. Otomatik senkronizasyon ve tekilleştirme trigger/fonksiyonları
-- ==============================================================================

-- 1. PARTİ ADRESLERİ (PARTY ADDRESSES)
CREATE TABLE IF NOT EXISTS party_addresses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    party_id UUID NOT NULL REFERENCES parties(id) ON DELETE CASCADE,
    address_type VARCHAR(50) NOT NULL DEFAULT 'BILLING', -- BILLING, SHIPPING, LEGAL, WAREHOUSE, CONTACT
    title VARCHAR(100), -- Örn: "Merkez Ofis", "Riyadh Antrepo"
    address_line1 TEXT NOT NULL,
    address_line2 TEXT,
    city VARCHAR(100),
    district VARCHAR(100),
    postal_code VARCHAR(20),
    country_code VARCHAR(2) NOT NULL DEFAULT 'SA' REFERENCES countries(code),
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. PARTİ YETKİLİ / İRTİBAT KİŞİLERİ (PARTY CONTACTS)
CREATE TABLE IF NOT EXISTS party_contacts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    party_id UUID NOT NULL REFERENCES parties(id) ON DELETE CASCADE,
    name VARCHAR(150) NOT NULL,
    title VARCHAR(100),
    department VARCHAR(100),
    email citext,
    phone VARCHAR(50),
    mobile VARCHAR(50),
    preferred_language_code VARCHAR(10) REFERENCES languages(code),
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. TİCARİ CARİ HESAPLAR (COMMERCIAL ACCOUNTS)
-- Aynı partinin farklı şirketlerde bağımsız limit, vade, vergi ve para birimi koşulları olabilir.
CREATE TABLE IF NOT EXISTS commercial_accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    party_id UUID NOT NULL REFERENCES parties(id) ON DELETE CASCADE,
    account_code VARCHAR(100) NOT NULL,
    currency_code VARCHAR(5) NOT NULL DEFAULT 'SAR' REFERENCES currencies(code),
    payment_terms_days INT NOT NULL DEFAULT 30,
    credit_limit NUMERIC(18,2) NOT NULL DEFAULT 0.00,
    risk_control_type VARCHAR(50) NOT NULL DEFAULT 'WARNING', -- STOP, WARNING, NONE
    tax_profile_id UUID REFERENCES tax_profiles(id) ON DELETE SET NULL,
    account_status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE', -- ACTIVE, BLOCKED, SUSPENDED, CLOSED
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_comm_account_comp UNIQUE (company_id, party_id, currency_code)
);

-- 4. MÜŞTERİ MASTER (CUSTOMERS)
CREATE TABLE IF NOT EXISTS customers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    party_id UUID NOT NULL REFERENCES parties(id) ON DELETE CASCADE,
    customer_code VARCHAR(100) NOT NULL,
    tax_profile_id UUID REFERENCES tax_profiles(id) ON DELETE SET NULL,
    payment_terms_days INT NOT NULL DEFAULT 30,
    currency_code VARCHAR(5) NOT NULL DEFAULT 'SAR' REFERENCES currencies(code),
    credit_limit NUMERIC(18,2) NOT NULL DEFAULT 0.00,
    status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_customer_company_code UNIQUE (company_id, customer_code),
    CONSTRAINT uq_customer_company_party UNIQUE (company_id, party_id)
);

-- 5. TEDARİKÇİ MASTER (SUPPLIERS)
CREATE TABLE IF NOT EXISTS suppliers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    party_id UUID NOT NULL REFERENCES parties(id) ON DELETE CASCADE,
    supplier_code VARCHAR(100) NOT NULL,
    payment_terms_days INT NOT NULL DEFAULT 30,
    currency_code VARCHAR(5) NOT NULL DEFAULT 'SAR' REFERENCES currencies(code),
    tax_profile_id UUID REFERENCES tax_profiles(id) ON DELETE SET NULL,
    lead_time_days INT NOT NULL DEFAULT 7,
    status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_supplier_company_code UNIQUE (company_id, supplier_code),
    CONSTRAINT uq_supplier_company_party UNIQUE (company_id, party_id)
);

-- 6. İNDEKSLER
CREATE INDEX IF NOT EXISTS idx_party_addresses_party ON party_addresses(party_id);
CREATE INDEX IF NOT EXISTS idx_party_contacts_party ON party_contacts(party_id);
CREATE INDEX IF NOT EXISTS idx_comm_accounts_tenant_comp ON commercial_accounts(tenant_id, company_id);
CREATE INDEX IF NOT EXISTS idx_comm_accounts_party ON commercial_accounts(party_id);
CREATE INDEX IF NOT EXISTS idx_customers_tenant_comp ON customers(tenant_id, company_id);
CREATE INDEX IF NOT EXISTS idx_customers_party ON customers(party_id);
CREATE INDEX IF NOT EXISTS idx_suppliers_tenant_comp ON suppliers(tenant_id, company_id);
CREATE INDEX IF NOT EXISTS idx_suppliers_party ON suppliers(party_id);

-- 7. ROW LEVEL SECURITY (RLS) POLİTİKALARI
ALTER TABLE party_addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE party_addresses FORCE ROW LEVEL SECURITY;

CREATE POLICY "party_addresses_select" ON party_addresses
    FOR SELECT USING (is_tenant_member(tenant_id));

CREATE POLICY "party_addresses_manage" ON party_addresses
    FOR ALL USING (is_tenant_member(tenant_id))
    WITH CHECK (is_tenant_member(tenant_id));

ALTER TABLE party_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE party_contacts FORCE ROW LEVEL SECURITY;

CREATE POLICY "party_contacts_select" ON party_contacts
    FOR SELECT USING (is_tenant_member(tenant_id));

CREATE POLICY "party_contacts_manage" ON party_contacts
    FOR ALL USING (is_tenant_member(tenant_id))
    WITH CHECK (is_tenant_member(tenant_id));

ALTER TABLE commercial_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE commercial_accounts FORCE ROW LEVEL SECURITY;

CREATE POLICY "commercial_accounts_select" ON commercial_accounts
    FOR SELECT USING (is_tenant_member(tenant_id) AND has_company_access(company_id));

CREATE POLICY "commercial_accounts_manage" ON commercial_accounts
    FOR ALL USING (is_tenant_member(tenant_id) AND has_company_access(company_id))
    WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(company_id));

ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers FORCE ROW LEVEL SECURITY;

CREATE POLICY "customers_select" ON customers
    FOR SELECT USING (is_tenant_member(tenant_id) AND has_company_access(company_id));

CREATE POLICY "customers_manage" ON customers
    FOR ALL USING (is_tenant_member(tenant_id) AND has_company_access(company_id))
    WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(company_id));

ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE suppliers FORCE ROW LEVEL SECURITY;

CREATE POLICY "suppliers_select" ON suppliers
    FOR SELECT USING (is_tenant_member(tenant_id) AND has_company_access(company_id));

CREATE POLICY "suppliers_manage" ON suppliers
    FOR ALL USING (is_tenant_member(tenant_id) AND has_company_access(company_id))
    WITH CHECK (is_tenant_member(tenant_id) AND has_company_access(company_id));

-- 8. CARİ KART VE PARTİ KÖPRÜ / SENKRONİZASYON TETİKLEYİCİSİ
-- Mevcut cariler tablosuna kayıt atıldığında veya güncellendiğinde,
-- parties, party_addresses, party_contacts ve commercial_accounts tablolarını otomatik besler.
CREATE OR REPLACE FUNCTION sync_cari_to_party_core()
RETURNS TRIGGER AS $$
DECLARE
    v_party_id UUID;
    v_role_type VARCHAR(50);
BEGIN
    v_party_id := NEW.party_id;

    -- A. Eğer party_id atanmamışsa, vergi_no veya unvan ile mevcut partiyi ara
    IF v_party_id IS NULL THEN
        IF NEW.vergi_no IS NOT NULL AND NEW.vergi_no != '' THEN
            SELECT id INTO v_party_id
            FROM parties
            WHERE tenant_id = NEW.tenant_id AND tax_number = NEW.vergi_no
            LIMIT 1;
        END IF;

        IF v_party_id IS NULL THEN
            SELECT id INTO v_party_id
            FROM parties
            WHERE tenant_id = NEW.tenant_id AND LOWER(legal_name) = LOWER(NEW.unvan)
            LIMIT 1;
        END IF;

        -- Parti yoksa oluştur
        IF v_party_id IS NULL THEN
            INSERT INTO parties (
                tenant_id,
                party_type,
                legal_name,
                tax_number,
                country_code,
                email,
                phone,
                website,
                is_active
            ) VALUES (
                NEW.tenant_id,
                'ORGANIZATION',
                NEW.unvan,
                NEW.vergi_no,
                COALESCE(NEW.ulke_kodu, 'SA'),
                NEW.eposta,
                COALESCE(NEW.sirket_telefonu, NEW.cep_telefonu),
                NEW.web_sitesi,
                NEW.aktif_mi
            ) RETURNING id INTO v_party_id;
        END IF;

        NEW.party_id := v_party_id;
    END IF;

    -- B. Rol Belirleme ve Ekleme
    v_role_type := CASE 
        WHEN LOWER(NEW.cari_tipi) LIKE '%tedarik%' THEN 'SUPPLIER'
        WHEN LOWER(NEW.cari_tipi) LIKE '%personel%' THEN 'EMPLOYEE'
        WHEN LOWER(NEW.cari_tipi) LIKE '%broker%' THEN 'BROKER'
        WHEN LOWER(NEW.cari_tipi) LIKE '%tasiyici%' OR LOWER(NEW.cari_tipi) LIKE '%lojistik%' THEN 'CARRIER'
        ELSE 'CUSTOMER'
    END;

    INSERT INTO party_roles (tenant_id, party_id, role_type)
    VALUES (NEW.tenant_id, v_party_id, v_role_type)
    ON CONFLICT (party_id, role_type) DO NOTHING;

    -- C. Adres Senkronizasyonu (Fatura Adresi)
    IF NEW.fatura_adresi IS NOT NULL AND NEW.fatura_adresi != '' THEN
        INSERT INTO party_addresses (
            tenant_id,
            party_id,
            address_type,
            title,
            address_line1,
            city,
            district,
            postal_code,
            country_code,
            is_default
        ) VALUES (
            NEW.tenant_id,
            v_party_id,
            'BILLING',
            'Fatura Adresi',
            NEW.fatura_adresi,
            NEW.sehir,
            NEW.ilce,
            NEW.posta_kodu,
            COALESCE(NEW.ulke_kodu, 'SA'),
            TRUE
        )
        ON CONFLICT DO NOTHING;
    END IF;

    -- D. Yetkili Kişi Senkronizasyonu (party_contacts)
    IF NEW.yetkili_kisi IS NOT NULL AND NEW.yetkili_kisi != '' THEN
        INSERT INTO party_contacts (
            tenant_id,
            party_id,
            name,
            title,
            department,
            phone,
            mobile,
            email,
            is_primary
        ) VALUES (
            NEW.tenant_id,
            v_party_id,
            NEW.yetkili_kisi,
            NEW.yetkili_unvan,
            NEW.departman,
            NEW.sirket_telefonu,
            NEW.cep_telefonu,
            NEW.eposta,
            TRUE
        )
        ON CONFLICT DO NOTHING;
    END IF;

    -- E. Şirket Ticari Cari Hesabı (commercial_accounts)
    IF NEW.company_id IS NOT NULL THEN
        INSERT INTO commercial_accounts (
            tenant_id,
            company_id,
            party_id,
            account_code,
            currency_code,
            payment_terms_days,
            credit_limit,
            risk_control_type,
            account_status
        ) VALUES (
            NEW.tenant_id,
            NEW.company_id,
            v_party_id,
            NEW.cari_kodu,
            COALESCE(NEW.para_birimi, 'SAR'),
            NEW.vade_gunu,
            NEW.risk_limiti,
            NEW.risk_kontrol_tipi,
            CASE WHEN NEW.aktif_mi THEN 'ACTIVE' ELSE 'SUSPENDED' END
        )
        ON CONFLICT (company_id, party_id, currency_code) DO UPDATE
        SET 
            credit_limit = EXCLUDED.credit_limit,
            payment_terms_days = EXCLUDED.payment_terms_days,
            account_status = EXCLUDED.account_status,
            updated_at = NOW();

        -- F. Rol spesifik master senkronizasyonu
        IF v_role_type = 'CUSTOMER' THEN
            INSERT INTO customers (
                tenant_id,
                company_id,
                party_id,
                customer_code,
                payment_terms_days,
                currency_code,
                credit_limit,
                status
            ) VALUES (
                NEW.tenant_id,
                NEW.company_id,
                v_party_id,
                NEW.cari_kodu,
                NEW.vade_gunu,
                COALESCE(NEW.para_birimi, 'SAR'),
                NEW.risk_limiti,
                CASE WHEN NEW.aktif_mi THEN 'ACTIVE' ELSE 'SUSPENDED' END
            )
            ON CONFLICT (company_id, party_id) DO UPDATE
            SET 
                payment_terms_days = EXCLUDED.payment_terms_days,
                credit_limit = EXCLUDED.credit_limit,
                status = EXCLUDED.status,
                updated_at = NOW();
        ELSIF v_role_type = 'SUPPLIER' THEN
            INSERT INTO suppliers (
                tenant_id,
                company_id,
                party_id,
                supplier_code,
                payment_terms_days,
                currency_code,
                lead_time_days,
                status
            ) VALUES (
                NEW.tenant_id,
                NEW.company_id,
                v_party_id,
                NEW.cari_kodu,
                NEW.vade_gunu,
                COALESCE(NEW.para_birimi, 'SAR'),
                7,
                CASE WHEN NEW.aktif_mi THEN 'ACTIVE' ELSE 'SUSPENDED' END
            )
            ON CONFLICT (company_id, party_id) DO UPDATE
            SET 
                payment_terms_days = EXCLUDED.payment_terms_days,
                status = EXCLUDED.status,
                updated_at = NOW();
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS trg_sync_cari_to_party_core ON cariler;
CREATE TRIGGER trg_sync_cari_to_party_core
BEFORE INSERT OR UPDATE ON cariler
FOR EACH ROW EXECUTE FUNCTION sync_cari_to_party_core();
