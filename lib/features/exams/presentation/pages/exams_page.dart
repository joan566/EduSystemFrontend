import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/state/list_state.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_data_table.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_pagination.dart';
import '../../../teaching/domain/entities/teaching_period_entity.dart';
import '../../../teaching/presentation/widgets/teaching_period_selector.dart';
import '../../domain/entities/exam_entity.dart';
import '../providers/exams_provider.dart';

class ExamsPage extends StatefulWidget {
  const ExamsPage({super.key});

  @override
  State<ExamsPage> createState() => _ExamsPageState();
}

class _ExamsPageState extends State<ExamsPage> {
  TeachingPeriodEntity? _period;

  void _onPeriodChanged(TeachingPeriodEntity? period) {
    setState(() => _period = period);
    if (period != null)
      context.read<ExamsProvider>().load(teachingPeriodId: period.id);
  }

  void _createExam() {
    if (_period == null) return;
    context.push('${RoutePaths.examCreate}?teachingPeriodId=${_period!.id}');
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ExamsProvider>().state;

    return Scaffold(
      floatingActionButton: context.isMobile && _period != null
          ? FloatingActionButton(
              onPressed: _createExam,
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          AppPageHeader(
            title: 'Exámenes',
            subtitle: 'Crea y gestiona los exámenes de tus clases.',
            actions: context.isMobile || _period == null
                ? []
                : [
                    AppButton(
                      label: 'Nuevo examen',
                      icon: Icons.add,
                      onPressed: _createExam,
                    ),
                  ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TeachingPeriodSelector(
              value: _period,
              onChanged: _onPeriodChanged,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _period == null
                ? const SizedBox.shrink()
                : _buildBody(state),
          ),
          if (_period != null && state.status == ViewStatus.success)
            AppPagination(
              page: state.page,
              totalPages: state.totalPages,
              totalElements: state.totalElements,
              onPageChanged: (page) => context.read<ExamsProvider>().load(
                teachingPeriodId: _period!.id,
                page: page,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(ListViewState<ExamSummaryEntity> state) {
    switch (state.status) {
      case ViewStatus.initial:
      case ViewStatus.loading:
        return const AppLoading();
      case ViewStatus.error:
        return AppErrorState(
          exception: state.error!,
          onRetry: () =>
              context.read<ExamsProvider>().load(teachingPeriodId: _period!.id),
        );
      case ViewStatus.empty:
        return AppEmptyState(
          title: 'No hay exámenes en esta clase',
          message: 'Crea un examen para empezar a evaluar a tus estudiantes.',
          icon: Icons.fact_check_outlined,
          actionLabel: 'Nuevo examen',
          onAction: _createExam,
        );
      case ViewStatus.success:
        return AppDataTable<ExamSummaryEntity>(
          isMobile: context.isMobile,
          items: state.items,
          onRowTap: (item) => context.push(RoutePaths.examDetail(item.id)),
          mobileCardBuilder: (context, item) => AppListTile(
            icon: Icons.fact_check_outlined,
            title: item.name,
            subtitle: '${item.numberOfQuestions} preguntas',
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => context.push(RoutePaths.examDetail(item.id)),
          ),
          columns: [
            AppDataColumn(
              label: 'Nombre',
              cellBuilder: (item) => Text(item.name),
            ),
            AppDataColumn(
              label: 'Fecha',
              cellBuilder: (item) => Text(
                item.evaluationDate == null
                    ? '—'
                    : Formatters.dateTime(item.evaluationDate!),
              ),
            ),
            AppDataColumn(
              label: 'Preguntas',
              cellBuilder: (item) => Text('${item.numberOfQuestions}'),
            ),
          ],
        );
    }
  }
}
