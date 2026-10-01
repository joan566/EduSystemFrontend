import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/state/detail_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/desktop/desktop_dialog.dart';
import '../../../../core/widgets/desktop/desktop_skeletons.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_status_chip.dart';
import '../../../../core/widgets/shared/skeleton/skeleton_blocks.dart';
import '../../../../core/widgets/shared/tinted_icon.dart';
import '../../../teaching/domain/entities/teaching_period_entity.dart';
import '../../../teaching/presentation/providers/teaching_provider.dart';
import '../../domain/entities/exam_entity.dart';
import '../providers/exams_provider.dart';
import '../shared/exam_actions.dart';
import '../shared/exam_edit_form.dart';
import '../shared/questions_draft_controller.dart';
import 'questions_editor_desktop.dart';
import 'widgets/exam_answer_sheets_desktop_tab.dart';
import 'widgets/exam_results_desktop_tab.dart';

/// Desktop exam workspace: breadcrumb line with the actions, the exam's
/// title and facts, then Preguntas / Hojas de respuesta / Resultados over
/// the full width. Each tab is a desktop tool of its own (navigator +
/// editor, preview + roster, KPIs + sortable table + distribution).
class ExamDetailDesktopView extends StatefulWidget {
  const ExamDetailDesktopView({
    super.key,
    required this.examId,
    required this.questions,
    required this.tab,
    required this.onTabChanged,
  });

  final int examId;
  final QuestionsDraftController? questions;

  /// Selected tab, owned by the page so it survives a layout switch.
  final int tab;
  final ValueChanged<int> onTabChanged;

  @override
  State<ExamDetailDesktopView> createState() => _ExamDetailDesktopViewState();
}

class _ExamDetailDesktopViewState extends State<ExamDetailDesktopView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: 3,
    vsync: this,
    initialIndex: widget.tab,
  )..addListener(_onTabChanged);

  void _onTabChanged() {
    if (!_tabs.indexIsChanging && _tabs.index != widget.tab) {
      widget.onTabChanged(_tabs.index);
    }
  }

  @override
  void didUpdateWidget(covariant ExamDetailDesktopView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tab != _tabs.index) _tabs.animateTo(widget.tab);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ExamsProvider>().detail(widget.examId);
    final exam = state.data;

    return Scaffold(
      body: switch (state.status) {
        DetailStatus.error => AppErrorState(
          exception: state.error!,
          onRetry: () =>
              context.read<ExamsProvider>().refreshDetail(widget.examId),
        ),
        _ when exam == null => const DesktopDetailSkeleton(
          avatar: SkeletonLeading.none,
          actions: 2,
          tabs: 3,
          main: SizedBox(height: 560, child: QuestionsEditorDesktopSkeleton()),
        ),
        _ => _Workspace(
          exam: exam,
          questions: widget.questions,
          tabs: _tabs,
          onGoToTab: (tab) => _tabs.animateTo(tab),
        ),
      },
    );
  }
}

class _Workspace extends StatelessWidget {
  const _Workspace({
    required this.exam,
    required this.questions,
    required this.tabs,
    required this.onGoToTab,
  });

  final ExamEntity exam;
  final QuestionsDraftController? questions;
  final TabController tabs;
  final ValueChanged<int> onGoToTab;

  @override
  Widget build(BuildContext context) {
    final period = context
        .watch<TeachingProvider>()
        .allPeriods
        .where((p) => p.id == exam.teachingPeriodId)
        .firstOrNull;
    final questions = this.questions;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(exam: exam, period: period),
          const SizedBox(height: 16),
          _Tabs(controller: tabs, exam: exam, questions: questions),
          Expanded(
            child: TabBarView(
              controller: tabs,
              // Mouse users switch with the tab bar; a drag would fight
              // text selection in the editor.
              physics: const NeverScrollableScrollPhysics(),
              children: [
                questions == null
                    ? const Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: QuestionsEditorDesktopSkeleton(),
                      )
                    : Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: QuestionsEditorDesktop(
                          controller: questions,
                          embedded: false,
                          onSave: () => questions.save(context, exam.id),
                        ),
                      ),
                ExamAnswerSheetsDesktopTab(
                  exam: exam,
                  period: period,
                  onGoToQuestions: () => onGoToTab(0),
                  onGoToResults: () => onGoToTab(2),
                ),
                ExamResultsDesktopTab(exam: exam, period: period),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.exam, required this.period});

  final ExamEntity exam;
  final TeachingPeriodEntity? period;

  Widget _actions(BuildContext context, {required bool alignEnd}) => Wrap(
    alignment: alignEnd ? WrapAlignment.end : WrapAlignment.start,
    spacing: 10,
    runSpacing: 10,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      AppButton(
        label: 'Editar datos',
        icon: Icons.edit_outlined,
        variant: AppButtonVariant.outlined,
        onPressed: () =>
            showDesktopDialog<void>(context, child: ExamEditForm(exam: exam)),
      ),
      AppButton(
        label: 'Descargar hojas',
        icon: Icons.picture_as_pdf_outlined,
        variant: AppButtonVariant.outlined,
        isLoading: context.watch<ExamsProvider>().isGeneratingSheets(exam.id),
        onPressed: exam.ready
            ? () => ExamActions.downloadAnswerSheets(context, exam.id)
            : null,
      ),
      PopupMenuButton<int>(
        tooltip: 'Más acciones',
        icon: const Icon(Icons.more_horiz),
        onSelected: (value) => switch (value) {
          0 => context.push(
            RoutePaths.teachingPeriodDetail(exam.teachingPeriodId),
          ),
          1 => context.refreshWithNotice(
            () => context.read<ExamsProvider>().refreshDetail(exam.id),
          ),
          _ => ExamActions.delete(context, exam.id),
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 0, child: Text('Ir a la clase')),
          PopupMenuItem(value: 1, child: Text('Actualizar datos')),
          PopupMenuDivider(),
          PopupMenuItem(value: 2, child: Text('Eliminar examen')),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final period = this.period;
    final date = exam.evaluationDate;
    final classLabel = period?.title;
    final facts = [
      ?classLabel,
      date == null ? 'Sin fecha' : Formatters.dateTime(date),
      '${exam.numberOfQuestions} preguntas',
      if (exam.maximumScore != null)
        'Nota máxima ${exam.maximumScore!.toStringAsFixed(1)}',
    ];

    // Wide: actions share the breadcrumb line, the title gets its own.
    // Narrow: actions move below the title.
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => Navigator.of(context).canPop()
                      ? Navigator.of(context).pop()
                      : context.go(RoutePaths.exams),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.arrow_back,
                          size: 16,
                          color: AppColors.accentBlue,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Exámenes',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.accentBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (classLabel != null) ...[
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: textTheme.bodySmall?.color,
                  ),
                  Flexible(
                    child: Text(
                      classLabel,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall,
                    ),
                  ),
                ],
                if (wide) ...[
                  const SizedBox(width: 16),
                  Expanded(flex: 3, child: _actions(context, alignEnd: true)),
                ],
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const TintedIcon(
                  icon: Icons.description_outlined,
                  color: AppColors.accentBlue,
                  size: 56,
                  solid: true,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              exam.name,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.headlineLarge,
                            ),
                          ),
                          const SizedBox(width: 12),
                          AppStatusChip(
                            label: exam.ready ? 'Listo' : 'Incompleto',
                            kind: exam.ready
                                ? AppStatusKind.success
                                : AppStatusKind.warning,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        facts.join('  ·  '),
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!wide) ...[
              const SizedBox(height: 14),
              _actions(context, alignEnd: false),
            ],
          ],
        );
      },
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({
    required this.controller,
    required this.exam,
    required this.questions,
  });

  final TabController controller;
  final ExamEntity exam;
  final QuestionsDraftController? questions;

  @override
  Widget build(BuildContext context) {
    final questions = this.questions;
    final completed = questions?.drafts.where((d) => d.data.isComplete).length;
    final total = questions?.drafts.length ?? exam.numberOfQuestions;

    Widget badge(String text, {Color? color}) => Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        color: (color ?? AppColors.textSecondary).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color ?? AppColors.textSecondary,
        ),
      ),
    );

    return TabBar(
      controller: controller,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      labelColor: AppColors.textPrimary,
      indicatorColor: AppColors.accentBlue,
      indicatorWeight: 3,
      dividerColor: Theme.of(context).colorScheme.outline,
      labelStyle: Theme.of(context).textTheme.labelLarge,
      tabs: [
        Tab(
          child: Row(
            children: [
              const Text('Preguntas'),
              if (completed != null)
                badge(
                  '$completed/$total',
                  color: completed == total
                      ? AppColors.success
                      : AppColors.warning,
                ),
              if (questions?.dirty ?? false)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Tooltip(
                    message: 'Cambios sin guardar',
                    child: Icon(
                      Icons.circle,
                      size: 8,
                      color: AppColors.warning,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Tab(
          child: Row(
            children: [
              const Text('Hojas de respuesta'),
              if (!exam.ready)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(Icons.lock_outline, size: 14),
                ),
            ],
          ),
        ),
        const Tab(text: 'Resultados'),
      ],
    );
  }
}
