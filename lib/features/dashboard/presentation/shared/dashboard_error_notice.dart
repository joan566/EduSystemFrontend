import 'package:flutter/material.dart';

/// Compact inline notice for a dashboard section whose source failed to
/// load — distinct from a genuine empty state, with its own retry (§104:
/// never let a real error read as "there's nothing here").
class DashboardErrorNotice extends StatelessWidget {
  const DashboardErrorNotice({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 18, color: colors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'No pudimos cargar esta información.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
