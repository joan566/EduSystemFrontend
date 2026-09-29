import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/layout/responsive.dart';
import '../../../teaching/presentation/providers/teaching_provider.dart';
import '../desktop/subjects_desktop_view.dart';
import '../mobile/subjects_mobile_view.dart';
import '../providers/subjects_provider.dart';

class SubjectsPage extends StatefulWidget {
  const SubjectsPage({super.key});

  @override
  State<SubjectsPage> createState() => _SubjectsPageState();
}

class _SubjectsPageState extends State<SubjectsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubjectsProvider>().load();
      // Where each subject is taught comes from the teacher's classes.
      context.read<TeachingProvider>().ensureAllPeriodsLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (_) => const SubjectsMobileView(),
      desktop: (_) => const SubjectsDesktopView(),
    );
  }
}
