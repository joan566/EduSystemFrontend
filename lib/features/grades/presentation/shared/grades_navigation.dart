import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/route_paths.dart';
import '../providers/grading_provider.dart';

/// Opens a student's grades; on return the class's period grades are
/// re-read quietly, since editing a grade inside can change them.
Future<void> openStudentGrades(
  BuildContext context,
  int teachingPeriodId,
  int studentId,
) async {
  await context.push(RoutePaths.studentGrades(teachingPeriodId, studentId));
  if (context.mounted) {
    context.read<GradingProvider>().loadPeriodGrades(
      teachingPeriodId,
      silent: true,
    );
  }
}
