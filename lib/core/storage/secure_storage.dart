import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  SecureStorage._();
  static final SecureStorage instance = SecureStorage._();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock),
  );

  static const _accessTokenKey  = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  // ── Access token ──────────────────────────────────────────────────────────
  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  Future<String?> getAccessToken() async {
    final token = await _storage.read(key: _accessTokenKey);
    // Return null if empty string — avoids sending "Bearer "
    return (token == null || token.isEmpty) ? null : token;
  }

  Future<void> deleteAccessToken() =>
      _storage.delete(key: _accessTokenKey);

  // ── Refresh token ─────────────────────────────────────────────────────────
  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  Future<String?> getRefreshToken() async {
    final token = await _storage.read(key: _refreshTokenKey);
    // Return null if empty string — avoids sending empty refresh token
    return (token == null || token.isEmpty) ? null : token;
  }

  Future<void> deleteRefreshToken() =>
      _storage.delete(key: _refreshTokenKey);

  // ── Clear all (on logout / refresh failure) ───────────────────────────────
  Future<void> clearAll() {
    debugPrint('⚠️ clearAll() called — stack: ${StackTrace.current}');
    return _storage.deleteAll();
  }

  // ── Check auth state ──────────────────────────────────────────────────────
  Future<bool> hasValidSession() async {
    final access  = await getAccessToken();
    final refresh = await getRefreshToken();
    return access != null || refresh != null;
  }
}
