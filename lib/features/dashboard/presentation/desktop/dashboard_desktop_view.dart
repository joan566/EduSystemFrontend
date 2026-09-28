import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../schedule/presentation/providers/schedule_provider.dart';
import '../providers/dashboard_provider.dart';
import '../shared/dashboard_state.dart';
import '../shared/getting_started_card.dart';
import 'widgets/activity_rail.dart';
import 'widgets/classes_grid_card.dart';
import 'widgets/greeting_hero.dart';
import 'widgets/next_class_card.dart';
import 'widgets/quick_actions_card.dart';
import 'widgets/stats_strip.dart';
import 'widgets/today_card.dart';

/// Desktop home: greeting hero and counts on top; "Hoy" and the classes
/// grid beside the next class and quick actions; recent activity as a
/// right rail.
///
/// The desktop family spans very different content widths (tablet rail,
/// collapsed or expanded sidebar, any window size), so this grid places
/// its columns by available width — the right rail drops below the main
/// column when there's no room beside it. That's desktop reflow, not a
/// mobile fork: phones get `DashboardMobileView`.
class DashboardDesktopView extends StatelessWidget {
  const DashboardDesktopView({super.key});

  static const _gap = 20.0;
  static const _railWidth = 340.0;

  /// Content width from which the activity rail sits beside the main
  /// column.
  static const _railBesideMinWidth = 1180.0;

  /// Main-column width from which the main column splits in two.
  static const _splitMinWidth = 860.0;

  /// Below the split, width from which the next-class and quick-actions
  /// cards still sit side by side.
  static const _pairMinWidth = 560.0;

  @override
  Widget build(BuildContext context) {
    final isBrandNew = watchIsBrandNewTeacher(context);
    final date =
        context.watch<ScheduleProvider>().today.data?.date ?? DateTime.now();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => context.read<DashboardProvider>().loadAll(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final railBeside = constraints.maxWidth >= _railBesideMinWidth;
            final contentWidth = constraints.maxWidth - 2 * 24;
            final mainWidth = railBeside
                ? contentWidth - _railWidth - _gap
                : contentWidth;

            final main = _MainColumn(
              isBrandNew: isBrandNew,
              date: date,
              split: mainWidth >= _splitMinWidth,
              pairSideCards: mainWidth >= _pairMinWidth,
            );

            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              children: [
                if (isBrandNew)
                  main
                else if (railBeside)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: main),
                      const SizedBox(width: _gap),
                      const SizedBox(width: _railWidth, child: ActivityRail()),
                    ],
                  )
                else ...[
                  main,
                  const SizedBox(height: _gap),
                  const ActivityRail(),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MainColumn extends StatelessWidget {
  const _MainColumn({
    required this.isBrandNew,
    required this.date,
    required this.split,
    required this.pairSideCards,
  });

  final bool isBrandNew;
  final DateTime date;
  final bool split;
  final bool pairSideCards;

  static const _gap = DashboardDesktopView._gap;

  @override
  Widget build(BuildContext context) {
    const side = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NextClassCard(),
        SizedBox(height: _gap),
        QuickActionsCard(),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GreetingHero(date: date, isBrandNew: isBrandNew),
        const SizedBox(height: _gap),
        if (isBrandNew)
          const GettingStartedCard()
        else ...[
          const StatsStrip(),
          const SizedBox(height: _gap),
          if (split)
            // "Hoy" and the classes grid on the left; next class and quick
            // actions stacked on the right.
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TodayCard(),
                      SizedBox(height: _gap),
                      ClassesGridCard(),
                    ],
                  ),
                ),
                SizedBox(width: _gap),
                Expanded(flex: 2, child: side),
              ],
            )
          else ...[
            const TodayCard(),
            const SizedBox(height: _gap),
            if (pairSideCards)
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: NextClassCard()),
                  SizedBox(width: _gap),
                  Expanded(child: QuickActionsCard()),
                ],
              )
            else
              side,
            const SizedBox(height: _gap),
            const ClassesGridCard(),
          ],
        ],
      ],
    );
  }
}
