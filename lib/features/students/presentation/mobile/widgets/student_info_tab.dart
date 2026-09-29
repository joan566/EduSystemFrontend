import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/mobile/mobile_section_card.dart';
import '../../../domain/entities/student_entity.dart';
import '../../shared/student_grades_controller.dart';

/// "Información": personal data and the current course.
class StudentInfoTab extends StatelessWidget {
  const StudentInfoTab({super.key, required this.detail});

  final StudentDetailEntity detail;

  @override
  Widget build(BuildContext context) {
    final student = detail.student;
    final current = currentEnrollmentOf(detail);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        MobileSectionCard(
          icon: Icons.person_outline,
          title: 'Datos personales',
          child: Column(
            children: [
              const SizedBox(height: 8),
              _Row(
                icon: Icons.badge_outlined,
                label: 'Nombre completo',
                value: student.fullName,
              ),
              _Row(
                icon: Icons.qr_code_2,
                label: 'Código',
                value: student.studentCode,
              ),
              _Row(
                icon: Icons.class_outlined,
                label: 'Curso',
                value: current?.courseLabel ?? 'Sin curso',
              ),
              _Row(
                icon: Icons.credit_card_outlined,
                label: 'Identificación',
                value: student.identificationNumber.isEmpty
                    ? 'Sin registrar'
                    : student.identificationNumber,
              ),
              _Row(
                icon: Icons.mail_outline,
                label: 'Correo electrónico',
                value: student.email.isEmpty ? 'Sin registrar' : student.email,
                last: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        MobileSectionCard(
          icon: Icons.school_outlined,
          title: 'Información académica',
          child: Column(
            children: [
              const SizedBox(height: 8),
              if (current == null)
                const _Row(
                  icon: Icons.info_outline,
                  label: 'Matrícula',
                  value: 'Sin matrículas registradas',
                  last: true,
                )
              else ...[
                _Row(
                  icon: Icons.class_outlined,
                  label: 'Curso',
                  value: current.courseLabel,
                ),
                _Row(
                  icon: Icons.calendar_month_outlined,
                  label: 'Año lectivo',
                  value: '${current.academicYear}',
                ),
                _Row(
                  icon: Icons.event_available_outlined,
                  label: 'Matriculado desde',
                  value: Formatters.date(current.enrolledAt),
                  last: current.withdrawnAt == null,
                ),
                if (current.withdrawnAt != null)
                  _Row(
                    icon: Icons.event_busy_outlined,
                    label: 'Retirado el',
                    value: Formatters.date(current.withdrawnAt!),
                    last: true,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.value,
    this.last = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(top: 10, bottom: last ? 0 : 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          SizedBox(
            width: 128,
            child: Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: SelectableText(value, style: textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
