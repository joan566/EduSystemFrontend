import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_form_frame.dart';
import '../../../../core/widgets/shared/app_text_field.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

/// Edits the signed-in user's name; closes itself on success.
class EditProfileForm extends StatefulWidget {
  const EditProfileForm({super.key});

  @override
  State<EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends State<EditProfileForm> {
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
    return AppFormFrame(
      title: 'Editar perfil',
      actions: [
        AppButton(label: 'Guardar', isLoading: saving, onPressed: _submit),
      ],
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

/// Changes the signed-in user's password; closes itself on success.
class ChangePasswordForm extends StatefulWidget {
  const ChangePasswordForm({super.key});

  @override
  State<ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends State<ChangePasswordForm> {
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
      context.showSuccess(
        'Contraseña actualizada. Tus otras sesiones se cerraron.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        context.watch<AuthProvider>().status == AuthStatus.authenticating;
    return AppFormFrame(
      title: 'Cambiar contraseña',
      actions: [
        AppButton(label: 'Guardar', isLoading: isLoading, onPressed: _submit),
      ],
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
              validator: (v) =>
                  Validators.required(v, field: 'La contraseña actual'),
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

/// Permanently deletes the account: asks for the current password and for
/// "ELIMINAR" typed out, so it can't happen by a stray tap. On success the
/// session is cleared and the router takes the user to /login.
class DeleteAccountForm extends StatefulWidget {
  const DeleteAccountForm({super.key});

  static const confirmationWord = 'ELIMINAR';

  @override
  State<DeleteAccountForm> createState() => _DeleteAccountFormState();
}

class _DeleteAccountFormState extends State<DeleteAccountForm> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _deleting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    // Outlives this form and the authenticated screens behind it, so the
    // confirmation still shows once the router has moved to /login.
    final rootContext = Navigator.of(context, rootNavigator: true).context;
    final auth = context.read<AuthProvider>();
    setState(() => _deleting = true);
    final ok = await auth.deleteAccount(_passwordController.text);
    if (mounted) setState(() => _deleting = false);
    if (!ok) {
      if (mounted && auth.error != null) context.showApiError(auth.error!);
      return;
    }
    if (mounted) Navigator.of(context).pop();
    if (rootContext.mounted) {
      rootContext.showSuccess('Tu cuenta y todos sus datos fueron eliminados.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppFormFrame(
      title: 'Eliminar cuenta',
      actions: [
        AppButton(
          label: 'Eliminar mi cuenta',
          variant: AppButtonVariant.danger,
          isLoading: _deleting,
          onPressed: _submit,
        ),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Se borrarán definitivamente tu cuenta y todos sus datos: '
              'estudiantes, notas, asistencia, exámenes y archivos. Esta '
              'acción no se puede deshacer.',
              style: textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _passwordController,
              label: 'Contraseña actual',
              required: true,
              obscureText: true,
              validator: (v) =>
                  Validators.required(v, field: 'La contraseña actual'),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _confirmController,
              label:
                  'Escribe ${DeleteAccountForm.confirmationWord} para confirmar',
              required: true,
              validator: (v) => v?.trim() == DeleteAccountForm.confirmationWord
                  ? null
                  : 'Escribe ${DeleteAccountForm.confirmationWord} en '
                        'mayúsculas.',
            ),
          ],
        ),
      ),
    );
  }
}
