import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/state/detail_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_loading.dart';
import '../../domain/entities/student_entity.dart';
import '../providers/students_provider.dart';
import '../shared/student_detail_widgets.dart';
import '../shared/student_grades_controller.dart';
import '../shared/student_status_chip.dart';
import 'widgets/student_enrollments_table.dart';
import 'widgets/student_grades_panel.dart';
import 'widgets/student_profile_cards.dart';

/// Desktop student record: breadcrumb line with the actions, the student's
/// name, then the profile (personal data + current course) always visible
/// in a side column while the main area switches between Notas and
/// Historial académico.
///
/// Mobile puts the profile in its own "Información" tab; here it never
/// hides, so the page tab 0 (Información) and 2 (Notas) both show Notas.
class StudentDetailDesktopView extends StatefulWidget {
  const StudentDetailDesktopView({
    super.key,
    required this.studentId,
    required this.tab,
    required this.onTabChanged,
    required this.grades,
  });

  final int studentId;

  /// The page's tab (mobile numbering, see the class doc).
  final int tab;
  final ValueChanged<int> onTabChanged;
  final StudentGradesController grades;

  static const _history = 1;
  static const _notas = 2;

  @override
  State<StudentDetailDesktopView> createState() =>
      _StudentDetailDesktopViewState();
}

class _StudentDetailDesktopViewState extends State<StudentDetailDesktopView>
    with SingleTickerProviderStateMixin {
  // Desktop tabs: 0 Notas, 1 Historial académico.
  late final TabController _tabs = TabController(
    length: 2,
    vsync: this,
    initialIndex: widget.tab == StudentDetailDesktopView._history ? 1 : 0,
  )..addListener(_onTabChanged);

  void _onTabChanged() {
    if (_tabs.indexIsChanging) return;
    setState(() {});
    final pageTab = _tabs.index == 1
        ? StudentDetailDesktopView._history
        : StudentDetailDesktopView._notas;
    if (pageTab != widget.tab) widget.onTabChanged(pageTab);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<StudentsProvider>().detail(widget.studentId);
    final detail = state.data;

    return Scaffold(
      body: switch (state.status) {
        DetailStatus.error => AppErrorState(
          exception: state.error!,
          onRetry: () =>
              context.read<StudentsProvider>().refreshDetail(widget.studentId),
        ),
        _ when detail == null => const AppLoading(),
        _ => _Workspace(detail: detail, tabs: _tabs, grades: widget.grades),
      },
    );
  }
}

class _Workspace extends StatelessWidget {
  const _Workspace({
    required this.detail,
    required this.tabs,
    required this.grades,
  });

  final StudentDetailEntity detail;
  final TabController tabs;
  final StudentGradesController grades;

  static const _railBesideMinWidth = 1100.0;
  static const _railWidth = 340.0;
  static const _railRowMinWidth = 820.0;

  @override
  Widget build(BuildContext context) {
    final tab = tabs.index == 1
        ? StudentEnrollmentsTable(detail: detail)
        : StudentGradesPanel(detail: detail, controller: grades);
    final rail = studentProfileCards(context, detail);

    return LayoutBuilder(
      builder: (context, constraints) {
        final railBeside = constraints.maxWidth >= _railBesideMinWidth;

        final main = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!railBeside) ...[
              // Profile cards above the tabs when there's no room for a
              // side column: in a row while they fit, stacked below that.
              if (constraints.maxWidth >= _railRowMinWidth)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (i, card) in rail.indexed) ...[
                        if (i > 0) const SizedBox(width: 16),
                        Expanded(child: card),
                      ],
                    ],
                  ),
                )
              else
                for (final (i, card) in rail.indexed) ...[
                  if (i > 0) const SizedBox(height: 16),
                  card,
                ],
              const SizedBox(height: 20),
            ],
            TabBar(
              controller: tabs,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.textPrimary,
              indicatorColor: AppColors.accentBlue,
              indicatorWeight: 3,
              dividerColor: Theme.of(context).colorScheme.outline,
              labelStyle: Theme.of(context).textTheme.labelLarge,
              tabs: [
                const Tab(text: 'Notas'),
                Tab(text: 'Historial académico (${detail.enrollments.length})'),
              ],
            ),
            const SizedBox(height: 20),
            tab,
          ],
        );

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            _Header(detail: detail),
            const SizedBox(height: 24),
            if (railBeside)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: _railWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final (i, card) in rail.indexed) ...[
                          if (i > 0) const SizedBox(height: 16),
                          card,
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(child: main),
                ],
              )
            else
              main,
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.detail});

  final StudentDetailEntity detail;

  Widget _actions(BuildContext context, {required bool alignEnd}) {
    final student = detail.student;
    final current = currentEnrollmentOf(detail);
    return Wrap(
      alignment: alignEnd ? WrapAlignment.end : WrapAlignment.start,
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (student.email.isNotEmpty)
          AppButton(
            label: 'Copiar correo',
            icon: Icons.alternate_email,
            variant: AppButtonVariant.outlined,
            onPressed: () =>
                StudentDetailActions.copy(context, 'Correo', student.email),
          ),
        if (current != null && current.active)
          AppButton(
            label: 'Retirar de ${current.courseLabel}',
            icon: Icons.person_remove_outlined,
            variant: AppButtonVariant.outlined,
            onPressed: () => StudentDetailActions.withdraw(
              context,
              studentId: student.id,
              enrollment: current,
            ),
          ),
        PopupMenuButton<int>(
          tooltip: 'Más acciones',
          icon: const Icon(Icons.more_horiz),
          onSelected: (value) => switch (value) {
            0 => StudentDetailActions.copy(
              context,
              'Código',
              student.studentCode,
            ),
            2 => StudentDetailActions.delete(context, student: student),
            _ => context.read<StudentsProvider>().refreshDetail(student.id),
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 0, child: Text('Copiar código')),
            const PopupMenuItem(value: 1, child: Text('Actualizar datos')),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 2,
              child: Text(
                'Eliminar estudiante',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final student = detail.student;
    final current = currentEnrollmentOf(detail);

    // Wide: actions share the breadcrumb line, the title gets its own.
    // Narrow: actions move below the title.
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => Navigator.of(context).canPop()
                      ? Navigator.of(context).pop()
                      : context.go(RoutePaths.students),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.arrow_back,
                          size: 16,
                          color: AppColors.accentBlue,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Estudiantes',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.accentBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (current != null) ...[
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: textTheme.bodySmall?.color,
                  ),
                  Text(current.courseLabel, style: textTheme.bodySmall),
                ],
                if (wide) ...[
                  const SizedBox(width: 16),
                  Expanded(child: _actions(context, alignEnd: true)),
                ],
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.accentBlue,
                  child: Text(
                    student.initials,
                    style: textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              student.fullName,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.headlineLarge,
                            ),
                          ),
                          const SizedBox(width: 12),
                          StudentStatusChip(enrollment: current),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          'Código ${student.studentCode}',
                          if (current != null)
                            '${current.courseLabel} · ${current.academicYear}',
                        ].join('  ·  '),
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!wide) ...[
              const SizedBox(height: 14),
              _actions(context, alignEnd: false),
            ],
          ],
        );
      },
    );
  }
}
