import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/state/list_state.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/widgets/app_data_table.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../domain/entities/academic_level_entity.dart';
import '../providers/academic_levels_provider.dart';
import '../widgets/academic_level_form.dart';

class AcademicLevelsPage extends StatefulWidget {
  const AcademicLevelsPage({super.key});

  @override
  State<AcademicLevelsPage> createState() => _AcademicLevelsPageState();
}

class _AcademicLevelsPageState extends State<AcademicLevelsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AcademicLevelsProvider>().load(),
    );
  }

  Future<void> _openForm({AcademicLevelEntity? initial}) async {
    final provider = context.read<AcademicLevelsProvider>();
    final result = await showAppDialog(
      context,
      child: AcademicLevelForm(initial: initial),
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
        initial == null ? 'Grado creado.' : 'Grado actualizado.',
      );
    }
  }

  Future<void> _delete(AcademicLevelEntity level) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Eliminar grado',
      message: 'Esta acción no se puede deshacer. ¿Eliminar "${level.name}"?',
      confirmLabel: 'Eliminar',
    );
    if (!confirmed || !mounted) return;
    final error = await context.read<AcademicLevelsProvider>().delete(level.id);
    if (!mounted) return;
    if (error != null) {
      context.showApiError(error);
    } else {
      context.showSuccess('Grado eliminado.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AcademicLevelsProvider>().state;

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
            title: 'Grados académicos',
            subtitle: 'Niveles compartidos usados para organizar los cursos.',
            actions: context.isMobile
                ? []
                : [
                    AppButton(
                      label: 'Nuevo grado',
                      icon: Icons.add,
                      onPressed: () => _openForm(),
                    ),
                  ],
          ),
          Expanded(child: _buildBody(state)),
        ],
      ),
    );
  }

  Widget _buildBody(ListViewState<AcademicLevelEntity> state) {
    switch (state.status) {
      case ViewStatus.initial:
      case ViewStatus.loading:
        return const AppLoading();
      case ViewStatus.error:
        return AppErrorState(
          exception: state.error!,
          onRetry: () => context.read<AcademicLevelsProvider>().load(),
        );
      case ViewStatus.empty:
        return AppEmptyState(
          title: 'No hay grados registrados',
          message:
              'Crea los grados académicos que usarás para organizar tus cursos.',
          icon: Icons.school_outlined,
          actionLabel: 'Nuevo grado',
          onAction: () => _openForm(),
        );
      case ViewStatus.success:
        return AppDataTable<AcademicLevelEntity>(
          isMobile: context.isMobile,
          items: state.items,
          onRowTap: (item) => _openForm(initial: item),
          mobileCardBuilder: (context, item) => AppListTile(
            icon: Icons.school_outlined,
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
