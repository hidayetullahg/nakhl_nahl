// ============================================================
// SUPABASE BAĞLANTILI CARİ KART YÖNETİMİ (CORE DATABASE v1.0)
// ============================================================
import 'package:flutter/material.dart';
import '../models/cari_kart_model.dart';
import '../repositories/cari_repository.dart';
import '../core/tenant/tenant_context.dart';
import '../widgets/help/help_tooltip.dart';
import '../widgets/help/form_field_help_icon.dart';
import '../widgets/address_picker_dialog.dart';

class CariKartEkleScreen extends StatefulWidget {
  final String? bizimSirketKisaltmamiz;
  final String? varsayilanUlkeKodu;
  final String? birincilDil;
  final String? ikincilDil;

  const CariKartEkleScreen({
    super.key,
    this.bizimSirketKisaltmamiz,
    this.varsayilanUlkeKodu,
    this.birincilDil,
    this.ikincilDil,
  });

  @override
  State<CariKartEkleScreen> createState() => _CariKartEkleScreenState();
}

class _CariKartEkleScreenState extends State<CariKartEkleScreen> {
  final TextEditingController _unvanController = TextEditingController();
  final TextEditingController _vergiNoController = TextEditingController();
  final TextEditingController _telefonController = TextEditingController();
  final TextEditingController _adresController = TextEditingController();
  final TextEditingController _cariKoduController = TextEditingController();
  final TextEditingController _epostaController = TextEditingController();

  String _secilenCariTipi = 'Musteri';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _cariKoduController.text =
        'CAR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
  }

  @override
  void dispose() {
    _unvanController.dispose();
    _vergiNoController.dispose();
    _telefonController.dispose();
    _adresController.dispose();
    _cariKoduController.dispose();
    _epostaController.dispose();
    super.dispose();
  }

  Future<void> _supabaseKaydet() async {
    if (_unvanController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Lütfen Cari Ünvanını / Şirket Adını giriniz.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final yeniCari = CariKart(
        cariKodu: _cariKoduController.text.trim(),
        unvan: _unvanController.text.trim(),
        cariTipi: _secilenCariTipi,
        vergiNo: _vergiNoController.text.trim(),
        sirketTelefonu: _telefonController.text.trim(),
        faturaAdresi: _adresController.text.trim(),
        eposta: _epostaController.text.trim(),
        ulkeKodu: 'SA',
        ulkeAdi: 'Suudi Arabistan',
        paraBirimi: 'SAR',
        vergiTipi: 'TRN',
        kdvOrani: '%15',
      );

      // CariRepository üzerinden RLS ve tenant_id korumalı kayıt
      await CariRepository.instance.cariKaydet(yeniCari);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF2E7D32),
          content:
              Text('Cari kart başarıyla Supabase Core Database\'e kaydedildi!'),
        ),
      );

      _unvanController.clear();
      _vergiNoController.clear();
      _telefonController.clear();
      _adresController.clear();
      _epostaController.clear();
      setState(() {
        _cariKoduController.text =
            'CAR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade800,
          content: Text('Kayıt hatası: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenantId =
        TenantContext.instance.activeTenantId ?? 'Varsayılan Tenant';

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F1), // Krem Teması
      appBar: AppBar(
        backgroundColor: const Color(0xFF5C4033), // Hurma Kahvesi
        title: const Text('NAKHL&NAHL — Supabase Cari Kart',
            style: TextStyle(color: Colors.amberAccent)),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: HelpTooltip(route: '/customers', iconColor: Colors.amberAccent),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security, color: Color(0xFF5C4033)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tenant İzolasyonu Aktif (RLS): $tenantId',
                      style: const TextStyle(
                          color: Color(0xFF5C4033),
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _cariKoduController,
              decoration: const InputDecoration(
                labelText: 'Cari Hesap Kodu',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.qr_code),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _unvanController,
              decoration: const InputDecoration(
                labelText: 'Şirket Resmi Unvanı / Adı Soyadı *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _secilenCariTipi,
              decoration: const InputDecoration(
                labelText: 'Cari Hesap Türü',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                    value: 'Musteri', child: Text('Müşteri (Customer)')),
                DropdownMenuItem(
                    value: 'Tedarikci', child: Text('Tedarikçi (Supplier)')),
                DropdownMenuItem(
                    value: 'MusteriTedarikci',
                    child: Text('Müşteri & Tedarikçi')),
              ],
              onChanged: (val) => setState(() => _secilenCariTipi = val!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _vergiNoController,
              decoration: InputDecoration(
                labelText: 'Vergi Numarası / TCKN',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.receipt),
                suffixIcon: FormFieldHelpIcon.vkn(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _telefonController,
              decoration: const InputDecoration(
                labelText: 'Telefon Numarası',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _epostaController,
              decoration: const InputDecoration(
                labelText: 'E-Posta Adresi',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Fatura Adresi & Lokasyon',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF5C4033)),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.list_alt_rounded, size: 16, color: Color(0xFF5C4033)),
                  label: const Text('Listeden Adres Seç', style: TextStyle(color: Color(0xFF5C4033), fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    final res = await AddressPickerDialog.show(
                      context,
                      initialCountryCode: widget.varsayilanUlkeKodu ?? 'SA',
                    );
                    if (res != null) {
                      setState(() {
                        _adresController.text = res.fullAddress;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _adresController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Açık Fatura Adresi / Lokasyon',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5C4033),
                foregroundColor: Colors.amberAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _isSaving ? null : _supabaseKaydet,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.amberAccent, strokeWidth: 2))
                  : const Icon(Icons.save),
              label: Text(
                _isSaving ? 'Kaydediliyor...' : 'Cari Kartı Supabase\'e Kaydet',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
