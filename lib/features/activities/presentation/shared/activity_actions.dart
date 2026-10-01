import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/route_paths.dart';
import '../providers/activities_provider.dart';
import 'activity_form.dart';

/// Activity mutations with user feedback, shared by the mobile and desktop
/// views.
class ActivityActions {
  ActivityActions._();

  /// Creates the activity; returns its id, or null (after showing the
  /// error) when it failed. The form closes with that id and the view then
  /// calls [openCreated].
  static Future<int?> create(
    BuildContext context, {
    required int teachingPeriodId,
    required ActivityFormResult data,
  }) async {
    final provider = context.read<ActivitiesProvider>();
    final activity = await provider.create(
      teachingPeriodId: teachingPeriodId,
      name: data.name,
      activityType: data.activityType.isEmpty ? null : data.activityType,
      maximumScore: data.maximumScore,
    );
    if (!context.mounted) return activity?.id;
    if (activity == null) {
      final error = provider.lastError;
      if (error != null) context.showApiError(error);
      return null;
    }
    context.showSuccess('Actividad creada.');
    return activity.id;
  }

  /// Opens a just-created activity's detail page.
  static void openCreated(BuildContext context, int activityId) =>
      context.push(RoutePaths.activityDetail(activityId));
}
