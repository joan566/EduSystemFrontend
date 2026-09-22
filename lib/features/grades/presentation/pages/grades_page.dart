import 'package:flutter/material.dart';

import '../../../../core/widgets/app_page_header.dart';
import '../../../teaching/domain/entities/teaching_period_entity.dart';
import '../../../teaching/presentation/widgets/teaching_period_selector.dart';
import '../widgets/grading_configuration_tab.dart';
import '../widgets/period_grades_tab.dart';

class GradesPage extends StatefulWidget {
  const GradesPage({super.key});

  @override
  State<GradesPage> createState() => _GradesPageState();
}

class _GradesPageState extends State<GradesPage> {
  TeachingPeriodEntity? _period;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Column(
          children: [
            const AppPageHeader(
              title: 'Calificaciones',
              subtitle: 'Configura la escala, las ponderaciones y consulta las notas del periodo.',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TeachingPeriodSelector(
                value: _period,
                onChanged: (period) => setState(() => _period = period),
              ),
            ),
            const SizedBox(height: 8),
            if (_period != null) ...[
              const TabBar(tabs: [Tab(text: 'Configuración'), Tab(text: 'Notas del periodo')]),
              Expanded(
                child: TabBarView(
                  children: [
                    GradingConfigurationTab(teachingPeriodId: _period!.id),
                    PeriodGradesTab(teachingPeriodId: _period!.id),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
