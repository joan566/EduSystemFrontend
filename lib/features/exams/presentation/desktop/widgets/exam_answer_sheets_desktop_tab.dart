import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/state/list_state.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/desktop/desktop_section_card.dart';
import '../../../../../core/widgets/shared/app_button.dart';
import '../../../../../core/widgets/shared/app_error_state.dart';
import '../../../../../core/widgets/shared/app_loading.dart';
import '../../../../../core/widgets/shared/app_search_field.dart';
import '../../../../students/domain/entities/student_entity.dart';
import '../../../../students/presentation/providers/students_provider.dart';
import '../../../../teaching/domain/entities/teaching_period_entity.dart';
import '../../../../teaching/presentation/shared/class_lookup.dart';
import '../../../domain/entities/exam_entity.dart';
import '../../shared/answer_sheet_preview.dart';
import '../../shared/exam_actions.dart';

/// "Hojas de respuesta" on desktop: a large preview of the sheet and how
/// the flow works on the left; on the right, the whole class's PDF and a
/// searchable roster to download any single student's sheet.
class ExamAnswerSheetsDesktopTab extends StatefulWidget {
  const ExamAnswerSheetsDesktopTab({
    super.key,
    required this.exam,
    required this.period,
    required this.onGoToQuestions,
    required this.onGoToResults,
  });

  final ExamEntity exam;

  /// The exam's class; null until the classes have loaded.
  final TeachingPeriodEntity? period;
  final VoidCallback onGoToQuestions;
  final VoidCallback onGoToResults;

  @override
  State<ExamAnswerSheetsDesktopTab> createState() =>
      _ExamAnswerSheetsDesktopTabState();
}

class _ExamAnswerSheetsDesktopTabState
    extends State<ExamAnswerSheetsDesktopTab> {
  static const _sideWidth = 400.0;
  static const _sideBesideMinWidth = 980.0;

  bool _downloadingAll = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRoster());
  }

  @override
  void didUpdateWidget(covariant ExamAnswerSheetsDesktopTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period?.groupId != widget.period?.groupId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadRoster());
    }
  }

  void _loadRoster() {
    final period = widget.period;
    if (!mounted || period == null) return;
    final students = context.read<StudentsProvider>();
    students.ensureGroupRoster(period.groupId);
  }

  Future<void> _downloadAll() async {
    setState(() => _downloadingAll = true);
    await ExamActions.downloadAnswerSheets(context, widget.exam.id);
    if (mounted) setState(() => _downloadingAll = false);
  }

  @override
  Widget build(BuildContext context) {
    final exam = widget.exam;

    final preview = DesktopSectionCard(
      icon: Icons.description_outlined,
      title: 'Vista previa',
      subtitle: 'una hoja por estudiante activo',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: AnswerSheetPreview(
                exam: exam,
                period: widget.period,
                width: 340,
                maxRows: 12,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _HowItWorks(onGoToResults: widget.onGoToResults),
        ],
      ),
    );

    final side = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WholeClassCard(
          exam: exam,
          period: widget.period,
          downloading: _downloadingAll,
          onDownload: _downloadAll,
        ),
        const SizedBox(height: 20),
        _PerStudentCard(exam: exam, period: widget.period),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final beside = constraints.maxWidth >= _sideBesideMinWidth;
        return ListView(
          padding: const EdgeInsets.only(top: 20, bottom: 24),
          children: [
            if (!exam.ready) ...[
              _NotReadyBanner(onGoToQuestions: widget.onGoToQuestions),
              const SizedBox(height: 20),
            ],
            if (beside)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: preview),
                  const SizedBox(width: 20),
                  SizedBox(width: _sideWidth, child: side),
                ],
              )
            else ...[
              side,
              const SizedBox(height: 20),
              preview,
            ],
          ],
        );
      },
    );
  }
}

class _NotReadyBanner extends StatelessWidget {
  const _NotReadyBanner({required this.onGoToQuestions});

  final VoidCallback onGoToQuestions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Completa todas las preguntas antes de generar las hojas de '
              'respuesta.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
            ),
          ),
          TextButton(
            onPressed: onGoToQuestions,
            style: TextButton.styleFrom(foregroundColor: AppColors.warning),
            child: const Text('Ir a Preguntas'),
          ),
        ],
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks({required this.onGoToResults});

  final VoidCallback onGoToResults;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    const steps = [
      (
        Icons.print_outlined,
        'Genera e imprime',
        'Descarga el PDF y imprime una hoja para cada estudiante.',
      ),
      (
        Icons.edit_outlined,
        'Los estudiantes responden',
        'Rellenan una burbuja por pregunta.',
      ),
      (
        Icons.document_scanner_outlined,
        'Califica',
        'Escanea las hojas o sube el PDF escaneado desde Resultados.',
      ),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, (icon, title, detail)) in steps.indexed) ...[
          if (i > 0) const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.accentBlue.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${i + 1}',
                        style: textTheme.labelMedium?.copyWith(
                          color: AppColors.accentBlue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(icon, size: 18, color: AppColors.textSecondary),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(detail, style: textTheme.bodySmall),
                if (i == steps.length - 1)
                  TextButton(
                    onPressed: onGoToResults,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.accentBlue,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Ir a Resultados'),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _WholeClassCard extends StatelessWidget {
  const _WholeClassCard({
    required this.exam,
    required this.period,
    required this.downloading,
    required this.onDownload,
  });

  final ExamEntity exam;
  final TeachingPeriodEntity? period;
  final bool downloading;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final period = this.period;

    return DesktopSectionCard(
      icon: Icons.groups_outlined,
      title: 'Toda la clase',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          Text(
            period == null
                ? 'Un solo PDF con las hojas de todos los estudiantes activos.'
                : 'Un solo PDF con ${period.studentCount} hojas, una por cada '
                      'estudiante activo de ${period.subjectName} — '
                      '${period.courseLabel}.',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Generar hojas PDF',
            icon: Icons.picture_as_pdf_outlined,
            expand: true,
            isLoading: downloading,
            onPressed: exam.ready ? onDownload : null,
          ),
        ],
      ),
    );
  }
}

/// The class roster with a download button per student (e.g. to reprint a
/// lost or damaged sheet).
class _PerStudentCard extends StatefulWidget {
  const _PerStudentCard({required this.exam, required this.period});

  final ExamEntity exam;
  final TeachingPeriodEntity? period;

  @override
  State<_PerStudentCard> createState() => _PerStudentCardState();
}

class _PerStudentCardState extends State<_PerStudentCard> {
  String _search = '';
  final Set<int> _downloading = {};

  Future<void> _download(StudentEntity student) async {
    setState(() => _downloading.add(student.id));
    await ExamActions.downloadAnswerSheet(context, widget.exam.id, student.id);
    if (mounted) setState(() => _downloading.remove(student.id));
  }

  @override
  Widget build(BuildContext context) {
    final period = widget.period;
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final state = period == null
        ? null
        : context.watch<StudentsProvider>().groupRoster(period.groupId);

    Widget body;
    if (period == null || state == null) {
      body = const Padding(padding: EdgeInsets.all(16), child: AppLoading());
    } else {
      switch (state.status) {
        case ViewStatus.initial:
        case ViewStatus.loading:
          body = const Padding(
            padding: EdgeInsets.all(16),
            child: AppLoading(),
          );
        case ViewStatus.error:
          body = AppErrorState(
            exception: state.error!,
            onRetry: () => context.read<StudentsProvider>().refreshGroupRoster(
              period.groupId,
            ),
          );
        case ViewStatus.empty:
          body = Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Este curso no tiene estudiantes.',
              style: textTheme.bodySmall,
            ),
          );
        case ViewStatus.success:
          final students =
              state.items
                  .where(
                    (s) => matchesSearch(_search, [s.fullName, s.studentCode]),
                  )
                  .toList()
                ..sort((a, b) => a.lastName.compareTo(b.lastName));
          body = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (students.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Ningún estudiante coincide con la búsqueda.',
                    style: textTheme.bodySmall,
                  ),
                ),
              for (final (i, student) in students.indexed) ...[
                if (i > 0) Divider(height: 1, color: colors.outline),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyMedium,
                            ),
                            Text(
                              student.studentCode,
                              style: textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _downloading.contains(student.id)
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : IconButton(
                              tooltip:
                                  'Descargar la hoja de '
                                  '${student.fullName}',
                              onPressed: widget.exam.ready
                                  ? () => _download(student)
                                  : null,
                              icon: const Icon(
                                Icons.download_outlined,
                                size: 20,
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ],
          );
      }
    }

    return DesktopSectionCard(
      icon: Icons.person_outline,
      title: 'Por estudiante',
      subtitle: 'para reimprimir una hoja',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          AppSearchField(
            hint: 'Buscar estudiante...',
            onChanged: (value) => setState(() => _search = value),
          ),
          const SizedBox(height: 8),
          body,
        ],
      ),
    );
  }
}
