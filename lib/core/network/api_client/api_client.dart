import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../interceptors/interceptors.dart';
import 'api_endpoints.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  late final Dio dio = _buildDio();

  Dio _buildDio() {
    final d = Dio(
      BaseOptions(
        // ✅ Now reads from .env via ApiEndpoints
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: Duration(seconds: ApiEndpoints.timeoutSeconds),
        receiveTimeout: Duration(seconds: ApiEndpoints.timeoutSeconds),
        sendTimeout:    Duration(seconds: ApiEndpoints.timeoutSeconds),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          ApiEndpoints.apiKeyHeader:   ApiEndpoints.apiKey,
        },
      ),
    );

    d.interceptors.addAll([
      AuthInterceptor(d),
      ErrorInterceptor(),
      // Remove LogInterceptor in production builds
      if (const bool.fromEnvironment('dart.vm.product') == false)
        LogInterceptor(
          requestBody:  true,
          responseBody: true,
          logPrint: (obj) => debugPrint(obj.toString()),
        ),
    ]);

    return d;
  }
}
