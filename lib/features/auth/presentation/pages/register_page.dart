import 'package:flutter/material.dart';

import '../../../../core/layout/responsive.dart';
import '../desktop/register_desktop_view.dart';
import '../mobile/register_mobile_view.dart';
import '../shared/register_form.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // A GlobalKey lets the same form State move between the mobile and
  // desktop trees, so typed values survive a layout switch.
  final _formKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final form = RegisterForm(key: _formKey);
    return ResponsiveBuilder(
      mobile: (_) => RegisterMobileView(form: form),
      desktop: (_) => RegisterDesktopView(form: form),
    );
  }
}
