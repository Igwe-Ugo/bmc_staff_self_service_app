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
  static const String login = '/mobapp/auth/login';
  static const String logout = '/mobapp/auth/logout';
  static const String refresh = '/mobapp/auth/refresh';

  // ── Availability ──────────────────────────────────────────────────────────────
  static const String availabilityCurrentWindow = '/hr/availability/windows/current'; // getting the open window and can only be seen when made available. WHich would be readonly when not available
  static const String availabilityMyCalendar = '/hr/availability/my-calendar'; // fetches the calandar itself.
  static const String availabilityBulk = '/hr/availability/bulk'; // for saving the availability
  static const String deleteAvailability = '/hr/availability/{slotId}'; // for deleting the availability

  static String fill(String path, Map<String, String> params) {
    var result = path;
    params.forEach((key, value) {
      result = result.replaceAll('{$key}', value);
    });
    return result;
  }
}
