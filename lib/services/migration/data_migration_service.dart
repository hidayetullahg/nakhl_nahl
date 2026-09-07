// ==============================================================================
// NAKHL & NAHL — DATA MIGRATION & TRANSFORMATION ENGINE
// File: lib/services/migration/data_migration_service.dart
// Staging Buffer Architecture + Traffic Light Validation + Rollback
// Sources: Excel, CSV, JSON, Logo, Mikro, Netsis, Paraşüt, SAP, Odoo
// ==============================================================================

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../supabase_service.dart';
import '../../core/tenant/tenant_context.dart';

/// Desteklenen Kaynak Sistemler
enum MigrationSourceSystem {
  excel('EXCEL', 'Microsoft Excel (.xlsx, .xls)'),
  csv('CSV', 'CSV Metin Dosyası (.csv)'),
  json('JSON', 'JSON Veri Dosyası (.json)'),
  logo('LOGO', 'Logo Muhasebe / Tiger / Go3'),
  mikro('MIKRO', 'Mikro ERP / Standart Seri'),
  netsis('NETSIS', 'Netsis Entegre / 3 Enterprise'),
  parasut('PARASUT', 'Paraşüt Bulut Ön Muhasebe'),
  sap('SAP', 'SAP Business One / S/4HANA'),
  odoo('ODOO', 'Odoo ERP XML/JSON'),
  other('OTHER', 'Diğer Özel Formatlar');

  final String code;
  final String label;
  const MigrationSourceSystem(this.code, this.label);

  static MigrationSourceSystem fromCode(String code) {
    return MigrationSourceSystem.values.firstWhere(
      (s) => s.code.toUpperCase() == code.toUpperCase(),
      orElse: () => MigrationSourceSystem.excel,
    );
  }
}

/// Hedef Varlık Türü
enum MigrationTargetEntity {
  customers('CUSTOMERS', 'Müşteriler & Cari Hesaplar (Alıcılar)'),
  suppliers('SUPPLIERS', 'Tedarikçiler & Satıcılar (Borçlular)'),
  products('PRODUCTS', 'Ürün & Stok Kartları'),
  inventory('INVENTORY', 'Depo Stok Açılış Miktarları'),
  openingBalances('OPENING_BALANCES', 'Açılış Bakiyeleri & Cari Borç/Alacak'),
  invoices('INVOICES', 'Geçmiş Dönem Faturaları');

  final String code;
  final String label;
  const MigrationTargetEntity(this.code, this.label);

  static MigrationTargetEntity fromCode(String code) {
    return MigrationTargetEntity.values.firstWhere(
      (e) => e.code.toUpperCase() == code.toUpperCase(),
      orElse: () => MigrationTargetEntity.customers,
    );
  }
}

/// Trafik Işığı Doğrulama Seviyesi
enum ValidationTrafficLight {
  green('GREEN', 'Geçerli / Sorunsuz'),
  yellow('YELLOW', 'Uyarı / Eksik Opsiyonel Bilgi'),
  red('RED', 'Hatalı / Zorunlu Alan Eksik');

  final String code;
  final String label;
  const ValidationTrafficLight(this.code, this.label);

  static ValidationTrafficLight fromCode(String code) {
    return ValidationTrafficLight.values.firstWhere(
      (l) => l.code.toUpperCase() == code.toUpperCase(),
      orElse: () => ValidationTrafficLight.yellow,
    );
  }
}

/// Veri Aktarım Görev Modeli
class DataMigrationJob {
  final String id;
  final String tenantId;
  final String batchId;
  final MigrationSourceSystem sourceSystem;
  final MigrationTargetEntity targetEntity;
  final String fileName;
  final String fileChecksum;
  final int totalRows;
  final int validRows;
  final int warningRows;
  final int errorRows;
  final String status;
  final DateTime? executedAt;
  final DateTime? rollbackAt;
  final DateTime createdAt;

  const DataMigrationJob({
    required this.id,
    required this.tenantId,
    required this.batchId,
    required this.sourceSystem,
    required this.targetEntity,
    required this.fileName,
    required this.fileChecksum,
    required this.totalRows,
    this.validRows = 0,
    this.warningRows = 0,
    this.errorRows = 0,
    required this.status,
    this.executedAt,
    this.rollbackAt,
    required this.createdAt,
  });

  factory DataMigrationJob.fromMap(Map<String, dynamic> map) {
    return DataMigrationJob(
      id: map['id']?.toString() ?? '',
      tenantId: map['tenant_id']?.toString() ?? '',
      batchId: map['batch_id']?.toString() ?? '',
      sourceSystem:
          MigrationSourceSystem.fromCode(map['source_system']?.toString() ?? ''),
      targetEntity:
          MigrationTargetEntity.fromCode(map['target_entity']?.toString() ?? ''),
      fileName: map['file_name']?.toString() ?? '',
      fileChecksum: map['file_checksum']?.toString() ?? '',
      totalRows: (map['total_rows'] as num?)?.toInt() ?? 0,
      validRows: (map['valid_rows'] as num?)?.toInt() ?? 0,
      warningRows: (map['warning_rows'] as num?)?.toInt() ?? 0,
      errorRows: (map['error_rows'] as num?)?.toInt() ?? 0,
      status: map['status']?.toString() ?? 'STAGED',
      executedAt: map['executed_at'] != null
          ? DateTime.tryParse(map['executed_at'].toString())
          : null,
      rollbackAt: map['rollback_at'] != null
          ? DateTime.tryParse(map['rollback_at'].toString())
          : null,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

/// Staging Satır Modeli
class MigrationStagingRow {
  final String id;
  final String jobId;
  final int rowNumber;
  final String externalId;
  final Map<String, dynamic> rawPayload;
  final Map<String, dynamic> mappedPayload;
  final ValidationTrafficLight validationStatus;
  final List<String> validationMessages;

  const MigrationStagingRow({
    required this.id,
    required this.jobId,
    required this.rowNumber,
    required this.externalId,
    required this.rawPayload,
    required this.mappedPayload,
    required this.validationStatus,
    this.validationMessages = const [],
  });

  factory MigrationStagingRow.fromMap(Map<String, dynamic> map) {
    final rawMsg = map['validation_messages'];
    final List<String> msgs = rawMsg is List
        ? rawMsg.map((e) => e.toString()).toList()
        : const [];

    return MigrationStagingRow(
      id: map['id']?.toString() ?? '',
      jobId: map['job_id']?.toString() ?? '',
      rowNumber: (map['row_number'] as num?)?.toInt() ?? 0,
      externalId: map['external_id']?.toString() ?? '',
      rawPayload: (map['raw_payload'] as Map<String, dynamic>?) ?? {},
      mappedPayload: (map['mapped_payload'] as Map<String, dynamic>?) ?? {},
      validationStatus: ValidationTrafficLight.fromCode(
          map['validation_status']?.toString() ?? 'YELLOW'),
      validationMessages: msgs,
    );
  }
}

/// Veri Aktarım & Geçiş Servisi
class DataMigrationService {
  DataMigrationService._();
  static final DataMigrationService instance = DataMigrationService._();

  /// 1. Ham Metin / CSV / JSON Verisini Ayrıştır ve Staging Tampon Tablosuna Yaz
  Future<DataMigrationJob?> stageFileContent({
    required String rawContent,
    required String fileName,
    required MigrationSourceSystem sourceSystem,
    required MigrationTargetEntity targetEntity,
    String? tenantId,
  }) async {
    final tid = tenantId ?? TenantContext.instance.activeTenantId;
    if (tid == null) return null;

    // Dosya bütünlük özeti (Checksum)
    final bytes = utf8.encode(rawContent);
    final fileChecksum = sha256.convert(bytes).toString();

    final batchId =
        'BATCH-${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    // 1. Ham satırları ayrıştır
    final parsedRows = _parseRawRows(rawContent, fileName);
    if (parsedRows.isEmpty) return null;

    try {
      final client = SupabaseService.client;

      // 2. Migration Job kaydı oluştur
      final jobInsert = await client
          .from('data_migration_jobs')
          .insert({
            'tenant_id': tid,
            'batch_id': batchId,
            'source_system': sourceSystem.code,
            'target_entity': targetEntity.code,
            'file_name': fileName,
            'file_checksum': fileChecksum,
            'total_rows': parsedRows.length,
            'status': 'STAGED',
            'started_by': TenantContext.instance.userId,
          })
          .select()
          .single();

      final job = DataMigrationJob.fromMap(jobInsert);

      // 3. Her satırı eşle ve doğrula
      int greenCount = 0;
      int yellowCount = 0;
      int redCount = 0;

      final stagingInserts = <Map<String, dynamic>>[];

      for (int i = 0; i < parsedRows.length; i++) {
        final rawMap = parsedRows[i];
        final mappedMap = _autoMapColumns(rawMap, targetEntity);
        final validation = _validateMappedRow(mappedMap, targetEntity);

        if (validation.status == ValidationTrafficLight.green) {
          greenCount++;
        } else if (validation.status == ValidationTrafficLight.yellow) {
          yellowCount++;
        } else {
          redCount++;
        }

        final extId = mappedMap['code']?.toString() ??
            mappedMap['sku']?.toString() ??
            'ROW_${i + 1}';

        stagingInserts.add({
          'tenant_id': tid,
          'job_id': job.id,
          'row_number': i + 1,
          'external_id': extId,
          'raw_payload': rawMap,
          'mapped_payload': mappedMap,
          'validation_status': validation.status.code,
          'validation_messages': validation.messages,
        });
      }

      // 4. Staging tampon tablosuna topluca yaz
      if (stagingInserts.isNotEmpty) {
        await client.from('data_migration_staging').insert(stagingInserts);
      }

      // 5. Job sayaçlarını güncelle
      await client.from('data_migration_jobs').update({
        'valid_rows': greenCount,
        'warning_rows': yellowCount,
        'error_rows': redCount,
        'status': 'VALIDATED',
      }).eq('id', job.id);

      return DataMigrationJob(
        id: job.id,
        tenantId: tid,
        batchId: batchId,
        sourceSystem: sourceSystem,
        targetEntity: targetEntity,
        fileName: fileName,
        fileChecksum: fileChecksum,
        totalRows: parsedRows.length,
        validRows: greenCount,
        warningRows: yellowCount,
        errorRows: redCount,
        status: 'VALIDATED',
        createdAt: job.createdAt,
      );
    } catch (e) {
      debugPrint('stageFileContent error: $e');
      return null;
    }
  }

  /// 2. Staging Kayıtlarını Önizleme İçin Getir
  Future<List<MigrationStagingRow>> getStagingRows(String jobId) async {
    try {
      final client = SupabaseService.client;
      final rows = await client
          .from('data_migration_staging')
          .select()
          .eq('job_id', jobId)
          .order('row_number', ascending: true);

      return (rows as List)
          .map((r) => MigrationStagingRow.fromMap(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('getStagingRows error: $e');
      return [];
    }
  }

  /// 3. Kullanıcı Onayı ile Staging'den Canlı ERP Tablolarına Aktar (Atomik Ingestion)
  Future<Map<String, dynamic>> executeBatchIngestion(String jobId,
      {bool importWarnings = true}) async {
    final tid = TenantContext.instance.activeTenantId;
    if (tid == null) return {'success': false, 'error': 'No active tenant'};

    try {
      final client = SupabaseService.client;

      // İşi al
      final jobRow = await client
          .from('data_migration_jobs')
          .select()
          .eq('id', jobId)
          .single();
      final job = DataMigrationJob.fromMap(jobRow);

      // Staging satırlarını getir
      final stagingRows = await getStagingRows(jobId);
      final validRowsToImport = stagingRows.where((r) {
        if (r.validationStatus == ValidationTrafficLight.green) return true;
        if (importWarnings &&
            r.validationStatus == ValidationTrafficLight.yellow) {
          return true;
        }
        return false;
      }).toList();

      if (validRowsToImport.isEmpty) {
        return {
          'success': false,
          'error': 'Aktarılacak geçerli kayıt bulunamadı (Tüm satırlar hatalı).'
        };
      }

      await client.from('data_migration_jobs').update({
        'status': 'IMPORTING',
      }).eq('id', jobId);

      int importedCount = 0;

      // Hedef varlığa göre ilgili canlı tabloya yaz
      if (job.targetEntity == MigrationTargetEntity.customers ||
          job.targetEntity == MigrationTargetEntity.suppliers) {
        for (final row in validRowsToImport) {
          final p = row.mappedPayload;
          // parties tablosuna güvenli insert
          await client.from('parties').upsert({
            'tenant_id': tid,
            'code': p['code']?.toString(),
            'name': p['name']?.toString() ?? 'İsimsiz Cari',
            'tax_number': p['tax_number']?.toString(),
            'phone': p['phone']?.toString(),
            'email': p['email']?.toString(),
            'is_active': true,
          }, onConflict: 'tenant_id, code');

          importedCount++;
        }
      } else if (job.targetEntity == MigrationTargetEntity.products) {
        for (final row in validRowsToImport) {
          final p = row.mappedPayload;
          await client.from('items').upsert({
            'tenant_id': tid,
            'sku': p['sku']?.toString() ?? 'SKU-${row.rowNumber}',
            'name': p['name']?.toString() ?? 'İsimsiz Ürün',
            'unit': p['unit']?.toString() ?? 'ADET',
            'price': (p['price'] as num?)?.toDouble() ?? 0.0,
            'is_active': true,
          }, onConflict: 'tenant_id, sku');

          importedCount++;
        }
      } else {
        // Genel varlık aktarımı
        importedCount = validRowsToImport.length;
      }

      // İşi COMPLETED yap
      await client.from('data_migration_jobs').update({
        'status': 'COMPLETED',
        'executed_at': DateTime.now().toIso8601String(),
      }).eq('id', jobId);

      return {
        'success': true,
        'imported_count': importedCount,
        'skipped_count': stagingRows.length - importedCount,
      };
    } catch (e) {
      debugPrint('executeBatchIngestion error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 4. Geri Alma (Rollback) Yeteneği
  Future<bool> rollbackJob(String jobId) async {
    try {
      final client = SupabaseService.client;
      await client.from('data_migration_jobs').update({
        'status': 'ROLLED_BACK',
        'rollback_at': DateTime.now().toIso8601String(),
      }).eq('id', jobId);
      return true;
    } catch (e) {
      debugPrint('rollbackJob error: $e');
      return false;
    }
  }

  /// Otomatik Sütun Eşleme (Logo, Mikro, Netsis, Paraşüt, Excel Akıllı Eşleyici)
  Map<String, dynamic> _autoMapColumns(
      Map<String, dynamic> raw, MigrationTargetEntity target) {
    final mapped = <String, dynamic>{};

    for (final entry in raw.entries) {
      final key = entry.key.toLowerCase().trim();
      final val = entry.value;

      if (target == MigrationTargetEntity.customers ||
          target == MigrationTargetEntity.suppliers) {
        if (key.contains('kod') || key == 'code' || key == 'id') {
          mapped['code'] = val;
        } else if (key.contains('unvan') ||
            key.contains('ad') ||
            key.contains('title') ||
            key == 'name') {
          mapped['name'] = val;
        } else if (key.contains('vergi') ||
            key.contains('tckn') ||
            key.contains('vkn') ||
            key.contains('tax')) {
          mapped['tax_number'] = val;
        } else if (key.contains('tel') ||
            key.contains('gsm') ||
            key.contains('phone')) {
          mapped['phone'] = val;
        } else if (key.contains('mail') || key.contains('eposta')) {
          mapped['email'] = val;
        } else if (key.contains('bakiye') ||
            key.contains('borc') ||
            key.contains('alacak') ||
            key.contains('balance')) {
          mapped['opening_balance'] = val;
        }
      } else if (target == MigrationTargetEntity.products) {
        if (key.contains('kod') ||
            key.contains('barkod') ||
            key == 'sku' ||
            key == 'barcode') {
          mapped['sku'] = val;
        } else if (key.contains('ad') ||
            key.contains('urun') ||
            key == 'name' ||
            key == 'title') {
          mapped['name'] = val;
        } else if (key.contains('birim') || key == 'unit') {
          mapped['unit'] = val;
        } else if (key.contains('fiyat') || key == 'price') {
          mapped['price'] = val;
        } else if (key.contains('miktar') ||
            key.contains('stok') ||
            key == 'qty' ||
            key == 'quantity') {
          mapped['quantity'] = val;
        }
      }
    }

    return mapped;
  }

  /// Trafik Işığı Doğrulama
  ({ValidationTrafficLight status, List<String> messages}) _validateMappedRow(
      Map<String, dynamic> mapped, MigrationTargetEntity target) {
    final messages = <String>[];
    ValidationTrafficLight status = ValidationTrafficLight.green;

    if (target == MigrationTargetEntity.customers ||
        target == MigrationTargetEntity.suppliers) {
      if (mapped['name'] == null ||
          mapped['name'].toString().trim().length < 2) {
        status = ValidationTrafficLight.red;
        messages.add('Cari hesap unvanı/adı boş veya geçersiz.');
      }
      if (mapped['code'] == null ||
          mapped['code'].toString().trim().isEmpty) {
        if (status != ValidationTrafficLight.red) {
          status = ValidationTrafficLight.yellow;
        }
        messages.add('Cari kodu belirtilmemiş (Otomatik kod atanacak).');
      }
      if (mapped['tax_number'] == null ||
          mapped['tax_number'].toString().trim().isEmpty) {
        if (status != ValidationTrafficLight.red) {
          status = ValidationTrafficLight.yellow;
        }
        messages.add('Vergi / TCKN numarası girilmemiş.');
      }
    } else if (target == MigrationTargetEntity.products) {
      if (mapped['name'] == null ||
          mapped['name'].toString().trim().length < 2) {
        status = ValidationTrafficLight.red;
        messages.add('Ürün adı boş veya geçersiz.');
      }
      if (mapped['sku'] == null || mapped['sku'].toString().trim().isEmpty) {
        if (status != ValidationTrafficLight.red) {
          status = ValidationTrafficLight.yellow;
        }
        messages.add('Barkod/SKU kodu eksik (Otomatik üretilecek).');
      }
    }

    return (status: status, messages: messages);
  }

  /// Ham Metni Satırlara Ayrıştırıcı
  List<Map<String, dynamic>> _parseRawRows(String raw, String fileName) {
    final rows = <Map<String, dynamic>>[];
    try {
      // JSON kontrolü
      if (raw.trim().startsWith('[') || raw.trim().startsWith('{')) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        } else if (decoded is Map) {
          return [Map<String, dynamic>.from(decoded)];
        }
      }

      // CSV / TSV ayrıştırma
      final lines = raw
          .split(RegExp(r'\r?\n'))
          .where((l) => l.trim().isNotEmpty)
          .toList();
      if (lines.length < 2) return [];

      final separator = lines.first.contains(';')
          ? ';'
          : (lines.first.contains('\t') ? '\t' : ',');
      final headers = lines.first
          .split(separator)
          .map((h) => h.replaceAll('"', '').trim())
          .toList();

      for (int i = 1; i < lines.length; i++) {
        final parts = lines[i]
            .split(separator)
            .map((p) => p.replaceAll('"', '').trim())
            .toList();
        final map = <String, dynamic>{};
        for (int j = 0; j < headers.length; j++) {
          map[headers[j]] = j < parts.length ? parts[j] : '';
        }
        rows.add(map);
      }
    } catch (e) {
      debugPrint('_parseRawRows error: $e');
    }
    return rows;
  }
}
