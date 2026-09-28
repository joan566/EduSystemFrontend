import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/state/list_state.dart';
import '../../../../core/widgets/desktop/desktop_data_table.dart';
import '../../../../core/widgets/desktop/desktop_dialog.dart';
import '../../../../core/widgets/desktop/desktop_page_header.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_dropdown.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_loading.dart';
import '../../../../core/widgets/shared/app_pagination.dart';
import '../../../academic_levels/domain/entities/academic_level_entity.dart';
import '../../../academic_levels/presentation/providers/academic_levels_provider.dart';
import '../../domain/entities/course_entity.dart';
import '../providers/courses_provider.dart';
import '../shared/course_actions.dart';
import '../shared/course_form.dart';

class CoursesDesktopView extends StatelessWidget {
  const CoursesDesktopView({super.key});

  Future<void> _openForm(BuildContext context, {CourseEntity? initial}) async {
    final levels = CourseActions.levelsForForm(context);
    if (levels == null) return;
    final data = await showDesktopDialog<CourseFormResult>(
      context,
      child: CourseForm(initial: initial, levels: levels),
    );
    if (data == null || !context.mounted) return;
    await CourseActions.save(context, initial: initial, data: data);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CoursesProvider>().state;
    final levels = context.watch<AcademicLevelsProvider>().state.items;

    return Scaffold(
      body: Column(
        children: [
          DesktopPageHeader(
            title: 'Cursos',
            subtitle: 'Grupos de estudiantes, por grado y año académico.',
            actions: [
              AppButton(
                label: 'Nuevo curso',
                icon: Icons.add,
                onPressed: () => _openForm(context),
              ),
            ],
          ),
          if (levels.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 220,
                  child: AppDropdown<AcademicLevelEntity?>(
                    label: 'Filtrar por grado',
                    value: null,
                    items: [null, ...levels],
                    itemLabel: (level) => level?.name ?? 'Todos los grados',
                    onChanged: (level) =>
                        CourseActions.filterByLevel(context, level),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(child: _buildBody(context, state)),
          if (state.status == ViewStatus.success)
            AppPagination(
              page: state.page,
              totalPages: state.totalPages,
              totalElements: state.totalElements,
              onPageChanged: (page) =>
                  context.read<CoursesProvider>().load(page: page),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, ListViewState<CourseEntity> state) {
    switch (state.status) {
      case ViewStatus.initial:
      case ViewStatus.loading:
        return const AppLoading();
      case ViewStatus.error:
        return AppErrorState(
          exception: state.error!,
          onRetry: () => context.read<CoursesProvider>().load(),
        );
      case ViewStatus.empty:
        return AppEmptyState(
          title: 'No hay cursos registrados',
          message: 'Crea un curso para empezar a matricular estudiantes.',
          icon: Icons.class_outlined,
          actionLabel: 'Nuevo curso',
          onAction: () => _openForm(context),
        );
      case ViewStatus.success:
        return DesktopDataTable<CourseEntity>(
          items: state.items,
          onRowTap: (item) => _openForm(context, initial: item),
          columns: [
            DesktopDataColumn(
              label: 'Grado',
              cellBuilder: (item) => Text(item.gradeName),
            ),
            DesktopDataColumn(
              label: 'Curso',
              cellBuilder: (item) => Text(item.name),
            ),
            DesktopDataColumn(
              label: 'Año académico',
              cellBuilder: (item) => Text('${item.academicYear}'),
            ),
            DesktopDataColumn(
              label: 'Acciones',
              cellBuilder: (item) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: () => _openForm(context, initial: item),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: () => CourseActions.delete(context, item),
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }
}
