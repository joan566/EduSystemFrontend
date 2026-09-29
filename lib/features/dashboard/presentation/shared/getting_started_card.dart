import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/shared/app_card.dart';

/// Brand-new account: a single guided checklist instead of stat cards full
/// of zeros and empty-state cards stacked with no shared narrative.
class GettingStartedCard extends StatelessWidget {
  const GettingStartedCard({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.accentBlue.withValues(alpha: 0.12),
                      AppColors.accentBlue.withValues(alpha: 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.rocket_launch_outlined,
                  color: AppColors.accentBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Primeros pasos', style: textTheme.titleMedium),
                    const SizedBox(height: 3),
                    Text(
                      'Todavía no tienes cursos, estudiantes ni clases '
                      'registradas. Sigue estos pasos para empezar a '
                      'evaluar.',
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _GettingStartedStep(
            number: 1,
            title: 'Crea tus cursos',
            subtitle: 'Registra los grupos que vas a enseñar (ej. 10-A).',
            actionLabel: 'Ir a Cursos',
            onTap: () => context.push(RoutePaths.courses),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1),
          ),
          _GettingStartedStep(
            number: 2,
            title: 'Agrega tus estudiantes',
            subtitle: 'Registra o importa los estudiantes de cada curso.',
            actionLabel: 'Ir a Estudiantes',
            onTap: () => context.push(RoutePaths.students),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1),
          ),
          _GettingStartedStep(
            number: 3,
            title: 'Crea tus asignaciones de clase',
            subtitle:
                'Vincula una materia, un curso y un periodo para poder '
                'evaluar.',
            actionLabel: 'Ir a Clases',
            onTap: () => context.push(RoutePaths.teaching),
          ),
        ],
      ),
    );
  }
}

class _GettingStartedStep extends StatelessWidget {
  const _GettingStartedStep({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  final int number;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Text('$number', style: textTheme.labelMedium),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(subtitle, style: textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(width: 8),
        TextButton(onPressed: onTap, child: Text(actionLabel)),
      ],
    );
  }
}
