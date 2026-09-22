import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthProvider auth) async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await auth.register(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;
    if (!ok && auth.error != null) context.showApiError(auth.error!);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoading = auth.status == AuthStatus.authenticating;
    final isMobile = context.isMobile;

    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 24 : 48,
            vertical: 24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.person_add_alt_outlined,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Crea tu cuenta',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Regístrate como profesor para empezar a gestionar tus cursos.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _firstNameController,
                            label: 'Nombre',
                            required: true,
                            textInputAction: TextInputAction.next,
                            validator: (v) => Validators.combine([
                              (v) => Validators.required(v, field: 'El nombre'),
                              (v) => Validators.maxLength(
                                v,
                                100,
                                field: 'El nombre',
                              ),
                            ])(v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            controller: _lastNameController,
                            label: 'Apellido',
                            required: true,
                            textInputAction: TextInputAction.next,
                            validator: (v) => Validators.combine([
                              (v) =>
                                  Validators.required(v, field: 'El apellido'),
                              (v) => Validators.maxLength(
                                v,
                                100,
                                field: 'El apellido',
                              ),
                            ])(v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _emailController,
                      label: 'Correo electrónico',
                      required: true,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _passwordController,
                      label: 'Contraseña',
                      required: true,
                      helperText: 'Entre 8 y 72 caracteres.',
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(auth),
                      validator: Validators.password,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: 'Crear cuenta',
                      isLoading: isLoading,
                      expand: true,
                      onPressed: () => _submit(auth),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '¿Ya tienes cuenta?',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () => context.go(RoutePaths.login),
                          child: const Text('Inicia sesión'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Tus datos están cifrados y protegidos',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
