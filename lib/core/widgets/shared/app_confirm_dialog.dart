import 'package:flutter/material.dart';

import 'app_button.dart';

/// Confirmation dialog for destructive actions (§63). Trivial actions
/// should not call this. A compact centered alert is the native idiom on
/// both phone and desktop, so unlike forms this one is genuinely shared.
Future<bool> showAppConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirmar',
  String cancelLabel = 'Cancelar',
  bool isDestructive = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 10),
              Text(message, style: Theme.of(ctx).textTheme.bodyMedium),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    label: cancelLabel,
                    variant: AppButtonVariant.text,
                    onPressed: () => Navigator.of(ctx).pop(false),
                  ),
                  const SizedBox(width: 8),
                  AppButton(
                    label: confirmLabel,
                    variant: isDestructive
                        ? AppButtonVariant.danger
                        : AppButtonVariant.primary,
                    onPressed: () => Navigator.of(ctx).pop(true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return result ?? false;
}

/// Shared copy for the "cerrar sesión" confirmation, so the title, message
/// and button label can't drift between the sidebar, the mobile "Más" page
/// and the profile page — each just calls this and, if it resolves true,
/// invokes its own `AuthProvider.logout()`.
Future<bool> confirmLogout(BuildContext context) => showAppConfirmDialog(
  context,
  title: 'Cerrar sesión',
  message: '¿Seguro que quieres cerrar tu sesión?',
  confirmLabel: 'Cerrar sesión',
);
