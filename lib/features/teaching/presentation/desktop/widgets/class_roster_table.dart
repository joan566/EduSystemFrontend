import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../core/router/route_paths.dart';
import '../../../../../core/state/list_state.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/desktop/desktop_section_card.dart';
import '../../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../../core/widgets/shared/app_error_state.dart';
import '../../../../../core/widgets/shared/app_search_field.dart';
import '../../../../students/presentation/providers/students_provider.dart';
import '../../shared/class_lookup.dart';

/// "Estudiantes": the group roster as a searchable table.
class ClassRosterTable extends StatefulWidget {
  const ClassRosterTable({super.key, required this.groupId});

  final int groupId;

  @override
  State<ClassRosterTable> createState() => _ClassRosterTableState();
}

class _ClassRosterTableState extends State<ClassRosterTable> {
  // Transient text filter over the loaded roster; losing it on a layout
  // switch is harmless.
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<StudentsProvider>().groupRoster(widget.groupId);
    final textTheme = Theme.of(context).textTheme;
    final students = state.items
        .where(
          (s) => matchesSearch(_query, [
            s.fullName,
            s.studentCode,
            s.identificationNumber,
            s.email,
          ]),
        )
        .toList();

    return DesktopSectionCard(
      icon: Icons.people_alt_outlined,
      title: 'Estudiantes',
      subtitle: state.status == ViewStatus.success
          ? '${state.totalElements}'
          : null,
      child: switch (state.status) {
        ViewStatus.error => AppErrorState(
          exception: state.error!,
          onRetry: () =>
              context.read<StudentsProvider>().loadGroupRoster(widget.groupId),
        ),
        ViewStatus.empty => AppEmptyState(
          title: 'Sin estudiantes',
          message: 'Importa o matricula estudiantes en este curso.',
          icon: Icons.people_alt_outlined,
          actionLabel: 'Importar estudiantes',
          onAction: () => context.push(RoutePaths.dataManagement),
        ),
        ViewStatus.success => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 320,
                child: AppSearchField(
                  hint: 'Buscar por nombre, código o correo...',
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    showCheckboxColumn: false,
                    headingTextStyle: textTheme.labelMedium,
                    columns: const [
                      DataColumn(label: Text('ESTUDIANTE')),
                      DataColumn(label: Text('CÓDIGO')),
                      DataColumn(label: Text('IDENTIFICACIÓN')),
                      DataColumn(label: Text('CORREO')),
                    ],
                    rows: [
                      for (final s in students)
                        DataRow(
                          onSelectChanged: (_) =>
                              context.push(RoutePaths.studentDetail(s.id)),
                          cells: [
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 15,
                                    backgroundColor: AppColors.accentBlue
                                        .withValues(alpha: 0.12),
                                    foregroundColor: AppColors.accentBlue,
                                    child: Text(
                                      '${s.firstName.characters.firstOrNull ?? ''}'
                                      '${s.lastName.characters.firstOrNull ?? ''}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    s.fullName,
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(Text(s.studentCode)),
                            DataCell(Text(s.identificationNumber)),
                            DataCell(Text(s.email)),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (students.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Ningún estudiante coincide con la búsqueda.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall,
                ),
              ),
            if (state.totalPages > 1)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Mostrando ${state.items.length} de ${state.totalElements}. '
                  'Consulta el resto en Estudiantes.',
                  style: textTheme.bodySmall,
                ),
              ),
          ],
        ),
        _ => const SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      },
    );
  }
}
