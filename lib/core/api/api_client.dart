import 'package:dio/dio.dart';
import 'package:smart_sprint/core/api/api_config.dart';
import 'package:smart_sprint/core/auth/token_store.dart';

/// Thin wrapper around Dio. Attaches the Bearer token to every request and
/// normalises backend errors into a readable [ApiException].
class ApiClient {
  final Dio _dio;
  final TokenStore _tokenStore;

  ApiClient({TokenStore? tokenStore})
    : _tokenStore = tokenStore ?? TokenStore(),
      _dio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: ApiConfig.connectTimeout,
          receiveTimeout: ApiConfig.receiveTimeout,
          contentType: 'application/json',
          // We handle non-2xx ourselves so we can read the error body.
          validateStatus: (code) => code != null && code < 500,
        ),
      ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStore.read();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  Dio get raw => _dio;

  Future<Map<String, dynamic>> post(
    String path, {
    Object? data,
  }) async {
    return _unwrap(await _safe(() => _dio.post(path, data: data)));
  }

  Future<Map<String, dynamic>> get(String path) async {
    return _unwrap(await _safe(() => _dio.get(path)));
  }

  // ── internals ───────────────────────────────────────────────────────────────

  Future<Response> _safe(Future<Response> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      // Connection-level failures (no internet, server down, cold-start timeout).
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw const ApiException(
          'The server took too long to respond. '
          "It may be waking up — please try again in a moment.",
        );
      }
      throw const ApiException(
        "Can't reach the server. Check your connection and try again.",
      );
    }
  }

  Map<String, dynamic> _unwrap(Response res) {
    final code = res.statusCode ?? 0;
    final body = res.data;

    if (code >= 200 && code < 300) {
      if (body is Map<String, dynamic>) return body;
      return {'data': body};
    }

    // FastAPI returns errors as { "detail": "..." } (or a list for validation).
    String message = 'Something went wrong. Please try again.';
    if (body is Map && body['detail'] != null) {
      final detail = body['detail'];
      if (detail is String) {
        message = detail;
      } else if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map && first['msg'] is String) {
          message = first['msg'] as String;
        }
      }
    }
    throw ApiException(message, statusCode: code);
  }
}

/// A user-presentable API error.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
