import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Primary & Accent Brand Palette (Restrained Indigo / Blue)
  static const Color primaryIndigo = Color(0xFF4338CA); // Indigo 700
  static const Color accentBlue = Color(0xFF2563EB); // Royal Blue
  static const Color secondarySky = Color(0xFF0284C7); // Sky 600

  // Semantic Status Tokens
  static const Color statusPending = Color(0xFFD97706); // Amber 600
  static const Color statusSubmitted = Color(0xFF2563EB); // Blue 600
  static const Color statusGraded = Color(0xFF059669); // Emerald 600
  static const Color statusOverdue = Color(0xFFDC2626); // Rose 600

  // Role Badges
  static const Color roleStudent = Color(0xFF4F46E5); // Indigo
  static const Color roleTeacher = Color(0xFF7C3AED); // Purple

  // Corner Radii Tokens
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusCard = 14.0;
  static const double radiusDialog = 18.0;

  static ThemeData get light {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: primaryIndigo,
          brightness: Brightness.light,
          surface: const Color(0xFFF8FAFC), // Slate 50
        ).copyWith(
          primary: primaryIndigo,
          onPrimary: Colors.white,
          primaryContainer: const Color(0xFFEEF2FF), // Indigo 50
          onPrimaryContainer: const Color(0xFF312E81),
          surface: const Color(0xFFF8FAFC),
          onSurface: const Color(0xFF0F172A),
          outlineVariant: const Color(0xFFE2E8F0),
        );

    return _buildTheme(colorScheme);
  }

  static ThemeData get dark {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: primaryIndigo,
          brightness: Brightness.dark,
          surface: const Color(0xFF0F172A), // Slate 900
        ).copyWith(
          primary: const Color(0xFF818CF8), // Indigo 400
          onPrimary: const Color(0xFF1E1B4B),
          primaryContainer: const Color(0xFF312E81), // Indigo 900
          onPrimaryContainer: const Color(0xFFE0E7FF),
          surface: const Color(0xFF0F172A),
          onSurface: const Color(0xFFF8FAFC),
          outlineVariant: const Color(0xFF334155),
        );

    return _buildTheme(colorScheme);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: BorderSide(color: borderColor, width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardBg,
        elevation: 2,
        indicatorColor: colorScheme.primary.withAlpha(35),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: cardBg,
        elevation: 1,
        indicatorColor: colorScheme.primary.withAlpha(35),
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
        unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
        selectedLabelTextStyle: TextStyle(
          color: colorScheme.primary,
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
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          side: BorderSide(color: borderColor),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        side: BorderSide(color: borderColor),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusDialog),
        ),
        backgroundColor: cardBg,
      ),
    );
  }
}
