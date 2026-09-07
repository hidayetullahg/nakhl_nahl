// ==============================================================================
// NAKHL & NAHL — COMMERCIAL MODULE STORE & BILLING SCREEN
// File: lib/screens/billing/module_store_screen.dart
// Decoupled SaaS Catalog: Multi-Currency + Cart + Credit Card & Bank Wire
// ==============================================================================

import 'package:flutter/material.dart';
import '../../services/billing/module_catalog_service.dart';
import '../../services/billing/subscription_billing_service.dart';
import '../../core/config/app_brand_config.dart';

class ModuleStoreScreen extends StatefulWidget {
  const ModuleStoreScreen({super.key});

  @override
  State<ModuleStoreScreen> createState() => _ModuleStoreScreenState();
}

class _ModuleStoreScreenState extends State<ModuleStoreScreen> {
  static const Color hurmaKahvesi = Color(0xFF5C4033);
  static const Color altinSarisi = Color(0xFFC89033);
  static const Color yesilBasari = Color(0xFF2E7D32);
  static const Color sariUyari = Color(0xFFF57F17);

  String _selectedCurrency = 'SAR';
  String _selectedCategory = 'ALL';
  bool _isYearly = true;
  bool _isLoading = true;

  List<CommercialModule> _allModules = [];
  Map<String, TenantSubscription> _activeSubs = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final catalog = await ModuleCatalogService.instance
        .getCatalog(activeCurrency: _selectedCurrency);

    final subs = await SubscriptionBillingService.instance.getSubscriptions();
    final subMap = <String, TenantSubscription>{};
    for (final s in subs) {
      subMap[s.moduleCode] = s;
    }

    setState(() {
      _allModules = catalog;
      _activeSubs = subMap;
      _isLoading = false;
    });
  }

  void _showPurchaseModal(CommercialModule module) {
    final pricing = module.getPricing(_selectedCurrency);
    final price = _isYearly
        ? (pricing?.yearlyPrice ?? 0.0)
        : (pricing?.monthlyPrice ?? 0.0);

    PaymentMethod selectedMethod = PaymentMethod.creditCard;
    final refController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(module.name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      )
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Dönem: ${_isYearly ? "Yıllık (Avantajlı)" : "Aylık"} | Tutar: $price $_selectedCurrency',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: hurmaKahvesi),
                  ),
                  const SizedBox(height: 16),
                  const Text('Ödeme Yöntemini Seçin:',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  RadioListTile<PaymentMethod>(
                    value: PaymentMethod.creditCard,
                    groupValue: selectedMethod,
                    title: const Text('Kredi / Banka Kartı (Anında Aktivasyon)'),
                    activeColor: altinSarisi,
                    onChanged: (val) =>
                        setModalState(() => selectedMethod = val!),
                  ),
                  RadioListTile<PaymentMethod>(
                    value: PaymentMethod.bankWire,
                    groupValue: selectedMethod,
                    title: const Text('Banka Havalesi / EFT / Dekont'),
                    activeColor: altinSarisi,
                    onChanged: (val) =>
                        setModalState(() => selectedMethod = val!),
                  ),
                  if (selectedMethod == PaymentMethod.bankWire) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Banka Hesap Adı: ${AppBrandConfig.current.companyLegalName}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 4),
                          const Text('IBAN: TR12 0006 2000 0001 2345 6789 01 (Garanti BBVA)',
                              style: TextStyle(
                                  fontSize: 12, fontFamily: 'monospace')),
                          const SizedBox(height: 8),
                          TextField(
                            controller: refController,
                            decoration: const InputDecoration(
                              labelText: 'Dekont / Havale Referans No',
                              hintText: 'Örn: DEKONT-98765',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hurmaKahvesi,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        _completePurchase(
                          module: module,
                          method: selectedMethod,
                          amount: price,
                          refCode: refController.text.trim(),
                        );
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(
                        selectedMethod == PaymentMethod.creditCard
                            ? 'Kartla Öde ve Hemen Başla'
                            : 'Havale Bildirimini Gönder',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _completePurchase({
    required CommercialModule module,
    required PaymentMethod method,
    required double amount,
    String? refCode,
  }) async {
    setState(() => _isLoading = true);

    final order = await SubscriptionBillingService.instance.createPaymentOrder(
      moduleCodes: [module.code],
      method: method,
      currency: _selectedCurrency,
      totalAmount: amount,
      billingCycle: _isYearly ? 'YEARLY' : 'MONTHLY',
      bankAccountTitle: AppBrandConfig.current.companyLegalName,
      bankIban: 'TR12 0006 2000 0001 2345 6789 01',
      referenceCode: refCode,
    );

    await _loadData();

    if (mounted) {
      if (order != null) {
        final msg = method == PaymentMethod.creditCard
            ? '${module.name} lisansı başarıyla aktifleştirildi!'
            : 'Ödeme bildiriminiz alındı. Yönetici kontrolünden sonra modül aktif olacaktır.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: method == PaymentMethod.creditCard
                ? yesilBasari
                : sariUyari,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sipariş oluşturulamadı. Lütfen tekrar deneyin.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startTrial(CommercialModule module) async {
    setState(() => _isLoading = true);
    final success =
        await SubscriptionBillingService.instance.startTrial(module.code);
    await _loadData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? '${module.name} için 14 günlük deneme sürümünüz başladı!'
              : 'Deneme başlatılamadı.'),
          backgroundColor: success ? yesilBasari : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _allModules.where((m) {
      if (_selectedCategory == 'ALL') return true;
      return m.category.code == _selectedCategory;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F2),
      appBar: AppBar(
        title: const Text('Modül & Lisans Mağazası',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: hurmaKahvesi,
        foregroundColor: Colors.white,
        actions: [
          // Para Birimi Seçici
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCurrency,
              dropdownColor: hurmaKahvesi,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              items: const [
                DropdownMenuItem(
                    value: 'SAR',
                    child: Text('SAR (Riyal)',
                        style: TextStyle(color: Colors.white))),
                DropdownMenuItem(
                    value: 'TRY',
                    child: Text('TRY (TL)',
                        style: TextStyle(color: Colors.white))),
                DropdownMenuItem(
                    value: 'USD',
                    child: Text('USD (\$)',
                        style: TextStyle(color: Colors.white))),
                DropdownMenuItem(
                    value: 'EUR',
                    child: Text('EUR (€)',
                        style: TextStyle(color: Colors.white))),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedCurrency = val);
                  _loadData();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          )
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: altinSarisi))
          : Column(
              children: [
                // Üst Bant: Dönem ve Filtre Çubuğu
                Container(
                  color: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Kategori Seçici
                      DropdownButton<String>(
                        value: _selectedCategory,
                        underline: const SizedBox.shrink(),
                        items: const [
                          DropdownMenuItem(
                              value: 'ALL', child: Text('Tüm Kategoriler')),
                          DropdownMenuItem(
                              value: 'FINANCE', child: Text('Finans & Muhasebe')),
                          DropdownMenuItem(
                              value: 'OPERATIONS', child: Text('Operasyon & Stok')),
                          DropdownMenuItem(
                              value: 'COMPLIANCE', child: Text('E-Fatura & Mevzuat')),
                          DropdownMenuItem(
                              value: 'MIGRATION', child: Text('Veri Aktarımı')),
                          DropdownMenuItem(
                              value: 'SERVICE', child: Text('Kurulum & Eğitim')),
                          DropdownMenuItem(
                              value: 'ANALYTICS', child: Text('Raporlama & BI')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedCategory = val);
                          }
                        },
                      ),
                      // Aylık / Yıllık Geçiş
                      Row(
                        children: [
                          Text('Aylık',
                              style: TextStyle(
                                  fontWeight: !_isYearly
                                      ? FontWeight.bold
                                      : FontWeight.normal)),
                          Switch(
                            value: _isYearly,
                            activeColor: altinSarisi,
                            onChanged: (val) =>
                                setState(() => _isYearly = val),
                          ),
                          Row(
                            children: [
                              Text('Yıllık',
                                  style: TextStyle(
                                      fontWeight: _isYearly
                                          ? FontWeight.bold
                                          : FontWeight.normal)),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: yesilBasari,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '%20 İndirim',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold),
                                ),
                              )
                            ],
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Modül Kartları Listesi
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, idx) {
                      final module = filtered[idx];
                      return _buildModuleCard(module);
                    },
                  ),
                )
              ],
            ),
    );
  }

  Widget _buildModuleCard(CommercialModule module) {
    final sub = _activeSubs[module.code];
    final isCore = module.isCore;
    final pricing = module.getPricing(_selectedCurrency);
    final price = _isYearly
        ? (pricing?.yearlyPrice ?? 0.0)
        : (pricing?.monthlyPrice ?? 0.0);

    bool isActive = isCore || (sub?.isUsable ?? false);
    bool isTrial = sub?.status == SubscriptionStatus.trial;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive ? yesilBasari.withOpacity(0.5) : Colors.grey.shade300,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(module.name,
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          if (isCore)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('Ücretsiz / Temel',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(module.category.label,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                // Durum Rozeti
                if (isActive)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: yesilBasari.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: yesilBasari),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle,
                            color: yesilBasari, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          isTrial
                              ? 'Deneme (${sub?.remainingDays ?? 0} gün)'
                              : 'Aktif Lisans',
                          style: const TextStyle(
                              color: yesilBasari,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    isCore ? '0.00 $_selectedCurrency' : '$price $_selectedCurrency',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: hurmaKahvesi),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              module.description ?? '',
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
            if (module.dependencies.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.link, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Gereksinim: ${module.dependencies.join(", ")}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            // Aksiyon Butonları
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isActive && !isCore) ...[
                  OutlinedButton(
                    onPressed: () => _startTrial(module),
                    child: const Text('14 Gün Ücretsiz Dene'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hurmaKahvesi,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _showPurchaseModal(module),
                    icon: const Icon(Icons.shopping_cart_checkout, size: 18),
                    label: const Text('Satın Al & Aktif Et'),
                  ),
                ] else if (isTrial) ...[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: altinSarisi,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _showPurchaseModal(module),
                    child: const Text('Tam Lisansa Yükselt'),
                  ),
                ] else ...[
                  OutlinedButton(
                    onPressed: null,
                    child: const Text('Lisansınız Aktif'),
                  ),
                ]
              ],
            )
          ],
        ),
      ),
    );
  }
}
