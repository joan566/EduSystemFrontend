import 'package:flutter/material.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';

/// A shortcut to a frequent task. It opens the screen where that task
/// starts (picking the class happens there).
class DashboardQuickAction {
  const DashboardQuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.path,
  });

  final String label;
  final IconData icon;
  final Color color;
  final String path;
}

/// The teacher's most frequent tasks, shown by both dashboards.
const dashboardQuickActions = [
  DashboardQuickAction(
    label: 'Crear examen',
    icon: Icons.description_outlined,
    color: AppColors.accentBlue,
    path: RoutePaths.exams,
  ),
  DashboardQuickAction(
    label: 'Importar estudiantes',
    icon: Icons.person_add_alt_1_outlined,
    color: AppColors.accentGreen,
    path: RoutePaths.dataManagement,
  ),
  DashboardQuickAction(
    label: 'Nueva actividad',
    icon: Icons.assignment_add,
    color: AppColors.accentPurple,
    path: RoutePaths.activities,
  ),
  DashboardQuickAction(
    label: 'Tomar asistencia',
    icon: Icons.event_available_outlined,
    color: AppColors.accentTeal,
    path: RoutePaths.attendance,
  ),
];
