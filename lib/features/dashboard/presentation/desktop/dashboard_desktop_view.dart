import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/state/list_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/desktop/desktop_hero_banner.dart';
import '../../../../core/widgets/desktop/desktop_stat_card.dart';
import '../../../../core/widgets/shared/app_card.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_list_tile.dart';
import '../../../audit/presentation/providers/audit_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../courses/presentation/providers/courses_provider.dart';
import '../../../students/presentation/providers/students_provider.dart';
import '../../../teaching/presentation/providers/teaching_provider.dart';
import '../providers/dashboard_provider.dart';
import '../shared/dashboard_error_notice.dart';
import '../shared/dashboard_state.dart';
import '../shared/getting_started_card.dart';

/// Desktop dashboard: hero greeting, KPI row, then classes beside recent
/// activity and the create-exam CTA.
class DashboardDesktopView extends StatelessWidget {
  const DashboardDesktopView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final studentsState = context.watch<StudentsProvider>().state;
    final coursesState = context.watch<CoursesProvider>().state;
    final assignmentsState = context.watch<TeachingProvider>().assignmentsState;
    final isBrandNew = watchIsBrandNewTeacher(context);
    final greeting = greetingForNow();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => context.read<DashboardProvider>().loadAll(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              children: [
                DesktopHeroBanner(
                  eyebrow: isBrandNew ? 'Bienvenido' : 'Bienvenido de nuevo',
                  title: user == null
                      ? greeting
                      : '$greeting, ${user.firstName}',
                  subtitle: isBrandNew
                      ? 'Configuremos tu espacio de trabajo.'
                      : 'Este es el resumen de tu actividad académica.',
                  icon: Icons.school_outlined,
                ),
                const SizedBox(height: 24),
                if (isBrandNew)
                  const GettingStartedCard()
                else ...[
                  _StatsRow(
                    students: studentsState,
                    courses: coursesState,
                    assignments: assignmentsState,
                  ),
                  const SizedBox(height: 24),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _TeachingPeriodsCard()),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            _RecentActivityCard(),
                            SizedBox(height: 16),
                            _CreateExamCta(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.students,
    required this.courses,
    required this.assignments,
  });

  final ListViewState<dynamic> students;
  final ListViewState<dynamic> courses;
  final ListViewState<dynamic> assignments;

  @override
  Widget build(BuildContext context) {
    final cards = [
      DesktopStatCard(
        label: 'Estudiantes',
        value: '${students.totalElements}',
        hasError: students.status == ViewStatus.error,
        icon: Icons.people_alt_outlined,
        accentColor: AppColors.primary,
        onTap: () => context.push(RoutePaths.students),
      ),
      DesktopStatCard(
        label: 'Cursos',
        value: '${courses.totalElements}',
        hasError: courses.status == ViewStatus.error,
        icon: Icons.class_outlined,
        accentColor: AppColors.info,
        onTap: () => context.push(RoutePaths.courses),
      ),
      DesktopStatCard(
        label: 'Clases activas',
        value: '${assignments.totalElements}',
        hasError: assignments.status == ViewStatus.error,
        icon: Icons.groups_outlined,
        accentColor: AppColors.success,
        onTap: () => context.push(RoutePaths.teaching),
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: 16),
          Expanded(child: cards[i]),
        ],
      ],
    );
  }
}

/// Real, honest CTA — links to Exams (which then asks the teacher to pick
/// a class) rather than pretending exam creation can start without one.
/// Deliberately not an [AppCard]: it's a solid accent block, not a neutral
/// content card, the same distinction the reference layout makes.
class _CreateExamCta extends StatelessWidget {
  const _CreateExamCta();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryDarkest,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.push(RoutePaths.exams),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.fact_check_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Crear nuevo examen',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Diseña y programa tus evaluaciones.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeachingPeriodsCard extends StatelessWidget {
  const _TeachingPeriodsCard();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TeachingProvider>().periodsState;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.groups_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tus clases',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton(
                onPressed: () => context.push(RoutePaths.teaching),
                child: const Text('Ver todas'),
              ),
            ],
          ),
          if (state.status == ViewStatus.error)
            DashboardErrorNotice(
              onRetry: () =>
                  context.read<TeachingProvider>().loadPeriods(page: 0),
            )
          else if (state.items.isEmpty)
            const AppEmptyState(
              title: 'Aún no tienes clases',
              message:
                  'Crea una asignación y vincúlala a un periodo académico.',
              icon: Icons.groups_outlined,
            )
          else
            for (final period in state.items.take(5)) ...[
              if (period != state.items.first) const Divider(height: 1),
              AppListTile(
                icon: Icons.menu_book_outlined,
                title: period.subjectName,
                subtitle:
                    '${period.courseLabel} · ${period.academicPeriodName}',
              ),
            ],
        ],
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuditProvider>().state;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.history_outlined, size: 18, color: AppColors.info),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Actividad reciente',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton(
                onPressed: () => context.push(RoutePaths.audit),
                child: const Text('Ver todo'),
              ),
            ],
          ),
          if (state.status == ViewStatus.error)
            DashboardErrorNotice(
              onRetry: () => context.read<AuditProvider>().load(page: 0),
            )
          else if (state.items.isEmpty)
            const AppEmptyState(
              title: 'Sin actividad reciente',
              icon: Icons.history_outlined,
            )
          else
            for (final log in state.items.take(5)) ...[
              if (log != state.items.first) const Divider(height: 1),
              AppListTile(
                icon: log.isSuccess
                    ? Icons.check_circle_outline
                    : Icons.error_outline,
                iconColor: log.isSuccess ? AppColors.success : AppColors.error,
                title: log.entityType,
                subtitle: Formatters.dateTime(log.createdAt),
              ),
            ],
        ],
      ),
    );
  }
}
