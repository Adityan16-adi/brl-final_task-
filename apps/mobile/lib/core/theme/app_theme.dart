import 'package:flutter/material.dart';

/// Central theme specification for Pragti ("Learn · Connect · Grow").
/// All light and dark mode colors are defined here with explicit ColorSchemes
/// and transparent surfaceTint to eliminate purple/violet Material 3 tints.
class AppTheme {
  AppTheme._();

  // Core Brand Tokens
  static const Color primaryBlue = Color(0xFF1680ED);
  static const Color primaryNavy = Color(0xFF0B1E48);
  static const Color accentOrange = Color(0xFFFB9823);

  // Status Tokens
  static const Color statusSuccess = Color(0xFF1E9E6A);
  static const Color statusWarning = Color(0xFFE5A00D);
  static const Color statusError = Color(0xFFD64545);

  // Light Mode Surface & Content Tokens
  static const Color lightBg = Color(0xFFF5F7FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightElevated = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE3E8F0);
  static const Color lightText = Color(0xFF0B1E48);
  static const Color lightSecondaryText = Color(0xFF5B6B8A);

  // Dark Mode Surface & Content Tokens (Calm deep navy/slate, no violet)
  static const Color darkBg = Color(0xFF0A0F1C);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkElevated = Color(0xFF172033);
  static const Color darkBorder = Color(0xFF243049);
  static const Color darkText = Color(0xFFF1F5F9);
  static const Color darkSecondaryText = Color(0xFF94A3B8);

  // Semantic Status Aliases
  static const Color statusPending = accentOrange;
  static const Color statusSubmitted = primaryBlue;
  static const Color statusGraded = statusSuccess;
  static const Color statusOverdue = statusError;

  // Role Badges
  static const Color roleStudent = primaryNavy;
  static const Color roleTeacher = primaryBlue;

  // Corner Radii Tokens
  static const double radiusSmall = 12.0;
  static const double radiusMedium = 16.0;
  static const double radiusCard = 16.0;
  static const double radiusDialog = 20.0;
  static const double radiusPill = 999.0;

  static ColorScheme get lightColorScheme => const ColorScheme(
        brightness: Brightness.light,
        primary: primaryBlue,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFEEF4FF),
        onPrimaryContainer: primaryNavy,
        secondary: primaryNavy,
        onSecondary: Colors.white,
        secondaryContainer: lightBorder,
        onSecondaryContainer: primaryNavy,
        tertiary: accentOrange,
        onTertiary: Colors.white,
        error: statusError,
        onError: Colors.white,
        surface: lightSurface,
        onSurface: lightText,
        onSurfaceVariant: lightSecondaryText,
        outline: lightBorder,
        outlineVariant: lightBorder,
        surfaceTint: Colors.transparent,
      );

  static ColorScheme get darkColorScheme => const ColorScheme(
        brightness: Brightness.dark,
        primary: primaryBlue,
        onPrimary: Colors.white,
        primaryContainer: darkElevated,
        onPrimaryContainer: darkText,
        secondary: darkSecondaryText,
        onSecondary: darkBg,
        secondaryContainer: darkBorder,
        onSecondaryContainer: darkText,
        tertiary: accentOrange,
        onTertiary: Colors.white,
        error: statusError,
        onError: Colors.white,
        surface: darkSurface,
        onSurface: darkText,
        onSurfaceVariant: darkSecondaryText,
        outline: darkBorder,
        outlineVariant: darkBorder,
        surfaceTint: Colors.transparent,
      );

  static ThemeData get light => _buildTheme(lightColorScheme);
  static ThemeData get dark => _buildTheme(darkColorScheme);

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    final cardBg = isDark ? darkElevated : lightSurface;
    final scaffoldBg = isDark ? darkBg : lightBg;
    final borderColor = isDark ? darkBorder : lightBorder;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,
      canvasColor: cardBg,
      dividerColor: borderColor,
      splashColor: primaryBlue.withValues(alpha: 0.08),
      highlightColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: BorderSide(color: borderColor, width: 1),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? darkSurface : lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? darkSurface : lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: primaryBlue.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? primaryBlue : colorScheme.onSurfaceVariant,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: isDark ? darkSurface : lightSurface,
        elevation: 0,
        indicatorColor: primaryBlue.withValues(alpha: 0.12),
        selectedIconTheme: const IconThemeData(color: primaryBlue),
        unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
        selectedLabelTextStyle: const TextStyle(
          color: primaryBlue,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          side: BorderSide(color: borderColor, width: 1),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? darkSurface : lightBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        side: BorderSide(color: borderColor, width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? darkElevated : lightSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: primaryBlue, width: 1.5),
        ),
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 14,
        ),
      ),
      dialogTheme: DialogThemeData(
        surfaceTintColor: Colors.transparent,
        backgroundColor: isDark ? darkSurface : lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusDialog),
          side: BorderSide(color: borderColor, width: 1),
        ),
      ),
    );
  }
}
