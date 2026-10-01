import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/state/list_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/subject_visuals.dart';
import '../../../../core/widgets/desktop/desktop_catalog_header.dart';
import '../../../../core/widgets/desktop/desktop_catalog_relations.dart';
import '../../../../core/widgets/desktop/desktop_dialog.dart';
import '../../../../core/widgets/desktop/desktop_section_card.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_pagination.dart';
import '../../../../core/widgets/shared/app_search_field.dart';
import '../../../../core/widgets/shared/skeleton/skeleton.dart';
import '../../../../core/widgets/shared/skeleton/skeleton_blocks.dart';
import '../../../../core/widgets/shared/tinted_icon.dart';
import '../../../teaching/domain/entities/teaching_period_entity.dart';
import '../../../teaching/presentation/providers/teaching_provider.dart';
import '../../domain/entities/subject_entity.dart';
import '../providers/subjects_provider.dart';
import '../shared/subject_actions.dart';
import '../shared/subject_form.dart';
import '../shared/subject_usage.dart';

/// Desktop "Materias": a grid of subject cards (icon and color that follow
/// the subject across the app, description, the courses where you teach
/// it) with edit/delete on hover, and a side column that summarizes the
/// catalog and how it relates to the others.
class SubjectsDesktopView extends StatelessWidget {
  const SubjectsDesktopView({
    super.key,
    required this.search,
    required this.onSearchChanged,
    required this.page,
    required this.onPageChanged,
  });

  /// The screen's search and page (owned by the page entry point).
  final String search;
  final ValueChanged<String> onSearchChanged;
  final int page;
  final ValueChanged<int> onPageChanged;

  static const _sideWidth = 320.0;
  static const _sideBesideMinWidth = 1080.0;

  Future<void> _openForm(BuildContext context, {SubjectEntity? initial}) async {
    await showDesktopDialog<void>(
      context,
      child: SubjectForm(
        initial: initial,
        onSubmit: (data) =>
            SubjectActions.save(context, initial: initial, data: data),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SubjectsProvider>().query(
      search: search,
      page: page,
    );
    final usage = classesBySubject(
      context.watch<TeachingProvider>().allPeriods,
    );

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DesktopCatalogHeader(
              title: 'Materias',
              subtitle: state.status == ViewStatus.success
                  ? '${state.totalElements} materias en el catálogo  ·  enseñas ${usage.length}'
                  : 'Las asignaturas del colegio.',
              actions: [
                AppButton(
                  label: 'Nueva materia',
                  icon: Icons.add,
                  onPressed: () => _openForm(context),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 360,
                child: AppSearchField(
                  hint: 'Buscar materia...',
                  initialValue: search,
                  onChanged: onSearchChanged,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final beside = constraints.maxWidth >= _sideBesideMinWidth;
                  final main = _body(context, state, usage);
                  final side = Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SummaryCard(
                        total: state.totalElements,
                        taught: usage.length,
                      ),
                      const SizedBox(height: 16),
                      const DesktopCatalogRelations(
                        current: CatalogKind.subjects,
                      ),
                    ],
                  );
                  if (!beside) return main;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: main),
                      const SizedBox(width: 24),
                      SizedBox(
                        width: _sideWidth,
                        child: SingleChildScrollView(child: side),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
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
        return const _SubjectsGridSkeleton();
      case ViewStatus.error:
        return AppErrorState(
          exception: state.error!,
          onRetry: () => context.read<SubjectsProvider>().refresh(),
        );
      case ViewStatus.empty:
        return AppEmptyState(
          title: search.trim().isEmpty
              ? 'No hay materias registradas'
              : 'Sin resultados',
          message:
              'Crea las asignaturas que impartes para asociarlas a tus cursos.',
          icon: Icons.menu_book_outlined,
          actionLabel: 'Nueva materia',
          onAction: () => _openForm(context),
        );
      case ViewStatus.success:
        return LayoutBuilder(
          builder: (context, constraints) {
            const gap = 16.0;
            final columns = (constraints.maxWidth / 280).floor().clamp(1, 4);
            final width =
                (constraints.maxWidth - gap * (columns - 1)) / columns;
            return ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final subject in state.items)
                      SizedBox(
                        width: width,
                        child: _SubjectCard(
                          subject: subject,
                          classes: usage[subject.id] ?? const [],
                          onEdit: () => _openForm(context, initial: subject),
                          onDelete: () =>
                              SubjectActions.delete(context, subject),
                        ),
                      ),
                    SizedBox(
                      width: width,
                      child: _AddCard(onTap: () => _openForm(context)),
                    ),
                  ],
                ),
                if (state.totalPages > 1) ...[
                  const SizedBox(height: 16),
                  AppPagination(
                    page: state.page,
                    totalPages: state.totalPages,
                    totalElements: state.totalElements,
                    onPageChanged: (page) => onPageChanged(page),
                  ),
                ],
              ],
            );
          },
        );
    }
  }
}

/// Placeholder of the subjects grid: [_SubjectCard]s with the same size,
/// stripe and layout, laid out by the same column rule.
class _SubjectsGridSkeleton extends StatelessWidget {
  const _SubjectsGridSkeleton();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final outline = Theme.of(context).colorScheme.outline;
    return Skeleton(
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = 16.0;
          final columns = (constraints.maxWidth / 280).floor().clamp(1, 4);
          final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
          return SkeletonFill(
            child: Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (var i = 0; i < columns * 3; i++)
                  SizedBox(
                    width: width,
                    height: 188,
                    child: SkeletonSurface(
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            height: 4,
                            color: outline.withValues(alpha: 0.6),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SkeletonBox(
                                  width: 42,
                                  height: 42,
                                  radius: 12,
                                ),
                                const SizedBox(height: 10),
                                SkeletonText(
                                  style: textTheme.titleMedium,
                                  widthFactor: SkeletonRepeat.factor(i),
                                ),
                                const SizedBox(height: 2),
                                SkeletonText(
                                  style: textTheme.bodySmall,
                                  lines: 2,
                                ),
                                const SizedBox(height: 10),
                                SkeletonText(
                                  style: textTheme.bodySmall,
                                  widthFactor: 0.4,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SubjectCard extends StatefulWidget {
  const _SubjectCard({
    required this.subject,
    required this.classes,
    required this.onEdit,
    required this.onDelete,
  });

  final SubjectEntity subject;
  final List<TeachingPeriodEntity> classes;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_SubjectCard> createState() => _SubjectCardState();
}

class _SubjectCardState extends State<_SubjectCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final subject = widget.subject;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accent = subjectAccent(subject.id);
    final description = subject.description?.trim();

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 188,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovering
                ? accent.withValues(alpha: 0.5)
                : colors.outline.withValues(alpha: 0.7),
          ),
          boxShadow: [
            BoxShadow(
              color: _hovering ? AppColors.shadowMedium : AppColors.shadowSoft,
              blurRadius: _hovering ? 18 : 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onEdit,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Identity stripe in the subject's color.
                Container(height: 4, color: accent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            TintedIcon(
                              icon: subjectIcon(subject.name),
                              color: accent,
                              size: 42,
                            ),
                            const Spacer(),
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 120),
                              opacity: _hovering ? 1 : 0,
                              child: Row(
                                children: [
                                  IconButton(
                                    tooltip: 'Editar materia',
                                    visualDensity: VisualDensity.compact,
                                    onPressed: widget.onEdit,
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Eliminar materia',
                                    visualDensity: VisualDensity.compact,
                                    onPressed: widget.onDelete,
                                    icon: Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: colors.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          subject.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Expanded(
                          child: Text(
                            description == null || description.isEmpty
                                ? 'Sin descripción'
                                : description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              fontStyle:
                                  description == null || description.isEmpty
                                  ? FontStyle.italic
                                  : null,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.groups_outlined,
                              size: 15,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                widget.classes.isEmpty
                                    ? classesCountLabel(0)
                                    : '${classesCountLabel(widget.classes.length)}  ·  ${coursesLabel(widget.classes)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodySmall?.copyWith(
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddCard extends StatelessWidget {
  const _AddCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      height: 188,
      child: Material(
        color: AppColors.accentBlue.withValues(alpha: 0.03),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.accentBlue.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const TintedIcon(
                icon: Icons.add,
                color: AppColors.accentBlue,
                size: 44,
                circle: true,
              ),
              const SizedBox(height: 10),
              Text(
                'Nueva materia',
                style: textTheme.titleSmall?.copyWith(
                  color: AppColors.accentBlue,
                ),
              ),
              Text('Agrégala al catálogo', style: textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.total, required this.taught});

  final int total;
  final int taught;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final fraction = total == 0 ? 0.0 : (taught / total).clamp(0.0, 1.0);
    return DesktopSectionCard(
      icon: Icons.insights_outlined,
      title: 'Resumen',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                '$taught',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(' de $total materias', style: textTheme.bodyMedium),
            ],
          ),
          Text('tienen al menos una clase tuya', style: textTheme.bodySmall),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              color: AppColors.accentBlue,
              backgroundColor: AppColors.accentBlue.withValues(alpha: 0.12),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'El catálogo es compartido por todo el colegio: editar una materia la cambia '
            'para todos sus cursos.',
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
