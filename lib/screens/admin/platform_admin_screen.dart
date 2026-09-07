// ==============================================================================
// NAKHL & NAHL — PLATFORM ADMIN & CUSTOMER MANAGEMENT PORTAL
// File: lib/screens/admin/platform_admin_screen.dart
// Customer Subscriptions + Manual/Dekont Approvals + Tenant Isolation Audits
// ==============================================================================

import 'package:flutter/material.dart';
import '../../services/billing/subscription_billing_service.dart';
import '../../core/tenant/tenant_context.dart';
import '../../core/config/app_brand_config.dart';

class PlatformAdminScreen extends StatefulWidget {
  const PlatformAdminScreen({super.key});

  @override
  State<PlatformAdminScreen> createState() => _PlatformAdminScreenState();
}

class _PlatformAdminScreenState extends State<PlatformAdminScreen>
    with SingleTickerProviderStateMixin {
  static const Color hurmaKahvesi = Color(0xFF5C4033);
  static const Color altinSarisi = Color(0xFFC89033);
  static const Color yesilBasari = Color(0xFF2E7D32);
  static const Color sariUyari = Color(0xFFF57F17);

  late TabController _tabController;
  bool _isLoading = true;
  List<CommercialPaymentOrder> _orders = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final orders =
        await SubscriptionBillingService.instance.getPendingPaymentOrders();
    setState(() {
      _orders = orders;
      _isLoading = false;
    });
  }

  Future<void> _approveOrder(CommercialPaymentOrder order) async {
    setState(() => _isLoading = true);
    final currentUserId =
        TenantContext.instance.userId ?? '00000000-0000-0000-0000-000000000001';

    final success = await SubscriptionBillingService.instance.approvePaymentOrder(
      orderId: order.id,
      verifierUserId: currentUserId,
    );

    await _loadData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? '${order.orderNumber} nolu sipariş onaylandı ve lisans aktif edildi!'
              : 'Onaylama başarısız oldu.'),
          backgroundColor: success ? yesilBasari : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F2),
      appBar: AppBar(
        title: Text('${AppBrandConfig.current.productName} — Platform Yönetim Merkezi',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: hurmaKahvesi,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: altinSarisi,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              icon: const Icon(Icons.payment),
              text:
                  'Ödeme & Dekont Onayları (${_orders.where((o) => o.paymentStatus == PaymentStatus.pending).length})',
            ),
            const Tab(
              icon: Icon(Icons.business),
              text: 'Sistem & Marka Bilgisi',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          )
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: altinSarisi))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersTab(),
                _buildBrandAndSystemTab(),
              ],
            ),
    );
  }

  Widget _buildOrdersTab() {
    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text('Henüz incelenecek ödeme siparişi bulunmuyor.',
                style: TextStyle(color: Colors.black54, fontSize: 15)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (context, idx) {
        final order = _orders[idx];
        final isPending = order.paymentStatus == PaymentStatus.pending;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: isPending
                  ? sariUyari.withOpacity(0.2)
                  : yesilBasari.withOpacity(0.2),
              child: Icon(
                isPending ? Icons.pending_actions : Icons.verified,
                color: isPending ? sariUyari : yesilBasari,
              ),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(order.orderNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${order.totalAmount} ${order.currency}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: hurmaKahvesi)),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text('Yöntem: ${order.paymentMethod.label} | Durum: ${order.paymentStatus.label}'),
                if (order.bankTransferReference != null &&
                    order.bankTransferReference!.isNotEmpty)
                  Text('Havale / Dekont No: ${order.bankTransferReference}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                if (order.notes != null)
                  Text('${order.notes}',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 4),
                Text('Tarih: ${order.createdAt.toString().substring(0, 16)}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            trailing: isPending
                ? ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: yesilBasari,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _approveOrder(order),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Onayla'),
                  )
                : const Chip(
                    label: Text('Ödendi',
                        style: TextStyle(
                            color: yesilBasari,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                    backgroundColor: Color(0xFFE8F5E9),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildBrandAndSystemTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Marka ve Alan Adı Bağımsızlığı (Decoupled SaaS)',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text(
                    'Uygulama teknik mimarisi ticari marka ve domain adından tamamen yalıtılmıştır. '
                    'Tüm marka ve iletişim değerleri AppBrandConfig üzerinden veya derleme sırasında (--dart-define) dinamik olarak değiştirilebilir.',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  const Divider(height: 24),
                  _buildConfigRow('Ürün / Yazılım Adı:', AppBrandConfig.current.productName),
                  _buildConfigRow('Şirket Resmi Ünvanı:', AppBrandConfig.current.companyLegalName),
                  _buildConfigRow('Birincil Alan Adı (Domain):', AppBrandConfig.current.primaryDomain),
                  _buildConfigRow('Destek E-Posta:', AppBrandConfig.current.supportEmail),
                  _buildConfigRow('Satış E-Posta:', AppBrandConfig.current.salesEmail),
                  _buildConfigRow('Gizlilik Politikası:', AppBrandConfig.current.privacyPolicyUrl),
                  _buildConfigRow('Hizmet Şartları:', AppBrandConfig.current.termsOfServiceUrl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontFamily: 'monospace',
                    color: hurmaKahvesi)),
          ),
        ],
      ),
    );
  }
}
