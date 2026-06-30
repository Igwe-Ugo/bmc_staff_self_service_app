// lib/features/auth/providers/auth_provider.dart

import 'package:bmc_app/core/storage/secure_storage.dart';
import 'package:flutter/material.dart';
import '../api_client/widget.dart';
import '../models/widget.dart';
import '../services/auth_services.dart';
import '../../../core/errors/api_exceptions.dart';
import 'widget.dart';

enum AuthState { idle, loading, success, error }

class AuthProvider extends ChangeNotifier {
  final AuthServices _authServices = AuthServices();

  String? _token;
  String? get token => _token;

  AuthState _state = AuthState.idle;
  String? _errorTitle;
  String? _errorMessage;
  int? _errorStatusCode;

  AuthState get state => _state;
  String? get errorTitle => _errorTitle;
  String? get errorMessage => _errorMessage;
  int? get errorStatusCode => _errorStatusCode;
  bool get isLoading => _state == AuthState.loading;
  bool get isAuthenticated => _state == AuthState.success;

  Future<bool> login(String username, String password, UserProvider userProvider) async {
    _state = AuthState.loading;
    _errorTitle = null;
    _errorMessage = null;
    _errorStatusCode = null;
    notifyListeners();

    try {
      final LoginResponse response = await _authServices.login(
        LoginRequest(username: username, password: password),
      );
      // ✅ Seed UserProvider directly from the login response
      userProvider.setUserFromLogin(response.user);
      _state = AuthState.success;
      notifyListeners();
      return true;

    } on ApiException catch (e) {
      _state = AuthState.error;
      _errorStatusCode = e.statusCode;

      // Fixed the switch syntax
      switch (e.statusCode) {
        case 401:
          _errorTitle = 'Invalid Credentials';
          _errorMessage = e.message;
          break;
        case 403:
          _errorTitle = 'Account Restricted';
          _errorMessage = e.message;
          break;
        case 404:
          _errorTitle = 'Account Not Found';
          _errorMessage = e.message;
          break;
        case 422:
          _errorTitle = 'Validation Error';
          _errorMessage = e.message;
          break;
        case 429:
          _errorTitle = 'Too Many Attempts';
          _errorMessage = e.message;
          break;
        case 500:
          _errorTitle = 'Server Error';
          _errorMessage = e.message;
          break;
        default:
          _errorTitle = 'Login Failed';
          _errorMessage = e.message;
          print(_errorMessage);
      }

      notifyListeners();
      return false;

    } catch (_) {
      _state = AuthState.error;
      _errorTitle = 'Oops!';
      _errorMessage = 'An unexpected error occurred. Please try again.';
      _errorStatusCode = null;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authServices.logout();
    _state = AuthState.idle;
    _errorTitle = null;
    _errorMessage = null;
    _errorStatusCode = null;
    notifyListeners();
  }

  // Check if user is already logged in (e.g., on app start)
  // Call this from your router or app startup
  Future<void> checkAuthStatus(UserProvider userProvider) async {
    final hasSession = await SecureStorage.instance.hasValidSession();

    if (!hasSession) {
      // No tokens at all — go straight to login
      _state = AuthState.idle;
      return;
    }

    // Has tokens — try to load user
    try {
      await userProvider.fetchMe();
      _state = AuthState.success;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        // Token expired AND refresh failed — clear and force login
        await SecureStorage.instance.clearAll();
        userProvider.clear();
        _state = AuthState.idle;
      }
    }
  }

  void reset() {
    _token = null;
    _state = AuthState.idle;

    // Explicitly strip headers from the dynamic ApiClient instance here as a safety net
    ApiClient.instance.dio.options.headers.remove('Authorization');

    _state = AuthState.idle;
    _errorTitle = null;
    _errorMessage = null;
    _errorStatusCode = null;
    notifyListeners();
  }
}
