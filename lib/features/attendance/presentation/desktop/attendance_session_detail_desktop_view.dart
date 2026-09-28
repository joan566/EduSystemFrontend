import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/state/detail_state.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/desktop/desktop_data_table.dart';
import '../../../../core/widgets/desktop/desktop_page_header.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_loading.dart';
import '../../domain/entities/attendance_entity.dart';
import '../providers/attendance_provider.dart';
import '../shared/attendance_marking_controller.dart';
import '../shared/attendance_status_toggle.dart';

/// Desktop: roster as a table with the P/A/E toggle per row; "mark all" and
/// save live in the header.
class AttendanceSessionDetailDesktopView extends StatelessWidget {
  const AttendanceSessionDetailDesktopView({
    super.key,
    required this.controller,
  });

  final AttendanceMarkingController controller;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AttendanceProvider>().detailState;
    final detail = state.data;
    final title = detail == null
        ? 'Asistencia'
        : Formatters.date(detail.session.sessionDate);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DesktopPageHeader(
            title: title,
            subtitle: detail?.session.name,
            breadcrumbs: ['Asistencia', title],
            onBack: () => Navigator.of(context).maybePop(),
            actions: [
              if (detail != null) ...[
                AppButton(
                  label: 'Marcar todos presentes',
                  variant: AppButtonVariant.outlined,
                  onPressed: () => controller.markAllPresent(detail.students),
                ),
                AppButton(
                  label: 'Guardar asistencia',
                  icon: Icons.save_outlined,
                  isLoading: controller.saving,
                  onPressed: () => controller.save(context),
                ),
              ],
            ],
          ),
          Expanded(child: _buildBody(context, state)),
        ],
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
        return DesktopDataTable<SessionStudentRecord>(
          items: state.data!.students,
          columns: [
            DesktopDataColumn(
              label: 'Estudiante',
              cellBuilder: (student) => Text(student.studentName),
            ),
            DesktopDataColumn(
              label: 'Asistencia',
              cellBuilder: (student) => AttendanceStatusToggle(
                value: controller.statusOf(student.studentId),
                onChanged: (status) =>
                    controller.setStatus(student.studentId, status),
              ),
            ),
          ],
        );
    }
  }
}
