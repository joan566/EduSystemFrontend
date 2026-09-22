import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../audit/presentation/providers/audit_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../courses/presentation/providers/courses_provider.dart';
import '../../../students/presentation/providers/students_provider.dart';
import '../../../teaching/presentation/providers/teaching_provider.dart';
import '../providers/dashboard_provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<DashboardProvider>().loadAll(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loaded = context.watch<DashboardProvider>().loaded;
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      body: loaded
          ? RefreshIndicator(
              onRefresh: () => context.read<DashboardProvider>().loadAll(),
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: context.isMobile ? 16 : 24,
                  vertical: 20,
                ),
                children: [
                  Text(
                    _greeting(user?.firstName),
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Este es el resumen de tu actividad académica.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 28),
                  const _StatsRow(),
                  const SizedBox(height: 28),
                  ResponsiveBuilder(
                    mobile: (_) => const Column(
                      children: [
                        _TeachingPeriodsCard(),
                        SizedBox(height: 16),
                        _RecentActivityCard(),
                      ],
                    ),
                    desktop: (_) => const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _TeachingPeriodsCard()),
                        SizedBox(width: 16),
                        Expanded(child: _RecentActivityCard()),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : const AppLoading(),
    );
  }

  String _greeting(String? name) {
    final hour = DateTime.now().hour;
    final base = hour < 12
        ? 'Buenos días'
        : hour < 19
        ? 'Buenas tardes'
        : 'Buenas noches';
    return name == null ? base : '$base, $name';
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    final students = context.watch<StudentsProvider>().state.totalElements;
    final courses = context.watch<CoursesProvider>().state.totalElements;
    final assignments = context
        .watch<TeachingProvider>()
        .assignmentsState
        .totalElements;

    final cards = [
      _StatCard(
        label: 'Estudiantes',
        value: students,
        icon: Icons.people_alt_outlined,
      ),
      _StatCard(label: 'Cursos', value: courses, icon: Icons.class_outlined),
      _StatCard(
        label: 'Clases activas',
        value: assignments,
        icon: Icons.groups_outlined,
      ),
    ];

    if (context.isMobile) {
      return Column(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            cards[i],
          ],
        ],
      );
    }

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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.12),
                  AppColors.primary.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$value', style: Theme.of(context).textTheme.displayLarge),
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeachingPeriodsCard extends StatelessWidget {
  const _TeachingPeriodsCard();

  @override
  Widget build(BuildContext context) {
    final periods = context.watch<TeachingProvider>().periodsState.items;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
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
          if (periods.isEmpty)
            const AppEmptyState(
              title: 'Aún no tienes clases',
              message:
                  'Crea una asignación y vincúlala a un periodo académico.',
              icon: Icons.groups_outlined,
            )
          else
            for (final period in periods.take(5)) ...[
              if (period != periods.first) const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.menu_book_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                title: Text(period.subjectName),
                subtitle: Text(
                  '${period.courseLabel} · ${period.academicPeriodName}',
                ),
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
    final logs = context.watch<AuditProvider>().state.items;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
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
          if (logs.isEmpty)
            const AppEmptyState(
              title: 'Sin actividad reciente',
              icon: Icons.history_outlined,
            )
          else
            for (final log in logs.take(5)) ...[
              if (log != logs.first) const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: log.isSuccess
                        ? AppColors.successBg
                        : AppColors.errorBg,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    log.isSuccess
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                    size: 18,
                    color: log.isSuccess ? AppColors.success : AppColors.error,
                  ),
                ),
                title: Text(log.entityType),
                subtitle: Text(Formatters.dateTime(log.createdAt)),
              ),
            ],
        ],
      ),
    );
  }
}
