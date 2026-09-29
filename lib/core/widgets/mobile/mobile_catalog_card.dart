import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'mobile_form.dart';

/// A catalog row card: a leading badge, title and subtitle, a meta line,
/// an optional trailing status, and an overflow menu (Editar / Eliminar,
/// plus [extraActions]). Tapping the card edits it.
class MobileCatalogCard extends StatelessWidget {
  const MobileCatalogCard({
    super.key,
    required this.leading,
    required this.title,
    required this.onEdit,
    required this.onDelete,
    this.subtitle,
    this.meta,
    this.trailing,
    this.footer,
    this.extraActions = const [],
    this.editLabel = 'Editar',
    this.deleteLabel = 'Eliminar',
  });

  final Widget leading;
  final String title;
  final String? subtitle;

  /// Small line under the subtitle (counts, dates).
  final Widget? meta;

  /// Top-right, e.g. a status chip.
  final Widget? trailing;

  /// Full-width content under the row (e.g. a progress bar).
  final Widget? footer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final List<({IconData icon, String label, VoidCallback onTap})> extraActions;
  final String editLabel;
  final String deleteLabel;

  Future<void> _openMenu(BuildContext context) async {
    final choice = await showMobileSheet<int>(
      context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final (i, a) in extraActions.indexed)
              ListTile(
                leading: Icon(a.icon),
                title: Text(a.label),
                onTap: () => Navigator.of(context).pop(i + 2),
              ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(editLabel),
              onTap: () => Navigator.of(context).pop(0),
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(deleteLabel),
              onTap: () => Navigator.of(context).pop(1),
            ),
          ],
        ),
      ),
    );
    switch (choice) {
      case null:
        return;
      case 0:
        onEdit();
      case 1:
        onDelete();
      default:
        extraActions[choice - 2].onTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        onLongPress: () => _openMenu(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  leading,
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium,
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty)
                          Text(
                            subtitle!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall,
                          ),
                        if (meta != null) ...[
                          const SizedBox(height: 4),
                          DefaultTextStyle.merge(
                            style: textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                            child: meta!,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    trailing!,
                  ],
                  IconButton(
                    tooltip: 'Más opciones',
                    onPressed: () => _openMenu(context),
                    icon: const Icon(Icons.more_vert, size: 20),
                  ),
                ],
              ),
              if (footer != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 10, 10, 0),
                  child: footer!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
