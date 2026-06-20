// styles.dart
import 'package:flutter/material.dart';

abstract class Styles {
  static ThemeData themeData(bool isDarkTheme, BuildContext context) {
    return ThemeData(
      visualDensity: VisualDensity.adaptivePlatformDensity,
      primaryColor: const Color(0xff645AB5),
      scaffoldBackgroundColor: isDarkTheme
          ? const Color(0xFF1E1E2F)
          : const Color(0xFFF8F9FA),
      cardColor: isDarkTheme
          ? const Color(0xFF27273F)
          : Colors.white,
      hoverColor: isDarkTheme
          ? const Color(0xFF2A2A44)
          : const Color(0xFFF1F3F5),
      hintColor: isDarkTheme
          ? const Color(0xFFE3E3E3)
          : Colors.black,
      brightness: isDarkTheme ? Brightness.dark : Brightness.light,
      appBarTheme: AppBarTheme(
        backgroundColor: isDarkTheme
            ? const Color(0xFF1A1A2E)
            : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDarkTheme ? Colors.white : Colors.black87,
        ),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(
          color: isDarkTheme ? Colors.white : const Color(0xFF1A1A2E),
        ),
        bodySmall: TextStyle(
          color: isDarkTheme ? Colors.white : const Color(0xFF1A1A2E),
        ),
        labelLarge: TextStyle(
          color: isDarkTheme ? Colors.white : const Color(0xFF1A1A2E),
        ),
        labelMedium: TextStyle(
          color: isDarkTheme ? Colors.white : const Color(0xFF1A1A2E),
        ),
        labelSmall: TextStyle(
          color: isDarkTheme ? Colors.white : const Color(0xFF1A1A2E),
        ),
        bodyMedium: TextStyle(
          color: isDarkTheme ? Colors.white : const Color(0xFF1A1A2E),
        ),
      ),
      dividerColor: isDarkTheme
          ? const Color(0xFF33334D)
          : const Color(0xFFE5E5EA),
    );
  }
}
