import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/shared/brand_logo.dart';
import '../shared/auth_widgets.dart';

/// Mobile login: centered brand mark, then the form full width.
class LoginMobileView extends StatelessWidget {
  const LoginMobileView({super.key, required this.form});

  final Widget form;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            const Center(child: BrandLogo(size: 64)),
            const SizedBox(height: 22),
            Text(
              'EduSistem',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Gestión académica para profesores',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            form,
            const SizedBox(height: 20),
            const AuthRegisterLink(),
            const SizedBox(height: 20),
            const AuthTrustRow(color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
