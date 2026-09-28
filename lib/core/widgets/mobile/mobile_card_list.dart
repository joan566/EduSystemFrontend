import 'package:flutter/material.dart';

/// Mobile listing: a vertical list of cards, each designed by the feature's
/// mobile view. [footer] is appended after the last card (e.g. pagination).
class MobileCardList<T> extends StatelessWidget {
  const MobileCardList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.footer,
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final count = items.length + (footer == null ? 0 : 1);
    return ListView.separated(
      // Bottom padding keeps the last card clear of a FloatingActionButton.
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) =>
          index < items.length ? itemBuilder(context, items[index]) : footer!,
    );
  }
}
