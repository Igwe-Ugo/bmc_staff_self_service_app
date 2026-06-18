import 'package:flutter/material.dart';
import '../../../core/errors/api_exceptions.dart';
import '../models/user_model.dart';
import '../services/user_services.dart';

enum UserState { idle, loading, success, error }

class UserProvider extends ChangeNotifier {
  final UserServices _userServices = UserServices();

  UserModel? _user;
  UserState _state = UserState.idle;
  String? _errorMessage;

  // ── Getters ─────────────────────────────────────────────────────────────────
  UserModel? get user => _user;
  UserState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == UserState.loading;
  bool get hasUser => _user != null;
  bool get hasAvatar => _user?.image != null && _user!.image!.isNotEmpty;

  String get displayName => _user?.name ?? '';
  String get initials => _user?.initials ?? '';
  String get email => _user?.email ?? '';
  String? get avatar => _user?.image;
  String get defaultDept => _user?.defaultDept ?? '';

  bool hasPrivilege(String privilege) =>
      _user?.hasPrivilege(privilege) ?? false;

  // ── Set from Login ─────────────────────────────────────────────────────────
  void setUserFromLogin(UserModel user) {
    _user = user;
    _state = UserState.success;
    notifyListeners();
    debugPrint('✅ User set from login. personnelId = ${user.personnelId}');
  }

  // ── UPDATED: Merge refresh data (preserves missing fields like personnelId) ──
  void updateFromRefresh(Map<String, dynamic> refreshPayload) {
    final userDataFromRefresh = refreshPayload['user'] as Map<String, dynamic>?;

    if (userDataFromRefresh == null) {
      debugPrint('⚠️ No user data in refresh payload');
      return;
    }

    if (_user == null) {
      _user = UserModel.fromJson(userDataFromRefresh);
    } else {
      // Merge strategy: Keep existing data + override with new data
      final existingJson = _user!.toJson();

      final mergedJson = {
        ...existingJson,           // Keep old data (especially personnelId)
        ...userDataFromRefresh,    // Override with fresh data
      };

      _user = UserModel.fromJson(mergedJson);
      debugPrint('✅ User merged from refresh. personnelId = ${_user?.personnelId}');
    }

    _state = UserState.success;
    notifyListeners();
  }

  // ── Fetch full user profile ────────────────────────────────────────────────
  Future<void> fetchMe() async {
    _setState(UserState.loading);
    try {
      _user = await _userServices.getUser();
      _setState(UserState.success);
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setState(UserState.error);
    } catch (_) {
      _errorMessage = 'Failed to load profile.';
      _setState(UserState.error);
    }
  }

  void clear() {
    _user = null;
    _state = UserState.idle;
    _errorMessage = null;
    notifyListeners();
  }

  void _setState(UserState state) {
    _state = state;
    if (state != UserState.error) _errorMessage = null;
    notifyListeners();
  }
}
