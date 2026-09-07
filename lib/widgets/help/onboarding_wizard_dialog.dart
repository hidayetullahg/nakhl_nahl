// NAKHL & NAHL — 15-Step Universal Onboarding Wizard
// Complies with Master Directive Section 14

import 'package:flutter/material.dart';
import '../../services/help/help_controller.dart';

class WizardStepInfo {
  final int number;
  final String title;
  final String description;
  final String actionLabel;
  final String route;
  final IconData icon;

  const WizardStepInfo({
    required this.number,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.route,
    required this.icon,
  });
}

class OnboardingWizardDialog extends StatefulWidget {
  const OnboardingWizardDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const OnboardingWizardDialog(),
    );
  }

  @override
  State<OnboardingWizardDialog> createState() => _OnboardingWizardDialogState();
}

class _OnboardingWizardDialogState extends State<OnboardingWizardDialog> {
  int _currentStepIndex = 0;

  static const List<WizardStepInfo> steps = [
    WizardStepInfo(
      number: 1,
      title: 'Şirketinizi Oluşturun',
      description: 'Ticari unvanınızı, vergi dairenizi ve resmi şirket kimlik bilgilerinizi kaydedin.',
      actionLabel: 'Şirket Ayarlarına Git',
      route: '/settings/company',
      icon: Icons.business_rounded,
    ),
    WizardStepInfo(
      number: 2,
      title: 'Şube Oluşturun',
      description: 'Merkez ofis ve varsa faaliyet gösteren operasyonel şubelerinizi tanımlayın.',
      actionLabel: 'Şube Yönetimine Git',
      route: '/settings/branches',
      icon: Icons.storefront_rounded,
    ),
    WizardStepInfo(
      number: 3,
      title: 'Kullanıcı / Personel Ekleyin',
      description: 'Ekip arkadaşlarınızı e-posta ile davet edin ve yetki çerçevelerini çizin.',
      actionLabel: 'Kullanıcıları Yönet',
      route: '/settings/users',
      icon: Icons.people_outline_rounded,
    ),
    WizardStepInfo(
      number: 4,
      title: 'Roller ve Yetkileri Ayarlayın',
      description: 'Muhasebe, Depo, Satış veya Kasa rollerini RBAC güvenlik mimarisiyle belirleyin.',
      actionLabel: 'Rolleri Düzenle',
      route: '/settings/roles',
      icon: Icons.admin_panel_settings_outlined,
    ),
    WizardStepInfo(
      number: 5,
      title: 'Depo Oluşturun',
      description: 'Mallarınızın tutulduğu ana ambar, sevkiyat deposu veya raf sistemini tanımlayın.',
      actionLabel: 'Depo Tanımla',
      route: '/inventory/warehouses',
      icon: Icons.warehouse_rounded,
    ),
    WizardStepInfo(
      number: 6,
      title: 'Ürünlerinizi Ekleyin',
      description: 'Satışını yaptığınız malları ve sunduğunuz hizmetleri SKU ve KDV oranlarıyla girin.',
      actionLabel: 'Ürün Kataloğunu Aç',
      route: '/inventory/products',
      icon: Icons.inventory_2_outlined,
    ),
    WizardStepInfo(
      number: 7,
      title: 'Müşterilerinizi Ekleyin',
      description: 'Müşteri cari kartlarını açarak VKN/TCKN ve risk limitlerini sisteme girin.',
      actionLabel: 'Cari Kart Aç',
      route: '/customers',
      icon: Icons.assignment_ind_outlined,
    ),
    WizardStepInfo(
      number: 8,
      title: 'Tedarikçilerinizi Ekleyin',
      description: 'Hizmet ve mal tedarik ettiğiniz firmaların cari ve IBAN bilgilerini kaydedin.',
      actionLabel: 'Tedarikçi Tanımla',
      route: '/suppliers',
      icon: Icons.local_shipping_outlined,
    ),
    WizardStepInfo(
      number: 9,
      title: 'Vergi Ayarlarını Yapın',
      description: 'Türkiye KDV veya Suudi Arabistan VAT kurallarınızı ve tevkifat oranlarınızı belirleyin.',
      actionLabel: 'Vergi Motoru Ayarları',
      route: '/settings/tax',
      icon: Icons.account_balance_outlined,
    ),
    WizardStepInfo(
      number: 10,
      title: 'E-Fatura / ZATCA Ayarlarını Yapın',
      description: 'GİB veya ZATCA Phase 2 entegrasyon profilini oluşturup Sandbox ortamında test edin.',
      actionLabel: 'Entegrasyonları Yapılandır',
      route: '/settings/integrations',
      icon: Icons.receipt_long_rounded,
    ),
    WizardStepInfo(
      number: 11,
      title: 'Açılış Stoklarını Girin',
      description: 'Mevcut fiziksel deponuzdaki sayım miktarlarını stok defterine açılış fişi ile aktarın.',
      actionLabel: 'Stok Girişi Yap',
      route: '/inventory/stocks',
      icon: Icons.move_to_inbox_rounded,
    ),
    WizardStepInfo(
      number: 12,
      title: 'Açılış Bakiyelerini Girin',
      description: 'Müşteri ve tedarikçilerin devreden borç/alacak bakiyelerini cari açılış fişi ile kaydedin.',
      actionLabel: 'Cari Bakiyeleri Gir',
      route: '/accounting/ledger',
      icon: Icons.account_balance_wallet_outlined,
    ),
    WizardStepInfo(
      number: 13,
      title: 'İlk Satışınızı Oluşturun',
      description: 'Teklif veya satış siparişi düzenleyerek satış sürecini başlatın.',
      actionLabel: 'Sipariş Oluştur',
      route: '/sales/orders',
      icon: Icons.shopping_cart_outlined,
    ),
    WizardStepInfo(
      number: 14,
      title: 'İlk Faturayı Kesin',
      description: 'Satışı faturaya dönüştürüp e-fatura/e-arşiv XML ve QR kodunu üretin.',
      actionLabel: 'Fatura Düzenle',
      route: '/sales/invoices',
      icon: Icons.point_of_sale_rounded,
    ),
    WizardStepInfo(
      number: 15,
      title: 'Raporları İnceleyin',
      description: 'Finansal durum, bilanço, mizan ve stok karlılık raporlarınızı denetleyin.',
      actionLabel: 'Raporlama Paneline Git',
      route: '/reports',
      icon: Icons.bar_chart_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final currentStep = steps[_currentStepIndex];
    final controller = HelpController();
    final completedCount = controller.completedWizardSteps.length;
    final progressRatio = completedCount / steps.length;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840, maxHeight: 680),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.rocket_launch_rounded, color: Color(0xFF10B981), size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'NAKHL & NAHL Kurulum ve Başlangıç Sihirbazı',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '15 adımda şirketinizi sıfırdan canlı üretime hazırlayın.',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Progress Bar
            LinearProgressIndicator(
              value: progressRatio,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
              minHeight: 4,
            ),

            // Main Content Area
            Expanded(
              child: Row(
                children: [
                  // Left: Steps List
                  SizedBox(
                    width: 280,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: steps.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 48),
                      itemBuilder: (context, idx) {
                        final s = steps[idx];
                        final isSelected = idx == _currentStepIndex;
                        final isDone = controller.completedWizardSteps.containsKey('step_${s.number}');

                        return ListTile(
                          dense: true,
                          selected: isSelected,
                          selectedTileColor: const Color(0xFFF1F5F9),
                          leading: CircleAvatar(
                            radius: 12,
                            backgroundColor: isDone
                                ? const Color(0xFF10B981)
                                : (isSelected ? const Color(0xFF0F172A) : Colors.grey.shade300),
                            child: isDone
                                ? const Icon(Icons.check, color: Colors.white, size: 14)
                                : Text(
                                    '${s.number}',
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.grey.shade700,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                          title: Text(
                            s.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? const Color(0xFF0F172A) : Colors.grey.shade800,
                            ),
                          ),
                          onTap: () => setState(() => _currentStepIndex = idx),
                        );
                      },
                    ),
                  ),

                  const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),

                  // Right: Detail Panel
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(0xFF0F172A).withOpacity(0.06),
                                child: Icon(currentStep.icon, color: const Color(0xFF0F172A), size: 26),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ADIM ${currentStep.number} / ${steps.length}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF10B981),
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      currentStep.title,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            currentStep.description,
                            style: const TextStyle(fontSize: 15, height: 1.5, color: Color(0xFF334155)),
                          ),
                          const Spacer(),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F172A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                                label: Text(currentStep.actionLabel),
                                onPressed: () {
                                  // Mark completed and navigate
                                  controller.markWizardStepCompleted(currentStep.number);
                                  Navigator.of(context).pop();
                                  // In real app router: context.go(currentStep.route);
                                },
                              ),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () {
                                  controller.markWizardStepCompleted(currentStep.number);
                                  if (_currentStepIndex < steps.length - 1) {
                                    setState(() => _currentStepIndex++);
                                  }
                                },
                                child: const Text('Tamamlandı Olarak İşaretle'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.chevron_left, size: 18),
                                label: const Text('Önceki'),
                                onPressed: _currentStepIndex > 0
                                    ? () => setState(() => _currentStepIndex--)
                                    : null,
                              ),
                              TextButton.icon(
                                label: const Text('Sonraki'),
                                icon: const Icon(Icons.chevron_right, size: 18),
                                onPressed: _currentStepIndex < steps.length - 1
                                    ? () => setState(() => _currentStepIndex++)
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
