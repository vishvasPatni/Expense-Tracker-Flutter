import 'package:flutter/material.dart';

/// Semantic palette: light matches Figma light frames; dark follows
/// [Dark-Mode Design.md] (“Midnight Editorial”) and dark Figma frames.
abstract final class AppColors {
  static const Color incomeLight = Color(0xFF006A62);
  static const Color incomeDark = Color(0xFF66D9CC);
  static const Color expenseLight = Color(0xFFB3272A);
  static const Color expenseDark = Color(0xFFFFB3B1);

  static const Color primaryLight = Color(0xFF006A62);
  static const Color primaryDark = Color(0xFF66D9CC);
  static const Color primaryContainerLight = Color(0xFF26A69A);
  static const Color primaryContainerDark = Color(0xFF26A69A);

  static const Color warningLight = Color(0xFFF59E0B);
  static const Color warningDark = Color(0xFFFCD34D);

  /// Light surfaces (Figma)
  static const Color bgLight = Color(0xFFF8F9FA);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color surfaceContainerLight = Color(0xFFF3F4F5);
  static const Color surfaceContainerHighLight = Color(0xFFE1E3E4);
  static const Color chipBgLight = Color(0xFFE7E8E9);
  static const Color dividerLight = Color(0xFFE5E7EB);

  static const Color textPrimaryLight = Color(0xFF191C1D);
  static const Color textSubLight = Color(0xFF3D4947);
  static const Color textMutedLight = Color(0xFF6D7A77);

  /// Midnight Editorial — dark
  static const Color bgDark = Color(0xFF0B1326);
  static const Color surfaceLowestDark = Color(0xFF060E20);
  static const Color cardDark = Color(0xFF2D3449);
  static const Color surfaceContainerDark = Color(0xFF141C2E);
  static const Color surfaceContainerHighDark = Color(0xFF232A42);

  static const Color elevatedDark = Color(0xFF2D3449);
  static const Color inputLight = Color(0xFFF3F4F6);
  static const Color dividerDark = Color(0xFF334155);
  static const Color outlineGhostDark = Color(0xFF3D4947);

  static const Color textPrimaryDark = Color(0xFFDAE2FD);
  static const Color textSubDark = Color(0xFF8B95B8);

  static const Color transferLight = Color(0xFF5C6BC0);
  static const Color transferDark = Color(0xFF9FA8DA);

  /// Curated category palette (charts; works on light & dark backgrounds)
  static const List<Color> categoryPalette = [
    Color(0xFFFF6B6B),
    Color(0xFFFF8E53),
    Color(0xFFFFD93D),
    Color(0xFF6BCB77),
    Color(0xFF4ECDC4),
    Color(0xFF45B7D1),
    Color(0xFF5C85D6),
    Color(0xFFA78BFA),
    Color(0xFFF472B6),
    Color(0xFF92400E),
    Color(0xFF64748B),
    Color(0xFF374151),
  ];

  static String colorToHex(Color c) =>
      '#${c.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
}
