import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/state/detail_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/mobile/mobile_form.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_loading.dart';
import '../../domain/entities/student_entity.dart';
import '../providers/students_provider.dart';
import '../shared/student_detail_widgets.dart';
import '../shared/student_grades_controller.dart';
import '../shared/student_status_chip.dart';
import 'widgets/student_grades_tab.dart';
import 'widgets/student_history_tab.dart';
import 'widgets/student_info_tab.dart';

/// Mobile student screen: back + title + more, the student's avatar, name,
/// code, course and status, then Información / Historial académico /
/// Notas tabs.
class StudentDetailMobileView extends StatefulWidget {
  const StudentDetailMobileView({
    super.key,
    required this.studentId,
    required this.tab,
    required this.onTabChanged,
    required this.grades,
  });

  final int studentId;

  /// Selected tab, owned by the page so it survives a layout switch.
  final int tab;
  final ValueChanged<int> onTabChanged;
  final StudentGradesController grades;

  @override
  State<StudentDetailMobileView> createState() =>
      _StudentDetailMobileViewState();
}

class _StudentDetailMobileViewState extends State<StudentDetailMobileView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: 3,
    vsync: this,
    initialIndex: widget.tab,
  )..addListener(_onTabChanged);

  void _onTabChanged() {
    if (!_tabs.indexIsChanging && _tabs.index != widget.tab) {
      widget.onTabChanged(_tabs.index);
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _openMore(StudentDetailEntity detail) async {
    final student = detail.student;
    final current = currentEnrollmentOf(detail);
    final choice = await showMobileSheet<int>(
      context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('Copiar código'),
              subtitle: Text(student.studentCode),
              onTap: () => Navigator.of(context).pop(0),
            ),
            if (student.email.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.alternate_email),
                title: const Text('Copiar correo'),
                subtitle: Text(student.email),
                onTap: () => Navigator.of(context).pop(1),
              ),
            if (current != null && current.active)
              ListTile(
                leading: Icon(
                  Icons.person_remove_outlined,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text('Retirar de ${current.courseLabel}'),
                subtitle: const Text('Se conserva su historial'),
                onTap: () => Navigator.of(context).pop(2),
              ),
            ListTile(
              leading: Icon(
                Icons.delete_forever_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Eliminar estudiante',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              subtitle: const Text('Borra todos sus datos, sin deshacer'),
              onTap: () => Navigator.of(context).pop(3),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case 0:
        await StudentDetailActions.copy(context, 'Código', student.studentCode);
      case 1:
        await StudentDetailActions.copy(context, 'Correo', student.email);
      case 2:
        await StudentDetailActions.withdraw(
          context,
          studentId: student.id,
          enrollment: current!,
        );
      case 3:
        await StudentDetailActions.delete(context, student: student);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<StudentsProvider>().detailState;
    final detail = state.data?.student.id == widget.studentId
        ? state.data
        : null;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
            child: Row(
              children: [
                const BackButton(),
                const SizedBox(width: 4),
                Expanded(
                  child: Text('Estudiante', style: textTheme.titleLarge),
                ),
                if (detail != null)
                  IconButton(
                    tooltip: 'Más opciones',
                    onPressed: () => _openMore(detail),
                    icon: const Icon(Icons.more_vert),
                  ),
              ],
            ),
          ),
          Expanded(
            child: switch (state.status) {
              DetailStatus.error => AppErrorState(
                exception: state.error!,
                onRetry: () => context.read<StudentsProvider>().loadDetail(
                  widget.studentId,
                ),
              ),
              _ when detail == null => const AppLoading(),
              _ => _Content(detail: detail, tabs: _tabs, grades: widget.grades),
            },
          ),
        ],
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.detail,
    required this.tabs,
    required this.grades,
  });

  final StudentDetailEntity detail;
  final TabController tabs;
  final StudentGradesController grades;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 16, 16),
          child: _Hero(detail: detail),
        ),
        TabBar(
          controller: tabs,
          labelColor: AppColors.accentBlue,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.accentBlue,
          indicatorWeight: 3,
          dividerColor: Theme.of(context).colorScheme.outline,
          labelStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: textTheme.labelLarge,
          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
          tabs: const [
            Tab(text: 'Información'),
            Tab(text: 'Historial académico'),
            Tab(text: 'Notas'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: tabs,
            children: [
              StudentInfoTab(detail: detail),
              StudentHistoryTab(detail: detail),
              StudentGradesTab(detail: detail, controller: grades),
            ],
          ),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.detail});

  final StudentDetailEntity detail;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final student = detail.student;
    final current = currentEnrollmentOf(detail);

    return Row(
      children: [
        // Soft ring around the avatar, as in the list's badge.
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accentBlue.withValues(alpha: 0.06),
          ),
          child: CircleAvatar(
            radius: 38,
            backgroundColor: AppColors.accentBlue.withValues(alpha: 0.12),
            child: Text(
              student.initials,
              style: textTheme.headlineSmall?.copyWith(
                color: AppColors.accentBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                student.fullName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Código: ${student.studentCode}',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (current != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.class_outlined, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            current.courseLabel,
                            style: textTheme.labelMedium,
                          ),
                        ],
                      ),
                    ),
                  StudentStatusChip(enrollment: current),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
