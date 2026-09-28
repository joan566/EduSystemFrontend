import 'package:provider/provider.dart';
import 'package:flutter/widgets.dart';

import '../../../../core/state/list_state.dart';
import '../../../courses/presentation/providers/courses_provider.dart';
import '../../../students/presentation/providers/students_provider.dart';
import '../../../teaching/presentation/providers/teaching_provider.dart';

/// A teacher is "brand new" only once every relevant source has confirmed
/// empty — not merely unloaded/erroring — so a transient failure never gets
/// mistaken for "you have nothing yet".
bool watchIsBrandNewTeacher(BuildContext context) {
  final students = context.watch<StudentsProvider>().state;
  final courses = context.watch<CoursesProvider>().state;
  final assignments = context.watch<TeachingProvider>().assignmentsState;
  return students.status == ViewStatus.empty &&
      courses.status == ViewStatus.empty &&
      assignments.status == ViewStatus.empty;
}

/// "Buenos días" / "Buenas tardes" / "Buenas noches" for the current hour.
String greetingForNow() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Buenos días';
  if (hour < 19) return 'Buenas tardes';
  return 'Buenas noches';
}
