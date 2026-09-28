import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/state/list_state.dart';
import '../../../../core/widgets/mobile/mobile_card_list.dart';
import '../../../../core/widgets/mobile/mobile_page_header.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_list_tile.dart';
import '../../../../core/widgets/shared/app_loading.dart';
import '../../../../core/widgets/shared/app_pagination.dart';
import '../../../teaching/domain/entities/teaching_period_entity.dart';
import '../../../teaching/presentation/shared/teaching_period_selector.dart';
import '../../domain/entities/exam_entity.dart';
import '../providers/exams_provider.dart';
import '../shared/exam_actions.dart';

class ExamsMobileView extends StatelessWidget {
  const ExamsMobileView({
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
      floatingActionButton: period == null
          ? null
          : FloatingActionButton(
              onPressed: () =>
                  ExamActions.create(context, teachingPeriodId: period.id),
              child: const Icon(Icons.add),
            ),
      body: Column(
        children: [
          const MobilePageHeader(title: 'Exámenes'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
        return MobileCardList<ExamSummaryEntity>(
          items: state.items,
          footer: AppPagination(
            page: state.page,
            totalPages: state.totalPages,
            totalElements: state.totalElements,
            onPageChanged: (page) => context.read<ExamsProvider>().load(
              teachingPeriodId: period.id,
              page: page,
            ),
          ),
          itemBuilder: (context, item) => AppListTile(
            icon: Icons.fact_check_outlined,
            title: item.name,
            subtitle: '${item.numberOfQuestions} preguntas',
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => context.push(RoutePaths.examDetail(item.id)),
          ),
        );
    }
  }
}
