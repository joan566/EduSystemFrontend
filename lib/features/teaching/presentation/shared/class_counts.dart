import 'package:flutter/material.dart';

/// "2 clases/sem · 16 alumnos" line of a class card. [weeklySessions] is
/// null while unknown, and then omitted rather than shown as zero.
class ClassCounts extends StatelessWidget {
  const ClassCounts({
    super.key,
    required this.weeklySessions,
    required this.students,
  });

  final int? weeklySessions;
  final int students;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11);
    final iconColor = style?.color;

    Widget item(IconData icon, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: iconColor),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            text,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    final sessions = weeklySessions;
    return Wrap(
      spacing: 10,
      children: [
        if (sessions != null)
          item(
            Icons.event_outlined,
            sessions == 1 ? '1 clase/sem' : '$sessions clases/sem',
          ),
        item(
          Icons.people_alt_outlined,
          students == 1 ? '1 alumno' : '$students alumnos',
        ),
      ],
    );
  }
}
