import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../shared/auth_widgets.dart';

/// Desktop login: brand panel on the left, credentials card on the right.
class LoginDesktopView extends StatelessWidget {
  const LoginDesktopView({super.key, required this.form});

  final Widget form;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.brandGradient,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  top: -80,
                  right: -60,
                  child: _GlowCircle(size: 280, opacity: 0.10),
                ),
                Positioned(
                  bottom: -100,
                  left: -70,
                  child: _GlowCircle(size: 320, opacity: 0.08),
                ),
                Padding(
                  padding: const EdgeInsets.all(56),
                  child: const _BrandingPanel(),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: ColoredBox(
            color: AppColors.background,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Container(
                    padding: const EdgeInsets.all(36),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.shadowMedium,
                          blurRadius: 32,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: _LoginCardContent(form: form),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Soft radial-looking accent used to add depth to the branding panel
/// without competing with its text content.
class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

class _LoginCardContent extends StatelessWidget {
  const _LoginCardContent({required this.form});

  final Widget form;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.accentBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.lock_outline,
            color: AppColors.accentBlue,
            size: 22,
          ),
        ),
        const SizedBox(height: 20),
        Text('Inicia sesión', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 6),
        Text(
          'Ingresa tus credenciales para continuar.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),
        form,
        const SizedBox(height: 20),
        const AuthRegisterLink(),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        const AuthTrustRow(color: AppColors.textSecondary),
      ],
    );
  }
}

class _BrandingPanel extends StatelessWidget {
  const _BrandingPanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
              ),
              child: const Icon(
                Icons.school_outlined,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'EduSistem',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const Spacer(),
        const Text(
          'Gestiona tus cursos,\nexámenes y calificaciones\nen un solo lugar.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            height: 1.22,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Estudiantes, exámenes, escaneo de hojas de respuesta, '
          'calificaciones y asistencia, todo integrado.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: 15,
            height: 1.5,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: Colors.white.withValues(alpha: 0.85),
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tus datos están cifrados y protegidos en todo momento.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
