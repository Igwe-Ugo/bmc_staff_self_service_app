// lib/features/auth/providers/auth_provider.dart

import 'package:bmc_app/core/storage/secure_storage.dart';
import 'package:flutter/material.dart';
import '../api_client/widget.dart';
import '../models/widget.dart';
import '../../../core/errors/api_exceptions.dart';
import '../../../core/network/provider/widget.dart';
import '../services/widget.dart';

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

  Future<bool> login(
    String username,
    String password,
    UserProvider userProvider,
    PresenceProvider presenceProvider,
    ChatProvider chatProvider,
    DocumentProvider documentProvider,
    TeleMedicineProvider teleMedProvider,
  ) async {
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

      // The login response only carries a SUBSET of the profile (id,
      // username, name, email, privileges) — rank, profession, gender,
      // department, phone, address, and country only come from a full
      // GET /users/regular, which is what fetchMe() does. checkAuthStatus()
      // (the warm-start path) already calls this; without it here too, a
      // freshly logged-in user's Profile screen shows blank/missing fields
      // until something else (e.g. a profile save) happens to trigger a
      // full fetch as a side effect. id/defaultDept are already set from
      // setUserFromLogin above, so fetchMe() can use them with no args.
      await userProvider.fetchMe();

      // Fire-and-forget, same pattern as ProfileService.preload() in
      // login_screen.dart — warms the Documents screen's list before the
      // user ever opens it, rather than gating the login spinner on it.
      // personnelId (not id) is refId — see documents.dart.
      final personnelId = userProvider.user?.personnelId;
      if (personnelId != null && personnelId.isNotEmpty) {
        documentProvider.loadDocuments(personnelId);
      }
      teleMedProvider.loadVisits();

      // USERNAME, not response.user.id — the socket mesh's identity space is
      // the login username (uuid is REST-only). See socket_models.dart for
      // the full naming note; getting this backwards means messages are
      // silently delivered to a room nobody is in.
      presenceProvider.me = response.user.username;
      chatProvider.me = response.user.username;
      await SocketService.instance.connect();

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

  Future<void> forgotPassword(String email) async {
    _state = AuthState.loading;
    _errorTitle = null;
    _errorMessage = null;
    _errorStatusCode = null;
    notifyListeners();

    try {
      await _authServices.resetPassword(ForgotPasswordRequest(email: email));
      _state = AuthState.success;
      notifyListeners();
    } on ApiException catch (e) {
      _state = AuthState.error;
      _errorStatusCode = e.statusCode;
      _errorTitle = 'Reset Password Failed';
      _errorMessage = e.message;
      notifyListeners();
    } catch (_) {
      _state = AuthState.error;
      _errorTitle = 'Oops!';
      _errorMessage = 'An unexpected error occurred. Please try again.';
      _errorStatusCode = null;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    // Before clearing storage — this emits process-user-sign-out, which
    // clears this surface's presence flag immediately rather than waiting
    // on the server's disconnect handler to notice a dropped transport.
    await SocketService.instance.disconnect();

    await _authServices.logout();
    _state = AuthState.idle;
    _errorTitle = null;
    _errorMessage = null;
    _errorStatusCode = null;
    notifyListeners();
  }

  // Check if user is already logged in (e.g., on app start)
  // Call this from your router or app startup — this is the warm-start path,
  // so it connects the socket too (login() only covers the fresh-login path).
  Future<void> checkAuthStatus(
    UserProvider userProvider,
    PresenceProvider presenceProvider,
    ChatProvider chatProvider,
    DocumentProvider documentProvider,
    TeleMedicineProvider teleMedProvider,
  ) async {
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
      debugPrint('✅ User ID from login. userId = ${userProvider.user?.id}');

      final personnelId = userProvider.user?.personnelId;
      if (personnelId != null && personnelId.isNotEmpty) {
        documentProvider.loadDocuments(personnelId);
      }
      teleMedProvider.loadVisits();

      final username = userProvider.user?.username;
      if (username != null && username.isNotEmpty) {
        presenceProvider.me = username;
        chatProvider.me = username;
        await SocketService.instance.connect();
      }
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
