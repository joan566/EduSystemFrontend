import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/state/list_state.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/desktop/desktop_data_table.dart';
import '../../../../core/widgets/desktop/desktop_page_header.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_loading.dart';
import '../../../../core/widgets/shared/app_pagination.dart';
import '../../../teaching/domain/entities/teaching_period_entity.dart';
import '../../../teaching/presentation/shared/teaching_period_selector.dart';
import '../../domain/entities/exam_entity.dart';
import '../providers/exams_provider.dart';
import '../shared/exam_actions.dart';

class ExamsDesktopView extends StatelessWidget {
  const ExamsDesktopView({
    super.key,
    required this.period,
    required this.onPeriodChanged,
  });

  final TeachingPeriodEntity? period;
  final ValueChanged<TeachingPeriodEntity?> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ExamsProvider>().state;
    final period = this.period;

    return Scaffold(
      body: Column(
        children: [
          DesktopPageHeader(
            title: 'Exámenes',
            subtitle: 'Crea y gestiona los exámenes de tus clases.',
            actions: [
              if (period != null)
                AppButton(
                  label: 'Nuevo examen',
                  icon: Icons.add,
                  onPressed: () =>
                      ExamActions.create(context, teachingPeriodId: period.id),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TeachingPeriodSelector(
              value: period,
              onChanged: onPeriodChanged,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: period == null
                ? const SizedBox.shrink()
                : _buildBody(context, state, period),
          ),
          if (period != null && state.status == ViewStatus.success)
            AppPagination(
              page: state.page,
              totalPages: state.totalPages,
              totalElements: state.totalElements,
              onPageChanged: (page) => context.read<ExamsProvider>().load(
                teachingPeriodId: period.id,
                page: page,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ListViewState<ExamSummaryEntity> state,
    TeachingPeriodEntity period,
  ) {
    switch (state.status) {
      case ViewStatus.initial:
      case ViewStatus.loading:
        return const AppLoading();
      case ViewStatus.error:
        return AppErrorState(
          exception: state.error!,
          onRetry: () =>
              context.read<ExamsProvider>().load(teachingPeriodId: period.id),
        );
      case ViewStatus.empty:
        return AppEmptyState(
          title: 'No hay exámenes en esta clase',
          message: 'Crea un examen para empezar a evaluar a tus estudiantes.',
          icon: Icons.fact_check_outlined,
          actionLabel: 'Nuevo examen',
          onAction: () =>
              ExamActions.create(context, teachingPeriodId: period.id),
        );
      case ViewStatus.success:
        return DesktopDataTable<ExamSummaryEntity>(
          items: state.items,
          onRowTap: (item) => context.push(RoutePaths.examDetail(item.id)),
          columns: [
            DesktopDataColumn(
              label: 'Nombre',
              cellBuilder: (item) => Text(item.name),
            ),
            DesktopDataColumn(
              label: 'Fecha',
              cellBuilder: (item) => Text(
                item.evaluationDate == null
                    ? '—'
                    : Formatters.dateTime(item.evaluationDate!),
              ),
            ),
            DesktopDataColumn(
              label: 'Preguntas',
              cellBuilder: (item) => Text('${item.numberOfQuestions}'),
            ),
          ],
        );
    }
  }
}
