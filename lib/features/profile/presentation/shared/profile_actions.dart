import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/shared/app_confirm_dialog.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileActions {
  ProfileActions._();

  static Future<void> logout(BuildContext context) async {
    final confirmed = await confirmLogout(context);
    if (confirmed && context.mounted) {
      await context.read<AuthProvider>().logout();
    }
  }
}
