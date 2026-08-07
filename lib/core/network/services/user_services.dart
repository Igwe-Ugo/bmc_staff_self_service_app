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
      Map<String, dynamic> record;
      if (payload is List) {
        if (payload.isEmpty) {
          throw ApiException(message: 'User not found.', statusCode: 404);
        }
        record = payload.first as Map<String, dynamic>;
      } else {
        record = payload as Map<String, dynamic>;
      }

      // Without a userId+deptId that actually resolves, this endpoint has
      // been seen to return a bare {message, toast} acknowledgment instead
      // of a user row — and UserModel.fromJson is defensive enough to
      // accept that silently and build a near-empty user (every field
      // falls back to '' / null). Fail loudly instead of handing back
      // something that LOOKS like a valid profile but isn't.
      if (!record.containsKey('id') && !record.containsKey('username')) {
        throw ApiException(
          message: 'Server did not return a user record for this request.',
          statusCode: response.statusCode,
        );
      }

      return UserModel.fromJson(record);
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
  ///
  /// [deptId] is passed through to the post-update GET /users/regular
  /// re-fetch below. Without it, that GET has been observed to return a
  /// bare {message, toast} acknowledgment instead of the user row — the
  /// getUser() guard above now throws on that instead of returning a
  /// near-empty UserModel, but the real fix is supplying deptId so the
  /// re-fetch resolves properly in the first place. Pass the CURRENT
  /// user's defaultDept from UserProvider — the person's department
  /// doesn't change via this endpoint, so it's safe to reuse.
  Future<UserModel> updateProfile(
    UserProfileUpdateData data, {
    String? deptId,
  }) async {
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

      // 2. Fetch fresh user data using current userId + deptId
      return await getUser(userId: data.id, deptId: deptId);
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
