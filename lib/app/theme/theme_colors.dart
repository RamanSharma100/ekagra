import 'package:flutter/material.dart';

/// Centralized color palette following the dark-first premium design system.
class ThemeColors {
  ThemeColors._();

  // Dark Theme Palette
  static const Color darkBackground = Color(0xFF0B0D10);
  static const Color darkSurface = Color(0xFF13161B);
  static const Color darkElevatedSurface = Color(0xFF1A1E24);
  static const Color darkCardHighlight = Color(0xFF222730);
  static const Color darkBorder = Color(0xFF252B34);
  static const Color darkBorderSubtle = Color(0xFF1D222A);

  // Light Theme Palette
  static const Color lightBackground = Color(0xFFF7F8FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightElevatedSurface = Color(0xFFF0F2F6);
  static const Color lightCardHighlight = Color(0xFFE8ECF2);
  static const Color lightBorder = Color(0xFFE2E6EC);
  static const Color lightBorderSubtle = Color(0xFFECEFF4);

  // Accents (Shared / Tuned)
  static const Color primaryAccent = Color(0xFF7C8CFF);
  static const Color primaryAccentLight = Color(0xFF9AA7FF);
  static const Color primaryAccentDark = Color(0xFF6372E5);
  static const Color primaryAccentSubtle = Color(0x247C8CFF);

  // Functional Semantic Colors
  static const Color success = Color(0xFF4FD18B);
  static const Color successSubtle = Color(0x204FD18B);
  static const Color warning = Color(0xFFF2B84B);
  static const Color warningSubtle = Color(0x20F2B84B);
  static const Color error = Color(0xFFFF6B6B);
  static const Color errorSubtle = Color(0x20FF6B6B);
  static const Color info = Color(0xFF4DB5FF);
  static const Color infoSubtle = Color(0x204DB5FF);

  // Text Colors - Dark Mode
  static const Color darkTextPrimary = Color(0xFFF3F4F6);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkTextMuted = Color(0xFF6B7280);

  // Text Colors - Light Mode
  static const Color lightTextPrimary = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF4B5563);
  static const Color lightTextMuted = Color(0xFF9CA3AF);

  // Activity Category Colors
  static const Color categoryProductive = Color(0xFF4FD18B);
  static const Color categoryNeutral = Color(0xFF7C8CFF);
  static const Color categoryDistracting = Color(0xFFFF6B6B);
}
