import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../storage/secure_storage.dart';
import '../api_client/widget.dart';
import '../provider/user_provider.dart';

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final SecureStorage _storage = SecureStorage.instance;
  UserProvider? _userProvider;

  // ── STATIC so it's shared even if the interceptor is re-instantiated ──────
  static bool _isRefreshing = false;

  AuthInterceptor(this._dio, [this._userProvider]);

  // ── Attach token to every outgoing request ────────────────────────────────
  @override
  Future<void> onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
      ) async {
    final token = await _storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  // ── Handle 401 — refresh then retry ──────────────────────────────────────
  @override
  Future<void> onError(
      DioException err,
      ErrorInterceptorHandler handler,
      ) async {
    final statusCode  = err.response?.statusCode;
    final requestPath = err.requestOptions.path;

    // Only intercept 401s that are NOT from the refresh endpoint itself,
    // and only when we are not already mid-refresh.
    if (statusCode != 401 ||
        requestPath.contains(ApiEndpoints.refresh) ||
        _isRefreshing) {
      handler.next(err);
      return;
    }

    _isRefreshing = true;
    debugPrint('=== AUTH INTERCEPTOR: 401 on $requestPath — attempting refresh ===');

    try {
      final refreshToken = await _storage.getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        debugPrint('❌ No refresh token found — logging out');
        await _forceLogout(handler, err);
        return;
      }

      debugPrint('🔄 Refresh token being sent: $refreshToken');
      debugPrint('🔄 Refresh token length: ${refreshToken.length}');

      // Use a bare Dio so the refresh call never hits this interceptor.
      final bareDio = Dio(
        BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            ApiEndpoints.apiKeyHeader: ApiEndpoints.apiKey,
          },
          validateStatus: (_) => true, // never throw on non-2xx
        ),
      );

      debugPrint('🔄 Calling refresh endpoint: ${ApiEndpoints.baseUrl}${ApiEndpoints.refresh}');

      final refreshResponse = await bareDio.post(
        ApiEndpoints.refresh,
        data: {'refreshToken': refreshToken},
      );

      debugPrint('🔄 REFRESH STATUS: ${refreshResponse.statusCode}');
      debugPrint('🔄 FULL REFRESH RESPONSE: ${refreshResponse.data}');

      if (refreshResponse.statusCode != 200 &&
          refreshResponse.statusCode != 201) {
        final msg = _extractMessage(refreshResponse.data) ?? 'Refresh failed';
        throw Exception('Refresh returned ${refreshResponse.statusCode}: $msg');
      }

      // Unwrap { "data": { "accessToken": ..., "refreshToken": ... } }
      final raw = refreshResponse.data;
      final payload = (raw is Map && raw.containsKey('data'))
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      debugPrint('🔄 REFRESH PAYLOAD (unwrapped): $payload');

      final newAccessToken  = payload['accessToken']?.toString()  ??
          payload['access_token']?.toString();
      final newRefreshToken = payload['refreshToken']?.toString() ??
          payload['refresh_token']?.toString();

      if (newAccessToken == null || newAccessToken.isEmpty) {
        throw Exception('accessToken missing from refresh response. '
            'Keys received: ${payload.keys.toList()}');
      }

      // Persist new tokens
      await _storage.saveAccessToken(newAccessToken);
      if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
        await _storage.saveRefreshToken(newRefreshToken);
        debugPrint('✅ Refresh token updated in storage');
      }

      // Update UserProvider so personnelId / user fields are preserved
      if (_userProvider != null && payload['user'] != null) {
        _userProvider!.updateFromRefresh(payload);
        debugPrint('✅ UserProvider updated from refresh payload');
      }

      debugPrint('✅ Refresh successful — retrying original request');

      // Patch the original request with the new token and replay it.
      // Keep _isRefreshing = true until AFTER resolve() so that any
      // parallel requests queued behind this one don't trigger another refresh.
      final retryOptions = err.requestOptions;
      retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';

      final retryResponse = await _dio.fetch(retryOptions);

      _isRefreshing = false;
      handler.resolve(retryResponse);
    } catch (e) {
      debugPrint('❌ Refresh failed: $e — clearing session and logging out');
      await _forceLogout(handler, err);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _forceLogout(
      ErrorInterceptorHandler handler,
      DioException originalErr,
      ) async {
    _isRefreshing = false;
    await _storage.clearAll();
    // Pass the original 401 error downstream so the UI can react
    // (e.g. redirect to login screen via an error interceptor or provider).
    handler.next(originalErr);
  }

  String? _extractMessage(dynamic data) {
    if (data == null) return null;
    if (data is Map) {
      return data['message']?.toString() ??
          data['error']?.toString();
    }
    return data.toString();
  }

  /// Called from ApiClient after providers are initialised.
  void updateUserProvider(UserProvider provider) {
    _userProvider = provider;
    debugPrint('🔄 AuthInterceptor: UserProvider injected');
  }
}
