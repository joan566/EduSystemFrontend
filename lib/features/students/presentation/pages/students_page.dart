import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/state/list_state.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_data_table.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_pagination.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../../domain/entities/student_entity.dart';
import '../providers/students_provider.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<StudentsProvider>().load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<StudentsProvider>().state;

    return Scaffold(
      body: Column(
        children: [
          AppPageHeader(
            title: 'Estudiantes',
            subtitle: 'Consulta y gestiona los estudiantes matriculados.',
            actions: [
              AppButton(
                label: 'Importar',
                icon: Icons.upload_file_outlined,
                variant: AppButtonVariant.outlined,
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
          if (state.status == ViewStatus.success)
            AppPagination(
              page: state.page,
              totalPages: state.totalPages,
              totalElements: state.totalElements,
              onPageChanged: (page) =>
                  context.read<StudentsProvider>().load(page: page),
            ),
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
        return AppDataTable<StudentEntity>(
          isMobile: context.isMobile,
          items: state.items,
          onRowTap: (item) => context.push(RoutePaths.studentDetail(item.id)),
          mobileCardBuilder: (context, item) => AppListTile(
            icon: Icons.people_alt_outlined,
            title: item.fullName,
            subtitle: 'Código: ${item.studentCode}',
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => context.push(RoutePaths.studentDetail(item.id)),
          ),
          columns: [
            AppDataColumn(
              label: 'Código',
              cellBuilder: (item) => Text(item.studentCode),
            ),
            AppDataColumn(
              label: 'Nombre',
              cellBuilder: (item) => Text(item.fullName),
            ),
            AppDataColumn(
              label: 'Identificación',
              cellBuilder: (item) => Text(item.identificationNumber),
            ),
            AppDataColumn(
              label: 'Correo',
              cellBuilder: (item) => Text(item.email),
            ),
          ],
        );
    }
  }
}
