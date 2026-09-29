import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/mobile/mobile_form.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_search_field.dart';
import '../../../teaching/domain/entities/teaching_period_entity.dart';
import '../../domain/entities/grading_entities.dart';
import '../providers/grading_provider.dart';
import '../shared/class_grades.dart';
import '../shared/grades_navigation.dart';
import '../shared/period_grades_state_view.dart';
import 'widgets/class_grades_summary_mobile.dart';
import 'widgets/class_picker_card.dart';
import 'widgets/student_grade_card.dart';

/// Mobile "Calificaciones": class picker, then Estudiantes (search, status
/// filter, one card per student with the period grade and status) and
/// Resumen de la clase.
class GradesMobileView extends StatefulWidget {
  const GradesMobileView({
    super.key,
    required this.period,
    required this.onPeriodChanged,
    required this.tab,
    required this.onTabChanged,
    required this.filters,
    required this.onFiltersChanged,
  });

  final TeachingPeriodEntity? period;
  final ValueChanged<TeachingPeriodEntity?> onPeriodChanged;
  final int tab;
  final ValueChanged<int> onTabChanged;
  final GradesListFilters filters;
  final ValueChanged<GradesListFilters> onFiltersChanged;

  @override
  State<GradesMobileView> createState() => _GradesMobileViewState();
}

class _GradesMobileViewState extends State<GradesMobileView>
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

  Future<void> _openMore() async {
    final period = widget.period;
    final choice = await showMobileSheet<int>(
      context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.tune),
              title: const Text('Configurar pesos'),
              subtitle: const Text('Escala, nota mínima y componentes'),
              onTap: () => Navigator.of(context).pop(0),
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Actualizar notas'),
              enabled: period != null,
              onTap: () => Navigator.of(context).pop(1),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case 0:
        await context.push(
          period == null
              ? RoutePaths.gradingSettings
              : RoutePaths.gradingSettingsForClass(period.id),
        );
        if (mounted && period != null) {
          context.read<GradingProvider>().loadPeriodGrades(period.id);
        }
      case 1:
        context.read<GradingProvider>().loadPeriodGrades(period!.id);
    }
  }

  Future<void> _openFilter() async {
    final filters = widget.filters;
    final picked = await showMobileSheet<GradesListFilters>(
      context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Text(
                'Estado',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final status in GradeStatusFilter.values)
              ListTile(
                dense: true,
                title: Text(gradeStatusFilterLabel(status)),
                trailing: filters.status == status
                    ? const Icon(Icons.check, color: AppColors.accentBlue)
                    : null,
                onTap: () =>
                    Navigator.of(context).pop(filters.copyWith(status: status)),
              ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
              child: Text(
                'Ordenar',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final sort in GradeSort.values)
              ListTile(
                dense: true,
                title: Text(gradeSortLabel(sort)),
                trailing: filters.sort == sort
                    ? const Icon(Icons.check, color: AppColors.accentBlue)
                    : null,
                onTap: () =>
                    Navigator.of(context).pop(filters.copyWith(sort: sort)),
              ),
          ],
        ),
      ),
    );
    if (picked != null) widget.onFiltersChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final period = widget.period;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
            child: Row(
              children: [
                if (Navigator.of(context).canPop())
                  const BackButton()
                else
                  const SizedBox(width: 12),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Calificaciones',
                    style: textTheme.headlineLarge?.copyWith(fontSize: 26),
                  ),
                ),
                IconButton(
                  tooltip: 'Más opciones',
                  onPressed: _openMore,
                  icon: const Icon(Icons.more_vert),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: ClassPickerCard(
              value: period,
              onChanged: widget.onPeriodChanged,
            ),
          ),
          TabBar(
            controller: _tabs,
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
              Tab(text: 'Estudiantes'),
              Tab(text: 'Resumen de la clase'),
            ],
          ),
          Expanded(
            child: period == null
                ? const AppEmptyState(
                    title: 'Selecciona una clase',
                    message:
                        'Elige una clase arriba para ver las notas de sus estudiantes.',
                    icon: Icons.grade_outlined,
                  )
                : PeriodGradesStateView(
                    teachingPeriodId: period.id,
                    builder: (context, data) => TabBarView(
                      controller: _tabs,
                      children: [
                        _StudentsTab(
                          data: data,
                          filters: widget.filters,
                          onFiltersChanged: widget.onFiltersChanged,
                          onOpenFilter: _openFilter,
                        ),
                        ClassGradesSummaryMobile(data: data),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StudentsTab extends StatelessWidget {
  const _StudentsTab({
    required this.data,
    required this.filters,
    required this.onFiltersChanged,
    required this.onOpenFilter,
  });

  final PeriodGradesEntity data;
  final GradesListFilters filters;
  final ValueChanged<GradesListFilters> onFiltersChanged;
  final VoidCallback onOpenFilter;

  @override
  Widget build(BuildContext context) {
    final students = filters.apply(data.students);
    final filtered =
        filters.status != GradeStatusFilter.all ||
        filters.sort != GradeSort.name;

    return RefreshIndicator(
      onRefresh: () => context.read<GradingProvider>().loadPeriodGrades(
        data.teachingPeriodId,
        silent: true,
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: AppSearchField(
                  hint: 'Buscar estudiante...',
                  initialValue: filters.search,
                  onChanged: (search) =>
                      onFiltersChanged(filters.copyWith(search: search)),
                ),
              ),
              const SizedBox(width: 10),
              Badge(
                isLabelVisible: filtered,
                smallSize: 8,
                backgroundColor: AppColors.accentBlue,
                child: IconButton.outlined(
                  tooltip: 'Filtrar y ordenar',
                  onPressed: onOpenFilter,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.tune),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (students.isEmpty)
            const AppEmptyState(
              title: 'Sin resultados',
              message:
                  'Ningún estudiante coincide con la búsqueda o el filtro.',
              icon: Icons.search_off,
            ),
          for (final student in students)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: StudentGradeCard(
                student: student,
                scale: data.scale,
                onTap: () => openStudentGrades(
                  context,
                  data.teachingPeriodId,
                  student.studentId,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
