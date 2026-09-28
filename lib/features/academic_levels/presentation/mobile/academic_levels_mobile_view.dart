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
import '../../domain/entities/academic_level_entity.dart';
import '../providers/academic_levels_provider.dart';
import '../shared/academic_level_actions.dart';
import '../shared/academic_level_form.dart';

class AcademicLevelsMobileView extends StatelessWidget {
  const AcademicLevelsMobileView({super.key});

  Future<void> _openForm(
    BuildContext context, {
    AcademicLevelEntity? initial,
  }) async {
    final data = await showMobileForm<AcademicLevelFormResult>(
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          const MobilePageHeader(title: 'Grados académicos'),
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
        return MobileCardList<AcademicLevelEntity>(
          items: state.items,
          itemBuilder: (context, item) => AppListTile(
            icon: Icons.school_outlined,
            title: item.name,
            subtitle: item.description,
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => AcademicLevelActions.delete(context, item),
            ),
            onTap: () => _openForm(context, initial: item),
          ),
        );
    }
  }
}
