import 'package:flutter/material.dart';

/// Centralized typographic scale. Widgets should pull styles from
/// `Theme.of(context).textTheme` (mapped below) rather than hardcoding
/// arbitrary [TextStyle]s.
///
/// Mapping used throughout the app:
/// - displayLarge  -> Display
/// - headlineLarge -> Headline
/// - titleLarge    -> Title
/// - titleMedium   -> Subtitle
/// - bodyMedium    -> Body
/// - labelLarge    -> Label
/// - bodySmall     -> Caption
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Roboto';

  static TextTheme textTheme(Color primaryText, Color secondaryText) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        height: 1.2,
        color: primaryText,
      ),
      headlineLarge: TextStyle(
        fontSize: 27,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        height: 1.25,
        color: primaryText,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.3,
        color: primaryText,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.35,
        color: primaryText,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: primaryText,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.55,
        color: primaryText,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1.3,
        letterSpacing: 0.15,
        color: primaryText,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        height: 1.3,
        letterSpacing: 0.3,
        color: secondaryText,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        letterSpacing: 0.1,
        color: secondaryText,
      ),
    );
  }
}
