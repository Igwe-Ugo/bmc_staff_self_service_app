import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../storage/secure_storage.dart';
import '../api_client/widget.dart';

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final SecureStorage _storage = SecureStorage.instance;

  // Prevents infinite retry loops
  bool _isRefreshing = false;

  AuthInterceptor(this._dio);

  // ── 1. Attach access token to every outgoing request ─────────────────────
  @override
  Future<void> onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
      ) async {
    final token = await _storage.getAccessToken();

    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    debugPrint('→ [${options.method}] ${options.path}');
    handler.next(options);
  }

  // ── 2. On 401 → attempt token refresh, then retry original request ────────
  @override
  Future<void> onError(
      DioException err,
      ErrorInterceptorHandler handler,
      ) async {
    final statusCode = err.response?.statusCode;
    final requestPath = err.requestOptions.path;

    // Don't retry if:
    // - Not a 401
    // - Already on the refresh endpoint (avoid infinite loop)
    // - Already mid-refresh
    if (statusCode != 401 ||
        requestPath == ApiEndpoints.refresh ||
        _isRefreshing) {
      handler.next(err);
      return;
    }

    _isRefreshing = true;

    try {
      final refreshToken = await _storage.getRefreshToken();

      // ✅ No refresh token stored — clear everything, force logout
      if (refreshToken == null || refreshToken.isEmpty) {
        debugPrint('No refresh token found — clearing session');
        await _storage.clearAll();
        _isRefreshing = false;
        handler.next(err);
        return;
      }

      // ✅ Call refresh endpoint with the token in the body
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          headers: {
            'Content-Type': 'application/json',
            'Accept':        'application/json',
            // x-api-key still needed on refresh
            ApiEndpoints.apiKeyHeader: ApiEndpoints.apiKey,
          },
        ),
      );

      final refreshResponse = await refreshDio.post(
        ApiEndpoints.refresh,
        data: {
          'refreshToken': refreshToken,   // ✅ matches your API's expected key
        },
      );

      // ✅ Unwrap the response — handle { data: { accessToken } } or flat
      final payload = refreshResponse.data['data'] ?? refreshResponse.data;
      final newAccessToken  = payload['accessToken']?.toString()
          ?? payload['access_token']?.toString();
      final newRefreshToken = payload['refreshToken']?.toString()
          ?? payload['refresh_token']?.toString();

      if (newAccessToken == null || newAccessToken.isEmpty) {
        throw Exception('Refresh response missing accessToken');
      }

      // Save new tokens
      await _storage.saveAccessToken(newAccessToken);
      if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
        await _storage.saveRefreshToken(newRefreshToken);
      }

      debugPrint('Token refreshed successfully');

      // ✅ Retry the original failed request with the new token
      final retryOptions = err.requestOptions;
      retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';

      final retryResponse = await _dio.fetch(retryOptions);
      _isRefreshing = false;
      handler.resolve(retryResponse);

    } catch (e) {
      debugPrint('Token refresh failed: $e — clearing session');
      await _storage.clearAll();
      _isRefreshing = false;
      handler.next(err);
    }
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('← [${response.statusCode}] ${response.requestOptions.path}');
    handler.next(response);
  }
}
