class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException({
    required this.message,
    this.statusCode,
  });

  factory ApiException.fromStatusCode(int code, [String? message]) {
    return ApiException(
      statusCode: code,
      message: message ?? _defaultMessage(code),
    );
  }

  static String _defaultMessage(int code) {
    switch (code) {
      case 400: return 'Bad request. Please check your input.';
      case 401: return 'Unauthorised. Please log in again.';
      case 403: return 'You do not have permission to do this.';
      case 404: return 'The requested resource was not found.';
      case 409: return 'Conflict. This resource already exists.';
      case 422: return 'Validation failed. Please check your input.';
      case 429: return 'Too many requests. Please slow down.';
      case 500: return 'Server error. Please try again later.';
      default:  return 'An unexpected error occurred.';
    }
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
