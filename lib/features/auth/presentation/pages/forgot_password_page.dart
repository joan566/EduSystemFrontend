import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';

enum _Step { email, code, newPassword, done }

/// Password recovery flow (§15): email -> 6-digit code -> new password.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  _Step _step = _Step.email;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthProvider auth) async {
    if (!_formKey.currentState!.validate()) return;

    bool ok;
    switch (_step) {
      case _Step.email:
        ok = await auth.forgotPassword(_emailController.text.trim());
        if (ok && mounted) setState(() => _step = _Step.code);
      case _Step.code:
        ok = await auth.verifyCode(
          email: _emailController.text.trim(),
          code: _codeController.text.trim(),
        );
        if (ok && mounted) setState(() => _step = _Step.newPassword);
      case _Step.newPassword:
        ok = await auth.resetPassword(
          email: _emailController.text.trim(),
          code: _codeController.text.trim(),
          newPassword: _passwordController.text,
        );
        if (ok && mounted) setState(() => _step = _Step.done);
      case _Step.done:
        ok = true;
    }
    if (!mounted) return;
    if (!ok && auth.error != null) context.showApiError(auth.error!);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoading = auth.status == AuthStatus.authenticating;

    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: _step == _Step.done
                ? _DoneContent(onGoToLogin: () => context.go('/login'))
                : Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(_title, style: Theme.of(context).textTheme.headlineLarge),
                        const SizedBox(height: 6),
                        Text(_subtitle, style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 28),
                        ..._fields(),
                        const SizedBox(height: 24),
                        AppButton(
                          label: _buttonLabel,
                          isLoading: isLoading,
                          expand: true,
                          onPressed: () => _submit(auth),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  String get _title => switch (_step) {
    _Step.email => 'Recuperar contraseña',
    _Step.code => 'Verifica tu correo',
    _Step.newPassword => 'Nueva contraseña',
    _Step.done => '',
  };

  String get _subtitle => switch (_step) {
    _Step.email => 'Ingresa tu correo y te enviaremos un código de verificación.',
    _Step.code => 'Ingresa el código de 6 dígitos que enviamos a ${_emailController.text}.',
    _Step.newPassword => 'Crea una nueva contraseña para tu cuenta.',
    _Step.done => '',
  };

  String get _buttonLabel => switch (_step) {
    _Step.email => 'Enviar código',
    _Step.code => 'Verificar código',
    _Step.newPassword => 'Restablecer contraseña',
    _Step.done => '',
  };

  List<Widget> _fields() {
    switch (_step) {
      case _Step.email:
        return [
          AppTextField(
            controller: _emailController,
            label: 'Correo electrónico',
            required: true,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
          ),
        ];
      case _Step.code:
        return [
          AppTextField(
            controller: _codeController,
            label: 'Código de verificación',
            required: true,
            keyboardType: TextInputType.number,
            hint: '123456',
            validator: (v) {
              if (v == null || v.trim().length != 6) {
                return 'El código debe tener 6 dígitos.';
              }
              return null;
            },
          ),
        ];
      case _Step.newPassword:
        return [
          AppTextField(
            controller: _passwordController,
            label: 'Nueva contraseña',
            required: true,
            obscureText: true,
            validator: Validators.password,
          ),
        ];
      case _Step.done:
        return [];
    }
  }
}

class _DoneContent extends StatelessWidget {
  const _DoneContent({required this.onGoToLogin});

  final VoidCallback onGoToLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle_outline, size: 48, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 16),
        Text('Contraseña actualizada', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Ya puedes iniciar sesión con tu nueva contraseña.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        AppButton(label: 'Ir a iniciar sesión', expand: true, onPressed: onGoToLogin),
      ],
    );
  }
}
