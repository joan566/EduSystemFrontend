import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/academic_level_entity.dart';
import 'level_usage.dart';

/// A level's number (or initials) in a tinted square with a degree mark.
class LevelBadge extends StatelessWidget {
  const LevelBadge({super.key, required this.level, this.size = 48});

  final AcademicLevelEntity level;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.accents[level.id % AppColors.accents.length];
    final mark = levelMark(level);
    final numeric = int.tryParse(mark) != null;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Text(
        numeric ? '$mark°' : mark,
        style: TextStyle(
          fontSize: size * (mark.length > 2 ? 0.28 : 0.38),
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
