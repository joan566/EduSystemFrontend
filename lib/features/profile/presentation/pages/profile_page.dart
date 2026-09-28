import 'package:flutter/material.dart';

import '../../../../core/layout/responsive.dart';
import '../desktop/profile_desktop_view.dart';
import '../mobile/profile_mobile_view.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (_) => const ProfileMobileView(),
      desktop: (_) => const ProfileDesktopView(),
    );
  }
}
