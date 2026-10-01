import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../core/router/route_paths.dart';
import '../desktop/auth_desktop_card.dart';
import '../shared/verify_email_form.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  // Keeps the typed code when switching between mobile and desktop layouts.
  final _formKey = GlobalKey();

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = VerifyEmailForm(key: _formKey);
    return ResponsiveBuilder(
      mobile: (_) => Scaffold(
        appBar: AppBar(leading: BackButton(onPressed: _back)),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: form,
          ),
        ),
      ),
      desktop: (_) => AuthDesktopCard(onBack: _back, child: form),
    );
  }
}
