import 'package:flutter/material.dart';
import '../../../core/errors/api_exceptions.dart';
import '../models/user_model.dart';
import '../services/user_services.dart';

enum UserState { idle, loading, success, error }

class UserProvider extends ChangeNotifier {
  final UserServices _userServices = UserServices();

  UserModel?  _user;
  UserState   _state        = UserState.idle;
  String?     _errorMessage;

  // ── Getters ─────────────────────────────────────────────────────────────────
  UserModel?  get user         => _user;
  UserState   get state        => _state;
  String?     get errorMessage => _errorMessage;
  bool        get isLoading    => _state == UserState.loading;
  bool        get hasUser      => _user != null;
  bool get hasAvatar => _user?.image != null && _user!.image!.isNotEmpty;

  // Convenience pass-throughs so widgets don't import UserModel directly
  String  get displayName => _user?.name       ?? '';
  String  get initials    => _user?.initials   ?? '';
  String  get email       => _user?.email      ?? '';
  String? get avatar      => _user?.image;
  String get defaultDept => _user?.defaultDept ?? '';

  bool hasPrivilege(String privilege) =>
      _user?.hasPrivilege(privilege) ?? false;

  // ── Seed user from login (no extra API call needed) ──────────────────────────
  void setUserFromLogin(UserModel user) {
    _user  = user;
    _state = UserState.success;
    notifyListeners();
  }

  // ── Fetch current user from API ──────────────────────────────────────────────
  Future<void> fetchMe() async {
    _setState(UserState.loading);

    try {
      _user = await _userServices.getMe();
      _setState(UserState.success);
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setState(UserState.error);
    } catch (_) {
      _errorMessage = 'Failed to load profile. Please try again.';
      _setState(UserState.error);
    }
  }

  /*// ── Fetch any user by ID ─────────────────────────────────────────────────────
  Future<UserModel?> fetchUserById(String id) async {
    try {
      return await _userServices.getUserById(id);
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return null;
    }
  }

  // ── Update profile ───────────────────────────────────────────────────────────
  Future<bool> updateProfile(Map<String, dynamic> fields) async {
    _setState(UserState.loading);

    try {
      _user = await _userServices.updateProfile(fields);
      _setState(UserState.success);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setState(UserState.error);
      return false;
    } catch (_) {
      _errorMessage = 'Update failed. Please try again.';
      _setState(UserState.error);
      return false;
    }
  }*/

  // ── Clear on logout ──────────────────────────────────────────────────────────
  void clear() {
    _user         = null;
    _state        = UserState.idle;
    _errorMessage = null;
    notifyListeners();
  }

  void _setState(UserState state) {
    _state = state;
    if (state != UserState.error) _errorMessage = null;
    notifyListeners();
  }
}
