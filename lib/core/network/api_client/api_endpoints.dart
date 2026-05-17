import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiEndpoints {
  ApiEndpoints._();

  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? '';

  static int get timeoutSeconds =>
      int.tryParse(dotenv.env['API_TIMEOUT_SECONDS'] ?? '15') ?? 15;

  // ✅ Read the API key from .env
  static String get apiKey =>
      dotenv.env['API_KEY'] ?? '';

  // ✅ The header name your backend expects
  static const String apiKeyHeader = 'x-api-key';

  // Routes
  static const String login          = '/mobapp/auth/login';
  static const String logout         = '/mobapp/auth/logout';
  static const String refresh        = '/mobapp/auth/refresh';
  static const String me             = '/users/me';
  static const String userById       = '/users/{id}';
  static const String updateProfile  = '/users/me';
  static const String uploadDocument = '/users/me/documents';
  static const String deleteDocument = '/users/me/documents/{id}';

  static String fill(String path, Map<String, String> params) {
    var result = path;
    params.forEach((key, value) {
      result = result.replaceAll('{$key}', value);
    });
    return result;
  }
}
