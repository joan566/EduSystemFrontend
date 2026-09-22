import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Centralized [ThemeData]. Every visual primitive (buttons, inputs, cards,
/// dialogs, chips, navigation) is configured here so features never need to
/// hardcode colors or styles.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.primaryMedium,
      onSecondary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surfaceMuted,
      outline: AppColors.border,
    );

    final textTheme = AppTypography.textTheme(
      AppColors.textPrimary,
      AppColors.textSecondary,
    );

    return _build(colorScheme, textTheme, AppColors.background);
  }

  static ThemeData get dark {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primaryLight,
      onPrimary: AppColors.primaryDarkest,
      secondary: AppColors.primaryMedium,
      onSecondary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textPrimaryDark,
      surfaceContainerHighest: AppColors.surfaceMutedDark,
      outline: AppColors.borderDark,
    );

    final textTheme = AppTypography.textTheme(
      AppColors.textPrimaryDark,
      AppColors.textSecondaryDark,
    );

    return _build(colorScheme, textTheme, AppColors.backgroundDark);
  }

  static ThemeData _build(
    ColorScheme colorScheme,
    TextTheme textTheme,
    Color scaffoldBackground,
  ) {
    final isDark = colorScheme.brightness == Brightness.dark;
    final borderColor = colorScheme.outline;
    final shadowColor = isDark ? Colors.black : AppColors.shadowSoft;

    OutlineInputBorder border(Color color, {double width = 1}) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackground,
      fontFamily: AppTypography.fontFamily,
      textTheme: textTheme,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,

      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: shadowColor,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
        centerTitle: false,
      ),

      // Stripe/Vercel-style separation: a crisp, fully-opaque 1px border
      // does most of the work; the shadow is a barely-there accent rather
      // than the primary depth cue (was elevation 3 / 70%-alpha border).
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: isDark ? 0 : 1,
        shadowColor: shadowColor,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: borderColor),
        ),
      ),

      dividerTheme: DividerThemeData(color: borderColor, thickness: 1),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return borderColor;
            return colorScheme.primary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.onSurface.withValues(alpha: 0.4);
            }
            return colorScheme.onPrimary;
          }),
          // Flatter elevation curve — Stripe/Vercel buttons barely lift.
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return 0;
            if (states.contains(WidgetState.pressed)) return 0;
            if (states.contains(WidgetState.hovered)) return 2.0;
            return 0.5;
          }),
          shadowColor: WidgetStatePropertyAll(
            isDark ? Colors.black : colorScheme.primary.withValues(alpha: 0.24),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          ),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
          animationDuration: const Duration(milliseconds: 120),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: borderColor, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: colorScheme.onSurface),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.surfaceMutedDark : AppColors.surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: border(Colors.transparent),
        enabledBorder: border(borderColor.withValues(alpha: isDark ? 1 : 0.8)),
        focusedBorder: border(colorScheme.primary, width: 2),
        errorBorder: border(colorScheme.error),
        focusedErrorBorder: border(colorScheme.error, width: 2),
        labelStyle: textTheme.bodyMedium,
        floatingLabelStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.primary,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: isDark ? AppColors.textSecondaryDark : AppColors.textDisabled,
        ),
        errorStyle: textTheme.bodySmall?.copyWith(color: colorScheme.error),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: isDark
            ? AppColors.surfaceMutedDark
            : AppColors.surfaceMuted,
        labelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        side: BorderSide.none,
        shape: const StadiumBorder(),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shadowColor: shadowColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shadowColor: shadowColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        showDragHandle: true,
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.12),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.primary,
        ),
        unselectedIconTheme: IconThemeData(
          color: colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        unselectedLabelTextStyle: textTheme.labelMedium,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.12),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shadowColor: shadowColor,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return (textTheme.labelMedium ?? const TextStyle()).copyWith(
            color: selected ? colorScheme.primary : null,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
      ),

      // Denser rows (Stripe/Vercel-style data-forward tables) than Material's
      // ~56px default — more rows visible without scrolling.
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStatePropertyAll(
          isDark ? AppColors.surfaceMutedDark : AppColors.surfaceMuted,
        ),
        headingRowHeight: 44,
        headingTextStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
        dataRowMinHeight: 44,
        dataRowMaxHeight: 48,
        dataTextStyle: textTheme.bodyMedium,
        dividerThickness: 1,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: borderColor,
        circularTrackColor: borderColor,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark
            ? AppColors.surfaceMutedDark
            : AppColors.primaryDarkest,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.onSurface,
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: colorScheme.surface),
      ),
    );
  }
}
