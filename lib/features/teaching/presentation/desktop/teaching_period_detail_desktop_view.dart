import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/state/detail_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/subject_visuals.dart';
import '../../../../core/widgets/desktop/desktop_skeletons.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_status_chip.dart';
import '../../../../core/widgets/shared/skeleton/skeleton_blocks.dart';
import '../../../../core/widgets/shared/tinted_icon.dart';
import '../../domain/entities/teaching_period_entity.dart';
import '../providers/teaching_provider.dart';
import '../shared/sibling_classes.dart';
import '../shared/class_lookup.dart';
import '../shared/teaching_actions.dart';
import 'widgets/class_detail_rail.dart';
import 'widgets/class_evaluations_table.dart';
import 'widgets/class_overview_tab.dart';
import 'widgets/class_roster_table.dart';
import 'widgets/class_week_grid.dart';

/// Desktop class workspace: breadcrumbed header with the main actions as
/// buttons, a tabbed main column, and a side column (progress, next
/// session, facts) that stays visible whatever tab is open. Below
/// [_railBesideMinWidth] the side cards move above the tabs.
class TeachingPeriodDetailDesktopView extends StatelessWidget {
  const TeachingPeriodDetailDesktopView({
    super.key,
    required this.teachingPeriodId,
    required this.tabController,
    required this.onRefresh,
  });

  final int teachingPeriodId;
  final TabController tabController;
  final Future<void> Function() onRefresh;

  static const _railBesideMinWidth = 1100.0;
  static const _railWidth = 340.0;

  /// Below the side column, width from which its cards fit in one row.
  static const _railRowMinWidth = 880.0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TeachingProvider>().periodDetail(
      teachingPeriodId,
    );
    final period = state.data;

    return Scaffold(
      body: switch (state.status) {
        DetailStatus.error => AppErrorState(
          exception: state.error!,
          onRetry: () => context.read<TeachingProvider>().refreshPeriodDetail(
            teachingPeriodId,
          ),
        ),
        _ when period == null => const DesktopDetailSkeleton(
          avatar: SkeletonLeading.square,
          tabs: 4,
          rail: 3,
          railEnd: true,
        ),
        _ => _Workspace(
          period: period,
          tabController: tabController,
          onRefresh: onRefresh,
        ),
      },
    );
  }
}

class _Workspace extends StatelessWidget {
  const _Workspace({
    required this.period,
    required this.tabController,
    required this.onRefresh,
  });

  final TeachingPeriodEntity period;
  final TabController tabController;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final tab = switch (tabController.index) {
      1 => ClassRosterTable(groupId: period.groupId),
      2 => ClassWeekGrid(period: period),
      3 => ClassEvaluationsTable(teachingPeriodId: period.id),
      _ => ClassOverviewTab(
        teachingPeriodId: period.id,
        onShowEvaluations: () => tabController.animateTo(3),
      ),
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final railBeside =
            constraints.maxWidth >=
            TeachingPeriodDetailDesktopView._railBesideMinWidth;
        final rail = classDetailRailCards(period);

        final main = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!railBeside) ...[
              // Side cards above the tabs when there's no room for a side
              // column: in a row while they fit, stacked below that.
              if (constraints.maxWidth >=
                  TeachingPeriodDetailDesktopView._railRowMinWidth)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (i, card) in rail.indexed) ...[
                        if (i > 0) const SizedBox(width: 16),
                        Expanded(child: card),
                      ],
                    ],
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, card) in rail.indexed) ...[
                      if (i > 0) const SizedBox(height: 16),
                      card,
                    ],
                  ],
                ),
              const SizedBox(height: 20),
            ],
            _Tabs(controller: tabController),
            const SizedBox(height: 20),
            tab,
          ],
        );

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            _Header(period: period, onRefresh: onRefresh),
            const SizedBox(height: 20),
            if (railBeside)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: main),
                  const SizedBox(width: 20),
                  SizedBox(
                    width: TeachingPeriodDetailDesktopView._railWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final (i, card) in rail.indexed) ...[
                          if (i > 0) const SizedBox(height: 16),
                          card,
                        ],
                      ],
                    ),
                  ),
                ],
              )
            else
              main,
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.period, required this.onRefresh});

  final TeachingPeriodEntity period;
  final Future<void> Function() onRefresh;

  Widget _actions(BuildContext context, {required bool alignEnd}) => Wrap(
    alignment: alignEnd ? WrapAlignment.end : WrapAlignment.start,
    spacing: 10,
    runSpacing: 10,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      AppButton(
        label: 'Registrar asistencia',
        icon: Icons.how_to_reg_outlined,
        onPressed: () => context.push(RoutePaths.attendanceForClass(period.id)),
      ),
      AppButton(
        label: 'Crear examen',
        icon: Icons.description_outlined,
        variant: AppButtonVariant.outlined,
        onPressed: () => context.push(RoutePaths.examCreateForClass(period.id)),
      ),
      AppButton(
        label: 'Nueva actividad',
        icon: Icons.edit_note_outlined,
        variant: AppButtonVariant.outlined,
        onPressed: () => context.push(RoutePaths.activitiesForClass(period.id)),
      ),
      PopupMenuButton<int>(
        tooltip: 'Más acciones',
        icon: const Icon(Icons.more_horiz),
        onSelected: (value) => switch (value) {
          0 => context.push(RoutePaths.gradesForClass(period.id)),
          1 => context.push(RoutePaths.schedule),
          2 => onRefresh(),
          _ => _delete(context),
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 0, child: Text('Calificaciones')),
          PopupMenuItem(value: 1, child: Text('Mi calendario')),
          PopupMenuItem(value: 2, child: Text('Actualizar datos')),
          PopupMenuDivider(),
          PopupMenuItem(value: 3, child: Text('Eliminar clase')),
        ],
      ),
    ],
  );

  Future<void> _delete(BuildContext context) async {
    final deleted = await TeachingActions.deletePeriod(context, period);
    if (deleted && context.mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final (statusLabel, statusKind) = switch (classPeriodStatus(
      period,
      DateTime.now(),
    )) {
      ClassPeriodStatus.active => ('Clase activa', AppStatusKind.success),
      ClassPeriodStatus.upcoming => ('Próxima a iniciar', AppStatusKind.info),
      ClassPeriodStatus.finished => ('Finalizada', AppStatusKind.neutral),
    };

    // Wide: actions share the breadcrumb line, the title gets its own.
    // Narrow: actions move below the title.
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumbs.
            Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => Navigator.of(context).canPop()
                      ? Navigator.of(context).pop()
                      : context.go(RoutePaths.teaching),
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
                          'Clases',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.accentBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: textTheme.bodySmall?.color,
                ),
                Flexible(
                  child: Text(
                    '${period.courseLabel}  ›  ${period.subjectName}',
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall,
                  ),
                ),
                if (wide) ...[
                  const SizedBox(width: 16),
                  Expanded(flex: 3, child: _actions(context, alignEnd: true)),
                ],
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                TintedIcon(
                  icon: subjectIcon(period.subjectName),
                  color: subjectAccent(period.subjectId),
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
                              period.subjectName,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.headlineLarge,
                            ),
                          ),
                          const SizedBox(width: 12),
                          AppStatusChip(label: statusLabel, kind: statusKind),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${period.courseLabel}  ·  '
                        '${period.academicPeriodName}  ·  '
                        '${period.studentCount} alumnos',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SiblingClassesBar(period: period),
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
  const _Tabs({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      labelColor: AppColors.textPrimary,
      indicatorColor: AppColors.accentBlue,
      indicatorWeight: 3,
      dividerColor: Theme.of(context).colorScheme.outline,
      labelStyle: Theme.of(context).textTheme.labelLarge,
      tabs: const [
        Tab(text: 'Resumen'),
        Tab(text: 'Estudiantes'),
        Tab(text: 'Horario'),
        Tab(text: 'Evaluaciones'),
      ],
    );
  }
}
