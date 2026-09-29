import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/desktop/desktop_section_card.dart';
import '../../../domain/entities/student_entity.dart';
import '../../shared/student_detail_widgets.dart';
import '../../shared/student_grades_controller.dart';
import '../../shared/student_status_chip.dart';

/// The student's profile cards: personal data (with copy buttons) and the
/// current enrollment. A side column beside the tabs on wide screens.
List<Widget> studentProfileCards(
  BuildContext context,
  StudentDetailEntity detail,
) {
  final student = detail.student;
  final current = currentEnrollmentOf(detail);

  return [
    DesktopSectionCard(
      icon: Icons.person_outline,
      title: 'Datos personales',
      child: Column(
        children: [
          const SizedBox(height: 8),
          _Field(label: 'Nombre completo', value: student.fullName),
          _Field(
            label: 'Código',
            value: student.studentCode,
            onCopy: () => StudentDetailActions.copy(
              context,
              'Código',
              student.studentCode,
            ),
          ),
          _Field(
            label: 'Identificación',
            value: student.identificationNumber.isEmpty
                ? 'Sin registrar'
                : student.identificationNumber,
            onCopy: student.identificationNumber.isEmpty
                ? null
                : () => StudentDetailActions.copy(
                    context,
                    'Identificación',
                    student.identificationNumber,
                  ),
          ),
          _Field(
            label: 'Correo electrónico',
            value: student.email.isEmpty ? 'Sin registrar' : student.email,
            onCopy: student.email.isEmpty
                ? null
                : () => StudentDetailActions.copy(
                    context,
                    'Correo',
                    student.email,
                  ),
          ),
        ],
      ),
    ),
    DesktopSectionCard(
      icon: Icons.school_outlined,
      title: 'Matrícula actual',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          if (current == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Sin matrículas registradas.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )
          else ...[
            _Field(label: 'Curso', value: current.courseLabel),
            _Field(label: 'Año lectivo', value: '${current.academicYear}'),
            _Field(
              label: 'Matriculado desde',
              value: Formatters.date(current.enrolledAt),
            ),
            if (current.withdrawnAt != null)
              _Field(
                label: 'Retirado el',
                value: Formatters.date(current.withdrawnAt!),
              ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: StudentStatusChip(enrollment: current),
            ),
          ],
        ],
      ),
    ),
  ];
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value, this.onCopy});

  final String label;
  final String value;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 1),
                SelectableText(value, style: textTheme.bodyMedium),
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(
              tooltip: 'Copiar ${label.toLowerCase()}',
              visualDensity: VisualDensity.compact,
              onPressed: onCopy,
              icon: const Icon(Icons.copy_outlined, size: 16),
            ),
        ],
      ),
    );
  }
}
