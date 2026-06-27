// auth_services.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/storage/secure_storage.dart';
import '../../errors/api_exceptions.dart';
import '../api_client/widget.dart';
import '../models/widget.dart';

class AuthServices {
  final Dio _dio = ApiClient.instance.dio;
  final SecureStorage _storage = SecureStorage.instance;

  Future<LoginResponse> login(LoginRequest request) async {
    try {
      // ── Resolve stable device ID first ────────────────────────────────────
      final deviceId = await _storage.getDeviceId();
      debugPrint('🆔 Login deviceId: $deviceId');

      final response = await _dio.post(
        ApiEndpoints.login,
        data: {
          ...request.toJson(),
          'deviceId': deviceId,   // always injected here — single source of truth
        },
      );

      print('=== API Response Debug ===');
      print('Status Code: ${response.statusCode}');
      print('Response Data Type: ${response.data.runtimeType}');
      print('Response Data: ${response.data}');

      Map<String, dynamic> jsonData;

      if (response.data is Map<String, dynamic>) {
        jsonData = response.data as Map<String, dynamic>;
      } else if (response.data is String) {
        final String jsonString = response.data as String;
        print('Raw JSON string: $jsonString');
        try {
          final decoded = jsonDecode(jsonString);
          if (decoded is Map<String, dynamic>) {
            jsonData = decoded;
          } else {
            throw ApiException(
              message:
              'Invalid response format: Expected JSON object but got ${decoded.runtimeType}',
              statusCode: response.statusCode,
            );
          }
        } catch (e) {
          throw ApiException(
            message: 'Failed to parse server response: $e',
            statusCode: response.statusCode,
          );
        }
      } else {
        throw ApiException(
          message:
          'Unexpected response type: ${response.data.runtimeType}',
          statusCode: response.statusCode,
        );
      }

      print('Parsed JSON keys: ${jsonData.keys}');

      final loginResponse = LoginResponse.fromJson(jsonData);

      print('Token before saving: ${loginResponse.accessToken}');

      await _storage.saveAccessToken(loginResponse.accessToken);

      if (loginResponse.refreshToken != null &&
          loginResponse.refreshToken!.isNotEmpty) {
        await _storage.saveRefreshToken(loginResponse.refreshToken!);
        debugPrint('Refresh token saved');
      } else {
        debugPrint('Warning: No refresh token in login response');
      }

      final token = await _storage.getAccessToken();
      print('STORED TOKEN after saving: $token');

      return loginResponse;

    } on DioException catch (e) {
      print('DioException caught:');
      print('  Message: ${e.message}');
      print('  Type: ${e.type}');
      print('  Response: ${e.response}');
      print('  Response data: ${e.response?.data}');

      if (e.response != null) {
        String errorMessage = _extractErrorMessage(e.response!.data);
        throw ApiException(
          message: errorMessage,
          statusCode: e.response?.statusCode,
        );
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw ApiException(
          message:
          'Connection timeout. Please check your internet connection.',
          statusCode: null,
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw ApiException(
          message:
          'Cannot connect to server. Please check your internet connection.',
          statusCode: null,
        );
      } else if (e.error is ApiException) {
        throw e.error as ApiException;
      } else {
        throw ApiException(
          message:
          'Network error: ${e.message ?? 'Unknown error occurred'}',
          statusCode: null,
        );
      }
    } catch (e) {
      print('Unexpected error: $e');
      print('Error type: ${e.runtimeType}');
      throw ApiException(
        message: 'An unexpected error occurred: $e',
        statusCode: null,
      );
    }
  }

  String _extractErrorMessage(dynamic data) {
    if (data == null) return 'Server error occurred';
    try {
      if (data is String) {
        final decoded = jsonDecode(data);
        data = decoded;
      }
      if (data is Map) {
        if (data.containsKey('message')) return data['message'].toString();
        if (data.containsKey('error'))   return data['error'].toString();
        if (data.containsKey('detail'))  return data['detail'].toString();
        if (data.containsKey('error_description'))
          return data['error_description'].toString();
        if (data.containsKey('errors')) {
          final errors = data['errors'];
          if (errors is Map) {
            final firstError = errors.values.first;
            if (firstError is List) return firstError.first.toString();
            return firstError.toString();
          }
          if (errors is List) return errors.first.toString();
        }
        if (data.containsKey('data') && data['data'] is Map) {
          return _extractErrorMessage(data['data']);
        }
      }
      if (data is List && data.isNotEmpty) {
        return _extractErrorMessage(data.first);
      }
      return data.toString();
    } catch (e) {
      return 'An error occurred while processing the server response';
    }
  }

  Future<void> logout() async {
    try {
      // 1. If your backend needs the token to invalidate the session,
      // send the post request BEFORE removing the header.
      await _dio.post(ApiEndpoints.logout);
    } catch (_) {
      // Always clear local storage even if the server call fails
    } finally {
      // 2. Clear headers from BOTH global ApiClient and local service _dio instances
      ApiClient.instance.dio.options.headers.remove('Authorization');
      _dio.options.headers.remove('Authorization');

      // 3. Wipe secure local storage completely
      await _storage.clearAll();
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.getAccessToken();
    return token != null;
  }
}
