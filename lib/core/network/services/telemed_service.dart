import 'package:dio/dio.dart';
import '../api_client/widget.dart';
import '../models/widget.dart';

class TeleMedicineService {
  final Dio _dio = ApiClient.instance.dio;

  TeleMedicineService();

  Future<List<QryBookingVisits>> fetchBookingVisits() async {
    try {
      final response = await _dio.get(
        ApiEndpoints.teleMedGuests
      );

      if (response.statusCode == 200) {
        final List<dynamic> body = response.data;
        return body.map((json) => QryBookingVisits.fromJson(json)).toList();
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
