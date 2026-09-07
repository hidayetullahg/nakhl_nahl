// NAKHL & NAHL — Universal Webhook Security & Event Processor
// Complies with Master Directive Section 8

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum WebhookProcessStatus {
  success,
  duplicateIgnored,
  invalidSignature,
  replayDetected,
  failed
}

class WebhookProcessResult {
  final WebhookProcessStatus status;
  final String message;
  final String? eventId;

  const WebhookProcessResult({
    required this.status,
    required this.message,
    this.eventId,
  });

  bool get isSuccess => status == WebhookProcessStatus.success || status == WebhookProcessStatus.duplicateIgnored;
}

class IntegrationWebhookHandler {
  final SupabaseClient _supabase;

  IntegrationWebhookHandler({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// Verify HMAC SHA256 Signature
  static bool verifySignature({
    required String rawPayload,
    required String secret,
    required String headerSignature,
  }) {
    if (headerSignature.isEmpty || secret.isEmpty) return false;

    final key = utf8.encode(secret);
    final bytes = utf8.encode(rawPayload);
    final hmacSha256 = Hmac(sha256, key);
    final computedDigest = hmacSha256.convert(bytes);
    final computedHex = computedDigest.toString();

    // Clean any prefix like 'sha256='
    final cleanHeader = headerSignature.replaceAll('sha256=', '').trim();
    return computedHex.toLowerCase() == cleanHeader.toLowerCase();
  }

  /// Process an incoming webhook with HMAC validation, replay protection, and idempotency
  Future<WebhookProcessResult> handleIncomingWebhook({
    required String tenantId,
    required String provider,
    required String eventType,
    required String idempotencyKey,
    required String rawPayload,
    required String signature,
    required String secret,
    DateTime? timestamp,
    Future<void> Function(Map<String, dynamic>)? onEventValidated,
  }) async {
    // 1. Replay Protection: Check timestamp freshness (within 5 minutes)
    if (timestamp != null) {
      final now = DateTime.now();
      final diff = now.difference(timestamp).abs();
      if (diff > const Duration(minutes: 5)) {
        return const WebhookProcessResult(
          status: WebhookProcessStatus.replayDetected,
          message: 'Webhook zaman damgası 5 dakikadan eski (Replay attack koruması).',
        );
      }
    }

    // 2. HMAC Signature Verification
    if (!verifySignature(rawPayload: rawPayload, secret: secret, headerSignature: signature)) {
      return const WebhookProcessResult(
        status: WebhookProcessStatus.invalidSignature,
        message: 'Geçersiz webhook HMAC imzası.',
      );
    }

    // 3. Idempotency Check: Prevent double processing
    try {
      final existing = await _supabase
          .from('integration_webhook_events')
          .select('id, status')
          .eq('tenant_id', tenantId)
          .eq('idempotency_key', idempotencyKey)
          .maybeSingle();

      if (existing != null) {
        return WebhookProcessResult(
          status: WebhookProcessStatus.duplicateIgnored,
          message: 'Etkinlik daha önce işlendi (Idempotent bypass).',
          eventId: existing['id']?.toString(),
        );
      }
    } catch (_) {}

    // 4. Record Received Event
    Map<String, dynamic> parsedPayload = {};
    try {
      parsedPayload = jsonDecode(rawPayload) as Map<String, dynamic>;
    } catch (_) {
      parsedPayload = {'raw': rawPayload};
    }

    String? eventId;
    try {
      final insertRes = await _supabase.from('integration_webhook_events').insert({
        'tenant_id': tenantId,
        'provider': provider,
        'event_type': eventType,
        'idempotency_key': idempotencyKey,
        'payload': parsedPayload,
        'signature': signature,
        'status': 'validated',
        'received_at': DateTime.now().toIso8601String(),
      }).select('id').maybeSingle();

      eventId = insertRes?['id']?.toString();
    } catch (e) {
      return WebhookProcessResult(
        status: WebhookProcessStatus.failed,
        message: 'Webhook veritabanına kaydedilemedi: $e',
      );
    }

    // 5. Execute Event Handler Logic
    if (onEventValidated != null) {
      try {
        await onEventValidated(parsedPayload);

        // Update status to processed
        if (eventId != null) {
          await _supabase.from('integration_webhook_events').update({
            'status': 'processed',
            'processed_at': DateTime.now().toIso8601String(),
          }).eq('id', eventId);
        }
      } catch (e) {
        if (eventId != null) {
          await _supabase.from('integration_webhook_events').update({
            'status': 'failed',
            'last_error': e.toString(),
          }).eq('id', eventId);
        }

        return WebhookProcessResult(
          status: WebhookProcessStatus.failed,
          message: 'Webhook iş mantığı hatası: $e',
          eventId: eventId,
        );
      }
    }

    return WebhookProcessResult(
      status: WebhookProcessStatus.success,
      message: 'Webhook başarıyla doğrulandı ve işlendi.',
      eventId: eventId,
    );
  }
}
