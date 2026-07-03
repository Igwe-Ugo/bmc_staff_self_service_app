// ─── profile_provider.dart ───────────────────────────────────────────────────

import 'dart:convert';
import 'dart:io';

import 'package:bmc_app/core/network/models/user_model.dart';
import 'package:bmc_app/core/network/provider/widget.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/widget.dart';
import '../services/widget.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileService _service = ProfileService();
  final UserProvider   userProvider;

  ProfileProvider(this.userProvider);

  // ── Controllers ───────────────────────────────────────────────────────────
  final phoneCtrl   = TextEditingController();
  final addressCtrl = TextEditingController();
  final cityCtrl    = TextEditingController();
  final passCtrl    = TextEditingController();
  final confirmCtrl = TextEditingController();

  // ── Image ─────────────────────────────────────────────────────────────────
  File?   imageFile;
  String? _base64Avatar;
  final ImagePicker _imagePicker = ImagePicker();

  // ── Dropdown state ───────────────────────────────────────────────────────
  String country = '';
  String state   = '';

  // Fetched once, cached — countryName -> list of state names
  List<Country>   _allCountries = [];
  List<String>    countries = [];
  List<String>    states    = [];
  bool            isLoadingCountries = false;

  // ── Dirty tracking ───────────────────────────────────────────────────────
  bool hasChanges  = false;
  bool _initialised = false;

  bool    get isUpdating   => userProvider.isUpdating;
  String? get errorMessage => userProvider.errorMessage;

  // ── Init ──────────────────────────────────────────────────────────────────
  Future<void> init() async {
    if (_initialised) return;
    _initialised = true;

    _populateFromUser();
    phoneCtrl.addListener(markDirty);
    addressCtrl.addListener(markDirty);
    cityCtrl.addListener(markDirty);
    passCtrl.addListener(markDirty);
    confirmCtrl.addListener(markDirty);

    await loadCountries();
    if (country.isNotEmpty) _applyStatesForCountry(country);
    notifyListeners();
  }

  void _populateFromUser() {
    final u = userProvider.user;
    if (u == null) return;
    phoneCtrl.text   = u.telno   ?? '';
    addressCtrl.text = u.address ?? '';
    cityCtrl.text    = u.city    ?? '';
    country = u.country ?? '';
    state   = u.state   ?? '';
  }

  void markDirty() {
    if (!hasChanges) {
      hasChanges = true;
      notifyListeners();
    }
  }

// ── Fetch once — countries + all their states come back together ────────
  Future<void> loadCountries({bool forceRefresh = false}) async {
    isLoadingCountries = true;
    notifyListeners();
    try {
      _allCountries = await _service.fetchCountriesWithStates(forceRefresh: forceRefresh);
      countries = _allCountries.map((c) => c.name).toList();
    } catch (e) {
      debugPrint('Failed to load countries: $e');
      _allCountries = [];
      countries = [];
    }
    isLoadingCountries = false;
    notifyListeners();
  }

// Local lookup — no network call, instant
  void _applyStatesForCountry(String countryName) {
    final match = _allCountries.firstWhere(
          (c) => c.name.toLowerCase() == countryName.toLowerCase(),
      orElse: () => const Country(name: '', iso2: '', states: []),
    );
    states = match.states;
  }

  void updateCountry(String? v) {
    country = v ?? '';
    state   = '';
    hasChanges = true;
    _applyStatesForCountry(country);
    notifyListeners();
  }

  void updateState(String? v) {
    state = v ?? '';
    markDirty();
  }

  // ── Image picking ─────────────────────────────────────────────────────────
  Future<void> pickImage(ImageSource source) async {
    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 512,
    );
    if (picked == null) return;

    final file   = File(picked.path);
    final bytes  = await file.readAsBytes();
    final base64 = base64Encode(bytes);
    final ext    = picked.path.split('.').last.toLowerCase();
    final mime   = ext == 'png' ? 'image/png' : 'image/jpeg';

    imageFile     = file;
    _base64Avatar = 'data:$mime;base64,$base64';
    hasChanges    = true;
    notifyListeners();
  }

  void removeAvatar() {
    imageFile     = null;
    _base64Avatar = null;
    hasChanges    = true;
    notifyListeners();
  }

  // ── Validation ────────────────────────────────────────────────────────────
  String? get passwordError {
    if (passCtrl.text.isEmpty) return null;
    if (passCtrl.text != confirmCtrl.text) return 'Passwords do not match';
    if (passCtrl.text.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  // ── Save ──────────────────────────────────────────────────────────────────
  Future<bool> save() async {
    final userId = userProvider.user?.id;
    if (userId == null || userId.isEmpty) return false;
    if (passwordError != null) return false;

    final data = UserProfileUpdateData(
      id:       userId,
      avatar:   _base64Avatar,
      address:  addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
      city:     cityCtrl.text.trim().isEmpty    ? null : cityCtrl.text.trim(),
      telno:    phoneCtrl.text.trim().isEmpty   ? null : phoneCtrl.text.trim(),
      state:    state.isEmpty   ? null : state,
      country:  country.isEmpty ? null : country,
      password: passCtrl.text.trim().isEmpty ? null : passCtrl.text.trim(),
    );

    final success = await userProvider.updateProfile(data);
    if (success) {
      hasChanges = false;
      imageFile  = null;
      passCtrl.clear();
      confirmCtrl.clear();
      notifyListeners();
    }
    return success;
  }

  void cancel() {
    _populateFromUser();
    hasChanges    = false;
    imageFile     = null;
    _base64Avatar = null;
    passCtrl.clear();
    confirmCtrl.clear();
    if (country.isNotEmpty) _applyStatesForCountry(country);
    notifyListeners();
  }

  @override
  void dispose() {
    phoneCtrl.dispose();
    addressCtrl.dispose();
    cityCtrl.dispose();
    passCtrl.dispose();
    confirmCtrl.dispose();
    super.dispose();
  }
}
