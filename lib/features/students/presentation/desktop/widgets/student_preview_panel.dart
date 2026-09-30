import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/shared/app_button.dart';
import '../../../../../core/widgets/shared/skeleton/skeleton_blocks.dart';
import '../../../../../core/widgets/shared/tinted_icon.dart';
import '../../../../grades/presentation/providers/grading_provider.dart';
import '../../../../teaching/presentation/providers/teaching_provider.dart';
import '../../../domain/entities/student_entity.dart';
import '../../shared/student_grades_controller.dart';
import '../../shared/student_status_chip.dart';
import 'students_table.dart';

/// Right-hand preview of the selected student: identity, contact, current
/// course, their grades in your classes of that course, and shortcuts.
class StudentPreviewPanel extends StatelessWidget {
  const StudentPreviewPanel({
    super.key,
    required this.student,
    required this.actions,
  });

  final StudentEntity? student;
  final StudentRowActions actions;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final student = this.student;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outline.withValues(alpha: 0.7)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: student == null
          ? const _Placeholder()
          : _Preview(
              key: ValueKey(student.id),
              student: student,
              actions: actions,
            ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TintedIcon(
              icon: Icons.touch_app_outlined,
              color: AppColors.accentBlue,
              size: 56,
            ),
            const SizedBox(height: 14),
            Text('Selecciona un estudiante', style: textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Haz clic en una fila para ver su resumen aquí. Doble clic o '
              'Enter abre su ficha.',
              style: textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Preview extends StatefulWidget {
  const _Preview({super.key, required this.student, required this.actions});

  final StudentEntity student;
  final StudentRowActions actions;

  @override
  State<_Preview> createState() => _PreviewState();
}

class _PreviewState extends State<_Preview> {
  late final StudentGradesController _grades = StudentGradesController(
    teaching: context.read<TeachingProvider>(),
    grading: context.read<GradingProvider>(),
  );
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final enrollment = widget.student.currentEnrollment;
    if (enrollment == null) return;
    // Holding ↑/↓ walks through rows quickly; only fetch grades for the
    // student the selection settles on. Only the current course's classes.
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _grades.ensureLoaded(
        StudentDetailEntity(student: widget.student, enrollments: [enrollment]),
      );
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _grades.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.student;
    final actions = widget.actions;
    final enrollment = student.currentEnrollment;
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.accentBlue.withValues(alpha: 0.12),
            child: Text(
              student.initials,
              style: textTheme.headlineSmall?.copyWith(
                color: AppColors.accentBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          student.fullName,
          textAlign: TextAlign.center,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            if (enrollment != null)
              _Tag(icon: Icons.class_outlined, label: enrollment.courseLabel),
            StudentStatusChip(enrollment: enrollment),
          ],
        ),
        const SizedBox(height: 20),
        Divider(height: 1, color: colors.outline),
        const SizedBox(height: 8),
        _Field(
          icon: Icons.qr_code_2,
          label: 'Código',
          value: student.studentCode,
          onCopy: () => actions.onCopy('Código', student.studentCode),
        ),
        _Field(
          icon: Icons.credit_card_outlined,
          label: 'Identificación',
          value: student.identificationNumber.isEmpty
              ? 'Sin registrar'
              : student.identificationNumber,
        ),
        _Field(
          icon: Icons.mail_outline,
          label: 'Correo',
          value: student.email.isEmpty ? 'Sin registrar' : student.email,
          onCopy: student.email.isEmpty
              ? null
              : () => actions.onCopy('Correo', student.email),
        ),
        if (enrollment != null)
          _Field(
            icon: Icons.event_available_outlined,
            label: enrollment.active ? 'Matriculado desde' : 'Retirado el',
            value: Formatters.date(
              enrollment.active
                  ? enrollment.enrolledAt
                  : enrollment.withdrawnAt ?? enrollment.enrolledAt,
            ),
          ),
        const SizedBox(height: 8),
        Divider(height: 1, color: colors.outline),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text(
                enrollment == null
                    ? 'Notas'
                    : 'Notas en ${enrollment.courseLabel}',
                style: textTheme.labelLarge,
              ),
            ),
            TextButton(
              onPressed: () => actions.onOpen(student, tab: 2),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accentBlue,
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('Ver todo'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (enrollment == null)
          Text('Sin curso actual.', style: textTheme.bodySmall)
        else
          ListenableBuilder(
            listenable: _grades,
            builder: (context, _) => _GradesGlance(grades: _grades.grades),
          ),
        const SizedBox(height: 20),
        AppButton(
          label: 'Abrir ficha',
          icon: Icons.open_in_new,
          expand: true,
          onPressed: () => actions.onOpen(student),
        ),
        if (enrollment != null && enrollment.active) ...[
          const SizedBox(height: 8),
          AppButton(
            label: 'Retirar de ${enrollment.courseLabel}',
            icon: Icons.person_remove_outlined,
            variant: AppButtonVariant.outlined,
            expand: true,
            onPressed: () => actions.onWithdraw(student),
          ),
        ],
      ],
    );
  }
}

class _GradesGlance extends StatelessWidget {
  const _GradesGlance({required this.grades});

  final List<StudentClassGrade>? grades;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final grades = this.grades;
    if (grades == null) {
      return const SkeletonValueRows(count: 2);
    }
    if (grades.isEmpty) {
      return Text(
        'No dictas clases en este curso.',
        style: textTheme.bodySmall,
      );
    }
    return Column(
      children: [
        for (final g in grades)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${g.period.subjectName} · ${g.period.academicPeriodName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  g.grade?.periodGrade != null && g.scale != null
                      ? Formatters.grade(
                          g.grade!.periodGrade!,
                          g.scale!.maximumValue,
                          decimals: 1,
                        )
                      : g.needsConfiguration
                      ? 'Sin configurar'
                      : '—',
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.icon,
    required this.label,
    required this.value,
    this.onCopy,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: textTheme.bodySmall?.copyWith(fontSize: 11)),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(
              tooltip: 'Copiar ${label.toLowerCase()}',
              visualDensity: VisualDensity.compact,
              onPressed: onCopy,
              icon: const Icon(Icons.copy_outlined, size: 16),
            )
          else
            const SizedBox(height: 40),
        ],
      ),
    );
  }
}
