import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final _picker = ImagePicker();
  File? _imageFile;

  /// CONTROLLERS
  final TextEditingController fullNameController =
  TextEditingController(text: "Ugochukwu Orji");

  final TextEditingController phoneController =
  TextEditingController(text: "+234 9061 686 915");

  final TextEditingController addressController =
  TextEditingController(text: "329 Agbani Road");

  final TextEditingController passwordController =
  TextEditingController();

  final TextEditingController confirmPasswordController =
  TextEditingController();

  /// DROPDOWNS
  String country = "Nigeria";
  String state = "Enugu";
  String city = "Enugu";

  /// SHOW SAVE BUTTONS
  bool hasChanges = false;

  @override
  void initState() {
    super.initState();

    /// LISTEN FOR FIELD CHANGES
    fullNameController.addListener(_onFieldChanged);
    phoneController.addListener(_onFieldChanged);
    addressController.addListener(_onFieldChanged);
    passwordController.addListener(_onFieldChanged);
    confirmPasswordController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!hasChanges) {
      setState(() {
        hasChanges = true;
      });
    }
  }

  void _onDropdownChanged() {
    setState(() {
      hasChanges = true;
    });
  }

  void _saveChanges() {
    setState(() {
      hasChanges = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile Updated")),
    );
  }

  void _cancelChanges() {
    setState(() {
      hasChanges = false;
    });

    /// RESET VALUES IF YOU WANT
    fullNameController.text = "Ugochukwu Orji";
    phoneController.text = "+234 9061 686 915";
    addressController.text = "329 Agbani Road";

    passwordController.clear();
    confirmPasswordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
            onPressed: () {
              GoRouter.of(context).pop();
            },
            icon: const Icon(
              Iconsax.arrow_left,
              size: 17,
            )),
        title: Text(
          "Update Profile",
          style: TextStyle(
            fontFamily: 'Lexend',
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// PROFILE IMAGE
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _imageFile == null ?  CircleAvatar(
                      radius: 75,
                      backgroundImage: AssetImage("assets/images/profile_pic.png"),
                    ) : Image.file(_imageFile!),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Iconsax.trash,
                          size: 16,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              /// IMAGE BUTTONS
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _imageButton(
                    icon: Icons.camera_outlined,
                    text: "Snap",
                    onTap: _pickImageFromCamera,
                  ),
                  const SizedBox(width: 12),
                  _imageButton(
                    icon: Iconsax.cloud_notif,
                    text: "Upload",
                    onTap: _pickImageFromGallery,
                  ),
                ],
              ),
              const SizedBox(height: 26),
              /// FULL NAME
              _fieldLabel("Full Name"),
              const SizedBox(height: 8),
              _customField(
                controller: fullNameController,
                hint: "Enter full name",
              ),
              const SizedBox(height: 18),
              /// PHONE
              _fieldLabel("Phone Number"),
              const SizedBox(height: 8),
              _customField(
                controller: phoneController,
                hint: "Enter phone number",
                prefix: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 10),

                    Container(
                      width: 20,
                      height: 14,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(
                            "assets/images/nigeria_flag.png",
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              /// COUNTRY
              _fieldLabel("Country"),
              const SizedBox(height: 8),

              _dropdownField(
                value: country,
                items: const ["Nigeria", "Ghana", "Kenya"],
                onChanged: (value) {
                  setState(() {
                    country = value!;
                  });
                  _onDropdownChanged();
                },
              ),
              const SizedBox(height: 18),
              /// STATE + CITY
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel("State"),
                        const SizedBox(height: 8),
                        _dropdownField(
                          value: state,
                          items: const ["Enugu", "Lagos", "Abuja"],
                          onChanged: (value) {
                            setState(() {
                              state = value!;
                            });
                            _onDropdownChanged();
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
                        _fieldLabel("City"),
                        const SizedBox(height: 8),
                        _dropdownField(
                          value: city,
                          items: const ["Enugu", "Nsukka", "Awgu"],
                          onChanged: (value) {
                            setState(() {
                              city = value!;
                            });
                            _onDropdownChanged();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              /// ADDRESS
              _fieldLabel("Address"),
              const SizedBox(height: 8),
              _customField(
                controller: addressController,
                hint: "Enter address",
              ),
              const SizedBox(height: 18),
              /// PASSWORDS
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel("New Password"),
                        const SizedBox(height: 8),
                        _customField(
                          controller: passwordController,
                          hint: "********",
                          obscure: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel("Confirm Password"),
                        const SizedBox(height: 8),
                        _customField(
                          controller: confirmPasswordController,
                          hint: "********",
                          obscure: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              /// SHOW BUTTONS ONLY WHEN EDITED
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),

                child: hasChanges
                    ? Column(
                  children: [
                    /// SAVE BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          "Save",
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
                    /// CANCEL BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _cancelChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFBE3E3),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          "Cancel",
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
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// =========================================================
  /// FIELD LABEL
  /// =========================================================

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        fontFamily: 'Lexend',
      ),
    );
  }

  /// =========================================================
  /// CUSTOM INPUT FIELD
  /// =========================================================

  Widget _customField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    Widget? prefix,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),

      child: TextField(
        controller: controller,
        obscureText: obscure,

        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 13,
            fontFamily: 'Lexend',
          ),
          prefixIcon: prefix,
          suffixIcon: const Icon(
            Icons.edit_outlined,
            size: 18,
            color: Colors.black54,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 15,
          ),
        ),
      ),
    );
  }

  // picking from Gallery
  Future<void> _pickImageFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // picking from camera
  Future<void> _pickImageFromCamera() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  /// DROPDOWN FIELD
  Widget _dropdownField({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),

      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,

          style: const TextStyle(
            color: Colors.black87,
            fontSize: 13,
            fontFamily: 'Lexend',
          ),

          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item),
            );
          }).toList(),

          onChanged: onChanged,
        ),
      ),
    );
  }

  /// =========================================================
  /// IMAGE BUTTON
  /// =========================================================

  Widget _imageButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: Colors.grey.shade300,
          ),
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
}
