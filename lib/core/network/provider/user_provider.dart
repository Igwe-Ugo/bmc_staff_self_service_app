// user_provider.dart
import 'package:flutter/material.dart';
import '../../../core/errors/api_exceptions.dart';
import '../models/user_model.dart';
import '../services/user_services.dart';

enum UserState { idle, loading, success, error }

class UserProvider extends ChangeNotifier {
  final UserServices _userServices = UserServices();

  UserModel? _user;
  UserState  _state        = UserState.idle;
  String?    _errorMessage;
  bool       _updating     = false;  // separate flag for profile update

  // ── Getters ───────────────────────────────────────────────────────────────
  UserModel? get user          => _user;
  UserState  get state         => _state;
  String?    get errorMessage  => _errorMessage;
  bool       get isLoading     => _state == UserState.loading;
  bool       get isUpdating    => _updating;
  bool       get hasUser       => _user != null;
  bool       get hasAvatar     => _user?.image != null && _user!.image!.isNotEmpty;

  String  get displayName  => _user?.name     ?? '';
  String  get initials     => _user?.initials ?? '';
  String  get email        => _user?.email    ?? '';
  String? get avatar       => _user?.image;
  String  get defaultDept  => _user?.defaultDept ?? '';

  // Extended profile getters
  String get address  => _user?.address  ?? '';
  String get city     => _user?.city     ?? '';
  String get state_   => _user?.state    ?? '';   // 'state' clashes with State<T>
  String get country  => _user?.country  ?? '';
  String get telno    => _user?.telno    ?? '';
  String get gender   => _user?.gender   ?? '';
  String get rank     => _user?.rank     ?? '';
  String get profession => _user?.profession ?? '';

  bool hasPrivilege(String privilege) => _user?.hasPrivilege(privilege) ?? false;

  // ── Set from Login ────────────────────────────────────────────────────────
  void setUserFromLogin(UserModel user) {
    _user  = user;
    _state = UserState.success;
    notifyListeners();
    debugPrint('✅ User set from login. personnelId = ${user.personnelId}');
  }

  // ── Merge from Token Refresh ──────────────────────────────────────────────
  void updateFromRefresh(Map<String, dynamic> refreshPayload) {
    final fresh = refreshPayload['user'] as Map<String, dynamic>?;
    if (fresh == null) {
      debugPrint('⚠️ No user data in refresh payload');
      return;
    }

    if (_user == null) {
      _user = UserModel.fromJson(fresh);
    } else {
      _user = UserModel.fromJson({
        ..._user!.toJson(),  // preserve existing (especially personnelId)
        ...fresh,            // override with refreshed data
      });
      debugPrint('✅ User merged from refresh. personnelId = ${_user?.personnelId}');
    }

    _state = UserState.success;
    notifyListeners();
  }

  // ── Fetch full user profile ───────────────────────────────────────────────
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

  // ── Update profile ────────────────────────────────────────────────────────
  /// Calls PATCH /api/users/profile and merges the returned user into state.
  /// Returns `true` on success, `false` on failure.
  /// Uses a separate `_updating` flag so the rest of the UI is unaffected.
  Future<bool> updateProfile(UserProfileUpdateData data) async {
    _updating     = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _userServices.updateProfile(data);

      // Merge: keep any fields the PATCH response doesn't return
      _user = UserModel.fromJson({
        ...(_user?.toJson() ?? {}),
        ...updated.toJson(),
      });

      _updating = false;
      notifyListeners();
      debugPrint('✅ Profile updated successfully');
      return true;

    } on ApiException catch (e) {
      _errorMessage = e.message;
      _updating     = false;
      notifyListeners();
      debugPrint('❌ Profile update failed: ${e.message}');
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred.';
      _updating     = false;
      notifyListeners();
      return false;
    }
  }

  // ── Clear (logout) ────────────────────────────────────────────────────────
  void clearUser() {
    _user         = null;
    _state        = UserState.idle;
    _errorMessage = null;
    _updating     = false;
    notifyListeners();
  }

  void _setState(UserState s) {
    _state = s;
    if (s != UserState.error) _errorMessage = null;
    notifyListeners();
  }
}
