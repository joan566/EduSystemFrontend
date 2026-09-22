import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      body: ListView(
        children: [
          const AppPageHeader(title: 'Perfil', subtitle: 'Tu información de cuenta.'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          user.initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.fullName, style: Theme.of(context).textTheme.titleLarge),
                            Text(user.email, style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                      AppStatusChip(
                        label: user.isAdmin ? 'Administrador' : 'Profesor',
                        kind: AppStatusKind.info,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Editar perfil',
                          variant: AppButtonVariant.outlined,
                          icon: Icons.edit_outlined,
                          onPressed: () => showAppDialog(context, child: const _EditProfileForm()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          label: 'Cambiar contraseña',
                          variant: AppButtonVariant.outlined,
                          icon: Icons.lock_outline,
                          onPressed: () =>
                              showAppDialog(context, child: const _ChangePasswordForm()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AppButton(
              label: 'Cerrar sesión',
              variant: AppButtonVariant.danger,
              icon: Icons.logout,
              onPressed: () async {
                final confirmed = await showAppConfirmDialog(
                  context,
                  title: 'Cerrar sesión',
                  message: '¿Seguro que quieres cerrar tu sesión?',
                  confirmLabel: 'Cerrar sesión',
                );
                if (confirmed && context.mounted) {
                  await context.read<AuthProvider>().logout();
                }
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _EditProfileForm extends StatefulWidget {
  const _EditProfileForm();

  @override
  State<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends State<_EditProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user!;
    _firstName = TextEditingController(text: user.firstName);
    _lastName = TextEditingController(text: user.lastName);
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final error = await context.read<ProfileProvider>().updateProfile(
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
    );
    if (!mounted) return;
    if (error != null) {
      context.showApiError(error);
    } else {
      Navigator.of(context).pop();
      context.showSuccess('Perfil actualizado.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = context.watch<ProfileProvider>().saving;
    return AppDialogFrame(
      title: 'Editar perfil',
      actions: [AppButton(label: 'Guardar', isLoading: saving, onPressed: _submit)],
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _firstName,
              label: 'Nombre',
              required: true,
              validator: (v) => Validators.combine([
                (v) => Validators.required(v, field: 'El nombre'),
                (v) => Validators.maxLength(v, 100, field: 'El nombre'),
              ])(v),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _lastName,
              label: 'Apellido',
              required: true,
              validator: (v) => Validators.combine([
                (v) => Validators.required(v, field: 'El apellido'),
                (v) => Validators.maxLength(v, 100, field: 'El apellido'),
              ])(v),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangePasswordForm extends StatefulWidget {
  const _ChangePasswordForm();

  @override
  State<_ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends State<_ChangePasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.changePassword(
      currentPassword: _currentController.text,
      newPassword: _newController.text,
    );
    if (!mounted) return;
    if (!ok && auth.error != null) {
      context.showApiError(auth.error!);
    } else if (ok) {
      Navigator.of(context).pop();
      context.showSuccess('Contraseña actualizada. Tus otras sesiones se cerraron.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().status == AuthStatus.authenticating;
    return AppDialogFrame(
      title: 'Cambiar contraseña',
      actions: [AppButton(label: 'Guardar', isLoading: isLoading, onPressed: _submit)],
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _currentController,
              label: 'Contraseña actual',
              required: true,
              obscureText: true,
              validator: (v) => Validators.required(v, field: 'La contraseña actual'),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _newController,
              label: 'Contraseña nueva',
              required: true,
              obscureText: true,
              validator: Validators.password,
            ),
          ],
        ),
      ),
    );
  }
}
