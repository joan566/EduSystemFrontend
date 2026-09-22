import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
      return InputDecorator(
        decoration: InputDecoration(labelText: widget.label),
        child: const Text('No tienes clases asignadas todavía'),
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
