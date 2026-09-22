import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/state/detail_state.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../domain/entities/student_entity.dart';
import '../providers/students_provider.dart';

class StudentDetailPage extends StatefulWidget {
  const StudentDetailPage({super.key, required this.studentId});

  final int studentId;

  @override
  State<StudentDetailPage> createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends State<StudentDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<StudentsProvider>().loadDetail(widget.studentId),
    );
  }

  Future<void> _withdraw(StudentEnrollmentEntity enrollment) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Retirar estudiante',
      message:
          'El estudiante se retirará de ${enrollment.courseLabel}. Se conservará su historial.',
      confirmLabel: 'Retirar',
    );
    if (!confirmed || !mounted) return;
    final error = await context.read<StudentsProvider>().withdraw(
      widget.studentId,
      enrollment.groupId,
    );
    if (!mounted) return;
    if (error != null) {
      context.showApiError(error);
    } else {
      context.showSuccess('Estudiante retirado del curso.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<StudentsProvider>().detailState;

    return Scaffold(
      appBar: AppBar(title: const Text('Estudiante')),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(DetailViewState<StudentDetailEntity> state) {
    switch (state.status) {
      case DetailStatus.initial:
      case DetailStatus.loading:
        return const AppLoading();
      case DetailStatus.error:
        return AppErrorState(
          exception: state.error!,
          onRetry: () =>
              context.read<StudentsProvider>().loadDetail(widget.studentId),
        );
      case DetailStatus.success:
        final detail = state.data!;
        return ListView(
          children: [
            AppPageHeader(
              title: detail.student.fullName,
              subtitle:
                  'Código ${detail.student.studentCode} · ${detail.student.email}',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Identificación: ${detail.student.identificationNumber}',
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Historial de matrícula',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            for (final enrollment in detail.enrollments)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: AppListTile(
                  icon: Icons.class_outlined,
                  title: enrollment.courseLabel,
                  subtitle: enrollment.withdrawnAt == null
                      ? 'Matriculado desde ${Formatters.date(enrollment.enrolledAt)}'
                      : 'Matriculado ${Formatters.date(enrollment.enrolledAt)} — '
                            'retirado ${Formatters.date(enrollment.withdrawnAt!)}',
                  trailing: enrollment.active
                      ? TextButton(
                          onPressed: () => _withdraw(enrollment),
                          child: const Text('Retirar'),
                        )
                      : const AppStatusChip(
                          label: 'Retirado',
                          kind: AppStatusKind.neutral,
                        ),
                ),
              ),
            const SizedBox(height: 24),
          ],
        );
    }
  }
}
