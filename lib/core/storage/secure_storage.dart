import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class SecureStorage {
  SecureStorage._();
  static final SecureStorage instance = SecureStorage._();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _accessTokenKey  = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _deviceIdKey     = 'device_id';   // ← persists across logouts

  // ── Access token ──────────────────────────────────────────────────────────
  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  Future<String?> getAccessToken() async {
    final token = await _storage.read(key: _accessTokenKey);
    return (token == null || token.isEmpty) ? null : token;
  }

  Future<void> deleteAccessToken() =>
      _storage.delete(key: _accessTokenKey);

  // ── Refresh token ─────────────────────────────────────────────────────────
  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  Future<String?> getRefreshToken() async {
    final token = await _storage.read(key: _refreshTokenKey);
    return (token == null || token.isEmpty) ? null : token;
  }

  Future<void> deleteRefreshToken() =>
      _storage.delete(key: _refreshTokenKey);

  // ── Device ID ─────────────────────────────────────────────────────────────
  /// Returns a stable UUID for this device installation.
  /// Minted once on first call, then reused forever — survives token wipes
  /// and logouts because clearAll() explicitly restores it.
  Future<String> getDeviceId() async {
    var id = await _storage.read(key: _deviceIdKey);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await _storage.write(key: _deviceIdKey, value: id);
      debugPrint('🆔 New device ID minted: $id');
    } else {
      debugPrint('🆔 Reusing device ID: $id');
    }
    return id;
  }

  // ── Clear all (logout / refresh failure) ──────────────────────────────────
  /// Wipes tokens but PRESERVES the device ID so the next login reuses the
  /// same session slot on the backend instead of claiming a new one.
  Future<void> clearAll() async {
    final deviceId = await _storage.read(key: _deviceIdKey);
    await _storage.deleteAll();
    if (deviceId != null && deviceId.isNotEmpty) {
      await _storage.write(key: _deviceIdKey, value: deviceId);
      debugPrint('🆔 Device ID preserved after clearAll');
    }
  }

  // ── Auth state ────────────────────────────────────────────────────────────
  Future<bool> hasValidSession() async {
    final access  = await getAccessToken();
    final refresh = await getRefreshToken();
    return access != null || refresh != null;
  }
}
