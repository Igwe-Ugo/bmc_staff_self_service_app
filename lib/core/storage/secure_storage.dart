import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  SecureStorage._();
  static final SecureStorage instance = SecureStorage._();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _accessTokenKey  = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  // ── Access token ────────────────────────────────────────────────────────────
  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  Future<String?> getAccessToken() =>
      _storage.read(key: _accessTokenKey);

  Future<void> deleteAccessToken() =>
      _storage.delete(key: _accessTokenKey);

  // ── Refresh token ───────────────────────────────────────────────────────────
  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  Future<String?> getRefreshToken() =>
      _storage.read(key: _refreshTokenKey);

  Future<void> deleteRefreshToken() =>
      _storage.delete(key: _refreshTokenKey);

  // ── Clear all (on logout) ───────────────────────────────────────────────────
  Future<void> clearAll() => _storage.deleteAll();
}
