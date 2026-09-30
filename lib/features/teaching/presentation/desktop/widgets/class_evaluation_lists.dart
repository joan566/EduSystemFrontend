import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/state/list_state.dart';
import '../../../../activities/presentation/providers/activities_provider.dart';
import '../../../../exams/presentation/providers/exams_provider.dart';
import '../../shared/class_evaluations.dart';

/// Exams and activities of [teachingPeriodId], merged, from that class's
/// own cached lists. Null while loading.
({List<ClassEvaluationItem>? items, bool failed, VoidCallback retry})
watchClassEvaluations(BuildContext context, int teachingPeriodId) {
  void reloadExams() =>
      context.read<ExamsProvider>().refreshExams(teachingPeriodId);
  void reloadActivities() =>
      context.read<ActivitiesProvider>().refreshActivities(teachingPeriodId);

  final exams = context.watch<ExamsProvider>().exams(teachingPeriodId);
  final activities = context.watch<ActivitiesProvider>().activities(
    teachingPeriodId,
  );

  bool ready(ListViewState<dynamic> s) =>
      s.status == ViewStatus.success || s.status == ViewStatus.empty;
  final failed =
      exams.status == ViewStatus.error || activities.status == ViewStatus.error;

  return (
    items: ready(exams) && ready(activities)
        ? mergeClassEvaluations(exams.items, activities.items)
        : null,
    failed: failed,
    retry: () {
      reloadExams();
      reloadActivities();
    },
  );
}
