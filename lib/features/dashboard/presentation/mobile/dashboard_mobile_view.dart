import 'package:flutter/material.dart';

import '../../../../core/widgets/mobile/mobile_brand_bar.dart';
import '../shared/dashboard_data.dart';
import '../shared/dashboard_state.dart';
import '../shared/getting_started_card.dart';
import 'widgets/classes_carousel_section.dart';
import 'widgets/quick_actions_section.dart';
import 'widgets/recent_activity_section.dart';
import 'widgets/today_section.dart';

/// Mobile home: brand bar, today's classes, quick actions, the teacher's
/// classes as a carousel, and recent activity — action-first, one column
/// of sections.
class DashboardMobileView extends StatelessWidget {
  const DashboardMobileView({super.key});

  @override
  Widget build(BuildContext context) {
    final isBrandNew = watchIsBrandNewTeacher(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => refreshDashboardData(context),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const MobileBrandBar(),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: isBrandNew
                  ? const GettingStartedCard()
                  : const Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TodaySection(),
                        SizedBox(height: 14),
                        QuickActionsSection(),
                        SizedBox(height: 14),
                        ClassesCarouselSection(),
                        SizedBox(height: 14),
                        RecentActivitySection(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
