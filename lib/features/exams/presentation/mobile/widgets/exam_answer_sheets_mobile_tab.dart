import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/state/list_state.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/mobile/mobile_form.dart';
import '../../../../../core/widgets/shared/app_button.dart';
import '../../../../../core/widgets/shared/app_error_state.dart';
import '../../../../../core/widgets/shared/skeleton/skeleton_blocks.dart';
import '../../../../../core/widgets/shared/tinted_icon.dart';
import '../../../../students/presentation/providers/students_provider.dart';
import '../../../../teaching/domain/entities/teaching_period_entity.dart';
import '../../../domain/entities/exam_entity.dart';
import '../../shared/answer_sheet_preview.dart';
import '../../shared/exam_actions.dart';

/// "Hojas de respuesta": what the sheets are, a preview of one, then the
/// whole class's PDF or a single student's (e.g. a reprint).
class ExamAnswerSheetsMobileTab extends StatefulWidget {
  const ExamAnswerSheetsMobileTab({
    super.key,
    required this.exam,
    required this.period,
  });

  final ExamEntity exam;

  /// The exam's class; null until the classes have loaded.
  final TeachingPeriodEntity? period;

  @override
  State<ExamAnswerSheetsMobileTab> createState() =>
      _ExamAnswerSheetsMobileTabState();
}

class _ExamAnswerSheetsMobileTabState extends State<ExamAnswerSheetsMobileTab> {
  bool _downloading = false;

  Future<void> _downloadAll() async {
    setState(() => _downloading = true);
    await ExamActions.downloadAnswerSheets(context, widget.exam.id);
    if (mounted) setState(() => _downloading = false);
  }

  Future<void> _pickStudent(TeachingPeriodEntity period) async {
    final students = context.read<StudentsProvider>();
    students.ensureGroupRoster(period.groupId);
    final studentId = await showMobileSheet<int>(
      context,
      builder: (_) => _StudentPickerSheet(groupId: period.groupId),
    );
    if (studentId == null || !mounted) return;
    setState(() => _downloading = true);
    await ExamActions.downloadAnswerSheet(context, widget.exam.id, studentId);
    if (mounted) setState(() => _downloading = false);
  }

  @override
  Widget build(BuildContext context) {
    final exam = widget.exam;
    final period = widget.period;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodyMedium?.copyWith(
      color: AppColors.textSecondary,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        if (!exam.ready)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warningBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Completa todas las preguntas antes de generar las hojas.',
                    style: textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.outline),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: AppColors.accentBlue.withValues(alpha: 0.05),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const TintedIcon(
                          icon: Icons.description_outlined,
                          color: AppColors.accentBlue,
                          size: 44,
                          circle: true,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Genera hojas listas para imprimir',
                            style: textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Crea las hojas de respuesta con el formato correcto '
                      'para tus estudiantes. Descárgalas en PDF e '
                      'imprímelas; después podrás escanearlas o subir el PDF '
                      'para calificar.',
                      style: muted,
                    ),
                    if (period != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.people_alt_outlined,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            period.studentCount == 1
                                ? '1 estudiante activo'
                                : '${period.studentCount} estudiantes activos',
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: AnswerSheetPreview(exam: exam, period: period),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppButton(
                      label: 'Generar hojas PDF',
                      icon: Icons.picture_as_pdf_outlined,
                      isLoading: _downloading,
                      expand: true,
                      onPressed: exam.ready ? _downloadAll : null,
                    ),
                    const SizedBox(height: 10),
                    AppButton(
                      label: 'Hoja de un estudiante',
                      icon: Icons.person_outline,
                      variant: AppButtonVariant.outlined,
                      expand: true,
                      onPressed: exam.ready && period != null && !_downloading
                          ? () => _pickStudent(period)
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The class roster; picking a student pops their id.
class _StudentPickerSheet extends StatelessWidget {
  const _StudentPickerSheet({required this.groupId});

  final int groupId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<StudentsProvider>().groupRoster(groupId);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              'Descargar la hoja de...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Flexible(
            child: switch (state.status) {
              ViewStatus.initial ||
              ViewStatus.loading => const SkeletonTileList(
                count: 5,
                leading: SkeletonLeading.circle,
                padding: EdgeInsets.fromLTRB(20, 8, 20, 24),
              ),
              ViewStatus.error => AppErrorState(
                exception: state.error!,
                onRetry: () => context
                    .read<StudentsProvider>()
                    .refreshGroupRoster(groupId),
              ),
              ViewStatus.empty => const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Este curso no tiene estudiantes.'),
              ),
              ViewStatus.success => ListView(
                shrinkWrap: true,
                children: [
                  for (final student in state.items)
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(student.fullName),
                      subtitle: Text(student.studentCode),
                      trailing: const Icon(Icons.download_outlined, size: 20),
                      onTap: () => Navigator.of(context).pop(student.id),
                    ),
                ],
              ),
            },
          ),
        ],
      ),
    );
  }
}
