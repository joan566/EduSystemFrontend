import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/state/detail_state.dart';
import '../../../../core/widgets/desktop/desktop_data_table.dart';
import '../../../../core/widgets/desktop/desktop_dialog.dart';
import '../../../../core/widgets/desktop/desktop_page_header.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_loading.dart';
import '../../../../core/widgets/shared/app_status_chip.dart';
import '../../domain/entities/exam_entity.dart';
import '../../domain/entities/submission_entity.dart';
import '../providers/exams_provider.dart';
import '../shared/answer_sheets_tab.dart';
import '../shared/exam_actions.dart';
import '../shared/exam_edit_form.dart';
import '../shared/exam_results.dart';
import '../shared/questions_draft_controller.dart';
import 'questions_editor_desktop.dart';

/// Desktop: breadcrumbed header with edit/delete buttons, then the three
/// tabs over the full content width.
class ExamDetailDesktopView extends StatelessWidget {
  const ExamDetailDesktopView({
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
    final name = exam?.name ?? 'Examen';

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DesktopPageHeader(
              title: name,
              breadcrumbs: ['Exámenes', name],
              onBack: () => Navigator.of(context).maybePop(),
              actions: [
                if (exam != null) ...[
                  AppStatusChip(
                    label: exam.ready ? 'Listo para publicar' : 'Incompleto',
                    kind: exam.ready
                        ? AppStatusKind.success
                        : AppStatusKind.warning,
                  ),
                  AppButton(
                    label: 'Editar',
                    icon: Icons.edit_outlined,
                    variant: AppButtonVariant.outlined,
                    onPressed: () => showDesktopDialog<void>(
                      context,
                      child: ExamEditForm(exam: exam),
                    ),
                  ),
                  AppButton(
                    label: 'Eliminar',
                    icon: Icons.delete_outline,
                    variant: AppButtonVariant.outlined,
                    onPressed: () => ExamActions.delete(context, examId),
                  ),
                ],
              ],
            ),
            const TabBar(
              tabs: [
                Tab(text: 'Preguntas'),
                Tab(text: 'Hojas de respuesta'),
                Tab(text: 'Resultados'),
              ],
            ),
            Expanded(child: _buildBody(context, state)),
          ],
        ),
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
        return TabBarView(
          children: [
            questions == null
                ? const AppLoading()
                : QuestionsEditorDesktop(
                    controller: questions,
                    embedded: false,
                    onSave: () => questions.save(context, examId),
                  ),
            AnswerSheetsTab(exam: exam),
            _ResultsTab(exam: exam),
          ],
        );
    }
  }
}

/// Desktop results: actions right-aligned above a submissions table.
class _ResultsTab extends StatelessWidget {
  const _ResultsTab({required this.exam});

  final ExamEntity exam;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Row(
            children: [
              const Spacer(),
              AppButton(
                label: 'Calificar PDF',
                icon: Icons.picture_as_pdf_outlined,
                variant: AppButtonVariant.outlined,
                onPressed: exam.ready
                    ? () => ExamActions.openBatches(context, exam.id)
                    : null,
              ),
              const SizedBox(width: 12),
              AppButton(
                label: 'Escanear hoja',
                icon: Icons.document_scanner_outlined,
                onPressed: exam.ready
                    ? () => ExamActions.openScanning(context, exam.id)
                    : null,
              ),
            ],
          ),
        ),
        Expanded(
          child: ExamResultsStateView(
            exam: exam,
            builder: (context, state) => Column(
              children: [
                Expanded(
                  child: DesktopDataTable<SubmissionSummaryEntity>(
                    items: state.items,
                    onRowTap: (item) => context.push(
                      RoutePaths.submissionDetail(exam.id, item.id),
                    ),
                    columns: [
                      DesktopDataColumn(
                        label: 'Estudiante',
                        cellBuilder: (item) => Text(item.studentName),
                      ),
                      DesktopDataColumn(
                        label: 'Calificación',
                        cellBuilder: (item) =>
                            Text(submissionGradeLabel(item, exam)),
                      ),
                      DesktopDataColumn(
                        label: 'Estado',
                        cellBuilder: (item) =>
                            submissionStatusChip(item.status),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    '${state.totalElements} hojas procesadas',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
