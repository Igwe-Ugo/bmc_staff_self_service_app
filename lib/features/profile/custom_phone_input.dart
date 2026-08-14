// lib/features/profile/custom_phone_input.dart
//
// Self-contained replacement for InternationalPhoneNumberInput's
// selector+field UI, built specifically because that package has no way to
// disable JUST its country selector while keeping the number field editable
// (confirmed open bug: natintosh/intl_phone_number_input#143). Building our
// own removes the constraint entirely — the "selector" here is a static
// Text, never a button, so there's no interactive element to lock down.
//
// The dial-code table below is self-contained and does NOT depend on your
// existing Country/world-countries model (which may or may not carry dial
// codes) — E.164 calling codes are stable reference data, safe to embed
// directly rather than guess at an unseen model's fields.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomPhoneInput extends StatelessWidget {
  final TextEditingController controller;

  /// Driven entirely by whatever the Country dropdown elsewhere in the form
  /// has selected — this widget never changes it itself.
  final String? countryIso2;

  final String hintText;

  const CustomPhoneInput({
    super.key,
    required this.controller,
    required this.countryIso2,
    this.hintText = '800 000 0000',
  });

  @override
  Widget build(BuildContext context) {
    final dialCode = dialCodeFor(countryIso2);
    final flag = flagEmojiFor(countryIso2);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          // Static display only — deliberately not a GestureDetector/button.
          // This is the whole point: nothing here is tappable, so there's
          // no selector to disable in the first place.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(flag, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  dialCode ?? '+--',
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'Lexend',
                    fontWeight: FontWeight.w500,
                    color: dialCode != null
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
              controller: controller,
              // markDirty (ProfileProvider._attachListeners) is already
              // wired to this controller — no onChanged needed here to get
              // dirty-tracking working.
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'Lexend',
                color: isDark ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 13,
                  fontFamily: 'Lexend',
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Regional Indicator Symbol trick: two letters in this Unicode range render
/// as the corresponding country's flag on iOS, Android, and most modern
/// desktop OSes. Falls back to a generic globe for null/unrecognised codes.
String flagEmojiFor(String? iso2) {
  if (iso2 == null || iso2.length != 2) return '🌐';
  final upper = iso2.toUpperCase();
  const base = 0x1F1E6; // Regional Indicator Symbol Letter A
  final first = base + (upper.codeUnitAt(0) - 'A'.codeUnitAt(0));
  final second = base + (upper.codeUnitAt(1) - 'A'.codeUnitAt(0));
  if (first < base || first > base + 25 || second < base || second > base + 25) {
    return '🌐';
  }
  return String.fromCharCode(first) + String.fromCharCode(second);
}

String? dialCodeFor(String? iso2) {
  if (iso2 == null) return null;
  return _dialCodes[iso2.toUpperCase()];
}

/// ISO 3166-1 alpha-2 → E.164 calling code.
const Map<String, String> _dialCodes = {
  'AD': '+376', 'AE': '+971', 'AF': '+93', 'AG': '+1', 'AI': '+1',
  'AL': '+355', 'AM': '+374', 'AO': '+244', 'AQ': '+672', 'AR': '+54',
  'AS': '+1', 'AT': '+43', 'AU': '+61', 'AW': '+297', 'AX': '+358',
  'AZ': '+994', 'BA': '+387', 'BB': '+1', 'BD': '+880', 'BE': '+32',
  'BF': '+226', 'BG': '+359', 'BH': '+973', 'BI': '+257', 'BJ': '+229',
  'BL': '+590', 'BM': '+1', 'BN': '+673', 'BO': '+591', 'BQ': '+599',
  'BR': '+55', 'BS': '+1', 'BT': '+975', 'BW': '+267', 'BY': '+375',
  'BZ': '+501', 'CA': '+1', 'CC': '+61', 'CD': '+243', 'CF': '+236',
  'CG': '+242', 'CH': '+41', 'CI': '+225', 'CK': '+682', 'CL': '+56',
  'CM': '+237', 'CN': '+86', 'CO': '+57', 'CR': '+506', 'CU': '+53',
  'CV': '+238', 'CW': '+599', 'CX': '+61', 'CY': '+357', 'CZ': '+420',
  'DE': '+49', 'DJ': '+253', 'DK': '+45', 'DM': '+1', 'DO': '+1',
  'DZ': '+213', 'EC': '+593', 'EE': '+372', 'EG': '+20', 'EH': '+212',
  'ER': '+291', 'ES': '+34', 'ET': '+251', 'FI': '+358', 'FJ': '+679',
  'FK': '+500', 'FM': '+691', 'FO': '+298', 'FR': '+33', 'GA': '+241',
  'GB': '+44', 'GD': '+1', 'GE': '+995', 'GF': '+594', 'GG': '+44',
  'GH': '+233', 'GI': '+350', 'GL': '+299', 'GM': '+220', 'GN': '+224',
  'GP': '+590', 'GQ': '+240', 'GR': '+30', 'GT': '+502', 'GU': '+1',
  'GW': '+245', 'GY': '+592', 'HK': '+852', 'HN': '+504', 'HR': '+385',
  'HT': '+509', 'HU': '+36', 'ID': '+62', 'IE': '+353', 'IL': '+972',
  'IM': '+44', 'IN': '+91', 'IO': '+246', 'IQ': '+964', 'IR': '+98',
  'IS': '+354', 'IT': '+39', 'JE': '+44', 'JM': '+1', 'JO': '+962',
  'JP': '+81', 'KE': '+254', 'KG': '+996', 'KH': '+855', 'KI': '+686',
  'KM': '+269', 'KN': '+1', 'KP': '+850', 'KR': '+82', 'KW': '+965',
  'KY': '+1', 'KZ': '+7', 'LA': '+856', 'LB': '+961', 'LC': '+1',
  'LI': '+423', 'LK': '+94', 'LR': '+231', 'LS': '+266', 'LT': '+370',
  'LU': '+352', 'LV': '+371', 'LY': '+218', 'MA': '+212', 'MC': '+377',
  'MD': '+373', 'ME': '+382', 'MF': '+590', 'MG': '+261', 'MH': '+692',
  'MK': '+389', 'ML': '+223', 'MM': '+95', 'MN': '+976', 'MO': '+853',
  'MP': '+1', 'MQ': '+596', 'MR': '+222', 'MS': '+1', 'MT': '+356',
  'MU': '+230', 'MV': '+960', 'MW': '+265', 'MX': '+52', 'MY': '+60',
  'MZ': '+258', 'NA': '+264', 'NC': '+687', 'NE': '+227', 'NF': '+672',
  'NG': '+234', 'NI': '+505', 'NL': '+31', 'NO': '+47', 'NP': '+977',
  'NR': '+674', 'NU': '+683', 'NZ': '+64', 'OM': '+968', 'PA': '+507',
  'PE': '+51', 'PF': '+689', 'PG': '+675', 'PH': '+63', 'PK': '+92',
  'PL': '+48', 'PM': '+508', 'PR': '+1', 'PS': '+970', 'PT': '+351',
  'PW': '+680', 'PY': '+595', 'QA': '+974', 'RE': '+262', 'RO': '+40',
  'RS': '+381', 'RU': '+7', 'RW': '+250', 'SA': '+966', 'SB': '+677',
  'SC': '+248', 'SD': '+249', 'SE': '+46', 'SG': '+65', 'SH': '+290',
  'SI': '+386', 'SJ': '+47', 'SK': '+421', 'SL': '+232', 'SM': '+378',
  'SN': '+221', 'SO': '+252', 'SR': '+597', 'SS': '+211', 'ST': '+239',
  'SV': '+503', 'SX': '+1', 'SY': '+963', 'SZ': '+268', 'TC': '+1',
  'TD': '+235', 'TG': '+228', 'TH': '+66', 'TJ': '+992', 'TK': '+690',
  'TL': '+670', 'TM': '+993', 'TN': '+216', 'TO': '+676', 'TR': '+90',
  'TT': '+1', 'TV': '+688', 'TW': '+886', 'TZ': '+255', 'UA': '+380',
  'UG': '+256', 'US': '+1', 'UY': '+598', 'UZ': '+998', 'VA': '+379',
  'VC': '+1', 'VE': '+58', 'VG': '+1', 'VI': '+1', 'VN': '+84',
  'VU': '+678', 'WF': '+681', 'WS': '+685', 'YE': '+967', 'YT': '+262',
  'ZA': '+27', 'ZM': '+260', 'ZW': '+263',
};