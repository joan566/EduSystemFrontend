import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/cache/synced_data_state.dart';
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

class _SubjectsPageState extends State<SubjectsPage>
    with SyncedDataState<SubjectsPage> {
  // Live here so they survive a mobile <-> desktop switch.
  String _search = '';
  int _page = 0;

  @override
  void ensureData() {
    context.read<SubjectsProvider>().ensure();
    // Where each subject is taught comes from the teacher's classes.
    context.read<TeachingProvider>().ensureAllPeriodsLoaded();
  }

  void _onSearchChanged(String value) => setState(() {
    _search = value;
    _page = 0;
  });

  void _onPageChanged(int page) => setState(() => _page = page);

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (_) => SubjectsMobileView(
        search: _search,
        onSearchChanged: _onSearchChanged,
        page: _page,
        onPageChanged: _onPageChanged,
      ),
      desktop: (_) => SubjectsDesktopView(
        search: _search,
        onSearchChanged: _onSearchChanged,
        page: _page,
        onPageChanged: _onPageChanged,
      ),
    );
  }
}
