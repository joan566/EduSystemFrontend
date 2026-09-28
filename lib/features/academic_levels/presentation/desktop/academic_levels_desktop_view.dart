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
import '../../domain/entities/academic_level_entity.dart';
import '../providers/academic_levels_provider.dart';
import '../shared/academic_level_actions.dart';
import '../shared/academic_level_form.dart';

class AcademicLevelsDesktopView extends StatelessWidget {
  const AcademicLevelsDesktopView({super.key});

  Future<void> _openForm(
    BuildContext context, {
    AcademicLevelEntity? initial,
  }) async {
    final data = await showDesktopDialog<AcademicLevelFormResult>(
      context,
      child: AcademicLevelForm(initial: initial),
    );
    if (data == null || !context.mounted) return;
    await AcademicLevelActions.save(context, initial: initial, data: data);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AcademicLevelsProvider>().state;

    return Scaffold(
      body: Column(
        children: [
          DesktopPageHeader(
            title: 'Grados académicos',
            subtitle: 'Niveles compartidos usados para organizar los cursos.',
            actions: [
              AppButton(
                label: 'Nuevo grado',
                icon: Icons.add,
                onPressed: () => _openForm(context),
              ),
            ],
          ),
          Expanded(child: _buildBody(context, state)),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ListViewState<AcademicLevelEntity> state,
  ) {
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
          onAction: () => _openForm(context),
        );
      case ViewStatus.success:
        return DesktopDataTable<AcademicLevelEntity>(
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
                    onPressed: () => AcademicLevelActions.delete(context, item),
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }
}
