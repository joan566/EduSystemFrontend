import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/state/list_state.dart';
import '../../../../core/widgets/mobile/mobile_card_list.dart';
import '../../../../core/widgets/mobile/mobile_page_header.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_list_tile.dart';
import '../../../../core/widgets/shared/app_loading.dart';
import '../../../../core/widgets/shared/app_pagination.dart';
import '../../../../core/widgets/shared/app_search_field.dart';
import '../../domain/entities/student_entity.dart';
import '../providers/students_provider.dart';

class StudentsMobileView extends StatelessWidget {
  const StudentsMobileView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<StudentsProvider>().state;

    return Scaffold(
      body: Column(
        children: [
          MobilePageHeader(
            title: 'Estudiantes',
            actions: [
              IconButton(
                tooltip: 'Importar',
                icon: const Icon(Icons.upload_file_outlined),
                onPressed: () => context.push(RoutePaths.dataManagement),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppSearchField(
              hint: 'Buscar por nombre, código o identificación...',
              onChanged: (value) =>
                  context.read<StudentsProvider>().search(value),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildBody(context, state)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, ListViewState<StudentEntity> state) {
    switch (state.status) {
      case ViewStatus.initial:
      case ViewStatus.loading:
        return const AppLoading();
      case ViewStatus.error:
        return AppErrorState(
          exception: state.error!,
          onRetry: () => context.read<StudentsProvider>().load(),
        );
      case ViewStatus.empty:
        return AppEmptyState(
          title: 'No tienes estudiantes registrados',
          message: 'Importa tu lista de estudiantes desde Excel para comenzar.',
          icon: Icons.people_alt_outlined,
          actionLabel: 'Importar estudiantes',
          onAction: () => context.push(RoutePaths.dataManagement),
        );
      case ViewStatus.success:
        return MobileCardList<StudentEntity>(
          items: state.items,
          footer: AppPagination(
            page: state.page,
            totalPages: state.totalPages,
            totalElements: state.totalElements,
            onPageChanged: (page) =>
                context.read<StudentsProvider>().load(page: page),
          ),
          itemBuilder: (context, item) => AppListTile(
            icon: Icons.people_alt_outlined,
            title: item.fullName,
            subtitle: 'Código: ${item.studentCode}',
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => context.push(RoutePaths.studentDetail(item.id)),
          ),
        );
    }
  }
}
