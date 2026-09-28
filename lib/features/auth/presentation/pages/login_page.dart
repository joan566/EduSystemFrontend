import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/layout/responsive.dart';
import '../desktop/login_desktop_view.dart';
import '../mobile/login_mobile_view.dart';
import '../providers/auth_provider.dart';
import '../shared/login_form.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Lets the same form State move between the mobile and desktop trees.
  final _formKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.consumeSessionExpiredFlag() && mounted) {
        context.showWarning('Tu sesión ha expirado. Inicia sesión de nuevo.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final form = LoginForm(key: _formKey);
    return Scaffold(
      body: ResponsiveBuilder(
        mobile: (_) => LoginMobileView(form: form),
        desktop: (_) => LoginDesktopView(form: form),
      ),
    );
  }
}
