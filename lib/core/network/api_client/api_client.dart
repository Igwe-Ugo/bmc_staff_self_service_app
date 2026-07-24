import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../interceptors/interceptors.dart';
import 'api_endpoints.dart';
import '../provider/user_provider.dart'; // ← Add this import

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  late final Dio dio = _buildDio();

  Dio _buildDio() {
    final d = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: Duration(seconds: ApiEndpoints.timeoutSeconds),
        receiveTimeout: Duration(seconds: ApiEndpoints.timeoutSeconds),
        sendTimeout: Duration(seconds: ApiEndpoints.timeoutSeconds),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          ApiEndpoints.apiKeyHeader: ApiEndpoints.apiKey,
        },
      ),
    );

    d.interceptors.addAll([
      // Pass UserProvider (it can be null initially)
      AuthInterceptor(d, null),
      ErrorInterceptor(),
      if (const bool.fromEnvironment('dart.vm.product') == false)
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (obj) => debugPrint(obj.toString()),
        ),
    ]);

    return d;
  }

  /// Call this after initializing providers (preferably in main.dart after login or in a provider setup)
  void setUserProvider(UserProvider userProvider) {
    final authInterceptor = dio.interceptors
        .whereType<AuthInterceptor>()
        .firstOrNull;

    if (authInterceptor != null) {
      authInterceptor.updateUserProvider(userProvider);
    } else {
      debugPrint('⚠️ AuthInterceptor not found in dio interceptors');
    }
  }
}
