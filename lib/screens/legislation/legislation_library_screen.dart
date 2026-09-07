// ==============================================================================
// NAKHL & NAHL — MEVZUAT KÜTÜPHANESİ EKRANI (LEGISLATION LIBRARY)
// Master Directive: Global Shelf Architecture & Active Packs Dashboard
// ==============================================================================

import 'package:flutter/material.dart';
import '../../models/legislation/legal_pack_model.dart';
import '../../services/legislation/legal_pack_registry_service.dart';
import 'cross_border_assessment_screen.dart';

class LegislationLibraryScreen extends StatefulWidget {
  const LegislationLibraryScreen({super.key});

  @override
  State<LegislationLibraryScreen> createState() => _LegislationLibraryScreenState();
}

class _LegislationLibraryScreenState extends State<LegislationLibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _registryService = LegalPackRegistryService.instance;

  static const Color hurmaKahvesi = Color(0xFF5C4033);
  static const Color hurmaKahvesiKoyu = Color(0xFF3E2723);
  static const Color altinSarisi = Color(0xFFC89033);
  static const Color zeytinYesili = Color(0xFF2E7D32);
  static const Color kremArkaplan = Color(0xFFFBF9F1);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onDemandDiscoveryIste(LegalJurisdictionModel shelf) {
    showDialog(
      context: context,
      builder: (ctx) {
        String seciliUrunKategorisi = 'Hurma & Kuru Gıda İhracatı';
        final notController = TextEditingController();

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Text(shelf.flagEmoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${shelf.nameTr} — On-Demand Keşif Başlat',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: hurmaKahvesiKoyu),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sistem tüm dünya mevzuatını baştan yüklemez. Yalnızca ticari işlem gerektirdiğinde resmi kaynaklar taranır ve insan incelemesiyle aktive edilir.',
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Hedef Ticari Kapsam:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: seciliUrunKategorisi,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Hurma & Kuru Gıda İhracatı', child: Text('Hurma & Kuru Gıda İhracatı')),
                    DropdownMenuItem(value: 'İşlenmiş Gıda & Şekerleme', child: Text('İşlenmiş Gıda & Şekerleme')),
                    DropdownMenuItem(value: 'Taze Tarım Ürünleri', child: Text('Taze Tarım Ürünleri')),
                    DropdownMenuItem(value: 'Genel Ticari İthalat/İhracat', child: Text('Genel Ticari İthalat/İhracat')),
                  ],
                  onChanged: (val) => seciliUrunKategorisi = val ?? seciliUrunKategorisi,
                ),
                const SizedBox(height: 12),
                const Text('Operasyon Notu:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: notController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Örn: Şanghay limanına 1 konteyner Medjool hurma satışı planlanıyor.',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.all(10),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Vazgeç', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: hurmaKahvesi,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.rocket_launch, size: 16),
              label: const Text('Keşfi Başlat'),
              onPressed: () {
                _registryService.requestPackDiscovery(
                  countryCode: shelf.code,
                  targetProductCategory: seciliUrunKategorisi,
                  requesterNote: notController.text,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: zeytinYesili,
                    content: Text('✅ ${shelf.nameTr} için resmi kaynak tarama talebi oluşturuldu (DISCOVERY).'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _aktifPaketDetayGoster(LegalPackModel pack) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: hurmaKahvesi.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.verified, color: zeytinYesili),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pack.packNameTr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(pack.packCode, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Text('Kapsam: ${pack.scopeDisplayTr}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('Kapsama Oranı: %${pack.coveragePercentage.toStringAsFixed(1)}', style: const TextStyle(fontSize: 13, color: zeytinYesili, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('Resmi Yetkili Kurumlar:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 6),
              ...pack.primaryAuthorities.map((a) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, size: 16, color: zeytinYesili),
                    const SizedBox(width: 6),
                    Expanded(child: Text(a, style: const TextStyle(fontSize: 13))),
                  ],
                ),
              )),
              const SizedBox(height: 16),
              const Text('Kapsanan Hukuk Alanları:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: pack.coveredDomains.map((d) => Chip(
                  label: Text(d, style: const TextStyle(fontSize: 11)),
                  backgroundColor: kremArkaplan,
                  side: BorderSide(color: hurmaKahvesi.withOpacity(0.2)),
                )).toList(),
              ),
              const SizedBox(height: 16),
              if (pack.notes != null)
                Text('Not: ${pack.notes}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black54)),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activePacks = _registryService.getActivePacks();
    final emptyShelves = _registryService.getEmptyShelves();

    return Scaffold(
      backgroundColor: kremArkaplan,
      appBar: AppBar(
        title: const Text('Mevzuat Kütüphanesi & Global Raflar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: hurmaKahvesiKoyu,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Çapraz Sınır Simülasyonu',
            icon: const Icon(Icons.compare_arrows, color: altinSarisi),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CrossBorderAssessmentScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: altinSarisi,
          indicatorWeight: 3,
          labelColor: altinSarisi,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              icon: const Icon(Icons.verified),
              text: 'Aktif Mevzuat (${activePacks.length})',
            ),
            Tab(
              icon: const Icon(Icons.shelves),
              text: 'Global Raflar (${emptyShelves.length})',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: AKTİF MEVZUAT HAVUZLARI
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: hurmaKahvesi.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, color: zeytinYesili, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Şirketin ana operasyonel mevzuat havuzu. 4 yetki alanı derinlemesine ve çalışır durumdadır. Kurallar asla birbirine karıştırılmaz (Jurisdiction Isolation).',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hurmaKahvesi,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text('Simüle Et', style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CrossBorderAssessmentScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              ...activePacks.map((p) => _buildActivePackCard(p)),
            ],
          ),

          // TAB 2: GLOBAL BOŞ RAFLAR (NOT_LOADED)
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blueGrey.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, color: Colors.blueGrey, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Bu ülkelerin mevzuatı sisteme önceden doldurulmamıştır. İleride bu pazarlara ihracat/ithalat kararı alındığında odaklanmış resmi kaynak taraması başlatılır.',
                        style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                      ),
                    ),
                  ],
                ),
              ),
              ...emptyShelves.map((s) => _buildEmptyShelfTile(s)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivePackCard(LegalPackModel pack) {
    String flagEmoji = '';
    switch (pack.jurisdictionCode) {
      case 'SA':
        flagEmoji = '🇸🇦';
      case 'TR':
        flagEmoji = '🇹🇷';
      case 'EU':
        flagEmoji = '🇪🇺';
      case 'DE':
        flagEmoji = '🇩🇪';
      default:
        flagEmoji = '🌐';
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _aktifPaketDetayGoster(pack),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(flagEmoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pack.packNameTr,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: hurmaKahvesiKoyu),
                        ),
                        Text(
                          pack.packCode,
                          style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: zeytinYesili.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: zeytinYesili.withOpacity(0.5)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: zeytinYesili, size: 14),
                        SizedBox(width: 4),
                        Text('ACTIVE', style: TextStyle(color: zeytinYesili, fontWeight: FontWeight.bold, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: pack.coveragePercentage / 100,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(zeytinYesili),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      pack.scopeDisplayTr,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '%${pack.coveragePercentage.toStringAsFixed(1)} Kapsama',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: zeytinYesili),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyShelfTile(LegalJurisdictionModel shelf) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Text(shelf.flagEmoji, style: const TextStyle(fontSize: 24)),
        title: Text(shelf.nameTr, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(
          '${shelf.code} • ${shelf.region} • Henüz yüklenmedi',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        trailing: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: hurmaKahvesi,
            side: const BorderSide(color: hurmaKahvesi),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
          icon: const Icon(Icons.add_circle_outline, size: 14),
          label: const Text('Keşif Başlat', style: TextStyle(fontSize: 11)),
          onPressed: () => _onDemandDiscoveryIste(shelf),
        ),
      ),
    );
  }
}
