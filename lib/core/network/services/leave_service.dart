// ─── leave_service.dart ───────────────────────────────────────────────────────

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../errors/api_exceptions.dart';
import '../api_client/widget.dart';
import '../models/widget.dart';

class LeaveService {
  final Dio _dio = ApiClient.instance.dio;

  // ── 1. POST /hr/leave/requests ────────────────────────────────────────────
  /// Submit a new leave request.
  Future<HrLeaveRequest> createRequest(HrLeaveRequestFormData data) async {
    try {
      final response = await _dio.post(ApiEndpoints.leaveRequests, data: data.toJson());
      debugPrint('📡 CREATE LEAVE: ${response.statusCode}');
      final payload = _unwrap(response.data);
      return HrLeaveRequest.fromJson(payload as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('❌ CREATE LEAVE ERROR: ${e.response?.data}');
      throw e.error as ApiException;
    }
  }

  // ── 2. GET /hr/leave/my-requests ─────────────────────────────────────────
  /// Fetch the current user's own leave requests.
  /// Optional filters: status (string), year (int).
  Future<List<HrLeaveRequest>> getMyRequests({
    String? status,
    int? year,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (status != null) params['status'] = status;
      if (year   != null) params['year']   = year.toString();

      final response = await _dio.get(
        ApiEndpoints.leaveRequests,
        queryParameters: params.isNotEmpty ? params : null,
      );
      debugPrint('📡 MY LEAVE REQUESTS: ${response.statusCode}');
      final payload = _unwrap(response.data);

      if (payload is List) {
        return payload
            .map((e) => HrLeaveRequest.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      // Some backends wrap in { data: { requests: [...] } }
      if (payload is Map && payload.containsKey('requests')) {
        return (payload['requests'] as List)
            .map((e) => HrLeaveRequest.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      debugPrint('❌ MY LEAVE REQUESTS ERROR: ${e.response?.data}');
      throw e.error as ApiException;
    }
  }

  // ── 3. GET /hr/leave/requests/search ─────────────────────────────────────
  /// Search / filter leave requests by various criteria.
  Future<List<HrLeaveRequest>> searchRequests(
      HrLeaveRequestFilters filters) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.leaveSearch,
        queryParameters: filters.toQueryParams(),
      );
      debugPrint('📡 SEARCH LEAVE: ${response.statusCode}');
      final payload = _unwrap(response.data);

      if (payload is List) {
        return payload
            .map((e) => HrLeaveRequest.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      debugPrint('❌ SEARCH LEAVE ERROR: ${e.response?.data}');
      throw e.error as ApiException;
    }
  }

  // ── 4. GET /hr/leave/requests/[id] ───────────────────────────────────────
  /// Fetch a single leave request by ID.
  Future<HrLeaveRequest> getRequestById(String id) async {
    try {
      final response = await _dio.get('${ApiEndpoints.leaveRequests}/$id');
      debugPrint('📡 GET LEAVE $id: ${response.statusCode}');
      final payload = _unwrap(response.data);
      return HrLeaveRequest.fromJson(payload as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('❌ GET LEAVE ERROR: ${e.response?.data}');
      throw e.error as ApiException;
    }
  }

  // ── 5. PATCH /hr/leave/requests/[id] ─────────────────────────────────────
  /// Update (modify) a pending leave request.
  Future<HrLeaveRequest> updateRequest(
      String id, HrLeaveUpdateFormData data) async {
    try {
      final response = await _dio.patch(
        '${ApiEndpoints.leaveRequests}/$id',
        data: data.toJson(),
      );
      debugPrint('📡 UPDATE LEAVE $id: ${response.statusCode}');
      final payload = _unwrap(response.data);
      return HrLeaveRequest.fromJson(payload as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('❌ UPDATE LEAVE ERROR: ${e.response?.data}');
      throw e.error as ApiException;
    }
  }

  // ── 6. DELETE /hr/leave/requests/[id] ────────────────────────────────────
  /// Delete a leave request.
  Future<void> deleteRequest(String id) async {
    try {
      await _dio.delete('${ApiEndpoints.leaveRequests}/$id');
      debugPrint('✅ LEAVE $id deleted');
    } on DioException catch (e) {
      debugPrint('❌ DELETE LEAVE ERROR: ${e.response?.data}');
      throw e.error as ApiException;
    }
  }

  // ── Helper ────────────────────────────────────────────────────────────────
  dynamic _unwrap(dynamic response) {
    final payload =
    (response is Map && response.containsKey('data'))
        ? response['data']
        : response;
    debugPrint('🔍 LEAVE PAYLOAD (${payload.runtimeType}): $payload');
    return payload;
  }
}
