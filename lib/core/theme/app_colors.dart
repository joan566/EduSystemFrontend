import 'package:flutter/material.dart';

/// Centralized color palette. Never reference raw `Color(0xFF...)` values
/// outside this file — use `Theme.of(context).colorScheme` or [AppColors]
/// constants instead.
class AppColors {
  AppColors._();

  // Brand palette (from product spec).
  static const Color primaryDarkest = Color(0xFF122036);
  static const Color primaryDark = Color(0xFF1E3450);
  static const Color primary = Color(0xFF2A4A6B);
  static const Color primaryMedium = Color(0xFF3E7196);
  static const Color primaryLight = Color(0xFF7FA2B8);

  // Neutrals.
  static const Color background = Color(0xFFF7F9FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFEEF2F6);
  static const Color border = Color(0xFFE1E7ED);
  static const Color textPrimary = Color(0xFF1A2433);
  static const Color textSecondary = Color(0xFF5B6B7C);
  static const Color textDisabled = Color(0xFFA2AEBA);

  // Dark mode neutrals.
  static const Color backgroundDark = Color(0xFF0B1420);
  static const Color surfaceDark = Color(0xFF122036);
  static const Color surfaceMutedDark = Color(0xFF1A2A40);
  static const Color borderDark = Color(0xFF27384E);
  static const Color textPrimaryDark = Color(0xFFE8EDF2);
  static const Color textSecondaryDark = Color(0xFF9FB0C0);

  // Semantic colors.
  static const Color success = Color(0xFF1E8E5A);
  static const Color successBg = Color(0xFFE5F5EC);
  static const Color error = Color(0xFFC5382D);
  static const Color errorBg = Color(0xFFFBEAE8);
  static const Color warning = Color(0xFFB8790C);
  static const Color warningBg = Color(0xFFFBF1DE);
  static const Color info = Color(0xFF2A6BA6);
  static const Color infoBg = Color(0xFFE6F0F8);

  // Identity accents: tell items apart (a subject's icon, a quick action)
  // where a status color would wrongly read as success/warning/error.
  static const Color accentBlue = Color(0xFF2F6FEB);
  static const Color accentGreen = Color(0xFF1F9D6B);
  static const Color accentPurple = Color(0xFF7B5CF0);
  static const Color accentOrange = Color(0xFFE07B24);
  static const Color accentTeal = Color(0xFF1A9AA8);
  static const Color accentPink = Color(0xFFD9467A);
  static const List<Color> accents = [
    accentBlue,
    accentGreen,
    accentPurple,
    accentOrange,
    accentTeal,
    accentPink,
  ];

  // Brand gradient — used sparingly for hero surfaces that should signal
  // trust/security (sidebar, login branding panel), never for body text
  // backgrounds or content cards.
  static const List<Color> brandGradient = [primaryDarkest, primary];
  static const List<Color> brandGradientDark = [Color(0xFF060B14), primaryDark];

  // Elevation shadows, tinted with the brand navy instead of pure black so
  // depth reads as "premium" rather than muddy. Alpha is intentionally low
  // and biased flat/crisp (Stripe/Vercel-style: separation comes mostly
  // from a defined 1px border, shadow is a barely-there accent, not the
  // primary depth cue) rather than soft/diffuse.
  static const Color shadowSoft = Color(0x0D122036); // ~5% navy
  static const Color shadowMedium = Color(0x18122036); // ~9% navy
  static const Color shadowStrong = Color(0x30122036); // ~19% navy
}
