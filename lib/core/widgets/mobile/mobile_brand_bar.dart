import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../router/route_paths.dart';
import '../../theme/app_colors.dart';
import '../shared/brand_logo.dart';

/// Top bar of the mobile home-level screens (Inicio, Clases): brand mark +
/// app name on the left, the user's avatar (-> profile) on the right.
class MobileBrandBar extends StatelessWidget {
  const MobileBrandBar({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          const BrandLogo(size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'EduSistem',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Semantics(
            button: true,
            label: 'Mi perfil',
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => context.push(RoutePaths.profile),
              child: CircleAvatar(
                radius: 21,
                backgroundColor: AppColors.primaryDarkest,
                child: Text(
                  user?.initials ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
