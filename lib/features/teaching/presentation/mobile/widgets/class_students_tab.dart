import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../core/router/route_paths.dart';
import '../../../../../core/state/list_state.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../../core/widgets/shared/app_error_state.dart';
import '../../../../../core/widgets/shared/app_loading.dart';
import '../../../../students/presentation/providers/students_provider.dart';

/// "Estudiantes": the class's group roster.
class ClassStudentsTab extends StatelessWidget {
  const ClassStudentsTab({super.key, required this.groupId});

  final int groupId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<StudentsProvider>().groupRoster(groupId);
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    switch (state.status) {
      case ViewStatus.initial:
      case ViewStatus.loading:
        return const Padding(padding: EdgeInsets.all(24), child: AppLoading());
      case ViewStatus.error:
        return AppErrorState(
          exception: state.error!,
          onRetry: () =>
              context.read<StudentsProvider>().loadGroupRoster(groupId),
        );
      case ViewStatus.empty:
        return AppEmptyState(
          title: 'Sin estudiantes',
          message: 'Importa o matricula estudiantes en este curso.',
          icon: Icons.people_alt_outlined,
          actionLabel: 'Importar estudiantes',
          onAction: () => context.push(RoutePaths.dataManagement),
        );
      case ViewStatus.success:
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.outline.withValues(alpha: 0.7)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Text(
                  state.totalElements == 1
                      ? '1 estudiante'
                      : '${state.totalElements} estudiantes',
                  style: textTheme.titleMedium,
                ),
              ),
              for (final (i, student) in state.items.indexed) ...[
                if (i > 0) const Divider(height: 1, indent: 68),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.accentBlue.withValues(
                      alpha: 0.12,
                    ),
                    foregroundColor: AppColors.accentBlue,
                    child: Text(
                      '${student.firstName.characters.firstOrNull ?? ''}'
                      '${student.lastName.characters.firstOrNull ?? ''}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  title: Text(student.fullName),
                  subtitle: Text('Código ${student.studentCode}'),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () =>
                      context.push(RoutePaths.studentDetail(student.id)),
                ),
              ],
              if (state.totalPages > 1)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Mostrando ${state.items.length} de ${state.totalElements}. '
                    'Consulta el resto en Estudiantes.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        );
    }
  }
}
