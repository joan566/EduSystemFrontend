import 'package:flutter/material.dart';

/// Column definition for [AppDataTable]. [cellBuilder] renders a single
/// cell for a row's item.
class AppDataColumn<T> {
  const AppDataColumn({
    required this.label,
    required this.cellBuilder,
    this.numeric = false,
  });

  final String label;
  final Widget Function(T item) cellBuilder;
  final bool numeric;
}

/// Responsive data listing (§66): a real [DataTable] on desktop/tablet,
/// a card list on mobile. Both are driven by the same [items] and the
/// same [onRowTap] — only presentation differs.
///
/// Use on desktop-oriented screens directly; wrap in [ResponsiveBuilder]
/// when the mobile experience needs a materially different card, or pass
/// [mobileCardBuilder] to keep everything in one widget.
class AppDataTable<T> extends StatelessWidget {
  const AppDataTable({
    super.key,
    required this.columns,
    required this.items,
    required this.mobileCardBuilder,
    this.onRowTap,
    this.isMobile = false,
  });

  final List<AppDataColumn<T>> columns;
  final List<T> items;
  final Widget Function(BuildContext context, T item) mobileCardBuilder;
  final void Function(T item)? onRowTap;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) =>
            mobileCardBuilder(context, items[index]),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Card(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: MediaQuery.sizeOf(context).width - 48,
              ),
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
    );
  }
}
