import 'package:flutter/material.dart';

/// Column definition for [DesktopDataTable]. [cellBuilder] renders a single
/// cell for a row's item.
class DesktopDataColumn<T> {
  const DesktopDataColumn({
    required this.label,
    required this.cellBuilder,
    this.numeric = false,
  });

  final String label;
  final Widget Function(T item) cellBuilder;
  final bool numeric;
}

/// Desktop data listing (§66): a real [DataTable] inside a card, with row
/// hover when rows are clickable. Mobile screens list the same data with
/// `MobileCardList` and their own card design instead.
class DesktopDataTable<T> extends StatelessWidget {
  const DesktopDataTable({
    super.key,
    required this.columns,
    required this.items,
    this.onRowTap,
  });

  final List<DesktopDataColumn<T>> columns;
  final List<T> items;
  final void Function(T item)? onRowTap;

  @override
  Widget build(BuildContext context) {
    final hoverColor = Theme.of(
      context,
    ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Card(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  columns: [
                    for (final column in columns)
                      DataColumn(
                        label: Text(column.label),
                        numeric: column.numeric,
                      ),
                  ],
                  rows: [
                    for (final item in items)
                      DataRow(
                        // Hover highlight (Stripe/Vercel-style) — only wired
                        // when the row is actually clickable.
                        color: onRowTap == null
                            ? null
                            : WidgetStateProperty.resolveWith(
                                (states) => states.contains(WidgetState.hovered)
                                    ? hoverColor
                                    : null,
                              ),
                        onSelectChanged: onRowTap == null
                            ? null
                            : (_) => onRowTap!(item),
                        cells: [
                          for (final column in columns)
                            DataCell(column.cellBuilder(item)),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
