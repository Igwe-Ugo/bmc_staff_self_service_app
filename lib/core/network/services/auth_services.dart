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
      final response = await _dio.post(
        ApiEndpoints.login,
        data: request.toJson(),
      );

      // Debug prints to see what the API actually returns
      print('=== API Response Debug ===');
      print('Status Code: ${response.statusCode}');
      print('Response Data Type: ${response.data.runtimeType}');
      print('Response Data: ${response.data}');

      // Handle different response types
      Map<String, dynamic> jsonData;

      // Case 1: Response.data is already a Map
      if (response.data is Map<String, dynamic>) {
        jsonData = response.data as Map<String, dynamic>;
      }
      // Case 2: Response.data is a String (JSON string)
      else if (response.data is String) {
        final String jsonString = response.data as String;
        print('Raw JSON string: $jsonString');

        // Try to parse the JSON string
        try {
          // Use dart:convert to parse JSON string
          final decoded = jsonDecode(jsonString);
          if (decoded is Map<String, dynamic>) {
            jsonData = decoded;
          } else {
            throw ApiException(
              message: 'Invalid response format: Expected JSON object but got ${decoded.runtimeType}',
              statusCode: response.statusCode,
            );
          }
        } catch (e) {
          throw ApiException(
            message: 'Failed to parse server response: $e',
            statusCode: response.statusCode,
          );
        }
      }
      // Case 3: Response.data is null or other type
      else {
        throw ApiException(
          message: 'Unexpected response type: ${response.data.runtimeType}',
          statusCode: response.statusCode,
        );
      }

      // Ensure required fields exist before parsing
      print('Parsed JSON keys: ${jsonData.keys}');

      // Create LoginResponse with safe parsing
      final loginResponse = LoginResponse.fromJson(jsonData);

      print("Token before saving");
      print(loginResponse.accessToken);

      // ✅ Save tokens
      await _storage.saveAccessToken(loginResponse.accessToken);

      if (loginResponse.refreshToken != null &&
          loginResponse.refreshToken!.isNotEmpty) {
        await _storage.saveRefreshToken(loginResponse.refreshToken!);
        debugPrint('Refresh token saved');
      } else {
        debugPrint('Warning: No refresh token in login response');
      }
      // ✅ Verify saved token
      final token = await _storage.getAccessToken();
      print("STORED TOKEN after saving: $token");

      return loginResponse;

    } on DioException catch (e) {
      print('DioException caught:');
      print('  Message: ${e.message}');
      print('  Type: ${e.type}');
      print('  Response: ${e.response}');
      print('  Response data: ${e.response?.data}');

      // Better error handling
      if (e.response != null) {
        // Try to extract error message from response
        String errorMessage = _extractErrorMessage(e.response!.data);
        throw ApiException(
          message: errorMessage,
          statusCode: e.response?.statusCode,
        );
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw ApiException(
          message: 'Connection timeout. Please check your internet connection.',
          statusCode: null,
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw ApiException(
          message: 'Cannot connect to server. Please check your internet connection.',
          statusCode: null,
        );
      } else if (e.error is ApiException) {
        throw e.error as ApiException;
      } else {
        throw ApiException(
          message: 'Network error: ${e.message ?? 'Unknown error occurred'}',
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
      // If data is a string, try to parse it as JSON
      if (data is String) {
        final decoded = jsonDecode(data);
        data = decoded;
      }

      // If data is a Map, look for common error fields
      if (data is Map) {
        // Common error response formats
        if (data.containsKey('message')) return data['message'].toString();
        if (data.containsKey('error')) return data['error'].toString();
        if (data.containsKey('detail')) return data['detail'].toString();
        if (data.containsKey('error_description')) return data['error_description'].toString();

        // Handle validation errors
        if (data.containsKey('errors')) {
          final errors = data['errors'];
          if (errors is Map) {
            final firstError = errors.values.first;
            if (firstError is List) {
              return firstError.first.toString();
            }
            return firstError.toString();
          }
          if (errors is List) {
            return errors.first.toString();
          }
        }

        // If we have a data field with error information
        if (data.containsKey('data') && data['data'] is Map) {
          return _extractErrorMessage(data['data']);
        }
      }

      // If data is a List
      if (data is List && data.isNotEmpty) {
        return _extractErrorMessage(data.first);
      }

      // Return string representation if nothing else works
      return data.toString();
    } catch (e) {
      return 'An error occurred while processing the server response';
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiEndpoints.logout);
    } catch (_) {
      // Always clear local storage even if the server call fails
    } finally {
      await _storage.clearAll();
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.getAccessToken();
    return token != null;
  }
}
