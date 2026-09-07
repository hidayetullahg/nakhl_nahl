// NAKHL & NAHL — Universal Integration Connector
// Complies with Master Directive Section 5

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../../models/integration_models.dart';

class ConnectorResponse {
  final int statusCode;
  final String body;
  final Map<String, String> headers;
  final String correlationId;
  final Duration duration;

  const ConnectorResponse({
    required this.statusCode,
    required this.body,
    required this.headers,
    required this.correlationId,
    required this.duration,
  });

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
  Map<String, dynamic> get jsonBody {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return {'raw': body};
    }
  }
}

class UniversalIntegrationConnector {
  final http.Client _httpClient;
  final int maxRetries;
  final Duration timeout;
  final Duration baseDelay;

  UniversalIntegrationConnector({
    http.Client? httpClient,
    this.maxRetries = 3,
    this.timeout = const Duration(seconds: 15),
    this.baseDelay = const Duration(milliseconds: 500),
  }) : _httpClient = httpClient ?? http.Client();

  /// Execute an HTTP request with automatic retry, exponential backoff, correlation ID and error normalization
  Future<ConnectorResponse> executeRequest({
    required String method,
    required Uri uri,
    Map<String, String>? headers,
    String? body,
    String? idempotencyKey,
    String? correlationId,
    bool isSoap = false,
  }) async {
    final corrId = correlationId ?? 'nakhl-corr-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(99999)}';
    final idempKey = idempotencyKey ?? 'idemp-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(99999)}';

    final effectiveHeaders = Map<String, String>.from(headers ?? {});
    effectiveHeaders['X-Correlation-ID'] = corrId;
    effectiveHeaders['Idempotency-Key'] = idempKey;

    if (isSoap) {
      effectiveHeaders['Content-Type'] ??= 'application/soap+xml; charset=utf-8';
    } else {
      effectiveHeaders['Content-Type'] ??= 'application/json; charset=utf-8';
      effectiveHeaders['Accept'] ??= 'application/json';
    }

    int attempt = 0;
    final stopwatch = Stopwatch()..start();

    while (attempt < maxRetries) {
      attempt++;
      try {
        http.Response response;
        final reqFuture = _send(method, uri, effectiveHeaders, body);
        response = await reqFuture.timeout(timeout);
        stopwatch.stop();

        // Check if rate limited (429) or server error (502, 503, 504) for retry
        if (response.statusCode == 429 || (response.statusCode >= 500 && attempt < maxRetries)) {
          final jitter = Random().nextInt(200);
          final backoff = Duration(
            milliseconds: (baseDelay.inMilliseconds * pow(2, attempt - 1)).toInt() + jitter,
          );
          await Future.delayed(backoff);
          stopwatch.start();
          continue;
        }

        // Error Normalization
        if (response.statusCode >= 400) {
          throw _normalizeHttpError(response, corrId);
        }

        return ConnectorResponse(
          statusCode: response.statusCode,
          body: response.body,
          headers: response.headers,
          correlationId: corrId,
          duration: stopwatch.elapsed,
        );
      } on TimeoutException {
        if (attempt >= maxRetries) {
          throw IntegrationException(
            code: IntegrationErrorCode.timeout,
            message: 'Entegrasyon uç noktası zaman aşımına uğradı ($timeout).',
            correlationId: corrId,
          );
        }
        await Future.delayed(baseDelay * attempt);
      } on IntegrationException {
        rethrow;
      } catch (e) {
        if (attempt >= maxRetries) {
          throw IntegrationException(
            code: IntegrationErrorCode.networkError,
            message: 'Ağ bağlantısı hatası: $e',
            technicalDetails: e.toString(),
            correlationId: corrId,
          );
        }
        await Future.delayed(baseDelay * attempt);
      }
    }

    throw IntegrationException(
      code: IntegrationErrorCode.unknownError,
      message: 'İstek $maxRetries deneme sonrasında başarısız oldu.',
      correlationId: corrId,
    );
  }

  Future<http.Response> _send(String method, Uri uri, Map<String, String> headers, String? body) {
    switch (method.toUpperCase()) {
      case 'GET':
        return _httpClient.get(uri, headers: headers);
      case 'POST':
        return _httpClient.post(uri, headers: headers, body: body);
      case 'PUT':
        return _httpClient.put(uri, headers: headers, body: body);
      case 'DELETE':
        return _httpClient.delete(uri, headers: headers);
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }
  }

  IntegrationException _normalizeHttpError(http.Response response, String correlationId) {
    final status = response.statusCode;
    final body = response.body;

    IntegrationErrorCode code;
    String userMessage;

    if (status == 401 || status == 403) {
      code = IntegrationErrorCode.authenticationError;
      userMessage = 'Yetkilendirme veya API kimlik bilgisi hatası (HTTP $status).';
    } else if (status == 409) {
      code = IntegrationErrorCode.duplicateDocument;
      userMessage = 'Mükerrer belge veya kaynak çakışması (HTTP 409).';
    } else if (status == 422 || status == 400) {
      if (body.toLowerCase().contains('vkn') || body.toLowerCase().contains('tckn') || body.toLowerCase().contains('tax')) {
        code = IntegrationErrorCode.invalidTaxId;
        userMessage = 'Vergi kimlik numarası doğrulamadan geçemedi.';
      } else if (body.toLowerCase().contains('cert') || body.toLowerCase().contains('mali muhur')) {
        code = IntegrationErrorCode.certificateError;
        userMessage = 'Sertifika veya imza doğrulaması başarısız.';
      } else {
        code = IntegrationErrorCode.validationError;
        userMessage = 'Belge şema veya iş kuralı doğrulaması başarısız (HTTP $status).';
      }
    } else if (status == 429) {
      code = IntegrationErrorCode.rateLimit;
      userMessage = 'İstek kotası aşıldı. Lütfen bekleyip tekrar deneyin.';
    } else if (status >= 500) {
      code = IntegrationErrorCode.remoteRejection;
      userMessage = 'Entegratör sunucu hatası (HTTP $status).';
    } else {
      code = IntegrationErrorCode.unknownError;
      userMessage = 'Entegrasyon hatası oluştu (HTTP $status).';
    }

    return IntegrationException(
      code: code,
      message: userMessage,
      technicalDetails: body,
      httpStatusCode: status,
      correlationId: correlationId,
    );
  }
}
