-- ==============================================================================
-- NAKHL & NAHL — MIGRATION 054: GLOBAL JURISDICTION SHELF & LEGAL LIBRARY
-- Purpose:
-- 1. Master Implementation Directive: Focused Legislation Library & Global Shelf
-- 2. 4 Active Packs: SAUDI_ARABIA_PACK, TURKEY_PACK, EU_FOOD_IMPORT_PACK, GERMANY_FOOD_IMPORT_PACK
-- 3. Empty Shelves: China, India, Russia, UAE, Qatar, Kuwait, Bahrain, Oman, UK, USA, etc. (NOT_LOADED)
-- 4. 25 Core Legal Library Tables with Jurisdiction Isolation, Versioning, Review Workflow
-- 5. RLS Policies and Tenant Access Enforcement
-- ==============================================================================

-- 1. LEGAL JURISDICTIONS
CREATE TABLE IF NOT EXISTS legal_jurisdictions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(30) NOT NULL UNIQUE, -- 'SA', 'TR', 'EU', 'DE', 'CN', 'IN', 'RU', 'US', etc.
    iso_alpha2 VARCHAR(2) NOT NULL,
    iso_alpha3 VARCHAR(3),
    name_tr VARCHAR(150) NOT NULL,
    name_en VARCHAR(150) NOT NULL,
    name_ar VARCHAR(150),
    region VARCHAR(50) NOT NULL, -- 'MIDDLE_EAST', 'EUROPE', 'ASIA', 'AMERICAS', 'GLOBAL'
    jurisdiction_type VARCHAR(30) NOT NULL DEFAULT 'NATIONAL' CHECK (jurisdiction_type IN ('NATIONAL', 'SUPRANATIONAL', 'REGIONAL', 'MUNICIPAL')),
    is_active BOOLEAN NOT NULL DEFAULT FALSE,
    shelf_status VARCHAR(30) NOT NULL DEFAULT 'NOT_LOADED' CHECK (shelf_status IN ('NOT_LOADED', 'DISCOVERY', 'PARTIAL', 'ACTIVE', 'MAINTENANCE', 'SUSPENDED', 'ARCHIVED')),
    official_portal_url TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. LEGAL AUTHORITIES
CREATE TABLE IF NOT EXISTS legal_authorities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    jurisdiction_id UUID NOT NULL REFERENCES legal_jurisdictions(id) ON DELETE CASCADE,
    code VARCHAR(50) NOT NULL, -- 'SA_ZATCA', 'SA_SFDA', 'TR_GIB', 'EU_SANTE', 'DE_BVL', etc.
    name_tr VARCHAR(200) NOT NULL,
    name_en VARCHAR(200) NOT NULL,
    name_native VARCHAR(200),
    authority_type VARCHAR(50) NOT NULL CHECK (authority_type IN ('TAX', 'CUSTOMS', 'FOOD_SAFETY', 'STANDARDS', 'COMMERCE', 'AGRICULTURE', 'HEALTH')),
    official_website TEXT,
    api_endpoint TEXT,
    trust_level INT NOT NULL DEFAULT 1 CHECK (trust_level BETWEEN 1 AND 6),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_authority_code UNIQUE (jurisdiction_id, code)
);

-- 3. LEGAL DOMAINS
CREATE TABLE IF NOT EXISTS legal_domains (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(50) NOT NULL UNIQUE, -- 'TAX', 'CUSTOMS', 'FOOD_SAFETY', 'LABELING', 'TRACEABILITY', 'HALAL', 'COMMERCE', 'PACKAGING', 'ORGANIC'
    name_tr VARCHAR(100) NOT NULL,
    name_en VARCHAR(100) NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. LEGAL SOURCES
CREATE TABLE IF NOT EXISTS legal_sources (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    authority_id UUID NOT NULL REFERENCES legal_authorities(id) ON DELETE CASCADE,
    source_name VARCHAR(255) NOT NULL,
    source_type VARCHAR(50) NOT NULL CHECK (source_type IN ('OFFICIAL_GAZETTE', 'MINISTERIAL_DECREE', 'DIRECTIVE', 'REGULATION', 'GUIDELINE', 'ANNOUNCEMENT')),
    source_level INT NOT NULL DEFAULT 1 CHECK (source_level BETWEEN 1 AND 6),
    source_url TEXT NOT NULL,
    language_code VARCHAR(10) NOT NULL DEFAULT 'tr',
    is_monitored BOOLEAN NOT NULL DEFAULT TRUE,
    last_fetched_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. LEGAL DOCUMENTS
CREATE TABLE IF NOT EXISTS legal_documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    jurisdiction_id UUID NOT NULL REFERENCES legal_jurisdictions(id) ON DELETE CASCADE,
    domain_id UUID NOT NULL REFERENCES legal_domains(id) ON DELETE CASCADE,
    source_id UUID REFERENCES legal_sources(id) ON DELETE SET NULL,
    document_code VARCHAR(100) NOT NULL, -- e.g. 'REG_EU_178_2002', 'SA_VAT_LAW_2020', 'TR_TTK_6102'
    title VARCHAR(300) NOT NULL,
    document_type VARCHAR(50) NOT NULL CHECK (document_type IN ('LAW', 'REGULATION', 'COMMUNIQUE', 'DIRECTIVE', 'STANDARD')),
    official_publication_number VARCHAR(100),
    official_publication_date DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_legal_document_code UNIQUE (jurisdiction_id, document_code)
);

-- 6. LEGAL DOCUMENT VERSIONS
CREATE TABLE IF NOT EXISTS legal_document_versions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    document_id UUID NOT NULL REFERENCES legal_documents(id) ON DELETE CASCADE,
    version_number VARCHAR(20) NOT NULL DEFAULT '1.0',
    effective_from DATE NOT NULL,
    effective_to DATE,
    status VARCHAR(30) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('DRAFT', 'ACTIVE', 'SUPERSEDED', 'REPEALED')),
    summary TEXT,
    change_log TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_doc_version UNIQUE (document_id, version_number)
);

-- 7. LEGAL ARTICLES
CREATE TABLE IF NOT EXISTS legal_articles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    document_version_id UUID NOT NULL REFERENCES legal_document_versions(id) ON DELETE CASCADE,
    article_number VARCHAR(50) NOT NULL, -- e.g. 'Article 18', 'Madde 11', 'Kural 53'
    title VARCHAR(255),
    content_text TEXT NOT NULL,
    is_actionable BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_article_num UNIQUE (document_version_id, article_number)
);

-- 8. LEGAL RULES
CREATE TABLE IF NOT EXISTS legal_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    article_id UUID REFERENCES legal_articles(id) ON DELETE SET NULL,
    jurisdiction_id UUID NOT NULL REFERENCES legal_jurisdictions(id) ON DELETE CASCADE,
    domain_id UUID NOT NULL REFERENCES legal_domains(id) ON DELETE CASCADE,
    rule_code VARCHAR(100) NOT NULL, -- e.g. 'EU_FOOD_TRACEABILITY_ART18', 'SA_VAT_STANDARD_15', 'DE_VERPACKG_LUCID'
    title VARCHAR(255) NOT NULL,
    rule_type VARCHAR(50) NOT NULL CHECK (rule_type IN ('REQUIREMENT', 'RESTRICTION', 'TAX_RATE', 'TARIFF', 'PROHIBITION', 'EXEMPTION')),
    direction VARCHAR(20) NOT NULL DEFAULT 'IMPORT' CHECK (direction IN ('IMPORT', 'EXPORT', 'DOMESTIC', 'TRANSIT', 'CROSS_BORDER')),
    rule_status VARCHAR(30) NOT NULL DEFAULT 'ACTIVE' CHECK (rule_status IN ('DISCOVERED', 'EXTRACTED', 'AI_PROPOSED', 'TESTING', 'LEGAL_REVIEW', 'APPROVED', 'ACTIVE', 'UNKNOWN')),
    confidence_score NUMERIC(5,2) DEFAULT 100.00,
    official_citation TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_rule_jurisdiction_code UNIQUE (jurisdiction_id, rule_code)
);

-- 9. LEGAL RULE VERSIONS
CREATE TABLE IF NOT EXISTS legal_rule_versions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_id UUID NOT NULL REFERENCES legal_rules(id) ON DELETE CASCADE,
    version_tag VARCHAR(20) NOT NULL DEFAULT '1.0',
    effective_from DATE NOT NULL,
    effective_to DATE,
    rule_parameters JSONB NOT NULL DEFAULT '{}'::JSONB,
    status VARCHAR(30) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'SUPERSEDED', 'PENDING_REVIEW')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_rule_version UNIQUE (rule_id, version_tag)
);

-- 10. LEGAL RULE CONDITIONS
CREATE TABLE IF NOT EXISTS legal_rule_conditions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_version_id UUID NOT NULL REFERENCES legal_rule_versions(id) ON DELETE CASCADE,
    field_name VARCHAR(100) NOT NULL, -- 'product_category', 'is_food', 'is_animal_origin', 'country_origin', 'is_organic'
    operator VARCHAR(30) NOT NULL CHECK (operator IN ('EQUALS', 'NOT_EQUALS', 'IN', 'NOT_IN', 'GREATER_THAN', 'LESS_THAN', 'CONTAINS')),
    expected_value JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 11. LEGAL RULE ACTIONS
CREATE TABLE IF NOT EXISTS legal_rule_actions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_version_id UUID NOT NULL REFERENCES legal_rule_versions(id) ON DELETE CASCADE,
    action_type VARCHAR(50) NOT NULL CHECK (action_type IN ('REQUIRE_DOCUMENT', 'REQUIRE_CERTIFICATE', 'APPLY_RATE', 'TRIGGER_BORDER_CHECK', 'REQUIRE_TRACES_NT', 'MANDATE_LABEL_LANGUAGE', 'BLOCK_TRANSACTION')),
    action_payload JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 12. LEGAL OBLIGATIONS
CREATE TABLE IF NOT EXISTS legal_obligations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_id UUID NOT NULL REFERENCES legal_rules(id) ON DELETE CASCADE,
    obligation_code VARCHAR(100) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    responsible_party VARCHAR(50) NOT NULL CHECK (responsible_party IN ('EXPORTER', 'IMPORTER', 'CARRIER', 'PRODUCER', 'DISTRIBUTOR')),
    severity VARCHAR(30) NOT NULL DEFAULT 'MANDATORY' CHECK (severity IN ('MANDATORY', 'CONDITIONAL', 'RECOMMENDED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_obligation_code UNIQUE (rule_id, obligation_code)
);

-- 13. LEGAL REQUIRED DOCUMENTS
CREATE TABLE IF NOT EXISTS legal_required_documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    obligation_id UUID REFERENCES legal_obligations(id) ON DELETE CASCADE,
    document_name VARCHAR(200) NOT NULL,
    issuing_authority VARCHAR(150),
    sample_url TEXT,
    is_mandatory BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 14. LEGAL CERTIFICATES
CREATE TABLE IF NOT EXISTS legal_certificates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    jurisdiction_id UUID NOT NULL REFERENCES legal_jurisdictions(id) ON DELETE CASCADE,
    certificate_code VARCHAR(100) NOT NULL, -- e.g. 'PHYTOSANITARY', 'HALAL_SFDA', 'ORGANIC_COI', 'HEALTH_CERT'
    name VARCHAR(255) NOT NULL,
    description TEXT,
    issuing_body_type VARCHAR(100),
    verification_method VARCHAR(100),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_cert_jurisdiction_code UNIQUE (jurisdiction_id, certificate_code)
);

-- 15. LEGAL PERMITS
CREATE TABLE IF NOT EXISTS legal_permits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    jurisdiction_id UUID NOT NULL REFERENCES legal_jurisdictions(id) ON DELETE CASCADE,
    permit_name VARCHAR(200) NOT NULL,
    authority_id UUID REFERENCES legal_authorities(id) ON DELETE SET NULL,
    validity_duration_days INT,
    prerequisite_rules JSONB DEFAULT '[]'::JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 16. LEGAL DEADLINES
CREATE TABLE IF NOT EXISTS legal_deadlines (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    obligation_id UUID REFERENCES legal_obligations(id) ON DELETE CASCADE,
    deadline_name VARCHAR(200) NOT NULL,
    deadline_type VARCHAR(50) NOT NULL CHECK (deadline_type IN ('PRIOR_TO_ARRIVAL', 'WITHIN_DAYS_OF_CLEARANCE', 'MONTHLY_RETURN', 'ANNUAL_RETURN')),
    timeframe_hours INT,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 17. LEGAL PENALTIES
CREATE TABLE IF NOT EXISTS legal_penalties (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    obligation_id UUID REFERENCES legal_obligations(id) ON DELETE CASCADE,
    penalty_type VARCHAR(50) NOT NULL CHECK (penalty_type IN ('FINANCIAL_FINE', 'SHIPMENT_REJECTION', 'CONFISCATION', 'LICENSE_SUSPENSION')),
    min_amount NUMERIC(15,2),
    max_amount NUMERIC(15,2),
    currency VARCHAR(10),
    description TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 18. LEGAL PRODUCT SCOPES
CREATE TABLE IF NOT EXISTS legal_product_scopes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_id UUID NOT NULL REFERENCES legal_rules(id) ON DELETE CASCADE,
    product_category VARCHAR(100) NOT NULL, -- 'DATES', 'DRIED_FRUITS', 'FOOD_NON_ANIMAL', 'FOOD_ANIMAL', 'ALL_FOOD'
    hs_code_prefix VARCHAR(20), -- e.g. '080410' for dates (taze/kuru hurma)
    is_food BOOLEAN NOT NULL DEFAULT TRUE,
    is_animal_origin BOOLEAN NOT NULL DEFAULT FALSE,
    is_processed BOOLEAN,
    is_organic BOOLEAN,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 19. LEGAL COUNTRY SCOPES
CREATE TABLE IF NOT EXISTS legal_country_scopes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_id UUID NOT NULL REFERENCES legal_rules(id) ON DELETE CASCADE,
    scope_type VARCHAR(30) NOT NULL CHECK (scope_type IN ('ORIGIN', 'DESTINATION', 'TRANSIT', 'THIRD_COUNTRY')),
    country_code VARCHAR(10) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 20. LEGAL TRANSACTION SCOPES
CREATE TABLE IF NOT EXISTS legal_transaction_scopes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_id UUID NOT NULL REFERENCES legal_rules(id) ON DELETE CASCADE,
    transaction_type VARCHAR(50) NOT NULL CHECK (transaction_type IN ('B2B_EXPORT', 'B2B_IMPORT', 'RETAIL_SALE', 'INTRA_COMMUNITY', 'TRANSIT')),
    incoterm VARCHAR(10), -- 'FOB', 'CIF', 'DDP', etc.
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 21. LEGAL APPLICABILITY
CREATE TABLE IF NOT EXISTS legal_applicability (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_id UUID NOT NULL REFERENCES legal_rules(id) ON DELETE CASCADE,
    source_country VARCHAR(10) NOT NULL,
    destination_country VARCHAR(10) NOT NULL,
    product_profile_signature VARCHAR(100) NOT NULL,
    evaluation_logic JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 22. LEGAL CHANGE EVENTS
CREATE TABLE IF NOT EXISTS legal_change_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    jurisdiction_id UUID NOT NULL REFERENCES legal_jurisdictions(id) ON DELETE CASCADE,
    event_type VARCHAR(50) NOT NULL CHECK (event_type IN ('NEW_LAW_PUBLISHED', 'AMENDMENT', 'TARIFF_UPDATE', 'EMERGENCY_MEASURE', 'REPEAL')),
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    published_date DATE NOT NULL,
    effective_date DATE NOT NULL,
    source_url TEXT,
    status VARCHAR(30) NOT NULL DEFAULT 'NEW' CHECK (status IN ('NEW', 'ANALYZED', 'APPLIED', 'DISMISSED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 23. LEGAL REVIEW QUEUE
CREATE TABLE IF NOT EXISTS legal_review_queue (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_id UUID REFERENCES legal_rules(id) ON DELETE CASCADE,
    change_event_id UUID REFERENCES legal_change_events(id) ON DELETE SET NULL,
    proposed_by VARCHAR(50) NOT NULL DEFAULT 'AI_EXTRACTION' CHECK (proposed_by IN ('AI_EXTRACTION', 'USER_REQUEST', 'OFFICIAL_CRAWLER')),
    review_status VARCHAR(30) NOT NULL DEFAULT 'PENDING' CHECK (review_status IN ('PENDING', 'IN_REVIEW', 'APPROVED', 'REJECTED')),
    reviewer_user_id UUID,
    reviewer_notes TEXT,
    reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 24. LEGAL SOURCE WATCHERS
CREATE TABLE IF NOT EXISTS legal_source_watchers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    source_id UUID NOT NULL REFERENCES legal_sources(id) ON DELETE CASCADE,
    watch_frequency_hours INT NOT NULL DEFAULT 24,
    last_run_at TIMESTAMPTZ,
    last_run_status VARCHAR(30) DEFAULT 'SUCCESS',
    consecutive_failures INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 25. LEGAL PACK REGISTRY
CREATE TABLE IF NOT EXISTS legal_pack_registry (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pack_code VARCHAR(50) NOT NULL UNIQUE, -- 'SAUDI_ARABIA_PACK', 'TURKEY_PACK', 'EU_FOOD_IMPORT_PACK', 'GERMANY_FOOD_IMPORT_PACK', etc.
    jurisdiction_id UUID NOT NULL REFERENCES legal_jurisdictions(id) ON DELETE CASCADE,
    pack_name_tr VARCHAR(150) NOT NULL,
    pack_name_en VARCHAR(150) NOT NULL,
    scope VARCHAR(50) NOT NULL CHECK (scope IN ('FULL_BUSINESS_OPERATION', 'FOOD_IMPORT_ONLY', 'FOOD_EXPORT_ONLY', 'NONE')),
    status VARCHAR(30) NOT NULL DEFAULT 'NOT_LOADED' CHECK (status IN ('ACTIVE', 'NOT_LOADED', 'DISCOVERY', 'PARTIAL', 'SUSPENDED')),
    coverage_percentage NUMERIC(5,2) NOT NULL DEFAULT 0.00,
    last_reviewed_at TIMESTAMPTZ,
    last_source_sync TIMESTAMPTZ,
    next_review TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==============================================================================
-- INITIAL SEEDING: 4 ACTIVE PACKS + EMPTY SHELVES
-- ==============================================================================

-- 1. JURISDICTIONS SEED
INSERT INTO legal_jurisdictions (code, iso_alpha2, iso_alpha3, name_tr, name_en, name_ar, region, jurisdiction_type, is_active, shelf_status, official_portal_url)
VALUES
-- ACTIVE 4
('SA', 'SA', 'SAU', 'Suudi Arabistan', 'Saudi Arabia', 'المملكة العربية السعودية', 'MIDDLE_EAST', 'NATIONAL', TRUE, 'ACTIVE', 'https://zatca.gov.sa'),
('TR', 'TR', 'TUR', 'Türkiye', 'Turkey', 'تركيا', 'MIDDLE_EAST', 'NATIONAL', TRUE, 'ACTIVE', 'https://www.gib.gov.tr'),
('EU', 'EU', 'EUR', 'Avrupa Birliği (Gıda İthalatı)', 'European Union (Food Import)', 'الاتحاد الأوروبي', 'EUROPE', 'SUPRANATIONAL', TRUE, 'ACTIVE', 'https://food.ec.europa.eu'),
('DE', 'DE', 'DEU', 'Almanya (Gıda İthalatı & Pazar)', 'Germany (Food Import & Market)', 'ألمانيا', 'EUROPE', 'NATIONAL', TRUE, 'ACTIVE', 'https://www.bvl.bund.de'),

-- EMPTY SHELVES (NOT_LOADED)
('CN', 'CN', 'CHN', 'Çin', 'China', 'الصين', 'ASIA', 'NATIONAL', FALSE, 'NOT_LOADED', 'http://customs.gov.cn'),
('IN', 'IN', 'IND', 'Hindistan', 'India', 'الهند', 'ASIA', 'NATIONAL', FALSE, 'NOT_LOADED', 'https://www.fssai.gov.in'),
('RU', 'RU', 'RUS', 'Rusya', 'Russia', 'روسيا', 'ASIA', 'NATIONAL', FALSE, 'NOT_LOADED', 'https://fsvps.gov.ru'),
('AE', 'AE', 'ARE', 'Birleşik Arap Emirlikleri', 'United Arab Emirates', 'الإمارات العربية المتحدة', 'MIDDLE_EAST', 'NATIONAL', FALSE, 'NOT_LOADED', 'https://tax.gov.ae'),
('QA', 'QA', 'QAT', 'Katar', 'Qatar', 'قطر', 'MIDDLE_EAST', 'NATIONAL', FALSE, 'NOT_LOADED', 'https://www.moph.gov.qa'),
('KW', 'KW', 'KWT', 'Kuveyt', 'Kuwait', 'الكويت', 'MIDDLE_EAST', 'NATIONAL', FALSE, 'NOT_LOADED', 'https://www.customs.gov.kw'),
('BH', 'BH', 'BHR', 'Bahreyn', 'Bahrain', 'البحرين', 'MIDDLE_EAST', 'NATIONAL', FALSE, 'NOT_LOADED', 'https://www.nbr.gov.bh'),
('OM', 'OM', 'OMN', 'Umman', 'Oman', 'عمان', 'MIDDLE_EAST', 'NATIONAL', FALSE, 'NOT_LOADED', 'https://tms.taxoman.gov.om'),
('EG', 'EG', 'EGY', 'Mısır', 'Egypt', 'مصر', 'MIDDLE_EAST', 'NATIONAL', FALSE, 'NOT_LOADED', 'https://www.eta.gov.eg'),
('JO', 'JO', 'JOR', 'Ürdün', 'Jordan', 'الأردن', 'MIDDLE_EAST', 'NATIONAL', FALSE, 'NOT_LOADED', 'https://jfda.jo'),
('GB', 'GB', 'GBR', 'Birleşik Krallık', 'United Kingdom', 'المملكة المتحدة', 'EUROPE', 'NATIONAL', FALSE, 'NOT_LOADED', 'https://www.food.gov.uk'),
('US', 'US', 'USA', 'Amerika Birleşik Devletleri', 'United States', 'الولايات المتحدة', 'AMERICAS', 'NATIONAL', FALSE, 'NOT_LOADED', 'https://www.fda.gov'),
('CA', 'CA', 'CAN', 'Kanada', 'Canada', 'كندا', 'AMERICAS', 'NATIONAL', FALSE, 'NOT_LOADED', 'https://inspection.canada.ca'),
('AU', 'AU', 'AUS', 'Avustralya', 'Australia', 'أستراليا', 'ASIA', 'NATIONAL', FALSE, 'NOT_LOADED', 'https://www.agriculture.gov.au'),
('JP', 'JP', 'JPN', 'Japonya', 'Japan', 'اليابان', 'ASIA', 'NATIONAL', FALSE, 'NOT_LOADED', 'https://www.mhlw.go.jp'),
('KR', 'KR', 'KOR', 'Güney Kore', 'South Korea', 'كوريا الجنوبية', 'ASIA', 'NATIONAL', FALSE, 'NOT_LOADED', 'https://www.mfds.go.kr'),
('KZ', 'KZ', 'KAZ', 'Kazakistan', 'Kazakhstan', 'كازاخستان', 'ASIA', 'NATIONAL', FALSE, 'NOT_LOADED', 'https://kgd.gov.kz'),
('UZ', 'UZ', 'UZB', 'Özbekistan', 'Uzbekistan', 'أوزبكستان', 'ASIA', 'NATIONAL', FALSE, 'NOT_LOADED', 'https://soliq.uz'),
('AZ', 'AZ', 'AZE', 'Azerbaycan', 'Azerbaijan', 'أذربيجان', 'ASIA', 'NATIONAL', FALSE, 'NOT_LOADED', 'https://afsa.gov.az')
ON CONFLICT (code) DO NOTHING;

-- 2. LEGAL DOMAINS SEED
INSERT INTO legal_domains (code, name_tr, name_en, description)
VALUES
('TAX', 'Vergi ve Harçlar', 'Tax & Levies', 'KDV, Gelir, Kurumlar, Stopaj, ÖTV'),
('CUSTOMS', 'Gümrük ve Dış Ticaret', 'Customs & Foreign Trade', 'Gümrük tarifesi, GTİP/HS kodları, Fasah, TRACES'),
('FOOD_SAFETY', 'Gıda Güvenliği', 'Food Safety', 'Hijyen, kontaminant, pestisit MRL, izlenebilirlik'),
('FOOD_IMPORT', 'Gıda İthalatı Kontrolleri', 'Food Import Controls', 'Resmi kontroller, sınır kontrol noktaları, analizler'),
('LABELING', 'Gıda Etiketleme', 'Food Labeling', 'Zorunlu bilgiler, dil şartı, besin tablosu, alerjenler'),
('TRACEABILITY', 'İzlenebilirlik', 'Traceability', 'Çiftlikten çatala partileme, lot takibi, geri çağırma'),
('HALAL', 'Helal Standartları', 'Halal Standards', 'SFDA Helal, HAK Helal, SMIIC uygunluk'),
('COMMERCE', 'Ticaret ve Şirketler Hukuku', 'Commerce & Company Law', 'CR, MERSİS, TTK, sözleşmeler'),
('PACKAGING', 'Ambalaj ve Temas Eden Materyaller', 'Packaging & Food Contact Materials', 'Migration testleri, VerpackG LUCID, geri dönüşüm')
ON CONFLICT (code) DO NOTHING;

-- 3. LEGAL AUTHORITIES SEED (Active Jurisdictions)
INSERT INTO legal_authorities (jurisdiction_id, code, name_tr, name_en, name_native, authority_type, official_website, trust_level)
SELECT id, 'SA_ZATCA', 'Zekât, Vergi ve Gümrük İdaresi', 'Zakat, Tax and Customs Authority', 'هيئة الزكاة والضريبة والجمارك', 'TAX', 'https://zatca.gov.sa', 1 FROM legal_jurisdictions WHERE code = 'SA'
ON CONFLICT (jurisdiction_id, code) DO NOTHING;

INSERT INTO legal_authorities (jurisdiction_id, code, name_tr, name_en, name_native, authority_type, official_website, trust_level)
SELECT id, 'SA_SFDA', 'Suudi Gıda ve İlaç Kurumu', 'Saudi Food and Drug Authority', 'الهيئة العامة للغذاء والدواء', 'FOOD_SAFETY', 'https://www.sfda.gov.sa', 1 FROM legal_jurisdictions WHERE code = 'SA'
ON CONFLICT (jurisdiction_id, code) DO NOTHING;

INSERT INTO legal_authorities (jurisdiction_id, code, name_tr, name_en, name_native, authority_type, official_website, trust_level)
SELECT id, 'SA_MOC', 'Suudi Ticaret Bakanlığı', 'Ministry of Commerce', 'وزارة التجارة', 'COMMERCE', 'https://mc.gov.sa', 1 FROM legal_jurisdictions WHERE code = 'SA'
ON CONFLICT (jurisdiction_id, code) DO NOTHING;

INSERT INTO legal_authorities (jurisdiction_id, code, name_tr, name_en, name_native, authority_type, official_website, trust_level)
SELECT id, 'TR_GIB', 'Gelir İdaresi Başkanlığı', 'Turkish Revenue Administration', 'Gelir İdaresi Başkanlığı', 'TAX', 'https://www.gib.gov.tr', 1 FROM legal_jurisdictions WHERE code = 'TR'
ON CONFLICT (jurisdiction_id, code) DO NOTHING;

INSERT INTO legal_authorities (jurisdiction_id, code, name_tr, name_en, name_native, authority_type, official_website, trust_level)
SELECT id, 'TR_TARIM', 'Tarım ve Orman Bakanlığı (Gıda ve Kontrol)', 'Ministry of Agriculture and Forestry', 'Tarım ve Orman Bakanlığı', 'FOOD_SAFETY', 'https://www.tarimorman.gov.tr', 1 FROM legal_jurisdictions WHERE code = 'TR'
ON CONFLICT (jurisdiction_id, code) DO NOTHING;

INSERT INTO legal_authorities (jurisdiction_id, code, name_tr, name_en, name_native, authority_type, official_website, trust_level)
SELECT id, 'TR_TICARET', 'Ticaret Bakanlığı (Gümrükler Gn. Md.)', 'Ministry of Trade', 'Ticaret Bakanlığı', 'CUSTOMS', 'https://ticaret.gov.tr', 1 FROM legal_jurisdictions WHERE code = 'TR'
ON CONFLICT (jurisdiction_id, code) DO NOTHING;

INSERT INTO legal_authorities (jurisdiction_id, code, name_tr, name_en, name_native, authority_type, official_website, trust_level)
SELECT id, 'EU_SANTE', 'Avrupa Komisyonu Sağlık ve Gıda Güvenliği Gn. Md.', 'DG Health and Food Safety', 'DG SANTE', 'FOOD_SAFETY', 'https://food.ec.europa.eu', 1 FROM legal_jurisdictions WHERE code = 'EU'
ON CONFLICT (jurisdiction_id, code) DO NOTHING;

INSERT INTO legal_authorities (jurisdiction_id, code, name_tr, name_en, name_native, authority_type, official_website, trust_level)
SELECT id, 'EU_TRACES', 'Avrupa Komisyonu TRACES NT Sistemi', 'TRACES NT Digital Certification', 'TRACES NT', 'CUSTOMS', 'https://webgate.ec.europa.eu/tracesnt', 1 FROM legal_jurisdictions WHERE code = 'EU'
ON CONFLICT (jurisdiction_id, code) DO NOTHING;

INSERT INTO legal_authorities (jurisdiction_id, code, name_tr, name_en, name_native, authority_type, official_website, trust_level)
SELECT id, 'DE_BVL', 'Tüketici Koruma ve Gıda Güvenliği Federal Dairesi', 'Federal Office of Consumer Protection and Food Safety', 'Bundesamt für Verbraucherschutz und Lebensmittelsicherheit', 'FOOD_SAFETY', 'https://www.bvl.bund.de', 1 FROM legal_jurisdictions WHERE code = 'DE'
ON CONFLICT (jurisdiction_id, code) DO NOTHING;

INSERT INTO legal_authorities (jurisdiction_id, code, name_tr, name_en, name_native, authority_type, official_website, trust_level)
SELECT id, 'DE_LUCID', 'Merkezi Ambalaj Sicil Dairesi (LUCID)', 'Central Agency Packaging Register', 'Zentrale Stelle Verpackungsregister', 'PACKAGING', 'https://www.verpackungsregister.org', 1 FROM legal_jurisdictions WHERE code = 'DE'
ON CONFLICT (jurisdiction_id, code) DO NOTHING;

-- 4. LEGAL PACK REGISTRY SEED
INSERT INTO legal_pack_registry (pack_code, jurisdiction_id, pack_name_tr, pack_name_en, scope, status, coverage_percentage, notes)
SELECT 'SAUDI_ARABIA_PACK', id, 'Suudi Arabistan Tam Operasyonel Mevzuat Paketi', 'Saudi Arabia Full Business Operation Pack', 'FULL_BUSINESS_OPERATION', 'ACTIVE', 98.50, 'ZATCA Vergi/Gümrük/KDV %15, 1445H Zekat, SFDA Gıda İthalat & Kayıt, Fasah, Helal, Ticaret Sicili'
FROM legal_jurisdictions WHERE code = 'SA'
ON CONFLICT (pack_code) DO NOTHING;

INSERT INTO legal_pack_registry (pack_code, jurisdiction_id, pack_name_tr, pack_name_en, scope, status, coverage_percentage, notes)
SELECT 'TURKEY_PACK', id, 'Türkiye Tam Operasyonel Mevzuat Paketi', 'Turkey Full Business Operation Pack', 'FULL_BUSINESS_OPERATION', 'ACTIVE', 98.00, 'GİB KDV %1/%10/%20, Kurumlar %25, TTK/MERSİS, Tarım Bak. Gıda Güvenliği, GTİP Gümrük, HAK Helal'
FROM legal_jurisdictions WHERE code = 'TR'
ON CONFLICT (pack_code) DO NOTHING;

INSERT INTO legal_pack_registry (pack_code, jurisdiction_id, pack_name_tr, pack_name_en, scope, status, coverage_percentage, notes)
SELECT 'EU_FOOD_IMPORT_PACK', id, 'Avrupa Birliği Gıda İthalatı Paketi', 'European Union Food Import Pack', 'FOOD_IMPORT_ONLY', 'ACTIVE', 95.00, 'Reg 178/2002 General Food Law, Reg 2017/625 Resmi Kontroller, TRACES NT CHED, Reg 1169/2011 Etiketleme, Pestisit/Kontaminant'
FROM legal_jurisdictions WHERE code = 'EU'
ON CONFLICT (pack_code) DO NOTHING;

INSERT INTO legal_pack_registry (pack_code, jurisdiction_id, pack_name_tr, pack_name_en, scope, status, coverage_percentage, notes)
SELECT 'GERMANY_FOOD_IMPORT_PACK', id, 'Almanya Gıda İthalatı ve Piyasaya Arz Paketi', 'Germany Food Import & Market Pack', 'FOOD_IMPORT_ONLY', 'ACTIVE', 94.50, 'BVL/LFGB Denetimleri, VerpackG LUCID Ambalaj Lisansı, Almanca Etiketleme Zorunluluğu, İthalatçı Sorumlulukları'
FROM legal_jurisdictions WHERE code = 'DE'
ON CONFLICT (pack_code) DO NOTHING;

-- Seed Empty Shelves into Pack Registry
INSERT INTO legal_pack_registry (pack_code, jurisdiction_id, pack_name_tr, pack_name_en, scope, status, coverage_percentage, notes)
SELECT 
    lj.code || '_PACK',
    lj.id,
    lj.name_tr || ' Mevzuat Rafı',
    lj.name_en || ' Shelf',
    'NONE',
    'NOT_LOADED',
    0.00,
    'Boş raf: İleride ticari gereksinim doğduğunda on-demand discovery ile doldurulacaktır.'
FROM legal_jurisdictions lj
WHERE lj.shelf_status = 'NOT_LOADED'
ON CONFLICT (pack_code) DO NOTHING;

-- ==============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ==============================================================================
ALTER TABLE legal_jurisdictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE legal_authorities ENABLE ROW LEVEL SECURITY;
ALTER TABLE legal_domains ENABLE ROW LEVEL SECURITY;
ALTER TABLE legal_sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE legal_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE legal_document_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE legal_articles ENABLE ROW LEVEL SECURITY;
ALTER TABLE legal_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE legal_rule_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE legal_rule_conditions ENABLE ROW LEVEL SECURITY;
ALTER TABLE legal_rule_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE legal_obligations ENABLE ROW LEVEL SECURITY;
ALTER TABLE legal_required_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE legal_certificates ENABLE ROW LEVEL SECURITY;
ALTER TABLE legal_permits ENABLE ROW LEVEL SECURITY;
ALTER TABLE legal_deadlines ENABLE ROW LEVEL SECURITY;
ALTER TABLE legal_penalties ENABLE ROW LEVEL SECURITY;
ALTER TABLE legal_product_scopes ENABLE ROW LEVEL SECURITY;
ALTER TABLE legal_country_scopes ENABLE ROW LEVEL SECURITY;
ALTER TABLE legal_transaction_scopes ENABLE ROW LEVEL SECURITY;
ALTER TABLE legal_applicability ENABLE ROW LEVEL SECURITY;
ALTER TABLE legal_change_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE legal_review_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE legal_source_watchers ENABLE ROW LEVEL SECURITY;
ALTER TABLE legal_pack_registry ENABLE ROW LEVEL SECURITY;

-- Okuma Politikaları: Tüm kimlik doğrulamış kiracılar ve sistem kullanıcıları genel mevzuat kütüphanesini okuyabilir.
CREATE POLICY "legal_jurisdictions_public_read" ON legal_jurisdictions FOR SELECT USING (true);
CREATE POLICY "legal_authorities_public_read" ON legal_authorities FOR SELECT USING (true);
CREATE POLICY "legal_domains_public_read" ON legal_domains FOR SELECT USING (true);
CREATE POLICY "legal_sources_public_read" ON legal_sources FOR SELECT USING (true);
CREATE POLICY "legal_documents_public_read" ON legal_documents FOR SELECT USING (true);
CREATE POLICY "legal_document_versions_public_read" ON legal_document_versions FOR SELECT USING (true);
CREATE POLICY "legal_articles_public_read" ON legal_articles FOR SELECT USING (true);
CREATE POLICY "legal_rules_public_read" ON legal_rules FOR SELECT USING (true);
CREATE POLICY "legal_rule_versions_public_read" ON legal_rule_versions FOR SELECT USING (true);
CREATE POLICY "legal_rule_conditions_public_read" ON legal_rule_conditions FOR SELECT USING (true);
CREATE POLICY "legal_rule_actions_public_read" ON legal_rule_actions FOR SELECT USING (true);
CREATE POLICY "legal_obligations_public_read" ON legal_obligations FOR SELECT USING (true);
CREATE POLICY "legal_required_documents_public_read" ON legal_required_documents FOR SELECT USING (true);
CREATE POLICY "legal_certificates_public_read" ON legal_certificates FOR SELECT USING (true);
CREATE POLICY "legal_permits_public_read" ON legal_permits FOR SELECT USING (true);
CREATE POLICY "legal_deadlines_public_read" ON legal_deadlines FOR SELECT USING (true);
CREATE POLICY "legal_penalties_public_read" ON legal_penalties FOR SELECT USING (true);
CREATE POLICY "legal_product_scopes_public_read" ON legal_product_scopes FOR SELECT USING (true);
CREATE POLICY "legal_country_scopes_public_read" ON legal_country_scopes FOR SELECT USING (true);
CREATE POLICY "legal_transaction_scopes_public_read" ON legal_transaction_scopes FOR SELECT USING (true);
CREATE POLICY "legal_applicability_public_read" ON legal_applicability FOR SELECT USING (true);
CREATE POLICY "legal_change_events_public_read" ON legal_change_events FOR SELECT USING (true);
CREATE POLICY "legal_pack_registry_public_read" ON legal_pack_registry FOR SELECT USING (true);
CREATE POLICY "legal_review_queue_public_read" ON legal_review_queue FOR SELECT USING (true);
CREATE POLICY "legal_source_watchers_public_read" ON legal_source_watchers FOR SELECT USING (true);

-- İndeksler
CREATE INDEX IF NOT EXISTS idx_legal_jurisdictions_active ON legal_jurisdictions(is_active, shelf_status);
CREATE INDEX IF NOT EXISTS idx_legal_rules_lookup ON legal_rules(jurisdiction_id, domain_id, direction, rule_status);
CREATE INDEX IF NOT EXISTS idx_legal_rule_versions_dates ON legal_rule_versions(rule_id, effective_from, effective_to);
CREATE INDEX IF NOT EXISTS idx_legal_product_scopes_cat ON legal_product_scopes(product_category, hs_code_prefix);
CREATE INDEX IF NOT EXISTS idx_legal_pack_registry_status ON legal_pack_registry(pack_code, status);
