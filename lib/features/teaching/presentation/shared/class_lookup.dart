import '../../../academic_periods/domain/entities/academic_period_entity.dart';
import '../../domain/entities/teaching_assignment_entity.dart';
import '../../domain/entities/teaching_period_entity.dart';

enum ClassPeriodStatus { upcoming, active, finished }

/// Where a class stands on [now] relative to its academic period dates.
ClassPeriodStatus classPeriodStatus(TeachingPeriodEntity period, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  if (today.isBefore(period.startDate)) return ClassPeriodStatus.upcoming;
  if (today.isAfter(period.endDate)) return ClassPeriodStatus.finished;
  return ClassPeriodStatus.active;
}

/// The class (teaching period) of [assignment] in [academicPeriodId], or —
/// when that is null ("todos los periodos") — its most recent one.
TeachingPeriodEntity? classForAssignment(
  TeachingAssignmentEntity assignment,
  List<TeachingPeriodEntity> periods, {
  int? academicPeriodId,
}) {
  final own =
      periods
          .where((p) => p.teachingAssignmentId == assignment.id)
          .where(
            (p) =>
                academicPeriodId == null ||
                p.academicPeriodId == academicPeriodId,
          )
          .toList()
        ..sort((a, b) => b.startDate.compareTo(a.startDate));
  return own.firstOrNull;
}

/// Academic period to preselect: the one running today, else the most
/// recent one.
AcademicPeriodEntity? defaultAcademicPeriod(
  List<AcademicPeriodEntity> periods,
) {
  final running = periods.where((p) => p.isActive).firstOrNull;
  if (running != null) return running;
  final sorted = [...periods]
    ..sort((a, b) => b.startDate.compareTo(a.startDate));
  return sorted.firstOrNull;
}

/// Case- and accent-insensitive "contains", for the class search box.
bool matchesSearch(String query, List<String?> fields) {
  final q = _fold(query.trim());
  if (q.isEmpty) return true;
  return fields.any((f) => f != null && _fold(f).contains(q));
}

String _fold(String value) {
  const from = 'áéíóúüñÁÉÍÓÚÜÑ';
  const to = 'aeiouunAEIOUUN';
  final buffer = StringBuffer();
  for (final rune in value.runes) {
    final char = String.fromCharCode(rune);
    final i = from.indexOf(char);
    buffer.write(i < 0 ? char : to[i]);
  }
  return buffer.toString().toLowerCase();
}
