import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/state/detail_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/mobile/mobile_file_picker_button.dart';
import '../../../../core/widgets/mobile/mobile_form.dart';
import '../../../../core/widgets/mobile/mobile_section_card.dart';
import '../../../../core/widgets/mobile/mobile_skeletons.dart';
import '../../../../core/widgets/shared/app_async_button.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/skeleton/skeleton_blocks.dart';
import '../../../../core/widgets/shared/tinted_icon.dart';
import '../../domain/entities/gradebook_entities.dart';
import '../providers/gradebook_provider.dart';
import '../shared/attachment_badge.dart';
import '../shared/category_visuals.dart';
import '../shared/grade_labels.dart';
import '../shared/gradebook_actions.dart';
import '../shared/gradebook_forms.dart';

/// Mobile "Detalle de nota": the grade with its weight and contribution,
/// then description, rubric, attachment and the teacher's comment. What
/// can be edited depends on the kind: activities are graded by hand or
/// with a rubric; exams by scanning; attendance by taking roll.
class GradeDetailMobileView extends StatelessWidget {
  const GradeDetailMobileView({
    super.key,
    required this.evaluationId,
    required this.studentId,
  });

  final int evaluationId;
  final int studentId;

  Future<void> _openMore(BuildContext context, GradeDetailEntity detail) async {
    final e = detail.evaluation;
    final isActivity = e.type == EvaluationType.activity;
    final choice = await showMobileSheet<int>(
      context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActivity)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Editar nota y comentario'),
                onTap: () => Navigator.of(context).pop(0),
              ),
            if (isActivity && detail.rubric.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.rule),
                title: const Text('Calificar con rúbrica'),
                onTap: () => Navigator.of(context).pop(1),
              ),
            if (isActivity)
              ListTile(
                leading: const Icon(Icons.list_alt_outlined),
                title: Text(
                  detail.rubric.isEmpty ? 'Crear rúbrica' : 'Editar rúbrica',
                ),
                onTap: () => Navigator.of(context).pop(2),
              ),
            if (isActivity && detail.rubric.isNotEmpty)
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: const Text('Quitar rúbrica'),
                onTap: () => Navigator.of(context).pop(3),
              ),
            ListTile(
              leading: Icon(evaluationIcon(e.type)),
              title: Text(switch (e.type) {
                EvaluationType.exam => 'Abrir el examen',
                EvaluationType.activity => 'Abrir la actividad',
                EvaluationType.attendance => 'Ir a asistencia',
              }),
              onTap: () => Navigator.of(context).pop(4),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    switch (choice) {
      case 0:
        await showMobileForm<void>(
          context,
          child: GradeEditForm(detail: detail),
        );
      case 1:
        await showMobileForm<void>(
          context,
          child: RubricScoresForm(detail: detail),
        );
      case 2:
        await showMobileForm<void>(context, child: RubricForm(detail: detail));
      case 3:
        await GradebookActions.deleteRubric(context, detail);
      case 4:
        context.push(switch (e.type) {
          EvaluationType.exam => RoutePaths.examDetail(e.examId!),
          EvaluationType.activity => RoutePaths.activityDetail(e.activityId!),
          EvaluationType.attendance => RoutePaths.attendanceForClass(
            detail.teachingPeriodId,
            date: e.evaluationDate,
          ),
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GradebookProvider>().detail(
      evaluationId,
      studentId,
    );
    final detail = state.data;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
            child: Row(
              children: [
                const BackButton(),
                const SizedBox(width: 4),
                Expanded(
                  child: Text('Detalle de nota', style: textTheme.titleLarge),
                ),
                if (detail != null)
                  IconButton(
                    tooltip: 'Más opciones',
                    onPressed: () => _openMore(context, detail),
                    icon: const Icon(Icons.more_vert),
                  ),
              ],
            ),
          ),
          Expanded(
            child: switch (state.status) {
              DetailStatus.error => AppErrorState(
                exception: state.error!,
                onRetry: () => context.read<GradebookProvider>().refreshDetail(
                  evaluationId,
                  studentId,
                ),
              ),
              _ when detail == null => const MobileDetailSkeleton(
                avatar: SkeletonLeading.square,
              ),
              _ => RefreshIndicator(
                onRefresh: () => context
                    .read<GradebookProvider>()
                    .refreshDetail(evaluationId, studentId),
                child: _Content(detail: detail),
              ),
            },
          ),
        ],
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.detail});

  final GradeDetailEntity detail;

  @override
  Widget build(BuildContext context) {
    final e = detail.evaluation;
    final textTheme = Theme.of(context).textTheme;
    final description = e.description?.trim();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _GradeCard(detail: detail),
        if (description != null && description.isNotEmpty) ...[
          const SizedBox(height: 12),
          MobileSectionCard(
            icon: Icons.description_outlined,
            title: 'Descripción',
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(description, style: textTheme.bodyMedium),
            ),
          ),
        ],
        const SizedBox(height: 12),
        switch (e.type) {
          EvaluationType.activity => _RubricCard(detail: detail),
          EvaluationType.exam => _ExamCard(detail: detail),
          EvaluationType.attendance => const _AttendanceCard(),
        },
        if (e.type != EvaluationType.attendance) ...[
          const SizedBox(height: 12),
          _AttachmentCard(detail: detail),
        ],
        const SizedBox(height: 12),
        _CommentCard(detail: detail),
      ],
    );
  }
}

class _GradeCard extends StatelessWidget {
  const _GradeCard({required this.detail});

  final GradeDetailEntity detail;

  @override
  Widget build(BuildContext context) {
    final e = detail.evaluation;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final visuals = categoryVisuals(e.categoryName);
    final date = e.evaluationDate;
    final contribution = contributionLabel(e);
    final fraction = e.fraction;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TintedIcon(
                icon: evaluationIcon(e.type),
                color: visuals.color,
                size: 48,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.name, style: textTheme.titleMedium),
                    Text(
                      [
                        evaluationKindLabel(e),
                        if (date != null) Formatters.date(date),
                      ].join('  ·  '),
                      style: textTheme.bodySmall,
                    ),
                    Text(
                      '${detail.student.fullName} · ${visuals.label}',
                      style: textTheme.bodySmall?.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      entryGradeLabel(e),
                      style: textTheme.titleSmall?.copyWith(
                        color: AppColors.accentBlue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (contribution != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '($contribution)',
                        style: textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (fraction != null && !e.excluded) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: fraction.clamp(0.0, 1.0),
                minHeight: 6,
                color: AppColors.accentBlue,
                backgroundColor: AppColors.accentBlue.withValues(alpha: 0.12),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Divider(height: 1, color: colors.outline),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _Fact(
                    label: 'Peso en la nota final',
                    value: weightLabel(e.weight),
                  ),
                ),
                VerticalDivider(width: 24, color: colors.outline),
                Expanded(
                  child: _Fact(
                    label: 'Aporte a la nota',
                    value: e.contribution == null || e.weight == null
                        ? '—'
                        : '${compactNumber(e.contribution!)} de ${compactNumber(e.weight!)} pts',
                  ),
                ),
              ],
            ),
          ),
          if (e.excluded)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'No cuenta para la nota: falta con excusa o sin registro de asistencia.',
                style: textTheme.bodySmall?.copyWith(color: AppColors.warning),
              ),
            ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _RubricCard extends StatelessWidget {
  const _RubricCard({required this.detail});

  final GradeDetailEntity detail;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final rubric = detail.rubric;
    final max = detail.evaluation.maximumScore;

    if (rubric.isEmpty) {
      return MobileSectionCard(
        icon: Icons.rule,
        title: 'Rúbrica de evaluación',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Text(
              'Esta actividad no tiene rúbrica. Con una, calificas cada criterio '
              'y la nota se calcula sola.',
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Crear rúbrica',
              icon: Icons.add,
              variant: AppButtonVariant.outlined,
              onPressed: () => showMobileForm<void>(
                context,
                child: RubricForm(detail: detail),
              ),
            ),
          ],
        ),
      );
    }

    final scored = rubric.every((c) => c.score != null);
    return MobileSectionCard(
      icon: Icons.rule,
      title: 'Rúbrica de evaluación',
      linkLabel: scored ? 'Recalificar' : 'Calificar',
      onLink: () => showMobileForm<void>(
        context,
        child: RubricScoresForm(detail: detail),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Expanded(child: Text('Criterio', style: textTheme.labelMedium)),
                Text('Puntaje', style: textTheme.labelMedium),
                const SizedBox(width: 44),
              ],
            ),
          ),
          for (final (i, c) in rubric.indexed) ...[
            if (i > 0) Divider(height: 1, color: colors.outline),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.accents[i % AppColors.accents.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(c.name, style: textTheme.bodyMedium)),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      c.score == null
                          ? '—'
                          : '${compactNumber(c.score!)} / ${compactNumber(max)}',
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColors.accentBlue,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    child: Text(
                      '${compactNumber(c.weight)}%',
                      textAlign: TextAlign.end,
                      style: textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (!scored)
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 4),
              child: Text(
                'Aún no se ha calificado con la rúbrica.',
                style: textTheme.bodySmall?.copyWith(color: AppColors.warning),
              ),
            ),
        ],
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  const _ExamCard({required this.detail});

  final GradeDetailEntity detail;

  @override
  Widget build(BuildContext context) {
    final e = detail.evaluation;
    final submission = e.submissionId;
    return MobileSectionCard(
      icon: Icons.fact_check_outlined,
      title: 'Hoja de respuestas',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text(
            submission == null
                ? 'Este estudiante aún no tiene hoja escaneada. La nota se registra '
                      'al escanear o subir el PDF del examen.'
                : 'La nota sale de la hoja escaneada; revísala para ver cada respuesta '
                      'o corregir una detección.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          AppButton(
            label: submission == null
                ? 'Abrir el examen'
                : 'Ver hoja del examen',
            icon: Icons.open_in_new,
            variant: AppButtonVariant.outlined,
            onPressed: () => context.push(
              submission == null
                  ? RoutePaths.examDetail(e.examId!)
                  : RoutePaths.submissionDetail(e.examId!, submission),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard();

  @override
  Widget build(BuildContext context) {
    return MobileSectionCard(
      icon: Icons.event_available_outlined,
      title: 'Asistencia',
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          'Presente cuenta el puntaje completo; ausente, cero; con excusa no cuenta. '
          'Se cambia al tomar asistencia.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}

class _AttachmentCard extends StatelessWidget {
  const _AttachmentCard({required this.detail});

  final GradeDetailEntity detail;

  @override
  Widget build(BuildContext context) {
    final attachment = detail.attachment;
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final uploading = context.watch<GradebookProvider>().isUploadingAttachment(
      detail,
    );

    return MobileSectionCard(
      icon: Icons.attach_file,
      title: 'Archivo adjunto',
      subtitle: 'opcional',
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: attachment == null
            ? MobileFilePickerButton(
                label: 'Adjuntar archivo',
                allowedExtensions: GradebookActions.attachmentExtensions,
                hint: 'PDF, Word, Excel, PowerPoint o imagen. Máx. 10 MB.',
                busy: uploading,
                onFilePicked: (file) =>
                    GradebookActions.upload(context, detail, file),
              )
            : Container(
                padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.outline),
                ),
                child: Row(
                  children: [
                    AttachmentBadge(fileName: attachment.fileName),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            attachment.fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyMedium,
                          ),
                          Text(
                            Formatters.fileSize(attachment.sizeBytes),
                            style: textTheme.bodySmall?.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    AppAsyncIconButton(
                      tooltip: 'Descargar',
                      onPressed: () =>
                          GradebookActions.download(context, detail),
                      icon: Icons.download_outlined,
                    ),
                    IconButton(
                      tooltip: 'Quitar archivo',
                      onPressed: () =>
                          GradebookActions.deleteAttachment(context, detail),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({required this.detail});

  final GradeDetailEntity detail;

  @override
  Widget build(BuildContext context) {
    final e = detail.evaluation;
    final textTheme = Theme.of(context).textTheme;
    final canEdit = e.type == EvaluationType.activity;
    final comment = e.comment;
    final gradedAt = e.gradedAt;

    return MobileSectionCard(
      icon: Icons.chat_bubble_outline,
      title: 'Comentarios del docente',
      linkLabel: canEdit ? (comment == null ? 'Agregar' : 'Editar') : null,
      onLink: canEdit
          ? () => showMobileForm<void>(
              context,
              child: GradeEditForm(detail: detail),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              comment ??
                  (canEdit
                      ? 'Sin comentario.'
                      : 'Los comentarios se dejan en las actividades.'),
              style: textTheme.bodyMedium?.copyWith(
                color: comment == null ? AppColors.textSecondary : null,
              ),
            ),
            if (gradedAt != null) ...[
              const SizedBox(height: 6),
              Text(
                'Calificado el ${Formatters.date(gradedAt)}',
                style: textTheme.bodySmall?.copyWith(fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
