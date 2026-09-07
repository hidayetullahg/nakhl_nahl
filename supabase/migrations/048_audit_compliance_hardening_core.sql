-- ==============================================================================
-- NAKHL & NAHL — FAZ 29: AUDIT + COMPLIANCE HARDENING CORE
-- Cryptographic Append-Only Audit Trail, Strict Ledger Immutability & Retention Policy
-- ==============================================================================

-- 1. AUDIT_LOGS TABLOSUNU GÜÇLENDİRME (Kriptografik Zincir ve Güvenlik Alanları)
ALTER TABLE audit_logs 
    ADD COLUMN IF NOT EXISTS actor_role VARCHAR(50) NOT NULL DEFAULT 'USER',
    ADD COLUMN IF NOT EXISTS record_hash VARCHAR(64),
    ADD COLUMN IF NOT EXISTS prev_hash VARCHAR(64),
    ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}'::jsonb;

-- 2. KRİPTOGRAFİK ZİNCİRLEME TETİKLEYİCİSİ (Tamper-Evident SHA-256 Cryptographic Chain)
-- Her denetim kaydını bir önceki kaydın özetine bağlar (Blockchain-benzeri değiştirilemezlik kanıtı)
CREATE OR REPLACE FUNCTION compute_audit_log_hash()
RETURNS TRIGGER AS $$
DECLARE
    v_prev_hash VARCHAR(64);
    v_payload TEXT;
BEGIN
    -- Aynı kiracı için bir önceki audit kaydının hash değerini al
    SELECT record_hash INTO v_prev_hash 
    FROM audit_logs 
    WHERE tenant_id = NEW.tenant_id 
    ORDER BY id DESC 
    LIMIT 1;

    IF v_prev_hash IS NULL THEN
        v_prev_hash := 'GENESIS_BLOCK_NAKHL_NAHL_AUDIT_TRAIL_000000000000000000000000000';
    END IF;

    NEW.prev_hash := v_prev_hash;

    -- Deterministik SHA-256 girdi yükü
    v_payload := CONCAT_WS('|',
        COALESCE(NEW.tenant_id::text, ''),
        COALESCE(NEW.user_id::text, ''),
        COALESCE(NEW.company_id::text, ''),
        NEW.action::text,
        NEW.entity_type,
        NEW.entity_id::text,
        COALESCE(NEW.old_data::text, ''),
        COALESCE(NEW.new_data::text, ''),
        COALESCE(NEW.actor_role, 'USER'),
        COALESCE(NEW.ip_address::text, ''),
        NEW.prev_hash
    );

    NEW.record_hash := encode(digest(v_payload, 'sha256'), 'hex');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_compute_audit_log_hash ON audit_logs;
CREATE TRIGGER trg_compute_audit_log_hash
BEFORE INSERT ON audit_logs
FOR EACH ROW EXECUTE FUNCTION compute_audit_log_hash();

-- ==============================================================================
-- 3. AUDIT DEĞİŞTİRİLEMEZLİK GÜVENCESİ (IMMUTABILITY - ZERO EXCEPTIONS)
-- SUPER_ADMIN dahi audit kayıtlarını değiştiremez veya silemez.
-- ==============================================================================
CREATE OR REPLACE FUNCTION prevent_audit_log_modification()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'CRITICAL COMPLIANCE VIOLATION: Audit log kayıtları kesinlikle değiştirilemez (UPDATE) veya silinemez (DELETE)! SUPER_ADMIN veya veritabanı yöneticileri dahi bu kayıtları değiştiremez (SOX / GDPR / ISO 27001 / ZATCA mevzuatı gereği append-only zorunludur).';
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_prevent_audit_log_modification ON audit_logs;
CREATE TRIGGER trg_prevent_audit_log_modification
BEFORE UPDATE OR DELETE ON audit_logs
FOR EACH ROW EXECUTE FUNCTION prevent_audit_log_modification();

-- ==============================================================================
-- 4. DEFTER (LEDGER) DEĞİŞTİRİLEMEZLİK PEKİŞTİRMESİ
-- Yevmiye satırları (journal_lines) ve stok hareket defteri (stock_ledger_entries)
-- ==============================================================================
CREATE OR REPLACE FUNCTION prevent_posted_journal_lines_modification()
RETURNS TRIGGER AS $$
DECLARE
    v_status VARCHAR(50);
BEGIN
    SELECT status INTO v_status 
    FROM journal_entries 
    WHERE id = COALESCE(OLD.journal_entry_id, NEW.journal_entry_id);

    IF v_status IN ('POSTED', 'LOCKED') THEN
        RAISE EXCEPTION 'Kesinleşmiş (POSTED/LOCKED) yevmiye fişlerinin satırları (journal_lines) kesinlikle değiştirilemez veya silinemez! Hatalar için ters kayıt (reversal) girilmelidir.';
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_prevent_posted_journal_lines_modification ON journal_lines;
CREATE TRIGGER trg_prevent_posted_journal_lines_modification
BEFORE UPDATE OR DELETE ON journal_lines
FOR EACH ROW EXECUTE FUNCTION prevent_posted_journal_lines_modification();

-- ==============================================================================
-- 5. EVRENSEL DENETİM KAYIT RPC (log_audit_event)
-- Desteklenen 10 Kritik Ticari İşlem:
-- CREATE, UPDATE, POST, APPROVE, REJECT, REVERSE, EXPORT, IMPORT, LOGIN, LOGOUT
-- ==============================================================================
CREATE OR REPLACE FUNCTION log_audit_event(
    p_action audit_action_enum,
    p_entity_type TEXT,
    p_entity_id UUID,
    p_tenant_id UUID,
    p_company_id UUID DEFAULT NULL,
    p_user_id UUID DEFAULT NULL,
    p_old_data JSONB DEFAULT NULL,
    p_new_data JSONB DEFAULT NULL,
    p_actor_role TEXT DEFAULT 'USER',
    p_ip_address INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL,
    p_metadata JSONB DEFAULT '{}'::jsonb
)
RETURNS BIGINT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_log_id BIGINT;
BEGIN
    INSERT INTO audit_logs (
        tenant_id,
        company_id,
        user_id,
        action,
        entity_type,
        entity_id,
        old_data,
        new_data,
        actor_role,
        ip_address,
        user_agent,
        metadata,
        created_at
    ) VALUES (
        p_tenant_id,
        p_company_id,
        p_user_id,
        p_action,
        p_entity_type,
        p_entity_id,
        p_old_data,
        p_new_data,
        COALESCE(p_actor_role, 'USER'),
        p_ip_address,
        p_user_agent,
        COALESCE(p_metadata, '{}'::jsonb),
        NOW()
    ) RETURNING id INTO v_log_id;

    RETURN v_log_id;
END;
$$;

-- ==============================================================================
-- 6. KRİPTOGRAFİK ZİNCİR BÜTÜNLÜK DOĞRULAMA RPC (verify_audit_log_chain_integrity)
-- Denetim izinde herhangi bir silinme veya veri tahrifatı olup olmadığını doğrular
-- ==============================================================================
CREATE OR REPLACE FUNCTION verify_audit_log_chain_integrity(
    p_tenant_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    r RECORD;
    v_expected_prev VARCHAR(64) := 'GENESIS_BLOCK_NAKHL_NAHL_AUDIT_TRAIL_000000000000000000000000000';
    v_recomputed_hash VARCHAR(64);
    v_payload TEXT;
    v_count INT := 0;
    v_is_valid BOOLEAN := TRUE;
    v_tampered_id BIGINT := NULL;
    v_tamper_reason TEXT := NULL;
BEGIN
    FOR r IN (
        SELECT * FROM audit_logs 
        WHERE tenant_id = p_tenant_id 
        ORDER BY id ASC
    ) LOOP
        v_count := v_count + 1;

        -- 1. prev_hash kontrolü
        IF r.prev_hash != v_expected_prev THEN
            v_is_valid := FALSE;
            v_tampered_id := r.id;
            v_tamper_reason := 'Zincir kırılması: prev_hash beklenen hash ile uyuşmuyor!';
            EXIT;
        END IF;

        -- 2. record_hash yeniden hesaplama ve karşılaştırma
        v_payload := CONCAT_WS('|',
            COALESCE(r.tenant_id::text, ''),
            COALESCE(r.user_id::text, ''),
            COALESCE(r.company_id::text, ''),
            r.action::text,
            r.entity_type,
            r.entity_id::text,
            COALESCE(r.old_data::text, ''),
            COALESCE(r.new_data::text, ''),
            COALESCE(r.actor_role, 'USER'),
            COALESCE(r.ip_address::text, ''),
            r.prev_hash
        );
        v_recomputed_hash := encode(digest(v_payload, 'sha256'), 'hex');

        IF r.record_hash != v_recomputed_hash THEN
            v_is_valid := FALSE;
            v_tampered_id := r.id;
            v_tamper_reason := 'Tahrifat tespit edildi: Kayıt içeriği veya hash değeri değiştirilmiş!';
            EXIT;
        END IF;

        v_expected_prev := r.record_hash;
    END LOOP;

    RETURN jsonb_build_object(
        'tenant_id', p_tenant_id,
        'total_records_checked', v_count,
        'is_valid', v_is_valid,
        'tampered_record_id', v_tampered_id,
        'tamper_reason', v_tamper_reason,
        'verified_at', NOW()
    );
END;
$$;

-- ==============================================================================
-- 7. DENETİM SAKLAMA POLİTİKASI (RETENTION POLICY & COMPLIANCE RULES)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS audit_retention_policies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    retention_period_years INT NOT NULL DEFAULT 10,
    storage_class VARCHAR(100) NOT NULL DEFAULT 'WORM_COMPLIANT_COLD_STORAGE',
    automated_purge_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    legal_frameworks TEXT[] NOT NULL DEFAULT ARRAY[
        'ZATCA Electronic Invoicing & Tax Audit Regulations (10 Years)',
        'KSA Corporate Tax & Commercial Law',
        'GCC Common Customs Law (International Trade Records)',
        'EU Traceability & Food Safety General Food Law Reg (EC) 178/2002',
        'IFRS / GAAP Financial Audit Standards',
        'ISO 27001 (Information Security) & ISO 9001 (Quality Assurance)'
    ],
    destruction_policy TEXT NOT NULL DEFAULT 'Herhangi bir otomatik silme işlemi yasaktır. 10 yıllık yasal süre sonunda dahi sadece çoklu imza (Multi-Signature Compliance Officer + Legal Officer) protokolü ile arşivleme yapılabilir.',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_audit_retention_tenant UNIQUE (tenant_id)
);

-- ==============================================================================
-- 8. GÜVENLİK VE ROW LEVEL SECURITY (RLS) POLİTİKALARI
-- Cross-Tenant erişim kesinlikle yasaktır.
-- ==============================================================================
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs FORCE ROW LEVEL SECURITY;

ALTER TABLE audit_retention_policies ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_retention_policies FORCE ROW LEVEL SECURITY;

-- audit_logs: Yalnızca kiracı üyeleri kendi tenant kayıtlarını görebilir
DROP POLICY IF EXISTS "audit_logs_select_tenant" ON audit_logs;
CREATE POLICY "audit_logs_select_tenant" ON audit_logs
    FOR SELECT TO authenticated
    USING (is_tenant_member(tenant_id));

-- audit_logs: Doğrudan harici UPDATE veya DELETE politikası YOKTUR (trigger ile de mutlak engellenmiştir)

-- audit_retention_policies politikaları
DROP POLICY IF EXISTS "audit_retention_policies_select" ON audit_retention_policies;
CREATE POLICY "audit_retention_policies_select" ON audit_retention_policies
    FOR SELECT TO authenticated
    USING (is_tenant_member(tenant_id));

DROP POLICY IF EXISTS "audit_retention_policies_admin" ON audit_retention_policies;
CREATE POLICY "audit_retention_policies_admin" ON audit_retention_policies
    FOR ALL TO authenticated
    USING (is_tenant_admin(tenant_id))
    WITH CHECK (is_tenant_admin(tenant_id));

-- Performans İndeksleri
CREATE INDEX IF NOT EXISTS idx_audit_logs_tenant_action ON audit_logs (tenant_id, action, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_entity ON audit_logs (entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_hash ON audit_logs (record_hash);
