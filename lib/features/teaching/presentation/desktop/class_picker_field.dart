import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/subject_visuals.dart';
import '../../../../core/widgets/desktop/desktop_dialog.dart';
import '../../../../core/widgets/shared/tinted_icon.dart';
import '../../domain/entities/teaching_period_entity.dart';
import '../providers/teaching_provider.dart';
import '../shared/class_picker.dart';

/// The class picker in a dialog; returns the class picked.
Future<TeachingPeriodEntity?> showDesktopClassPicker(
  BuildContext context, {
  required TeachingPeriodEntity? selected,
}) => showDesktopDialog<TeachingPeriodEntity>(
  context,
  width: 520,
  child: ClassPickerContent(selectedId: selected?.id),
);

/// The class a desktop screen works with, as a toolbar button (subject
/// icon, name, period and students); it opens [showDesktopClassPicker].
class DesktopClassPickerField extends StatelessWidget {
  const DesktopClassPickerField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final TeachingPeriodEntity? value;
  final ValueChanged<TeachingPeriodEntity> onChanged;

  Future<void> _open(BuildContext context) async {
    final picked = await showDesktopClassPicker(context, selected: value);
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final teaching = context.watch<TeachingProvider>();
    final noClasses = teaching.allPeriodsLoaded && teaching.allPeriods.isEmpty;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final value = this.value;

    return Tooltip(
      message: 'Cambiar de clase',
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: noClasses ? null : () => _open(context),
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TintedIcon(
                  icon: value == null
                      ? Icons.class_outlined
                      : subjectIcon(value.subjectName),
                  color: value == null
                      ? AppColors.accentBlue
                      : subjectAccent(value.subjectId),
                  size: 38,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 280),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          value == null
                              ? (noClasses
                                    ? 'Todavía no tienes clases'
                                    : 'Selecciona una clase')
                              : value.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (value != null)
                          Text(
                            '${value.academicPeriodName} · '
                            '${value.studentCount} estudiantes',
                            maxLines: 1,
                            style: textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.unfold_more,
                  size: 20,
                  color: textTheme.bodySmall?.color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
