import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'core/events/domain_events.dart';
import 'core/network/api_client.dart';
import 'core/network/request_metrics.dart';
import 'core/network/session_expiry_notifier.dart';
import 'core/session/session_scope.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/academic_levels/data/datasources/academic_level_remote_datasource.dart';
import 'features/academic_levels/data/repositories/academic_level_repository.dart';
import 'features/academic_levels/presentation/providers/academic_levels_provider.dart';
import 'features/academic_periods/data/datasources/academic_period_remote_datasource.dart';
import 'features/academic_periods/data/repositories/academic_period_repository.dart';
import 'features/academic_periods/presentation/providers/academic_periods_provider.dart';
import 'features/activities/data/datasources/activity_remote_datasource.dart';
import 'features/activities/data/repositories/activity_repository.dart';
import 'features/activities/presentation/providers/activities_provider.dart';
import 'features/app_version/data/datasources/app_version_remote_datasource.dart';
import 'features/app_version/data/datasources/installed_version_datasource.dart';
import 'features/app_version/data/repositories/app_version_repository.dart';
import 'features/app_version/presentation/pages/app_version_gate.dart';
import 'features/app_version/presentation/providers/app_version_provider.dart';
import 'features/attendance/data/datasources/attendance_remote_datasource.dart';
import 'features/attendance/data/repositories/attendance_repository.dart';
import 'features/attendance/presentation/providers/attendance_provider.dart';
import 'features/audit/data/datasources/audit_remote_datasource.dart';
import 'features/audit/presentation/providers/audit_provider.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/courses/data/datasources/course_remote_datasource.dart';
import 'features/courses/data/repositories/course_repository.dart';
import 'features/courses/presentation/providers/courses_provider.dart';
import 'features/exams/data/datasources/exam_remote_datasource.dart';
import 'features/exams/data/repositories/exam_repository.dart';
import 'features/exams/presentation/providers/exams_provider.dart';
import 'features/exams/presentation/providers/submission_batches_provider.dart';
import 'features/exams/presentation/providers/submissions_provider.dart';
import 'features/exports/data/export_datasource.dart';
import 'features/grades/data/datasources/gradebook_remote_datasource.dart';
import 'features/grades/data/datasources/grading_remote_datasource.dart';
import 'features/grades/data/repositories/gradebook_repository.dart';
import 'features/grades/data/repositories/grading_repository.dart';
import 'features/grades/presentation/providers/gradebook_provider.dart';
import 'features/grades/presentation/providers/grading_provider.dart';
import 'features/imports/data/datasources/import_remote_datasource.dart';
import 'features/imports/data/repositories/import_repository.dart';
import 'features/imports/presentation/providers/imports_provider.dart';
import 'features/profile/data/user_profile_datasource.dart';
import 'features/profile/presentation/providers/profile_provider.dart';
import 'features/schedule/data/datasources/schedule_remote_datasource.dart';
import 'features/schedule/data/repositories/schedule_repository.dart';
import 'features/schedule/presentation/providers/schedule_provider.dart';
import 'features/students/data/datasources/student_remote_datasource.dart';
import 'features/students/data/repositories/student_repository.dart';
import 'features/students/presentation/providers/students_provider.dart';
import 'features/subjects/data/datasources/subject_remote_datasource.dart';
import 'features/subjects/data/repositories/subject_repository.dart';
import 'features/subjects/presentation/providers/subjects_provider.dart';
import 'features/teaching/data/datasources/teaching_remote_datasource.dart';
import 'features/teaching/data/repositories/teaching_repository.dart';
import 'features/teaching/presentation/providers/teaching_provider.dart';

/// Everything private to one signed-in teacher. Built again (empty) for
/// every session by [SessionScope].
List<SingleChildWidget> sessionProviders() => [
  // --- Academic catalog ------------------------------------------
  ChangeNotifierProvider<AcademicLevelsProvider>(
    create: (context) => AcademicLevelsProvider(
      AcademicLevelRepository(
        AcademicLevelRemoteDataSource(context.read<ApiClient>()),
      ),
      context.read<DomainEvents>(),
    ),
  ),
  ChangeNotifierProvider<SubjectsProvider>(
    create: (context) => SubjectsProvider(
      SubjectRepository(SubjectRemoteDataSource(context.read<ApiClient>())),
      context.read<DomainEvents>(),
    ),
  ),
  ChangeNotifierProvider<AcademicPeriodsProvider>(
    create: (context) => AcademicPeriodsProvider(
      AcademicPeriodRepository(
        AcademicPeriodRemoteDataSource(context.read<ApiClient>()),
      ),
      context.read<DomainEvents>(),
    ),
  ),
  ChangeNotifierProvider<CoursesProvider>(
    create: (context) => CoursesProvider(
      CourseRepository(CourseRemoteDataSource(context.read<ApiClient>())),
      context.read<DomainEvents>(),
    ),
  ),
  ChangeNotifierProvider<TeachingProvider>(
    create: (context) => TeachingProvider(
      TeachingRepository(TeachingRemoteDataSource(context.read<ApiClient>())),
      context.read<DomainEvents>(),
    ),
  ),
  ChangeNotifierProvider<ScheduleProvider>(
    create: (context) => ScheduleProvider(
      ScheduleRepository(ScheduleRemoteDataSource(context.read<ApiClient>())),
      context.read<DomainEvents>(),
    ),
  ),

  // --- Students & imports -----------------------------------------
  ChangeNotifierProvider<StudentsProvider>(
    create: (context) => StudentsProvider(
      StudentRepository(StudentRemoteDataSource(context.read<ApiClient>())),
      context.read<DomainEvents>(),
    ),
  ),
  ChangeNotifierProvider<ImportsProvider>(
    create: (context) => ImportsProvider(
      ImportRepository(
        ImportRemoteDataSource(context.read<ApiClient>()),
        AuditRemoteDataSource(context.read<ApiClient>()),
      ),
      context.read<DomainEvents>(),
    ),
  ),

  // --- Exams, activities, attendance, grading ---------------------
  ChangeNotifierProvider<ExamsProvider>(
    create: (context) => ExamsProvider(
      ExamRepository(ExamRemoteDataSource(context.read<ApiClient>())),
      context.read<DomainEvents>(),
    ),
  ),
  ChangeNotifierProvider<SubmissionsProvider>(
    create: (context) => SubmissionsProvider(
      ExamRepository(ExamRemoteDataSource(context.read<ApiClient>())),
      context.read<DomainEvents>(),
    ),
  ),
  ChangeNotifierProvider<SubmissionBatchesProvider>(
    create: (context) => SubmissionBatchesProvider(
      ExamRepository(ExamRemoteDataSource(context.read<ApiClient>())),
      context.read<DomainEvents>(),
    ),
  ),
  ChangeNotifierProvider<ActivitiesProvider>(
    create: (context) => ActivitiesProvider(
      ActivityRepository(ActivityRemoteDataSource(context.read<ApiClient>())),
      context.read<DomainEvents>(),
    ),
  ),
  ChangeNotifierProvider<AttendanceProvider>(
    create: (context) => AttendanceProvider(
      AttendanceRepository(
        AttendanceRemoteDataSource(context.read<ApiClient>()),
      ),
      context.read<DomainEvents>(),
    ),
  ),
  ChangeNotifierProvider<GradingProvider>(
    create: (context) => GradingProvider(
      GradingRepository(GradingRemoteDataSource(context.read<ApiClient>())),
      context.read<DomainEvents>(),
    ),
  ),
  ChangeNotifierProvider<GradebookProvider>(
    create: (context) => GradebookProvider(
      GradebookRepository(GradebookRemoteDataSource(context.read<ApiClient>())),
      context.read<DomainEvents>(),
    ),
  ),

  // --- Audit, exports, profile -------------------------------------
  ChangeNotifierProvider<AuditProvider>(
    create: (context) => AuditProvider(
      AuditRemoteDataSource(context.read<ApiClient>()),
      context.read<DomainEvents>(),
    ),
  ),
  Provider<ExportDataSource>(
    create: (context) => ExportDataSource(context.read<ApiClient>()),
  ),
  ChangeNotifierProvider<ProfileProvider>(
    create: (context) => ProfileProvider(
      dataSource: UserProfileDataSource(context.read<ApiClient>()),
      authProvider: context.read<AuthProvider>(),
    ),
  ),
];

void main() {
  if (kDebugMode) {
    // `ext.edusystem.httpReport` (DevTools > service extensions, or
    // `flutter attach`) prints how many requests each route got so far;
    // `?reset=true` starts counting again.
    developer.registerExtension('ext.edusystem.httpReport', (_, params) async {
      final report = RequestMetrics.instance.report();
      debugPrint(report);
      if (params['reset'] == 'true') RequestMetrics.instance.reset();
      return developer.ServiceExtensionResponse.result(
        jsonEncode({'report': report}),
      );
    });
  }
  runApp(const EduSistemApp());
}

class EduSistemApp extends StatelessWidget {
  const EduSistemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // --- Core -----------------------------------------------------
        Provider<SessionExpiryNotifier>(create: (_) => SessionExpiryNotifier()),
        Provider<ApiClient>(
          create: (context) => ApiClient(
            onSessionExpired: context.read<SessionExpiryNotifier>().notify,
          ),
        ),

        // --- Auth (wires the session-expiry callback below) -----------
        Provider<AuthRepository>(
          create: (context) => AuthRepositoryImpl(
            remoteDataSource: AuthRemoteDataSource(context.read<ApiClient>()),
            apiClient: context.read<ApiClient>(),
          ),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (context) {
            final authProvider = AuthProvider(
              repository: context.read<AuthRepository>(),
              apiClient: context.read<ApiClient>(),
            );
            context.read<SessionExpiryNotifier>().handler =
                authProvider.forceLogout;
            return authProvider;
          },
        ),

        // --- Version policy (public, independent of the session) -------
        // Not lazy: the check starts now, alongside the session restore,
        // and never holds the splash.
        ChangeNotifierProvider<AppVersionProvider>(
          lazy: false,
          create: (context) => AppVersionProvider(
            repository: AppVersionRepository(
              AppVersionRemoteDataSource(context.read<ApiClient>()),
              const InstalledVersionDataSource(),
            ),
          )..check(),
        ),
      ],
      child: const _AppRoot(),
    );
  }
}

class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  late final Future<void> _restoreSession = context
      .read<AuthProvider>()
      .restoreSession();

  /// Only the first session's router restores the platform location (a web
  /// deep link or reload); after a user change navigation starts over.
  bool _firstSession = true;

  @override
  Widget build(BuildContext context) {
    // GoRouter is only mounted once the session is restored, so it never
    // has to render `initialLocation` (the dashboard) before the redirect
    // logic knows whether the user is actually authenticated.
    return FutureBuilder<void>(
      future: _restoreSession,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            title: 'EduSystem',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: ThemeMode.light,
            builder: _versionGate,
            home: const _SplashScreen(),
          );
        }
        // A different user (or none) gets a brand-new session subtree:
        // every domain provider, cache and route of the previous one is
        // disposed with it.
        return Selector<AuthProvider, int?>(
          selector: (_, auth) => auth.user?.id,
          builder: (context, userId, _) {
            final restoreLocation = _firstSession;
            _firstSession = false;
            return SessionScope(
              key: ValueKey<int?>(userId),
              providers: sessionProviders,
              createRouter: () => AppRouter(
                context.read<AuthProvider>(),
                restorePlatformLocation: restoreLocation,
              ).router,
              builder: (context, router) => MaterialApp.router(
                title: 'EduSistem',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: ThemeMode.light,
                builder: _versionGate,
                routerConfig: router,
              ),
            );
          },
        );
      },
    );
  }
}

/// Every screen, splash included, sits behind the version policy.
Widget _versionGate(BuildContext context, Widget? child) =>
    AppVersionGate(child: child ?? const SizedBox.shrink());

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
