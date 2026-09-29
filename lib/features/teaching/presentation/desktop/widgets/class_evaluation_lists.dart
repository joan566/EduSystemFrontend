import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/state/list_state.dart';
import '../../../../activities/presentation/providers/activities_provider.dart';
import '../../../../exams/presentation/providers/exams_provider.dart';
import '../../shared/class_evaluations.dart';
import '../../shared/class_scoped_state.dart';

/// Exams and activities of [teachingPeriodId], merged, guarding against the
/// shared providers holding another class's lists. Null while loading.
({List<ClassEvaluationItem>? items, bool failed, VoidCallback retry})
watchClassEvaluations(BuildContext context, int teachingPeriodId) {
  void reloadExams() =>
      context.read<ExamsProvider>().load(teachingPeriodId: teachingPeriodId);
  void reloadActivities() => context.read<ActivitiesProvider>().load(
    teachingPeriodId: teachingPeriodId,
  );

  final exams = classScoped(
    context.watch<ExamsProvider>().state,
    teachingPeriodId: teachingPeriodId,
    teachingPeriodOf: (e) => e.teachingPeriodId,
    reload: reloadExams,
  );
  final activities = classScoped(
    context.watch<ActivitiesProvider>().state,
    teachingPeriodId: teachingPeriodId,
    teachingPeriodOf: (a) => a.teachingPeriodId,
    reload: reloadActivities,
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
