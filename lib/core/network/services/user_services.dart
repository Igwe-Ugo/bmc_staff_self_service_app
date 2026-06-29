// user_services.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/errors/api_exceptions.dart';
import '../api_client/widget.dart';
import '../models/user_model.dart';

class UserServices {
  final Dio _dio = ApiClient.instance.dio;

  // ── GET /users/me ─────────────────────────────────────────────────────────
  Future<UserModel> getUser() async {
    try {
      final response = await _dio.get(ApiEndpoints.userProfile);
      final payload  = _unwrap(response.data);
      return UserModel.fromJson(payload as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('❌ GET USER ERROR: ${e.response?.data}');
      throw e.error as ApiException;
    }
  }

  // ── PATCH /api/users/profile ──────────────────────────────────────────────
  /// Updates only the fields provided. Sends only non-null values so existing
  /// data is never accidentally overwritten with blanks.
  Future<UserModel> updateProfile(UserProfileUpdateData data) async {
    final body = data.toJson();
    if (body.isEmpty) {
      throw ApiException(message: 'No changes to save.', statusCode: null);
    }

    try {
      debugPrint('📡 PATCH /users/profile body keys: ${body.keys.toList()}');
      final response = await _dio.patch(
        ApiEndpoints.updateProfile,
        data: body,
      );
      debugPrint('📡 UPDATE PROFILE STATUS: ${response.statusCode}');
      final payload = _unwrap(response.data);
      return UserModel.fromJson(payload as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('❌ UPDATE PROFILE ERROR: ${e.response?.data}');
      // Extract a meaningful message from the response body
      final msg = _extractMessage(e.response?.data) ?? e.message ?? 'Update failed.';
      throw ApiException(message: msg, statusCode: e.response?.statusCode);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  dynamic _unwrap(dynamic data) {
    if (data is Map && data.containsKey('data')) return data['data'];
    return data;
  }

  String? _extractMessage(dynamic data) {
    if (data == null) return null;
    if (data is Map) {
      return data['message']?.toString() ?? data['error']?.toString();
    }
    return data.toString();
  }
}
