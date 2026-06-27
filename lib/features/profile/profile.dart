// profile.dart
import 'dart:convert';
import 'dart:io';

import 'package:bmc_app/core/network/models/user_model.dart';
import 'package:bmc_app/core/network/provider/widget.dart';
import 'package:bmc_app/features/common/show_message.dart';
import 'package:bmc_app/features/common/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  // ── Image ─────────────────────────────────────────────────────────────────
  File?             _imageFile;
  String?           _base64Avatar; // encoded for upload
  final ImagePicker _imagePicker = ImagePicker();

  // ── Controllers ───────────────────────────────────────────────────────────
  final _phoneCtrl   = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();

  // ── Dropdowns ─────────────────────────────────────────────────────────────
  String _country = '';
  String _state   = '';
  String _city    = '';

  // ── Dirty tracking ────────────────────────────────────────────────────────
  bool _hasChanges = false;

  // Pre-populate from provider on first load
  bool _initialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialised) {
      _initialised = true;
      _populateFromProvider();
    }
  }

  void _populateFromProvider() {
    final u = context.read<UserProvider>().user;
    if (u == null) return;
    _phoneCtrl.text   = u.telno    ?? '';
    _addressCtrl.text = u.address  ?? '';
    _country          = u.country  ?? '';
    _state            = u.state    ?? '';
    _city             = u.city     ?? '';

    _phoneCtrl.addListener(_markDirty);
    _addressCtrl.addListener(_markDirty);
    _passCtrl.addListener(_markDirty);
    _confirmCtrl.addListener(_markDirty);
  }

  void _markDirty() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
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
    final base64 = base64Encode(bytes);
    final ext    = picked.path.split('.').last.toLowerCase();
    final mime   = ext == 'png' ? 'image/png' : 'image/jpeg';

    setState(() {
      _imageFile    = file;
      _base64Avatar = 'data:$mime;base64,$base64';
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
    // Password validation
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
      id:         context.read<UserProvider>().user?.id,
      avatar:   _base64Avatar,
      address:  _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      city:     _city.isEmpty    ? null : _city,
      telno:    _phoneCtrl.text.trim().isEmpty   ? null : _phoneCtrl.text.trim(),
      state:    _state.isEmpty   ? null : _state,
      country:  _country.isEmpty ? null : _country,
      password: _passCtrl.text.trim().isEmpty    ? null : _passCtrl.text.trim(),
    );

    final success = await context.read<UserProvider>().updateProfile(data);

    if (!mounted) return;

    if (success) {
      setState(() {
        _hasChanges = false;
        _imageFile  = null;   // now using the updated avatar from provider
        _passCtrl.clear();
        _confirmCtrl.clear();
      });
      showMessage('Profile updated successfully!', context,
          status: MessageStatus.success, title: 'Saved');
    } else {
      final err = context.read<UserProvider>().errorMessage ?? 'Update failed.';
      showMessage(err, context,
          status: MessageStatus.error, title: 'Error');
    }
  }

  void _cancel() {
    _populateFromProvider();
    setState(() {
      _hasChanges   = false;
      _imageFile    = null;
      _base64Avatar = null;
    });
    _passCtrl.clear();
    _confirmCtrl.clear();
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final user      = userProvider.user;
        final updating  = userProvider.isUpdating;

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
              padding: const EdgeInsets.symmetric(
                  horizontal: 30, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Avatar ──────────────────────────────────────────────
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).primaryColor,
                              width: 2,
                            ),
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

                        // Remove button
                        if (_imageFile != null || userProvider.hasAvatar)
                          Positioned(
                            right: 0,
                            top: 6,
                            child: GestureDetector(
                              onTap: _removeAvatar,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                  )],
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

                  // ── Image action buttons ─────────────────────────────────
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

                  // ── Read-only info ────────────────────────────────────────
                  if (user != null) ...[
                    _fieldLabel('Full Name'),
                    const SizedBox(height: 8),
                    _readonlyField(user.name),
                    const SizedBox(height: 18),

                    _fieldLabel('Email'),
                    const SizedBox(height: 8),
                    _readonlyField(user.email),
                    const SizedBox(height: 18),

                    if (user.rank?.isNotEmpty == true) ...[
                      _fieldLabel('Rank / Role'),
                      const SizedBox(height: 8),
                      _readonlyField(user.rank!),
                      const SizedBox(height: 18),
                    ],
                  ],

                  // ── Editable fields ───────────────────────────────────────
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

                  // Country
                  _fieldLabel('Country'),
                  const SizedBox(height: 8),
                  _dropdownField(
                    value: _country.isEmpty ? null : _country,
                    hint: 'Select country',
                    items: const [
                      'Nigeria', 'Ghana', 'Kenya', 'South Africa',
                      'Ethiopia', 'Tanzania', 'Uganda', 'Rwanda',
                    ],
                    onChanged: (v) {
                      setState(() { _country = v ?? ''; _hasChanges = true; });
                    },
                  ),

                  const SizedBox(height: 18),

                  // State + City side by side
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _fieldLabel('State'),
                            const SizedBox(height: 8),
                            _dropdownField(
                              value: _state.isEmpty ? null : _state,
                              hint: 'State',
                              items: const [
                                'Abia', 'Adamawa', 'Akwa Ibom', 'Anambra',
                                'Bauchi', 'Bayelsa', 'Benue', 'Borno',
                                'Cross River', 'Delta', 'Ebonyi', 'Edo',
                                'Ekiti', 'Enugu', 'FCT', 'Gombe', 'Imo',
                                'Jigawa', 'Kaduna', 'Kano', 'Katsina',
                                'Kebbi', 'Kogi', 'Kwara', 'Lagos', 'Nasarawa',
                                'Niger', 'Ogun', 'Ondo', 'Osun', 'Oyo',
                                'Plateau', 'Rivers', 'Sokoto', 'Taraba',
                                'Yobe', 'Zamfara',
                              ],
                              onChanged: (v) {
                                setState(() { _state = v ?? ''; _hasChanges = true; });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _fieldLabel('City'),
                            const SizedBox(height: 8),
                            _customField(
                              controller: TextEditingController(text: _city),
                              hint: 'City',
                              onChanged: (v) {
                                _city = v;
                                _markDirty();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
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
                        fontSize: 11,
                        color: Theme.of(context).hintColor),
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

                  // ── Action buttons — only shown when dirty ─────────────────
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _hasChanges
                        ? Column(
                      key: const ValueKey('buttons'),
                      children: [
                        // Save
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
                                ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                                : const Text(
                              'Save Changes',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                fontFamily: 'Lexend',
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Cancel
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: updating ? null : _cancel,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                              const Color(0xFFFBE3E3),
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
                                fontFamily: 'Lexend',
                              ),
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

  // ── Widget helpers ─────────────────────────────────────────────────────────

  Widget _fieldLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      fontFamily: 'Lexend',
    ),
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
    child: Text(
      value,
      style: TextStyle(
        fontSize: 13,
        fontFamily: 'Lexend',
        color: Theme.of(context).hintColor,
      ),
    ),
  );

  Widget _customField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    Widget? prefix,
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
            prefixIcon: prefix,
            suffixIcon: const Icon(Icons.edit_outlined,
                size: 18),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 15),
          ),
        ),
      );

  Widget _dropdownField({
    required String? value,
    required String hint,
    required List<String> items,
    required void Function(String?) onChanged,
  }) =>
      Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white10
              : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            hint: Text(hint,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                    fontSize: 13,
                    fontFamily: 'Lexend')),
            style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                fontSize: 13,
                fontFamily: 'Lexend'),
            items: items
                .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                .toList(),
            onChanged: onChanged,
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
