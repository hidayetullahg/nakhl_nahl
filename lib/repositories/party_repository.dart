import '../services/supabase_service.dart';
import '../core/tenant/tenant_context.dart';

enum PartyRoleType {
  customer('CUSTOMER', 'Müşteri'),
  supplier('SUPPLIER', 'Tedarikçi'),
  employee('EMPLOYEE', 'Personel'),
  carrier('CARRIER', 'Taşıyıcı / Lojistik Firma'),
  broker('BROKER', 'Komisyoncu / Broker'),
  customsAgent('CUSTOMS_AGENT', 'Gümrük Müşaviri'),
  bank('BANK', 'Banka / Finans Kuruluşu'),
  other('OTHER', 'Diğer İş Ortağı');

  final String code;
  final String label;
  const PartyRoleType(this.code, this.label);

  static PartyRoleType fromCode(String code) {
    for (final r in values) {
      if (r.code.equalsIgnoreCase(code)) return r;
    }
    return PartyRoleType.other;
  }
}

extension StringExtension on String {
  bool equalsIgnoreCase(String other) => toLowerCase() == other.toLowerCase();
}

class PartyAddress {
  final String id;
  final String partyId;
  final String addressType; // BILLING, SHIPPING, LEGAL, WAREHOUSE, CONTACT
  final String? title;
  final String addressLine1;
  final String? addressLine2;
  final String? city;
  final String? district;
  final String? postalCode;
  final String countryCode;
  final bool isDefault;

  const PartyAddress({
    required this.id,
    required this.partyId,
    required this.addressType,
    this.title,
    required this.addressLine1,
    this.addressLine2,
    this.city,
    this.district,
    this.postalCode,
    required this.countryCode,
    required this.isDefault,
  });

  factory PartyAddress.fromMap(Map<String, dynamic> map) {
    return PartyAddress(
      id: map['id'] ?? '',
      partyId: map['party_id'] ?? '',
      addressType: map['address_type'] ?? 'BILLING',
      title: map['title'],
      addressLine1: map['address_line1'] ?? '',
      addressLine2: map['address_line2'],
      city: map['city'],
      district: map['district'],
      postalCode: map['postal_code'],
      countryCode: map['country_code'] ?? 'SA',
      isDefault: map['is_default'] ?? false,
    );
  }
}

class PartyContact {
  final String id;
  final String partyId;
  final String name;
  final String? title;
  final String? department;
  final String? email;
  final String? phone;
  final String? mobile;
  final String? preferredLanguageCode;
  final bool isPrimary;

  const PartyContact({
    required this.id,
    required this.partyId,
    required this.name,
    this.title,
    this.department,
    this.email,
    this.phone,
    this.mobile,
    this.preferredLanguageCode,
    required this.isPrimary,
  });

  factory PartyContact.fromMap(Map<String, dynamic> map) {
    return PartyContact(
      id: map['id'] ?? '',
      partyId: map['party_id'] ?? '',
      name: map['name'] ?? '',
      title: map['title'],
      department: map['department'],
      email: map['email'],
      phone: map['phone'],
      mobile: map['mobile'],
      preferredLanguageCode: map['preferred_language_code'],
      isPrimary: map['is_primary'] ?? false,
    );
  }
}

class CommercialAccount {
  final String id;
  final String companyId;
  final String partyId;
  final String accountCode;
  final String currencyCode;
  final int paymentTermsDays;
  final double creditLimit;
  final String riskControlType;
  final String? taxProfileId;
  final String accountStatus;

  const CommercialAccount({
    required this.id,
    required this.companyId,
    required this.partyId,
    required this.accountCode,
    required this.currencyCode,
    required this.paymentTermsDays,
    required this.creditLimit,
    required this.riskControlType,
    this.taxProfileId,
    required this.accountStatus,
  });

  factory CommercialAccount.fromMap(Map<String, dynamic> map) {
    return CommercialAccount(
      id: map['id'] ?? '',
      companyId: map['company_id'] ?? '',
      partyId: map['party_id'] ?? '',
      accountCode: map['account_code'] ?? '',
      currencyCode: map['currency_code'] ?? 'SAR',
      paymentTermsDays: map['payment_terms_days'] ?? 30,
      creditLimit: (map['credit_limit'] as num?)?.toDouble() ?? 0.0,
      riskControlType: map['risk_control_type'] ?? 'WARNING',
      taxProfileId: map['tax_profile_id'],
      accountStatus: map['account_status'] ?? 'ACTIVE',
    );
  }
}

class Party {
  final String id;
  final String tenantId;
  final String partyType; // PERSON, ORGANIZATION
  final String legalName;
  final String? tradeName;
  final String? taxNumber;
  final String? countryCode;
  final String? email;
  final String? phone;
  final String? website;
  final bool isActive;
  final List<String> roles;
  final List<PartyAddress> addresses;
  final List<PartyContact> contacts;

  const Party({
    required this.id,
    required this.tenantId,
    required this.partyType,
    required this.legalName,
    this.tradeName,
    this.taxNumber,
    this.countryCode,
    this.email,
    this.phone,
    this.website,
    required this.isActive,
    this.roles = const [],
    this.addresses = const [],
    this.contacts = const [],
  });

  factory Party.fromMap(
    Map<String, dynamic> map, [
    List<String> roles = const [],
    List<PartyAddress> addresses = const [],
    List<PartyContact> contacts = const [],
  ]) {
    return Party(
      id: map['id'] ?? '',
      tenantId: map['tenant_id'] ?? '',
      partyType: map['party_type'] ?? 'ORGANIZATION',
      legalName: map['legal_name'] ?? '',
      tradeName: map['trade_name'],
      taxNumber: map['tax_number'],
      countryCode: map['country_code'] ?? 'SA',
      email: map['email'],
      phone: map['phone'],
      website: map['website'],
      isActive: map['is_active'] ?? true,
      roles: roles,
      addresses: addresses,
      contacts: contacts,
    );
  }
}

class PartyRepository {
  PartyRepository._();
  static final PartyRepository instance = PartyRepository._();

  /// Aktif kiracıya ait partileri listeler
  Future<List<Party>> getParties(
      {String? roleType, bool onlyActive = true}) async {
    try {
      final tenantId = TenantContext.instance.activeTenantId;
      if (tenantId == null) return [];

      var query = SupabaseService.client
          .from('parties')
          .select(
              '*, party_roles(role_type), party_addresses(*), party_contacts(*)')
          .eq('tenant_id', tenantId);

      if (onlyActive) {
        query = query.eq('is_active', true);
      }

      final response = await query.order('legal_name', ascending: true);
      final List<Party> parties = [];

      for (final row in (response as List<dynamic>)) {
        final map = row as Map<String, dynamic>;
        final roleRows = (map['party_roles'] as List<dynamic>?) ?? [];
        final roles =
            roleRows.map((r) => r['role_type']?.toString() ?? '').toList();

        if (roleType != null && roleType.isNotEmpty) {
          if (!roles.contains(roleType.toUpperCase())) continue;
        }

        final addrRows = (map['party_addresses'] as List<dynamic>?) ?? [];
        final addresses = addrRows
            .map((a) => PartyAddress.fromMap(a as Map<String, dynamic>))
            .toList();

        final contactRows = (map['party_contacts'] as List<dynamic>?) ?? [];
        final contacts = contactRows
            .map((c) => PartyContact.fromMap(c as Map<String, dynamic>))
            .toList();

        parties.add(Party.fromMap(map, roles, addresses, contacts));
      }

      return parties;
    } catch (_) {
      return [];
    }
  }

  /// Vergi numarası veya ticaret unvanı ile parti var mı kontrol eder (Deduplication)
  Future<Party?> findExistingParty(
      {String? taxNumber, required String legalName}) async {
    try {
      final tenantId = TenantContext.instance.activeTenantId;
      if (tenantId == null) return null;

      if (taxNumber != null && taxNumber.trim().isNotEmpty) {
        final byTax = await SupabaseService.client
            .from('parties')
            .select()
            .eq('tenant_id', tenantId)
            .eq('tax_number', taxNumber.trim())
            .maybeSingle();
        if (byTax != null) return Party.fromMap(byTax);
      }

      final byName = await SupabaseService.client
          .from('parties')
          .select()
          .eq('tenant_id', tenantId)
          .ilike('legal_name', legalName.trim())
          .maybeSingle();

      if (byName != null) return Party.fromMap(byName);

      return null;
    } catch (_) {
      return null;
    }
  }

  /// Yeni parti oluşturur ve rolleri tanımlar (Mükerrerlik engeli)
  Future<Party?> createParty({
    required String legalName,
    String? tradeName,
    String? taxNumber,
    String partyType = 'ORGANIZATION',
    String countryCode = 'SA',
    String? email,
    String? phone,
    String? website,
    required List<PartyRoleType> initialRoles,
  }) async {
    try {
      final tenantId = TenantContext.instance.activeTenantId;
      if (tenantId == null) throw Exception('Aktif tenant seçilmedi.');

      // 1. Mükerrer kontrolü
      final existing =
          await findExistingParty(taxNumber: taxNumber, legalName: legalName);
      if (existing != null) {
        for (final r in initialRoles) {
          await addRoleToParty(existing.id, r);
        }
        return existing;
      }

      // 2. Yeni parti oluştur
      final partyRes = await SupabaseService.client
          .from('parties')
          .insert({
            'tenant_id': tenantId,
            'party_type': partyType,
            'legal_name': legalName.trim(),
            'trade_name': tradeName?.trim(),
            'tax_number': taxNumber?.trim(),
            'country_code': countryCode,
            'email': email?.trim(),
            'phone': phone?.trim(),
            'website': website?.trim(),
          })
          .select()
          .single();

      final partyId = partyRes['id'] as String;

      // 3. Rolleri ata
      final roleStrings = <String>[];
      for (final r in initialRoles) {
        await SupabaseService.client.from('party_roles').insert({
          'tenant_id': tenantId,
          'party_id': partyId,
          'role_type': r.code,
        });
        roleStrings.add(r.code);
      }

      return Party.fromMap(partyRes, roleStrings);
    } catch (_) {
      return null;
    }
  }

  /// Partiye adres ekler
  Future<PartyAddress?> addAddress({
    required String partyId,
    String addressType = 'BILLING',
    String? title,
    required String addressLine1,
    String? addressLine2,
    String? city,
    String? district,
    String? postalCode,
    String countryCode = 'SA',
    bool isDefault = false,
  }) async {
    try {
      final tenantId = TenantContext.instance.activeTenantId;
      if (tenantId == null) return null;

      final res = await SupabaseService.client
          .from('party_addresses')
          .insert({
            'tenant_id': tenantId,
            'party_id': partyId,
            'address_type': addressType,
            'title': title,
            'address_line1': addressLine1.trim(),
            'address_line2': addressLine2?.trim(),
            'city': city?.trim(),
            'district': district?.trim(),
            'postal_code': postalCode?.trim(),
            'country_code': countryCode,
            'is_default': isDefault,
          })
          .select()
          .single();

      return PartyAddress.fromMap(res);
    } catch (_) {
      return null;
    }
  }

  /// Partiye yetkili kişi ekler
  Future<PartyContact?> addContact({
    required String partyId,
    required String name,
    String? title,
    String? department,
    String? email,
    String? phone,
    String? mobile,
    String? preferredLanguageCode,
    bool isPrimary = false,
  }) async {
    try {
      final tenantId = TenantContext.instance.activeTenantId;
      if (tenantId == null) return null;

      final res = await SupabaseService.client
          .from('party_contacts')
          .insert({
            'tenant_id': tenantId,
            'party_id': partyId,
            'name': name.trim(),
            'title': title?.trim(),
            'department': department?.trim(),
            'email': email?.trim(),
            'phone': phone?.trim(),
            'mobile': mobile?.trim(),
            'preferred_language_code': preferredLanguageCode,
            'is_primary': isPrimary,
          })
          .select()
          .single();

      return PartyContact.fromMap(res);
    } catch (_) {
      return null;
    }
  }

  /// Şirkete bağlı ticari cari hesap getirir
  Future<CommercialAccount?> getCommercialAccount({
    required String companyId,
    required String partyId,
    String currencyCode = 'SAR',
  }) async {
    try {
      final res = await SupabaseService.client
          .from('commercial_accounts')
          .select()
          .eq('company_id', companyId)
          .eq('party_id', partyId)
          .eq('currency_code', currencyCode)
          .maybeSingle();

      if (res != null) {
        return CommercialAccount.fromMap(res);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Partiye yeni bir ticari rol ekler
  Future<void> addRoleToParty(String partyId, PartyRoleType role) async {
    try {
      final tenantId = TenantContext.instance.activeTenantId;
      if (tenantId == null) return;

      await SupabaseService.client.from('party_roles').upsert({
        'tenant_id': tenantId,
        'party_id': partyId,
        'role_type': role.code,
      });
    } catch (_) {}
  }
}
