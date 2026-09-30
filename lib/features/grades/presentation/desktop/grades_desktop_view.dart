import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_dropdown.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_search_field.dart';
import '../../../teaching/domain/entities/teaching_period_entity.dart';
import '../../../teaching/presentation/providers/teaching_provider.dart';
import '../../domain/entities/grading_entities.dart';
import '../providers/grading_provider.dart';
import '../shared/class_grades.dart';
import '../shared/grade_labels.dart';
import '../shared/grades_navigation.dart';
import '../shared/period_grades_state_view.dart';
import 'widgets/class_grades_summary_desktop.dart';
import 'widgets/grades_table.dart';
import 'widgets/student_grade_preview.dart';

/// Desktop "Calificaciones": class and filters in one toolbar, then a
/// gradebook table (one column per component, the final grade and status)
/// with the selected student's evaluations previewed beside it; or the
/// class summary. Weights are set in Configuración de notas.
class GradesDesktopView extends StatefulWidget {
  const GradesDesktopView({
    super.key,
    required this.period,
    required this.onPeriodChanged,
    required this.tab,
    required this.onTabChanged,
    required this.filters,
    required this.onFiltersChanged,
    required this.selectedStudentId,
    required this.onSelect,
  });

  final TeachingPeriodEntity? period;
  final ValueChanged<TeachingPeriodEntity?> onPeriodChanged;
  final int tab;
  final ValueChanged<int> onTabChanged;
  final GradesListFilters filters;
  final ValueChanged<GradesListFilters> onFiltersChanged;
  final int? selectedStudentId;
  final ValueChanged<int?> onSelect;

  static const _previewMinWidth = 1180.0;
  static const _previewWidth = 380.0;

  @override
  State<GradesDesktopView> createState() => _GradesDesktopViewState();
}

class _GradesDesktopViewState extends State<GradesDesktopView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs =
      TabController(length: 2, vsync: this, initialIndex: widget.tab)
        ..addListener(() {
          if (_tabs.indexIsChanging) return;
          setState(() {});
          if (_tabs.index != widget.tab) widget.onTabChanged(_tabs.index);
        });

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  /// Saving weights there makes these grades stale; they're re-read on
  /// return only then.
  void _configure() {
    final period = widget.period;
    context.push(
      period == null
          ? RoutePaths.gradingSettings
          : RoutePaths.gradingSettingsForClass(period.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final period = widget.period;
    final classes = context.watch<TeachingProvider>().allPeriods;
    final textTheme = Theme.of(context).textTheme;
    final current = period == null
        ? null
        : context.watch<GradingProvider>().periodGrades(period.id).data;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Calificaciones', style: textTheme.headlineLarge),
                      const SizedBox(height: 2),
                      Text(
                        current == null
                            ? 'Las notas de tus estudiantes, clase por clase.'
                            : '${current.students.length} estudiantes  ·  escala '
                                  '${current.scale.name}'
                                  '${current.passingGrade == null ? '' : '  ·  aprueba con ${compactNumber(current.passingGrade!)}'}',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                AppButton(
                  label: 'Configurar pesos',
                  icon: Icons.tune,
                  variant: AppButtonVariant.outlined,
                  onPressed: _configure,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                SizedBox(
                  width: 340,
                  child: AppDropdown<TeachingPeriodEntity>(
                    label: 'Clase',
                    value: classes.where((c) => c.id == period?.id).firstOrNull,
                    items: classes,
                    itemLabel: (c) => c.displayName,
                    onChanged: widget.onPeriodChanged,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: TabBar(
                    controller: _tabs,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelColor: AppColors.textPrimary,
                    indicatorColor: AppColors.accentBlue,
                    indicatorWeight: 3,
                    dividerColor: Colors.transparent,
                    labelStyle: textTheme.labelLarge,
                    tabs: const [
                      Tab(text: 'Estudiantes'),
                      Tab(text: 'Resumen de la clase'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: period == null
                  ? const AppEmptyState(
                      title: 'Selecciona una clase',
                      message:
                          'Elige una clase para ver las notas de sus estudiantes.',
                      icon: Icons.grade_outlined,
                    )
                  : PeriodGradesStateView(
                      teachingPeriodId: period.id,
                      builder: (context, data) => _tabs.index == 1
                          ? ClassGradesSummaryDesktop(data: data)
                          : _StudentsPane(
                              data: data,
                              filters: widget.filters,
                              onFiltersChanged: widget.onFiltersChanged,
                              selectedStudentId: widget.selectedStudentId,
                              onSelect: widget.onSelect,
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentsPane extends StatelessWidget {
  const _StudentsPane({
    required this.data,
    required this.filters,
    required this.onFiltersChanged,
    required this.selectedStudentId,
    required this.onSelect,
  });

  final PeriodGradesEntity data;
  final GradesListFilters filters;
  final ValueChanged<GradesListFilters> onFiltersChanged;
  final int? selectedStudentId;
  final ValueChanged<int?> onSelect;

  @override
  Widget build(BuildContext context) {
    final students = filters.apply(data.students);
    final selected = students
        .where((s) => s.studentId == selectedStudentId)
        .firstOrNull;
    final hasPassing = data.passingGrade != null;

    void open(StudentPeriodGrade s) =>
        openStudentGrades(context, data.teachingPeriodId, s.studentId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 300,
              child: AppSearchField(
                hint: 'Buscar estudiante...',
                initialValue: filters.search,
                onChanged: (search) =>
                    onFiltersChanged(filters.copyWith(search: search)),
              ),
            ),
            SegmentedButton<GradeStatusFilter>(
              showSelectedIcon: false,
              segments: [
                for (final s in GradeStatusFilter.values)
                  if (hasPassing ||
                      s == GradeStatusFilter.all ||
                      s == GradeStatusFilter.ungraded)
                    ButtonSegment(
                      value: s,
                      label: Text(gradeStatusFilterLabel(s)),
                    ),
              ],
              selected: {
                hasPassing ||
                        filters.status == GradeStatusFilter.all ||
                        filters.status == GradeStatusFilter.ungraded
                    ? filters.status
                    : GradeStatusFilter.all,
              },
              onSelectionChanged: (v) =>
                  onFiltersChanged(filters.copyWith(status: v.first)),
            ),
            SizedBox(
              width: 200,
              child: AppDropdown<GradeSort>(
                label: 'Ordenar',
                value: filters.sort,
                items: GradeSort.values,
                itemLabel: gradeSortLabel,
                onChanged: (s) {
                  if (s != null) onFiltersChanged(filters.copyWith(sort: s));
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showPreview =
                  constraints.maxWidth >= GradesDesktopView._previewMinWidth;
              final table = students.isEmpty
                  ? const AppEmptyState(
                      title: 'Sin resultados',
                      message:
                          'Ningún estudiante coincide con la búsqueda o el filtro.',
                      icon: Icons.search_off,
                    )
                  : GradesTable(
                      data: data,
                      students: students,
                      selectedStudentId: selectedStudentId,
                      onSelect: (s) => onSelect(s.studentId),
                      onOpen: open,
                      clickOpens: !showPreview,
                    );
              if (!showPreview) return table;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: table),
                  const SizedBox(width: 20),
                  SizedBox(
                    width: GradesDesktopView._previewWidth,
                    child: StudentGradePreview(
                      key: ValueKey(selected?.studentId),
                      teachingPeriodId: data.teachingPeriodId,
                      student: selected,
                      scale: data.scale,
                      onOpen: selected == null ? null : () => open(selected),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
