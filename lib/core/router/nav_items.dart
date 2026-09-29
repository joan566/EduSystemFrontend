import 'package:flutter/material.dart';

import 'route_paths.dart';

/// A single navigation destination shared by the desktop sidebar, tablet
/// rail, and the mobile bottom nav / "More" page. One source of truth for
/// icon + label + path, so each shell only decides layout (§66, §107).
class NavItem {
  const NavItem({
    required this.path,
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String path;
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

/// Primary items: always visible (bottom nav on mobile, rail on tablet,
/// top of the sidebar on desktop). Kept short on purpose (§18: no giant
/// sidebar; §19: prioritize the teacher's real day-to-day tasks).
const primaryNavItems = <NavItem>[
  NavItem(
    path: RoutePaths.dashboard,
    label: 'Inicio',
    icon: Icons.dashboard_outlined,
    activeIcon: Icons.dashboard,
  ),
  NavItem(
    path: RoutePaths.teaching,
    label: 'Clases',
    icon: Icons.groups_outlined,
    activeIcon: Icons.groups,
  ),
  NavItem(
    path: RoutePaths.exams,
    label: 'Exámenes',
    icon: Icons.fact_check_outlined,
    activeIcon: Icons.fact_check,
  ),
  NavItem(
    path: RoutePaths.students,
    label: 'Estudiantes',
    icon: Icons.people_alt_outlined,
    activeIcon: Icons.people_alt,
  ),
];

/// The teacher's weekly agenda. Desktop lists it right after the primary
/// items; mobile/tablet reach it from "Más" and from the dashboard.
const scheduleNavItem = NavItem(
  path: RoutePaths.schedule,
  label: 'Horario',
  icon: Icons.calendar_today_outlined,
  activeIcon: Icons.calendar_today,
);

/// Secondary items: desktop shows them in a second sidebar section; mobile
/// and tablet group them under "Más" (§19).
const secondaryNavItems = <NavItem>[
  NavItem(
    path: RoutePaths.activities,
    label: 'Actividades',
    icon: Icons.assignment_outlined,
    activeIcon: Icons.assignment,
  ),
  NavItem(
    path: RoutePaths.attendance,
    label: 'Asistencia',
    icon: Icons.checklist_outlined,
    activeIcon: Icons.checklist,
  ),
  NavItem(
    path: RoutePaths.grades,
    label: 'Calificaciones',
    icon: Icons.grade_outlined,
    activeIcon: Icons.grade,
  ),
];

/// Academic catalog — shared, less frequently edited data.
const catalogNavItems = <NavItem>[
  NavItem(
    path: RoutePaths.subjects,
    label: 'Materias',
    icon: Icons.menu_book_outlined,
    activeIcon: Icons.menu_book,
  ),
  NavItem(
    path: RoutePaths.courses,
    label: 'Cursos',
    icon: Icons.class_outlined,
    activeIcon: Icons.class_,
  ),
  NavItem(
    path: RoutePaths.periods,
    label: 'Periodos académicos',
    icon: Icons.calendar_month_outlined,
    activeIcon: Icons.calendar_month,
  ),
  NavItem(
    path: RoutePaths.academicLevels,
    label: 'Grados académicos',
    icon: Icons.school_outlined,
    activeIcon: Icons.school,
  ),
];

/// Setup that shapes how the teacher evaluates, edited rarely (grading
/// weights live here, apart from the day-to-day grades).
const settingsNavItems = <NavItem>[
  NavItem(
    path: RoutePaths.gradingSettings,
    label: 'Configuración de notas',
    icon: Icons.tune_outlined,
    activeIcon: Icons.tune,
  ),
];

/// System / data-management utilities.
const systemNavItems = <NavItem>[
  NavItem(
    path: RoutePaths.dataManagement,
    label: 'Importar y exportar',
    icon: Icons.import_export_outlined,
    activeIcon: Icons.import_export,
  ),
  NavItem(
    path: RoutePaths.audit,
    label: 'Auditoría',
    icon: Icons.history_outlined,
    activeIcon: Icons.history,
  ),
];

const profileNavItem = NavItem(
  path: RoutePaths.profile,
  label: 'Perfil',
  icon: Icons.person_outline,
  activeIcon: Icons.person,
);

/// All destinations shown on the mobile/tablet "More" page, in one list.
List<NavItem> get moreNavItems => [
  scheduleNavItem,
  ...secondaryNavItems,
  ...catalogNavItems,
  ...settingsNavItems,
  ...systemNavItems,
  profileNavItem,
];

/// Whether [item] is the destination for [currentPath]. The dashboard only
/// matches exactly; every other item also matches its nested routes.
bool isNavItemActive(String currentPath, NavItem item) {
  if (item.path == RoutePaths.dashboard) return currentPath == item.path;
  return currentPath.startsWith(item.path);
}
