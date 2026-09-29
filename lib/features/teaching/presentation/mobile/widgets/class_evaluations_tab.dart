import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../core/router/route_paths.dart';
import '../../../../../core/state/list_state.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/mobile/mobile_section_card.dart';
import '../../../../../core/widgets/shared/tinted_icon.dart';
import '../../../../activities/presentation/providers/activities_provider.dart';
import '../../../../exams/presentation/providers/exams_provider.dart';
import '../../shared/class_scoped_state.dart';

/// "Evaluaciones": the class's exams and activities.
class ClassEvaluationsTab extends StatelessWidget {
  const ClassEvaluationsTab({super.key, required this.teachingPeriodId});

  final int teachingPeriodId;

  @override
  Widget build(BuildContext context) {
    final exams = classScoped(
      context.watch<ExamsProvider>().state,
      teachingPeriodId: teachingPeriodId,
      teachingPeriodOf: (e) => e.teachingPeriodId,
      reload: () => context.read<ExamsProvider>().load(
        teachingPeriodId: teachingPeriodId,
      ),
    );
    final activities = classScoped(
      context.watch<ActivitiesProvider>().state,
      teachingPeriodId: teachingPeriodId,
      teachingPeriodOf: (a) => a.teachingPeriodId,
      reload: () => context.read<ActivitiesProvider>().load(
        teachingPeriodId: teachingPeriodId,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MobileSectionCard(
          icon: Icons.fact_check_outlined,
          title: 'Exámenes',
          linkLabel: 'Crear',
          onLink: () =>
              context.push(RoutePaths.examCreateForClass(teachingPeriodId)),
          child: _EvaluationList(
            state: exams,
            emptyText: 'Aún no hay exámenes en esta clase.',
            icon: Icons.fact_check_outlined,
            color: AppColors.accentBlue,
            titleOf: (e) => e.name,
            subtitleOf: (e) => [
              '${e.numberOfQuestions} preguntas',
              if (e.evaluationDate != null) Formatters.date(e.evaluationDate!),
            ].join(' · '),
            onOpen: (e) => context.push(RoutePaths.examDetail(e.id)),
            onRetry: () => context.read<ExamsProvider>().load(
              teachingPeriodId: teachingPeriodId,
            ),
          ),
        ),
        const SizedBox(height: 14),
        MobileSectionCard(
          icon: Icons.assignment_outlined,
          title: 'Actividades',
          linkLabel: 'Crear',
          onLink: () =>
              context.push(RoutePaths.activitiesForClass(teachingPeriodId)),
          child: _EvaluationList(
            state: activities,
            emptyText: 'Aún no hay actividades en esta clase.',
            icon: Icons.assignment_outlined,
            color: AppColors.accentPurple,
            titleOf: (a) => a.name,
            subtitleOf: (a) => [
              a.activityType ?? 'Actividad',
              'Máx. ${a.maximumScore.toStringAsFixed(1)}',
            ].join(' · '),
            onOpen: (a) => context.push(RoutePaths.activityDetail(a.id)),
            onRetry: () => context.read<ActivitiesProvider>().load(
              teachingPeriodId: teachingPeriodId,
            ),
          ),
        ),
      ],
    );
  }
}

class _EvaluationList<T> extends StatelessWidget {
  const _EvaluationList({
    required this.state,
    required this.emptyText,
    required this.icon,
    required this.color,
    required this.titleOf,
    required this.subtitleOf,
    required this.onOpen,
    required this.onRetry,
  });

  final ListViewState<T> state;
  final String emptyText;
  final IconData icon;
  final Color color;
  final String Function(T) titleOf;
  final String Function(T) subtitleOf;
  final ValueChanged<T> onOpen;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return switch (state.status) {
      ViewStatus.success => Column(
        children: [
          for (final (i, item) in state.items.indexed) ...[
            if (i > 0) const Divider(height: 1),
            InkWell(
              onTap: () => onOpen(item),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    TintedIcon(icon: icon, color: color, size: 38),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titleOf(item),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(subtitleOf(item), style: textTheme.bodySmall),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: colors.onSurface.withValues(alpha: 0.4),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      ViewStatus.empty => Text(emptyText, style: textTheme.bodySmall),
      ViewStatus.error => Row(
        children: [
          Expanded(
            child: Text(
              'No pudimos cargar esta lista.',
              style: textTheme.bodySmall,
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
      _ => const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
    };
  }
}
