import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_text_field.dart';
import '../providers/auth_provider.dart';

/// Email verification after sign-up (or after a login rejected with
/// `EMAIL_NOT_VERIFIED`): 6-digit code + resend. On success the user goes
/// to /login, since verifying doesn't open a session.
class VerifyEmailForm extends StatefulWidget {
  const VerifyEmailForm({super.key});

  @override
  State<VerifyEmailForm> createState() => _VerifyEmailFormState();
}

class _VerifyEmailFormState extends State<VerifyEmailForm> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _verifying = false;
  bool _resending = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify(AuthProvider auth) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _verifying = true);
    final ok = await auth.verifyEmail(_codeController.text.trim());
    if (!mounted) return;
    setState(() => _verifying = false);
    if (ok) {
      context.showSuccess('Correo verificado. Ya puedes iniciar sesión.');
      context.go(RoutePaths.login);
    } else if (auth.error != null) {
      context.showApiError(auth.error!);
    }
  }

  Future<void> _resend(AuthProvider auth) async {
    setState(() => _resending = true);
    final ok = await auth.resendVerification();
    if (!mounted) return;
    setState(() => _resending = false);
    if (ok) {
      _codeController.clear();
      context.showSuccess('Te enviamos un nuevo código.');
    } else if (auth.error != null) {
      context.showApiError(auth.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final email = auth.pendingVerificationEmail;
    final textTheme = Theme.of(context).textTheme;

    if (email == null) {
      // e.g. a page reload: there is no account waiting for verification.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Verifica tu correo', style: textTheme.headlineLarge),
          const SizedBox(height: 6),
          Text(
            'Inicia sesión con tu cuenta para verificar tu correo.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Ir a iniciar sesión',
            expand: true,
            onPressed: () => context.go(RoutePaths.login),
          ),
        ],
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Verifica tu correo', style: textTheme.headlineLarge),
          const SizedBox(height: 6),
          Text(
            'Ingresa el código de 6 dígitos que enviamos a $email. '
            'Si expiró, pide uno nuevo.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 28),
          AppTextField(
            controller: _codeController,
            label: 'Código de verificación',
            required: true,
            keyboardType: TextInputType.number,
            hint: '123456',
            maxLength: 6,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _verify(auth),
            validator: (v) {
              if (v == null || !RegExp(r'^\d{6}$').hasMatch(v.trim())) {
                return 'El código debe tener 6 dígitos.';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Verificar correo',
            isLoading: _verifying,
            expand: true,
            onPressed: _resending ? null : () => _verify(auth),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _verifying || _resending ? null : () => _resend(auth),
            child: const Text('Reenviar código'),
          ),
        ],
      ),
    );
  }
}
