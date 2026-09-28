import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/teaching_assignment_entity.dart';
import 'teaching_actions.dart';

/// Deterministic per-subject accent, cycling through the existing semantic
/// palette (no new colors) so classes read apart from each other in lists.
const _subjectPalette = [
  AppColors.primary,
  AppColors.info,
  AppColors.success,
  AppColors.warning,
  AppColors.error,
  AppColors.primaryMedium,
];

Color subjectColor(int subjectId) =>
    _subjectPalette[subjectId % _subjectPalette.length];

class SubjectBadge extends StatelessWidget {
  const SubjectBadge({super.key, required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        name,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }
}

/// Active switch + delete for one assignment.
class AssignmentActions extends StatelessWidget {
  const AssignmentActions({super.key, required this.item});

  final TeachingAssignmentEntity item;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Switch(
          value: item.active,
          onChanged: (value) =>
              TeachingActions.setAssignmentActive(context, item, value),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 18),
          onPressed: () => TeachingActions.deleteAssignment(context, item),
        ),
      ],
    );
  }
}
