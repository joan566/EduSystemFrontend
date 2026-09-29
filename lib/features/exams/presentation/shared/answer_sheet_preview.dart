import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../teaching/domain/entities/teaching_period_entity.dart';
import '../../domain/entities/exam_entity.dart';

/// A miniature answer sheet drawn from the exam's real shape: class,
/// the first [maxRows] questions and its option letters. Drawn at a base
/// size and scaled to [width], so text stays sharp at any size.
class AnswerSheetPreview extends StatelessWidget {
  const AnswerSheetPreview({
    super.key,
    required this.exam,
    required this.period,
    this.width = 200,
    this.maxRows = 5,
  });

  final ExamEntity exam;
  final TeachingPeriodEntity? period;
  final double width;
  final int maxRows;

  // Paper stays white in dark mode too: it depicts the printed sheet.
  static const _paper = AppColors.surface;
  static const _ink = AppColors.textPrimary;
  static const _line = AppColors.border;
  static const _baseWidth = 200.0;

  @override
  Widget build(BuildContext context) {
    final letters = [
      for (var i = 0; i < (exam.optionCount == 0 ? 4 : exam.optionCount); i++)
        String.fromCharCode(65 + i),
    ].take(5).toList();
    final rows = exam.numberOfQuestions.clamp(1, maxRows);
    final more = exam.numberOfQuestions - rows;
    final period = this.period;

    Widget page({required Widget child}) => Container(
      width: 170,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _line),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    const tiny = TextStyle(fontSize: 7, color: _ink);
    final sheet = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Row(
          children: [
            Icon(Icons.school_rounded, size: 9, color: AppColors.accentBlue),
            SizedBox(width: 3),
            Text(
              'EduSistem',
              style: TextStyle(
                fontSize: 6,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Hoja de respuesta',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
        ),
        if (period != null)
          Text(
            '${period.subjectName} — ${period.courseLabel}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tiny.copyWith(color: AppColors.textSecondary),
          ),
        const SizedBox(height: 8),
        for (final field in const ['Nombre:', 'Fecha:'])
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Text(field, style: tiny.copyWith(fontSize: 6)),
                const SizedBox(width: 4),
                const Expanded(child: Divider(height: 6, color: _line)),
              ],
            ),
          ),
        const SizedBox(height: 6),
        for (var q = 1; q <= rows; q++)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              children: [
                SizedBox(
                  width: 14,
                  child: Text(
                    '$q.',
                    style: tiny.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                for (final letter in letters)
                  Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.only(right: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _ink.withValues(alpha: 0.5),
                        width: 0.8,
                      ),
                    ),
                    child: Text(letter, style: tiny.copyWith(fontSize: 5)),
                  ),
              ],
            ),
          ),
        if (more > 0)
          Text(
            more == 1 ? '+ 1 pregunta más' : '+ $more preguntas más',
            style: tiny.copyWith(fontSize: 6, color: AppColors.textSecondary),
          ),
      ],
    );

    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        child: FittedBox(
          fit: BoxFit.fitWidth,
          child: SizedBox(
            width: _baseWidth,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // A second sheet peeking out behind: "one per student".
                Positioned(
                  left: 24,
                  top: 8,
                  bottom: -8,
                  child: page(child: const SizedBox.shrink()),
                ),
                page(child: sheet),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
