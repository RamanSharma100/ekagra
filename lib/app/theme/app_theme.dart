import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme_colors.dart';
import 'theme_radius.dart';
import 'theme_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    final textTheme = ThemeTypography.textTheme(true);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ThemeColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: ThemeColors.primaryAccent,
        onPrimary: Colors.white,
        secondary: ThemeColors.primaryAccentLight,
        onSecondary: Colors.white,
        surface: ThemeColors.darkSurface,
        onSurface: ThemeColors.darkTextPrimary,
        error: ThemeColors.error,
        onError: Colors.white,
      ),
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: ThemeColors.darkBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: IconThemeData(color: ThemeColors.darkTextPrimary),
        titleTextStyle: TextStyle(
          color: ThemeColors.darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: const CardThemeData(
        color: ThemeColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: ThemeRadius.radiusL,
          side: BorderSide(color: ThemeColors.darkBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: ThemeColors.darkBorderSubtle,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: ThemeColors.darkSurface,
        elevation: 0,
        indicatorColor: ThemeColors.primaryAccentSubtle,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: ThemeColors.primaryAccent, size: 22);
          }
          return const IconThemeData(color: ThemeColors.darkTextMuted, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ThemeColors.primaryAccent,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: ThemeColors.darkTextMuted,
          );
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ThemeColors.primaryAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: ThemeRadius.radiusM,
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ThemeColors.darkTextPrimary,
          side: const BorderSide(color: ThemeColors.darkBorder, width: 1),
          shape: const RoundedRectangleBorder(
            borderRadius: ThemeRadius.radiusM,
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ThemeColors.darkElevatedSurface,
        border: OutlineInputBorder(
          borderRadius: ThemeRadius.radiusM,
          borderSide: const BorderSide(color: ThemeColors.darkBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: ThemeRadius.radiusM,
          borderSide: const BorderSide(color: ThemeColors.darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: ThemeRadius.radiusM,
          borderSide: const BorderSide(color: ThemeColors.primaryAccent, width: 1.5),
        ),
        hintStyle: const TextStyle(color: ThemeColors.darkTextMuted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  static ThemeData get lightTheme {
    final textTheme = ThemeTypography.textTheme(false);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: ThemeColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: ThemeColors.primaryAccent,
        onPrimary: Colors.white,
        secondary: ThemeColors.primaryAccentDark,
        onSecondary: Colors.white,
        surface: ThemeColors.lightSurface,
        onSurface: ThemeColors.lightTextPrimary,
        error: ThemeColors.error,
        onError: Colors.white,
      ),
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: ThemeColors.lightBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: ThemeColors.lightTextPrimary),
        titleTextStyle: TextStyle(
          color: ThemeColors.lightTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: const CardThemeData(
        color: ThemeColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: ThemeRadius.radiusL,
          side: BorderSide(color: ThemeColors.lightBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: ThemeColors.lightBorderSubtle,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: ThemeColors.lightSurface,
        elevation: 0,
        indicatorColor: ThemeColors.primaryAccentSubtle,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: ThemeColors.primaryAccent, size: 22);
          }
          return const IconThemeData(color: ThemeColors.lightTextMuted, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ThemeColors.primaryAccent,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: ThemeColors.lightTextMuted,
          );
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ThemeColors.primaryAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: ThemeRadius.radiusM,
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ThemeColors.lightTextPrimary,
          side: const BorderSide(color: ThemeColors.lightBorder, width: 1),
          shape: const RoundedRectangleBorder(
            borderRadius: ThemeRadius.radiusM,
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ThemeColors.lightElevatedSurface,
        border: OutlineInputBorder(
          borderRadius: ThemeRadius.radiusM,
          borderSide: const BorderSide(color: ThemeColors.lightBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: ThemeRadius.radiusM,
          borderSide: const BorderSide(color: ThemeColors.lightBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: ThemeRadius.radiusM,
          borderSide: const BorderSide(color: ThemeColors.primaryAccent, width: 1.5),
        ),
        hintStyle: const TextStyle(color: ThemeColors.lightTextMuted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
