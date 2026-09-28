import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/state/list_state.dart';
import '../../../../core/widgets/mobile/mobile_card_list.dart';
import '../../../../core/widgets/mobile/mobile_form.dart';
import '../../../../core/widgets/mobile/mobile_page_header.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_list_tile.dart';
import '../../../../core/widgets/shared/app_loading.dart';
import '../../../../core/widgets/shared/app_pagination.dart';
import '../../../../core/widgets/shared/app_search_field.dart';
import '../../domain/entities/subject_entity.dart';
import '../providers/subjects_provider.dart';
import '../shared/subject_actions.dart';
import '../shared/subject_form.dart';

class SubjectsMobileView extends StatelessWidget {
  const SubjectsMobileView({super.key});

  Future<void> _openForm(BuildContext context, {SubjectEntity? initial}) async {
    final data = await showMobileForm<SubjectFormResult>(
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          const MobilePageHeader(title: 'Materias'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppSearchField(
              hint: 'Buscar materia...',
              onChanged: (value) =>
                  context.read<SubjectsProvider>().search(value),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildBody(context, state)),
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
        return MobileCardList<SubjectEntity>(
          items: state.items,
          footer: AppPagination(
            page: state.page,
            totalPages: state.totalPages,
            totalElements: state.totalElements,
            onPageChanged: (page) =>
                context.read<SubjectsProvider>().load(page: page),
          ),
          itemBuilder: (context, item) => AppListTile(
            icon: Icons.menu_book_outlined,
            title: item.name,
            subtitle: item.description,
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => SubjectActions.delete(context, item),
            ),
            onTap: () => _openForm(context, initial: item),
          ),
        );
    }
  }
}
