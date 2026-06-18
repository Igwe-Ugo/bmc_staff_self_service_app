import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../storage/secure_storage.dart';
import '../api_client/widget.dart';
import '../provider/user_provider.dart';

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final SecureStorage _storage = SecureStorage.instance;
  UserProvider? _userProvider;        // Not final so we can update it later
  bool _isRefreshing = false;

  AuthInterceptor(this._dio, [this._userProvider]);

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

  @override
  Future<void> onError(
      DioException err,
      ErrorInterceptorHandler handler,
      ) async {
    final statusCode = err.response?.statusCode;
    final requestPath = err.requestOptions.path;

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
        debugPrint('No refresh token — forcing logout');
        await _storage.clearAll();
        _isRefreshing = false;
        handler.next(err);
        return;
      }

      final bareDio = Dio();
      bareDio.options = BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          ApiEndpoints.apiKeyHeader: ApiEndpoints.apiKey,
        },
        validateStatus: (_) => true,
      );

      final body = {'refreshToken': refreshToken};
      debugPrint('Refresh body: $body');
      debugPrint('Refresh endpoint: ${ApiEndpoints.baseUrl}${ApiEndpoints.refresh}');

      final refreshResponse = await bareDio.post(
        ApiEndpoints.refresh,
        data: body,
      );

      debugPrint('🔄 REFRESH STATUS: ${refreshResponse.statusCode}');
      debugPrint('🔄 FULL REFRESH RESPONSE: ${refreshResponse.data}');

      if (refreshResponse.statusCode != 200 && refreshResponse.statusCode != 201) {
        final errorMsg = refreshResponse.data['error'] ??
            refreshResponse.data['message'] ??
            'Refresh failed';
        throw Exception('Refresh returned ${refreshResponse.statusCode}: $errorMsg');
      }

      // Unwrap envelope
      final payload = (refreshResponse.data is Map &&
          refreshResponse.data.containsKey('data'))
          ? refreshResponse.data['data'] as Map<String, dynamic>
          : refreshResponse.data as Map<String, dynamic>;

      debugPrint('🔄 REFRESH PAYLOAD (after unwrap): $payload');

      final newAccessToken = payload['accessToken']?.toString() ??
          payload['access_token']?.toString();
      final newRefreshToken = payload['refreshToken']?.toString() ??
          payload['refresh_token']?.toString();

      if (newAccessToken == null || newAccessToken.isEmpty) {
        throw Exception('accessToken missing from refresh response');
      }

      await _storage.saveAccessToken(newAccessToken);
      if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
        await _storage.saveRefreshToken(newRefreshToken);
      }

      // 🔥 Update UserProvider to preserve personnelId and other fields
      if (_userProvider != null && payload['user'] != null) {
        _userProvider!.updateFromRefresh(payload);
        debugPrint('✅ UserProvider updated from refresh (personnelId preserved)');
      }

      debugPrint('=== Refresh successful — retrying original request ===');

      final retryOptions = err.requestOptions;
      retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';

      _isRefreshing = false;
      final retryResponse = await _dio.fetch(retryOptions);
      handler.resolve(retryResponse);
    } catch (e) {
      debugPrint('=== Refresh failed: $e — clearing session ===');
      await _storage.clearAll();
      _isRefreshing = false;
      handler.next(err);
    }
  }

  // Method to inject UserProvider after ApiClient is initialized
  void updateUserProvider(UserProvider provider) {
    _userProvider = provider;
    debugPrint('🔄 AuthInterceptor: UserProvider injected successfully');
  }
}
