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
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_pagination.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/subject_entity.dart';
import '../providers/subjects_provider.dart';

class SubjectsPage extends StatefulWidget {
  const SubjectsPage({super.key});

  @override
  State<SubjectsPage> createState() => _SubjectsPageState();
}

class _SubjectsPageState extends State<SubjectsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<SubjectsProvider>().load(),
    );
  }

  Future<void> _openForm({SubjectEntity? initial}) async {
    final provider = context.read<SubjectsProvider>();
    final result = await showAppDialog(
      context,
      child: _SubjectForm(initial: initial),
    );
    if (result == null) return;
    final data = result as ({String name, String description});
    final error = initial == null
        ? await provider.create(
            name: data.name,
            description: data.description.isEmpty ? null : data.description,
          )
        : await provider.update(
            initial.id,
            name: data.name,
            description: data.description.isEmpty ? null : data.description,
          );
    if (!mounted) return;
    if (error != null) {
      context.showApiError(error);
    } else {
      context.showSuccess(
        initial == null ? 'Materia creada.' : 'Materia actualizada.',
      );
    }
  }

  Future<void> _delete(SubjectEntity subject) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Eliminar materia',
      message: 'Esta acción no se puede deshacer. ¿Eliminar "${subject.name}"?',
      confirmLabel: 'Eliminar',
    );
    if (!confirmed || !mounted) return;
    final error = await context.read<SubjectsProvider>().delete(subject.id);
    if (!mounted) return;
    if (error != null) {
      context.showApiError(error);
    } else {
      context.showSuccess('Materia eliminada.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SubjectsProvider>().state;

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
            title: 'Materias',
            subtitle: 'Asignaturas disponibles para tus cursos.',
            actions: context.isMobile
                ? []
                : [
                    AppButton(
                      label: 'Nueva materia',
                      icon: Icons.add,
                      onPressed: () => _openForm(),
                    ),
                  ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppSearchField(
              hint: 'Buscar materia...',
              onChanged: (value) =>
                  context.read<SubjectsProvider>().search(value),
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
                  context.read<SubjectsProvider>().load(page: page),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(ListViewState<SubjectEntity> state) {
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
          onAction: () => _openForm(),
        );
      case ViewStatus.success:
        return AppDataTable<SubjectEntity>(
          isMobile: context.isMobile,
          items: state.items,
          onRowTap: (item) => _openForm(initial: item),
          mobileCardBuilder: (context, item) => AppListTile(
            icon: Icons.menu_book_outlined,
            title: item.name,
            subtitle: item.description,
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => _delete(item),
            ),
            onTap: () => _openForm(initial: item),
          ),
          columns: [
            AppDataColumn(
              label: 'Nombre',
              cellBuilder: (item) => Text(item.name),
            ),
            AppDataColumn(
              label: 'Descripción',
              cellBuilder: (item) => Text(item.description ?? '—'),
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

class _SubjectForm extends StatefulWidget {
  const _SubjectForm({this.initial});

  final SubjectEntity? initial;

  @override
  State<_SubjectForm> createState() => _SubjectFormState();
}

class _SubjectFormState extends State<_SubjectForm> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.initial?.name,
  );
  late final _descriptionController = TextEditingController(
    text: widget.initial?.description,
  );

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop((
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initial != null;
    return AppDialogFrame(
      title: isEditing ? 'Editar materia' : 'Nueva materia',
      actions: [AppButton(label: 'Guardar', onPressed: _submit)],
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _nameController,
              label: 'Nombre',
              required: true,
              hint: 'Ej. Matemáticas',
              validator: (v) => Validators.combine([
                (v) => Validators.required(v, field: 'El nombre'),
                (v) => Validators.maxLength(v, 100, field: 'El nombre'),
              ])(v),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _descriptionController,
              label: 'Descripción',
              maxLines: 2,
              validator: (v) =>
                  Validators.maxLength(v, 255, field: 'La descripción'),
            ),
          ],
        ),
      ),
    );
  }
}
