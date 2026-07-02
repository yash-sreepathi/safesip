import 'package:flutter/material.dart';

/// SafeSip color palette: primary blues #39c6e1, #215b76 + white and accents.
class AppColors {
  AppColors._();

  // Primary
  static const Color primaryLight = Color(0xFF39C6E1);
  static const Color primaryDark = Color(0xFF215B76);
  static const Color white = Color(0xFFFFFFFF);

  // Backgrounds
  static const Color backgroundLight = Color(0xFFF0F9FC);
  static const Color surface = Color(0xFFFFFFFF);

  // Semantic
  static const Color safe = Color(0xFF2E8B6E);
  static const Color warning = Color(0xFFD4A03A);
  static const Color error = Color(0xFFC75C5C);

  // Text
  static const Color textPrimary = Color(0xFF1A3A4A);
  static const Color textSecondary = Color(0xFF5A6C7D);

  // Borders
  static const Color border = Color(0xFFC5D4DE);

  // Map pin colors by contaminant type (distinct for filter/legend)
  static const Color pinSafe = Color(0xFF2E8B6E);           // green
  static const Color pinCuCl2 = Color(0xFFB87333);          // copper brown
  static const Color pinFeCl3 = Color(0xFF8B4513);         // sienna
  static const Color pinKNO3 = Color(0xFF9370DB);         // medium purple
  static const Color pinNaNO3 = Color(0xFF20B2AA);         // light sea green
  static const Color pinNiCl2 = Color(0xFF4B0082);        // indigo
  static const Color pinPbNO3 = Color(0xFFC75C5C);        // red (lead)
  static const Color pinCuCl2NiCl2 = Color(0xFF2F4F4F);   // dark slate (industrial)
  static const Color pinKNO3NaNO3 = Color(0xFFDA70D6);    // orchid
  static const Color pinPbNO3FeCl3 = Color(0xFFCD853F);   // peru
  static const Color pinContaminant = Color(0xFFD4A03A);  // fallback orange
}
