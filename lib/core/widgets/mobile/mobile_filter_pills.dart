import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// A horizontally scrolling row of single-choice pills (Todos, En curso…).
class MobileFilterPills<T> extends StatelessWidget {
  const MobileFilterPills({
    super.key,
    required this.options,
    required this.selected,
    required this.label,
    required this.onSelected,
  });

  final List<T> options;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final option in options)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Material(
                color: option == selected
                    ? AppColors.accentBlue
                    : colors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                  side: BorderSide(
                    color: option == selected
                        ? AppColors.accentBlue
                        : colors.outline,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => onSelected(option),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 9,
                    ),
                    child: Text(
                      label(option),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: option == selected
                            ? Colors.white
                            : colors.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
