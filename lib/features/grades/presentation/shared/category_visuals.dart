import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// How an evaluation category is shown: the backend names them by code
/// (EXAMS, ACTIVITIES, ATTENDANCE); any other category keeps its name.
class CategoryVisuals {
  const CategoryVisuals({
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String label;
  final String description;
  final IconData icon;
  final Color color;
}

CategoryVisuals categoryVisuals(String name, {String? description}) =>
    switch (name) {
      'EXAMS' => const CategoryVisuals(
        label: 'Exámenes',
        description: 'Exámenes de selección múltiple calificados al escanear',
        icon: Icons.description_outlined,
        color: AppColors.accentBlue,
      ),
      'ACTIVITIES' => const CategoryVisuals(
        label: 'Actividades',
        description: 'Tareas, talleres, trabajos y proyectos',
        icon: Icons.assignment_outlined,
        color: AppColors.accentTeal,
      ),
      'ATTENDANCE' => const CategoryVisuals(
        label: 'Asistencia',
        description:
            'Presente cuenta el puntaje completo; con excusa no cuenta',
        icon: Icons.groups_outlined,
        color: AppColors.accentPurple,
      ),
      _ => CategoryVisuals(
        label: name,
        description: description ?? '',
        icon: Icons.star_outline_rounded,
        color: AppColors.accentOrange,
      ),
    };

String categoryLabel(String name) => categoryVisuals(name).label;
