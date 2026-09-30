import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/state/detail_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/mobile/mobile_form.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_loading.dart';
import '../../../teaching/presentation/providers/teaching_provider.dart';
import '../../domain/entities/exam_entity.dart';
import '../providers/exams_provider.dart';
import '../shared/exam_actions.dart';
import '../shared/exam_edit_form.dart';
import '../shared/questions_draft_controller.dart';
import 'questions_editor_mobile.dart';
import 'widgets/exam_answer_sheets_mobile_tab.dart';
import 'widgets/exam_info_card.dart';
import 'widgets/exam_results_mobile_tab.dart';

/// Mobile exam screen: back + name + edit/more, a class/date/status card,
/// then Preguntas / Hojas de respuesta / Resultados tabs.
class ExamDetailMobileView extends StatefulWidget {
  const ExamDetailMobileView({
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
  State<ExamDetailMobileView> createState() => _ExamDetailMobileViewState();
}

class _ExamDetailMobileViewState extends State<ExamDetailMobileView>
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
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _edit(ExamEntity exam) =>
      showMobileForm<void>(context, child: ExamEditForm(exam: exam));

  Future<void> _openMore(ExamEntity exam) async {
    final choice = await showMobileSheet<int>(
      context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Editar datos del examen'),
              onTap: () => Navigator.of(context).pop(0),
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              title: const Text('Eliminar examen'),
              onTap: () => Navigator.of(context).pop(1),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case 0:
        _edit(exam);
      case 1:
        await ExamActions.delete(context, exam.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ExamsProvider>().detail(widget.examId);
    final exam = state.data;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
            child: Row(
              children: [
                const BackButton(),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    exam?.name ?? 'Examen',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleLarge,
                  ),
                ),
                if (exam != null) ...[
                  IconButton(
                    tooltip: 'Editar examen',
                    onPressed: () => _edit(exam),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Más opciones',
                    onPressed: () => _openMore(exam),
                    icon: const Icon(Icons.more_vert),
                  ),
                ],
              ],
            ),
          ),
          Expanded(child: _buildBody(context, state, exam)),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    DetailViewState<ExamEntity> state,
    ExamEntity? exam,
  ) {
    if (state.status == DetailStatus.error) {
      return AppErrorState(
        exception: state.error!,
        onRetry: () =>
            context.read<ExamsProvider>().refreshDetail(widget.examId),
      );
    }
    if (exam == null) return const AppLoading();

    final period = context
        .watch<TeachingProvider>()
        .allPeriods
        .where((p) => p.id == exam.teachingPeriodId)
        .firstOrNull;
    final questions = widget.questions;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: ExamInfoCard(exam: exam, period: period),
        ),
        TabBar(
          controller: _tabs,
          labelColor: AppColors.accentBlue,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.accentBlue,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Theme.of(context).colorScheme.outline,
          labelStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: textTheme.labelLarge,
          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
          tabs: const [
            Tab(text: 'Preguntas'),
            Tab(text: 'Hojas de respuesta'),
            Tab(text: 'Resultados'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              questions == null
                  ? const AppLoading()
                  : QuestionsEditorMobile(
                      controller: questions,
                      embedded: false,
                      onSave: () => questions.save(context, exam.id),
                    ),
              ExamAnswerSheetsMobileTab(exam: exam, period: period),
              ExamResultsMobileTab(exam: exam, period: period),
            ],
          ),
        ),
      ],
    );
  }
}
