// lib/features/services/tele_medicine_service.dart

import 'package:dio/dio.dart';
import '../../../core/errors/api_exceptions.dart';
import '../api_client/widget.dart';
import '../models/widget.dart';
import 'package:flutter/material.dart';

class TeleMedicineService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<QryBookingVisits>> fetchBookingVisits() async {
    try {
      final response = await _dio.get(ApiEndpoints.teleMedProviders);
      final rawData = response.data;
      List<dynamic> listData = [];

      if (rawData is Map<String, dynamic>) {
        listData = (rawData['data'] is List)
            ? rawData['data'] as List<dynamic>
            : [];
      } else if (rawData is List<dynamic>) {
        listData = rawData;
      }

      return listData
          .map(
            (json) => QryBookingVisits.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (e) {
      throw ApiException(
        message:
            _extractMessage(e.response?.data) ??
            'Failed to load booking visits.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  // PATCH /api/patients/visits/consultant-ready
  Future<void> setConsultantReady({required QryBookingVisits data}) async {
    final body = data.toJson();
    if (body.length <= 1) {
      throw ApiException(message: 'No changes to save.', statusCode: null);
    }

    debugPrint('[setConsultantReady] → PATCH ${ApiEndpoints.consultantReady}');
    debugPrint(
      '[setConsultantReady] → visitId: ${body['visitId']}, consultantReady: ${body['consultantReady']}',
    );

    try {
      final response = await _dio.patch(
        ApiEndpoints.consultantReady,
        data: body,
      );

      debugPrint('[setConsultantReady] ✓ status: ${response.statusCode}');
      debugPrint('[setConsultantReady] ✓ response: ${response.data}');
      debugPrint('📡 PATCH : ${response.statusCode}');
    } on DioException catch (e) {
      debugPrint('[setConsultantReady] ✗ status: ${e.response?.statusCode}');
      debugPrint('[setConsultantReady] ✗ response: ${e.response?.data}');
      debugPrint('[setConsultantReady] ✗ uri: ${e.requestOptions.uri}');

      throw ApiException(
        message:
            _extractMessage(e.response?.data) ??
            'Failed to set consultant status.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  // POST /api/patients/booking-visits/telemedicine/get-link (Consultant)
  Future<String> getTelemedicineLink({required JoinTeleMedLink data}) async {
    final body = data.toJson();
    try {
      final response = await _dio.post(
        ApiEndpoints.telemedicineGetLink,
        data: {'data': body},
      );

      final joinLink = response.data?['data']?.toString();
      if (joinLink == null || joinLink.isEmpty) {
        throw const ApiException(
          message: 'Server did not return a valid join link.',
        );
      }
      print('response: $response');
      return joinLink;
    } on DioException catch (e) {
      throw ApiException(
        message:
            _extractMessage(e.response?.data) ?? 'Failed to fetch join link.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  // POST /api/patients/booking-visits/telemedicine/get-link (Guest/Patient)
  Future<String> getTelemedicineLinkForGuest({required String visitId}) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.telemedicineGetLink,
        data: {
          'data': {'visitId': visitId},
        },
      );

      final joinLink = response.data?['data']?.toString();
      if (joinLink == null || joinLink.isEmpty) {
        throw const ApiException(message: 'Server did not return a join link.');
      }
      return joinLink;
    } on DioException catch (e) {
      throw ApiException(
        message:
            _extractMessage(e.response?.data) ?? 'Failed to fetch guest link.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  String? _extractMessage(dynamic data) {
    if (data is Map) {
      return data['message']?.toString() ?? data['error']?.toString();
    }
    return null;
  }
}
