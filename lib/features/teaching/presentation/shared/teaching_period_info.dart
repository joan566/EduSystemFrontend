import 'package:flutter/material.dart';

import '../../../../core/theme/subject_visuals.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/teaching_period_entity.dart';

/// Subject badge, course · period, dates and student count of a class.
/// Content only; each view puts it in its own card.
class TeachingPeriodInfo extends StatelessWidget {
  const TeachingPeriodInfo({super.key, required this.period});

  final TeachingPeriodEntity period;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = subjectAccent(period.subjectId);

    Widget line(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: textTheme.bodySmall?.color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: textTheme.bodyMedium)),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                subjectIcon(period.subjectName),
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(period.subjectName, style: textTheme.titleLarge),
                  Text(
                    '${period.courseLabel} · ${period.academicPeriodName}',
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        line(
          Icons.date_range_outlined,
          '${Formatters.date(period.startDate)} — ${Formatters.date(period.endDate)}',
        ),
        line(
          Icons.people_alt_outlined,
          period.studentCount == 1
              ? '1 estudiante activo'
              : '${period.studentCount} estudiantes activos',
        ),
      ],
    );
  }
}
