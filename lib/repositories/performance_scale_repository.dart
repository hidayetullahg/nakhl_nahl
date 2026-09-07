import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../core/tenant/tenant_context.dart';

/// Sayfalanmış Sonuç Kapsayıcısı (Generic Paged Result)
class PagedResult<T> {
  final List<T> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  const PagedResult({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  bool get hasMore => page < totalPages;
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
}

/// Performans Benchmark Modeli
class PerformanceBenchmarkModel {
  final double indexScanLatencyMs;
  final double aggregationLatencyMs;
  final double rlsEvaluationOverheadMs;
  final String databaseModel;
  final String recommendedTenantCapacity;
  final String scalingVerdict;
  final DateTime benchmarkTimestamp;

  const PerformanceBenchmarkModel({
    required this.indexScanLatencyMs,
    required this.aggregationLatencyMs,
    required this.rlsEvaluationOverheadMs,
    required this.databaseModel,
    required this.recommendedTenantCapacity,
    required this.scalingVerdict,
    required this.benchmarkTimestamp,
  });

  factory PerformanceBenchmarkModel.fromJson(Map<String, dynamic> json) {
    return PerformanceBenchmarkModel(
      indexScanLatencyMs:
          (json['index_scan_latency_ms'] as num?)?.toDouble() ?? 0.0,
      aggregationLatencyMs:
          (json['aggregation_latency_ms'] as num?)?.toDouble() ?? 0.0,
      rlsEvaluationOverheadMs:
          (json['rls_evaluation_overhead_ms'] as num?)?.toDouble() ?? 0.0,
      databaseModel: json['database_model']?.toString() ??
          'SHARED_POSTGRESQL_MULTI_TENANT_RLS',
      recommendedTenantCapacity:
          json['recommended_tenant_capacity']?.toString() ?? '',
      scalingVerdict: json['scaling_verdict']?.toString() ?? 'OPTIMAL',
      benchmarkTimestamp:
          DateTime.tryParse(json['benchmark_timestamp']?.toString() ?? '') ??
              DateTime.now(),
    );
  }
}

/// Kontrollü ve Kapsamlı Realtime Abonelik Yöneticisi (Realtime Subscription Manager)
/// Bütün tabloyu kontrolsüz dinleme yerine sadece tenant ve kanal bazlı dinleme sağlar
class RealtimeSubscriptionManager {
  RealtimeSubscriptionManager._();
  static final RealtimeSubscriptionManager instance =
      RealtimeSubscriptionManager._();

  final Map<String, RealtimeChannel> _activeChannels = {};

  /// Aktif kanal sayısı
  int get activeChannelCount => _activeChannels.length;

  /// Belirli bir tenant tablosu için filtrelenmiş abonelik açar
  RealtimeChannel subscribeToTenantChanges({
    required String channelName,
    required String table,
    required String tenantId,
    required void Function(PostgresChangePayload payload) onData,
  }) {
    // Mevcut kanal varsa önce temizle
    unsubscribe(channelName);

    final channel = SupabaseService.client.channel(channelName);
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: table,
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'tenant_id',
        value: tenantId,
      ),
      callback: onData,
    );

    channel.subscribe();
    _activeChannels[channelName] = channel;
    return channel;
  }

  /// Belirli bir kanalı kapatır (Hafıza ve Ağ Sızıntısını Önler)
  Future<void> unsubscribe(String channelName) async {
    final channel = _activeChannels.remove(channelName);
    if (channel != null) {
      await SupabaseService.client.removeChannel(channel);
    }
  }

  /// Tüm açık kanalları kapatır (Screen Dispose / Logout için)
  Future<void> unsubscribeAll() async {
    for (final channel in _activeChannels.values) {
      await SupabaseService.client.removeChannel(channel);
    }
    _activeChannels.clear();
  }
}

/// NAKHL & NAHL — Performans ve Ölçeklenebilirlik Servisi
class PerformanceScaleRepository {
  PerformanceScaleRepository._();
  static final PerformanceScaleRepository instance =
      PerformanceScaleRepository._();

  String get _tenantId => TenantContext.instance.activeTenantId ?? '';
  String get _companyId => TenantContext.instance.activeCompanyId ?? '';

  /// 1. Tek Turda Sayfalamalı Fatura Getirme (N+1 ve Büyük Liste Yükleme Önleyici)
  Future<PagedResult<Map<String, dynamic>>> getPaginatedInvoices({
    String invoiceType = 'SALES',
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final res = await SupabaseService.client.rpc(
        'get_paginated_invoices_optimized',
        params: {
          'p_tenant_id': _tenantId,
          'p_company_id': _companyId,
          'p_invoice_type': invoiceType,
          'p_page': page,
          'p_page_size': pageSize,
        },
      );

      if (res is Map<String, dynamic>) {
        final items = (res['items'] as List?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [];
        final totalCount = (res['total_count'] as num?)?.toInt() ?? 0;
        final totalPages = (res['total_pages'] as num?)?.toInt() ?? 1;

        return PagedResult<Map<String, dynamic>>(
          items: items,
          page: page,
          pageSize: pageSize,
          totalCount: totalCount,
          totalPages: totalPages,
        );
      }

      return PagedResult<Map<String, dynamic>>(
        items: [],
        page: page,
        pageSize: pageSize,
        totalCount: 0,
        totalPages: 0,
      );
    } catch (_) {
      return PagedResult<Map<String, dynamic>>(
        items: [],
        page: page,
        pageSize: pageSize,
        totalCount: 0,
        totalPages: 0,
      );
    }
  }

  /// 2. Performans Benchmarkını Çalıştır
  Future<PerformanceBenchmarkModel?> runBenchmark() async {
    try {
      final res = await SupabaseService.client.rpc(
        'run_performance_benchmark',
        params: {
          'p_tenant_id': _tenantId,
          'p_company_id': _companyId,
        },
      );

      if (res is Map<String, dynamic>) {
        return PerformanceBenchmarkModel.fromJson(res);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
