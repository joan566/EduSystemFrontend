import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// A column of [DesktopListTable]: either [flex] (share of the free width)
/// or a fixed [width].
class DesktopListColumn<T> {
  const DesktopListColumn({
    required this.label,
    required this.cell,
    this.flex = 1,
    this.width,
    this.alignEnd = false,
  });

  final String label;
  final Widget Function(T item) cell;
  final int flex;
  final double? width;
  final bool alignEnd;
}

/// A row action shown on hover (and always in the row's menu).
class DesktopRowAction<T> {
  const DesktopRowAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
    this.inline = true,
  });

  final IconData icon;
  final String label;
  final void Function(T item) onTap;
  final bool destructive;

  /// Shown as an icon button on hover; otherwise only in the menu.
  final bool inline;
}

/// Desktop listing in the app's card-table style: uppercase header, hover
/// rows, actions that appear on hover, optional group headers (e.g. by
/// year) and a footer. A click runs [onRowTap] (usually edit).
class DesktopListTable<T> extends StatelessWidget {
  const DesktopListTable({
    super.key,
    required this.columns,
    required this.items,
    this.actions = const [],
    this.onRowTap,
    this.groupOf,
    this.footer,
    this.shrinkWrap = false,
  });

  final List<DesktopListColumn<T>> columns;
  final List<T> items;
  final List<DesktopRowAction<T>> actions;
  final void Function(T item)? onRowTap;

  /// Items with a different group than the previous get a header row;
  /// [items] must already be sorted by group.
  final String Function(T item)? groupOf;
  final Widget? footer;

  /// Lay rows out in a Column (inside a scroll view) instead of a ListView.
  final bool shrinkWrap;

  double get _actionsWidth =>
      actions.isEmpty ? 0 : 40.0 * actions.where((a) => a.inline).length + 52;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final header = Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(letterSpacing: 0.4);

    final rows = <Widget>[];
    String? group;
    for (final (i, item) in items.indexed) {
      final g = groupOf?.call(item);
      if (g != null && g != group) {
        group = g;
        rows.add(_GroupHeader(label: g, first: i == 0));
      } else if (i > 0) {
        rows.add(Divider(height: 1, color: colors.outline));
      }
      rows.add(_Row<T>(item: item, table: this));
    }

    final body = shrinkWrap
        ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows)
        : Expanded(child: ListView(children: rows));

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outline.withValues(alpha: 0.7)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.45),
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
            child: Row(
              children: [
                for (final c in columns)
                  _sized(
                    c,
                    Text(
                      c.label.toUpperCase(),
                      textAlign: c.alignEnd ? TextAlign.end : TextAlign.start,
                      style: header,
                    ),
                  ),
                SizedBox(width: _actionsWidth),
              ],
            ),
          ),
          Divider(height: 1, color: colors.outline),
          body,
          if (footer != null) ...[
            Divider(height: 1, color: colors.outline),
            footer!,
          ],
        ],
      ),
    );
  }

  Widget _sized(DesktopListColumn<T> c, Widget child) => c.width != null
      ? SizedBox(width: c.width, child: child)
      : Expanded(flex: c.flex, child: child);
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label, required this.first});

  final String label;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.accentBlue.withValues(alpha: 0.04),
        border: Border(
          top: first ? BorderSide.none : BorderSide(color: colors.outline),
          bottom: BorderSide(color: colors.outline),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppColors.accentBlue,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Row<T> extends StatefulWidget {
  const _Row({super.key, required this.item, required this.table});

  final T item;
  final DesktopListTable<T> table;

  @override
  State<_Row<T>> createState() => _RowState<T>();
}

class _RowState<T> extends State<_Row<T>> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final table = widget.table;
    final item = widget.item;
    final colors = Theme.of(context).colorScheme;
    final onTap = table.onRowTap;

    return MouseRegion(
      cursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Material(
        color: _hovering
            ? colors.surfaceContainerHighest.withValues(alpha: 0.35)
            : Colors.transparent,
        child: InkWell(
          onTap: onTap == null ? null : () => onTap(item),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 12, 10),
            child: Row(
              children: [
                for (final c in table.columns)
                  table._sized(
                    c,
                    Align(
                      alignment: c.alignEnd
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: c.cell(item),
                    ),
                  ),
                if (table.actions.isNotEmpty)
                  SizedBox(
                    width: table._actionsWidth,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 120),
                          opacity: _hovering ? 1 : 0,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (final a in table.actions.where(
                                (a) => a.inline,
                              ))
                                IconButton(
                                  tooltip: a.label,
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => a.onTap(item),
                                  icon: Icon(
                                    a.icon,
                                    size: 18,
                                    color: a.destructive ? colors.error : null,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        PopupMenuButton<int>(
                          tooltip: 'Acciones',
                          icon: Icon(
                            Icons.more_horiz,
                            size: 20,
                            color: colors.onSurface.withValues(
                              alpha: _hovering ? 0.8 : 0.4,
                            ),
                          ),
                          onSelected: (i) => table.actions[i].onTap(item),
                          itemBuilder: (context) => [
                            for (final (i, a) in table.actions.indexed)
                              PopupMenuItem(
                                value: i,
                                child: Row(
                                  children: [
                                    Icon(
                                      a.icon,
                                      size: 18,
                                      color: a.destructive
                                          ? colors.error
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(a.label),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
