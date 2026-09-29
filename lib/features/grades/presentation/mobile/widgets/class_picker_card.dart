import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/mobile/mobile_form.dart';
import '../../../../../core/widgets/shared/tinted_icon.dart';
import '../../../../teaching/domain/entities/teaching_period_entity.dart';
import '../../../../teaching/presentation/providers/teaching_provider.dart';

/// "Castellano — 5° A (2026-2)" in a card; the sheet lists every class.
class ClassPickerCard extends StatelessWidget {
  const ClassPickerCard({
    super.key,
    required this.value,
    required this.onChanged,
    this.showLabel = false,
  });

  final TeachingPeriodEntity? value;
  final ValueChanged<TeachingPeriodEntity?> onChanged;

  /// A small "Clase" label above the value (settings screen).
  final bool showLabel;

  static String label(TeachingPeriodEntity p) =>
      '${p.subjectName} — ${p.courseLabel} (${p.academicPeriodName})';

  Future<void> _open(
    BuildContext context,
    List<TeachingPeriodEntity> all,
  ) async {
    final picked = await showMobileSheet<TeachingPeriodEntity>(
      context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Clase',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final p in all)
                    ListTile(
                      title: Text('${p.subjectName} — ${p.courseLabel}'),
                      subtitle: Text(p.academicPeriodName),
                      trailing: p.id == value?.id
                          ? const Icon(Icons.check, color: AppColors.accentBlue)
                          : null,
                      onTap: () => Navigator.of(context).pop(p),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final all = context.watch<TeachingProvider>().allPeriods;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final value = this.value;

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: all.isEmpty ? null : () => _open(context, all),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            12,
            showLabel ? 12 : 10,
            10,
            showLabel ? 12 : 10,
          ),
          child: Row(
            children: [
              TintedIcon(
                icon: Icons.menu_book_outlined,
                color: AppColors.accentBlue,
                size: showLabel ? 44 : 36,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showLabel) Text('Clase', style: textTheme.bodySmall),
                    Text(
                      value == null
                          ? (all.isEmpty
                                ? 'Todavía no tienes clases'
                                : 'Selecciona una clase')
                          : label(value),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down,
                color: colors.onSurface.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
