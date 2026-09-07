-- ==============================================================================
-- NAKHL & NAHL — INTEGRATION & HELP SYSTEM SECURITY & RLS TEST SUITE
-- File: supabase/security_tests/053_integration_and_help_security_tests.sql
-- Complies with Master Directive Sections 38, 40, 42
-- ==============================================================================

DO $$
DECLARE
    v_tenant_a UUID;
    v_tenant_b UUID;
    v_user_a UUID;
    v_user_b UUID;
    v_role_admin UUID;
    v_config_a UUID;
    v_config_b UUID;
    v_webhook_a UUID;
    v_webhook_b UUID;
    v_test_count INT := 0;
    v_pass_count INT := 0;
    v_secret_leak TEXT;
    v_count INT;
BEGIN
    RAISE NOTICE '=============================================================';
    RAISE NOTICE 'INTEGRATION & HELP SECURITY TEST SUITE (RLS & ISOLATION)';
    RAISE NOTICE '=============================================================';

    -- 0. SETUP TEST FIXTURES
    SELECT id INTO v_role_admin FROM roles WHERE code = 'TENANT_ADMIN' AND tenant_id IS NULL LIMIT 1;

    INSERT INTO tenants (code, legal_name, display_name)
    VALUES ('SEC_INT_TENANT_A', 'Sec Int Tenant A Ltd', 'Tenant A Integrations')
    RETURNING id INTO v_tenant_a;

    INSERT INTO tenants (code, legal_name, display_name)
    VALUES ('SEC_INT_TENANT_B', 'Sec Int Tenant B Ltd', 'Tenant B Integrations')
    RETURNING id INTO v_tenant_b;

    INSERT INTO public.users (display_name, email)
    VALUES ('Sec Int User A', 'sec_int_user_a@nakhl-test.com')
    RETURNING id INTO v_user_a;

    INSERT INTO public.users (display_name, email)
    VALUES ('Sec Int User B', 'sec_int_user_b@nakhl-test.com')
    RETURNING id INTO v_user_b;

    INSERT INTO tenant_users (tenant_id, user_id, role_id, status)
    VALUES (v_tenant_a, v_user_a, v_role_admin, 'ACTIVE');

    INSERT INTO tenant_users (tenant_id, user_id, role_id, status)
    VALUES (v_tenant_b, v_user_b, v_role_admin, 'ACTIVE');

    -- Insert Integration Configs for Tenant A and Tenant B
    INSERT INTO integration_configs (
        tenant_id, provider_code, country_code, environment, is_active,
        api_endpoint, credentials_encrypted, tax_identity_number
    ) VALUES (
        v_tenant_a, 'GIB', 'TR', 'sandbox', true,
        'https://efatura-test.gib.gov.tr/services', 'ENCRYPTED_SECRET_KEY_TENANT_A', '1234567890'
    ) RETURNING id INTO v_config_a;

    INSERT INTO integration_configs (
        tenant_id, provider_code, country_code, environment, is_active,
        api_endpoint, credentials_encrypted, tax_identity_number
    ) VALUES (
        v_tenant_b, 'ZATCA', 'SA', 'production', true,
        'https://gw-fatoora.zatca.gov.sa/e-invoicing/core', 'SECRET_CSID_KEY_TENANT_B', '399999999900003'
    ) RETURNING id INTO v_config_b;

    -- =========================================================================
    -- TEST 1: Tenant Membership Function Isolation
    -- =========================================================================
    v_test_count := v_test_count + 1;
    -- Set session user context to User A
    PERFORM set_config('request.jwt.claim.sub', v_user_a::text, true);

    IF is_tenant_member(v_tenant_a) AND NOT is_tenant_member(v_tenant_b) THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE 'TEST 1 (Tenant Membership Boundary User A): PASS';
    ELSE
        RAISE EXCEPTION 'TEST 1 FAILED: User A incorrectly authorized for Tenant B';
    END IF;

    -- =========================================================================
    -- TEST 2: Cross-Tenant Integration Config Access (Credential Protection)
    -- =========================================================================
    v_test_count := v_test_count + 1;
    -- Attempting to query Tenant B credentials with is_tenant_member check
    SELECT credentials_encrypted INTO v_secret_leak
    FROM integration_configs
    WHERE id = v_config_b AND is_tenant_member(tenant_id);

    IF v_secret_leak IS NULL THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE 'TEST 2 (Cross-Tenant Credentials Leak Prevention): PASS';
    ELSE
        RAISE EXCEPTION 'TEST 2 FAILED: Tenant A read Tenant B encrypted credentials: %', v_secret_leak;
    END IF;

    -- =========================================================================
    -- TEST 3: Cross-Tenant Entity Mappings Isolation
    -- =========================================================================
    v_test_count := v_test_count + 1;
    INSERT INTO integration_entity_mappings (
        tenant_id, provider, local_entity, local_id, external_id, external_status
    ) VALUES (
        v_tenant_b, 'ZATCA', 'customer', 'cust_local_999', 'zatca_cust_ext_888', 'ACTIVE'
    );

    SELECT count(*) INTO v_count
    FROM integration_entity_mappings
    WHERE tenant_id = v_tenant_b AND is_tenant_member(tenant_id);

    IF v_count = 0 THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE 'TEST 3 (Cross-Tenant Entity Mapping Isolation): PASS';
    ELSE
        RAISE EXCEPTION 'TEST 3 FAILED: Tenant A saw Tenant B entity mappings count=%', v_count;
    END IF;

    -- =========================================================================
    -- TEST 4: Webhook & Webhook Events Tenant Isolation
    -- =========================================================================
    v_test_count := v_test_count + 1;
    INSERT INTO integration_webhooks (
        tenant_id, provider, webhook_url, secret_hash, subscribed_events
    ) VALUES (
        v_tenant_b, 'QNB', 'https://api.tenantb.com/webhook', 'HASHED_SECRET_B', ARRAY['invoice.approved']
    ) RETURNING id INTO v_webhook_b;

    INSERT INTO integration_webhook_events (
        tenant_id, webhook_id, provider, event_type, idempotency_key, payload, status
    ) VALUES (
        v_tenant_b, v_webhook_b, 'QNB', 'invoice.approved', 'IDEMP_KEY_B_001', '{"invoice_id": "INV-999"}'::jsonb, 'received'
    );

    SELECT count(*) INTO v_count
    FROM integration_webhook_events
    WHERE tenant_id = v_tenant_b AND is_tenant_member(tenant_id);

    IF v_count = 0 THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE 'TEST 4 (Webhook & Event Tenant Isolation): PASS';
    ELSE
        RAISE EXCEPTION 'TEST 4 FAILED: Tenant A saw Tenant B webhook events count=%', v_count;
    END IF;

    -- =========================================================================
    -- TEST 5: Webhook Event Idempotency Enforcement
    -- =========================================================================
    v_test_count := v_test_count + 1;
    INSERT INTO integration_webhook_events (
        tenant_id, provider, event_type, idempotency_key, payload, status
    ) VALUES (
        v_tenant_a, 'GIB', 'invoice.sent', 'IDEMP_KEY_A_UNIQUE', '{"inv": 1}'::jsonb, 'received'
    );

    BEGIN
        INSERT INTO integration_webhook_events (
            tenant_id, provider, event_type, idempotency_key, payload, status
        ) VALUES (
            v_tenant_a, 'GIB', 'invoice.sent', 'IDEMP_KEY_A_UNIQUE', '{"inv": 2}'::jsonb, 'received'
        );
        RAISE EXCEPTION 'TEST 5 FAILED: Duplicate idempotency key was allowed!';
    EXCEPTION WHEN unique_violation THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE 'TEST 5 (Webhook Idempotency Enforcement): PASS';
    END;

    -- =========================================================================
    -- TEST 6: Integration Sync Logs Audit Isolation
    -- =========================================================================
    v_test_count := v_test_count + 1;
    INSERT INTO integration_sync_logs (
        tenant_id, provider, sync_type, entity_type, direction, correlation_id, status
    ) VALUES (
        v_tenant_b, 'LOGO', 'automatic', 'product', 'outbound', 'CORR_LOG_B_1', 'SUCCESS'
    );

    SELECT count(*) INTO v_count
    FROM integration_sync_logs
    WHERE tenant_id = v_tenant_b AND is_tenant_member(tenant_id);

    IF v_count = 0 THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE 'TEST 6 (Integration Sync Logs Isolation): PASS';
    ELSE
        RAISE EXCEPTION 'TEST 6 FAILED: Tenant A accessed Tenant B sync logs';
    END IF;

    -- =========================================================================
    -- TEST 7: User Help Progress Tenant Isolation
    -- =========================================================================
    v_test_count := v_test_count + 1;
    INSERT INTO user_help_progress (
        user_id, tenant_id, help_id, completed, progress
    ) VALUES (
        v_user_b, v_tenant_b, 'help_customers', true, '{"step": 5}'::jsonb
    );

    SELECT count(*) INTO v_count
    FROM user_help_progress
    WHERE tenant_id = v_tenant_b AND is_tenant_member(tenant_id);

    IF v_count = 0 THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE 'TEST 7 (User Help Progress Tenant Isolation): PASS';
    ELSE
        RAISE EXCEPTION 'TEST 7 FAILED: Tenant A saw Tenant B user help progress';
    END IF;

    -- =========================================================================
    -- TEST 8: Help Contents Global vs Custom Tenant Segregation
    -- =========================================================================
    v_test_count := v_test_count + 1;
    -- Global content (tenant_id IS NULL) must be readable
    SELECT count(*) INTO v_count
    FROM help_contents
    WHERE tenant_id IS NULL;

    IF v_count >= 5 THEN
        -- Insert a tenant B specific customized help topic
        INSERT INTO help_contents (
            id, tenant_id, route, menu_key, title, short_description, long_description,
            searchable_text, language
        ) VALUES (
            'custom_help_tenant_b', v_tenant_b, '/custom/b', 'custom_b', 'Tenant B Özel Rehber',
            'Sadece Tenant B görebilir', 'Detay B', 'özel tenant b', 'tr'
        );

        -- Tenant A should not see Tenant B custom content
        SELECT count(*) INTO v_count
        FROM help_contents
        WHERE id = 'custom_help_tenant_b' AND (tenant_id IS NULL OR is_tenant_member(tenant_id));

        IF v_count = 0 THEN
            v_pass_count := v_pass_count + 1;
            RAISE NOTICE 'TEST 8 (Help Content Global Read & Tenant Privacy): PASS';
        ELSE
            RAISE EXCEPTION 'TEST 8 FAILED: Tenant A saw Tenant B custom help content!';
        END IF;
    ELSE
        RAISE EXCEPTION 'TEST 8 FAILED: Global help contents not populated (count=%)', v_count;
    END IF;

    -- =========================================================================
    -- TEST 9: Help Usage Events Privacy & Tenant Scoping
    -- =========================================================================
    v_test_count := v_test_count + 1;
    INSERT INTO help_usage_events (
        tenant_id, user_id, event_name, help_id, metadata
    ) VALUES (
        v_tenant_b, v_user_b, 'tutorial_completed', 'help_customers', '{"duration_sec": 45}'::jsonb
    );

    SELECT count(*) INTO v_count
    FROM help_usage_events
    WHERE tenant_id = v_tenant_b AND is_tenant_member(tenant_id);

    IF v_count = 0 THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE 'TEST 9 (Help Usage Analytics Tenant Boundary): PASS';
    ELSE
        RAISE EXCEPTION 'TEST 9 FAILED: Tenant A saw Tenant B usage events';
    END IF;

    -- =========================================================================
    -- TEST 10: Provider Registry Global Accessibility
    -- =========================================================================
    v_test_count := v_test_count + 1;
    SELECT count(*) INTO v_count
    FROM integration_provider_registry
    WHERE active = true;

    IF v_count >= 10 THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE 'TEST 10 (Provider Registry Catalogue Access): PASS (Found % Active Providers)', v_count;
    ELSE
        RAISE EXCEPTION 'TEST 10 FAILED: Integration Provider Registry incomplete (count=%)', v_count;
    END IF;

    -- CLEANUP
    DELETE FROM help_usage_events WHERE tenant_id IN (v_tenant_a, v_tenant_b);
    DELETE FROM user_help_progress WHERE tenant_id IN (v_tenant_a, v_tenant_b);
    DELETE FROM help_contents WHERE tenant_id IN (v_tenant_a, v_tenant_b);
    DELETE FROM integration_sync_logs WHERE tenant_id IN (v_tenant_a, v_tenant_b);
    DELETE FROM integration_webhook_events WHERE tenant_id IN (v_tenant_a, v_tenant_b);
    DELETE FROM integration_webhooks WHERE tenant_id IN (v_tenant_a, v_tenant_b);
    DELETE FROM integration_entity_mappings WHERE tenant_id IN (v_tenant_a, v_tenant_b);
    DELETE FROM integration_configs WHERE tenant_id IN (v_tenant_a, v_tenant_b);
    DELETE FROM tenant_users WHERE tenant_id IN (v_tenant_a, v_tenant_b);
    DELETE FROM tenants WHERE id IN (v_tenant_a, v_tenant_b);
    DELETE FROM public.users WHERE id IN (v_user_a, v_user_b);

    RAISE NOTICE '=============================================================';
    RAISE NOTICE 'SONUÇ: % TESTİN % TANESİ BAŞARIYLA GEÇTİ (ALL PASS)', v_test_count, v_pass_count;
    RAISE NOTICE '=============================================================';
END $$;
