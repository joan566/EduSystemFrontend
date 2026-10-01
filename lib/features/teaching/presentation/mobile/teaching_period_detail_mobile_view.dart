import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/state/detail_state.dart';
import '../../../../core/state/list_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/subject_visuals.dart';
import '../../../../core/widgets/mobile/mobile_form.dart';
import '../../../../core/widgets/mobile/mobile_skeletons.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/skeleton/skeleton_blocks.dart';
import '../../../../core/widgets/shared/tinted_icon.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';
import '../../domain/entities/teaching_period_entity.dart';
import '../providers/teaching_provider.dart';
import '../shared/sibling_classes.dart';
import '../shared/teaching_actions.dart';
import 'widgets/class_evaluations_tab.dart';
import 'widgets/class_hero_card.dart';
import 'widgets/class_quick_actions.dart';
import 'widgets/class_schedule_tab.dart';
import 'widgets/class_students_tab.dart';
import 'widgets/class_summary_tab.dart';

/// Mobile class screen: header, hero card, shortcuts, then Resumen /
/// Estudiantes / Clases / Evaluaciones tabs.
class TeachingPeriodDetailMobileView extends StatelessWidget {
  const TeachingPeriodDetailMobileView({
    super.key,
    required this.teachingPeriodId,
    required this.tabController,
    required this.onRefresh,
  });

  final int teachingPeriodId;
  final TabController tabController;

  /// Reloads the class and everything shown about it (pull to refresh).
  final Future<void> Function() onRefresh;

  static const _scheduleTab = 2;

  Future<void> _delete(
    BuildContext context,
    TeachingPeriodEntity period,
  ) async {
    final deleted = await TeachingActions.deletePeriod(context, period);
    if (deleted && context.mounted) Navigator.of(context).maybePop();
  }

  Future<void> _openMore(
    BuildContext context,
    TeachingPeriodEntity period,
  ) async {
    final choice = await showMobileSheet<int>(
      context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.grade_outlined),
              title: const Text('Calificaciones'),
              onTap: () => Navigator.of(context).pop(0),
            ),
            ListTile(
              leading: const Icon(Icons.schedule_outlined),
              title: const Text('Horario de la clase'),
              onTap: () => Navigator.of(context).pop(1),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Mi calendario'),
              onTap: () => Navigator.of(context).pop(2),
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              title: const Text('Eliminar clase'),
              onTap: () => Navigator.of(context).pop(3),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    switch (choice) {
      case 0:
        context.push(RoutePaths.gradesForClass(period.id));
      case 1:
        tabController.animateTo(_scheduleTab);
      case 2:
        context.push(RoutePaths.schedule);
      case 3:
        await _delete(context, period);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TeachingProvider>().periodDetail(
      teachingPeriodId,
    );
    final period = state.data;

    return Scaffold(
      body: switch (state.status) {
        DetailStatus.error => Column(
          children: [
            const _BackOnlyHeader(),
            Expanded(
              child: AppErrorState(
                exception: state.error!,
                onRetry: () => context
                    .read<TeachingProvider>()
                    .refreshPeriodDetail(teachingPeriodId),
              ),
            ),
          ],
        ),
        _ when period == null => const Column(
          children: [
            _BackOnlyHeader(),
            Expanded(
              child: MobileDetailSkeleton(
                avatar: SkeletonLeading.square,
                tabs: 4,
              ),
            ),
          ],
        ),
        _ => RefreshIndicator(
          onRefresh: onRefresh,
          child: _Content(
            period: period,
            tabController: tabController,
            onMore: () => _openMore(context, period),
            onDelete: () => _delete(context, period),
          ),
        ),
      },
    );
  }
}

class _BackOnlyHeader extends StatelessWidget {
  const _BackOnlyHeader();

  @override
  Widget build(BuildContext context) => const Align(
    alignment: Alignment.centerLeft,
    child: Padding(padding: EdgeInsets.all(4), child: BackButton()),
  );
}

class _Content extends StatelessWidget {
  const _Content({
    required this.period,
    required this.tabController,
    required this.onMore,
    required this.onDelete,
  });

  final TeachingPeriodEntity period;
  final TabController tabController;
  final VoidCallback onMore;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final blocks = context.watch<ScheduleProvider>().classSchedules(period.id);
    final textTheme = Theme.of(context).textTheme;

    final tab = switch (tabController.index) {
      1 => ClassStudentsTab(groupId: period.groupId),
      2 => ClassScheduleTab(teachingPeriodId: period.id),
      3 => ClassEvaluationsTab(teachingPeriodId: period.id),
      _ => ClassSummaryTab(
        period: period,
        onOpenSchedule: () => tabController.animateTo(2),
      ),
    };

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // Header: back, subject badge, name and context, overflow menu.
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: Row(
            children: [
              const BackButton(),
              TintedIcon(
                icon: subjectIcon(period.subjectName),
                color: subjectAccent(period.subjectId),
                size: 44,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      period.subjectName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleLarge,
                    ),
                    Text(
                      [
                        period.courseLabel,
                        period.academicPeriodName,
                      ].join('  ·  '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<int>(
                tooltip: 'Más opciones',
                icon: const Icon(Icons.more_vert),
                onSelected: (value) => value == 0 ? onMore() : onDelete(),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 0, child: Text('Más acciones')),
                  PopupMenuItem(value: 1, child: Text('Eliminar clase')),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ClassHeroCard(
            period: period,
            // Weekly blocks; unknown (null) until the schedule loads.
            weeklySessions: switch (blocks.status) {
              ViewStatus.success || ViewStatus.empty => blocks.items.length,
              _ => null,
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: SiblingClassesBar(period: period),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ClassQuickActions(
            actions: [
              ClassQuickAction(
                label: 'Crear examen',
                icon: Icons.description_outlined,
                onTap: () =>
                    context.push(RoutePaths.examCreateForClass(period.id)),
              ),
              ClassQuickAction(
                label: 'Registrar asistencia',
                icon: Icons.how_to_reg_outlined,
                onTap: () =>
                    context.push(RoutePaths.attendanceForClass(period.id)),
              ),
              ClassQuickAction(
                label: 'Nueva actividad',
                icon: Icons.edit_note_outlined,
                onTap: () =>
                    context.push(RoutePaths.activitiesForClass(period.id)),
              ),
              ClassQuickAction(
                label: 'Más',
                icon: Icons.more_horiz,
                onTap: onMore,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TabBar(
          controller: tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppColors.textPrimary,
          indicatorColor: AppColors.accentBlue,
          indicatorWeight: 3,
          dividerColor: Theme.of(context).colorScheme.outline,
          labelStyle: textTheme.labelLarge,
          tabs: const [
            Tab(text: 'Resumen'),
            Tab(text: 'Estudiantes'),
            Tab(text: 'Clases'),
            Tab(text: 'Evaluaciones'),
          ],
        ),
        Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), child: tab),
      ],
    );
  }
}
