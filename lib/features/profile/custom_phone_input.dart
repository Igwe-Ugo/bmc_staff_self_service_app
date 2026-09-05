import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Combines the selected country's dynamic dial code with the raw user input
/// into an E.164 compliant phone string (e.g., +2348000000000).
String preparePhoneForBackend({
  required String rawInputNumber,
  required String dialCode,
}) {
  final cleanDialCode = dialCode.trim();
  final rawCode = cleanDialCode.replaceAll('+', '');

  String cleanNumber = rawInputNumber.trim();
  if (cleanNumber.startsWith('+')) {
    cleanNumber = cleanNumber.substring(1);
  }

  // Strip dial code if user accidentally pasted it in the text field
  if (rawCode.isNotEmpty && cleanNumber.startsWith(rawCode)) {
    cleanNumber = cleanNumber.substring(rawCode.length).trim();
  }

  return cleanDialCode.isNotEmpty
      ? '$cleanDialCode$cleanNumber'
      : cleanNumber;
}

/// Strips leading plus signs and any matching dial code prefix from stored user phone numbers.
String stripDialCode(String? fullNumber, {String? dialCode}) {
  if (fullNumber == null) return '';
  var number = fullNumber.trim();
  if (number.isEmpty) return '';

  if (number.startsWith('+')) {
    number = number.substring(1);
  }

  if (dialCode != null && dialCode.isNotEmpty) {
    final rawCode = dialCode.replaceAll('+', '').trim();
    if (rawCode.isNotEmpty && number.startsWith(rawCode)) {
      return number.substring(rawCode.length).trim();
    }
  }

  return number;
}

class CustomPhoneInput extends StatefulWidget {
  final TextEditingController controller;
  final String? countryIso2;
  final String? dialCode;
  final String hintText;

  const CustomPhoneInput({
    super.key,
    required this.controller,
    required this.countryIso2,
    this.dialCode,
    this.hintText = '800 000 0000',
  });

  @override
  State<CustomPhoneInput> createState() => _CustomPhoneInputState();
}

class _CustomPhoneInputState extends State<CustomPhoneInput> {
  String? _warningMessage;

  @override
  void initState() {
    super.initState();
    _stripInitialDialCode();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant CustomPhoneInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dialCode != widget.dialCode ||
        oldWidget.countryIso2 != widget.countryIso2 ||
        oldWidget.controller != widget.controller) {
      if (oldWidget.controller != widget.controller) {
        oldWidget.controller.removeListener(_onTextChanged);
        widget.controller.addListener(_onTextChanged);
      }
      _stripInitialDialCode();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _stripInitialDialCode() {
    final dialCode = widget.dialCode;
    if (dialCode == null || dialCode.isEmpty) return;

    final rawCode = dialCode.replaceAll('+', '');
    String currentText = widget.controller.text.trim();

    if (currentText.startsWith('+')) {
      currentText = currentText.substring(1);
    }

    if (currentText.startsWith(rawCode)) {
      final stripped = currentText.substring(rawCode.length).trim();
      widget.controller.value = TextEditingValue(
        text: stripped,
        selection: TextSelection.collapsed(offset: stripped.length),
      );
    }
  }

  void _onTextChanged() {
    final dialCode = widget.dialCode;
    if (dialCode == null || dialCode.isEmpty) return;

    final rawCode = dialCode.replaceAll('+', '');
    final text = widget.controller.text.trim();

    if (text.startsWith('+') || text.startsWith(rawCode)) {
      if (_warningMessage == null) {
        setState(() {
          _warningMessage =
              'Please enter your phone number without the country code ($dialCode).';
        });
      }
    } else {
      if (_warningMessage != null) {
        setState(() {
          _warningMessage = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dialCode = widget.dialCode ?? '+--';
    final iso2 = (widget.countryIso2?.isNotEmpty == true)
        ? widget.countryIso2!.toUpperCase()
        : '--';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _warningMessage != null
                  ? Colors.red
                  : Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 15,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      iso2,
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'Lexend',
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      dialCode,
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'Lexend',
                        fontWeight: FontWeight.w500,
                        color: dialCode != '+--'
                            ? (isDark ? Colors.white : Colors.black87)
                            : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 24, color: Colors.grey.shade300),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'Lexend',
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                      fontFamily: 'Lexend',
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_warningMessage != null) ...[
          const SizedBox(height: 4),
          Text(
            _warningMessage!,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 11,
              fontFamily: 'Lexend',
            ),
          ),
        ],
      ],
    );
  }
}
