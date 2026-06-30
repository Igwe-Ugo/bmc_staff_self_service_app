// ─── rota_service.dart ────────────────────────────────────────────────────────

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/errors/api_exceptions.dart';
import '../../../core/network/api_client/widget.dart';
import '../../../core/network/models/widget.dart';

class RotaService {
  final Dio _dio = ApiClient.instance.dio;

  // ── 1. GET /api/hr/rota/my-shifts?month=YYYY-MM ─────────────────────────────
  Future<List<HrMyShift>> fetchMyShifts({String? month}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.rotaMyShifts,
        queryParameters: month != null ? {'month': month} : null,
      );

      debugPrint('📡 ROTA MY SHIFTS: ${response.statusCode}');
      debugPrint('📡 ROTA RESPONSE: ${response.data}');

      final payload = _unwrap(response.data);
      if (payload == null) return [];

      // Shape A: { shifts: [...] }
      if (payload is Map<String, dynamic> && payload.containsKey('shifts')) {
        final list = payload['shifts'] as List<dynamic>? ?? [];
        return list
            .map((e) => HrMyShift.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // Shape B: flat list
      if (payload is List) {
        return payload
            .map((e) => HrMyShift.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      debugPrint('⚠️ Unexpected my-shifts response shape: ${payload.runtimeType}');
      return [];
    } on DioException catch (e) {
      debugPrint('❌ ROTA MY SHIFTS ERROR: ${e.response?.data}');
      throw ApiException(
        message: _extractMessage(e.response?.data) ?? 'Failed to load your shifts.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  // ── 2. POST /api/hr/rota/swaps ────────────────────────────────────────────
  /// { fromAssignmentId, toAssignmentId, toPersonnelId, reason }
  /// Goes to admin for approval — returns the created (pending) swap record.
  Future<HrShiftSwap> createSwapRequest(HrSwapRequestPayload payload) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.rotaSwaps,
        data: payload.toJson(),
      );

      debugPrint('📡 SWAP REQUEST SUBMITTED: ${response.statusCode}');
      final data = _unwrap(response.data);
      return HrShiftSwap.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('❌ SWAP REQUEST ERROR: ${e.response?.data}');
      throw ApiException(
        message: _extractMessage(e.response?.data) ??
            'Failed to submit shift swap request',
        statusCode: e.response?.statusCode,
      );
    }
  }

  // ── 2. DELETE /api/hr/rota/swaps ────────────────────────────────────────────
  Future<HrShiftSwap> deleteSwapRequest(String swapId) async {
    try {
      final response = await _dio.delete(
        ApiEndpoints.rotaSwaps,
        data: swapId,
      );

      debugPrint('📡 SWAP REQUEST DELETED: ${response.statusCode}');
      final data = _unwrap(response.data);
      return HrShiftSwap.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('❌ SWAP DELETE ERROR: ${e.response?.data}');
      throw ApiException(
        message: _extractMessage(e.response?.data) ??
            'Failed to delete shift swap request',
        statusCode: e.response?.statusCode,
      );
    }
  }

  // ── 3. GET /api/hr/personnel ───────────────────────────────────────────────
  /// search params: deptId, includeDeptUsers=true, status=ACTIVE
  Future<List<StaffMember>> fetchDeptStaff(String deptId) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.personnel,
        queryParameters: {
          'deptId':           deptId,
          'includeDeptUsers': true,
          'status':           'ACTIVE',
        },
      );

      debugPrint('📡 DEPARTMENT PERSONNEL: ${response.statusCode}');
      final data = _unwrap(response.data);

      if (data is List) {
        return data
            .map((e) => StaffMember.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      // Shape: { personnel: [...] }
      if (data is Map<String, dynamic> && data.containsKey('personnel')) {
        final list = data['personnel'] as List<dynamic>? ?? [];
        return list
            .map((e) => StaffMember.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      debugPrint('❌ DEPARTMENT PERSONNEL ERROR: ${e.response?.data}');
      throw ApiException(
        message: _extractMessage(e.response?.data) ??
            'Failed to load department staff',
        statusCode: e.response?.statusCode,
      );
    }
  }

  // ── 4. GET /api/hr/rota/personnel-shifts ──────────────────────────────────
  /// search params: personnelId, periodId
  /// Returns the chosen staff member's shifts for the given rota period.
  Future<List<RotaEvent>> fetchPersonnelShifts({
    required String personnelId,
    required String periodId,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.rotaPersonnelShifts,
        queryParameters: {
          'personnelId': personnelId,
          'periodId':    periodId,
        },
      );

      debugPrint('📡 PERSONNEL SHIFTS: ${response.statusCode}');
      final data = _unwrap(response.data);

      if (data is List) {
        return data
            .map((e) => RotaEvent.fromMyShift(
          HrMyShift.fromJson(e as Map<String, dynamic>),
        ))
            .toList();
      }
      // Shape: { shifts: [...] }
      if (data is Map<String, dynamic> && data.containsKey('shifts')) {
        final list = data['shifts'] as List<dynamic>? ?? [];
        return list
            .map((e) => RotaEvent.fromMyShift(
          HrMyShift.fromJson(e as Map<String, dynamic>),
        ))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      debugPrint('❌ PERSONNEL SHIFTS ERROR: ${e.response?.data}');
      throw ApiException(
        message: _extractMessage(e.response?.data) ??
            'Failed to load shifts for this staff member',
        statusCode: e.response?.statusCode,
      );
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
