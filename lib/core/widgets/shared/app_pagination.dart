import 'package:flutter/material.dart';

/// Prev/next pagination bar for [PAGE] endpoints (§69).
class AppPagination extends StatelessWidget {
  const AppPagination({
    super.key,
    required this.page,
    required this.totalPages,
    required this.totalElements,
    required this.onPageChanged,
  });

  final int page;
  final int totalPages;
  final int totalElements;
  final void Function(int page) onPageChanged;

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();
    final textStyle = Theme.of(context).textTheme.bodySmall;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$totalElements resultados', style: textStyle),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: page > 0 ? () => onPageChanged(page - 1) : null,
              ),
              Text('${page + 1} / $totalPages', style: textStyle),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed:
                    page < totalPages - 1 ? () => onPageChanged(page + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
