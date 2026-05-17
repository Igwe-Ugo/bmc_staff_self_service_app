import 'package:bmc_app/core/network/models/widget.dart';

class LoginRequest {
  final String username;
  final String password;

  LoginRequest({
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'username': username,
    'password': password,
  };
}

class LoginResponse {
  final String    accessToken;
  final String?   refreshToken;
  final String    tokenType;
  final int?      expiresIn;
  final UserModel user;

  const LoginResponse({
    required this.accessToken,
    this.refreshToken,
    this.tokenType = 'Bearer',
    this.expiresIn,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    // Unwrap { data: { ... } } envelope if present
    final payload = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : json;

    // ── Access token ──────────────────────────────────────────────────────────
    final accessToken = payload['accessToken']?.toString()
        ?? payload['access_token']?.toString()
        ?? payload['token']?.toString()
        ?? '';

    if (accessToken.isEmpty) {
      throw Exception('No access token found in response: $json');
    }

    // ── Refresh token ─────────────────────────────────────────────────────────
    final refreshToken = payload['refreshToken']?.toString()
        ?? payload['refresh_token']?.toString();

    // ── Token type ────────────────────────────────────────────────────────────
    final tokenType = payload['tokenType']?.toString()
        ?? payload['token_type']?.toString()
        ?? 'Bearer';

    // ── Expires in ────────────────────────────────────────────────────────────
    // ✅ Safely parse whether it comes as int, String, or double
    final expiresIn = _parseInt(
      payload['expiresIn'] ?? payload['expires_in'],
    );

    // ── Nested user ───────────────────────────────────────────────────────────
    final userJson = payload['user'];
    if (userJson == null || userJson is! Map<String, dynamic>) {
      throw Exception('No user object found in response: $json');
    }

    return LoginResponse(
      accessToken:  accessToken,
      refreshToken: refreshToken,
      tokenType:    tokenType,
      expiresIn:    expiresIn,
      user:         UserModel.fromJson(userJson),
    );
  }

  /// Safely converts anything the API might send into an int?.
  /// Handles: int → int, String → parsed int, double → truncated int, null → null.
  static int? _parseInt(dynamic value) {
    if (value == null)          return null;
    if (value is int)           return value;
    if (value is double)        return value.toInt();
    if (value is String)        return int.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() => {
    'accessToken':  accessToken,
    'refreshToken': refreshToken,
    'tokenType':    tokenType,
    'expiresIn':    expiresIn,
    'user':         user.toJson(),
  };
}
