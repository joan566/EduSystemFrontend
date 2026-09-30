import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/state/detail_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/desktop/desktop_dialog.dart';
import '../../../../core/widgets/desktop/desktop_section_card.dart';
import '../../../../core/widgets/desktop/desktop_skeletons.dart';
import '../../../../core/widgets/desktop/desktop_upload_zone.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/picked_file.dart';
import '../../../../core/widgets/shared/skeleton/skeleton_blocks.dart';
import '../../../../core/widgets/shared/tinted_icon.dart';
import '../../domain/entities/gradebook_entities.dart';
import '../providers/gradebook_provider.dart';
import '../shared/attachment_badge.dart';
import '../shared/category_visuals.dart';
import '../shared/grade_labels.dart';
import '../shared/gradebook_actions.dart';
import '../shared/gradebook_forms.dart';

/// Desktop grade detail: the grade, description and rubric in the main
/// column, with the rubric scored in place; comment, attachment (drag &
/// drop) and the evaluation's facts in a side column.
class GradeDetailDesktopView extends StatelessWidget {
  const GradeDetailDesktopView({
    super.key,
    required this.evaluationId,
    required this.studentId,
  });

  final int evaluationId;
  final int studentId;

  static const _sideWidth = 340.0;
  static const _sideBesideMinWidth = 1000.0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GradebookProvider>().detail(
      evaluationId,
      studentId,
    );
    final detail = state.data;

    return Scaffold(
      body: switch (state.status) {
        DetailStatus.error => AppErrorState(
          exception: state.error!,
          onRetry: () => context.read<GradebookProvider>().refreshDetail(
            evaluationId,
            studentId,
          ),
        ),
        _ when detail == null => const DesktopDetailSkeleton(
          avatar: SkeletonLeading.square,
          rail: 2,
          railEnd: true,
        ),
        _ => LayoutBuilder(
          builder: (context, constraints) {
            final d = detail;
            final e = d.evaluation;
            final description = e.description?.trim();
            final main = [
              _GradeCard(detail: d),
              if (description != null && description.isNotEmpty)
                DesktopSectionCard(
                  icon: Icons.description_outlined,
                  title: 'Descripción',
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              switch (e.type) {
                EvaluationType.activity => _RubricCard(
                  key: ValueKey(d.rubric.length),
                  detail: d,
                ),
                EvaluationType.exam => _ExamCard(detail: d),
                EvaluationType.attendance => const _AttendanceCard(),
              },
            ];
            final side = [
              _CommentCard(detail: d),
              if (e.type != EvaluationType.attendance)
                _AttachmentCard(detail: d),
              _FactsCard(detail: d),
            ];
            List<Widget> spaced(List<Widget> cards) => [
              for (final (i, c) in cards.indexed) ...[
                if (i > 0) const SizedBox(height: 16),
                c,
              ],
            ];

            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              children: [
                _Header(detail: d),
                const SizedBox(height: 24),
                if (constraints.maxWidth >= _sideBesideMinWidth)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: spaced(main),
                        ),
                      ),
                      const SizedBox(width: 24),
                      SizedBox(
                        width: _sideWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: spaced(side),
                        ),
                      ),
                    ],
                  )
                else
                  ...spaced([...main, ...side]),
              ],
            );
          },
        ),
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.detail});

  final GradeDetailEntity detail;

  @override
  Widget build(BuildContext context) {
    final e = detail.evaluation;
    final textTheme = Theme.of(context).textTheme;
    final visuals = categoryVisuals(e.categoryName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => Navigator.of(context).canPop()
              ? Navigator.of(context).pop()
              : context.go(
                  RoutePaths.studentGrades(
                    detail.teachingPeriodId,
                    detail.student.id,
                  ),
                ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.arrow_back,
                  size: 16,
                  color: AppColors.accentBlue,
                ),
                const SizedBox(width: 6),
                Text(
                  'Notas de ${detail.student.fullName}',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.accentBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            TintedIcon(
              icon: evaluationIcon(e.type),
              color: visuals.color,
              size: 56,
              solid: true,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.name, style: textTheme.headlineLarge),
                  Text(
                    [
                      evaluationKindLabel(e),
                      visuals.label,
                      if (e.evaluationDate != null)
                        Formatters.date(e.evaluationDate!),
                    ].join('  ·  '),
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final fraction = e.fraction;

    Widget fact(String label, String value) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              fact('Nota', entryGradeLabel(e)),
              fact(
                'Logro',
                fraction == null || e.excluded
                    ? '—'
                    : '${(fraction * 100).round()}%',
              ),
              fact('Peso en la nota final', weightLabel(e.weight)),
              fact(
                'Aporte a la nota',
                e.contribution == null || e.weight == null
                    ? '—'
                    : '${compactNumber(e.contribution!)} de ${compactNumber(e.weight!)} pts',
              ),
            ],
          ),
          if (fraction != null && !e.excluded) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: fraction.clamp(0.0, 1.0),
                minHeight: 8,
                color: AppColors.accentBlue,
                backgroundColor: AppColors.accentBlue.withValues(alpha: 0.12),
              ),
            ),
          ],
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

/// The rubric, scored in place: "Calificar" turns each score into a field
/// and shows the resulting grade live.
class _RubricCard extends StatefulWidget {
  const _RubricCard({super.key, required this.detail});

  final GradeDetailEntity detail;

  @override
  State<_RubricCard> createState() => _RubricCardState();
}

class _RubricCardState extends State<_RubricCard> {
  bool _scoring = false;
  bool _saving = false;
  late Map<int, TextEditingController> _fields = _makeFields();

  Map<int, TextEditingController> _makeFields() => {
    for (final c in widget.detail.rubric)
      c.id: TextEditingController(
        text: c.score == null ? '' : compactNumber(c.score!),
      ),
  };

  @override
  void didUpdateWidget(covariant _RubricCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_scoring && oldWidget.detail != widget.detail) {
      for (final f in _fields.values) {
        f.dispose();
      }
      _fields = _makeFields();
    }
  }

  @override
  void dispose() {
    for (final f in _fields.values) {
      f.dispose();
    }
    super.dispose();
  }

  double get _max => widget.detail.evaluation.maximumScore;

  double? _value(int id) =>
      double.tryParse(_fields[id]!.text.trim().replaceAll(',', '.'));

  double? get _grade {
    var total = 0.0;
    for (final c in widget.detail.rubric) {
      final v = _value(c.id);
      if (v == null || v < 0 || v > _max) return null;
      total += v * c.weight / 100;
    }
    return total;
  }

  Future<void> _save() async {
    if (_grade == null) {
      context.showWarning(
        'Cada criterio necesita un puntaje entre 0 y ${compactNumber(_max)}.',
      );
      return;
    }
    setState(() => _saving = true);
    final error = await context.read<GradebookProvider>().scoreWithRubric(
      widget.detail,
      scores: {for (final c in widget.detail.rubric) c.id: _value(c.id)!},
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      context.showApiError(error);
    } else {
      setState(() => _scoring = false);
      context.showSuccess('Nota calculada con la rúbrica.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final rubric = detail.rubric;
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    if (rubric.isEmpty) {
      return DesktopSectionCard(
        icon: Icons.rule,
        title: 'Rúbrica de evaluación',
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Esta actividad no tiene rúbrica. Con una, calificas cada criterio y la '
                  'nota se calcula sola, para todos los estudiantes con los mismos pesos.',
                  style: textTheme.bodySmall,
                ),
              ),
              const SizedBox(width: 16),
              AppButton(
                label: 'Crear rúbrica',
                icon: Icons.add,
                onPressed: () => showDesktopDialog<void>(
                  context,
                  child: RubricForm(detail: detail),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final header = textTheme.labelMedium?.copyWith(letterSpacing: 0.4);
    final grade = _grade;
    return DesktopSectionCard(
      icon: Icons.rule,
      title: 'Rúbrica de evaluación',
      subtitle: '${rubric.length} criterios',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.outline),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Container(
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.45),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text('CRITERIO', style: header)),
                      SizedBox(width: 80, child: Text('PESO', style: header)),
                      SizedBox(
                        width: 130,
                        child: Text('PUNTAJE', style: header),
                      ),
                      SizedBox(
                        width: 90,
                        child: Text(
                          'APORTA',
                          textAlign: TextAlign.end,
                          style: header,
                        ),
                      ),
                    ],
                  ),
                ),
                for (final (i, c) in rubric.indexed) ...[
                  Divider(height: 1, color: colors.outline),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: _scoring ? 6 : 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color:
                                AppColors.accents[i % AppColors.accents.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(c.name, style: textTheme.bodyMedium),
                        ),
                        SizedBox(
                          width: 80,
                          child: Text(
                            '${compactNumber(c.weight)}%',
                            style: textTheme.bodyMedium,
                          ),
                        ),
                        SizedBox(
                          width: 130,
                          child: _scoring
                              ? Padding(
                                  padding: const EdgeInsets.only(right: 16),
                                  child: TextField(
                                    controller: _fields[c.id],
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    textInputAction: TextInputAction.next,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      suffixText: '/ ${compactNumber(_max)}',
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                )
                              : Text(
                                  c.score == null
                                      ? '—'
                                      : '${compactNumber(c.score!)} / ${compactNumber(_max)}',
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                        SizedBox(
                          width: 90,
                          child: Text(
                            () {
                              final v = _scoring ? _value(c.id) : c.score;
                              return v == null
                                  ? '—'
                                  : compactNumber(v * c.weight / 100);
                            }(),
                            textAlign: TextAlign.end,
                            style: textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                Divider(height: 1, color: colors.outline),
                Container(
                  color: AppColors.accentBlue.withValues(alpha: 0.05),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Nota resultante',
                          style: textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        _scoring
                            ? (grade == null
                                  ? '—'
                                  : '${grade.toStringAsFixed(2)} / ${compactNumber(_max)}')
                            : (rubric.every((c) => c.score != null)
                                  ? entryGradeLabel(detail.evaluation)
                                  : 'Sin calificar con la rúbrica'),
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Left: the rubric itself; right: scoring.
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    onPressed: _scoring
                        ? null
                        : () => showDesktopDialog<void>(
                            context,
                            child: RubricForm(detail: detail),
                          ),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Editar criterios'),
                  ),
                  TextButton.icon(
                    onPressed: _scoring
                        ? null
                        : () => GradebookActions.deleteRubric(context, detail),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Quitar rúbrica'),
                    style: TextButton.styleFrom(foregroundColor: colors.error),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_scoring) ...[
                    TextButton(
                      onPressed: _saving
                          ? null
                          : () => setState(() {
                              _scoring = false;
                              for (final c in rubric) {
                                _fields[c.id]!.text = c.score == null
                                    ? ''
                                    : compactNumber(c.score!);
                              }
                            }),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    AppButton(
                      label: 'Guardar nota',
                      isLoading: _saving,
                      onPressed: _save,
                    ),
                  ] else
                    AppButton(
                      label: rubric.every((c) => c.score != null)
                          ? 'Recalificar'
                          : 'Calificar',
                      icon: Icons.edit_note,
                      onPressed: () => setState(() => _scoring = true),
                    ),
                ],
              ),
            ],
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
    return DesktopSectionCard(
      icon: Icons.fact_check_outlined,
      title: 'Hoja de respuestas',
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                submission == null
                    ? 'Este estudiante aún no tiene hoja escaneada. La nota se registra al '
                          'escanear o subir el PDF del examen.'
                    : 'La nota sale de la hoja escaneada; ábrela para ver cada respuesta o '
                          'corregir una detección.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(width: 16),
            AppButton(
              label: submission == null ? 'Abrir el examen' : 'Ver hoja',
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
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard();

  @override
  Widget build(BuildContext context) {
    return DesktopSectionCard(
      icon: Icons.event_available_outlined,
      title: 'Asistencia',
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Text(
          'Presente cuenta el puntaje completo; ausente, cero; con excusa no cuenta. '
          'Se cambia al tomar asistencia.',
          style: Theme.of(context).textTheme.bodySmall,
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

    return DesktopSectionCard(
      icon: Icons.chat_bubble_outline,
      title: 'Comentario del docente',
      linkLabel: canEdit ? 'Editar nota' : null,
      onLink: canEdit
          ? () => showDesktopDialog<void>(
              context,
              child: GradeEditForm(detail: detail),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
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
            if (e.gradedAt != null) ...[
              const SizedBox(height: 6),
              Text(
                'Calificado el ${Formatters.date(e.gradedAt!)}',
                style: textTheme.bodySmall?.copyWith(fontSize: 11),
              ),
            ],
          ],
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

    return DesktopSectionCard(
      icon: Icons.attach_file,
      title: 'Archivo adjunto',
      subtitle: 'opcional',
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: attachment == null
            ? DesktopUploadZone(
                title: 'Arrastra el trabajo aquí',
                subtitle:
                    'o haz clic para elegirlo · PDF, Word, Excel, PowerPoint o imagen, máx. 10 MB',
                allowedExtensions: GradebookActions.attachmentExtensions,
                onFilePicked: (file) =>
                    GradebookActions.upload(context, detail, file),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
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
                                [
                                  Formatters.fileSize(attachment.sizeBytes),
                                  if (attachment.updatedAt != null)
                                    Formatters.date(attachment.updatedAt!),
                                ].join('  ·  '),
                                style: textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Descargar',
                          onPressed: () =>
                              GradebookActions.download(context, detail),
                          icon: const Icon(Icons.download_outlined),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          final file = await pickSingleFile(
                            allowedExtensions:
                                GradebookActions.attachmentExtensions,
                          );
                          if (file != null && context.mounted) {
                            await GradebookActions.upload(
                              context,
                              detail,
                              file,
                            );
                          }
                        },
                        icon: const Icon(Icons.swap_horiz, size: 18),
                        label: const Text('Reemplazar'),
                      ),

                      TextButton.icon(
                        onPressed: () =>
                            GradebookActions.deleteAttachment(context, detail),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Quitar'),
                        style: TextButton.styleFrom(
                          foregroundColor: colors.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

class _FactsCard extends StatelessWidget {
  const _FactsCard({required this.detail});

  final GradeDetailEntity detail;

  @override
  Widget build(BuildContext context) {
    final e = detail.evaluation;
    final textTheme = Theme.of(context).textTheme;

    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(label, style: textTheme.bodySmall),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );

    return DesktopSectionCard(
      icon: Icons.info_outline,
      title: 'Evaluación',
      linkLabel: switch (e.type) {
        EvaluationType.exam => 'Abrir examen',
        EvaluationType.activity => 'Abrir actividad',
        EvaluationType.attendance => 'Asistencia',
      },
      onLink: () => context.push(switch (e.type) {
        EvaluationType.exam => RoutePaths.examDetail(e.examId!),
        EvaluationType.activity => RoutePaths.activityDetail(e.activityId!),
        EvaluationType.attendance => RoutePaths.attendanceForClass(
          detail.teachingPeriodId,
          date: e.evaluationDate,
        ),
      }),
      child: Column(
        children: [
          const SizedBox(height: 8),
          row('Estudiante', detail.student.fullName),
          row('Componente', categoryLabel(e.categoryName)),
          row('Tipo', evaluationKindLabel(e)),
          row(
            'Fecha',
            e.evaluationDate == null
                ? 'Sin fecha'
                : Formatters.date(e.evaluationDate!),
          ),
          row('Puntaje máximo', compactNumber(e.maximumScore)),
          if (e.gradedAt != null)
            row('Calificado el', Formatters.date(e.gradedAt!)),
        ],
      ),
    );
  }
}
