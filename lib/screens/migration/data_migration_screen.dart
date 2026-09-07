// ==============================================================================
// NAKHL & NAHL — COMMERCIAL DATA MIGRATION SCREEN
// File: lib/screens/migration/data_migration_screen.dart
// 5-Step Wizard: Source -> Staging -> Validation (Traffic Light) -> Preview -> Ingest
// ==============================================================================

import 'package:flutter/material.dart';
import '../../services/migration/data_migration_service.dart';

class DataMigrationScreen extends StatefulWidget {
  const DataMigrationScreen({super.key});

  @override
  State<DataMigrationScreen> createState() => _DataMigrationScreenState();
}

class _DataMigrationScreenState extends State<DataMigrationScreen> {
  static const Color hurmaKahvesi = Color(0xFF5C4033);
  static const Color altinSarisi = Color(0xFFC89033);
  static const Color yesilBasari = Color(0xFF2E7D32);
  static const Color sariUyari = Color(0xFFF57F17);
  static const Color kirmiziHata = Color(0xFFC62828);

  int _currentStep = 0;
  MigrationSourceSystem _selectedSource = MigrationSourceSystem.excel;
  MigrationTargetEntity _selectedTarget = MigrationTargetEntity.customers;
  final TextEditingController _contentController = TextEditingController();
  final String _fileName = 'veri_aktarim_listesi.csv';

  bool _isProcessing = false;
  DataMigrationJob? _activeJob;
  List<MigrationStagingRow> _stagingRows = [];
  String? _executionResult;

  @override
  void initState() {
    super.initState();
    _loadSampleContent();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _loadSampleContent() {
    if (_selectedTarget == MigrationTargetEntity.customers) {
      _contentController.text =
          'cari_kod,cari_unvan,vergi_no,telefon,eposta,bakiye\n'
          'C001,Marmara Hurma İthalat Ltd.,1234567890,+905551234567,info@marmarahurma.com,15000\n'
          'C002,Hicaz Gıda Dağıtım A.Ş.,9876543210,+905329876543,muhasebe@hicazgida.com,24500\n'
          'C003,Medine Soğuk Hava Deposu,,+905441112233,depo@medinesoguk.com,0\n'
          'C004,,1112223334,+905001112233,hatali@domain.com,-5000\n';
    } else if (_selectedTarget == MigrationTargetEntity.products) {
      _contentController.text =
          'barkod,urun_adi,birim,fiyat,stok_miktari\n'
          '8680001001,Acve Hurması 1. Kalite 1kg,KG,450.00,120\n'
          '8680001002,Mebrum Lüks Hurma 500g,ADET,180.00,350\n'
          '8680001003,Sugai Hurma Dökme Koli,KOLI,,45\n'
          ',İsimsiz Barkodsuz Ürün,ADET,50.00,10\n';
    } else {
      _contentController.text =
          'kod,ad,tutar,aciklama\n'
          'A01,Açılış Kaydı 1,10000,2026 Dönem Başı Bakiyesi\n';
    }
  }

  Future<void> _processStaging() async {
    final text = _contentController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen aktarılacak veriyi girin.')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    final job = await DataMigrationService.instance.stageFileContent(
      rawContent: text,
      fileName: _fileName,
      sourceSystem: _selectedSource,
      targetEntity: _selectedTarget,
    );

    if (job != null) {
      final rows =
          await DataMigrationService.instance.getStagingRows(job.id);
      setState(() {
        _activeJob = job;
        _stagingRows = rows;
        _currentStep = 2; // Move to validation & preview
        _isProcessing = false;
      });
    } else {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Veri ayrıştırılamadı. Formatı kontrol edin.')),
        );
      }
    }
  }

  Future<void> _executeIngestion() async {
    if (_activeJob == null) return;
    setState(() => _isProcessing = true);

    final res = await DataMigrationService.instance
        .executeBatchIngestion(_activeJob!.id);

    setState(() {
      _isProcessing = false;
      if (res['success'] == true) {
        _executionResult =
            'Başarıyla Aktarıldı: ${res['imported_count']} kayıt canlı sisteme işlendi.';
        _currentStep = 4;
      } else {
        _executionResult = 'Hata: ${res['error']}';
      }
    });
  }

  Future<void> _rollback() async {
    if (_activeJob == null) return;
    setState(() => _isProcessing = true);
    await DataMigrationService.instance.rollbackJob(_activeJob!.id);
    setState(() {
      _isProcessing = false;
      _executionResult = 'Aktarım geri alındı (Rollback tamamlandı).';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F2),
      appBar: AppBar(
        title: const Text('Veri Aktarımı & Geçiş Sihirbazı',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: hurmaKahvesi,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Örnek Veriyi Yenile',
            onPressed: () {
              _loadSampleContent();
              setState(() {
                _activeJob = null;
                _stagingRows = [];
                _currentStep = 0;
                _executionResult = null;
              });
            },
          )
        ],
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: altinSarisi),
                  SizedBox(height: 16),
                  Text('Veriler güvenli tampon bölgede işleniyor...'),
                ],
              ),
            )
          : Stepper(
              currentStep: _currentStep,
              onStepTapped: (step) {
                if (step <= _currentStep) setState(() => _currentStep = step);
              },
              controlsBuilder: (context, details) => const SizedBox.shrink(),
              steps: [
                Step(
                  title: const Text('1. Kaynak ve Hedef Seçimi'),
                  subtitle: const Text('Aktarılacak veri kaynağı ve türü'),
                  isActive: _currentStep >= 0,
                  state:
                      _currentStep > 0 ? StepState.complete : StepState.indexed,
                  content: _buildStep1SourceSelection(),
                ),
                Step(
                  title: const Text('2. Veri Yükleme & Tampon Bellek'),
                  subtitle:
                      const Text('CSV/Excel içeriğini yapıştırın veya yükleyin'),
                  isActive: _currentStep >= 1,
                  state:
                      _currentStep > 1 ? StepState.complete : StepState.indexed,
                  content: _buildStep2DataUpload(),
                ),
                Step(
                  title: const Text('3. Trafik Işığı Doğrulaması & Eşleme'),
                  subtitle: const Text('Yeşil (Geçerli), Sarı (Uyarı), Kırmızı (Hata)'),
                  isActive: _currentStep >= 2,
                  state:
                      _currentStep > 2 ? StepState.complete : StepState.indexed,
                  content: _buildStep3ValidationPreview(),
                ),
                Step(
                  title: const Text('4. Canlı Sisteme Aktarım (Atomik)'),
                  subtitle: const Text('Doğrulanmış kayıtları kalıcı kaydet'),
                  isActive: _currentStep >= 3,
                  state:
                      _currentStep > 3 ? StepState.complete : StepState.indexed,
                  content: _buildStep4Ingestion(),
                ),
                Step(
                  title: const Text('5. Sonuç & Geri Alma'),
                  subtitle: const Text('İşlem özeti ve denetim kaydı'),
                  isActive: _currentStep >= 4,
                  state:
                      _currentStep >= 4 ? StepState.complete : StepState.indexed,
                  content: _buildStep5Summary(),
                ),
              ],
            ),
    );
  }

  Widget _buildStep1SourceSelection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Eski Muhasebe / ERP Programınız:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            DropdownButtonFormField<MigrationSourceSystem>(
              value: _selectedSource,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: MigrationSourceSystem.values.map((s) {
                return DropdownMenuItem(value: s, child: Text(s.label));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedSource = val);
              },
            ),
            const SizedBox(height: 20),
            const Text('Aktarılacak Veri Türü:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            DropdownButtonFormField<MigrationTargetEntity>(
              value: _selectedTarget,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: MigrationTargetEntity.values.map((e) {
                return DropdownMenuItem(value: e, child: Text(e.label));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedTarget = val;
                    _loadSampleContent();
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: hurmaKahvesi,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () => setState(() => _currentStep = 1),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Devam Et: Veri Yükle'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStep2DataUpload() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ham Veri Metni (CSV / Sekmeyle Ayrılmış / JSON):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Eski programınızdan dışa aktardığınız metni buraya yapıştırabilir veya hazır şablonu inceleyebilirsiniz:',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              maxLines: 8,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                hintText: 'Kolon1,Kolon2,Kolon3...',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: altinSarisi,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  onPressed: _processStaging,
                  icon: const Icon(Icons.shield_outlined),
                  label: const Text('Tampon Belleğe Al ve Doğrula'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => setState(() => _currentStep = 0),
                  child: const Text('Geri'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStep3ValidationPreview() {
    final valid = _activeJob?.validRows ?? 0;
    final warning = _activeJob?.warningRows ?? 0;
    final error = _activeJob?.errorRows ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Trafik Işığı Rozetleri
        Row(
          children: [
            _buildBadge('Yeşil (Sorunsuz)', valid, yesilBasari, Icons.check_circle),
            const SizedBox(width: 8),
            _buildBadge('Sarı (Uyarı)', warning, sariUyari, Icons.warning_amber),
            const SizedBox(width: 8),
            _buildBadge('Kırmızı (Hata)', error, kirmiziHata, Icons.cancel),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Tampon Tablo Kayıtları (Staging Buffer):',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Container(
          height: 260,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ListView.separated(
            itemCount: _stagingRows.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, idx) {
              final row = _stagingRows[idx];
              Color statusColor = yesilBasari;
              if (row.validationStatus == ValidationTrafficLight.yellow) {
                statusColor = sariUyari;
              } else if (row.validationStatus == ValidationTrafficLight.red) {
                statusColor = kirmiziHata;
              }

              final payload = row.mappedPayload;
              final title = payload['name'] ?? payload['code'] ?? 'Satır ${row.rowNumber}';
              final sub = payload.entries
                  .map((e) => '${e.key}: ${e.value}')
                  .take(3)
                  .join(' | ');

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.15),
                  child: Text(
                    '${row.rowNumber}',
                    style: TextStyle(
                        color: statusColor, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(title.toString(),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sub,
                        style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    if (row.validationMessages.isNotEmpty)
                      Text(
                        row.validationMessages.join(', '),
                        style: TextStyle(
                            fontSize: 11,
                            color: statusColor,
                            fontWeight: FontWeight.w500),
                      ),
                  ],
                ),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    row.validationStatus.code,
                    style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: hurmaKahvesi,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () => setState(() => _currentStep = 3),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Devam Et: Aktarım Onayı'),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: () => setState(() => _currentStep = 1),
              child: const Text('Geri'),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildStep4Ingestion() {
    final valid = _activeJob?.validRows ?? 0;
    final warning = _activeJob?.warningRows ?? 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.verified, color: yesilBasari, size: 28),
                SizedBox(width: 8),
                Text('Canlı Sisteme Aktarım Onayı',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Toplam ${valid + warning} kayıt canlı ERP tablolarına aktarılmaya hazır. '
              'Tüm aktarımlar atomik bir oturum içinde gerçekleştirilir ve istenirse geri alınabilir.',
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: yesilBasari,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                  ),
                  onPressed: _executeIngestion,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Şimdi Aktarımı Başlat',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => setState(() => _currentStep = 2),
                  child: const Text('Önizlemeye Dön'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStep5Summary() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.task_alt, color: yesilBasari, size: 28),
                SizedBox(width: 8),
                Text('İşlem Tamamlandı',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _executionResult ?? 'Aktarım başarıyla tamamlandı.',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hurmaKahvesi,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.home),
                  label: const Text('Ana Ekrana Dön'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: kirmiziHata),
                  onPressed: _rollback,
                  icon: const Icon(Icons.undo),
                  label: const Text('Aktarımı Geri Al (Rollback)'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String title, int count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
                Text('$count',
                    style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.w900)),
              ],
            )
          ],
        ),
      ),
    );
  }
}
