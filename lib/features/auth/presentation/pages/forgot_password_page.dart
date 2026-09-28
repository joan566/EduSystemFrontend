import 'package:flutter/material.dart';

import '../../../../core/layout/responsive.dart';
import '../desktop/forgot_password_desktop_view.dart';
import '../mobile/forgot_password_mobile_view.dart';
import '../shared/forgot_password_flow.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    // The flow's state sits above the layout fork so a resize mid-flow
    // keeps the current step.
    return ForgotPasswordFlow(
      builder: (context, onBack, content) => ResponsiveBuilder(
        mobile: (_) =>
            ForgotPasswordMobileView(onBack: onBack, content: content),
        desktop: (_) =>
            ForgotPasswordDesktopView(onBack: onBack, content: content),
      ),
    );
  }
}
