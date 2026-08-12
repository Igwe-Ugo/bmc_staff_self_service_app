// ─── profile.dart ─────────────────────────────────────────────────────────────
import 'package:bmc_app/core/network/provider/widget.dart';
import 'package:bmc_app/features/common/show_message.dart';
import 'package:bmc_app/features/common/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  late final ProfileProvider _provider;
  bool _changePasswordField = false;

  @override
  void initState() {
    super.initState();
    _provider = ProfileProvider(context.read<UserProvider>());
    WidgetsBinding.instance.addPostFrameCallback((_) => _provider.init());
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  Future<void> _save(ProfileProvider p) async {
    final pwError = p.passwordError;
    if (pwError != null) {
      showMessage(
        pwError,
        context,
        status: MessageStatus.error,
        title: 'Validation',
      );
      return;
    }

    final success = await p.save();
    if (!mounted) return;

    if (success) {
      showMessage(
        'Profile updated successfully!',
        context,
        status: MessageStatus.success,
        title: 'Saved',
      );
    } else {
      showMessage(
        p.errorMessage ?? 'Update failed.',
        context,
        status: MessageStatus.error,
        title: 'Error',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer2<ProfileProvider, UserProvider>(
        builder: (context, p, userProvider, _) {
          final user = userProvider.user;

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
                  fontFamily: 'Lexend',
                ),
              ),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _changePasswordField = !_changePasswordField;
                        });
                      },
                      child: Container(
                        alignment: Alignment.center,
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        child: Text(
                          _changePasswordField
                              ? 'Click here to change Profile'
                              : 'Click here to change Password',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    if (!_changePasswordField)
                      Column(
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
                                    child: p.imageFile != null
                                        ? Image.file(
                                            p.imageFile!,
                                            fit: BoxFit.cover,
                                          )
                                        : UserAvatar(
                                            image: userProvider.avatar,
                                            initials: userProvider.initials,
                                            radius: 60,
                                          ),
                                  ),
                                ),
                                if (p.imageFile != null ||
                                    userProvider.hasAvatar)
                                  Positioned(
                                    right: 0,
                                    top: 6,
                                    child: GestureDetector(
                                      onTap: p.removeAvatar,
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black12,
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Iconsax.trash,
                                          size: 14,
                                          color: Colors.red,
                                        ),
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
                                onTap: () => p.pickImage(ImageSource.camera),
                              ),
                              const SizedBox(width: 12),
                              _imageButton(
                                icon: Icons.cloud_upload_outlined,
                                text: 'Upload',
                                onTap: () => p.pickImage(ImageSource.gallery),
                              ),
                            ],
                          ),

                          const SizedBox(height: 26),

                          // ── Read-only info ────────────────────────────────────
                          if (user != null) ...[
                            _readOnlyInfo(
                              'Full Name',
                              user.fullname?.isNotEmpty == true
                                  ? user.fullname!
                                  : user.name,
                            ),
                            _readOnlyInfo('Email', user.email),
                            if (user.username.isNotEmpty) ...[
                              _readOnlyInfo('Username', user.username),
                            ],
                            if (user.rank?.isNotEmpty == true &&
                                user.clinicalRoleLabel.isNotEmpty) ...[
                              _readOnlyInfo('Rank', user.rank!),
                              _readOnlyInfo(
                                'Profession',
                                user.clinicalRoleLabel,
                              ),
                            ],

                            if (user.deptName?.isNotEmpty == true) ...[
                              _readOnlyInfo('Department', user.deptName!),
                            ],

                            if (user.gender?.isNotEmpty == true) ...[
                              _readOnlyInfo('Gender', user.gender!),
                            ],
                          ],
                          const SizedBox(height: 18),

                          // ── Editable fields ────────────────────────────────────
                          _fieldLabel('Address'),
                          const SizedBox(height: 8),
                          _customField(
                            controller: p.addressCtrl,
                            hint: 'Street address',
                          ),

                          const SizedBox(height: 18),

                          // Country (dynamic)
                          // Country
                          _fieldLabel('Country'),
                          const SizedBox(height: 8),
                          if (p.isLoadingCountries)
                            _dropdownLoading()
                          else if (p.countries.isEmpty)
                            GestureDetector(
                              onTap: () => p.loadCountries(forceRefresh: true),
                              child: Container(
                                height: 52,
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.red.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.refresh,
                                      size: 16,
                                      color: Colors.red.shade400,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Couldn't load countries — tap to retry",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.red.shade400,
                                        fontFamily: 'Lexend',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            _dropdownField(
                              value: p.country.isEmpty ? null : p.country,
                              hint: 'Select country',
                              items: p.countries,
                              onChanged: p.updateCountry,
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
                                      value: p.state.isEmpty ? null : p.state,
                                      hint: 'State',
                                      items: p.states,
                                      onChanged: p.updateState,
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
                                      controller: p.cityCtrl,
                                      hint: 'City',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          _fieldLabel('Phone Number'),
                          const SizedBox(height: 8),

                          IgnorePointer(
                            ignoring: true,
                            child: InternationalPhoneNumberInput(
                              key: ValueKey(
                                p.selectedCountryIso2,
                              ), // Forces rebuild when user selects a different country
                              onInputChanged: (PhoneNumber number) {
                                p.phoneCtrl.text = number.phoneNumber ?? '';
                              },
                              initialValue: PhoneNumber(
                                isoCode: p.selectedCountryIso2,
                                phoneNumber: p.phoneCtrl.text,
                              ),
                              selectorConfig: const SelectorConfig(
                                leadingPadding: 10,
                                selectorType:
                                    PhoneInputSelectorType.BOTTOM_SHEET,
                                // disabled: true, // Prevents user from opening/changing the country flag dropdown
                                setSelectorButtonAsPrefixIcon: true,
                              ),
                              ignoreBlank: false,
                              autoValidateMode: AutovalidateMode.disabled,
                              textFieldController: p.phoneCtrl,
                              formatInput: true,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    signed: true,
                                    decimal: true,
                                  ),
                              inputDecoration: InputDecoration(
                                hintText: '800 000 0000',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 13,
                                  fontFamily: 'Lexend',
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 15,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],
                      ),

                    if (_changePasswordField)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 16),

                          // ── Change password ────────────────────────────────────
                          _fieldLabel('New Password'),
                          const SizedBox(height: 4),
                          Text(
                            'Leave blank to keep your current password',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _customField(
                            controller: p.passCtrl,
                            hint: '••••••••',
                            obscure: true,
                          ),

                          const SizedBox(height: 18),

                          _fieldLabel('Confirm New Password'),
                          const SizedBox(height: 8),
                          _customField(
                            controller: p.confirmCtrl,
                            hint: '••••••••',
                            obscure: true,
                          ),

                          const SizedBox(height: 32),
                        ],
                      ),

                    // ── Action buttons — only shown when dirty ─────────────
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: p.hasChanges
                          ? Column(
                              key: const ValueKey('buttons'),
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: p.isUpdating
                                        ? null
                                        : () => _save(p),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(
                                        context,
                                      ).primaryColor,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    child: p.isUpdating
                                        ? SizedBox(
                                            width: 22,
                                            height: 22,
                                            child:
                                                LoadingAnimationWidget.staggeredDotsWave(
                                                  color: Colors.white,
                                                  size: 20,
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
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: p.isUpdating ? null : p.cancel,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFBE3E3),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
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
      ),
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

  Widget _readOnlyInfo(String label, String value) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        fontFamily: 'Lexend',
      ),
    ),
    subtitle: Text(
      value,
      style: const TextStyle(fontSize: 11, fontFamily: 'Lexend'),
    ),
  );

  Widget _customField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    Widget? prefix,
    TextInputType keyboardType = TextInputType.text,
  }) => Container(
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
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 13,
          fontFamily: 'Lexend',
        ),
        prefixIcon: prefix,
        suffixIcon: const Icon(Icons.edit_outlined, size: 18),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
      ),
    ),
  );

  Widget _dropdownField({
    required String? value,
    required String hint,
    required List<String> items,
    required void Function(String?) onChanged,
  }) => Container(
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
        value: items.contains(value) ? value : null,
        isExpanded: true,
        hint: Text(
          hint,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
            fontSize: 13,
            fontFamily: 'Lexend',
          ),
        ),
        style: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
          fontSize: 13,
          fontFamily: 'Lexend',
        ),
        items: items
            .map((i) => DropdownMenuItem(value: i, child: Text(i)))
            .toList(),
        onChanged: onChanged,
      ),
    ),
  );

  Widget _dropdownLoading() => Container(
    height: 52,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    alignment: Alignment.centerLeft,
    decoration: BoxDecoration(
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.white10
          : Colors.white,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: const SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
  );

  Widget _imageButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) => GestureDetector(
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
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'Lexend',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}
