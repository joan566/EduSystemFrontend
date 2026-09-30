import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/shared/app_button.dart';
import '../../../../../core/widgets/shared/tinted_icon.dart';
import '../../../domain/entities/grading_entities.dart';
import '../../providers/gradebook_provider.dart';
import '../../shared/category_visuals.dart';
import '../../shared/grade_labels.dart';
import '../../shared/grade_ring.dart';

/// Right-hand preview of the selected student: final grade and, evaluation
/// by evaluation, what they got and what it adds; fetched once the
/// selection settles, so walking the table with ↑/↓ stays cheap.
class StudentGradePreview extends StatefulWidget {
  const StudentGradePreview({
    super.key,
    required this.teachingPeriodId,
    required this.student,
    required this.scale,
    required this.onOpen,
  });

  final int teachingPeriodId;
  final StudentPeriodGrade? student;
  final GradingScaleEntity scale;
  final VoidCallback? onOpen;

  @override
  State<StudentGradePreview> createState() => _StudentGradePreviewState();
}

class _StudentGradePreviewState extends State<StudentGradePreview> {
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final student = widget.student;
    if (student == null) return;
    final gradebook = context.read<GradebookProvider>();
    // A report already in memory shows at once; otherwise it's read once
    // the selection settles.
    if (gradebook.report(widget.teachingPeriodId, student.studentId).data !=
        null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _ensure(student);
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) _ensure(student);
    });
  }

  void _ensure(StudentPeriodGrade student) => context
      .read<GradebookProvider>()
      .ensureReport(widget.teachingPeriodId, student.studentId);

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final student = widget.student;
    final reportState = student == null
        ? null
        : context.watch<GradebookProvider>().report(
            widget.teachingPeriodId,
            student.studentId,
          );
    final report = reportState?.data;
    final error = report == null ? reportState?.error : null;

    final Widget body;
    if (student == null) {
      body = Center(
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
                'Haz clic en una fila para ver sus notas evaluación por evaluación. '
                'Doble clic o Enter abre el detalle.',
                style: textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    } else {
      final grade = student.periodGrade;
      body = ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              GradeRing(
                value: grade == null ? '—' : grade.toStringAsFixed(2),
                maximum: widget.scale.maximumValue.toStringAsFixed(2),
                fraction: grade == null
                    ? null
                    : scaleFraction(grade, widget.scale),
                size: 84,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(student.studentName, style: textTheme.titleMedium),
                    Text(student.studentCode, style: textTheme.bodySmall),
                    const SizedBox(height: 6),
                    GradeStatusChip(
                      passing: student.passing,
                      hasGrade: grade != null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (report?.score != null) ...[
            const SizedBox(height: 12),
            Text(
              '${compactNumber(report!.score!)} de 100 puntos',
              style: textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 16),
          Divider(height: 1, color: colors.outline),
          const SizedBox(height: 12),
          Text('Evaluaciones', style: textTheme.labelLarge),
          const SizedBox(height: 8),
          if (error != null)
            Text('No se pudieron cargar.', style: textTheme.bodySmall)
          else if (report == null)
            const LinearProgressIndicator(minHeight: 2)
          else if (report.evaluations.isEmpty)
            Text(
              'La clase aún no tiene evaluaciones.',
              style: textTheme.bodySmall,
            )
          else
            for (final e in report.evaluations.take(10))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Icon(
                      evaluationIcon(e.type),
                      size: 16,
                      color: categoryVisuals(e.categoryName).color,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        e.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      entryGradeLabel(e),
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                    SizedBox(
                      width: 64,
                      child: Text(
                        contributionLabel(e) ?? '',
                        textAlign: TextAlign.end,
                        style: textTheme.bodySmall?.copyWith(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
          if (report != null && report.evaluations.length > 10)
            Text(
              'y ${report.evaluations.length - 10} más',
              style: textTheme.bodySmall,
            ),
          if (report?.observation != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                report!.observation!.text,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall,
              ),
            ),
          ],
          const SizedBox(height: 20),
          AppButton(
            label: 'Abrir detalle',
            icon: Icons.open_in_new,
            expand: true,
            onPressed: widget.onOpen,
          ),
        ],
      );
    }

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
      child: body,
    );
  }
}
