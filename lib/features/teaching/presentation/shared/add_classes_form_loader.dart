import 'package:flutter/material.dart';

import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_form_frame.dart';
import '../../../../core/widgets/shared/skeleton/skeleton.dart';
import 'teaching_actions.dart';
import 'teaching_forms.dart';

/// Opens at once and shows [AddClassesForm] once its catalogs are in
/// memory (usually immediately). On a cold cache the tap is acknowledged
/// with the form's skeleton instead of nothing happening; if the form
/// can't be offered, it closes after [TeachingActions.addClassesFormInputs]
/// has told the user why.
class AddClassesFormLoader extends StatefulWidget {
  const AddClassesFormLoader({
    super.key,
    required this.onSubmit,
    this.initialGroupId,
    this.initialAcademicPeriodId,
  });

  final Future<bool> Function(AddClassesResult) onSubmit;
  final int? initialGroupId;
  final int? initialAcademicPeriodId;

  @override
  State<AddClassesFormLoader> createState() => _AddClassesFormLoaderState();
}

class _AddClassesFormLoaderState extends State<AddClassesFormLoader> {
  late final _inputs = TeachingActions.addClassesFormInputs(context);

  @override
  void initState() {
    super.initState();
    _inputs.then((inputs) {
      if (inputs == null && mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _inputs,
      builder: (context, snapshot) {
        final inputs = snapshot.data;
        if (inputs == null) return const _AddClassesFormSkeleton();
        return AddClassesForm(
          courses: inputs.courses,
          subjects: inputs.subjects,
          academicPeriods: inputs.academicPeriods,
          assignments: inputs.assignments,
          initialGroupId: widget.initialGroupId,
          initialAcademicPeriodId: widget.initialAcademicPeriodId,
          onSubmit: widget.onSubmit,
        );
      },
    );
  }
}

/// Two dropdowns and the subject chips, shaped like [AddClassesForm].
class _AddClassesFormSkeleton extends StatelessWidget {
  const _AddClassesFormSkeleton();

  @override
  Widget build(BuildContext context) {
    return AppFormFrame(
      title: 'Agregar materias a un curso',
      actions: const [AppButton(label: 'Guardar', onPressed: null)],
      child: Skeleton(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SkeletonBox(height: 48, radius: 10),
            const SizedBox(height: 16),
            const SkeletonBox(height: 48, radius: 10),
            const SizedBox(height: 20),
            const SkeletonBox(width: 120),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final width in const [88.0, 112.0, 72.0, 96.0, 120.0])
                  SkeletonBox(width: width, height: 32, radius: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
