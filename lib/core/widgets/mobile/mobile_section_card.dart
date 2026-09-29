import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Rounded white section card of mobile screens: icon + title header with
/// an optional "Ver todo"-style link, then [child].
class MobileSectionCard extends StatelessWidget {
  const MobileSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
    this.linkLabel,
    this.onLink,
    this.padding = const EdgeInsets.fromLTRB(16, 14, 16, 16),
  });

  final IconData icon;
  final String title;
  final Widget child;

  /// Shown after the title as "Title · subtitle".
  final String? subtitle;
  final String? linkLabel;
  final VoidCallback? onLink;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outline.withValues(alpha: 0.7)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: colors.onSurface),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: title,
                    style: textTheme.titleMedium,
                    children: [
                      if (subtitle != null)
                        TextSpan(
                          text: '  ·  $subtitle',
                          style: textTheme.bodySmall?.copyWith(fontSize: 13),
                        ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (linkLabel != null && onLink != null)
                _SectionLink(label: linkLabel!, onTap: onLink!),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SectionLink extends StatelessWidget {
  const _SectionLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: AppColors.accentBlue,
      fontWeight: FontWeight.w600,
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: style),
            const SizedBox(width: 2),
            const Icon(
              Icons.chevron_right,
              size: 16,
              color: AppColors.accentBlue,
            ),
          ],
        ),
      ),
    );
  }
}
