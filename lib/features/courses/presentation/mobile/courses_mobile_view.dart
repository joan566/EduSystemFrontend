import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/state/list_state.dart';
import '../../../../core/widgets/mobile/mobile_card_list.dart';
import '../../../../core/widgets/mobile/mobile_form.dart';
import '../../../../core/widgets/mobile/mobile_page_header.dart';
import '../../../../core/widgets/shared/app_dropdown.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_list_tile.dart';
import '../../../../core/widgets/shared/app_loading.dart';
import '../../../../core/widgets/shared/app_pagination.dart';
import '../../../academic_levels/domain/entities/academic_level_entity.dart';
import '../../../academic_levels/presentation/providers/academic_levels_provider.dart';
import '../../domain/entities/course_entity.dart';
import '../providers/courses_provider.dart';
import '../shared/course_actions.dart';
import '../shared/course_form.dart';

class CoursesMobileView extends StatelessWidget {
  const CoursesMobileView({super.key});

  Future<void> _openForm(BuildContext context, {CourseEntity? initial}) async {
    final levels = CourseActions.levelsForForm(context);
    if (levels == null) return;
    final data = await showMobileForm<CourseFormResult>(
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          const MobilePageHeader(title: 'Cursos'),
          if (levels.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppDropdown<AcademicLevelEntity?>(
                label: 'Filtrar por grado',
                value: null,
                items: [null, ...levels],
                itemLabel: (level) => level?.name ?? 'Todos los grados',
                onChanged: (level) =>
                    CourseActions.filterByLevel(context, level),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(child: _buildBody(context, state)),
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
        return MobileCardList<CourseEntity>(
          items: state.items,
          footer: AppPagination(
            page: state.page,
            totalPages: state.totalPages,
            totalElements: state.totalElements,
            onPageChanged: (page) =>
                context.read<CoursesProvider>().load(page: page),
          ),
          itemBuilder: (context, item) => AppListTile(
            icon: Icons.class_outlined,
            title: item.displayName,
            subtitle: 'Año académico ${item.academicYear}',
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => CourseActions.delete(context, item),
            ),
            onTap: () => _openForm(context, initial: item),
          ),
        );
    }
  }
}
