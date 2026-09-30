import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';

/// Opens a student's grades. Editing a grade inside makes the class's
/// period grades stale, so the list re-reads them on return only then.
Future<void> openStudentGrades(
  BuildContext context,
  int teachingPeriodId,
  int studentId,
) => context.push(RoutePaths.studentGrades(teachingPeriodId, studentId));
