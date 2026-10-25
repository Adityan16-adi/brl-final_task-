import 'package:flutter/material.dart';

import 'clay_theme.dart';

class AppTheme {
  AppTheme._();

  // Primary & Accent Brand Palette (Deep Indigo & Soft Lavender)
  static const Color primaryIndigo = ClayTokens.deepIndigo;
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color secondarySky = Color(0xFF0EA5E9);

  // Semantic Status Tokens
  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusSubmitted = Color(0xFF3B82F6);
  static const Color statusGraded = Color(0xFF10B981);
  static const Color statusOverdue = Color(0xFFEF4444);

  // Role Badges
  static const Color roleStudent = ClayTokens.deepIndigo;
  static const Color roleTeacher = Color(0xFF8B5CF6);

  // Corner Radii Tokens
  static const double radiusSmall = ClayTokens.radiusSmall;
  static const double radiusMedium = ClayTokens.radiusMedium;
  static const double radiusCard = ClayTokens.radiusMedium;
  static const double radiusDialog = ClayTokens.radiusLarge;

  static ThemeData get light {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: primaryIndigo,
          brightness: Brightness.light,
          surface: ClayTokens.lightBg,
        ).copyWith(
          primary: primaryIndigo,
          onPrimary: Colors.white,
          primaryContainer: ClayTokens.softLavender,
          onPrimaryContainer: ClayTokens.darkInk,
          secondary: const Color(0xFF6356F5),
          surface: ClayTokens.lightBg,
          surfaceContainerHighest: const Color(0xFFE8E6F3),
          onSurface: ClayTokens.darkInk,
          onSurfaceVariant: ClayTokens.secondaryText,
          outlineVariant: const Color(0xFFE1DFED),
        );

    return _buildTheme(colorScheme);
  }

  static ThemeData get dark {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: primaryIndigo,
          brightness: Brightness.dark,
          surface: ClayTokens.darkBg,
        ).copyWith(
          primary: const Color(0xFF8F85FF),
          onPrimary: const Color(0xFF1F1D33),
          primaryContainer: const Color(0xFF2E2B4D),
          onPrimaryContainer: ClayTokens.softLavender,
          secondary: const Color(0xFFA5B4FC),
          surface: ClayTokens.darkBg,
          surfaceContainerHighest: ClayTokens.darkCard,
          onSurface: const Color(0xFFF8F7FC),
          onSurfaceVariant: const Color(0xFFA3A1BD),
          outlineVariant: const Color(0xFF35334D),
        );

    return _buildTheme(colorScheme);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    final cardBg = isDark ? ClayTokens.darkCard : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF35334D)
        : const Color(0xFFE6E4F0);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 19,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClayTokens.radiusMedium),
          side: BorderSide(color: borderColor, width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardBg,
        elevation: 3,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            color: isSelected
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: cardBg,
        elevation: 2,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.15),
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
        unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
        selectedLabelTextStyle: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w800,
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ClayTokens.radiusMedium),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ClayTokens.radiusMedium),
          ),
          side: BorderSide(color: borderColor, width: 1.2),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClayTokens.radiusSmall),
        ),
        side: BorderSide(color: borderColor),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? ClayTokens.darkCard : const Color(0xFFEBE9F5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ClayTokens.radiusMedium),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ClayTokens.radiusMedium),
          borderSide: BorderSide(color: borderColor.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ClayTokens.radiusMedium),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.8),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClayTokens.radiusLarge),
        ),
        backgroundColor: cardBg,
      ),
    );
  }
}
