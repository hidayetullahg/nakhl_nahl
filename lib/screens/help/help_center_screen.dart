// NAKHL & NAHL — Universal Help & Education Center Screen
// Complies with Master Directive Sections 12, 13, 19, 20, 22, 34

import 'package:flutter/material.dart';
import '../../models/help_models.dart';
import '../../services/help/help_controller.dart';
import '../../services/help/help_registry.dart';
import '../../widgets/help/help_drawer.dart';
import '../../widgets/help/onboarding_wizard_dialog.dart';
import '../../widgets/help/guided_tour_overlay.dart';
import 'help_admin_screen.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final _searchController = TextEditingController();
  final _registry = HelpRegistry();
  final _controller = HelpController();
  List<HelpContent> _filteredContents = [];

  @override
  void initState() {
    super.initState();
    _filteredContents = HelpRegistry.defaultContents;
  }

  void _onSearchChanged(String query) {
    setState(() {
      _filteredContents = _registry.search(query, role: _controller.currentRole, language: _controller.currentLanguage);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('❓ NAKHL & NAHL Yardım ve Eğitim Merkezi'),
        actions: [
          // Help Mode Selection
          PopupMenuButton<HelpMode>(
            initialValue: _controller.mode,
            tooltip: 'Yardım Modu',
            icon: const Icon(Icons.tune_rounded),
            onSelected: (newMode) => _controller.setHelpMode(newMode),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: HelpMode.detailed,
                child: Text('🟢 Detaylı Yardım (Adım Adım & Kılavuz)'),
              ),
              const PopupMenuItem(
                value: HelpMode.basic,
                child: Text('🟡 Basit Yardım (Yalnızca İpuçları)'),
              ),
              const PopupMenuItem(
                value: HelpMode.off,
                child: Text('⚪ Yardım Kapalı (Deneyimli Kullanıcı)'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_outlined),
            tooltip: 'Yardım İçerik Yönetimi (Admin)',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HelpAdminScreen()),
              );
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Banner
                _buildHeroBanner(context),
                const SizedBox(height: 24),

                // Search Bar
                _buildSearchBar(),
                const SizedBox(height: 28),

                // Task-Based Guided Flows
                _buildTaskBasedGuides(context),
                const SizedBox(height: 32),

                // Official Documentation Links
                _buildOfficialDocLinks(),
                const SizedBox(height: 32),

                // All ERP Modules Knowledge Base
                const Text(
                  'Tüm Modüller ve Kullanım Kılavuzları',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 16),
                _buildModuleCards(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'SIFIRDAN BAŞLANGIÇ REHBERİ',
                    style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'NAKHL & NAHL Sistemine Hoş Geldiniz!',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hiçbir muhasebe veya ERP deneyiminiz olmasa dahi adım adım sihirbazımızla şirketinizi kurabilir, ilk faturanızı kesebilir ve stoklarınızı yönetebilirsiniz.',
                  style: TextStyle(color: Colors.grey.shade300, fontSize: 13.5, height: 1.45),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.play_circle_outline_rounded, size: 20),
                      label: const Text('15 Adımlı Kurulum Sihirbazı'),
                      onPressed: () => OnboardingWizardDialog.show(context),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.explore_outlined, size: 18),
                      label: const Text('Sistemi Bana Öğret (Tur)'),
                      onPressed: () {
                        GuidedTourOverlay.start(context, [
                          const TourStepItem(
                            title: '1. Müşterilerinizi Yönetin',
                            description: 'Sol menüdeki Müşteriler sekmesinden cari kartlarınızı oluşturabilir ve borç/alacak bakiyelerini izleyebilirsiniz.',
                          ),
                          const TourStepItem(
                            title: '2. Ürünlerinizi Tanımlayın',
                            description: 'Ürün kataloğundan barkod okutarak saniyeler içinde mal ve hizmet kartları açabilirsiniz.',
                          ),
                          const TourStepItem(
                            title: '3. Fatura ve E-Fatura',
                            description: 'Satış faturası düzenleyip tek tıkla Gelir İdaresi (GİB) veya ZATCA sistemine resmi e-fatura iletebilirsiniz.',
                          ),
                          const TourStepItem(
                            title: '4. Finansal Raporlar',
                            description: 'Bilanço, mizan ve stok raporlarıyla şirketinizin nakit akışını anlık takip edebilirsiniz.',
                          ),
                        ]);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Ne yapmak istiyorsunuz? (örn: fatura kesmek, stok girmek, cari bakiye, zatca...)',
        prefixIcon: const Icon(Icons.search_rounded, size: 22, color: Color(0xFF0F172A)),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded),
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildTaskBasedGuides(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Görev Bazlı Hızlı Kılavuzlar',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 12),
        Row(
          children: HelpRegistry.taskGuides.map((g) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withOpacity(0.06),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        g.category.toUpperCase(),
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      g.title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      g.description,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.35),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                      label: const Text('Rehberi Aç', style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        final helpContent = HelpContent(
                          id: g.id,
                          route: g.targetRoute,
                          menuKey: g.id,
                          title: g.title,
                          shortDescription: g.description,
                          longDescription: g.description,
                          steps: g.steps,
                          searchableText: g.title,
                        );
                        _controller.openDrawer(helpContent);
                        HelpDrawer.show(context, helpContent);
                      },
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildOfficialDocLinks() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_user_outlined, color: Color(0xFF0284C7), size: 20),
              SizedBox(width: 8),
              Text(
                'Resmi Mevzuat ve Dokümantasyon Bağlantıları',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.open_in_new, size: 14),
                label: const Text('🇹🇷 GİB E-Fatura Resmi Portalı'),
                onPressed: () {},
              ),
              ActionChip(
                avatar: const Icon(Icons.open_in_new, size: 14),
                label: const Text('🇸🇦 ZATCA Fatoora Phase 2 Kılavuzu'),
                onPressed: () {},
              ),
              ActionChip(
                avatar: const Icon(Icons.open_in_new, size: 14),
                label: const Text('🇦🇪 UAE FTA E-Fatura Portalı'),
                onPressed: () {},
              ),
              ActionChip(
                avatar: const Icon(Icons.open_in_new, size: 14),
                label: const Text('🇪🇺 OpenPEPPOL BIS 3.0 Standardı'),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCards(BuildContext context) {
    if (_filteredContents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text('Aramanızla eşleşen yardım konusu bulunamadı.', style: TextStyle(color: Colors.grey.shade600)),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 700 ? 2 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 150,
          ),
          itemCount: _filteredContents.length,
          itemBuilder: (context, idx) {
            final content = _filteredContents[idx];
            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                _controller.openDrawer(content);
                HelpDrawer.show(context, content);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: const Color(0xFF0F172A).withOpacity(0.06),
                          child: const Icon(Icons.menu_book_outlined, size: 16, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            content.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      content.shortDescription,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.35),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          '${content.steps.length} Adım',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Rol: ${content.role.toUpperCase()}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
