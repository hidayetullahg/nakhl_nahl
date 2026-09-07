// ==============================================================================
// NAKHL & NAHL — PRODUCT LEGAL PROFILE MODEL
// Master Directive: Product-Centric Legislation & Legal Decision Tree
// ==============================================================================

class ProductLegalProfileModel {
  final String productName;
  final String hsCode; // e.g. '080410' for Hurma (Taze/Kuru)
  final String sourceCountry; // 'SA', 'TR', etc.
  final String destinationCountry; // 'DE', 'SA', 'TR', etc.
  final List<String> transitCountries;
  final bool isFood;
  final bool isAnimalOrigin;
  final bool isPlantOrigin;
  final bool isProcessed;
  final bool isFresh;
  final bool isFrozen;
  final bool isOrganic;
  final bool isHalalCertified;
  final String packagingType; // 'RETAIL_BOX', 'BULK_CARTON', 'VACUUM_PACK', 'PLASTIC_CONTAINER'
  final double quantityKg;
  final bool isCommercial;
  final String exporterEntityName;
  final String importerEntityName;

  const ProductLegalProfileModel({
    required this.productName,
    required this.hsCode,
    required this.sourceCountry,
    required this.destinationCountry,
    this.transitCountries = const [],
    this.isFood = true,
    this.isAnimalOrigin = false,
    this.isPlantOrigin = true,
    this.isProcessed = true,
    this.isFresh = false,
    this.isFrozen = false,
    this.isOrganic = false,
    this.isHalalCertified = true,
    this.packagingType = 'RETAIL_BOX',
    required this.quantityKg,
    this.isCommercial = true,
    this.exporterEntityName = 'NAKHL & NAHL Trading Co.',
    this.importerEntityName = 'Import Partner GmbH',
  });

  /// Standard preset for Saudi Medjool Dates export to Germany
  factory ProductLegalProfileModel.saudiMedjoolDatesToGermany({
    double quantityKg = 5000.0,
    bool isOrganic = false,
  }) {
    return ProductLegalProfileModel(
      productName: 'Suudi Medjool Hurma (Kuru)',
      hsCode: '080410',
      sourceCountry: 'SA',
      destinationCountry: 'DE',
      transitCountries: const ['EU'],
      isFood: true,
      isAnimalOrigin: false,
      isPlantOrigin: true,
      isProcessed: true,
      isFresh: false,
      isFrozen: false,
      isOrganic: isOrganic,
      isHalalCertified: true,
      packagingType: 'RETAIL_BOX',
      quantityKg: quantityKg,
      isCommercial: true,
      exporterEntityName: 'NAKHL & NAHL Dates Estate (Riyadh)',
      importerEntityName: 'Al-Barakah Feinkost Import GmbH (Frankfurt)',
    );
  }

  /// Standard preset for Turkey Food/Dates export to Germany
  factory ProductLegalProfileModel.turkeyFoodToGermany({
    double quantityKg = 3000.0,
    bool isOrganic = false,
  }) {
    return ProductLegalProfileModel(
      productName: 'Türk Paketli Kuru Gıda & Hurma Ezmesi',
      hsCode: '200899',
      sourceCountry: 'TR',
      destinationCountry: 'DE',
      transitCountries: const ['EU'],
      isFood: true,
      isAnimalOrigin: false,
      isPlantOrigin: true,
      isProcessed: true,
      isFresh: false,
      isFrozen: false,
      isOrganic: isOrganic,
      isHalalCertified: true,
      packagingType: 'RETAIL_BOX',
      quantityKg: quantityKg,
      isCommercial: true,
      exporterEntityName: 'NAKHL & NAHL Gıda Dış Tic. A.Ş. (İstanbul)',
      importerEntityName: 'Euro-Orient Import GmbH (Berlin)',
    );
  }
}
