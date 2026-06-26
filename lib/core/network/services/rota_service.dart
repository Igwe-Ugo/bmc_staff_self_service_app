// lib/features/rota/services/rota_service.dart
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/errors/api_exceptions.dart';
import '../../../core/network/api_client/widget.dart';
import '../../../core/network/models/widget.dart';

class RotaService {
  final Dio _dio = ApiClient.instance.dio;

  // ── GET /api/hr/rota/my-shifts?month=YYYY-MM ───────────────────────────────
  Future<List<HrMyShift>> fetchMyShifts({String? month}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.rotaMyShifts,
        queryParameters: month != null ? {'month': month} : null,
      );

      debugPrint('📡 ROTA MY SHIFTS: ${response.statusCode}');
      debugPrint('📡 ROTA RESPONSE: ${response.data}');

      // Handle the response structure
      final responseData = response.data;

      // Check if we have data
      if (responseData == null) {
        return [];
      }

      // Get the data object
      dynamic data = responseData['data'] ?? responseData;

      // If data is a Map with 'shifts' key, extract the shifts array
      if (data is Map<String, dynamic> && data.containsKey('shifts')) {
        final shiftsList = data['shifts'] as List<dynamic>?;
        if (shiftsList != null) {
          return shiftsList
              .map((e) => HrMyShift.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return [];
      }

      // If data is already a List (fallback)
      if (data is List) {
        return data
            .map((e) => HrMyShift.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // If data is a single shift object
      if (data is Map<String, dynamic> && data.containsKey('assignmentId')) {
        return [HrMyShift.fromJson(data)];
      }

      debugPrint('⚠️ Unexpected response format: ${data.runtimeType}');
      return [];
    } on DioException catch (e) {
      debugPrint('❌ ROTA MY SHIFTS ERROR: ${e.response?.data}');
      throw ApiException(
        message: e.response?.data?['message'] ?? 'Failed to load shifts',
        statusCode: e.response?.statusCode,
      );
    }
  }

  // ── POST /api/hr/rota/swap-requests ───────────────────────────────────────
  Future<HrShiftSwapResponse> submitSwapRequest(HrSwapRequestPayload payload) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.rotaSwapRequests,
        data: payload.toJson(),
      );

      debugPrint('📡 SWAP REQUEST SUBMITTED: ${response.statusCode}');
      final data = response.data['data'] ?? response.data;
      return HrShiftSwapResponse.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('❌ SWAP REQUEST ERROR: ${e.response?.data}');
      throw ApiException(
        message: e.response?.data?['message'] ?? 'Failed to submit swap request',
        statusCode: e.response?.statusCode,
      );
    }
  }

  // ── GET /api/hr/rota/eligible-staff?shiftId=xxx ───────────────────────────
  Future<List<StaffMember>> fetchEligibleStaff(String shiftId) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.rotaEligibleStaff,
        queryParameters: {'shiftId': shiftId},
      );

      debugPrint('📡 ELIGIBLE STAFF: ${response.statusCode}');
      final data = response.data['data'] ?? response.data;

      if (data is List) {
        return data.map((e) => StaffMember.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      debugPrint('❌ ELIGIBLE STAFF ERROR: ${e.response?.data}');
      throw ApiException(
        message: e.response?.data?['message'] ?? 'Failed to load eligible staff',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
