import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/state/detail_state.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_data_table.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../domain/entities/grading_entities.dart';
import '../providers/grading_provider.dart';

/// Read-only view of computed period grades (§53, §84): the backend is
/// the sole source of the official grade — this only presents it.
class PeriodGradesTab extends StatefulWidget {
  const PeriodGradesTab({super.key, required this.teachingPeriodId});

  final int teachingPeriodId;

  @override
  State<PeriodGradesTab> createState() => _PeriodGradesTabState();
}

class _PeriodGradesTabState extends State<PeriodGradesTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<GradingProvider>().loadPeriodGrades(
        widget.teachingPeriodId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GradingProvider>().periodGradesState;

    switch (state.status) {
      case DetailStatus.initial:
      case DetailStatus.loading:
        return const AppLoading();
      case DetailStatus.error:
        final error = state.error!;
        if (error.code == 'GRADING_CONFIGURATION_INCOMPLETE') {
          return const AppEmptyState(
            title: 'La configuración de calificación está incompleta',
            message:
                'Ve a la pestaña "Configuración" y asegúrate de que las '
                'ponderaciones sumen 100%.',
            icon: Icons.rule_outlined,
          );
        }
        return AppErrorState(
          exception: error,
          onRetry: () => context.read<GradingProvider>().loadPeriodGrades(
            widget.teachingPeriodId,
          ),
        );
      case DetailStatus.success:
        final data = state.data!;
        if (data.students.isEmpty) {
          return const AppEmptyState(
            title: 'No hay estudiantes en este curso',
            icon: Icons.people_alt_outlined,
          );
        }
        final categoryNames = data.students.first.categories
            .map((c) => c.categoryName)
            .toList();

        return AppDataTable<StudentPeriodGrade>(
          isMobile: context.isMobile,
          items: data.students,
          mobileCardBuilder: (context, item) => AppListTile(
            icon: Icons.grade_outlined,
            title: item.studentName,
            subtitle: item.categories
                .map(
                  (c) =>
                      '${c.categoryName}: ${c.achievement?.toStringAsFixed(1) ?? '—'}',
                )
                .join(' · '),
            trailing: Text(
              item.periodGrade != null
                  ? Formatters.grade(item.periodGrade!, data.scale.maximumValue)
                  : '—',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          columns: [
            AppDataColumn(
              label: 'Estudiante',
              cellBuilder: (item) => Text(item.studentName),
            ),
            for (final name in categoryNames)
              AppDataColumn(
                label: name,
                cellBuilder: (item) {
                  final category = item.categories.firstWhere(
                    (c) => c.categoryName == name,
                  );
                  return Text(
                    category.achievement != null
                        ? '${category.achievement!.toStringAsFixed(1)}%'
                        : '—',
                  );
                },
              ),
            AppDataColumn(
              label: 'Nota del periodo',
              cellBuilder: (item) => Text(
                item.periodGrade != null
                    ? Formatters.grade(
                        item.periodGrade!,
                        data.scale.maximumValue,
                      )
                    : '—',
              ),
            ),
          ],
        );
    }
  }
}
