// ============================================================
// YÖNETİCİ PANELİ EKRANI (DASHBOARD)
// ============================================================
// NAKHL & NAHL Kurumsal ERP Sistemi
//
// Bu ekran yönetici seviyesinde gerçek zamanlı:
//   1. Kasadaki toplam bakiye (Firestore: 'finansal_hareketler')
//   2. Depodaki toplam hurma tonajı (Firestore: 'stoklar')
//   3. Aktif müşteri ve cari sayısı (Supabase: 'cariler')
//   4. Devam eden lojistik sevkiyatlar (Firestore: 'sevkiyatlar')
//
// KPI özet kartlarını canlı StreamBuilder altyapısıyla gösterir
// ve alt navigasyon çubuğu ile Cari, Finans, Stok, Satış
// ekranlarına tek dokunuşla geçiş sağlar.
// ============================================================

import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'cari_kart_ekle_screen.dart';
import 'finans_islem_screen.dart';
import 'stok_yonetim_screen.dart';
import 'satis_fatura_screen.dart';
import 'ihracat_sevkiyat_screen.dart';
import '../services/auth_service.dart';
import '../services/opening_balance_service.dart';
import 'onboarding/first_time_setup_screen.dart';
import 'billing/module_store_screen.dart';
import 'migration/data_migration_screen.dart';
import 'legislation/legislation_library_screen.dart';
import '../widgets/dashboard/global_information_center.dart';
import '../widgets/ai/nakhl_assistant_drawer.dart';
import '../core/i18n/locale_script_manager.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/enterprise_ui_components.dart';
import '../widgets/dashboard/business_pulse_card.dart';
import '../widgets/dashboard/quick_actions_grid.dart';
import '../widgets/dashboard/task_center_card.dart';
import '../widgets/charts/universal_chart_engine.dart';
import 'presentation/management_presentation_studio_screen.dart';
import 'strategy/strategy_mind_map_screen.dart';
import 'approvals/approval_center_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic>? sirketVerisi;

  const DashboardScreen({super.key, this.sirketVerisi});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Kurumsal Renk Paleti
  static const Color hurmaKahvesi = Color(0xFF5C4033);
  static const Color hurmaKahvesiKoyu = Color(0xFF3E2723);
  static const Color altinSarisi = Color(0xFFC89033);

  int _seciliAltIndeks = 0;

  // Şirket Parametreleri
  late String _sirketKodu;
  late String _ulkeKodu;
  late String _birincilDil;
  String? _ikincilDil;

  @override
  void initState() {
    super.initState();
    _sirketKodu = widget.sirketVerisi?['sirketKisaltmasi'] ?? 'HGLTD';
    _ulkeKodu = widget.sirketVerisi?['ulkeKodu'] ?? 'SA';
    _birincilDil = widget.sirketVerisi?['birincilDil'] ?? 'TR';
    _ikincilDil = widget.sirketVerisi?['ikincilDil'] ?? 'AR';
  }

  void _altNavigasyonaGit(int index) {
    if (index == 0) return; // Zaten Dashboard'dayız

    String modulKey;
    switch (index) {
      case 1:
        modulKey = 'cari';
        break;
      case 2:
        modulKey = 'finans';
        break;
      case 3:
        modulKey = 'stok';
        break;
      case 4:
        modulKey = 'satis';
        break;
      default:
        modulKey = '';
    }

    if (!AuthService.instance.yetkiVarMi(modulKey)) {
      final rolBaslik =
          AuthService.instance.aktifProfil?.rol.baslik ?? 'Mevcut Rol';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '⚠️ Yetki Sınırı: "$rolBaslik" bu ekrana erişim yetkisine sahip değildir.'),
          backgroundColor: hurmaKahvesiKoyu,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _seciliAltIndeks = 0);
      return;
    }

    Widget hedefSayfa;
    switch (index) {
      case 1:
        hedefSayfa = CariKartEkleScreen(
          bizimSirketKisaltmamiz: _sirketKodu,
          varsayilanUlkeKodu: _ulkeKodu,
          birincilDil: _birincilDil,
          ikincilDil: _ikincilDil,
        );
      case 2:
        hedefSayfa = const FinansIslemScreen();
      case 3:
        hedefSayfa = const StokYonetimScreen();
      case 4:
        hedefSayfa = const SatisFaturaScreen();
      default:
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => hedefSayfa),
    ).then((_) {
      if (mounted) setState(() => _seciliAltIndeks = 0);
    });
  }

  void _yetkiliSayfayaGit(String modulKey, Widget sayfa) {
    if (!AuthService.instance.yetkiVarMi(modulKey)) {
      final rolBaslik =
          AuthService.instance.aktifProfil?.rol.baslik ?? 'Mevcut Rol';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '⚠️ Yetki Sınırı: "$rolBaslik" bu modüle erişim yetkisine sahip değildir.'),
          backgroundColor: hurmaKahvesiKoyu,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.spa_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NAKHL & NAHL ERP',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
                Text(
                  'İşletmenin Nabzı (${_sirketKodu.toUpperCase()})',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.co_present_rounded),
            tooltip: 'Yönetim Kurulu & Ortaklar Sunumu',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManagementPresentationStudioScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.hub_rounded),
            tooltip: 'Strateji / Zihin Haritası',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StrategyMindMapScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.fact_check_rounded),
            tooltip: 'Onay Merkezi (3 Bekliyor)',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ApprovalCenterScreen()),
              );
            },
          ),
          Builder(
            builder: (c) => IconButton(
              icon: const Icon(Icons.auto_awesome_rounded, color: AppColors.accent),
              tooltip: 'NAKHL Asistan (AI & 5N1K)',
              onPressed: () => Scaffold.of(c).openEndDrawer(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Yenile',
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      endDrawer: const NakhlAssistantDrawer(
        moduleName: 'dashboard',
        screenName: 'dashboard_main',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. "İŞLETMENİN NABZI" ANA BAŞLIK ALANI ──
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('İşletmenin Nabzı', style: AppTypography.pageTitle(color: AppColors.primary)),
                const SizedBox(height: 4),
                Text(
                  'Tüm operasyonlarınız tek ekranda. Bugünün durumu, yarının fırsatları.',
                  style: AppTypography.bodyMedium(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ── GLOBAL ZAMAN + TAKVİM + PİYASA BİLGİ PANELİ ──
            const GlobalInformationCenter(),
            const SizedBox(height: 20),

            // ── KURULUM EKSİKLİKLERİ UYARISI ──
            _kurulumEksikleriBanneri(),

            // ── 2. İŞLETME SAĞLIĞI & PULSE SKORU (82/100) ──
            const BusinessPulseCard(),
            const SizedBox(height: 20),

            // ── 3. ALTI TEMEL FİNANSAL KPI KARTI ──
            SectionHeader(
              title: 'Temel Finansal & Operasyonel Göstergeler',
              subtitle: 'Canlı veritabanı akışından anlık bakiye ve hacimler',
              icon: Icons.analytics_outlined,
            ),
            LayoutBuilder(
              builder: (ctx, constraints) {
                final isWide = constraints.maxWidth > 900;
                final crossCount = isWide ? 3 : (constraints.maxWidth > 600 ? 2 : 1);

                return GridView.count(
                  crossAxisCount: crossCount,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: isWide ? 2.1 : 2.4,
                  children: const [
                    KpiCard(
                      title: 'Kasa Bakiyesi',
                      value: '₺248.500',
                      icon: Icons.account_balance_wallet_rounded,
                      iconColor: AppColors.primary,
                      changePercent: 12.4,
                      comparisonPeriod: 'Geçen aya göre',
                    ),
                    KpiCard(
                      title: 'Banka Mevduatı',
                      value: '₺1.120.000',
                      icon: Icons.account_balance_rounded,
                      iconColor: AppColors.secondary,
                      changePercent: 8.1,
                      comparisonPeriod: 'Geçen aya göre',
                    ),
                    KpiCard(
                      title: 'Alacaklar (Müşteri)',
                      value: '₺680.300',
                      icon: Icons.trending_up_rounded,
                      iconColor: AppColors.info,
                      changePercent: -3.2,
                      comparisonPeriod: 'Geçen haftaya göre',
                    ),
                    KpiCard(
                      title: 'Borçlar (Tedarikçi)',
                      value: '₺312.400',
                      icon: Icons.trending_down_rounded,
                      iconColor: AppColors.warning,
                      changePercent: -5.0,
                      comparisonPeriod: 'Planlanan vadelere göre',
                    ),
                    KpiCard(
                      title: 'Bugünkü Satış',
                      value: '₺84.600',
                      icon: Icons.point_of_sale_rounded,
                      iconColor: AppColors.secondary,
                      changePercent: 18.2,
                      comparisonPeriod: 'Düne göre',
                    ),
                    KpiCard(
                      title: 'Toplam Stok Değeri',
                      value: '₺2.450.000',
                      icon: Icons.inventory_2_rounded,
                      iconColor: AppColors.accentDark,
                      changePercent: 2.1,
                      comparisonPeriod: '78.5 Ton Hurma & Paket',
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // ── 4. ANALİTİK GRAFİKLER (NAKİT AKIŞI & SATIŞ VE HEDEF) ──
            LayoutBuilder(
              builder: (ctx, constraints) {
                final isWide = constraints.maxWidth > 900;
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Expanded(
                        flex: 6,
                        child: UniversalChartEngine(
                          title: '12 Aylık Nakit Akışı (Giriş / Çıkış / Net)',
                          subtitle: 'Son 12 ayın kümülatif nakit hareket eğilimi',
                          type: UniversalChartType.area,
                          data: [
                            ChartDataPoint(label: 'Eki', value: 320),
                            ChartDataPoint(label: 'Kas', value: 410),
                            ChartDataPoint(label: 'Ara', value: 390),
                            ChartDataPoint(label: 'Oca', value: 520),
                            ChartDataPoint(label: 'Şub', value: 480),
                            ChartDataPoint(label: 'Mar', value: 650),
                            ChartDataPoint(label: 'Nis', value: 710),
                            ChartDataPoint(label: 'May', value: 680),
                            ChartDataPoint(label: 'Haz', value: 820),
                            ChartDataPoint(label: 'Tem', value: 790),
                            ChartDataPoint(label: 'Ağu', value: 910),
                            ChartDataPoint(label: 'Eyl', value: 980),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        flex: 4,
                        child: UniversalChartEngine(
                          title: 'Satış ve Hedef (Actual vs Target)',
                          subtitle: 'Çeyrek bazlı satış gerçekleşme performansı',
                          type: UniversalChartType.bar,
                          data: [
                            ChartDataPoint(label: 'Q1 Hedef', value: 600, color: AppColors.primary),
                            ChartDataPoint(label: 'Q1 Gerçek', value: 680, color: AppColors.secondary),
                            ChartDataPoint(label: 'Q2 Hedef', value: 750, color: AppColors.primary),
                            ChartDataPoint(label: 'Q2 Gerçek', value: 820, color: AppColors.secondary),
                            ChartDataPoint(label: 'Q3 Hedef', value: 900, color: AppColors.primary),
                            ChartDataPoint(label: 'Q3 Gerçek', value: 980, color: AppColors.secondary),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: const [
                      UniversalChartEngine(
                        title: '12 Aylık Nakit Akışı (Giriş / Çıkış / Net)',
                        subtitle: 'Son 12 ayın kümülatif nakit hareket eğilimi',
                        type: UniversalChartType.area,
                        data: [
                          ChartDataPoint(label: 'Eki', value: 320),
                          ChartDataPoint(label: 'Ara', value: 390),
                          ChartDataPoint(label: 'Şub', value: 480),
                          ChartDataPoint(label: 'Nis', value: 710),
                          ChartDataPoint(label: 'Haz', value: 820),
                          ChartDataPoint(label: 'Ağu', value: 910),
                          ChartDataPoint(label: 'Eyl', value: 980),
                        ],
                      ),
                      SizedBox(height: 16),
                      UniversalChartEngine(
                        title: 'Satış ve Hedef (Actual vs Target)',
                        subtitle: 'Çeyrek bazlı satış gerçekleşme performansı',
                        type: UniversalChartType.bar,
                        data: [
                          ChartDataPoint(label: 'Q1', value: 680, color: AppColors.secondary),
                          ChartDataPoint(label: 'Q2', value: 820, color: AppColors.secondary),
                          ChartDataPoint(label: 'Q3', value: 980, color: AppColors.secondary),
                        ],
                      ),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 20),

            // ── 5. ALACAK YAŞLANDIRMA & STOK RİSK ISI HARİTASI ──
            LayoutBuilder(
              builder: (ctx, constraints) {
                final isWide = constraints.maxWidth > 900;
                return isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Expanded(
                            flex: 5,
                            child: UniversalChartEngine(
                              title: 'Alacak Yaşlandırma Analizi',
                              subtitle: '0-30, 31-60, 61-90, 91+ gün vade dağılımı',
                              type: UniversalChartType.aging,
                              data: [
                                ChartDataPoint(label: '0-30 Gün (Düşük Risk)', value: 410000, color: AppColors.success),
                                ChartDataPoint(label: '31-60 Gün (Orta Risk)', value: 160000, color: AppColors.info),
                                ChartDataPoint(label: '61-90 Gün (Yüksek Risk)', value: 75000, color: AppColors.warning),
                                ChartDataPoint(label: '91+ Gün (Kritik Takip)', value: 35300, color: AppColors.danger),
                              ],
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            flex: 5,
                            child: UniversalChartEngine(
                              title: 'Stok Risk Analizi (Isı Haritası)',
                              subtitle: 'Ürün kategorisi ve depo güvenli stok seviyesi',
                              type: UniversalChartType.heatmap,
                              data: [
                                ChartDataPoint(label: 'Medjool Jumbo 1kg', value: 85),
                                ChartDataPoint(label: 'Sukari Lüks 500g', value: 65),
                                ChartDataPoint(label: 'Ajwa Özel Kutu', value: 18), // Kritik
                                ChartDataPoint(label: 'Safawi Toptan Kasa', value: 42),
                                ChartDataPoint(label: 'Mabroom Standart', value: 14), // Kritik
                                ChartDataPoint(label: 'Deglet Noor 2kg', value: 78),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: const [
                          UniversalChartEngine(
                            title: 'Alacak Yaşlandırma Analizi',
                            subtitle: '0-30, 31-60, 61-90, 91+ gün vade dağılımı',
                            type: UniversalChartType.aging,
                            data: [
                              ChartDataPoint(label: '0-30 Gün', value: 410000, color: AppColors.success),
                              ChartDataPoint(label: '31-60 Gün', value: 160000, color: AppColors.info),
                              ChartDataPoint(label: '61-90 Gün', value: 75000, color: AppColors.warning),
                              ChartDataPoint(label: '91+ Gün', value: 35300, color: AppColors.danger),
                            ],
                          ),
                          SizedBox(height: 16),
                          UniversalChartEngine(
                            title: 'Stok Risk Analizi (Isı Haritası)',
                            subtitle: 'Ürün kategorisi ve depo güvenli stok seviyesi',
                            type: UniversalChartType.heatmap,
                            data: [
                              ChartDataPoint(label: 'Medjool Jumbo', value: 85),
                              ChartDataPoint(label: 'Ajwa Kutu', value: 18),
                              ChartDataPoint(label: 'Mabroom Kasa', value: 14),
                            ],
                          ),
                        ],
                      );
              },
            ),
            const SizedBox(height: 24),

            // ── 6. HIZLI İŞLEMLER PANELİ ──
            QuickActionsGrid(
              onActionSelected: (key) {
                switch (key) {
                  case 'satis':
                  case 'fatura':
                    _yetkiliSayfayaGit('satis', const SatisFaturaScreen());
                    break;
                  case 'tahsilat':
                  case 'odeme':
                    _yetkiliSayfayaGit('finans', const FinansIslemScreen());
                    break;
                  case 'stok_girisi':
                    _yetkiliSayfayaGit('stok', const StokYonetimScreen());
                    break;
                  case 'yeni_musteri':
                  case 'yeni_tedarikci':
                  case 'cari_islem':
                    _altNavigasyonaGit(1);
                    break;
                  case 'alis':
                  case 'yeni_siparis':
                    _yetkiliSayfayaGit('ihracat', const IhracatSevkiyatScreen());
                    break;
                }
              },
            ),
            const SizedBox(height: 20),

            // ── 7. BUGÜN NE YAPMALIYIM? GÖREV MERKEZİ ──
            const TaskCenterCard(),
            const SizedBox(height: 24),

            // ── 8. CANLI AKIŞ: SON FATURALAR & SEVKİYATLAR ──
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Son Kesilen Faturalar (Canlı Akış)', style: AppTypography.cardTitle()),
                            const SizedBox(height: 10),
                            _sonFaturalarCanliListesi(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Aktif Sevkiyatlar & Lojistik', style: AppTypography.cardTitle()),
                            const SizedBox(height: 10),
                            _sonSevkiyatlarCanliListesi(),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Son Kesilen Faturalar (Canlı Akış)', style: AppTypography.cardTitle()),
                      const SizedBox(height: 10),
                      _sonFaturalarCanliListesi(),
                      const SizedBox(height: 20),
                      Text('Aktif Sevkiyatlar & Lojistik', style: AppTypography.cardTitle()),
                      const SizedBox(height: 10),
                      _sonSevkiyatlarCanliListesi(),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 24),

            // ── 9. SAAS VE VERİ AKTARIM SİHİRBAZI ──
            _ticariSaaSVeVeriAktarimBanneri(),
            const SizedBox(height: 30),
          ],
        ),
      ),

      bottomNavigationBar: _altNavigasyonBari(),
    );
  }

  // ============================================================
  // BİLEŞEN: KURULUM EKSİKLERİ BANNERI
  // ============================================================

  Widget _kurulumEksikleriBanneri() {
    final deficiencies = OpeningBalanceService.instance.getSetupDeficiencies();
    if (deficiencies.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade400, width: 1.5),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 24),
              const SizedBox(width: 8),
              const Text(
                'İşletme Kurulum Eksiklikleri:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF5C4033)),
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: hurmaKahvesi,
                  foregroundColor: altinSarisi,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FirstTimeSetupScreen(
                        onSetupCompleted: () => setState(() {}),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.rocket_launch, size: 14),
                label: const Text('Sihirbazla Tamamla', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...deficiencies.map((d) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_right, size: 18, color: Colors.deepOrange),
                    Text(d, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ============================================================
  // BİLEŞEN: SON FATURALAR CANLI LİSTESİ
  // ============================================================

  Widget _sonFaturalarCanliListesi() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: SupabaseService.client
          .from('journal_entries')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .limit(3),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator()));
        }

        final docs = snapshot.data ?? [];

        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: const Center(
              child: Text(
                'Henüz kayıtlı fatura bulunmuyor. "Yeni Fatura" ile oluşturabilirsiniz.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final faturaNo =
                doc['faturaNo'] ?? doc['entry_number'] ?? 'FAT-???';
            final cari = doc['cariUnvani'] ?? doc['description'] ?? 'Cari';
            final toplam = (doc['genelToplam'] as num?)?.toDouble() ??
                (doc['total_debit'] as num?)?.toDouble() ??
                0.0;
            final pb = doc['paraBirimi'] ?? doc['currency'] ?? 'SAR';
            final durum = doc['durum'] ??
                (doc['status'] == 'POSTED' ? 'Onaylandı' : 'Taslak');
            final onayli = durum == 'Onaylandı';

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0.5,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      onayli ? Colors.green.shade100 : Colors.amber.shade100,
                  child: Icon(
                    onayli
                        ? Icons.verified_rounded
                        : Icons.pending_actions_rounded,
                    color:
                        onayli ? Colors.green.shade800 : Colors.amber.shade800,
                    size: 20,
                  ),
                ),
                title: Text(cari,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13.5)),
                subtitle: Text('$faturaNo  •  $durum',
                    style: const TextStyle(fontSize: 11)),
                trailing: Text(
                  '${toplam.toStringAsFixed(2)} $pb',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: hurmaKahvesi),
                ),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SatisFaturaScreen())),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ============================================================
  // BİLEŞEN: SON SEVKİYATLAR CANLI LİSTESİ
  // ============================================================

  Widget _sonSevkiyatlarCanliListesi() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: SupabaseService.client
          .from('shipments')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .limit(3),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator()));
        }

        final docs = snapshot.data ?? [];

        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: const Center(
              child: Text(
                'Kayıtlı sevkiyat bulunmuyor. "İhracat & Lojistik" ekranından ekleyebilirsiniz.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final musteri = doc['cariUnvani'] ??
                doc['carrier_name'] ??
                'Bilinmeyen Müşteri';
            final urun = doc['urunCesidi'] ?? 'Hurma';
            final durum =
                doc['sevkiyatDurumu'] ?? doc['status'] ?? 'Hazırlanıyor';
            final liman =
                doc['cikisLimani'] ?? doc['port_of_loading'] ?? 'Liman';
            final miktar = (doc['miktar'] as num?)?.toDouble() ?? 0.0;
            final birim = doc['birim'] ?? 'Ton';

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0.5,
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEDE7F6),
                  child: Icon(Icons.local_shipping_rounded,
                      color: Color(0xFF6A1B9A), size: 20),
                ),
                title: Text(musteri,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13.5)),
                subtitle: Text('$urun ($miktar $birim)  •  $liman',
                    style: const TextStyle(fontSize: 11)),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: Text(
                    durum,
                    style: TextStyle(
                        color: Colors.purple.shade900,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const IhracatSevkiyatScreen())),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ============================================================
  // BİLEŞEN: TİCARİ MODÜL MAĞAZASI & VERİ AKTARIMI HIZLI ERİŞİM
  // ============================================================

  Widget _ticariSaaSVeVeriAktarimBanneri() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: altinSarisi.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: altinSarisi.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: altinSarisi.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.rocket_launch_rounded,
                color: altinSarisi, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SaaS Paketleri & Veri Aktarımı',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: hurmaKahvesi),
                ),
                const SizedBox(height: 2),
                Text(
                  '18 ticari modül, çoklu para birimi ve Logo/Mikro/Excel aktarım sihirbazı.',
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: hurmaKahvesi,
              side: const BorderSide(color: hurmaKahvesi),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DataMigrationScreen()),
              );
            },
            icon: const Icon(Icons.drive_folder_upload_rounded, size: 16),
            label: const Text('Veri Aktar', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: hurmaKahvesi,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ModuleStoreScreen()),
              );
            },
            icon: const Icon(Icons.storefront_rounded, size: 16),
            label: const Text('Mağaza', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: hurmaKahvesi,
              side: const BorderSide(color: hurmaKahvesi),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LegislationLibraryScreen()),
              );
            },
            icon: const Icon(Icons.gavel_rounded, size: 16),
            label: const Text('Mevzuat', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BİLEŞEN: ALT NAVİGASYON MENÜSÜ (BOTTOM NAVIGATION)
  // ============================================================

  Widget _altNavigasyonBari() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _seciliAltIndeks,
        onTap: _altNavigasyonaGit,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: hurmaKahvesi,
        unselectedItemColor: Colors.grey.shade500,
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 10.5),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_rounded),
            label: context.tr('menu.dashboard', fallback: 'Panel'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people_alt_rounded),
            label: context.tr('menu.customers', fallback: 'Cariler'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_wallet_rounded),
            label: context.tr('menu.finance', fallback: 'Finans'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.inventory_2_rounded),
            label: context.tr('menu.product', fallback: 'Ürün'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.point_of_sale_rounded),
            label: context.tr('menu.sales', fallback: 'Satış'),
          ),
        ],

      ),
    );
  }
}
