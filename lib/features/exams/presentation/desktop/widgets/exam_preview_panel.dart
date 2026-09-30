import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/state/list_state.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/shared/app_button.dart';
import '../../../../../core/widgets/shared/app_status_chip.dart';
import '../../../../../core/widgets/shared/tinted_icon.dart';
import '../../../../teaching/domain/entities/teaching_period_entity.dart';
import '../../../domain/entities/exam_entity.dart';
import '../../providers/submissions_provider.dart';
import '../../shared/exam_results_summary.dart';
import 'exams_table.dart';

/// Right-hand preview of the selected exam: where it stands (questions →
/// sheets → grading), its results so far, and a shortcut to each tab.
class ExamPreviewPanel extends StatelessWidget {
  const ExamPreviewPanel({
    super.key,
    required this.exam,
    required this.period,
    required this.actions,
  });

  final ExamSummaryEntity? exam;
  final TeachingPeriodEntity? period;
  final ExamRowActions actions;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final exam = this.exam;

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
      child: exam == null
          ? const _Placeholder()
          : _Preview(
              key: ValueKey(exam.id),
              exam: exam,
              period: period,
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
            Text('Selecciona un examen', style: textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Haz clic en una fila para ver su estado y resultados aquí. '
              'Doble clic o Enter lo abre.',
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
  const _Preview({
    super.key,
    required this.exam,
    required this.period,
    required this.actions,
  });

  final ExamSummaryEntity exam;
  final TeachingPeriodEntity? period;
  final ExamRowActions actions;

  @override
  State<_Preview> createState() => _PreviewState();
}

class _PreviewState extends State<_Preview> {
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final submissions = context.read<SubmissionsProvider>();
    // Results already in memory show at once (no request). Otherwise,
    // holding ↑/↓ walks through rows quickly: only the exam the selection
    // settles on is read.
    if (submissions.results(widget.exam.id).status != ViewStatus.initial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) submissions.ensureResults(widget.exam.id);
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) submissions.ensureResults(widget.exam.id);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exam = widget.exam;
    final period = widget.period;
    final actions = widget.actions;
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final submissions = context.watch<SubmissionsProvider>().results(exam.id);
    final results =
        submissions.status == ViewStatus.success ||
            submissions.status == ViewStatus.empty
        ? ExamResultsSummary.from(submissions.items, exam)
        : null;
    final date = exam.evaluationDate;
    final description = exam.description?.trim();
    final students = period?.studentCount;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TintedIcon(
              icon: Icons.description_outlined,
              color: AppColors.accentBlue,
              size: 44,
              solid: true,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exam.name, style: textTheme.titleMedium),
                  const SizedBox(height: 6),
                  AppStatusChip(
                    label: exam.ready ? 'Listo' : 'Incompleto',
                    kind: exam.ready
                        ? AppStatusKind.success
                        : AppStatusKind.warning,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (description != null && description.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(description, style: textTheme.bodySmall),
        ],
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Fact(
              icon: Icons.calendar_today_outlined,
              label: date == null ? 'Sin fecha' : Formatters.date(date),
            ),
            _Fact(
              icon: Icons.format_list_numbered,
              label: '${exam.numberOfQuestions} preguntas',
            ),
            if (exam.maximumScore != null)
              _Fact(
                icon: Icons.grade_outlined,
                label: 'Nota máx. ${exam.maximumScore!.toStringAsFixed(1)}',
              ),
            if (students != null)
              _Fact(
                icon: Icons.people_alt_outlined,
                label: '$students estudiantes',
              ),
          ],
        ),
        const SizedBox(height: 20),
        Divider(height: 1, color: colors.outline),
        const SizedBox(height: 16),
        Text('Progreso', style: textTheme.labelLarge),
        const SizedBox(height: 10),
        _Step(
          done: exam.ready,
          title: 'Preguntas configuradas',
          detail: exam.ready
              ? 'Todas las preguntas tienen enunciado, opciones y respuesta.'
              : 'Faltan preguntas por completar.',
          actionLabel: exam.ready ? null : 'Completar',
          onAction: () => actions.onOpen(exam, tab: 0),
        ),
        _Step(
          done: exam.ready,
          title: 'Hojas de respuesta',
          detail: exam.ready
              ? 'Listas para generar e imprimir.'
              : 'Se habilitan al completar las preguntas.',
          actionLabel: exam.ready ? 'Descargar PDF' : null,
          onAction: () => actions.onDownloadSheets(exam),
        ),
        _Step(
          done:
              results != null &&
              students != null &&
              students > 0 &&
              results.graded >= students,
          title: 'Calificación',
          detail: results == null
              ? 'Cargando resultados...'
              : results.sheets == 0
              ? 'Aún no hay hojas calificadas.'
              : '${results.graded} de ${students ?? results.sheets} '
                    'estudiantes calificados'
                    '${results.reviewRequired > 0 ? ' · ${results.reviewRequired} por revisar' : ''}.',
          actionLabel: results != null && results.sheets > 0
              ? 'Ver resultados'
              : null,
          onAction: () => actions.onOpen(exam, tab: 2),
          last: true,
        ),
        if (results != null && results.average != null) ...[
          const SizedBox(height: 8),
          _AverageMeter(average: results.average!, maximum: exam.maximumScore),
        ],
        const SizedBox(height: 20),
        AppButton(
          label: 'Abrir examen',
          icon: Icons.open_in_new,
          expand: true,
          onPressed: () => actions.onOpen(exam),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Preguntas',
                variant: AppButtonVariant.outlined,
                onPressed: () => actions.onOpen(exam, tab: 0),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppButton(
                label: 'Resultados',
                variant: AppButtonVariant.outlined,
                onPressed: () => actions.onOpen(exam, tab: 2),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// One step of the exam's lifecycle, with a connector to the next.
class _Step extends StatelessWidget {
  const _Step({
    required this.done,
    required this.title,
    required this.detail,
    required this.onAction,
    this.actionLabel,
    this.last = false,
  });

  final bool done;
  final String title;
  final String detail;
  final String? actionLabel;
  final VoidCallback onAction;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(
                done ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 20,
                color: done ? AppColors.success : colors.outline,
              ),
              if (!last)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: colors.outline,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(detail, style: textTheme.bodySmall),
                  if (actionLabel != null)
                    TextButton(
                      onPressed: onAction,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.accentBlue,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 30),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text(actionLabel!),
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

/// The class average as a meter against the grade scale.
class _AverageMeter extends StatelessWidget {
  const _AverageMeter({required this.average, required this.maximum});

  final double average;
  final double? maximum;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final maximum = this.maximum;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accentBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Promedio de la clase', style: textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            maximum == null
                ? average.toStringAsFixed(1)
                : Formatters.grade(average, maximum, decimals: 1),
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (maximum != null && maximum > 0) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (average / maximum).clamp(0.0, 1.0),
                minHeight: 6,
                color: AppColors.accentBlue,
                backgroundColor: AppColors.accentBlue.withValues(alpha: 0.15),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
