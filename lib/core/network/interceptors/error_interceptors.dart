// error_interceptors.dart - Updated
import 'package:dio/dio.dart';
import 'dart:convert';
import '../../errors/api_exceptions.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('=== Error Interceptor ===');
    print('Error type: ${err.type}');
    print('Error message: ${err.message}');
    print('Error response: ${err.response}');

    final statusCode = err.response?.statusCode;
    dynamic responseData = err.response?.data;

    print('Response data type: ${responseData.runtimeType}');
    print('Response data: $responseData');

    // Extract meaningful error message from various response formats
    String errorMessage = _extractErrorMessage(responseData);

    // Handle the unknown error type specifically
    if (err.type == DioExceptionType.unknown) {
      // Check if it's a format/parsing error
      if (err.error is FormatException || err.message?.contains('subtype') == true) {
        errorMessage = 'Server returned an invalid response format. Please contact support.';
      } else if (err.error is TypeError) {
        errorMessage = 'Data type mismatch. Please try again later.';
      } else if (err.message?.contains('XMLHttpRequest') == true) {
        errorMessage = 'Network request failed. Please check your connection.';
      }
    }

    final exception = switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => ApiException(
        message: 'Connection timed out. Please check your internet.',
        statusCode: statusCode,
      ),
      DioExceptionType.connectionError => ApiException(
        message: 'No internet connection. Please check your network.',
        statusCode: statusCode,
      ),
      DioExceptionType.badResponse => ApiException.fromStatusCode(
        statusCode ?? 0,
        errorMessage,
      ),
      DioExceptionType.unknown => ApiException(
        message: errorMessage,
        statusCode: statusCode,
      ),
      _ => ApiException(
        message: err.message ?? 'Something went wrong.',
        statusCode: statusCode,
      ),
    };

    print('Throwing ApiException: ${exception.message}');

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: exception,
        response: err.response,
        type: err.type,
      ),
    );
  }

  String _extractErrorMessage(dynamic data) {
    if (data == null) return 'Server error occurred';

    try {
      // Handle string responses
      if (data is String) {
        if (data.trim().isEmpty) return 'Empty response from server';

        // Try to parse as JSON if it looks like JSON
        if (data.trim().startsWith('{') || data.trim().startsWith('[')) {
          try {
            final decoded = jsonDecode(data);
            return _extractErrorMessage(decoded);
          } catch (e) {
            // Not valid JSON, return as is (but don't expose internal errors)
            if (data.contains('<!DOCTYPE') || data.contains('<html>')) {
              return 'Server returned HTML instead of JSON. API endpoint might be incorrect.';
            }
            return 'Server response: $data';
          }
        }

        return data;
      }

      // Handle map responses
      if (data is Map) {
        // Common error fields
        if (data.containsKey('message')) return data['message'].toString();
        if (data.containsKey('error')) return data['error'].toString();
        if (data.containsKey('detail')) return data['detail'].toString();
        if (data.containsKey('error_description')) return data['error_description'].toString();

        // Handle validation errors
        if (data.containsKey('errors')) {
          final errors = data['errors'];
          if (errors is Map) {
            final firstError = errors.values.first;
            if (firstError is List && firstError.isNotEmpty) {
              return firstError.first.toString();
            }
            return firstError.toString();
          }
          if (errors is List && errors.isNotEmpty) {
            return errors.first.toString();
          }
        }

        // Return first non-system field
        for (var entry in data.entries) {
          if (!entry.key.startsWith('_')) {
            return '${entry.key}: ${entry.value}';
          }
        }
      }

      // Handle list responses
      if (data is List && data.isNotEmpty) {
        return _extractErrorMessage(data.first);
      }

      return data.toString();
    } catch (e) {
      return 'Unable to process server response';
    }
  }
}
