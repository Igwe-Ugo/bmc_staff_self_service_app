import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/errors/api_exceptions.dart';
import '../api_client/widget.dart';
import '../models/availability_model.dart';

class AvailabilityServices {
  final Dio _dio = ApiClient.instance.dio;

  // ── 1. GET /hr/availability/windows/current ───────────────────────────────
  /// Fetches the currently active availability window set by admin.
  /// Returns null if no window is currently active.
  Future<HrAvailabilityWindow?> getCurrentWindow() async {
    try {
      final response = await _dio.get(ApiEndpoints.availabilityCurrentWindow);

      debugPrint('📡 STATUS CODE: ${response.statusCode}');
      debugPrint('📡 FULL RESPONSE: ${response.data}');   // ← Raw response

      final payload = _unwrap(response.data);
      if (payload == null) return null;
      print('PAYLOAD ===> ${response.data}');
      return HrAvailabilityWindow.fromJson(payload as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('❌ API ERROR: ${e.response?.data}');
      throw e.error as ApiException;
    }
  }

  // ── 2. GET /hr/availability/my-calendar?month=YYYY-MM ────────────────────
  /// Fetches the logged-in user's availability slots for a given month.
  Future<List<HrAvailabilitySlot>> getMyCalendar(String month) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.availabilityMyCalendar,
        queryParameters: {'month': month},
      );
      final payload = _unwrap(response.data);
      return (payload as List<dynamic>)
          .map((e) => HrAvailabilitySlot.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw e.error as ApiException;
    }
  }

  // ── 3. POST /hr/availability/bulk ─────────────────────────────────────────
  /// Submits one or more availability slots at once.
  /// The single-slot case is just a bulk with one item in the slots array.
  Future<List<HrAvailabilitySlot>> submitBulk(
      HrAvailabilityBulkFormData formData) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.availabilityBulk,
        data: formData.toJson(),
      );
      final payload = _unwrap(response.data);

      // API may return a single object or a list — handle both
      if (payload is List) {
        return payload
            .map((e) => HrAvailabilitySlot.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (payload is Map<String, dynamic>) {
        return [HrAvailabilitySlot.fromJson(payload)];
      }
      return [];
    } on DioException catch (e) {
      throw e.error as ApiException;
    }
  }

  // ── 4. DELETE /hr/availability/{id} ───────────────────────────────────────
  Future<void> deleteAvailability(String slotId) async {
    try {
      final response = await _dio.delete(
        ApiEndpoints.fill(ApiEndpoints.deleteAvailability, {'slotId': slotId}),
      );
      _unwrap(response.data);
    } on DioException catch (e) {
      throw e.error as ApiException;
    }
  }

  // ── Helper ────────────────────────────────────────────────────────────────
  // Add this at the top of the class or inside methods
  dynamic _unwrap(dynamic data) {
    final payload = (data is Map && data.containsKey('data')) ? data['data'] : data;

    // 🔥 Print payload for debugging
    debugPrint('🔍 API PAYLOAD: $payload');
    if (payload != null) {
      debugPrint('🔍 PAYLOAD TYPE: ${payload.runtimeType}');
    }

    return payload;
  }
}
