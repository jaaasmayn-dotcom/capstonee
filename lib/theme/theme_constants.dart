import 'package:flutter/material.dart';

class ThemeConstants {
  static bool isDark = false;

  static Color get background =>
      isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF0F0DB);

  static Color get cardWhite =>
      isDark
          ? const Color(0xFF1E1E1E)
          : Colors.white;

  static Color get textDark =>
      isDark
          ? Colors.white
          : const Color(0xFF333333);

  static Color get textLight =>
      isDark
          ? Colors.grey.shade400
          : const Color(0xFF718096);

  static const Color primaryGreen =
      Color(0xFF185F20);

  static const Color navyBlue =
      Color(0xFF1A2F4B);

  static const Color optimalGreen =
      Color(0xFF2E7D32);

  static const Color criticalRed =
      Color(0xFFD32F2F);
}