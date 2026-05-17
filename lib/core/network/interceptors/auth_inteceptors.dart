import 'package:dio/dio.dart';
import '../../storage/secure_storage.dart';
import '../api_client/widget.dart';

class AuthInterceptor extends Interceptor {
  final Dio dio;
  final SecureStorage _storage = SecureStorage.instance;

  AuthInterceptor(this.dio);

  // 1. Attach access token to every request
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

  // 2. On 401 → try to refresh the token, then retry the original request
  @override
  Future<void> onError(
      DioException err,
      ErrorInterceptorHandler handler,
      ) async {
    if (err.response?.statusCode == 401) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        // Retry original request with new token
        final opts = err.requestOptions;
        final token = await _storage.getAccessToken();
        opts.headers['Authorization'] = 'Bearer $token';
        try {
          final response = await dio.fetch(opts);
          return handler.resolve(response);
        } catch (_) {}
      }
      // Refresh failed → clear storage (force logout)
      await _storage.clearAll();
    }
    handler.next(err);
  }

  Future<bool> _tryRefresh() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await dio.post(
        ApiEndpoints.refresh,
        data: {'refresh_token': refreshToken},
        options: Options(headers: {'Authorization': ''}), // skip auth interceptor
      );

      final newToken = response.data['access_token'] as String?;
      if (newToken == null) return false;

      await _storage.saveAccessToken(newToken);

      final newRefresh = response.data['refresh_token'] as String?;
      if (newRefresh != null) await _storage.saveRefreshToken(newRefresh);

      return true;
    } catch (_) {
      return false;
    }
  }
}
