import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/shared/app_dropdown.dart';
import '../../../subjects/domain/entities/subject_entity.dart';
import '../../../subjects/presentation/providers/subjects_provider.dart';
import 'teaching_actions.dart';

/// Subject + active-state filters for the assignments list. Renders nothing
/// until subjects are loaded.
class AssignmentFiltersBar extends StatelessWidget {
  const AssignmentFiltersBar({
    super.key,
    required this.filters,
    required this.onChanged,
  });

  final AssignmentFilters filters;
  final ValueChanged<AssignmentFilters> onChanged;

  @override
  Widget build(BuildContext context) {
    final subjects = context.watch<SubjectsProvider>().state.items;
    if (subjects.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: AppDropdown<SubjectEntity?>(
            label: 'Materia',
            value: subjects.where((s) => s.id == filters.subjectId).firstOrNull,
            items: [null, ...subjects],
            itemLabel: (s) => s?.name ?? 'Todas las materias',
            onChanged: (s) => onChanged(
              AssignmentFilters(subjectId: s?.id, active: filters.active),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppDropdown<bool?>(
            label: 'Estado',
            value: filters.active,
            items: const [null, true, false],
            itemLabel: (v) => switch (v) {
              null => 'Todas',
              true => 'Activas',
              false => 'Inactivas',
            },
            onChanged: (v) => onChanged(
              AssignmentFilters(subjectId: filters.subjectId, active: v),
            ),
          ),
        ),
      ],
    );
  }
}
