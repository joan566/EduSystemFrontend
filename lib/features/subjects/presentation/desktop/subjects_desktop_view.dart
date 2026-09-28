import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/state/list_state.dart';
import '../../../../core/widgets/desktop/desktop_data_table.dart';
import '../../../../core/widgets/desktop/desktop_dialog.dart';
import '../../../../core/widgets/desktop/desktop_page_header.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_loading.dart';
import '../../../../core/widgets/shared/app_pagination.dart';
import '../../../../core/widgets/shared/app_search_field.dart';
import '../../domain/entities/subject_entity.dart';
import '../providers/subjects_provider.dart';
import '../shared/subject_actions.dart';
import '../shared/subject_form.dart';

class SubjectsDesktopView extends StatelessWidget {
  const SubjectsDesktopView({super.key});

  Future<void> _openForm(BuildContext context, {SubjectEntity? initial}) async {
    final data = await showDesktopDialog<SubjectFormResult>(
      context,
      child: SubjectForm(initial: initial),
    );
    if (data == null || !context.mounted) return;
    await SubjectActions.save(context, initial: initial, data: data);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SubjectsProvider>().state;

    return Scaffold(
      body: Column(
        children: [
          DesktopPageHeader(
            title: 'Materias',
            subtitle: 'Asignaturas disponibles para tus cursos.',
            actions: [
              AppButton(
                label: 'Nueva materia',
                icon: Icons.add,
                onPressed: () => _openForm(context),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AppSearchField(
              hint: 'Buscar materia...',
              onChanged: (value) =>
                  context.read<SubjectsProvider>().search(value),
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
                  context.read<SubjectsProvider>().load(page: page),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, ListViewState<SubjectEntity> state) {
    switch (state.status) {
      case ViewStatus.initial:
      case ViewStatus.loading:
        return const AppLoading();
      case ViewStatus.error:
        return AppErrorState(
          exception: state.error!,
          onRetry: () => context.read<SubjectsProvider>().load(),
        );
      case ViewStatus.empty:
        return AppEmptyState(
          title: 'No hay materias registradas',
          message:
              'Crea las asignaturas que impartes para asociarlas a tus cursos.',
          icon: Icons.menu_book_outlined,
          actionLabel: 'Nueva materia',
          onAction: () => _openForm(context),
        );
      case ViewStatus.success:
        return DesktopDataTable<SubjectEntity>(
          items: state.items,
          onRowTap: (item) => _openForm(context, initial: item),
          columns: [
            DesktopDataColumn(
              label: 'Nombre',
              cellBuilder: (item) => Text(item.name),
            ),
            DesktopDataColumn(
              label: 'Descripción',
              cellBuilder: (item) => Text(item.description ?? '—'),
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
                    onPressed: () => SubjectActions.delete(context, item),
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }
}
