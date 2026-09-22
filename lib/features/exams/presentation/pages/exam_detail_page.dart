import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/state/detail_state.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../domain/entities/exam_entity.dart';
import '../providers/exams_provider.dart';
import '../widgets/answer_sheets_tab.dart';
import '../widgets/questions_editor.dart';
import '../widgets/results_tab.dart';
import 'exam_edit_dialog.dart';

class ExamDetailPage extends StatefulWidget {
  const ExamDetailPage({super.key, required this.examId});

  final int examId;

  @override
  State<ExamDetailPage> createState() => _ExamDetailPageState();
}

class _ExamDetailPageState extends State<ExamDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<ExamsProvider>().loadDetail(widget.examId),
    );
  }

  Future<void> _delete() async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Eliminar examen',
      message:
          'Esta acción no se puede deshacer. Se perderán las preguntas configuradas.',
      confirmLabel: 'Eliminar',
    );
    if (!confirmed || !mounted) return;
    final error = await context.read<ExamsProvider>().delete(widget.examId);
    if (!mounted) return;
    if (error != null) {
      context.showApiError(error);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ExamsProvider>().detailState;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(state.data?.name ?? 'Examen'),
          actions: state.data == null
              ? null
              : [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => showAppDialog(
                      context,
                      child: ExamEditDialog(exam: state.data!),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: _delete,
                  ),
                ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Preguntas'),
              Tab(text: 'Hojas de respuesta'),
              Tab(text: 'Resultados'),
            ],
          ),
        ),
        body: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(DetailViewState<ExamEntity> state) {
    switch (state.status) {
      case DetailStatus.initial:
      case DetailStatus.loading:
        return const AppLoading();
      case DetailStatus.error:
        return AppErrorState(
          exception: state.error!,
          onRetry: () =>
              context.read<ExamsProvider>().loadDetail(widget.examId),
        );
      case DetailStatus.success:
        final exam = state.data!;
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
                  QuestionsEditor(examId: widget.examId, exam: exam),
                  AnswerSheetsTab(exam: exam),
                  ResultsTab(exam: exam),
                ],
              ),
            ),
          ],
        );
    }
  }
}
