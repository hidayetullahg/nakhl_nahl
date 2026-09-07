import 'package:flutter/material.dart';
import '../repositories/tenant_repository.dart';
import '../repositories/company_repository.dart';
import '../core/tenant/tenant_context.dart';
import '../services/opening_balance_service.dart';
import 'dashboard_screen.dart';
import 'onboarding/first_time_setup_screen.dart';

class TenantSelectionScreen extends StatefulWidget {
  const TenantSelectionScreen({super.key});

  @override
  State<TenantSelectionScreen> createState() => _TenantSelectionScreenState();
}

class _TenantSelectionScreenState extends State<TenantSelectionScreen> {
  static const Color hurmaKahvesi = Color(0xFF5C4033);
  static const Color kremArkaplan = Color(0xFFFBF9F1);
  static const Color altinSarisi = Color(0xFFC89033);

  bool _yukleniyor = true;
  List<Tenant> _tenants = [];
  Tenant? _secilenTenant;
  List<Company> _companies = [];
  Company? _secilenCompany;

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  Future<void> _verileriYukle() async {
    setState(() => _yukleniyor = true);
    final tenants = await TenantRepository.instance.getUserTenants();
    setState(() {
      _tenants = tenants;
      if (tenants.isNotEmpty) {
        _secilenTenant = tenants.first;
      }
      _yukleniyor = false;
    });

    if (_secilenTenant != null) {
      await _sirketleriYukle(_secilenTenant!.id);
    }
  }

  Future<void> _sirketleriYukle(String tenantId) async {
    final companies = await CompanyRepository.instance.getCompanies(tenantId);
    setState(() {
      _companies = companies;
      _secilenCompany = companies.isNotEmpty ? companies.first : null;
    });
  }

  void _sistemeGirisYap() {
    if (_secilenTenant == null) return;

    TenantContext.instance.setActiveTenant(
      tenantId: _secilenTenant!.id,
      tenantCode: _secilenTenant!.code,
      companyId: _secilenCompany?.id,
      companyName: _secilenCompany?.legalName,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DashboardScreen(
          sirketVerisi: {
            'sirketKisaltmasi': _secilenCompany?.code ?? _secilenTenant!.code,
            'sirketAdi':
                _secilenCompany?.legalName ?? _secilenTenant!.displayName,
            'ulkeKodu': _secilenTenant!.countryCode,
            'paraBirimi': _secilenCompany?.currencyCode ??
                _secilenTenant!.defaultCurrencyCode,
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kremArkaplan,
      appBar: AppBar(
        backgroundColor: hurmaKahvesi,
        title: const Text('NAKHL & NAHL — Şirket Seçimi',
            style: TextStyle(color: altinSarisi, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: _yukleniyor
            ? const CircularProgressIndicator(color: hurmaKahvesi)
            : Container(
                width: 450,
                padding: const EdgeInsets.all(28),
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 15,
                        offset: Offset(0, 5))
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.business_center_rounded,
                        size: 54, color: hurmaKahvesi),
                    const SizedBox(height: 16),
                    const Text(
                      'Çalışma Alanınızı Seçiniz',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: hurmaKahvesi),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Yetkili olduğunuz grup veya şirketi belirleyerek devam ediniz.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    if (_tenants.isEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange, size: 28),
                            SizedBox(height: 8),
                            Text(
                              'Henüz kayıtlı bir işletmeniz bulunmuyor.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Yeni bir şirket kurabilir veya test amaçlı demo şirketi açabilirsiniz.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.black54, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hurmaKahvesi,
                          foregroundColor: altinSarisi,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FirstTimeSetupScreen(
                                onSetupCompleted: () {
                                  _verileriYukle();
                                },
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.rocket_launch_rounded),
                        label: const Text('✨ Yeni İşletme Kur (İlk Kurulum Sihirbazı)',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: hurmaKahvesi,
                          side: const BorderSide(color: hurmaKahvesi),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _demoGirisYap,
                        icon: const Icon(Icons.play_circle_fill_rounded),
                        label: const Text('🌟 Demo İşletmeyle Hemen Başla (HGLTD)',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                    ] else ...[
                      DropdownButtonFormField<Tenant>(
                        value: _secilenTenant,
                        decoration: const InputDecoration(
                          labelText: 'Kiracı / Grup (Tenant)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.corporate_fare),
                        ),
                        items: _tenants
                            .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text('${t.displayName} (${t.code})')))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _secilenTenant = val);
                            _sirketleriYukle(val.id);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<Company>(
                        value: _secilenCompany,
                        decoration: const InputDecoration(
                          labelText: 'Tüzel Şirket (Company)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.store),
                        ),
                        items: _companies
                            .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text('${c.legalName} (${c.code})')))
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _secilenCompany = val),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hurmaKahvesi,
                          foregroundColor: altinSarisi,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _sistemeGirisYap,
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Çalışma Alanına Gir',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: hurmaKahvesi,
                          side: const BorderSide(color: hurmaKahvesi),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FirstTimeSetupScreen(
                                onSetupCompleted: () {
                                  _verileriYukle();
                                },
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_business_rounded),
                        label: const Text('+ Yeni Şirket Kurulumu Başlat'),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  void _demoGirisYap() {
    TenantContext.instance.setActiveTenant(
      tenantId: '00000000-0000-0000-0000-000000000001',
      tenantCode: 'HGLTD',
      companyId: '00000000-0000-0000-0000-000000000002',
      companyName: 'Hidayetullah Global Ticaret Ltd.',
    );

    OpeningBalanceService.instance.initializeDemoSnapshot(currency: 'SAR');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const DashboardScreen(
          sirketVerisi: {
            'sirketKisaltmasi': 'HGLTD',
            'sirketAdi': 'Hidayetullah Global Ticaret Ltd.',
            'ulkeKodu': 'SA',
            'paraBirimi': 'SAR',
            'birincilDil': 'TR',
            'ikincilDil': 'AR',
          },
        ),
      ),
    );
  }
}
