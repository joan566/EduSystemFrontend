import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/responsive.dart';

/// Gradient hero banner: an eyebrow label, a two-tone title, a subtitle, a
/// large faded decorative icon, and an optional primary action — the
/// opening block for a page that deserves more presence than a plain
/// [AppPageHeader] (Dashboard, Teaching, ...). Reuses the same
/// [AppColors.brandGradient] as the sidebar and login branding panel, so it
/// doesn't introduce a new color, only a new place that color shows up.
class AppHeroBanner extends StatelessWidget {
  const AppHeroBanner({
    super.key,
    required this.eyebrow,
    required this.title,
    this.titleHighlight,
    required this.subtitle,
    this.icon = Icons.school_outlined,
    this.ctaLabel,
    this.ctaIcon,
    this.onCtaPressed,
  });

  final String eyebrow;
  final String title;

  /// Optional trailing portion of the title rendered in the lighter brand
  /// accent instead of white (e.g. "Gestiona tus clases " + "académicas").
  final String? titleHighlight;
  final String subtitle;
  final IconData icon;

  /// A single primary action rendered as a white pill button — desktop/
  /// tablet only; mobile pages are expected to offer the same action via a
  /// FloatingActionButton instead, matching the rest of the app's pattern.
  final String? ctaLabel;
  final IconData? ctaIcon;
  final VoidCallback? onCtaPressed;

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final textTheme = Theme.of(context).textTheme;
    final showCta = !isMobile && ctaLabel != null && onCtaPressed != null;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.brandGradient,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Opacity(
                opacity: isMobile ? 0.10 : 0.14,
                child: Icon(
                  icon,
                  size: isMobile ? 110 : 170,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      eyebrow.toUpperCase(),
                      style: textTheme.labelMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.65),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        style:
                            (isMobile
                                    ? textTheme.headlineLarge
                                    : textTheme.displayLarge)
                                ?.copyWith(color: Colors.white),
                        children: [
                          TextSpan(text: title),
                          if (titleHighlight != null)
                            TextSpan(
                              text: titleHighlight,
                              style: const TextStyle(
                                color: AppColors.primaryLight,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ),
              ),
              if (showCta) ...[
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  onPressed: onCtaPressed,
                  icon: ctaIcon == null
                      ? const SizedBox.shrink()
                      : Icon(ctaIcon, size: 18),
                  label: Text(ctaLabel!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryDarkest,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
