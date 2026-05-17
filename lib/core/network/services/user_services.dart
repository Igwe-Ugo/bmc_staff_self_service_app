import 'package:dio/dio.dart';
import '../../../core/errors/api_exceptions.dart';
import '../api_client/widget.dart';
import '../models/user_model.dart';

class UserServices {
  final Dio _dio = ApiClient.instance.dio;

  /// GET /users/me
  Future<UserModel> getMe() async {
    try {
      final response = await _dio.get(ApiEndpoints.me);
      final payload  = response.data['data'] ?? response.data;
      return UserModel.fromJson(payload as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.error as ApiException;
    }
  }

  /// GET /users/{id}
  Future<UserModel> getUserById(String id) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.fill(ApiEndpoints.userById, {'id': id}),
      );
      final payload = response.data['data'] ?? response.data;
      return UserModel.fromJson(payload as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.error as ApiException;
    }
  }

  /// PATCH /users/me — send only changed fields
  Future<UserModel> updateProfile(Map<String, dynamic> fields) async {
    try {
      final response = await _dio.patch(
        ApiEndpoints.updateProfile,
        data: fields,
      );
      final payload = response.data['data'] ?? response.data;
      return UserModel.fromJson(payload as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.error as ApiException;
    }
  }
}
