import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/subject_visuals.dart';
import '../../../../core/widgets/mobile/mobile_form.dart';
import '../../../../core/widgets/shared/tinted_icon.dart';
import '../../domain/entities/teaching_period_entity.dart';
import '../providers/teaching_provider.dart';
import '../shared/class_picker.dart';

/// The class picker in a bottom sheet; returns the class picked.
Future<TeachingPeriodEntity?> showMobileClassPicker(
  BuildContext context, {
  required TeachingPeriodEntity? selected,
}) => showMobileSheet<TeachingPeriodEntity>(
  context,
  builder: (_) => ClassPickerContent(selectedId: selected?.id),
);

/// The class a mobile screen works with, in a card; tapping it opens
/// [showMobileClassPicker].
class MobileClassPickerCard extends StatelessWidget {
  const MobileClassPickerCard({
    super.key,
    required this.value,
    required this.onChanged,
    this.showLabel = false,
  });

  final TeachingPeriodEntity? value;
  final ValueChanged<TeachingPeriodEntity> onChanged;

  /// A small "Clase" label above the value.
  final bool showLabel;

  Future<void> _open(BuildContext context) async {
    final picked = await showMobileClassPicker(context, selected: value);
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final teaching = context.watch<TeachingProvider>();
    final noClasses = teaching.allPeriodsLoaded && teaching.allPeriods.isEmpty;
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
        onTap: noClasses ? null : () => _open(context),
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
                icon: value == null
                    ? Icons.menu_book_outlined
                    : subjectIcon(value.subjectName),
                color: value == null
                    ? AppColors.accentBlue
                    : subjectAccent(value.subjectId),
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
                          ? (noClasses
                                ? 'Todavía no tienes clases'
                                : 'Selecciona una clase')
                          : classPickerLabel(context, value),
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
