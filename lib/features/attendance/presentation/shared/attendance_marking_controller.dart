import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/attendance_entity.dart';
import '../providers/attendance_provider.dart';

/// Fast attendance marking state (§55, §99): per-student statuses edited
/// locally, then one batch [save]. Owned by the page entry point so marks
/// survive a mobile <-> desktop switch.
class AttendanceMarkingController extends ChangeNotifier {
  AttendanceMarkingController(this.sessionId);

  final int sessionId;
  final Map<int, AttendanceStatus?> _statuses = {};

  bool _saving = false;
  bool get saving => _saving;

  AttendanceStatus? statusOf(int studentId) => _statuses[studentId];

  void setStatus(int studentId, AttendanceStatus status) {
    _statuses[studentId] = status;
    notifyListeners();
  }

  /// Seeds the local marks from the statuses already saved on the server.
  void seed(List<SessionStudentRecord> students) {
    for (final s in students) {
      _statuses[s.studentId] = s.status;
    }
    notifyListeners();
  }

  void markAllPresent(List<SessionStudentRecord> students) {
    for (final s in students) {
      _statuses[s.studentId] = AttendanceStatus.present;
    }
    notifyListeners();
  }

  Future<void> save(BuildContext context) async {
    final entries = _statuses.entries.where((e) => e.value != null).toList();
    if (entries.isEmpty) {
      context.showWarning('Marca al menos un estudiante.');
      return;
    }
    _saving = true;
    notifyListeners();
    final error = await context.read<AttendanceProvider>().saveRecords(
      sessionId,
      [
        for (final e in entries)
          (studentId: e.key, status: e.value!, observation: null),
      ],
    );
    _saving = false;
    notifyListeners();
    if (!context.mounted) return;
    if (error != null) {
      context.showApiError(error);
    } else {
      context.showSuccess('Asistencia guardada.');
    }
  }
}
