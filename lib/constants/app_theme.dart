import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Ambient elevation per Dark-Mode Design.md
List<BoxShadow> editorialAmbientShadow(BuildContext context) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  if (!dark) {
    return const [
      BoxShadow(
        color: Color(0x0D000000),
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ];
  }
  return const [
    BoxShadow(
      color: Color(0x80060E20),
      blurRadius: 20,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 40,
      offset: Offset(0, 10),
    ),
  ];
}

ThemeData buildLightTheme() {
  final baseScheme = ColorScheme.light(
    primary: AppColors.primaryLight,
    onPrimary: Colors.white,
    primaryContainer: AppColors.primaryContainerLight,
    onPrimaryContainer: Color(0xFF00201D),
    secondary: AppColors.expenseLight,
    onSecondary: Colors.white,
    tertiary: AppColors.transferLight,
    onTertiary: Colors.white,
    surface: AppColors.bgLight,
    onSurface: AppColors.textPrimaryLight,
    onSurfaceVariant: AppColors.textSubLight,
    surfaceContainerLowest: AppColors.bgLight,
    surfaceContainerLow: AppColors.chipBgLight,
    surfaceContainer: AppColors.surfaceContainerLight,
    surfaceContainerHigh: AppColors.surfaceContainerHighLight,
    surfaceContainerHighest: AppColors.cardLight,
    error: AppColors.expenseLight,
    onError: Colors.white,
    outline: AppColors.dividerLight,
    outlineVariant: AppColors.chipBgLight,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: baseScheme,
    scaffoldBackgroundColor: AppColors.bgLight,
    textTheme: GoogleFonts.interTextTheme().apply(
      bodyColor: AppColors.textPrimaryLight,
      displayColor: AppColors.textPrimaryLight,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.cardLight,
      indicatorColor: AppColors.primaryLight.withValues(alpha: 0.12),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryLight,
      foregroundColor: Colors.white,
    ),
    cardTheme: CardThemeData(
      color: baseScheme.surfaceContainerHighest,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    dividerTheme: DividerThemeData(
      color: baseScheme.outline.withValues(alpha: 0.35),
      thickness: 1,
    ),
  );
}

ThemeData buildDarkTheme() {
  final ghost = AppColors.outlineGhostDark.withValues(alpha: 0.15);
  final baseScheme = ColorScheme.dark(
    primary: AppColors.primaryDark,
    onPrimary: Color(0xFF00332E),
    primaryContainer: AppColors.primaryContainerDark,
    onPrimaryContainer: Color(0xFFB8FFF5),
    secondary: AppColors.expenseDark,
    onSecondary: Color(0xFF3D1515),
    tertiary: AppColors.transferDark,
    onTertiary: Color(0xFF1A1F3A),
    surface: AppColors.bgDark,
    onSurface: AppColors.textPrimaryDark,
    onSurfaceVariant: AppColors.textSubDark,
    surfaceContainerLowest: AppColors.surfaceLowestDark,
    surfaceContainerLow: Color(0xFF0A1428),
    surfaceContainer: AppColors.surfaceContainerDark,
    surfaceContainerHigh: AppColors.surfaceContainerHighDark,
    surfaceContainerHighest: AppColors.cardDark,
    error: AppColors.expenseDark,
    onError: Color(0xFF2A0A0A),
    errorContainer: AppColors.expenseDark.withValues(alpha: 0.2),
    onErrorContainer: AppColors.expenseDark,
    outline: ghost,
    outlineVariant: ghost,
  );

  final darkText = GoogleFonts.manropeTextTheme(
    ThemeData(brightness: Brightness.dark).textTheme,
  ).apply(
    bodyColor: AppColors.textPrimaryDark,
    displayColor: AppColors.textPrimaryDark,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: baseScheme,
    scaffoldBackgroundColor: AppColors.bgDark,
    textTheme: darkText,
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: baseScheme.surfaceContainerHigh,
      indicatorColor: AppColors.primaryDark.withValues(alpha: 0.2),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: baseScheme.primaryContainer,
      foregroundColor: baseScheme.onPrimaryContainer,
    ),
    cardTheme: CardThemeData(
      color: baseScheme.surfaceContainerHighest,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    dividerTheme: DividerThemeData(
      color: Colors.transparent,
      thickness: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: baseScheme.primaryContainer,
        foregroundColor: baseScheme.onPrimaryContainer,
      ),
    ),
  );
}
