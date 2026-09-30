import 'package:edusistem_front/core/theme/app_theme.dart';
import 'package:edusistem_front/core/widgets/desktop/desktop_skeletons.dart';
import 'package:edusistem_front/core/widgets/mobile/mobile_skeletons.dart';
import 'package:edusistem_front/core/widgets/shared/skeleton/skeleton.dart';
import 'package:edusistem_front/core/widgets/shared/skeleton/skeleton_blocks.dart';
import 'package:edusistem_front/features/dashboard/presentation/desktop/widgets/dashboard_desktop_skeleton.dart';
import 'package:edusistem_front/features/exams/presentation/desktop/questions_editor_desktop.dart';
import 'package:edusistem_front/features/exams/presentation/mobile/questions_editor_mobile.dart';
import 'package:edusistem_front/features/schedule/presentation/desktop/widgets/week_time_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpAt(WidgetTester tester, Size size, Widget child) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: child),
    ),
  );
  // Past the reveal delay and into the shimmer.
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  const phone = Size(390, 844);
  const desktop = Size(1440, 900);

  testWidgets('the skeleton stays invisible for its delay, then fades in', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: Skeleton(child: SkeletonBox(width: 80))),
      ),
    );
    FadeTransition fade() => tester.widget<FadeTransition>(
      find.descendant(
        of: find.byType(Skeleton),
        matching: find.byType(FadeTransition),
      ),
    );

    // A request that answers within the delay never shows a skeleton.
    await tester.pump(const Duration(milliseconds: 100));
    expect(fade().opacity.value, 0);

    await tester.pump(const Duration(milliseconds: 400));
    expect(fade().opacity.value, 1);
    expect(find.bySemanticsLabel('Cargando contenido'), findsOneWidget);
  });

  testWidgets('with animations disabled the skeleton is static and visible', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(body: Skeleton(child: SkeletonBox(width: 80))),
        ),
      ),
    );
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
  });

  group('presets lay out without overflow', () {
    final mobile = <String, Widget>{
      'list': const MobileListSkeleton(meta: true, trailingWidth: 60),
      'list shrinkWrap in a scroll view': ListView(
        children: const [
          MobileListSkeleton(shrinkWrap: true, bar: true, itemCount: 3),
        ],
      ),
      'detail': const MobileDetailSkeleton(tabs: 3, stats: 3),
      'tile list': const SkeletonTileList(trailingWidth: 48),
      'ring summary': const Skeleton(child: SkeletonRingSummary()),
      'value rows': const SkeletonValueRows(),
      'questions editor': const QuestionsEditorMobileSkeleton(),
      'section': const Skeleton(child: MobileSectionSkeleton()),
    };
    for (final MapEntry(:key, :value) in mobile.entries) {
      testWidgets('mobile: $key', (tester) async {
        await _pumpAt(tester, phone, value);
        expect(tester.takeException(), isNull);
      });
    }

    final wide = <String, Widget>{
      'list table': const DesktopListTableSkeleton(
        columns: [
          SkeletonColumn('Estudiante', flex: 5, cell: SkeletonCell.entity),
          SkeletonColumn('Curso', flex: 2),
          SkeletonColumn('Nota', flex: 3, cell: SkeletonCell.bar),
          SkeletonColumn('Estado', width: 120, cell: SkeletonCell.chip),
          SkeletonColumn('Asistencia', width: 348, cell: SkeletonCell.segments),
        ],
      ),
      'data table': const DesktopDataTableSkeleton(
        columns: [
          SkeletonColumn('Nombre', flex: 3),
          SkeletonColumn('Puntaje', cell: SkeletonCell.value),
        ],
      ),
      'detail with rail': const DesktopDetailSkeleton(
        rail: 3,
        railEnd: true,
        tabs: 4,
        stats: 4,
      ),
      'dashboard': const DashboardDesktopSkeleton(),
      'questions editor': const QuestionsEditorDesktopSkeleton(),
      'week grid': const Skeleton(child: WeekTimeGridSkeleton()),
    };
    for (final MapEntry(:key, :value) in wide.entries) {
      testWidgets('desktop: $key', (tester) async {
        await _pumpAt(tester, desktop, value);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('desktop detail below the rail breakpoint', (tester) async {
      await _pumpAt(
        tester,
        const Size(900, 700),
        const DesktopDetailSkeleton(rail: 2),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
