import 'package:dio/dio.dart';
import '../api_client/widget.dart';
import '../models/widget.dart';

// tele_medicine_service.dart

class TeleMedicineService {
  final Dio _dio = ApiClient.instance.dio;

  TeleMedicineService();

  Future<List<QryBookingVisits>> fetchBookingVisits() async {
    try {
      final response = await _dio.get(ApiEndpoints.teleMedProviders);

      if (response.statusCode == 200) {
        final rawData = response.data;

        List<dynamic> listData = [];

        if (rawData is Map<String, dynamic>) {
          // Extract array from 'data' key or fallback to empty list
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
      } else {
        throw Exception(
          'Failed to load booking visits: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching booking visits: $e');
    }
  }
}
