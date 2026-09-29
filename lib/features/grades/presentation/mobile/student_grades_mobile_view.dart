import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/state/detail_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/mobile/mobile_form.dart';
import '../../../../core/widgets/mobile/mobile_section_card.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_loading.dart';
import '../../../teaching/presentation/providers/teaching_provider.dart';
import '../../domain/entities/gradebook_entities.dart';
import '../providers/gradebook_provider.dart';
import '../shared/category_visuals.dart';
import '../shared/grade_labels.dart';
import '../shared/grade_ring.dart';
import '../shared/gradebook_forms.dart';
import 'widgets/grade_entry_card.dart';

/// Mobile student grades: name, code and status; the final grade in a
/// ring with points, weight and status; then Detalle de notas (every
/// evaluation, observations) and Información del estudiante.
class StudentGradesMobileView extends StatefulWidget {
  const StudentGradesMobileView({
    super.key,
    required this.teachingPeriodId,
    required this.studentId,
    required this.tab,
    required this.onTabChanged,
    required this.onRefresh,
  });

  final int teachingPeriodId;
  final int studentId;
  final int tab;
  final ValueChanged<int> onTabChanged;
  final Future<void> Function() onRefresh;

  @override
  State<StudentGradesMobileView> createState() =>
      _StudentGradesMobileViewState();
}

class _StudentGradesMobileViewState extends State<StudentGradesMobileView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs =
      TabController(length: 2, vsync: this, initialIndex: widget.tab)
        ..addListener(() {
          if (!_tabs.indexIsChanging && _tabs.index != widget.tab) {
            widget.onTabChanged(_tabs.index);
          }
        });

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _openMore(StudentGradeReport report) async {
    final choice = await showMobileSheet<int>(
      context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_note_outlined),
              title: Text(
                report.observation == null
                    ? 'Agregar observación'
                    : 'Editar observación',
              ),
              onTap: () => Navigator.of(context).pop(0),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Ver ficha del estudiante'),
              onTap: () => Navigator.of(context).pop(1),
            ),
            ListTile(
              leading: const Icon(Icons.tune),
              title: const Text('Configurar pesos de la clase'),
              onTap: () => Navigator.of(context).pop(2),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case 0:
        await showMobileForm<void>(
          context,
          child: ObservationForm(report: report),
        );
      case 1:
        context.push(RoutePaths.studentDetail(report.student.id));
      case 2:
        await context.push(
          RoutePaths.gradingSettingsForClass(report.teachingPeriodId),
        );
        if (mounted) widget.onRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GradebookProvider>().report;
    final report =
        state.data?.student.id == widget.studentId &&
            state.data?.teachingPeriodId == widget.teachingPeriodId
        ? state.data
        : null;

    return Scaffold(
      body: switch (state.status) {
        DetailStatus.error => Column(
          children: [
            const Align(alignment: Alignment.centerLeft, child: BackButton()),
            Expanded(
              child: AppErrorState(
                exception: state.error!,
                onRetry: widget.onRefresh,
              ),
            ),
          ],
        ),
        _ when report == null => const Column(
          children: [
            Align(alignment: Alignment.centerLeft, child: BackButton()),
            Expanded(child: AppLoading()),
          ],
        ),
        _ => _Content(
          report: report,
          tabs: _tabs,
          onMore: () => _openMore(report),
          onRefresh: widget.onRefresh,
        ),
      },
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.report,
    required this.tabs,
    required this.onMore,
    required this.onRefresh,
  });

  final StudentGradeReport report;
  final TabController tabs;
  final VoidCallback onMore;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return NestedScrollView(
      headerSliverBuilder: (context, _) => [
        SliverToBoxAdapter(
          child: _Header(report: report, onMore: onMore),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: _SummaryCard(report: report),
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _TabsHeader(
            TabBar(
              controller: tabs,
              labelColor: AppColors.accentBlue,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.accentBlue,
              indicatorWeight: 3,
              dividerColor: Theme.of(context).colorScheme.outline,
              labelStyle: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: textTheme.labelLarge,
              tabs: const [
                Tab(text: 'Detalle de notas'),
                Tab(text: 'Información del estudiante'),
              ],
            ),
            Theme.of(context).scaffoldBackgroundColor,
          ),
        ),
      ],
      body: TabBarView(
        controller: tabs,
        children: [
          RefreshIndicator(
            onRefresh: onRefresh,
            child: _EvaluationsTab(report: report),
          ),
          _InfoTab(report: report),
        ],
      ),
    );
  }
}

class _TabsHeader extends SliverPersistentHeaderDelegate {
  _TabsHeader(this.tabBar, this.background);

  final TabBar tabBar;
  final Color background;

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => ColoredBox(color: background, child: tabBar);

  @override
  bool shouldRebuild(covariant _TabsHeader oldDelegate) =>
      oldDelegate.tabBar != tabBar;
}

class _Header extends StatelessWidget {
  const _Header({required this.report, required this.onMore});

  final StudentGradeReport report;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final student = report.student;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const BackButton(),
              const Spacer(),
              IconButton(
                tooltip: 'Más opciones',
                onPressed: onMore,
                icon: const Icon(Icons.more_vert),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.accentBlue.withValues(alpha: 0.12),
                  child: Text(
                    student.initials,
                    style: textTheme.titleLarge?.copyWith(
                      color: AppColors.accentBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.fullName,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Código: ${student.studentCode}',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      GradeStatusChip(
                        passing: report.passing,
                        hasGrade: report.periodGrade != null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.report});

  final StudentGradeReport report;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final scale = report.scale;
    final grade = report.periodGrade;
    final score = report.score;

    if (!report.configurationComplete) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.warningBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'La nota final aún no se puede calcular',
              style: textTheme.titleSmall?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              scale == null
                  ? 'Esta clase no tiene pesos de evaluación.'
                  : 'Los pesos de la clase suman ${compactNumber(report.totalWeight)}%, '
                        'deben sumar 100%.',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            AppButton(
              label: 'Configurar pesos',
              icon: Icons.tune,
              variant: AppButtonVariant.outlined,
              onPressed: () => context.push(
                RoutePaths.gradingSettingsForClass(report.teachingPeriodId),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GradeRing(
                value: grade == null ? '—' : grade.toStringAsFixed(2),
                maximum: scale!.maximumValue.toStringAsFixed(2),
                fraction: grade == null ? null : scaleFraction(grade, scale),
                size: 96,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Nota final',
                            style: textTheme.titleMedium,
                          ),
                        ),
                        if (score != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentBlue.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${score.round()}%',
                              style: textTheme.labelMedium?.copyWith(
                                color: AppColors.accentBlue,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.passingGrade == null
                          ? 'Escala ${scale.name}'
                          : 'Aprueba con ${compactNumber(report.passingGrade!)}',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: colors.outline),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              children: [
                _Fact(
                  label: 'Puntaje obtenido',
                  value: score == null ? '—' : '${compactNumber(score)} / 100',
                ),
                VerticalDivider(width: 20, color: colors.outline),
                _Fact(
                  label: 'Ponderación total',
                  value: '${compactNumber(report.totalWeight)}%',
                ),
                VerticalDivider(width: 20, color: colors.outline),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Estado', style: textTheme.bodySmall),
                      const SizedBox(height: 4),
                      report.passing == null
                          ? Text('—', style: textTheme.titleMedium)
                          : FittedBox(
                              child: GradeStatusChip(
                                passing: report.passing,
                                hasGrade: grade != null,
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: textTheme.bodySmall),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EvaluationsTab extends StatelessWidget {
  const _EvaluationsTab({required this.report});

  final StudentGradeReport report;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final observation = report.observation;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text('Actividades y evaluaciones', style: textTheme.titleMedium),
        const SizedBox(height: 10),
        if (report.evaluations.isEmpty)
          const AppEmptyState(
            title: 'Sin evaluaciones',
            message:
                'Esta clase aún no tiene exámenes, actividades ni asistencia.',
            icon: Icons.assignment_outlined,
          ),
        for (final entry in report.evaluations)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GradeEntryCard(
              entry: entry,
              onTap: () => context.push(
                RoutePaths.gradeDetail(
                  report.teachingPeriodId,
                  report.student.id,
                  entry.evaluationId,
                ),
              ),
            ),
          ),
        const SizedBox(height: 6),
        MobileSectionCard(
          icon: Icons.chat_bubble_outline,
          title: 'Observaciones',
          linkLabel: observation == null ? 'Agregar' : 'Editar',
          onLink: () => showMobileForm<void>(
            context,
            child: ObservationForm(report: report),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              observation?.text ??
                  'Sin observaciones sobre este estudiante en la clase.',
              style: textTheme.bodyMedium?.copyWith(
                color: observation == null ? AppColors.textSecondary : null,
              ),
            ),
          ),
        ),
        if (observation?.updatedAt != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              'Actualizada el ${Formatters.date(observation!.updatedAt!)}',
              style: textTheme.bodySmall?.copyWith(fontSize: 11),
            ),
          ),
      ],
    );
  }
}

class _InfoTab extends StatelessWidget {
  const _InfoTab({required this.report});

  final StudentGradeReport report;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final period = context
        .watch<TeachingProvider>()
        .allPeriods
        .where((p) => p.id == report.teachingPeriodId)
        .firstOrNull;
    final scale = report.scale;

    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(child: Text(value, style: textTheme.bodyMedium)),
        ],
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        MobileSectionCard(
          icon: Icons.person_outline,
          title: 'Estudiante',
          linkLabel: 'Ver ficha',
          onLink: () =>
              context.push(RoutePaths.studentDetail(report.student.id)),
          child: Column(
            children: [
              const SizedBox(height: 6),
              row('Nombre', report.student.fullName),
              row('Código', report.student.studentCode),
              if (period != null) ...[
                row('Clase', '${period.subjectName} — ${period.courseLabel}'),
                row('Periodo', period.academicPeriodName),
              ],
              if (scale != null) row('Escala', scale.name),
              if (report.passingGrade != null)
                row('Nota mínima', compactNumber(report.passingGrade!)),
            ],
          ),
        ),
        if (report.categories.isNotEmpty) ...[
          const SizedBox(height: 16),
          MobileSectionCard(
            icon: Icons.donut_small_outlined,
            title: 'Por componente',
            child: Column(
              children: [
                const SizedBox(height: 6),
                for (final c in report.categories)
                  row(
                    '${categoryLabel(c.categoryName)} (${compactNumber(c.weight)}%)',
                    '${periodGradeLabel(c.gradeOnScale, scale)}  ·  '
                        '${c.evaluationCount} evaluaciones',
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
