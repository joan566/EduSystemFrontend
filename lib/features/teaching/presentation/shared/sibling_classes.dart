import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/subject_visuals.dart';
import '../../domain/entities/teaching_period_entity.dart';
import '../providers/teaching_provider.dart';

/// The teacher's other classes in [period]'s course and academic period,
/// by subject.
List<TeachingPeriodEntity> siblingClasses(
  List<TeachingPeriodEntity> all,
  TeachingPeriodEntity period,
) =>
    [
      for (final p in all)
        if (p.groupId == period.groupId &&
            p.academicPeriodId == period.academicPeriodId &&
            p.id != period.id)
          p,
    ]..sort(
      (a, b) =>
          a.subjectName.toLowerCase().compareTo(b.subjectName.toLowerCase()),
    );

/// "También en 6° A: [Estadística] [Física]": jumps to the other subjects
/// taught in the same course, replacing this class's screen. Nothing when
/// there are none.
class SiblingClassesBar extends StatelessWidget {
  const SiblingClassesBar({super.key, required this.period});

  final TeachingPeriodEntity period;

  @override
  Widget build(BuildContext context) {
    final siblings = siblingClasses(
      context.watch<TeachingProvider>().allPeriods,
      period,
    );
    if (siblings.isEmpty) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('También en ${period.courseLabel}:', style: textTheme.bodySmall),
        for (final s in siblings)
          ActionChip(
            avatar: Icon(
              subjectIcon(s.subjectName),
              size: 16,
              color: subjectAccent(s.subjectId),
            ),
            label: Text(s.subjectName),
            visualDensity: VisualDensity.compact,
            onPressed: () =>
                context.pushReplacement(RoutePaths.teachingPeriodDetail(s.id)),
          ),
      ],
    );
  }
}
