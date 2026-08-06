// lib/core/network/interceptors/auth_refresh.dart
//
// Single-flight access-token refresh, shared by AuthInterceptor (Dio 401s)
// and SocketService (socket auth failures / token expiry on reconnect).
//
// Refresh tokens are single-use with rotation on this backend — reusing one
// revokes the WHOLE token family. If the Dio interceptor and the socket each
// ran their own refresh call, a request that raced both would present an
// already-rotated token and the user would be logged out of this device
// entirely, for no reason visible to them. Every refresh in the app must go
// through this class — nothing else should ever POST to
// ApiEndpoints.refresh directly.
//
// This is a lift of the refresh block that used to live inline in
// AuthInterceptor.onError() — same request, same response-unwrapping, same
// token persistence. Only the entry point changed: it's now a plain
// awaitable that any caller can share.

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../storage/secure_storage.dart';
import '../api_client/widget.dart';
import '../provider/user_provider.dart';

class AuthRefresh {
  AuthRefresh._();
  static final AuthRefresh instance = AuthRefresh._();

  final SecureStorage _storage = SecureStorage.instance;
  UserProvider? _userProvider;

  Future<String?>? _inFlight;

  /// Call once providers exist (see main.dart). Mirrors
  /// AuthInterceptor.updateUserProvider so a refresh keeps personnelId/user
  /// fields in sync the same way it always did.
  void updateUserProvider(UserProvider provider) {
    _userProvider = provider;
  }

  /// Returns the NEW access token, or null if refresh failed.
  ///
  /// Concurrent callers (e.g. a Dio 401 and a socket reconnect firing in the
  /// same moment) share this single in-flight request instead of each
  /// starting their own — that sharing is the entire point of this class.
  Future<String?> getFreshAccessToken() {
    return _inFlight ??= _run().whenComplete(() => _inFlight = null);
  }

  Future<String?> _run() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        debugPrint('❌ AuthRefresh: no refresh token found');
        return null;
      }

      // Bare Dio so this call never re-enters AuthInterceptor.
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

      debugPrint('🔄 AuthRefresh: calling ${ApiEndpoints.baseUrl}${ApiEndpoints.refresh}');

      final response = await bareDio.post(
        ApiEndpoints.refresh,
        data: {'refreshToken': refreshToken},
      );

      debugPrint('🔄 AuthRefresh: status ${response.statusCode}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        debugPrint('❌ AuthRefresh: refresh returned ${response.statusCode} '
            '— ${_extractMessage(response.data) ?? 'no message'}');
        return null;
      }

      // Unwrap { "data": { "accessToken": ..., "refreshToken": ... } }
      final raw = response.data;
      final payload = (raw is Map && raw.containsKey('data'))
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      final newAccessToken = payload['accessToken']?.toString() ??
          payload['access_token']?.toString();
      final newRefreshToken = payload['refreshToken']?.toString() ??
          payload['refresh_token']?.toString();

      if (newAccessToken == null || newAccessToken.isEmpty) {
        debugPrint('❌ AuthRefresh: accessToken missing from response. '
            'Keys received: ${payload.keys.toList()}');
        return null;
      }

      await _storage.saveAccessToken(newAccessToken);
      if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
        await _storage.saveRefreshToken(newRefreshToken);
        debugPrint('✅ AuthRefresh: refresh token rotated in storage');
      }

      if (_userProvider != null && payload['user'] != null) {
        _userProvider!.updateFromRefresh(payload);
        debugPrint('✅ AuthRefresh: UserProvider updated from refresh payload');
      }

      debugPrint('✅ AuthRefresh: refresh successful');
      return newAccessToken;
    } catch (e) {
      debugPrint('❌ AuthRefresh: refresh failed — $e');
      return null;
    }
  }

  String? _extractMessage(dynamic data) {
    if (data == null) return null;
    if (data is Map) {
      return data['message']?.toString() ?? data['error']?.toString();
    }
    return data.toString();
  }
}
