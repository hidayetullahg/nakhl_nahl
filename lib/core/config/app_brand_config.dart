// ==============================================================================
// NAKHL & NAHL — APP BRAND & DOMAIN CONFIGURATION
// Decouples commercial branding, product name, logos, and domain from technical architecture
// Complies with Master Prompt Section 2 & 106
// ==============================================================================

class AppBrandConfig {
  final String productName;
  final String shortName;
  final String companyLegalName;
  final String primaryDomain;
  final String supportEmail;
  final String salesEmail;
  final String logoAsset;
  final String faviconAsset;
  final String privacyPolicyUrl;
  final String termsOfServiceUrl;
  final String documentationUrl;
  final String copyrightText;

  const AppBrandConfig({
    required this.productName,
    required this.shortName,
    required this.companyLegalName,
    required this.primaryDomain,
    required this.supportEmail,
    required this.salesEmail,
    required this.logoAsset,
    required this.faviconAsset,
    required this.privacyPolicyUrl,
    required this.termsOfServiceUrl,
    required this.documentationUrl,
    required this.copyrightText,
  });

  /// Compile-time or runtime configurable instance
  /// Can be overridden via --dart-define flags without altering internal code
  static AppBrandConfig get current {
    const pName = String.fromEnvironment('BRAND_PRODUCT_NAME', defaultValue: 'NAKHL & NAHL');
    const sName = String.fromEnvironment('BRAND_SHORT_NAME', defaultValue: 'NAKHL');
    const cName = String.fromEnvironment('BRAND_COMPANY_NAME', defaultValue: 'NAKHL & NAHL Global Technology Ltd.');
    const domain = String.fromEnvironment('BRAND_PRIMARY_DOMAIN', defaultValue: 'beeofdate.com');
    const supEmail = String.fromEnvironment('BRAND_SUPPORT_EMAIL', defaultValue: 'support@beeofdate.com');
    const salEmail = String.fromEnvironment('BRAND_SALES_EMAIL', defaultValue: 'sales@beeofdate.com');

    return AppBrandConfig(
      productName: pName,
      shortName: sName,
      companyLegalName: cName,
      primaryDomain: domain,
      supportEmail: supEmail,
      salesEmail: salEmail,
      logoAsset: 'assets/images/logo.png',
      faviconAsset: 'favicon.png',
      privacyPolicyUrl: 'https://$domain/privacy',
      termsOfServiceUrl: 'https://$domain/terms',
      documentationUrl: 'https://$domain/docs',
      copyrightText: '© ${DateTime.now().year} $cName. All rights reserved.',
    );
  }
}
