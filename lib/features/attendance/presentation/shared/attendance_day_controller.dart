import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/attendance_entity.dart';
import '../providers/attendance_provider.dart';

/// Roster filter on desktop.
enum AttendanceFilter { all, unmarked, present, absent, excused }

/// Attendance being marked for one class on one date: each student's
/// status and observation, edited locally and sent together in one
/// request. Owned by the page
/// entry point so marks and the search survive a mobile <-> desktop switch.
class AttendanceDayController extends ChangeNotifier {
  final Map<int, AttendanceStatus?> _statuses = {};
  final Map<int, String?> _observations = {};
  final Set<int> _pending = {};

  List<SessionStudentRecord> _students = const [];
  List<SessionStudentRecord> get students => _students;

  String _query = '';
  String get query => _query;

  AttendanceFilter _filter = AttendanceFilter.all;
  AttendanceFilter get filter => _filter;

  bool _saving = false;
  bool get saving => _saving;

  AttendanceStatus? statusOf(int studentId) => _statuses[studentId];
  String? observationOf(int studentId) => _observations[studentId];
  bool isPending(int studentId) => _pending.contains(studentId);
  bool get hasPending => _pending.isNotEmpty;

  int countOf(AttendanceStatus status) =>
      _statuses.values.where((s) => s == status).length;
  int get presentCount => countOf(AttendanceStatus.present);
  int get pendingCount => _pending.length;
  int get unmarkedCount =>
      _students.where((s) => statusOf(s.studentId) == null).length;

  /// Students matching the search and the filter, in roster order.
  List<SessionStudentRecord> get visibleStudents {
    final q = _query.trim().toLowerCase();
    return _students.where((s) {
      final status = statusOf(s.studentId);
      final matchesFilter = switch (_filter) {
        AttendanceFilter.all => true,
        AttendanceFilter.unmarked => status == null,
        AttendanceFilter.present => status == AttendanceStatus.present,
        AttendanceFilter.absent => status == AttendanceStatus.absent,
        AttendanceFilter.excused => status == AttendanceStatus.excused,
      };
      return matchesFilter &&
          (q.isEmpty ||
              s.studentName.toLowerCase().contains(q) ||
              s.studentCode.toLowerCase().contains(q));
    }).toList();
  }

  /// Starts over from what the server has for the loaded day.
  void seed(List<SessionStudentRecord> students) {
    _students = students;
    _statuses
      ..clear()
      ..addEntries(students.map((s) => MapEntry(s.studentId, s.status)));
    _observations
      ..clear()
      ..addEntries(students.map((s) => MapEntry(s.studentId, s.observation)));
    _pending.clear();
    notifyListeners();
  }

  void clear() {
    _students = const [];
    _statuses.clear();
    _observations.clear();
    _pending.clear();
    notifyListeners();
  }

  void search(String query) {
    _query = query;
    notifyListeners();
  }

  void setFilter(AttendanceFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  /// Drops every unsaved mark, back to what the server has.
  void discard() => seed(_students);

  void mark(int studentId, AttendanceStatus status, {String? observation}) {
    _statuses[studentId] = status;
    _observations[studentId] = observation;
    _pending.add(studentId);
    notifyListeners();
  }

  /// Changes only the observation; it is sent with the student's status.
  void setObservation(int studentId, String observation) {
    final value = observation.trim().isEmpty ? null : observation.trim();
    if (value == _observations[studentId]) return;
    _observations[studentId] = value;
    _pending.add(studentId);
    notifyListeners();
  }

  /// Marks every student without a status as present.
  void markUnmarkedPresent() {
    for (final s in _students) {
      if (statusOf(s.studentId) == null) {
        _statuses[s.studentId] = AttendanceStatus.present;
        _pending.add(s.studentId);
      }
    }
    notifyListeners();
  }

  /// Sends every pending change in a single request. True on success.
  Future<bool> save(BuildContext context) async {
    final ids = {..._pending};
    final records = [
      for (final id in ids)
        if (_statuses[id] case final status?)
          (studentId: id, status: status, observation: _observations[id]),
    ];
    if (records.isEmpty) {
      context.showWarning('Marca al menos un estudiante.');
      return false;
    }
    _saving = true;
    notifyListeners();
    final provider = context.read<AttendanceProvider>();
    final error = await provider.saveDay(records);
    _saving = false;
    if (error == null) {
      _pending.removeAll(ids);
      // What the server has now is what "discard" goes back to.
      _students = provider.day.data?.students ?? _students;
    }
    notifyListeners();
    if (!context.mounted) return error == null;
    if (error != null) {
      context.showApiError(error);
    } else {
      context.showSuccess('Asistencia guardada.');
    }
    return error == null;
  }
}
