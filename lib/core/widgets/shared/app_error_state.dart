import 'package:flutter/material.dart';

import '../../errors/app_exception.dart';
import '../../theme/app_colors.dart';
import 'app_button.dart';

/// Full-section error state with retry (§104: never leave the user on a
/// broken screen — offer a way forward).
class AppErrorState extends StatelessWidget {
  const AppErrorState({super.key, required this.exception, this.onRetry});

  final AppException exception;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isNetwork = exception.isNetwork;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(color: AppColors.errorBg, shape: BoxShape.circle),
              child: Icon(
                isNetwork ? Icons.wifi_off_rounded : Icons.error_outline,
                size: 32,
                color: colors.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isNetwork
                  ? 'No pudimos conectar con el servidor.'
                  : _titleFor(exception),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              isNetwork
                  ? 'Verifica tu conexión e inténtalo de nuevo.'
                  : exception.message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.6),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              AppButton(
                label: 'Reintentar',
                icon: Icons.refresh,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _titleFor(AppException e) {
    if (e.isForbidden) return 'Sin permisos';
    if (e.isNotFound) return 'No encontrado';
    if (e.isServerError) return 'Error del servidor';
    return 'Algo salió mal';
  }
}
