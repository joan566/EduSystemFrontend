import 'package:flutter/widgets.dart';

import '../../../../core/state/list_state.dart';

/// Exams and activities providers hold one class's list at a time, shared
/// with their own screens. When the list loaded belongs to another class
/// (the user switched class there and came back), this treats it as
/// loading and reloads it for [teachingPeriodId] after the frame.
ListViewState<T> classScoped<T>(
  ListViewState<T> state, {
  required int teachingPeriodId,
  required int Function(T) teachingPeriodOf,
  required VoidCallback reload,
}) {
  final foreign =
      state.status == ViewStatus.success &&
      state.items.any((item) => teachingPeriodOf(item) != teachingPeriodId);
  if (!foreign) return state;
  WidgetsBinding.instance.addPostFrameCallback((_) => reload());
  return ListViewState<T>.loading();
}
