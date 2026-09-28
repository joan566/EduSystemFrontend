import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/state/detail_state.dart';
import '../../../../core/widgets/shared/app_card.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_loading.dart';
import '../../domain/entities/student_entity.dart';
import '../providers/students_provider.dart';
import '../shared/student_detail_widgets.dart';

class StudentDetailMobileView extends StatelessWidget {
  const StudentDetailMobileView({super.key, required this.studentId});

  final int studentId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<StudentsProvider>().detailState;

    return Scaffold(
      appBar: AppBar(title: Text(state.data?.student.fullName ?? 'Estudiante')),
      body: _buildBody(context, state),
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
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Código ${student.studentCode}',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 12),
                  StudentInfoRow(icon: Icons.mail_outline, text: student.email),
                  const SizedBox(height: 8),
                  StudentInfoRow(
                    icon: Icons.badge_outlined,
                    text: 'Identificación: ${student.identificationNumber}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Historial de matrícula',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (detail.enrollments.isEmpty)
              const AppEmptyState(
                title: 'Sin matrículas registradas',
                message:
                    'Este estudiante todavía no ha sido matriculado en ningún '
                    'curso.',
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
        );
    }
  }
}
