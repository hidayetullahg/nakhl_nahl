// NAKHL & NAHL — Integration Provider Registry
// Complies with Master Directive Section 4

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/integration_models.dart';

class IntegrationProviderRegistry {
  static final IntegrationProviderRegistry _instance = IntegrationProviderRegistry._internal();
  factory IntegrationProviderRegistry() => _instance;
  IntegrationProviderRegistry._internal();

  /// Built-in fallback profiles if database connection is offline or during bootstrap
  static final List<CountryIntegrationProfile> defaultProfiles = [
    // Türkiye GİB Sandbox & Production
    const CountryIntegrationProfile(
      id: 'reg_tr_gib_sandbox',
      countryCode: 'TR',
      countryName: 'Türkiye',
      currency: 'TRY',
      taxSystem: 'KDV',
      invoiceFormat: 'UBL-TR',
      providerType: 'GIB',
      providerName: 'Gelir İdaresi Başkanlığı (Test/Sandbox)',
      environment: 'sandbox',
      endpoint: 'https://efatura-test.gib.gov.tr/services',
      authenticationType: 'CERTIFICATE',
      certificateRequired: true,
      signingRequired: true,
      reportingRequired: true,
      configurationSchema: {
        'fields': ['vkn', 'portal_username', 'portal_password', 'test_api_key']
      },
    ),
    const CountryIntegrationProfile(
      id: 'reg_tr_gib_prod',
      countryCode: 'TR',
      countryName: 'Türkiye',
      currency: 'TRY',
      taxSystem: 'KDV',
      invoiceFormat: 'UBL-TR',
      providerType: 'GIB',
      providerName: 'Gelir İdaresi Başkanlığı (Canlı)',
      environment: 'production',
      endpoint: 'https://merkez.efatura.gov.tr/services',
      authenticationType: 'CERTIFICATE',
      certificateRequired: true,
      signingRequired: true,
      reportingRequired: true,
      configurationSchema: {
        'fields': ['vkn', 'mali_muhur_alias', 'hsm_pin', 'api_token']
      },
    ),
    // Türkiye Özel Entegratörler
    const CountryIntegrationProfile(
      id: 'reg_tr_logo',
      countryCode: 'TR',
      countryName: 'Türkiye',
      currency: 'TRY',
      taxSystem: 'KDV',
      invoiceFormat: 'UBL-TR',
      providerType: 'LOGO',
      providerName: 'Logo Özel Entegratör',
      environment: 'production',
      endpoint: 'https://elogo.com.tr/e-fatura/api/v1',
      authenticationType: 'API_KEY',
      signingRequired: true,
      reportingRequired: true,
      configurationSchema: {
        'fields': ['vkn', 'app_key', 'app_secret', 'sender_alias']
      },
    ),
    const CountryIntegrationProfile(
      id: 'reg_tr_qnb',
      countryCode: 'TR',
      countryName: 'Türkiye',
      currency: 'TRY',
      taxSystem: 'KDV',
      invoiceFormat: 'UBL-TR',
      providerType: 'QNB',
      providerName: 'QNB eFinans Özel Entegratör',
      environment: 'production',
      endpoint: 'https://efinans.qnb.com.tr/services/v2',
      authenticationType: 'OAUTH2',
      signingRequired: true,
      reportingRequired: true,
      configurationSchema: {
        'fields': ['vkn', 'client_id', 'client_secret', 'mailbox_alias']
      },
    ),
    const CountryIntegrationProfile(
      id: 'reg_tr_uyumsoft',
      countryCode: 'TR',
      countryName: 'Türkiye',
      currency: 'TRY',
      taxSystem: 'KDV',
      invoiceFormat: 'UBL-TR',
      providerType: 'UYUMSOFT',
      providerName: 'Uyumsoft Bilgi Sistemleri',
      environment: 'production',
      endpoint: 'https://efatura.uyumsoft.com.tr/services/integration',
      authenticationType: 'BASIC_AUTH',
      signingRequired: true,
      reportingRequired: true,
      configurationSchema: {
        'fields': ['vkn', 'username', 'password', 'alias']
      },
    ),
    const CountryIntegrationProfile(
      id: 'reg_tr_sovos',
      countryCode: 'TR',
      countryName: 'Türkiye',
      currency: 'TRY',
      taxSystem: 'KDV',
      invoiceFormat: 'UBL-TR',
      providerType: 'SOVOS',
      providerName: 'Sovos Foriba Entegratör',
      environment: 'production',
      endpoint: 'https://api.sovos.com.tr/einvoice/v1',
      authenticationType: 'API_KEY',
      signingRequired: true,
      reportingRequired: true,
      configurationSchema: {
        'fields': ['vkn', 'api_key', 'partner_code']
      },
    ),
    // Suudi Arabistan ZATCA Phase 2 Fatoora
    const CountryIntegrationProfile(
      id: 'reg_sa_zatca_sandbox',
      countryCode: 'SA',
      countryName: 'Saudi Arabia',
      currency: 'SAR',
      taxSystem: 'VAT',
      invoiceFormat: 'UBL-2.1',
      providerType: 'ZATCA',
      providerName: 'ZATCA Fatoora Phase 2 (Developer Sandbox)',
      environment: 'sandbox',
      endpoint: 'https://gw-fatoora.zatca.gov.sa/e-invoicing/developer-portal',
      authenticationType: 'CSID',
      certificateRequired: true,
      signingRequired: true,
      qrRequired: true,
      clearanceRequired: true,
      reportingRequired: true,
      configurationSchema: {
        'fields': ['vat_number', 'otp', 'csr_pem', 'csid_binary', 'csid_secret']
      },
    ),
    const CountryIntegrationProfile(
      id: 'reg_sa_zatca_prod',
      countryCode: 'SA',
      countryName: 'Saudi Arabia',
      currency: 'SAR',
      taxSystem: 'VAT',
      invoiceFormat: 'UBL-2.1',
      providerType: 'ZATCA',
      providerName: 'ZATCA Fatoora Phase 2 (Live Core)',
      environment: 'production',
      endpoint: 'https://gw-fatoora.zatca.gov.sa/e-invoicing/core',
      authenticationType: 'CSID',
      certificateRequired: true,
      signingRequired: true,
      qrRequired: true,
      clearanceRequired: true,
      reportingRequired: true,
      configurationSchema: {
        'fields': ['vat_number', 'production_csid', 'production_secret', 'private_key']
      },
    ),
    // UAE FTA Peppol
    const CountryIntegrationProfile(
      id: 'reg_ae_peppol',
      countryCode: 'AE',
      countryName: 'United Arab Emirates',
      currency: 'AED',
      taxSystem: 'VAT',
      invoiceFormat: 'PEPPOL-BIS-3.0',
      providerType: 'PEPPOL',
      providerName: 'UAE FTA Peppol Gateway',
      environment: 'sandbox',
      endpoint: 'https://peppol-sandbox.fta.gov.ae/api/v1',
      authenticationType: 'OAUTH2',
      certificateRequired: true,
      signingRequired: true,
      qrRequired: true,
      reportingRequired: true,
      configurationSchema: {
        'fields': ['trn', 'client_id', 'client_secret', 'participant_id']
      },
    ),
    // EU Peppol
    const CountryIntegrationProfile(
      id: 'reg_eu_peppol',
      countryCode: 'EU',
      countryName: 'European Union',
      currency: 'EUR',
      taxSystem: 'VAT',
      invoiceFormat: 'PEPPOL-BIS-3.0',
      providerType: 'PEPPOL',
      providerName: 'OpenPEPPOL Access Point',
      environment: 'sandbox',
      endpoint: 'https://test-ap.peppol.eu/accesspoint/as4',
      authenticationType: 'CERTIFICATE',
      certificateRequired: true,
      signingRequired: true,
      reportingRequired: true,
      configurationSchema: {
        'fields': ['peppol_id', 'cert_thumbprint', 'as4_endpoint']
      },
    ),
  ];

  /// Get list of profiles for a specific country
  Future<List<CountryIntegrationProfile>> getProfilesForCountry(String countryCode) async {
    try {
      final client = Supabase.instance.client;
      final res = await client
          .from('integration_provider_registry')
          .select()
          .eq('country_code', countryCode.toUpperCase())
          .eq('active', true);
      
      if (res.isNotEmpty) {
        return (res as List).map((e) => CountryIntegrationProfile.fromJson(e)).toList();
      }
    } catch (_) {
      // Fallback to in-memory registry
    }

    return defaultProfiles
        .where((p) => p.countryCode == countryCode.toUpperCase())
        .toList();
  }

  /// Get distinct supported countries
  Future<List<Map<String, String>>> getSupportedCountries() async {
    return [
      {'code': 'TR', 'name': 'Türkiye 🇹🇷', 'currency': 'TRY'},
      {'code': 'SA', 'name': 'Saudi Arabia 🇸🇦', 'currency': 'SAR'},
      {'code': 'AE', 'name': 'United Arab Emirates 🇦🇪', 'currency': 'AED'},
      {'code': 'EU', 'name': 'European Union 🇪🇺', 'currency': 'EUR'},
      {'code': 'DE', 'name': 'Germany 🇩🇪', 'currency': 'EUR'},
      {'code': 'US', 'name': 'United States 🇺🇸', 'currency': 'USD'},
    ];
  }

  /// Find profile by provider and environment
  CountryIntegrationProfile? findProfile(String countryCode, String providerType, String environment) {
    try {
      return defaultProfiles.firstWhere(
        (p) =>
            p.countryCode == countryCode.toUpperCase() &&
            p.providerType == providerType.toUpperCase() &&
            p.environment == environment.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}
