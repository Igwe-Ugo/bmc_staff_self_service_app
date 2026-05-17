import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomTextInput extends StatefulWidget {
  final String hint;
  final IconData prefixIcon;
  final bool isPassword;
  final TextEditingController controller;

  const CustomTextInput({
    super.key,
    required this.hint,
    required this.prefixIcon,
    this.isPassword = false,
    required this.controller,
  });

  @override
  State<CustomTextInput> createState() => _CustomTextInputState();
}

class _CustomTextInputState extends State<CustomTextInput> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(30);

    return TextFormField(
      controller: widget.controller,
      obscureText: widget.isPassword ? _obscure : false,
      maxLines: 1,
      style: const TextStyle(
        fontFamily: 'Lexend',
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
          fontFamily: 'Lexend',
          fontSize: 14,
        ),

        /// 🔹 PREFIX ICON
        prefixIcon: Icon(
          widget.prefixIcon,
          size: 20,
          color: Colors.grey.shade500,
        ),

        /// 🔹 PASSWORD TOGGLE ICON
        suffixIcon: widget.isPassword
            ? IconButton(
          onPressed: () {
            setState(() {
              _obscure = !_obscure;
            });
          },
          icon: Icon(
            _obscure ? Icons.visibility_off : Icons.visibility,
            size: 18,
          ),
        )
            : null,

        /// 🔹 SPACING
        contentPadding:
        const EdgeInsets.symmetric(vertical: 18, horizontal: 20),

        /// 🔹 DEFAULT BORDER
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),

        /// 🔹 FOCUSED BORDER
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 1.5,
          ),
        ),

        /// 🔹 ERROR BORDER (future-proof)
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: const BorderSide(
            color: Colors.red,
          ),
        ),

        /// 🔹 FOCUSED ERROR BORDER
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
