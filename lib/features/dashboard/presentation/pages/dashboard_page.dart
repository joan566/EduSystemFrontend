import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/state/list_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_list_tile.dart';
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

    if (!loaded) return const Scaffold(body: AppLoading());

    final studentsState = context.watch<StudentsProvider>().state;
    final coursesState = context.watch<CoursesProvider>().state;
    final assignmentsState = context.watch<TeachingProvider>().assignmentsState;

    // A teacher is "brand new" only once every relevant source has
    // confirmed empty — not merely unloaded/erroring — so a transient
    // failure never gets mistaken for "you have nothing yet".
    final isBrandNew =
        studentsState.status == ViewStatus.empty &&
        coursesState.status == ViewStatus.empty &&
        assignmentsState.status == ViewStatus.empty;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => context.read<DashboardProvider>().loadAll(),
        child: ListView(
          padding: EdgeInsets.symmetric(
            horizontal: context.isMobile ? 16 : 24,
            vertical: 20,
          ),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting(user?.firstName),
                        style: Theme.of(context).textTheme.displayLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isBrandNew
                            ? 'Bienvenido a EduSistem. Configuremos tu espacio de trabajo.'
                            : 'Este es el resumen de tu actividad académica.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                if (!context.isMobile)
                  IconButton(
                    tooltip: 'Actualizar',
                    onPressed: () => context.read<DashboardProvider>().loadAll(),
                    icon: const Icon(Icons.refresh),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            if (isBrandNew)
              const _GettingStartedCard()
            else ...[
              _StatsRow(
                students: studentsState,
                courses: coursesState,
                assignments: assignmentsState,
              ),
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
          ],
        ),
      ),
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

// ---------------------------------------------------------------------------
// Brand-new account: a single guided checklist instead of stat cards full
// of zeros and two empty-state cards stacked with no shared narrative.
// ---------------------------------------------------------------------------

class _GettingStartedCard extends StatelessWidget {
  const _GettingStartedCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                child: const Icon(
                  Icons.rocket_launch_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Primeros pasos', style: textTheme.titleMedium),
                    const SizedBox(height: 3),
                    Text(
                      'Todavía no tienes cursos, estudiantes ni clases '
                      'registradas. Sigue estos pasos para empezar a '
                      'evaluar.',
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _GettingStartedStep(
            number: 1,
            title: 'Crea tus cursos',
            subtitle: 'Registra los grupos que vas a enseñar (ej. 10-A).',
            actionLabel: 'Ir a Cursos',
            onTap: () => context.push(RoutePaths.courses),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1),
          ),
          _GettingStartedStep(
            number: 2,
            title: 'Agrega tus estudiantes',
            subtitle: 'Registra o importa los estudiantes de cada curso.',
            actionLabel: 'Ir a Estudiantes',
            onTap: () => context.push(RoutePaths.students),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1),
          ),
          _GettingStartedStep(
            number: 3,
            title: 'Crea tus asignaciones de clase',
            subtitle:
                'Vincula una materia, un curso y un periodo para poder '
                'evaluar.',
            actionLabel: 'Ir a Clases',
            onTap: () => context.push(RoutePaths.teaching),
          ),
        ],
      ),
    );
  }
}

class _GettingStartedStep extends StatelessWidget {
  const _GettingStartedStep({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  final int number;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Text('$number', style: textTheme.labelMedium),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(subtitle, style: textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(width: 8),
        TextButton(onPressed: onTap, child: Text(actionLabel)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Established account
// ---------------------------------------------------------------------------

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
      _StatCard(
        label: 'Estudiantes',
        value: students.totalElements,
        hasError: students.status == ViewStatus.error,
        icon: Icons.people_alt_outlined,
      ),
      _StatCard(
        label: 'Cursos',
        value: courses.totalElements,
        hasError: courses.status == ViewStatus.error,
        icon: Icons.class_outlined,
      ),
      _StatCard(
        label: 'Clases activas',
        value: assignments.totalElements,
        hasError: assignments.status == ViewStatus.error,
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
    this.hasError = false,
  });

  final String label;
  final int value;
  final IconData icon;
  final bool hasError;

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasError)
                  Tooltip(
                    message: 'No se pudo cargar este dato.',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('—', style: Theme.of(context).textTheme.displayLarge),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.error_outline,
                          size: 18,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ],
                    ),
                  )
                else
                  Text('$value', style: Theme.of(context).textTheme.displayLarge),
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
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
    final state = context.watch<TeachingProvider>().periodsState;

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
          if (state.status == ViewStatus.error)
            _CardErrorNotice(
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
                subtitle: '${period.courseLabel} · ${period.academicPeriodName}',
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
            _CardErrorNotice(
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

/// Compact inline notice for a dashboard section whose source failed to
/// load — distinct from a genuine empty state, with its own retry (§104:
/// never let a real error read as "there's nothing here").
class _CardErrorNotice extends StatelessWidget {
  const _CardErrorNotice({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 18, color: colors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'No pudimos cargar esta información.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
