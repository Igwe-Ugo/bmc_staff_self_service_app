import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/errors/api_exceptions.dart';
import '../api_client/widget.dart';
import '../models/availability_model.dart';

class AvailabilityServices {
  final Dio _dio = ApiClient.instance.dio;

  // ── 1. GET /hr/availability/windows/current ───────────────────────────────
  /// Returns null if no window is currently active.
  Future<HrAvailabilityWindow?> getCurrentWindow() async {
    try {
      final response = await _dio.get(ApiEndpoints.availabilityCurrentWindow);

      debugPrint('📡 STATUS CODE: ${response.statusCode}');
      debugPrint('📡 FULL RESPONSE: ${response.data}');

      // Shape: { "data": { ...window fields... } }
      final payload = _unwrapObject(response.data);
      if (payload == null) return null;
      return HrAvailabilityWindow.fromJson(payload);
    } on DioException catch (e) {
      debugPrint('❌ WINDOW ERROR: ${e.response?.data}');
      throw e.error as ApiException;
    }
  }

  // Expose for manual refresh
  Future<void> refreshWindow() async => getCurrentWindow();

  // ── 2. GET /hr/availability/my-calendar?month=YYYY-MM ────────────────────
  /// Shape: { "data": { "personnelId": "...", "slots": [...] } }
  Future<List<HrAvailabilitySlot>> getMyCalendar(String month) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.availabilityMyCalendar,
        queryParameters: {'month': month},
      );

      debugPrint('📡 MY-CALENDAR STATUS: ${response.statusCode}');
      debugPrint('📡 MY-CALENDAR RESPONSE: ${response.data}');

      // Unwrap outer "data" envelope → { "personnelId": ..., "slots": [...] }
      final envelope = _unwrapObject(response.data);
      if (envelope == null) return [];

      // Pull "slots" array out of the envelope
      final slotsList = envelope['slots'];
      if (slotsList == null || slotsList is! List) {
        debugPrint('⚠️ No "slots" array found in calendar response');
        return [];
      }

      debugPrint('✅ ${slotsList.length} slot(s) found for $month');
      return slotsList
          .map((e) => HrAvailabilitySlot.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      debugPrint('❌ CALENDAR ERROR: ${e.response?.data}');
      throw e.error as ApiException;
    }
  }

  // ── 3. POST /hr/availability/bulk ─────────────────────────────────────────
  /// Submits one or more availability slots at once.
  /// API may return { "data": { "personnelId": ..., "slots": [...] } }
  /// or { "data": [ ...slots... ] } — handles both.
  Future<List<HrAvailabilitySlot>> submitBulk(
      HrAvailabilityBulkFormData formData) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.availabilityBulk,
        data: formData.toJson(),
      );

      debugPrint('📡 BULK SUBMIT STATUS: ${response.statusCode}');
      debugPrint('📡 BULK SUBMIT RESPONSE: ${response.data}');

      final inner = _unwrapRaw(response.data); // raw data["data"]

      // Shape A: { "personnelId": ..., "slots": [...] }
      if (inner is Map<String, dynamic> && inner.containsKey('slots')) {
        final list = inner['slots'] as List<dynamic>;
        return list
            .map((e) => HrAvailabilitySlot.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // Shape B: [ ...slots... ]
      if (inner is List) {
        return inner
            .map((e) => HrAvailabilitySlot.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // Shape C: single slot object
      if (inner is Map<String, dynamic>) {
        return [HrAvailabilitySlot.fromJson(inner)];
      }

      debugPrint('⚠️ Unexpected bulk response shape: ${inner.runtimeType}');
      return [];
    } on DioException catch (e) {
      debugPrint('❌ BULK SUBMIT ERROR: ${e.response?.data}');
      throw e.error as ApiException;
    }
  }

  // ── 4. DELETE /hr/availability/{id} ───────────────────────────────────────
  Future<void> deleteAvailability(String id) async {
    try {
      await _dio.delete(
        ApiEndpoints.fill(
          ApiEndpoints.deleteAvailability,
          {'slotId': id},
        ),
      );

      debugPrint('✅ Slot $id deleted');
    } on DioException catch (e) {
      debugPrint('❌ DELETE ERROR: ${e.response?.data}');
      throw e.error as ApiException;
    }
  }

  // ── Unwrap helpers ────────────────────────────────────────────────────────

  /// Returns data["data"] as Map, or null.
  Map<String, dynamic>? _unwrapObject(dynamic response) {
    final raw = _unwrapRaw(response);
    if (raw == null) return null;
    if (raw is Map<String, dynamic>) return raw;
    debugPrint('⚠️ Expected Map but got ${raw.runtimeType}');
    return null;
  }

  /// Returns data["data"] raw (any type), or data itself if no "data" key.
  dynamic _unwrapRaw(dynamic response) {
    if (response is Map && response.containsKey('data')) {
      final inner = response['data'];
      debugPrint('🔍 UNWRAPPED PAYLOAD (${ inner.runtimeType}): $inner');
      return inner;
    }
    debugPrint('🔍 NO "data" KEY — returning as-is: $response');
    return response;
  }
}
