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

      // If response is null
      if (response.data == null) {
        debugPrint('⚠️ Null response from calendar');
        return [];
      }

      // Unwrap outer "data" envelope
      dynamic inner;
      if (response.data is Map<String, dynamic> && response.data.containsKey('data')) {
        inner = response.data['data'];
      } else {
        inner = response.data;
      }

      if (inner == null) {
        return [];
      }

      // Get slots from envelope
      List<dynamic> slotsList = [];
      if (inner is Map<String, dynamic>) {
        slotsList = inner['slots'] as List<dynamic>? ?? [];
      } else if (inner is List<dynamic>) {
        slotsList = inner;
      }

      debugPrint('✅ ${slotsList.length} slot(s) found for $month');

      final List<HrAvailabilitySlot> results = [];
      for (final slotJson in slotsList) {
        try {
          if (slotJson is Map<String, dynamic>) {
            results.add(HrAvailabilitySlot.fromJson(slotJson));
          }
        } catch (e) {
          debugPrint('❌ Error parsing slot: $e');
        }
      }

      return results;
    } on DioException catch (e) {
      debugPrint('❌ CALENDAR ERROR: ${e.response?.data}');
      throw ApiException(
        message: e.response?.data?['message'] ?? 'Failed to fetch calendar',
        statusCode: e.response?.statusCode,
      );
    }
  }

  // ── 3. POST /hr/availability/bulk ─────────────────────────────────────────
  /// Submits one or more availability slots at once.
  /// API may return { "data": { "personnelId": ..., "slots": [...] } }
  /// or { "data": [ ...slots... ] } — handles both.
  Future<List<HrAvailabilitySlot>> submitBulk(
      HrAvailabilityBulkFormData formData,
      ) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.availabilityBulk,
        data: formData.toJson(),
      );

      debugPrint('📡 BULK SUBMIT STATUS: ${response.statusCode}');
      debugPrint('📡 BULK SUBMIT RESPONSE: ${response.data}');

      // If response is null
      if (response.data == null) {
        debugPrint('⚠️ Null response from bulk submit');
        return [];
      }

      // Get the inner data
      dynamic inner;
      if (response.data is Map<String, dynamic> && response.data.containsKey('data')) {
        inner = response.data['data'];
      } else {
        inner = response.data;
      }

      debugPrint('📡 Inner data type: ${inner.runtimeType}');
      debugPrint('📡 Inner data: $inner');

      // If inner is null
      if (inner == null) {
        return [];
      }

      // Try to parse as list of slots
      List<dynamic> slotsList = [];

      if (inner is List<dynamic>) {
        slotsList = inner;
      } else if (inner is Map<String, dynamic>) {
        // Check if it has a 'slots' key
        if (inner.containsKey('slots')) {
          slotsList = inner['slots'] as List<dynamic>? ?? [];
        } else {
          // Single slot object
          slotsList = [inner];
        }
      }

      debugPrint('📡 Parsing ${slotsList.length} slots');

      // Parse each slot
      final List<HrAvailabilitySlot> results = [];
      for (final slotJson in slotsList) {
        try {
          if (slotJson is Map<String, dynamic>) {
            final slot = HrAvailabilitySlot.fromJson(slotJson);
            results.add(slot);
            debugPrint('✅ Parsed slot: ${slot.id} - ${slot.date}');
          } else {
            debugPrint('⚠️ Slot is not a Map: ${slotJson.runtimeType}');
          }
        } catch (e, stackTrace) {
          debugPrint('❌ Error parsing slot: $e');
          debugPrint('Stack trace: $stackTrace');
          debugPrint('Slot JSON: $slotJson');
        }
      }

      return results;
    } on DioException catch (e) {
      debugPrint('❌ BULK SUBMIT ERROR: ${e.response?.data}');
      debugPrint('❌ Error details: ${e.message}');
      throw ApiException(
        message: e.response?.data?['message'] ?? 'Failed to submit availability',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      debugPrint('❌ Unexpected error in submitBulk: $e');
      throw ApiException(message: e.toString());
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
