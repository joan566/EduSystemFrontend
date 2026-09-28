import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../shared/dashboard_state.dart';

/// Light hero: today's date, a greeting with the teacher's name, a one-line
/// summary, and a decorative illustration built from icons.
class GreetingHero extends StatelessWidget {
  const GreetingHero({super.key, required this.date, required this.isBrandNew});

  final DateTime date;
  final bool isBrandNew;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final textTheme = Theme.of(context).textTheme;
    final greeting = greetingForNow();

    return Container(
      padding: const EdgeInsets.fromLTRB(28, 24, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accentBlue.withValues(alpha: 0.10),
            AppColors.accentBlue.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${Formatters.longDayMonth(date)} de ${date.year}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  user == null ? greeting : '$greeting, ${user.firstName}',
                  style: textTheme.displayLarge?.copyWith(
                    color: AppColors.primaryDarkest,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isBrandNew
                      ? 'Configuremos tu espacio de trabajo para empezar a evaluar.'
                      : 'Aquí tienes un resumen de tu actividad académica y lo '
                            'más importante de hoy.',
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const _Illustration(),
        ],
      ),
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: 190,
        height: 120,
        child: Stack(
          children: [
            Positioned(
              right: 10,
              bottom: 0,
              child: Container(
                width: 150,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(60),
                ),
              ),
            ),
            Positioned(
              left: 18,
              bottom: 6,
              child: Icon(
                Icons.local_florist_outlined,
                size: 58,
                color: AppColors.accentGreen.withValues(alpha: 0.8),
              ),
            ),
            Positioned(
              right: 22,
              bottom: 2,
              child: Icon(
                Icons.menu_book_rounded,
                size: 84,
                color: AppColors.accentBlue.withValues(alpha: 0.55),
              ),
            ),
            const Positioned(
              right: 30,
              top: 0,
              child: Icon(
                Icons.school_rounded,
                size: 64,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
