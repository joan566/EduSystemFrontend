import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/state/detail_state.dart';
import '../../../../core/widgets/desktop/desktop_page_header.dart';
import '../../../../core/widgets/shared/app_card.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_loading.dart';
import '../../domain/entities/student_entity.dart';
import '../providers/students_provider.dart';
import '../shared/student_detail_widgets.dart';

/// Desktop: breadcrumbed header, then profile card and enrollment history
/// side by side.
class StudentDetailDesktopView extends StatelessWidget {
  const StudentDetailDesktopView({super.key, required this.studentId});

  final int studentId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<StudentsProvider>().detailState;
    final name = state.data?.student.fullName ?? 'Estudiante';

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DesktopPageHeader(title: name, breadcrumbs: ['Estudiantes', name]),
          Expanded(child: _buildBody(context, state)),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    DetailViewState<StudentDetailEntity> state,
  ) {
    switch (state.status) {
      case DetailStatus.initial:
      case DetailStatus.loading:
        return const AppLoading();
      case DetailStatus.error:
        return AppErrorState(
          exception: state.error!,
          onRetry: () => context.read<StudentsProvider>().loadDetail(studentId),
        );
      case DetailStatus.success:
        final detail = state.data!;
        final student = detail.student;
        final textTheme = Theme.of(context).textTheme;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 340,
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Datos del estudiante',
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Código ${student.studentCode}',
                        style: textTheme.labelMedium,
                      ),
                      const SizedBox(height: 16),
                      StudentInfoRow(
                        icon: Icons.mail_outline,
                        text: student.email,
                      ),
                      const SizedBox(height: 8),
                      StudentInfoRow(
                        icon: Icons.badge_outlined,
                        text: 'Identificación: ${student.identificationNumber}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Historial de matrícula',
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      if (detail.enrollments.isEmpty)
                        const AppEmptyState(
                          title: 'Sin matrículas registradas',
                          message:
                              'Este estudiante todavía no ha sido matriculado '
                              'en ningún curso.',
                          icon: Icons.class_outlined,
                        )
                      else
                        for (final enrollment in detail.enrollments)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: StudentEnrollmentTile(
                              studentId: studentId,
                              enrollment: enrollment,
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }
}
