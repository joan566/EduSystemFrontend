import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/course_entity.dart';

/// A course as a badge: its grade on top, the group big below ("5°" / "A"),
/// tinted by grade so courses of the same grade match.
class CourseBadge extends StatelessWidget {
  const CourseBadge({super.key, required this.course, this.size = 48});

  final CourseEntity course;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.accents[course.gradeId % AppColors.accents.length];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            course.gradeName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: size * 0.2,
              color: color,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
          Text(
            course.name,
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: TextStyle(
              fontSize: size * 0.36,
              color: color,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
