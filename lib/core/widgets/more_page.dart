import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../router/nav_items.dart';
import 'app_confirm_dialog.dart';

/// Secondary destinations for mobile/tablet (§19, §107): everything that
/// doesn't fit in the bottom nav / rail lives here as a simple list.
class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(title: const Text('Más')),
      body: ListView(
        children: [
          if (user != null)
            ListTile(
              leading: CircleAvatar(child: Text(user.initials)),
              title: Text(user.fullName),
              subtitle: Text(user.email),
            ),
          const Divider(height: 1),
          for (final item in moreNavItems)
            ListTile(
              leading: Icon(item.icon),
              title: Text(item.label),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () => context.push(item.path),
            ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar sesión'),
            onTap: () async {
              final confirmed = await confirmLogout(context);
              if (confirmed && context.mounted) {
                await context.read<AuthProvider>().logout();
              }
            },
          ),
        ],
      ),
    );
  }
}
