// ─── profile_provider.dart ───────────────────────────────────────────────────

import 'dart:convert';
import 'dart:io';
import 'package:bmc_app/core/network/provider/widget.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/widget.dart';
import '../services/widget.dart';
import '../../../features/profile/widget.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileService _service = ProfileService();
  final UserProvider userProvider;

  ProfileProvider(this.userProvider);

  // ── Controllers ───────────────────────────────────────────────────────────
  final phoneCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();

  // ── Image ─────────────────────────────────────────────────────────────────
  File? imageFile;
  String? _base64Avatar;
  bool _avatarRemoved = false;
  final ImagePicker _imagePicker = ImagePicker();

  // ── Dropdown state ───────────────────────────────────────────────────────
  String country = '';
  String state = '';

  /// Default when a user has no saved country yet — see _populateFromUser.
  static const _defaultCountryName = 'Nigeria';

  /// Last-resort fallback if "Nigeria" itself can't be found in the fetched
  /// list (e.g. the countries fetch failed outright) — matches
  /// _defaultCountryName's intent so selectedCountryIso2/DialCode never go
  /// blank, they just fall back to Nigeria's known values.
  static const _fallbackCountry = Country(
    name: '',
    iso2: 'NG',
    dialCode: '+234',
    states: [],
  );

  // Fetched once, cached — countryName -> list of state names
  List<Country> _allCountries = [];
  List<String> countries = [];
  List<String> states = [];
  bool isLoadingCountries = false;

  // ── Dirty tracking ───────────────────────────────────────────────────────
  bool hasChanges = false;
  bool _initialised = false;

  bool get isUpdating => userProvider.isUpdating;
  String? get errorMessage => userProvider.errorMessage;

  // ── Init ──────────────────────────────────────────────────────────────────
  Future<void> init() async {
    // Refetch the full profile every time this screen opens, rather than
    // trusting whatever UserProvider already has. A fresh login only seeds
    // a SUBSET of fields (id/username/name/email/privileges) — the rest
    // (rank/profession/gender/department/phone/address/country) needs a
    // real GET /users/regular. This is defensive: AuthProvider.login() now
    // does that fetch too, but this screen shouldn't silently depend on
    // every caller getting that right — and it also picks up anything
    // changed server-side since login (e.g. a department reassignment).
    await userProvider.fetchMe();

    // loadCountries() must finish BEFORE _populateFromUser() runs: the
    // latter resolves the phone field's dial code (via
    // selectedCountryDialCode) and, for a user with no saved country,
    // needs to match "Nigeria" against the fetched list to fill in NG's
    // real dial code — neither works if _allCountries is still empty.
    if (!_initialised) {
      _initialised = true;
      _attachListeners();
      await loadCountries();
    }

    _populateFromUser();

    if (country.isNotEmpty) _applyStatesForCountry(country);
    notifyListeners();
  }

  void _attachListeners() {
    phoneCtrl.addListener(markDirty);
    addressCtrl.addListener(markDirty);
    cityCtrl.addListener(markDirty);
    passCtrl.addListener(markDirty);
    confirmCtrl.addListener(markDirty);
  }

  void _removeListeners() {
    phoneCtrl.removeListener(markDirty);
    addressCtrl.removeListener(markDirty);
    cityCtrl.removeListener(markDirty);
    passCtrl.removeListener(markDirty);
    confirmCtrl.removeListener(markDirty);
  }

  void _populateFromUser() {
    // Detach listeners temporarily so programmatic updates don't flag hasChanges = true
    _removeListeners();

    final u = userProvider.user;
    if (u != null) {
      // u.country/u.state are the RAW tblUsers fields — per the model's own
      // comment, these may not be display names at all (could be a code or
      // internal id). u.countryName/u.stateName are the qryUsers joined
      // fields — the actual resolved human-readable names, which is the
      // only thing that can ever match a Country.name from the fetched
      // world-countries list. Reading u.country directly here was why the
      // dropdown never showed a selection and the dial code kept falling
      // through to the fallback. Falls back to the raw field only if the
      // joined name genuinely wasn't returned, then to Nigeria if neither
      // was.
      final resolvedCountry = (u.countryName?.trim().isNotEmpty ?? false)
          ? u.countryName!.trim()
          : (u.country?.trim() ?? '');
      country = resolvedCountry.isNotEmpty
          ? resolvedCountry
          : _defaultCountryName;

      state = (u.stateName?.trim().isNotEmpty ?? false)
          ? u.stateName!.trim()
          : (u.state?.trim() ?? '');

      // u.telno is stored as a full E.164 number (dial code + local number).
      // CustomPhoneInput shows the dial code as its own prefix chip, so the
      // controller must only ever hold the local part — otherwise the field
      // shows the dial code twice and trips the widget's own "don't include
      // the country code" warning. selectedCountryDialCode needs
      // _allCountries already loaded (see init()) to resolve correctly.
      phoneCtrl.text = stripDialCode(
        u.telno,
        dialCode: selectedCountryDialCode,
      );
      addressCtrl.text = u.address ?? '';
      cityCtrl.text = u.city ?? '';
    }

    _attachListeners();
  }

  void markDirty() {
    if (!hasChanges) {
      hasChanges = true;
      notifyListeners();
    }
  }

  // ── Add this to ProfileProvider ──────────────────────────────────────────────
  String get selectedCountryIso2 {
    final match = _allCountries.firstWhere(
      (c) => c.name.toLowerCase() == country.toLowerCase(),
      orElse: () => _fallbackCountry,
    );
    return match.iso2.isNotEmpty ? match.iso2 : _fallbackCountry.iso2;
  }

  String get selectedCountryDialCode {
    final match = _allCountries.firstWhere(
      (c) => c.name.toLowerCase() == country.toLowerCase(),
      orElse: () => _fallbackCountry,
    );
    return match.dialCode.isNotEmpty
        ? match.dialCode
        : _fallbackCountry.dialCode;
  }

  // ── Fetch once — countries + all their states come back together ────────
  Future<void> loadCountries({bool forceRefresh = false}) async {
    isLoadingCountries = true;
    notifyListeners();
    try {
      _allCountries = await _service.fetchCountriesWithStates(
        forceRefresh: forceRefresh,
      );
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
      orElse: () => const Country(name: '', iso2: '', dialCode: '', states: []),
    );
    states = match.states;
  }

  void updateCountry(String? v) {
    country = v ?? '';
    state = '';
    hasChanges = true;
    _applyStatesForCountry(country);
    notifyListeners();
  }

  void updateState(String? v) {
    state = v ?? '';
    hasChanges = true;
    notifyListeners();
  }

  // ── Image picking ─────────────────────────────────────────────────────────
  Future<void> pickImage(ImageSource source) async {
    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 512,
    );
    if (picked == null) return;

    final file = File(picked.path);
    final bytes = await file.readAsBytes();
    final base64 = base64Encode(bytes);
    final ext = picked.path.split('.').last.toLowerCase();
    final mime = ext == 'png' ? 'image/png' : 'image/jpeg';

    imageFile = file;
    _base64Avatar = 'data:$mime;base64,$base64';
    _avatarRemoved = false;
    hasChanges = true;
    notifyListeners();
  }

  void removeAvatar() {
    imageFile = null;
    _base64Avatar = null;
    _avatarRemoved = true;
    hasChanges = true;
    notifyListeners();
  }

  // ── Validation ────────────────────────────────────────────────────────────
  String? get passwordError {
    if (passCtrl.text.isEmpty) return null;
    if (passCtrl.text != confirmCtrl.text) return 'Passwords do not match';
    if (passCtrl.text.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  // ── Save ──────────────────────────────────────────────────────────────────
  Future<bool> save() async {
    final userId = userProvider.user?.id;
    if (userId == null || userId.isEmpty) return false;
    if (passwordError != null) return false;

    final formattedPhone = phoneCtrl.text.trim().isEmpty
        ? null
        : preparePhoneForBackend(
            rawInputNumber: phoneCtrl.text.trim(),
            dialCode: selectedCountryDialCode,
          );

    final data = UserProfileUpdateData(
      id: userId,
      avatar: _base64Avatar,
      removeAvatar: _avatarRemoved,
      address: addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
      city: cityCtrl.text.trim().isEmpty ? null : cityCtrl.text.trim(),
      telno: formattedPhone, // 👈 Send formatted E.164 number to backend
      state: state.isEmpty ? null : state,
      country: country.isEmpty ? null : country,
      password: passCtrl.text.trim().isEmpty ? null : passCtrl.text.trim(),
    );

    final success = await userProvider.updateProfile(data);
    if (success) {
      _populateFromUser();

      hasChanges = false;
      imageFile = null;
      _base64Avatar = null;
      _avatarRemoved = false;

      _removeListeners();
      passCtrl.clear();
      confirmCtrl.clear();
      _attachListeners();

      if (country.isNotEmpty) _applyStatesForCountry(country);

      notifyListeners();
    }
    return success;
  }

  void cancel() {
    _populateFromUser();
    hasChanges = false;
    imageFile = null;
    _base64Avatar = null;
    _avatarRemoved = false;

    _removeListeners();
    passCtrl.clear();
    confirmCtrl.clear();
    _attachListeners();

    if (country.isNotEmpty) _applyStatesForCountry(country);
    notifyListeners();
  }

  @override
  void dispose() {
    _removeListeners();
    phoneCtrl.dispose();
    addressCtrl.dispose();
    cityCtrl.dispose();
    passCtrl.dispose();
    confirmCtrl.dispose();
    super.dispose();
  }
}
