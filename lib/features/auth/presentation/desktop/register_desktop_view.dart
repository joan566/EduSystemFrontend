import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'auth_desktop_card.dart';

class RegisterDesktopView extends StatelessWidget {
  const RegisterDesktopView({super.key, required this.form});

  final Widget form;

  @override
  Widget build(BuildContext context) {
    return AuthDesktopCard(
      maxWidth: 480,
      onBack: () => context.pop(),
      child: form,
    );
  }
}
