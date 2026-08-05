class ApiEndpoints {
  ApiEndpoints._();

  // ── Environment Configurations (Build-time injection) ─────────────────────
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String apiKey = String.fromEnvironment(
    'API_KEY',
    defaultValue: '',
  );

  static const int timeoutSeconds = int.fromEnvironment(
    'API_TIMEOUT_SECONDS',
    defaultValue: 15,
  );

  // The header name your backend expects
  static const String apiKeyHeader = 'x-api-key';

  /// Call this method at app startup (e.g., in lib/main.dart) to ensure 
  /// required build variables are provided before making network calls.
  static void validateEnv() {
    assert(
      baseUrl.isNotEmpty,
      'CRITICAL BUILD ERROR: API_BASE_URL was not provided at build time!',
    );
    assert(
      apiKey.isNotEmpty,
      'CRITICAL BUILD ERROR: API_KEY was not provided at build time!',
    );

    if (baseUrl.isEmpty || apiKey.isEmpty) {
      throw Exception(
        'Missing required environment variables. '
        'Ensure you run Flutter with --dart-define or --dart-define-from-file.',
      );
    }
  }

  // ── Routes ──────────────────────────────────────────────────────────────────
  static const String login = '/mobapp/auth/login';
  static const String logout = '/mobapp/auth/logout';
  static const String refresh = '/mobapp/auth/refresh';

  // ── Availability ────────────────────────────────────────────────────────────
  static const String availabilityCurrentWindow =
      '/hr/availability/windows/current';
  static const String availabilityMyCalendar = '/hr/availability/my-calendar';
  static const String availabilityBulk = '/hr/availability/bulk';
  static const String deleteAvailability = '/hr/availability/{slotId}';

  // ── Leave Request ───────────────────────────────────────────────────────────
  static const String leaveRequests = '/hr/leave/requests';
  static const String leaveMyRequests = '/hr/leave/my-requests';
  static const String leaveSearch = '/hr/leave/search';

  // ── Rota ────────────────────────────────────────────────────────────────────
  static const String rotaMyShifts = '/hr/rota/my-shifts';
  static const String requestRotaSwaps = '/hr/rota/swaps';
  static const String displayRotaSwaps = '/hr/rota/swaps';
  static const String personnel = '/hr/personnel';
  static const String deleteSwapRequest = '/hr/rota/swaps';
  static const String rotaPersonnelShifts = '/hr/rota/personnel-shifts';

  // ── Profile ─────────────────────────────────────────────────────────────────
  static const String usersRegular = '/users/regular';
  static const String updateProfile = '/users/profile';
  static const String worldCountries = '/system-apis/world-countries';

  static String fill(String path, Map<String, String> params) {
    var result = path;
    params.forEach((key, value) {
      result = result.replaceAll('{$key}', value);
    });
    return result;
  }
}
