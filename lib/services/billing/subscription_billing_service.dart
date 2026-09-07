// ==============================================================================
// NAKHL & NAHL — SUBSCRIPTION & BILLING SERVICE
// File: lib/services/billing/subscription_billing_service.dart
// Lifecycle: TRIAL -> ACTIVE -> GRACE (7 days) -> EXPIRED (Read-only)
// Payment: Credit Card (Instant) & Bank Wire / Dekont (Admin Verification)
// ==============================================================================

import 'package:flutter/foundation.dart';
import '../supabase_service.dart';
import '../../core/tenant/tenant_context.dart';

/// Abonelik Durumları
enum SubscriptionStatus {
  trial('TRIAL', 'Deneme Sürümü'),
  active('ACTIVE', 'Aktif Lisans'),
  grace('GRACE', 'Ek Süre (Grace Period)'),
  expired('EXPIRED', 'Süresi Dolmuş (Salt Okunur)'),
  suspended('SUSPENDED', 'Askıya Alınmış'),
  cancelled('CANCELLED', 'İptal Edilmiş');

  final String code;
  final String label;
  const SubscriptionStatus(this.code, this.label);

  static SubscriptionStatus fromCode(String code) {
    return SubscriptionStatus.values.firstWhere(
      (s) => s.code.toUpperCase() == code.toUpperCase(),
      orElse: () => SubscriptionStatus.expired,
    );
  }
}

/// Ödeme Yöntemi
enum PaymentMethod {
  creditCard('CREDIT_CARD', 'Kredi / Banka Kartı'),
  bankWire('BANK_WIRE', 'Banka Havalesi / EFT / Dekont'),
  adminManual('ADMIN_MANUAL', 'Yönetici Manuel Aktivasyon');

  final String code;
  final String label;
  const PaymentMethod(this.code, this.label);

  static PaymentMethod fromCode(String code) {
    return PaymentMethod.values.firstWhere(
      (m) => m.code.toUpperCase() == code.toUpperCase(),
      orElse: () => PaymentMethod.bankWire,
    );
  }
}

/// Ödeme Durumu
enum PaymentStatus {
  pending('PENDING', 'Onay Bekliyor'),
  paid('PAID', 'Ödendi / Aktif'),
  rejected('REJECTED', 'Reddedildi'),
  refunded('REFUNDED', 'İade Edildi');

  final String code;
  final String label;
  const PaymentStatus(this.code, this.label);

  static PaymentStatus fromCode(String code) {
    return PaymentStatus.values.firstWhere(
      (s) => s.code.toUpperCase() == code.toUpperCase(),
      orElse: () => PaymentStatus.pending,
    );
  }
}

/// Kiracı Modül Abonelik Modeli
class TenantSubscription {
  final String id;
  final String tenantId;
  final String moduleCode;
  final SubscriptionStatus status;
  final String billingCycle;
  final DateTime? trialExpiresAt;
  final DateTime activatedAt;
  final DateTime expiresAt;
  final DateTime gracePeriodUntil;
  final bool autoRenew;

  const TenantSubscription({
    required this.id,
    required this.tenantId,
    required this.moduleCode,
    required this.status,
    required this.billingCycle,
    this.trialExpiresAt,
    required this.activatedAt,
    required this.expiresAt,
    required this.gracePeriodUntil,
    this.autoRenew = true,
  });

  factory TenantSubscription.fromMap(Map<String, dynamic> map) {
    return TenantSubscription(
      id: map['id']?.toString() ?? '',
      tenantId: map['tenant_id']?.toString() ?? '',
      moduleCode: map['module_code']?.toString() ?? '',
      status:
          SubscriptionStatus.fromCode(map['status']?.toString() ?? 'EXPIRED'),
      billingCycle: map['billing_cycle']?.toString() ?? 'MONTHLY',
      trialExpiresAt: map['trial_expires_at'] != null
          ? DateTime.tryParse(map['trial_expires_at'].toString())
          : null,
      activatedAt: DateTime.tryParse(map['activated_at']?.toString() ?? '') ??
          DateTime.now(),
      expiresAt: DateTime.tryParse(map['expires_at']?.toString() ?? '') ??
          DateTime.now().add(const Duration(days: 30)),
      gracePeriodUntil:
          DateTime.tryParse(map['grace_period_until']?.toString() ?? '') ??
              DateTime.now().add(const Duration(days: 37)),
      autoRenew: map['auto_renew'] != false,
    );
  }

  bool get isUsable {
    final now = DateTime.now();
    if (status == SubscriptionStatus.active ||
        status == SubscriptionStatus.trial) {
      return now.isBefore(expiresAt);
    }
    if (status == SubscriptionStatus.grace) {
      return now.isBefore(gracePeriodUntil);
    }
    return false;
  }

  int get remainingDays {
    final now = DateTime.now();
    final target =
        status == SubscriptionStatus.grace ? gracePeriodUntil : expiresAt;
    return target.difference(now).inDays;
  }
}

/// Ödeme Sipariş Modeli
class CommercialPaymentOrder {
  final String id;
  final String tenantId;
  final String orderNumber;
  final PaymentMethod paymentMethod;
  final String currency;
  final double totalAmount;
  final PaymentStatus paymentStatus;
  final String? bankAccountTitle;
  final String? bankIban;
  final String? bankTransferReference;
  final String? receiptDocumentUrl;
  final String? notes;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final DateTime createdAt;

  const CommercialPaymentOrder({
    required this.id,
    required this.tenantId,
    required this.orderNumber,
    required this.paymentMethod,
    required this.currency,
    required this.totalAmount,
    required this.paymentStatus,
    this.bankAccountTitle,
    this.bankIban,
    this.bankTransferReference,
    this.receiptDocumentUrl,
    this.notes,
    this.verifiedBy,
    this.verifiedAt,
    required this.createdAt,
  });

  factory CommercialPaymentOrder.fromMap(Map<String, dynamic> map) {
    return CommercialPaymentOrder(
      id: map['id']?.toString() ?? '',
      tenantId: map['tenant_id']?.toString() ?? '',
      orderNumber: map['order_number']?.toString() ?? '',
      paymentMethod:
          PaymentMethod.fromCode(map['payment_method']?.toString() ?? ''),
      currency: map['currency']?.toString() ?? 'SAR',
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0.0,
      paymentStatus:
          PaymentStatus.fromCode(map['payment_status']?.toString() ?? ''),
      bankAccountTitle: map['bank_account_title']?.toString(),
      bankIban: map['bank_iban']?.toString(),
      bankTransferReference: map['bank_transfer_reference']?.toString(),
      receiptDocumentUrl: map['receipt_document_url']?.toString(),
      notes: map['notes']?.toString(),
      verifiedBy: map['verified_by']?.toString(),
      verifiedAt: map['verified_at'] != null
          ? DateTime.tryParse(map['verified_at'].toString())
          : null,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

/// Abonelik ve Faturalama Servisi
class SubscriptionBillingService {
  SubscriptionBillingService._();
  static final SubscriptionBillingService instance =
      SubscriptionBillingService._();

  final Map<String, TenantSubscription> _localCache = {};

  /// Kiracının Modüle Aktif Erişimi Var mı?
  Future<bool> hasActiveModule(String moduleCode, {String? tenantId}) async {
    // MOD_CORE her zaman ücretsiz ve aktiftir
    if (moduleCode == 'MOD_CORE') return true;

    final tid = tenantId ?? TenantContext.instance.activeTenantId;
    if (tid == null) return false;

    // Önce yerel önbelleğe bak
    final cacheKey = '$tid:$moduleCode';
    if (_localCache.containsKey(cacheKey)) {
      return _localCache[cacheKey]!.isUsable;
    }

    try {
      final client = SupabaseService.client;
      // PostgreSQL has_active_module RPC çağrısı
      final response = await client.rpc('has_active_module', params: {
        'p_tenant_id': tid,
        'p_module_code': moduleCode,
      });

      if (response is bool) {
        return response;
      }

      // RPC bulunamazsa tabloyu sorgula
      final rows = await client
          .from('commercial_tenant_subscriptions')
          .select()
          .eq('tenant_id', tid)
          .eq('module_code', moduleCode)
          .limit(1);

      if ((rows as List).isEmpty) return false;

      final sub = TenantSubscription.fromMap(rows.first);
      _localCache[cacheKey] = sub;
      return sub.isUsable;
    } catch (e) {
      debugPrint('hasActiveModule check error ($moduleCode): $e');
      // Geliştirme veya çevrimdışı modda tenant varsa izin ver
      return false;
    }
  }

  /// Kiracının Tüm Aboneliklerini Getir
  Future<List<TenantSubscription>> getSubscriptions({String? tenantId}) async {
    final tid = tenantId ?? TenantContext.instance.activeTenantId;
    if (tid == null) return [];

    try {
      final client = SupabaseService.client;
      final rows = await client
          .from('commercial_tenant_subscriptions')
          .select()
          .eq('tenant_id', tid);

      final list = (rows as List)
          .map((r) => TenantSubscription.fromMap(r as Map<String, dynamic>))
          .toList();

      for (final sub in list) {
        _localCache['$tid:${sub.moduleCode}'] = sub;
      }

      return list;
    } catch (e) {
      debugPrint('getSubscriptions error: $e');
      return [];
    }
  }

  /// 14 Günlük Ücretsiz Deneme Başlat
  Future<bool> startTrial(String moduleCode, {String? tenantId}) async {
    final tid = tenantId ?? TenantContext.instance.activeTenantId;
    if (tid == null) return false;

    final now = DateTime.now();
    final expires = now.add(const Duration(days: 14));
    final grace = expires.add(const Duration(days: 7));

    try {
      final client = SupabaseService.client;
      await client.from('commercial_tenant_subscriptions').upsert({
        'tenant_id': tid,
        'module_code': moduleCode,
        'status': 'TRIAL',
        'billing_cycle': 'MONTHLY',
        'trial_started_at': now.toIso8601String(),
        'trial_expires_at': expires.toIso8601String(),
        'purchased_at': now.toIso8601String(),
        'activated_at': now.toIso8601String(),
        'expires_at': expires.toIso8601String(),
        'grace_period_until': grace.toIso8601String(),
        'auto_renew': false,
      });

      _localCache.remove('$tid:$moduleCode');
      return true;
    } catch (e) {
      debugPrint('startTrial error: $e');
      return false;
    }
  }

  /// Ödeme Siparişi Oluştur
  Future<CommercialPaymentOrder?> createPaymentOrder({
    required List<String> moduleCodes,
    required PaymentMethod method,
    required String currency,
    required double totalAmount,
    String billingCycle = 'YEARLY',
    String? bankAccountTitle,
    String? bankIban,
    String? referenceCode,
    String? receiptUrl,
    String? tenantId,
  }) async {
    final tid = tenantId ?? TenantContext.instance.activeTenantId;
    if (tid == null) return null;

    final orderNo =
        'ORD-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final isCreditCard = method == PaymentMethod.creditCard;
    final initialStatus = isCreditCard ? 'PAID' : 'PENDING';

    try {
      final client = SupabaseService.client;
      final orderInsert = await client
          .from('commercial_payment_orders')
          .insert({
            'tenant_id': tid,
            'order_number': orderNo,
            'payment_method': method.code,
            'currency': currency.toUpperCase(),
            'total_amount': totalAmount,
            'payment_status': initialStatus,
            'bank_account_title': bankAccountTitle,
            'bank_iban': bankIban,
            'bank_transfer_reference': referenceCode,
            'receipt_document_url': receiptUrl,
            'notes': 'Satın alınan modüller: ${moduleCodes.join(', ')}',
          })
          .select()
          .single();

      final order = CommercialPaymentOrder.fromMap(orderInsert);

      // Kredi kartı ile anında ödendiyse modülleri derhal aktif et
      if (isCreditCard) {
        final now = DateTime.now();
        final durationDays = billingCycle == 'YEARLY' ? 365 : 30;
        final expires = now.add(Duration(days: durationDays));
        final grace = expires.add(const Duration(days: 7));

        for (final mCode in moduleCodes) {
          await client.from('commercial_tenant_subscriptions').upsert({
            'tenant_id': tid,
            'module_code': mCode,
            'status': 'ACTIVE',
            'billing_cycle': billingCycle.toUpperCase(),
            'purchased_at': now.toIso8601String(),
            'activated_at': now.toIso8601String(),
            'expires_at': expires.toIso8601String(),
            'grace_period_until': grace.toIso8601String(),
            'auto_renew': true,
          });
          _localCache.remove('$tid:$mCode');
        }
      }

      return order;
    } catch (e) {
      debugPrint('createPaymentOrder error: $e');
      return null;
    }
  }

  /// Platform Yöneticisi: Banka Havalesi / Dekont Onayı
  Future<bool> approvePaymentOrder({
    required String orderId,
    required String verifierUserId,
    String billingCycle = 'YEARLY',
  }) async {
    try {
      final client = SupabaseService.client;

      // Siparişi getir
      final orderRow = await client
          .from('commercial_payment_orders')
          .select()
          .eq('id', orderId)
          .single();

      final order = CommercialPaymentOrder.fromMap(orderRow);
      final tid = order.tenantId;

      // Siparişi PAID olarak işaretle
      await client.from('commercial_payment_orders').update({
        'payment_status': 'PAID',
        'verified_by': verifierUserId,
        'verified_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      // Sipariş notlarındaki modül kodlarını ayrıştır veya sipariş kalemlerinden al
      final notes = order.notes ?? '';
      final now = DateTime.now();
      final durationDays = billingCycle == 'YEARLY' ? 365 : 30;
      final expires = now.add(Duration(days: durationDays));
      final grace = expires.add(const Duration(days: 7));

      // Modül listesini bul
      final moduleMatches = RegExp(r'MOD_[A-Z_]+').allMatches(notes);
      final List<String> modulesToActivate =
          moduleMatches.map((m) => m.group(0)!).toSet().toList();

      if (modulesToActivate.isEmpty) {
        // En azından temel modülü etkinleştir
        modulesToActivate.add('MOD_ACCOUNTING');
      }

      for (final mCode in modulesToActivate) {
        await client.from('commercial_tenant_subscriptions').upsert({
          'tenant_id': tid,
          'module_code': mCode,
          'status': 'ACTIVE',
          'billing_cycle': billingCycle.toUpperCase(),
          'purchased_at': now.toIso8601String(),
          'activated_at': now.toIso8601String(),
          'expires_at': expires.toIso8601String(),
          'grace_period_until': grace.toIso8601String(),
          'auto_renew': true,
        });
        _localCache.remove('$tid:$mCode');
      }

      return true;
    } catch (e) {
      debugPrint('approvePaymentOrder error: $e');
      return false;
    }
  }

  /// Platform Yöneticisi İçin Bekleyen Ödeme Siparişleri
  Future<List<CommercialPaymentOrder>> getPendingPaymentOrders() async {
    try {
      final client = SupabaseService.client;
      final rows = await client
          .from('commercial_payment_orders')
          .select()
          .order('created_at', ascending: false);

      return (rows as List)
          .map((r) => CommercialPaymentOrder.fromMap(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('getPendingPaymentOrders error: $e');
      return [];
    }
  }
}
