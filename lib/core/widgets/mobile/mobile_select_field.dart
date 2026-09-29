import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'mobile_form.dart';

/// Compact filter box — icon, small label, current value, chevron — that
/// opens a bottom sheet to pick one of [options].
class MobileSelectField<T> extends StatelessWidget {
  const MobileSelectField({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.options,
    required this.itemLabel,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final T value;
  final List<T> options;
  final String Function(T) itemLabel;
  final ValueChanged<T> onChanged;

  Future<void> _open(BuildContext context) async {
    final picked = await showMobileSheet<_Picked<T>>(
      context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final option in options)
                    ListTile(
                      title: Text(itemLabel(option)),
                      trailing: option == value
                          ? const Icon(Icons.check, color: AppColors.accentBlue)
                          : null,
                      onTap: () => Navigator.of(context).pop(_Picked(option)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (picked != null) onChanged(picked.value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            children: [
              Icon(icon, size: 20, color: colors.onSurface),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: textTheme.bodySmall?.copyWith(fontSize: 11),
                    ),
                    Text(
                      itemLabel(value),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color: colors.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wraps the picked option so a nullable [T] (e.g. "Todas" = null) can be
/// told apart from dismissing the sheet.
class _Picked<T> {
  const _Picked(this.value);

  final T value;
}
