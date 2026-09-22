import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/state/list_state.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/widgets/app_data_table.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_pagination.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../academic_levels/domain/entities/academic_level_entity.dart';
import '../../../academic_levels/presentation/providers/academic_levels_provider.dart';
import '../../domain/entities/course_entity.dart';
import '../providers/courses_provider.dart';

class CoursesPage extends StatefulWidget {
  const CoursesPage({super.key});

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CoursesProvider>().load();
      final levels = context.read<AcademicLevelsProvider>();
      if (levels.state.status == ViewStatus.initial) levels.load();
    });
  }

  Future<void> _openForm({CourseEntity? initial}) async {
    final levels = context.read<AcademicLevelsProvider>().state.items;
    if (levels.isEmpty) {
      context.showWarning('Primero crea al menos un grado académico.');
      return;
    }
    final provider = context.read<CoursesProvider>();
    final result = await showAppDialog(
      context,
      child: _CourseForm(initial: initial, levels: levels),
    );
    if (result == null) return;
    final data = result as ({int gradeId, String name, int academicYear});
    final error = initial == null
        ? await provider.create(
            gradeId: data.gradeId,
            name: data.name,
            academicYear: data.academicYear,
          )
        : await provider.update(
            initial.id,
            name: data.name,
            academicYear: data.academicYear,
          );
    if (!mounted) return;
    if (error != null) {
      context.showApiError(error);
    } else {
      context.showSuccess(
        initial == null ? 'Curso creado.' : 'Curso actualizado.',
      );
    }
  }

  Future<void> _delete(CourseEntity course) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Eliminar curso',
      message:
          'Esta acción no se puede deshacer. ¿Eliminar "${course.displayName}"?',
      confirmLabel: 'Eliminar',
    );
    if (!confirmed || !mounted) return;
    final error = await context.read<CoursesProvider>().delete(course.id);
    if (!mounted) return;
    if (error != null) {
      context.showApiError(error);
    } else {
      context.showSuccess('Curso eliminado.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CoursesProvider>().state;
    final levels = context.watch<AcademicLevelsProvider>().state.items;

    return Scaffold(
      floatingActionButton: context.isMobile
          ? FloatingActionButton(
              onPressed: () => _openForm(),
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          AppPageHeader(
            title: 'Cursos',
            subtitle: 'Grupos de estudiantes, por grado y año académico.',
            actions: context.isMobile
                ? []
                : [
                    AppButton(
                      label: 'Nuevo curso',
                      icon: Icons.add,
                      onPressed: () => _openForm(),
                    ),
                  ],
          ),
          if (levels.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 220,
                child: AppDropdown<AcademicLevelEntity?>(
                  label: 'Filtrar por grado',
                  value: null,
                  items: [null, ...levels],
                  itemLabel: (level) => level?.name ?? 'Todos los grados',
                  onChanged: (level) => context.read<CoursesProvider>().load(
                    page: 0,
                    gradeId: level?.id,
                    resetFilters: level == null,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(child: _buildBody(state)),
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

  Widget _buildBody(ListViewState<CourseEntity> state) {
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
          onAction: () => _openForm(),
        );
      case ViewStatus.success:
        return AppDataTable<CourseEntity>(
          isMobile: context.isMobile,
          items: state.items,
          onRowTap: (item) => _openForm(initial: item),
          mobileCardBuilder: (context, item) => AppListTile(
            icon: Icons.class_outlined,
            title: item.displayName,
            subtitle: 'Año académico ${item.academicYear}',
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => _delete(item),
            ),
            onTap: () => _openForm(initial: item),
          ),
          columns: [
            AppDataColumn(
              label: 'Grado',
              cellBuilder: (item) => Text(item.gradeName),
            ),
            AppDataColumn(
              label: 'Curso',
              cellBuilder: (item) => Text(item.name),
            ),
            AppDataColumn(
              label: 'Año académico',
              cellBuilder: (item) => Text('${item.academicYear}'),
            ),
            AppDataColumn(
              label: 'Acciones',
              cellBuilder: (item) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: () => _openForm(initial: item),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: () => _delete(item),
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }
}

class _CourseForm extends StatefulWidget {
  const _CourseForm({this.initial, required this.levels});

  final CourseEntity? initial;
  final List<AcademicLevelEntity> levels;

  @override
  State<_CourseForm> createState() => _CourseFormState();
}

class _CourseFormState extends State<_CourseForm> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.initial?.name,
  );
  late final _yearController = TextEditingController(
    text: (widget.initial?.academicYear ?? DateTime.now().year).toString(),
  );
  int? _gradeId;

  @override
  void initState() {
    super.initState();
    _gradeId =
        widget.initial?.gradeId ??
        (widget.levels.isNotEmpty ? widget.levels.first.id : null);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_gradeId == null) return;
    Navigator.of(context).pop((
      gradeId: _gradeId!,
      name: _nameController.text.trim(),
      academicYear: int.parse(_yearController.text.trim()),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initial != null;
    return AppDialogFrame(
      title: isEditing ? 'Editar curso' : 'Nuevo curso',
      actions: [AppButton(label: 'Guardar', onPressed: _submit)],
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppDropdown<int>(
              label: 'Grado',
              required: true,
              value: _gradeId,
              enabled: !isEditing,
              items: [for (final level in widget.levels) level.id],
              itemLabel: (id) =>
                  widget.levels.firstWhere((l) => l.id == id).name,
              onChanged: (value) => setState(() => _gradeId = value),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _nameController,
              label: 'Nombre del curso',
              required: true,
              hint: 'Ej. A',
              validator: (v) => Validators.combine([
                (v) => Validators.required(v, field: 'El nombre'),
                (v) => Validators.maxLength(v, 50, field: 'El nombre'),
              ])(v),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _yearController,
              label: 'Año académico',
              required: true,
              keyboardType: TextInputType.number,
              validator: (v) {
                final year = int.tryParse(v ?? '');
                if (year == null || year < 2000 || year > 2200) {
                  return 'Ingresa un año válido (2000-2200).';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
