import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/route_paths.dart';
import '../providers/attendance_provider.dart';

/// Attendance-session mutations with user feedback, shared by the mobile
/// and desktop views.
class AttendanceActions {
  AttendanceActions._();

  /// Asks for the session date (native picker on both platforms), creates
  /// the session and opens it for marking.
  static Future<void> createSession(
    BuildContext context, {
    required int teachingPeriodId,
  }) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );
    if (date == null || !context.mounted) return;
    final provider = context.read<AttendanceProvider>();
    final session = await provider.create(
      teachingPeriodId: teachingPeriodId,
      sessionDate: date,
    );
    if (!context.mounted) return;
    if (session == null) {
      final error = provider.lastError;
      if (error != null) context.showApiError(error);
    } else {
      context.push(RoutePaths.attendanceSessionDetail(session.id));
    }
  }
}
