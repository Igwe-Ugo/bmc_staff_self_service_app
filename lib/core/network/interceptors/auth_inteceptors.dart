import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../storage/secure_storage.dart';
import '../api_client/widget.dart';
import '../provider/user_provider.dart';
import 'auth_refresh.dart';

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final SecureStorage _storage = SecureStorage.instance;
  UserProvider? _userProvider;

  AuthInterceptor(this._dio, [this._userProvider]) {
    // Keep AuthRefresh in sync if a UserProvider was already available at
    // construction time (some ApiClient setups build the interceptor after
    // providers exist).
    if (_userProvider != null) {
      AuthRefresh.instance.updateUserProvider(_userProvider!);
    }
  }

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
  //
  // The actual refresh call now lives in AuthRefresh, shared with
  // SocketService, so a Dio 401 and a socket reconnect can never race two
  // independent refreshes against a single-use, rotating refresh token. See
  // auth_refresh.dart for why that matters.
  @override
  Future<void> onError(
      DioException err,
      ErrorInterceptorHandler handler,
      ) async {
    final statusCode  = err.response?.statusCode;
    final requestPath = err.requestOptions.path;

    if (statusCode != 401 || requestPath.contains(ApiEndpoints.refresh)) {
      handler.next(err);
      return;
    }

    debugPrint('=== AUTH INTERCEPTOR: 401 on $requestPath — attempting refresh ===');

    // If another request already triggered a refresh, this awaits the same
    // in-flight call instead of starting a second one.
    final newAccessToken = await AuthRefresh.instance.getFreshAccessToken();

    if (newAccessToken == null) {
      debugPrint('❌ Refresh failed — logging out');
      await _forceLogout(handler, err);
      return;
    }

    debugPrint('✅ Refresh successful — retrying original request');

    final retryOptions = err.requestOptions;
    retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';

    try {
      final retryResponse = await _dio.fetch(retryOptions);
      handler.resolve(retryResponse);
    } catch (_) {
      // The retry itself failed for some other reason — surface the
      // ORIGINAL 401 rather than swallowing it.
      handler.next(err);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _forceLogout(
      ErrorInterceptorHandler handler,
      DioException originalErr,
      ) async {
    await _storage.clearAll();
    // Pass the original 401 error downstream so the UI can react
    // (e.g. redirect to login screen via an error interceptor or provider).
    handler.next(originalErr);
  }

  /// Called from ApiClient after providers are initialised.
  void updateUserProvider(UserProvider provider) {
    _userProvider = provider;
    AuthRefresh.instance.updateUserProvider(provider);
    debugPrint('🔄 AuthInterceptor: UserProvider injected');
  }
}
