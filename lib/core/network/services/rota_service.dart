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
      final responseData = response.data['data'] ?? response.data;
      if (responseData == null) return [];

      // unwrap the present 'data' wrapper if present
      dynamic coreData = responseData['data'] ?? responseData;

      // handle the nested shifts map response structure safely
      if (coreData is Map<String, dynamic> && coreData.containsKey('shifts')) {
        final List<dynamic>? shiftsList = coreData['shifts'] as List<dynamic>?;
        if (shiftsList != null){
          return shiftsList.map((e) => HrMyShift.fromJson(e as Map<String, dynamic>)).toList();
        }
      }

      // fallback if data is a raw direct array list
      if (coreData is List) {
        return responseData.map((e) => HrMyShift.fromJson(e as Map<String, dynamic>)).toList();
      }
      debugPrint('⚠️ Unexpected response format: ${responseData.runtimeType}');
      return [];
    } on DioException catch (e) {
      debugPrint('❌ ROTA MY SHIFTS ERROR: ${e.response?.data}');
      throw ApiException(
        message: e.response?.data?['message'] ?? 'Failed to load your shifts.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  // ── POST /api/hr/rota/swap-requests ───────────────────────────────────────
  Future<bool> createSwapRequest(HrSwapRequestPayload payload) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.rotaSwapRequests,
        data: payload.toJson(),
      );

      debugPrint('📡 SWAP REQUEST SUBMITTED: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      debugPrint('❌ SWAP REQUEST ERROR: ${e.response?.data}');
      throw ApiException(
        message: e.response?.data?['message'] ?? 'Failed to submit shift swap request',
        statusCode: e.response?.statusCode,
      );
    }
  }

  // ── GET /api/hr/rota/eligible-staff?shiftId=xxx ───────────────────────────
  Future<List<RotaEvent>> fetchDeptStaffShift(String personnelId, String periodId) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.rotaDeptStaffShift,
        queryParameters: {'personnelId': personnelId, 'periodId': periodId},
      );

      debugPrint('📡 DEPARTMENT STAFF SHIFT: ${response.statusCode}');
      final data = response.data['data'] ?? response.data;

      if (data is List) {
        return data.map((e) => RotaEvent.fromMyShift(HrMyShift.fromJson(e as Map<String, dynamic>))).toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      debugPrint('❌ DEPARTMENT STAFF SHIFT ERROR: ${e.response?.data}');
      throw ApiException(
        message: e.response?.data?['message'] ?? 'Failed to load Department staff shift',
        statusCode: e.response?.statusCode,
      );
    }
  }

  // WIll work on this later, this is meant to fetch the department of the staff directly.
  Future<List<StaffMember>> fetchDeptStaff(String deptId) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.rotaDeptStaff,
        queryParameters: {'deptId': deptId, 'includeDeptUsers': true, 'status': 'ACTIVE'},
      );

      debugPrint('📡 DEPARTMENT STAFF: ${response.statusCode}');
      final data = response.data['data'] ?? response.data;

      if (data is List) {
        return data.map((e) => StaffMember.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      debugPrint('❌ DEPARTMENT STAFF ERROR: ${e.response?.data}');
      throw ApiException(
        message: e.response?.data?['message'] ?? 'Failed to load Department staff',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
