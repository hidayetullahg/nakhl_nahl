import '../services/supabase_service.dart';
import '../core/tenant/tenant_context.dart';

class ItemLot {
  final String id;
  final String tenantId;
  final String companyId;
  final String itemId;
  final String lotNumber;
  final DateTime? productionDate;
  final DateTime? expirationDate;
  final String? supplierPartyId;
  final String? sourceDocumentType;
  final String? sourceDocumentRef;
  final String countryOfOrigin;
  final double initialQuantity;
  final String? uom;
  final String qualityStatus; // APPROVED, QUARANTINE, REJECTED, HOLD
  final bool halalCertified;
  final String? halalCertificateNumber;
  final String? notes;

  const ItemLot({
    required this.id,
    required this.tenantId,
    required this.companyId,
    required this.itemId,
    required this.lotNumber,
    this.productionDate,
    this.expirationDate,
    this.supplierPartyId,
    this.sourceDocumentType,
    this.sourceDocumentRef,
    required this.countryOfOrigin,
    required this.initialQuantity,
    this.uom,
    required this.qualityStatus,
    required this.halalCertified,
    this.halalCertificateNumber,
    this.notes,
  });

  factory ItemLot.fromMap(Map<String, dynamic> map) {
    return ItemLot(
      id: map['id'] ?? '',
      tenantId: map['tenant_id'] ?? '',
      companyId: map['company_id'] ?? '',
      itemId: map['item_id'] ?? '',
      lotNumber: map['lot_number'] ?? '',
      productionDate: map['production_date'] != null
          ? DateTime.tryParse(map['production_date'].toString())
          : null,
      expirationDate: map['expiration_date'] != null
          ? DateTime.tryParse(map['expiration_date'].toString())
          : null,
      supplierPartyId: map['supplier_party_id'],
      sourceDocumentType: map['source_document_type'],
      sourceDocumentRef: map['source_document_ref'],
      countryOfOrigin: map['country_of_origin'] ?? 'SA',
      initialQuantity: (map['initial_quantity'] as num?)?.toDouble() ?? 0.0,
      uom: map['uom'] ?? 'KG',
      qualityStatus: map['quality_status'] ?? 'APPROVED',
      halalCertified: map['halal_certified'] ?? true,
      halalCertificateNumber: map['halal_certificate_number'],
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tenant_id': tenantId,
      'company_id': companyId,
      'item_id': itemId,
      'lot_number': lotNumber,
      'production_date': productionDate?.toIso8601String().split('T').first,
      'expiration_date': expirationDate?.toIso8601String().split('T').first,
      'supplier_party_id': supplierPartyId,
      'source_document_type': sourceDocumentType,
      'source_document_ref': sourceDocumentRef,
      'country_of_origin': countryOfOrigin,
      'initial_quantity': initialQuantity,
      'uom': uom,
      'quality_status': qualityStatus,
      'halal_certified': halalCertified,
      'halal_certificate_number': halalCertificateNumber,
      'notes': notes,
    };
  }
}

class LotRepository {
  LotRepository._();
  static final LotRepository instance = LotRepository._();

  /// Belirli bir ürüne veya şirkete ait partileri listeler
  Future<List<ItemLot>> getLots(
      {required String companyId, String? itemId}) async {
    try {
      var query = SupabaseService.client
          .from('item_lots')
          .select()
          .eq('company_id', companyId);

      if (itemId != null && itemId.isNotEmpty) {
        query = query.eq('item_id', itemId);
      }

      final response = await query.order('created_at', ascending: false);
      return (response as List<dynamic>)
          .map((m) => ItemLot.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Yeni parti / lot kaydı açar
  Future<ItemLot?> createLot({
    required String companyId,
    required String itemId,
    required String lotNumber,
    DateTime? productionDate,
    DateTime? expirationDate,
    String? supplierPartyId,
    String? sourceDocumentType,
    String? sourceDocumentRef,
    String countryOfOrigin = 'SA',
    double initialQuantity = 0.0,
    String uom = 'KG',
    String qualityStatus = 'APPROVED',
    bool halalCertified = true,
    String? halalCertificateNumber,
    String? notes,
  }) async {
    try {
      final tenantId = TenantContext.instance.activeTenantId;
      if (tenantId == null) throw Exception('Aktif tenant seçilmedi.');

      final response = await SupabaseService.client
          .from('item_lots')
          .insert({
            'tenant_id': tenantId,
            'company_id': companyId,
            'item_id': itemId,
            'lot_number': lotNumber.trim(),
            'production_date':
                productionDate?.toIso8601String().split('T').first,
            'expiration_date':
                expirationDate?.toIso8601String().split('T').first,
            'supplier_party_id': supplierPartyId,
            'source_document_type': sourceDocumentType,
            'source_document_ref': sourceDocumentRef,
            'country_of_origin': countryOfOrigin,
            'initial_quantity': initialQuantity,
            'uom': uom,
            'quality_status': qualityStatus,
            'halal_certified': halalCertified,
            'halal_certificate_number': halalCertificateNumber,
            'notes': notes?.trim(),
          })
          .select()
          .single();

      return ItemLot.fromMap(response);
    } catch (_) {
      return null;
    }
  }
}
