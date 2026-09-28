import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Gradient hero banner: an eyebrow label, a two-tone title, a subtitle, a
/// large faded decorative icon, and an optional primary action — the
/// opening block for a desktop page that deserves more presence than a
/// plain [DesktopPageHeader] (Dashboard, Teaching, ...). Reuses the same
/// [AppColors.brandGradient] as the sidebar and login branding panel, so it
/// doesn't introduce a new color, only a new place that color shows up.
class DesktopHeroBanner extends StatelessWidget {
  const DesktopHeroBanner({
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

  /// A single primary action rendered as a white pill button.
  final String? ctaLabel;
  final IconData? ctaIcon;
  final VoidCallback? onCtaPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final showCta = ctaLabel != null && onCtaPressed != null;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(28),
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
          // Skipped entirely when a CTA button is present — at any size or
          // position, a decorative icon sharing the same corner as an
          // interactive button reads as visual clutter, not depth.
          if (!showCta)
            Positioned(
              top: -30,
              right: -20,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.10,
                  child: Icon(icon, size: 130, color: Colors.white),
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
                        style: textTheme.displayLarge?.copyWith(
                          color: Colors.white,
                        ),
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
