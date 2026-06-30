import 'dart:convert';
import 'dart:io';

import 'package:bmc_app/core/network/models/user_model.dart';
import 'package:bmc_app/core/network/provider/widget.dart';
import 'package:bmc_app/features/common/show_message.dart';
import 'package:bmc_app/features/common/user_avatar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';

// ── Country / State service (no API key, no extra package needed) ────────────

class _GeoService {
  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  /// Returns list of country names sorted A-Z.
  /// Uses countriesnow.space — returns { data: [{ country, iso2, states:[{name}] }] }
  static Future<List<_Country>> fetchCountries() async {
    final response = await _dio.get(
      'https://countriesnow.space/api/v0.1/countries/states',
    );
    final list = (response.data['data'] as List<dynamic>);
    return list
        .map((c) => _Country.fromJson(c as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }
}

class _Country {
  final String       name;
  final String       iso2;
  final List<String> states;

  const _Country({required this.name, required this.iso2, required this.states});

  factory _Country.fromJson(Map<String, dynamic> json) {
    final rawStates = (json['states'] as List<dynamic>? ?? []);
    return _Country(
      name:   json['name']  as String? ?? '',
      iso2:   json['iso2']  as String? ?? '',
      states: rawStates
          .map((s) => (s as Map<String, dynamic>)['name'] as String? ?? '')
          .where((s) => s.isNotEmpty)
          .toList()
        ..sort(),
    );
  }
}

// ── Profile screen ────────────────────────────────────────────────────────────

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  // ── Image ─────────────────────────────────────────────────────────────────
  File?             _imageFile;
  String?           _base64Avatar;
  final ImagePicker _imagePicker = ImagePicker();

  // ── Controllers ───────────────────────────────────────────────────────────
  final _phoneCtrl   = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl    = TextEditingController();   // text field for city
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();

  // ── Country / State (dynamic) ─────────────────────────────────────────────
  List<_Country> _countries      = [];
  List<String>   _states         = [];
  _Country?      _selectedCountry;
  String?        _selectedState;
  bool           _loadingGeo     = false;
  String?        _geoError;

  // ── Dirty tracking ────────────────────────────────────────────────────────
  bool _hasChanges  = false;
  bool _initialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialised) {
      _initialised = true;
      _populateFromProvider();
      _loadGeo();
    }
  }

  void _populateFromProvider() {
    final u = context.read<UserProvider>().user;
    if (u == null) return;
    _phoneCtrl.text   = u.telno   ?? '';
    _addressCtrl.text = u.address ?? '';
    _cityCtrl.text    = u.city    ?? '';

    _phoneCtrl.addListener(_markDirty);
    _addressCtrl.addListener(_markDirty);
    _cityCtrl.addListener(_markDirty);
    _passCtrl.addListener(_markDirty);
    _confirmCtrl.addListener(_markDirty);
  }

  Future<void> _loadGeo() async {
    setState(() { _loadingGeo = true; _geoError = null; });
    try {
      final all = await _GeoService.fetchCountries();
      final u   = context.read<UserProvider>().user;

      _Country? match;
      if (u?.country?.isNotEmpty == true) {
        try {
          match = all.firstWhere(
                (c) => c.name.toLowerCase() == u!.country!.toLowerCase() ||
                c.iso2.toLowerCase() == u!.country!.toLowerCase(),
          );
        } catch (_) {
          // no match found — that's fine
        }
      }

      setState(() {
        _countries       = all;
        _selectedCountry = match;
        _states          = match?.states ?? [];
        _loadingGeo      = false;

        // pre-select saved state if the country matched
        if (match != null && u?.state?.isNotEmpty == true) {
          final savedState = u!.state!;
          _selectedState = _states.any(
                  (s) => s.toLowerCase() == savedState.toLowerCase())
              ? _states.firstWhere(
                  (s) => s.toLowerCase() == savedState.toLowerCase())
              : null;
        }
      });
    } catch (e) {
      setState(() {
        _loadingGeo = false;
        _geoError   = 'Could not load countries. Check your connection.';
      });
    }
  }

  void _onCountryChanged(_Country? c) {
    setState(() {
      _selectedCountry = c;
      _states          = c?.states ?? [];
      _selectedState   = null;
      _hasChanges      = true;
    });
  }

  void _markDirty() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ── Image picking ─────────────────────────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 512,
    );
    if (picked == null) return;
    final file   = File(picked.path);
    final bytes  = await file.readAsBytes();
    final ext    = picked.path.split('.').last.toLowerCase();
    final mime   = ext == 'png' ? 'image/png' : 'image/jpeg';

    setState(() {
      _imageFile    = file;
      _base64Avatar = 'data:$mime;base64,${base64Encode(bytes)}';
      _hasChanges   = true;
    });
  }

  void _removeAvatar() {
    setState(() {
      _imageFile    = null;
      _base64Avatar = null;
      _hasChanges   = true;
    });
  }

  // ── Save ──────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    final userProvider = context.read<UserProvider>();
    final userId = userProvider.user?.id ?? '';

    // ── Guard: id must be present ─────────────────────────────────────────
    debugPrint('💾 Saving profile. userId = "$userId"');
    if (userId.isEmpty) {
      showMessage(
        'Unable to identify your account. Please log out and log in again.',
        context,
        status: MessageStatus.error,
        title: 'Error',
      );
      return;
    }

    // ── Password validation ───────────────────────────────────────────────
    if (_passCtrl.text.isNotEmpty) {
      if (_passCtrl.text != _confirmCtrl.text) {
        showMessage('Passwords do not match', context,
            status: MessageStatus.error, title: 'Validation');
        return;
      }
      if (_passCtrl.text.length < 6) {
        showMessage('Password must be at least 6 characters', context,
            status: MessageStatus.error, title: 'Validation');
        return;
      }
    }

    final data = UserProfileUpdateData(
      id:       userId,
      avatar:   _base64Avatar,
      address:  _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      city:     _cityCtrl.text.trim().isEmpty    ? null : _cityCtrl.text.trim(),
      telno:    _phoneCtrl.text.trim().isEmpty   ? null : _phoneCtrl.text.trim(),
      state:    _selectedState?.isEmpty != false  ? null : _selectedState,
      country:  _selectedCountry?.name.isEmpty != false ? null : _selectedCountry?.name,
      password: _passCtrl.text.trim().isEmpty    ? null : _passCtrl.text.trim(),
    );

    debugPrint('💾 Sending update body: ${data.toJson()}');

    final success = await userProvider.updateProfile(data);

    if (!mounted) return;

    if (success) {
      setState(() {
        _hasChanges = false;
        _imageFile  = null;
        _passCtrl.clear();
        _confirmCtrl.clear();
      });
      showMessage('Profile updated successfully!', context,
          status: MessageStatus.success, title: 'Saved');
    } else {
      final err = userProvider.errorMessage ?? 'Update failed.';
      showMessage(err, context, status: MessageStatus.error, title: 'Error');
    }
  }

  void _cancel() {
    _populateFromProvider();

    // Re-match country/state from provider
    final u = context.read<UserProvider>().user;
    _Country? match;
    if (u?.country?.isNotEmpty == true && _countries.isNotEmpty) {
      try {
        match = _countries.firstWhere(
              (c) => c.name.toLowerCase() == u!.country!.toLowerCase(),
        );
      } catch (_) {}
    }
    String? savedState;
    if (match != null && u?.state?.isNotEmpty == true) {
      final s = u!.state!;
      savedState = (match.states.any((st) => st.toLowerCase() == s.toLowerCase()))
          ? match.states.firstWhere((st) => st.toLowerCase() == s.toLowerCase())
          : null;
    }

    setState(() {
      _hasChanges      = false;
      _imageFile       = null;
      _base64Avatar    = null;
      _selectedCountry = match;
      _states          = match?.states ?? [];
      _selectedState   = savedState;
    });
    _passCtrl.clear();
    _confirmCtrl.clear();
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final user     = userProvider.user;
        final updating = userProvider.isUpdating;

        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, size: 18),
            ),
            title: const Text(
              'Update Profile',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Lexend'),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Avatar ─────────────────────────────────────────────────
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 120, height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Theme.of(context).primaryColor, width: 2),
                          ),
                          child: ClipOval(
                            child: _imageFile != null
                                ? Image.file(_imageFile!, fit: BoxFit.cover)
                                : UserAvatar(
                              image:    userProvider.avatar,
                              initials: userProvider.initials,
                              radius:   60,
                            ),
                          ),
                        ),
                        if (_imageFile != null || userProvider.hasAvatar)
                          Positioned(
                            right: 0, top: 6,
                            child: GestureDetector(
                              onTap: _removeAvatar,
                              child: Container(
                                width: 24, height: 24,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(
                                      color: Colors.black12, blurRadius: 4)],
                                ),
                                child: const Icon(Iconsax.trash,
                                    size: 14, color: Colors.red),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _imageButton(
                        icon: Icons.camera_outlined,
                        text: 'Snap',
                        onTap: () => _pickImage(ImageSource.camera),
                      ),
                      const SizedBox(width: 12),
                      _imageButton(
                        icon: Icons.cloud_upload_outlined,
                        text: 'Upload',
                        onTap: () => _pickImage(ImageSource.gallery),
                      ),
                    ],
                  ),

                  const SizedBox(height: 26),

                  // ── Read-only fields ───────────────────────────────────────
                  if (user != null) ...[
                    _fieldLabel('Full Name'),
                    const SizedBox(height: 8),
                    _readonlyField(
                        user.fullname?.isNotEmpty == true
                            ? user.fullname!
                            : user.name),
                    const SizedBox(height: 18),

                    _fieldLabel('Email'),
                    const SizedBox(height: 8),
                    _readonlyField(user.email),
                    const SizedBox(height: 18),

                    if (user.username.isNotEmpty) ...[
                      _fieldLabel('Username'),
                      const SizedBox(height: 8),
                      _readonlyField(user.username),
                      const SizedBox(height: 18),
                    ],

                    Row(
                      children: [
                        if (user.rank?.isNotEmpty == true)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('Rank'),
                                const SizedBox(height: 8),
                                _readonlyField(user.rank!),
                              ],
                            ),
                          ),
                        if (user.rank?.isNotEmpty == true &&
                            user.clinicalRoleLabel.isNotEmpty)
                          const SizedBox(width: 12),
                        if (user.clinicalRoleLabel.isNotEmpty)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('Profession'),
                                const SizedBox(height: 8),
                                _readonlyField(user.clinicalRoleLabel),
                              ],
                            ),
                          ),
                      ],
                    ),
                    if (user.rank?.isNotEmpty == true ||
                        user.clinicalRoleLabel.isNotEmpty)
                      const SizedBox(height: 18),

                    if (user.deptName?.isNotEmpty == true) ...[
                      _fieldLabel('Department'),
                      const SizedBox(height: 8),
                      _readonlyField(user.deptName!),
                      const SizedBox(height: 18),
                    ],

                    if (user.gender?.isNotEmpty == true) ...[
                      _fieldLabel('Gender'),
                      const SizedBox(height: 8),
                      _readonlyField(user.gender!),
                      const SizedBox(height: 18),
                    ],
                  ],

                  // ── Editable fields ────────────────────────────────────────
                  _fieldLabel('Phone Number'),
                  const SizedBox(height: 8),
                  _customField(
                    controller: _phoneCtrl,
                    hint: 'e.g. +234 800 000 0000',
                    keyboardType: TextInputType.phone,
                  ),

                  const SizedBox(height: 18),

                  _fieldLabel('Address'),
                  const SizedBox(height: 8),
                  _customField(
                    controller: _addressCtrl,
                    hint: 'Street address',
                  ),

                  const SizedBox(height: 18),

                  // ── Country (dynamic) ──────────────────────────────────────
                  _fieldLabel('Country'),
                  const SizedBox(height: 8),

                  if (_loadingGeo)
                    _geoLoadingTile('Loading countries...')
                  else if (_geoError != null)
                    _geoErrorTile(_geoError!, _loadGeo)
                  else
                    _searchableCountryPicker(),

                  const SizedBox(height: 18),

                  // ── State (dynamic, depends on country) ────────────────────
                  _fieldLabel('State / Province'),
                  const SizedBox(height: 8),

                  if (_loadingGeo)
                    _geoLoadingTile('Loading states...')
                  else if (_selectedCountry == null)
                    _inactiveTile('Select a country first')
                  else if (_states.isEmpty)
                      _inactiveTile('No states available for this country')
                    else
                      _statePicker(),

                  const SizedBox(height: 18),

                  // ── City (free text) ───────────────────────────────────────
                  _fieldLabel('City'),
                  const SizedBox(height: 8),
                  _customField(
                    controller: _cityCtrl,
                    hint: 'City / Town',
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // ── Change password ────────────────────────────────────────
                  _fieldLabel('New Password'),
                  const SizedBox(height: 4),
                  Text(
                    'Leave blank to keep your current password',
                    style: TextStyle(
                        fontSize: 11, color: Theme.of(context).hintColor),
                  ),
                  const SizedBox(height: 8),
                  _customField(
                    controller: _passCtrl,
                    hint: '••••••••',
                    obscure: true,
                  ),

                  const SizedBox(height: 18),

                  _fieldLabel('Confirm New Password'),
                  const SizedBox(height: 8),
                  _customField(
                    controller: _confirmCtrl,
                    hint: '••••••••',
                    obscure: true,
                  ),

                  const SizedBox(height: 32),

                  // ── Action buttons ─────────────────────────────────────────
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _hasChanges
                        ? Column(
                      key: const ValueKey('buttons'),
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: updating ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                              Theme.of(context).primaryColor,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(30)),
                            ),
                            child: updating
                                ? SizedBox(
                              width: 22, height: 22,
                              child: LoadingAnimationWidget.staggeredDotsWave(
                                color: Colors.white,
                                size: 20,
                              ))
                                : const Text(
                              'Save Changes',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  fontFamily: 'Lexend'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: updating ? null : _cancel,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFBE3E3),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(30)),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  fontFamily: 'Lexend'),
                            ),
                          ),
                        ),
                      ],
                    )
                        : const SizedBox.shrink(key: ValueKey('empty')),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Country searchable picker ─────────────────────────────────────────────

  Widget _searchableCountryPicker() {
    return GestureDetector(
      onTap: () async {
        final result = await showModalBottomSheet<_Country>(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (_) => _CountryPickerSheet(
            countries: _countries,
            selected: _selectedCountry,
          ),
        );
        if (result != null) {
          _onCountryChanged(result);
        }
      },
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white10
              : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.public_outlined,
                size: 18, color: Colors.grey),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _selectedCountry?.name ?? 'Select country',
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'Lexend',
                  color: _selectedCountry == null
                      ? Colors.grey.shade400
                      : Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  // ── State searchable picker ───────────────────────────────────────────────

  Widget _statePicker() {
    return GestureDetector(
      onTap: () async {
        final result = await showModalBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (_) => _StatePickerSheet(
            states:    _states,
            selected:  _selectedState,
            countryName: _selectedCountry?.name ?? '',
          ),
        );
        if (result != null) {
          setState(() {
            _selectedState = result;
            _hasChanges    = true;
          });
        }
      },
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white10
              : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on_outlined,
                size: 18, color: Colors.grey),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _selectedState ?? 'Select state / province',
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'Lexend',
                  color: _selectedState == null
                      ? Colors.grey.shade400
                      : Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  // ── Geo helper tiles ──────────────────────────────────────────────────────

  Widget _geoLoadingTile(String label) => Container(
    height: 52,
    alignment: Alignment.centerLeft,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: Row(
      children: [
        const SizedBox(
            width: 16, height: 16,
            child: CircularProgressIndicator(strokeWidth: 2)),
        const SizedBox(width: 12),
        Text(label,
            style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                fontFamily: 'Lexend')),
      ],
    ),
  );

  Widget _geoErrorTile(String msg, VoidCallback onRetry) => Container(
    height: 52,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: Colors.red.shade200),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, size: 18, color: Colors.red),
        const SizedBox(width: 8),
        Expanded(
          child: Text(msg,
              style: const TextStyle(
                  fontSize: 12, color: Colors.red, fontFamily: 'Lexend')),
        ),
        TextButton(
          onPressed: onRetry,
          child: const Text('Retry',
              style: TextStyle(fontSize: 12, fontFamily: 'Lexend')),
        ),
      ],
    ),
  );

  Widget _inactiveTile(String label) => Container(
    height: 52,
    alignment: Alignment.centerLeft,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Text(label,
        style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade400,
            fontFamily: 'Lexend')),
  );

  // ── Shared widget helpers ─────────────────────────────────────────────────

  Widget _fieldLabel(String text) => Text(
    text,
    style: const TextStyle(
        fontSize: 12, fontWeight: FontWeight.w500, fontFamily: 'Lexend'),
  );

  Widget _readonlyField(String value) => Container(
    height: 52,
    alignment: Alignment.centerLeft,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.white10
          : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: Text(value,
        style: TextStyle(
            fontSize: 13,
            fontFamily: 'Lexend',
            color: Theme.of(context).hintColor)),
  );

  Widget _customField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    void Function(String)? onChanged,
  }) =>
      Container(
        height: 52,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white10
              : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 13,
                fontFamily: 'Lexend'),
            suffixIcon: const Icon(Icons.edit_outlined, size: 18),
            border: InputBorder.none,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          ),
        ),
      );

  Widget _imageButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white10
                : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(text,
                  style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'Lexend',
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );
}

// ─── Country Picker Sheet ─────────────────────────────────────────────────────

class _CountryPickerSheet extends StatefulWidget {
  final List<_Country> countries;
  final _Country?      selected;
  const _CountryPickerSheet({required this.countries, this.selected});

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final _search = TextEditingController();
  List<_Country> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.countries;
    _search.addListener(() {
      final q = _search.text.toLowerCase();
      setState(() {
        _filtered = q.isEmpty
            ? widget.countries
            : widget.countries
            .where((c) => c.name.toLowerCase().contains(q))
            .toList();
      });
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, scroll) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _search,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search country...',
                    hintStyle: const TextStyle(
                        fontFamily: 'Lexend', fontSize: 13),
                    prefixIcon: const Icon(Icons.search, size: 18),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    contentPadding:
                    const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: scroll,
                  itemCount: _filtered.length,
                  itemBuilder: (context, i) {
                    final c = _filtered[i];
                    final isSelected =
                        widget.selected?.iso2 == c.iso2;
                    return ListTile(
                      title: Text(c.name,
                          style: const TextStyle(
                              fontSize: 14, fontFamily: 'Lexend')),
                      trailing: isSelected
                          ? Icon(Icons.check,
                          color: Theme.of(context).primaryColor)
                          : null,
                      selected: isSelected,
                      selectedTileColor:
                      Theme.of(context).primaryColor.withOpacity(0.06),
                      onTap: () => Navigator.pop(context, c),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── State Picker Sheet ───────────────────────────────────────────────────────

class _StatePickerSheet extends StatefulWidget {
  final List<String> states;
  final String?      selected;
  final String       countryName;
  const _StatePickerSheet(
      {required this.states, this.selected, required this.countryName});

  @override
  State<_StatePickerSheet> createState() => _StatePickerSheetState();
}

class _StatePickerSheetState extends State<_StatePickerSheet> {
  final _search = TextEditingController();
  List<String> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.states;
    _search.addListener(() {
      final q = _search.text.toLowerCase();
      setState(() {
        _filtered = q.isEmpty
            ? widget.states
            : widget.states
            .where((s) => s.toLowerCase().contains(q))
            .toList();
      });
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, scroll) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _search,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search ${widget.countryName} state...',
                    hintStyle: const TextStyle(
                        fontFamily: 'Lexend', fontSize: 13),
                    prefixIcon: const Icon(Icons.search, size: 18),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    contentPadding:
                    const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: scroll,
                  itemCount: _filtered.length,
                  itemBuilder: (context, i) {
                    final s = _filtered[i];
                    final isSelected = widget.selected == s;
                    return ListTile(
                      title: Text(s,
                          style: const TextStyle(
                              fontSize: 14, fontFamily: 'Lexend')),
                      trailing: isSelected
                          ? Icon(Icons.check,
                          color: Theme.of(context).primaryColor)
                          : null,
                      selected: isSelected,
                      selectedTileColor:
                      Theme.of(context).primaryColor.withOpacity(0.06),
                      onTap: () => Navigator.pop(context, s),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
