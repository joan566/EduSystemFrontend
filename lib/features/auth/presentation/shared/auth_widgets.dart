import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';

/// "Tus datos están protegidos" microcopy — a lightweight, always-visible
/// trust signal on the auth screens (mirrors the sidebar's security badge).
class AuthTrustRow extends StatelessWidget {
  const AuthTrustRow({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          'Tus datos están cifrados y protegidos',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class AuthRegisterLink extends StatelessWidget {
  const AuthRegisterLink({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿No tienes una cuenta?',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        TextButton(
          onPressed: () => context.push(RoutePaths.register),
          child: const Text('Regístrate'),
        ),
      ],
    );
  }
}
