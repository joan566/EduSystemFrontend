import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/state/list_state.dart';
import '../../../../core/widgets/shared/app_dropdown.dart';
import '../../../../core/widgets/shared/skeleton/skeleton.dart';
import '../../domain/entities/teaching_period_entity.dart';
import '../providers/teaching_provider.dart';

/// Dropdown to pick the "class" (a [TeachingPeriodEntity], i.e. the
/// `teachingPeriodId`) a screen is working with. Every module that lists
/// exams, activities, attendance sessions, or grading data needs this,
/// since `teachingPeriodId` is a required query param across the API.
class TeachingPeriodSelector extends StatefulWidget {
  const TeachingPeriodSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Clase',
    this.preferredId,
  });

  final TeachingPeriodEntity? value;
  final void Function(TeachingPeriodEntity?) onChanged;
  final String label;

  /// Class to select on first load instead of the first one (e.g. when a
  /// class screen opens this page for a specific class).
  final int? preferredId;

  @override
  State<TeachingPeriodSelector> createState() => _TeachingPeriodSelectorState();
}

class _TeachingPeriodSelectorState extends State<TeachingPeriodSelector> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<TeachingProvider>();
      await provider.ensureAllPeriodsLoaded();
      if (!mounted) return;
      if (widget.value == null && provider.allPeriods.isNotEmpty) {
        final preferred = provider.allPeriods
            .where((p) => p.id == widget.preferredId)
            .firstOrNull;
        widget.onChanged(preferred ?? provider.allPeriods.first);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final teaching = context.watch<TeachingProvider>();
    final periods = teaching.allPeriods;

    // Still reading the classes: the field's placeholder, not "no classes".
    if (periods.isEmpty &&
        switch (teaching.periodsState.status) {
          ViewStatus.initial || ViewStatus.loading => true,
          _ => false,
        }) {
      return const Skeleton(child: SkeletonBox(height: 48, radius: 8));
    }
    if (periods.isEmpty) {
      final colors = Theme.of(context).colorScheme;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.outline),
        ),
        child: Row(
          children: [
            Icon(
              Icons.groups_outlined,
              size: 20,
              color: colors.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Todavía no tienes clases asignadas.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            TextButton(
              onPressed: () => context.push(RoutePaths.teaching),
              child: const Text('Crear una clase'),
            ),
          ],
        ),
      );
    }

    return AppDropdown<TeachingPeriodEntity>(
      label: widget.label,
      value: widget.value,
      items: periods,
      itemLabel: (period) => period.displayName,
      onChanged: widget.onChanged,
    );
  }
}
