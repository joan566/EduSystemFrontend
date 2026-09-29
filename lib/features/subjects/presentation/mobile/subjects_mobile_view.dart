import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/state/list_state.dart';
import '../../../../core/theme/subject_visuals.dart';
import '../../../../core/widgets/mobile/mobile_catalog_card.dart';
import '../../../../core/widgets/mobile/mobile_catalog_header.dart';
import '../../../../core/widgets/mobile/mobile_form.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_loading.dart';
import '../../../../core/widgets/shared/app_pagination.dart';
import '../../../../core/widgets/shared/app_search_field.dart';
import '../../../../core/widgets/shared/tinted_icon.dart';
import '../../../teaching/domain/entities/teaching_period_entity.dart';
import '../../../teaching/presentation/providers/teaching_provider.dart';
import '../../domain/entities/subject_entity.dart';
import '../providers/subjects_provider.dart';
import '../shared/subject_actions.dart';
import '../shared/subject_form.dart';
import '../shared/subject_usage.dart';

/// Mobile "Materias": title with counts and add, search, then one card per
/// subject with its icon, description and where you teach it.
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
    final provider = context.watch<SubjectsProvider>();
    final state = provider.state;
    final usage = classesBySubject(
      context.watch<TeachingProvider>().allPeriods,
    );

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MobileCatalogHeader(
            title: 'Materias',
            subtitle: state.status == ViewStatus.success
                ? '${state.totalElements} materias  ·  ${usage.length} con clases'
                : 'Las asignaturas que enseñas',
            addTooltip: 'Nueva materia',
            onAdd: () => _openForm(context),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: AppSearchField(
              hint: 'Buscar materia...',
              initialValue: provider.searchQuery,
              onChanged: (value) =>
                  context.read<SubjectsProvider>().search(value),
            ),
          ),
          Expanded(child: _body(context, state, usage)),
        ],
      ),
    );
  }

  Widget _body(
    BuildContext context,
    ListViewState<SubjectEntity> state,
    Map<int, List<TeachingPeriodEntity>> usage,
  ) {
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
          title: context.read<SubjectsProvider>().searchQuery == null
              ? 'No hay materias registradas'
              : 'Sin resultados',
          message:
              'Crea las asignaturas que impartes para asociarlas a tus cursos.',
          icon: Icons.menu_book_outlined,
          actionLabel: 'Nueva materia',
          onAction: () => _openForm(context),
        );
      case ViewStatus.success:
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            for (final subject in state.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: MobileCatalogCard(
                  leading: TintedIcon(
                    icon: subjectIcon(subject.name),
                    color: subjectAccent(subject.id),
                    size: 48,
                  ),
                  title: subject.name,
                  subtitle: subject.description,
                  meta: Row(
                    children: [
                      const Icon(Icons.groups_outlined, size: 13),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          [
                            classesCountLabel(usage[subject.id]?.length ?? 0),
                            if (usage[subject.id] != null)
                              coursesLabel(usage[subject.id]!),
                          ].join('  ·  '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  editLabel: 'Editar materia',
                  deleteLabel: 'Eliminar materia',
                  onEdit: () => _openForm(context, initial: subject),
                  onDelete: () => SubjectActions.delete(context, subject),
                ),
              ),
            if (state.totalPages > 1)
              AppPagination(
                page: state.page,
                totalPages: state.totalPages,
                totalElements: state.totalElements,
                onPageChanged: (page) =>
                    context.read<SubjectsProvider>().load(page: page),
              ),
          ],
        );
    }
  }
}
