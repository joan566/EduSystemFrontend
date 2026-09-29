import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Top of a mobile catalog screen (Materias, Cursos, ...): back when the
/// screen was pushed, a large title with a count line, and the add button.
class MobileCatalogHeader extends StatelessWidget {
  const MobileCatalogHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onAdd,
    this.addTooltip = 'Agregar',
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onAdd;
  final String addTooltip;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 12, 0),
      child: Row(
        children: [
          if (Navigator.of(context).canPop())
            const BackButton()
          else
            const SizedBox(width: 12),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.headlineLarge?.copyWith(fontSize: 26),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (onAdd != null)
            IconButton.filledTonal(
              tooltip: addTooltip,
              onPressed: onAdd,
              icon: const Icon(Icons.add),
            ),
        ],
      ),
    );
  }
}
