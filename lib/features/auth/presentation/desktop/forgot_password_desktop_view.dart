import 'package:flutter/material.dart';

import 'auth_desktop_card.dart';

class ForgotPasswordDesktopView extends StatelessWidget {
  const ForgotPasswordDesktopView({
    super.key,
    required this.onBack,
    required this.content,
  });

  final VoidCallback onBack;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return AuthDesktopCard(onBack: onBack, child: content);
  }
}
