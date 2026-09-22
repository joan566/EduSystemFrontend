import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/state/detail_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../domain/entities/attendance_entity.dart';
import '../providers/attendance_provider.dart';

/// Fast attendance marking (§55, §99): tap through the whole roster with
/// three-way chips per student, then a single batch save.
class AttendanceSessionDetailPage extends StatefulWidget {
  const AttendanceSessionDetailPage({super.key, required this.sessionId});

  final int sessionId;

  @override
  State<AttendanceSessionDetailPage> createState() =>
      _AttendanceSessionDetailPageState();
}

class _AttendanceSessionDetailPageState
    extends State<AttendanceSessionDetailPage> {
  final Map<int, AttendanceStatus?> _statuses = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<AttendanceProvider>().loadDetail(widget.sessionId);
      final detail = context.read<AttendanceProvider>().detailState.data;
      if (detail != null && mounted) {
        setState(() {
          for (final s in detail.students) {
            _statuses[s.studentId] = s.status;
          }
        });
      }
    });
  }

  void _markAllPresent(List<SessionStudentRecord> students) {
    setState(() {
      for (final s in students) {
        _statuses[s.studentId] = AttendanceStatus.present;
      }
    });
  }

  Future<void> _save() async {
    final entries = _statuses.entries.where((e) => e.value != null).toList();
    if (entries.isEmpty) {
      context.showWarning('Marca al menos un estudiante.');
      return;
    }
    setState(() => _saving = true);
    final error = await context.read<AttendanceProvider>().saveRecords(
      widget.sessionId,
      [
        for (final e in entries)
          (studentId: e.key, status: e.value!, observation: null),
      ],
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      context.showApiError(error);
    } else {
      context.showSuccess('Asistencia guardada.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AttendanceProvider>().detailState;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          state.data == null
              ? 'Asistencia'
              : Formatters.date(state.data!.session.sessionDate),
        ),
        actions: state.data == null
            ? null
            : [
                TextButton(
                  onPressed: () => _markAllPresent(state.data!.students),
                  child: const Text('Marcar todos'),
                ),
              ],
      ),
      body: _buildBody(state),
      bottomNavigationBar: state.data == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AppButton(
                  label: 'Guardar asistencia',
                  isLoading: _saving,
                  expand: true,
                  onPressed: _save,
                ),
              ),
            ),
    );
  }

  Widget _buildBody(DetailViewState<SessionDetailEntity> state) {
    switch (state.status) {
      case DetailStatus.initial:
      case DetailStatus.loading:
        return const AppLoading();
      case DetailStatus.error:
        return AppErrorState(
          exception: state.error!,
          onRetry: () =>
              context.read<AttendanceProvider>().loadDetail(widget.sessionId),
        );
      case DetailStatus.success:
        final students = state.data!.students;
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: students.length,
          separatorBuilder: (_, _) => const SizedBox(height: 6),
          itemBuilder: (context, index) {
            final student = students[index];
            return AppListTile(
              icon: Icons.person_outline,
              title: student.studentName,
              trailing: _StatusToggle(
                value: _statuses[student.studentId],
                onChanged: (status) =>
                    setState(() => _statuses[student.studentId] = status),
              ),
            );
          },
        );
    }
  }
}

class _StatusToggle extends StatelessWidget {
  const _StatusToggle({required this.value, required this.onChanged});

  final AttendanceStatus? value;
  final void Function(AttendanceStatus) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _chip(context, 'P', AttendanceStatus.present, AppColors.success),
        const SizedBox(width: 4),
        _chip(context, 'A', AttendanceStatus.absent, AppColors.error),
        const SizedBox(width: 4),
        _chip(context, 'E', AttendanceStatus.excused, AppColors.warning),
      ],
    );
  }

  Widget _chip(
    BuildContext context,
    String label,
    AttendanceStatus status,
    Color color,
  ) {
    final selected = value == status;
    return InkWell(
      onTap: () => onChanged(status),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
