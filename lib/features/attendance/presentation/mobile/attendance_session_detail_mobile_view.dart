import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/state/detail_state.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_list_tile.dart';
import '../../../../core/widgets/shared/app_loading.dart';
import '../../domain/entities/attendance_entity.dart';
import '../providers/attendance_provider.dart';
import '../shared/attendance_marking_controller.dart';
import '../shared/attendance_status_toggle.dart';

/// Mobile: tap through the roster card by card, sticky save at the bottom.
class AttendanceSessionDetailMobileView extends StatelessWidget {
  const AttendanceSessionDetailMobileView({
    super.key,
    required this.controller,
  });

  final AttendanceMarkingController controller;

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
                  onPressed: () =>
                      controller.markAllPresent(state.data!.students),
                  child: const Text('Marcar todos'),
                ),
              ],
      ),
      body: _buildBody(context, state),
      bottomNavigationBar: state.data == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AppButton(
                  label: 'Guardar asistencia',
                  isLoading: controller.saving,
                  expand: true,
                  onPressed: () => controller.save(context),
                ),
              ),
            ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    DetailViewState<SessionDetailEntity> state,
  ) {
    switch (state.status) {
      case DetailStatus.initial:
      case DetailStatus.loading:
        return const AppLoading();
      case DetailStatus.error:
        return AppErrorState(
          exception: state.error!,
          onRetry: () => context.read<AttendanceProvider>().loadDetail(
            controller.sessionId,
          ),
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
              trailing: AttendanceStatusToggle(
                value: controller.statusOf(student.studentId),
                onChanged: (status) =>
                    controller.setStatus(student.studentId, status),
              ),
            );
          },
        );
    }
  }
}
