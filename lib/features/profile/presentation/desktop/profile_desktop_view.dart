import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/desktop/desktop_dialog.dart';
import '../../../../core/widgets/desktop/desktop_page_header.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_card.dart';
import '../../../../core/widgets/shared/app_status_chip.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../shared/profile_actions.dart';
import '../shared/profile_forms.dart';

class ProfileDesktopView extends StatelessWidget {
  const ProfileDesktopView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      body: ListView(
        children: [
          const DesktopPageHeader(
            title: 'Perfil',
            subtitle: 'Tu información de cuenta.',
          ),
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
                            Text(
                              user.fullName,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              user.email,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              'El correo no se puede cambiar desde aquí.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
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
                          onPressed: () => showDesktopDialog<void>(
                            context,
                            child: const EditProfileForm(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          label: 'Cambiar contraseña',
                          variant: AppButtonVariant.outlined,
                          icon: Icons.lock_outline,
                          onPressed: () => showDesktopDialog<void>(
                            context,
                            child: const ChangePasswordForm(),
                          ),
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
              onPressed: () => ProfileActions.logout(context),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
