// NAKHL & NAHL — Universal ERP Integration Sync Service
// Complies with Master Directive Sections 6 & 7

import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/integration_models.dart';

class SyncResult {
  final bool success;
  final String correlationId;
  final int totalProcessed;
  final int totalFailed;
  final List<String> errors;
  final Duration duration;

  const SyncResult({
    required this.success,
    required this.correlationId,
    required this.totalProcessed,
    required this.totalFailed,
    this.errors = const [],
    required this.duration,
  });
}

class IntegrationSyncService {
  final SupabaseClient _supabase;

  IntegrationSyncService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// Export local entities (Customers, Products, Invoices, Journals) to external ERP
  Future<SyncResult> exportEntitiesToErp({
    required String tenantId,
    required String provider,
    required String entityType,
    required List<Map<String, dynamic>> items,
    required Future<Map<String, dynamic>> Function(Map<String, dynamic>) externalErpSender,
  }) async {
    final correlationId = 'sync-exp-${DateTime.now().millisecondsSinceEpoch}';
    final stopwatch = Stopwatch()..start();
    int processed = 0;
    int failed = 0;
    final errors = <String>[];

    for (final item in items) {
      final localId = item['local_id']?.toString() ?? item['id']?.toString() ?? '';
      try {
        final hash = item['hash']?.toString() ?? jsonEncode(item);

        // Check existing mapping to avoid unnecessary resync
        final existingMapping = await _getMapping(tenantId, provider, entityType, localId);
        if (existingMapping != null && existingMapping.syncHash == hash && existingMapping.externalStatus == 'SYNCED') {
          processed++;
          continue; // Already in sync
        }

        // Send to external ERP
        final response = await externalErpSender(item);
        final externalId = response['external_id']?.toString() ?? 'EXT-$localId';

        // Upsert mapping in integration_entity_mappings
        await _saveMapping(
          tenantId: tenantId,
          provider: provider,
          entityType: entityType,
          localId: localId,
          externalId: externalId,
          status: 'SYNCED',
          direction: 'outbound',
          syncHash: hash,
        );

        processed++;
      } catch (e) {
        failed++;
        errors.add('Entity $localId failed: $e');

        await _saveMapping(
          tenantId: tenantId,
          provider: provider,
          entityType: entityType,
          localId: localId,
          externalId: 'ERROR',
          status: 'FAILED',
          direction: 'outbound',
          errorMessage: e.toString(),
        );
      }
    }

    stopwatch.stop();

    // Log to integration_sync_logs
    await _writeSyncLog(
      tenantId: tenantId,
      provider: provider,
      syncType: 'manual',
      entityType: entityType,
      direction: 'outbound',
      correlationId: correlationId,
      status: failed == 0 ? 'SUCCESS' : (processed > 0 ? 'WARNING' : 'FAILED'),
      processed: processed,
      failed: failed,
      durationMs: stopwatch.elapsedMilliseconds,
      errorDetails: errors.isNotEmpty ? errors.join('\n') : null,
    );

    return SyncResult(
      success: failed == 0,
      correlationId: correlationId,
      totalProcessed: processed,
      totalFailed: failed,
      errors: errors,
      duration: stopwatch.elapsed,
    );
  }

  /// Inbound Sync: Process incoming external ERP items into NAKHL
  Future<SyncResult> importEntitiesFromErp({
    required String tenantId,
    required String provider,
    required String entityType,
    required List<Map<String, dynamic>> externalItems,
    required Future<String> Function(Map<String, dynamic>) localEntityCreator,
  }) async {
    final correlationId = 'sync-imp-${DateTime.now().millisecondsSinceEpoch}';
    final stopwatch = Stopwatch()..start();
    int processed = 0;
    int failed = 0;
    final errors = <String>[];

    for (final extItem in externalItems) {
      final externalId = extItem['external_id']?.toString() ?? extItem['id']?.toString() ?? '';
      try {
        final hash = jsonEncode(extItem);

        // Check if already mapped
        final existing = await _getMappingByExternalId(tenantId, provider, entityType, externalId);
        if (existing != null && existing.syncHash == hash) {
          processed++;
          continue; // Idempotent: already imported with matching hash
        }

        // Create or update local entity in NAKHL
        final localId = await localEntityCreator(extItem);

        await _saveMapping(
          tenantId: tenantId,
          provider: provider,
          entityType: entityType,
          localId: localId,
          externalId: externalId,
          status: 'SYNCED',
          direction: 'inbound',
          syncHash: hash,
        );

        processed++;
      } catch (e) {
        failed++;
        errors.add('External Item $externalId failed: $e');
      }
    }

    stopwatch.stop();

    await _writeSyncLog(
      tenantId: tenantId,
      provider: provider,
      syncType: 'automatic',
      entityType: entityType,
      direction: 'inbound',
      correlationId: correlationId,
      status: failed == 0 ? 'SUCCESS' : 'WARNING',
      processed: processed,
      failed: failed,
      durationMs: stopwatch.elapsedMilliseconds,
      errorDetails: errors.isNotEmpty ? errors.join('\n') : null,
    );

    return SyncResult(
      success: failed == 0,
      correlationId: correlationId,
      totalProcessed: processed,
      totalFailed: failed,
      errors: errors,
      duration: stopwatch.elapsed,
    );
  }

  Future<IntegrationEntityMapping?> _getMapping(
    String tenantId,
    String provider,
    String entityType,
    String localId,
  ) async {
    try {
      final res = await _supabase
          .from('integration_entity_mappings')
          .select()
          .eq('tenant_id', tenantId)
          .eq('provider', provider)
          .eq('local_entity', entityType)
          .eq('local_id', localId)
          .maybeSingle();

      if (res != null) {
        return IntegrationEntityMapping.fromJson(res);
      }
    } catch (_) {}
    return null;
  }

  Future<IntegrationEntityMapping?> _getMappingByExternalId(
    String tenantId,
    String provider,
    String entityType,
    String externalId,
  ) async {
    try {
      final res = await _supabase
          .from('integration_entity_mappings')
          .select()
          .eq('tenant_id', tenantId)
          .eq('provider', provider)
          .eq('local_entity', entityType)
          .eq('external_id', externalId)
          .maybeSingle();

      if (res != null) {
        return IntegrationEntityMapping.fromJson(res);
      }
    } catch (_) {}
    return null;
  }

  Future<void> _saveMapping({
    required String tenantId,
    required String provider,
    required String entityType,
    required String localId,
    required String externalId,
    required String status,
    required String direction,
    String? syncHash,
    String? errorMessage,
  }) async {
    try {
      await _supabase.from('integration_entity_mappings').upsert({
        'tenant_id': tenantId,
        'provider': provider,
        'local_entity': entityType,
        'local_id': localId,
        'external_id': externalId,
        'external_status': status,
        'sync_direction': direction,
        'sync_hash': syncHash,
        'error_message': errorMessage,
        'last_synced_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'tenant_id,provider,local_entity,local_id');
    } catch (_) {}
  }

  Future<void> _writeSyncLog({
    required String tenantId,
    required String provider,
    required String syncType,
    required String entityType,
    required String direction,
    required String correlationId,
    required String status,
    required int processed,
    required int failed,
    required int durationMs,
    String? errorDetails,
  }) async {
    try {
      await _supabase.from('integration_sync_logs').insert({
        'tenant_id': tenantId,
        'provider': provider,
        'sync_type': syncType,
        'entity_type': entityType,
        'direction': direction,
        'correlation_id': correlationId,
        'status': status,
        'records_processed': processed,
        'records_failed': failed,
        'duration_ms': durationMs,
        'error_details': errorDetails,
        'started_at': DateTime.now().toIso8601String(),
        'completed_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }
}
