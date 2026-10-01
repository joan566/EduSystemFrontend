import 'package:flutter/material.dart';

import 'app_button.dart';

/// Confirmation dialog for destructive actions (§63). Trivial actions
/// should not call this. A compact centered alert is the native idiom on
/// both phone and desktop, so unlike forms this one is genuinely shared.
///
/// With [onConfirm], confirming runs it while the dialog stays open with
/// the confirm button loading (cancel and dismiss disabled), and the
/// dialog closes when it completes — so a delete is visibly in progress
/// instead of the dialog vanishing with nothing happening.
Future<bool> showAppConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirmar',
  String cancelLabel = 'Cancelar',
  bool isDestructive = true,
  Future<void> Function()? onConfirm,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => _ConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      isDestructive: isDestructive,
      onConfirm: onConfirm,
    ),
  );
  return result ?? false;
}

class _ConfirmDialog extends StatefulWidget {
  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.isDestructive,
    required this.onConfirm,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;
  final Future<void> Function()? onConfirm;

  @override
  State<_ConfirmDialog> createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends State<_ConfirmDialog> {
  bool _running = false;

  Future<void> _confirm() async {
    final onConfirm = widget.onConfirm;
    if (onConfirm != null) {
      setState(() => _running = true);
      try {
        await onConfirm();
      } finally {
        if (mounted) setState(() => _running = false);
      }
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return PopScope(
      canPop: !_running,
      child: Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: textTheme.titleLarge),
                const SizedBox(height: 10),
                Text(widget.message, style: textTheme.bodyMedium),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppButton(
                      label: widget.cancelLabel,
                      variant: AppButtonVariant.text,
                      onPressed: _running
                          ? null
                          : () => Navigator.of(context).pop(false),
                    ),
                    const SizedBox(width: 8),
                    AppButton(
                      label: widget.confirmLabel,
                      variant: widget.isDestructive
                          ? AppButtonVariant.danger
                          : AppButtonVariant.primary,
                      isLoading: _running,
                      onPressed: _confirm,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
