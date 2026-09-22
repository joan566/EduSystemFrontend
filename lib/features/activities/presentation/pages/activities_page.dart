import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/state/list_state.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_data_table.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../teaching/domain/entities/teaching_period_entity.dart';
import '../../../teaching/presentation/widgets/teaching_period_selector.dart';
import '../../domain/entities/activity_entity.dart';
import '../providers/activities_provider.dart';
import '../widgets/activity_form.dart';

class ActivitiesPage extends StatefulWidget {
  const ActivitiesPage({super.key});

  @override
  State<ActivitiesPage> createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends State<ActivitiesPage> {
  TeachingPeriodEntity? _period;

  void _onPeriodChanged(TeachingPeriodEntity? period) {
    setState(() => _period = period);
    if (period != null)
      context.read<ActivitiesProvider>().load(teachingPeriodId: period.id);
  }

  Future<void> _createActivity() async {
    if (_period == null) return;
    final result = await showAppDialog(context, child: const ActivityForm());
    if (result == null) return;
    final data =
        result as ({String name, String activityType, double maximumScore});
    final activity = await context.read<ActivitiesProvider>().create(
      teachingPeriodId: _period!.id,
      name: data.name,
      activityType: data.activityType.isEmpty ? null : data.activityType,
      maximumScore: data.maximumScore,
    );
    if (!mounted) return;
    if (activity == null) {
      final error = context.read<ActivitiesProvider>().lastError;
      if (error != null) context.showApiError(error);
    } else {
      context.showSuccess('Actividad creada.');
      context.push(RoutePaths.activityDetail(activity.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ActivitiesProvider>().state;

    return Scaffold(
      floatingActionButton: context.isMobile && _period != null
          ? FloatingActionButton(
              onPressed: _createActivity,
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          AppPageHeader(
            title: 'Actividades',
            subtitle: 'Talleres, proyectos y demás actividades evaluables.',
            actions: context.isMobile || _period == null
                ? []
                : [
                    AppButton(
                      label: 'Nueva actividad',
                      icon: Icons.add,
                      onPressed: _createActivity,
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
        ],
      ),
    );
  }

  Widget _buildBody(ListViewState<ActivityEntity> state) {
    switch (state.status) {
      case ViewStatus.initial:
      case ViewStatus.loading:
        return const AppLoading();
      case ViewStatus.error:
        return AppErrorState(
          exception: state.error!,
          onRetry: () => context.read<ActivitiesProvider>().load(
            teachingPeriodId: _period!.id,
          ),
        );
      case ViewStatus.empty:
        return AppEmptyState(
          title: 'No hay actividades en esta clase',
          message:
              'Crea una actividad para empezar a registrar calificaciones.',
          icon: Icons.assignment_outlined,
          actionLabel: 'Nueva actividad',
          onAction: _createActivity,
        );
      case ViewStatus.success:
        return AppDataTable<ActivityEntity>(
          isMobile: context.isMobile,
          items: state.items,
          onRowTap: (item) => context.push(RoutePaths.activityDetail(item.id)),
          mobileCardBuilder: (context, item) => AppListTile(
            icon: Icons.assignment_outlined,
            title: item.name,
            subtitle: item.activityType ?? 'Actividad',
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => context.push(RoutePaths.activityDetail(item.id)),
          ),
          columns: [
            AppDataColumn(
              label: 'Nombre',
              cellBuilder: (item) => Text(item.name),
            ),
            AppDataColumn(
              label: 'Tipo',
              cellBuilder: (item) => Text(item.activityType ?? '—'),
            ),
            AppDataColumn(
              label: 'Puntaje máx.',
              cellBuilder: (item) => Text(item.maximumScore.toStringAsFixed(2)),
            ),
            AppDataColumn(
              label: 'Fecha',
              cellBuilder: (item) => Text(
                item.evaluationDate == null
                    ? '—'
                    : Formatters.date(item.evaluationDate!),
              ),
            ),
          ],
        );
    }
  }
}
