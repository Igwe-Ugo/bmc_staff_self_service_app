// user_services.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/errors/api_exceptions.dart';
import '../api_client/widget.dart';
import '../models/user_model.dart';

class UserServices {
  final Dio _dio = ApiClient.instance.dio;

  // ── GET /api/users/regular ────────────────────────────────────────────────
  /// search params: userId, deptId
  /// Used to fetch the current (or any) user's full profile record.
  Future<UserModel> getUser({String? userId, String? deptId}) async {
    try {
      final params = <String, dynamic>{};
      if (userId != null) params['userId'] = userId;
      if (deptId != null) params['deptId'] = deptId;

      final response = await _dio.get(
        ApiEndpoints.usersRegular,
        queryParameters: params.isNotEmpty ? params : null,
      );

      debugPrint('📡 GET /users/regular: ${response.statusCode}');
      final payload = _unwrap(response.data);

      // Some backends may return a list (e.g. matching by deptId only) —
      // take the first match in that case.
      if (payload is List) {
        if (payload.isEmpty) {
          throw ApiException(message: 'User not found.', statusCode: 404);
        }
        return UserModel.fromJson(payload.first as Map<String, dynamic>);
      }

      return UserModel.fromJson(payload as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('❌ GET USER ERROR: ${e.response?.data}');
      final msg =
          _extractMessage(e.response?.data) ?? 'Failed to load profile.';
      throw ApiException(message: msg, statusCode: e.response?.statusCode);
    }
  }

  // ── PATCH /api/users/profile ──────────────────────────────────────────────
  /// { id, avatar, address, city, telno, state, country, password }
  /// Updates only the fields provided. Sends only non-null values so existing
  /// data is never accidentally overwritten with blanks.
  Future<UserModel> updateProfile(UserProfileUpdateData data) async {
    final body = data.toJson();
    if (body.length <= 1) {
      throw ApiException(message: 'No changes to save.', statusCode: null);
    }

    try {
      debugPrint('📤 PROFILE UPDATE PAYLOAD: $body');
      final response = await _dio.patch(
        ApiEndpoints.updateProfile,
        data: {'data': body},
      );
      debugPrint('📡 UPDATE PROFILE STATUS: ${response.statusCode}');

      // 1. Verify response status
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ApiException(
          message: 'Update failed.',
          statusCode: response.statusCode,
        );
      }

      // 2. Fetch fresh user data using current userId
      return await getUser(userId: data.id);
    } on DioException catch (e) {
      debugPrint('❌ UPDATE PROFILE ERROR: ${e.response?.data}');
      final msg =
          _extractMessage(e.response?.data) ?? e.message ?? 'Update failed.';
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
