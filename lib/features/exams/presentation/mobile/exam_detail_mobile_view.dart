import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/state/detail_state.dart';
import '../../../../core/widgets/mobile/mobile_card_list.dart';
import '../../../../core/widgets/mobile/mobile_form.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_list_tile.dart';
import '../../../../core/widgets/shared/app_loading.dart';
import '../../../../core/widgets/shared/app_status_chip.dart';
import '../../domain/entities/exam_entity.dart';
import '../providers/exams_provider.dart';
import '../shared/answer_sheets_tab.dart';
import '../shared/exam_actions.dart';
import '../shared/exam_edit_form.dart';
import '../shared/exam_results.dart';
import '../shared/questions_draft_controller.dart';
import 'questions_editor_mobile.dart';

class ExamDetailMobileView extends StatelessWidget {
  const ExamDetailMobileView({
    super.key,
    required this.examId,
    required this.questions,
  });

  final int examId;
  final QuestionsDraftController? questions;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ExamsProvider>().detailState;
    final exam = state.data;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(exam?.name ?? 'Examen'),
          actions: exam == null
              ? null
              : [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => showMobileForm<void>(
                      context,
                      child: ExamEditForm(exam: exam),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => ExamActions.delete(context, examId),
                  ),
                ],
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Preguntas'),
              Tab(text: 'Hojas de respuesta'),
              Tab(text: 'Resultados'),
            ],
          ),
        ),
        body: _buildBody(context, state),
      ),
    );
  }

  Widget _buildBody(BuildContext context, DetailViewState<ExamEntity> state) {
    switch (state.status) {
      case DetailStatus.initial:
      case DetailStatus.loading:
        return const AppLoading();
      case DetailStatus.error:
        return AppErrorState(
          exception: state.error!,
          onRetry: () => context.read<ExamsProvider>().loadDetail(examId),
        );
      case DetailStatus.success:
        final exam = state.data!;
        final questions = this.questions;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  AppStatusChip(
                    label: exam.ready ? 'Listo para publicar' : 'Incompleto',
                    kind: exam.ready
                        ? AppStatusKind.success
                        : AppStatusKind.warning,
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  questions == null
                      ? const AppLoading()
                      : QuestionsEditorMobile(
                          controller: questions,
                          embedded: false,
                          onSave: () => questions.save(context, examId),
                        ),
                  AnswerSheetsTab(exam: exam),
                  _ResultsTab(exam: exam),
                ],
              ),
            ),
          ],
        );
    }
  }
}

/// Mobile results: both entry points as full-width buttons, then a card
/// per submission.
class _ResultsTab extends StatelessWidget {
  const _ResultsTab({required this.exam});

  final ExamEntity exam;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Calificar PDF',
                  icon: Icons.picture_as_pdf_outlined,
                  variant: AppButtonVariant.outlined,
                  onPressed: exam.ready
                      ? () => ExamActions.openBatches(context, exam.id)
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton(
                  label: 'Escanear',
                  icon: Icons.document_scanner_outlined,
                  onPressed: exam.ready
                      ? () => ExamActions.openScanning(context, exam.id)
                      : null,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ExamResultsStateView(
            exam: exam,
            builder: (context, state) => MobileCardList(
              items: state.items,
              footer: Center(
                child: Text(
                  '${state.totalElements} hojas procesadas',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              itemBuilder: (context, item) => AppListTile(
                icon: Icons.fact_check_outlined,
                title: item.studentName,
                subtitle: item.finalGrade != null && exam.maximumScore != null
                    ? submissionGradeLabel(item, exam)
                    : item.statusDetail ?? '',
                trailing: submissionStatusChip(item.status),
                onTap: () =>
                    context.push(RoutePaths.submissionDetail(exam.id, item.id)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
