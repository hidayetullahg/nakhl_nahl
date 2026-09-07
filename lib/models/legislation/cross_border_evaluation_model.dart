// ==============================================================================
// NAKHL & NAHL — CROSS BORDER EVALUATION RESULT MODEL
// Master Directive: Cross-Border Applicability Engine & Jurisdiction Isolation
// ==============================================================================

class LegalObligationItem {
  final String code;
  final String title;
  final String description;
  final String jurisdictionCode; // 'SA', 'TR', 'EU', 'DE'
  final String authority; // 'ZATCA', 'SFDA', 'GIB', 'DG SANTE', 'BVL'
  final String officialCitation; // Law/Reg article
  final String responsibleParty; // 'EXPORTER', 'IMPORTER', 'CARRIER'
  final bool isMandatory;

  const LegalObligationItem({
    required this.code,
    required this.title,
    required this.description,
    required this.jurisdictionCode,
    required this.authority,
    required this.officialCitation,
    required this.responsibleParty,
    this.isMandatory = true,
  });
}

class RequiredDocumentItem {
  final String documentName;
  final String issuingAuthority;
  final String jurisdictionCode;
  final String purpose;
  final bool isMandatory;
  final String? digitalSystem; // 'FASAH', 'TRACES NT', 'GİB'

  const RequiredDocumentItem({
    required this.documentName,
    required this.issuingAuthority,
    required this.jurisdictionCode,
    required this.purpose,
    this.isMandatory = true,
    this.digitalSystem,
  });
}

class CrossBorderEvaluationResult {
  final String sourceCountry;
  final String destinationCountry;
  final String productName;
  final String hsCode;
  final DateTime evaluatedAt;

  // 1. Isolated Jurisdiction Frameworks
  final List<LegalObligationItem> sourceExportObligations;
  final List<LegalObligationItem> supranationalObligations; // EU Food Import / Customs
  final List<LegalObligationItem> destinationNationalObligations; // Germany National

  // 2. Clear Operational Summaries
  final List<RequiredDocumentItem> requiredDocuments;
  final List<String> requiredCertificates;
  final bool isTracesNtRequired;
  final String tracesNtType; // 'CHED-D' (hayvansal olmayan) or 'CHED-P' (hayvansal)
  final bool isBorderControlPostRequired; // Sınır kontrol noktası
  final bool isLabAnalysisRequired; // Aflatoksin / pestisit kalıntı testi
  final List<String> mandatoryLabelingElements;
  final List<String> packagingAndRecyclingObligations; // e.g. LUCID VerpackG

  // 3. Tariffs & Taxes
  final double customsDutyRate;
  final String customsTariffCitation;
  final double importVatRate;
  final bool isReverseChargeApplicable;

  // 4. Deadlines, Risk & Disclaimer
  final List<String> criticalDeadlines;
  final String riskLevel; // 'LOW' (Green), 'MEDIUM' (Yellow), 'HIGH' (Red)
  final List<String> riskAlerts;
  final String legalDisclaimer;
  final bool isShelfEmpty; // True if destination country pack is NOT_LOADED

  const CrossBorderEvaluationResult({
    required this.sourceCountry,
    required this.destinationCountry,
    required this.productName,
    required this.hsCode,
    required this.evaluatedAt,
    required this.sourceExportObligations,
    required this.supranationalObligations,
    required this.destinationNationalObligations,
    required this.requiredDocuments,
    required this.requiredCertificates,
    required this.isTracesNtRequired,
    required this.tracesNtType,
    required this.isBorderControlPostRequired,
    required this.isLabAnalysisRequired,
    required this.mandatoryLabelingElements,
    required this.packagingAndRecyclingObligations,
    required this.customsDutyRate,
    required this.customsTariffCitation,
    required this.importVatRate,
    required this.isReverseChargeApplicable,
    required this.criticalDeadlines,
    required this.riskLevel,
    required this.riskAlerts,
    required this.legalDisclaimer,
    this.isShelfEmpty = false,
  });
}
