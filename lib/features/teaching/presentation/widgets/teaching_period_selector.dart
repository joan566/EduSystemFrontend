import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/widgets/app_dropdown.dart';
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
  });

  final TeachingPeriodEntity? value;
  final void Function(TeachingPeriodEntity?) onChanged;
  final String label;

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
        widget.onChanged(provider.allPeriods.first);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final periods = context.watch<TeachingProvider>().allPeriods;

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
