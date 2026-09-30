import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/route_paths.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/subject_visuals.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/mobile/mobile_skeletons.dart';
import '../../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../../core/widgets/shared/skeleton/skeleton_blocks.dart';
import '../../../../../core/widgets/shared/tinted_icon.dart';
import '../../../../grades/presentation/shared/category_visuals.dart';
import '../../../domain/entities/student_entity.dart';
import '../../shared/student_grades_controller.dart';

/// "Notas": the student's period grade in each of the teacher's classes of
/// their courses, with the per-category breakdown.
class StudentGradesTab extends StatefulWidget {
  const StudentGradesTab({
    super.key,
    required this.detail,
    required this.controller,
  });

  final StudentDetailEntity detail;
  final StudentGradesController controller;

  @override
  State<StudentGradesTab> createState() => _StudentGradesTabState();
}

class _StudentGradesTabState extends State<StudentGradesTab> {
  @override
  void initState() {
    super.initState();
    // Built only once the tab is first shown, so the grades (one request
    // per class) are fetched on demand.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.controller.ensureLoaded(widget.detail),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final grades = widget.controller.grades;
        if (grades == null) {
          return const MobileListSkeleton(
            itemCount: 4,
            leading: SkeletonLeading.square,
            leadingSize: 40,
            trailingWidth: 56,
            bar: true,
            radius: 16,
            padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
          );
        }
        if (grades.isEmpty) {
          return const AppEmptyState(
            title: 'Sin clases con este estudiante',
            message:
                'No dictas clases en los cursos en los que está o estuvo '
                'matriculado.',
            icon: Icons.menu_book_outlined,
          );
        }
        return RefreshIndicator(
          onRefresh: () => widget.controller.reload(widget.detail),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              for (final grade in grades)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ClassGradeCard(
                    grade: grade,
                    studentId: widget.detail.student.id,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ClassGradeCard extends StatelessWidget {
  const _ClassGradeCard({required this.grade, required this.studentId});

  final StudentClassGrade grade;
  final int studentId;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final period = grade.period;
    final scale = grade.scale;
    final value = grade.grade?.periodGrade;
    final fraction = value != null && scale != null
        ? ((value - scale.minimumValue) /
                  (scale.maximumValue - scale.minimumValue))
              .clamp(0.0, 1.0)
        : null;

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // The student's grade evaluation by evaluation; a class without
        // weights goes to its grading setup instead.
        onTap: () => context.push(
          grade.needsConfiguration
              ? RoutePaths.gradingSettingsForClass(period.id)
              : RoutePaths.studentGrades(period.id, studentId),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  TintedIcon(
                    icon: subjectIcon(period.subjectName),
                    color: subjectAccent(period.subjectId),
                    size: 40,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          period.subjectName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium,
                        ),
                        Text(
                          '${period.courseLabel}  ·  ${period.academicPeriodName}',
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (value != null && scale != null)
                    Text.rich(
                      TextSpan(
                        text: value.toStringAsFixed(1),
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        children: [
                          TextSpan(
                            text: ' / ${scale.maximumValue.toStringAsFixed(1)}',
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (grade.needsConfiguration)
                _Note(
                  icon: Icons.tune,
                  text:
                      'Configura la escala y los pesos de esta clase para '
                      'calcular la nota.',
                  color: AppColors.warning,
                )
              else if (grade.error != null)
                const _Note(
                  icon: Icons.error_outline,
                  text: 'No se pudo cargar la nota de esta clase.',
                  color: AppColors.error,
                )
              else if (grade.grade == null)
                const _Note(
                  icon: Icons.info_outline,
                  text: 'El estudiante no tiene notas en esta clase.',
                  color: AppColors.textSecondary,
                )
              else ...[
                if (fraction != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 6,
                      color: AppColors.accentBlue,
                      backgroundColor: AppColors.accentBlue.withValues(
                        alpha: 0.12,
                      ),
                    ),
                  )
                else
                  Text('Aún sin nota definitiva.', style: textTheme.bodySmall),
                const SizedBox(height: 10),
                for (final category in grade.grade!.categories)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${categoryLabel(category.categoryName)}  ·  '
                            '${category.weight.toStringAsFixed(0)}%',
                            style: textTheme.bodySmall,
                          ),
                        ),
                        Text(
                          category.gradeOnScale != null && scale != null
                              ? Formatters.grade(
                                  category.gradeOnScale!,
                                  scale.maximumValue,
                                  decimals: 1,
                                )
                              : category.evaluationCount == 0
                              ? 'Sin evaluaciones'
                              : '—',
                          style: textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}
