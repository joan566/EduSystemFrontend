import 'package:flutter/material.dart';

import 'app_button.dart';
import 'app_dialog.dart';

/// Confirmation dialog for destructive actions (§63). Trivial actions
/// should not call this.
Future<bool> showAppConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirmar',
  String cancelLabel = 'Cancelar',
  bool isDestructive = true,
}) async {
  final result = await showAppDialog<bool>(
    context,
    desktopWidth: 400,
    child: Builder(
      builder: (ctx) => Padding(
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
  );
  return result ?? false;
}
