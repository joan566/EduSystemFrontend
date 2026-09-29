import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/academic_levels/presentation/pages/academic_levels_page.dart';
import '../../features/academic_periods/presentation/pages/academic_periods_page.dart';
import '../../features/activities/presentation/pages/activities_page.dart';
import '../../features/activities/presentation/pages/activity_detail_page.dart';
import '../../features/attendance/presentation/pages/attendance_page.dart';
import '../../features/attendance/presentation/pages/attendance_session_detail_page.dart';
import '../../features/audit/presentation/pages/audit_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/courses/presentation/pages/courses_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/data_management/presentation/pages/data_management_page.dart';
import '../../features/exams/presentation/pages/batch_detail_page.dart';
import '../../features/exams/presentation/pages/batch_upload_page.dart';
import '../../features/exams/presentation/pages/exam_builder_page.dart';
import '../../features/exams/presentation/pages/exam_detail_page.dart';
import '../../features/exams/presentation/pages/exams_page.dart';
import '../../features/exams/presentation/pages/submission_detail_page.dart';
import '../../features/grades/presentation/pages/grades_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/scanning/presentation/pages/scanning_page.dart';
import '../../features/students/presentation/pages/student_detail_page.dart';
import '../../features/students/presentation/pages/students_page.dart';
import '../../features/subjects/presentation/pages/subjects_page.dart';
import '../../features/schedule/presentation/pages/schedule_page.dart';
import '../../features/teaching/presentation/pages/teaching_page.dart';
import '../../features/teaching/presentation/pages/teaching_period_detail_page.dart';
import '../layout/app_shell.dart';
import '../widgets/mobile/mobile_more_page.dart';
import 'route_paths.dart';

/// Centralized routing (§17). Auth state drives redirects here rather
/// than in every page: an unauthenticated user is always sent to
/// `/login`, and an authenticated one is kept out of the auth screens.
class AppRouter {
  AppRouter(this._authProvider);

  final AuthProvider _authProvider;

  late final GoRouter router = GoRouter(
    initialLocation: RoutePaths.dashboard,
    refreshListenable: _authProvider,
    redirect: _redirect,
    routes: [
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RoutePaths.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: RoutePaths.dashboard,
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: RoutePaths.teaching,
            builder: (context, state) => const TeachingPage(),
            routes: [
              GoRoute(
                path: 'periods/:id',
                builder: (context, state) => TeachingPeriodDetailPage(
                  teachingPeriodId: int.parse(state.pathParameters['id']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: RoutePaths.schedule,
            builder: (context, state) => const SchedulePage(),
          ),
          GoRoute(
            path: RoutePaths.students,
            builder: (context, state) => const StudentsPage(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => StudentDetailPage(
                  studentId: int.parse(state.pathParameters['id']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: RoutePaths.subjects,
            builder: (context, state) => const SubjectsPage(),
          ),
          GoRoute(
            path: RoutePaths.courses,
            builder: (context, state) => const CoursesPage(),
          ),
          GoRoute(
            path: RoutePaths.periods,
            builder: (context, state) => const AcademicPeriodsPage(),
          ),
          GoRoute(
            path: RoutePaths.academicLevels,
            builder: (context, state) => const AcademicLevelsPage(),
          ),
          GoRoute(
            path: RoutePaths.exams,
            builder: (context, state) => const ExamsPage(),
            routes: [
              GoRoute(
                // Must come before ':id' so "create" isn't swallowed as an id.
                path: 'create',
                builder: (context, state) {
                  final raw = state.uri.queryParameters['teachingPeriodId'];
                  final teachingPeriodId = raw == null
                      ? null
                      : int.tryParse(raw);
                  return teachingPeriodId == null
                      ? const ExamsPage()
                      : ExamBuilderPage(teachingPeriodId: teachingPeriodId);
                },
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => ExamDetailPage(
                  examId: int.parse(state.pathParameters['id']!),
                ),
                routes: [
                  GoRoute(
                    path: 'scanning',
                    builder: (context, state) => ScanningPage(
                      examId: int.parse(state.pathParameters['id']!),
                    ),
                  ),
                  GoRoute(
                    path: 'batches',
                    builder: (context, state) => BatchUploadPage(
                      examId: int.parse(state.pathParameters['id']!),
                    ),
                    routes: [
                      GoRoute(
                        path: ':batchId',
                        builder: (context, state) => BatchDetailPage(
                          examId: int.parse(state.pathParameters['id']!),
                          batchId: int.parse(state.pathParameters['batchId']!),
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'submissions/:submissionId',
                    builder: (context, state) => SubmissionDetailPage(
                      examId: int.parse(state.pathParameters['id']!),
                      submissionId: int.parse(
                        state.pathParameters['submissionId']!,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: RoutePaths.activities,
            builder: (context, state) => ActivitiesPage(
              initialTeachingPeriodId: _teachingPeriodIdParam(state),
            ),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => ActivityDetailPage(
                  activityId: int.parse(state.pathParameters['id']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: RoutePaths.attendance,
            builder: (context, state) => AttendancePage(
              initialTeachingPeriodId: _teachingPeriodIdParam(state),
            ),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => AttendanceSessionDetailPage(
                  sessionId: int.parse(state.pathParameters['id']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: RoutePaths.grades,
            builder: (context, state) => GradesPage(
              initialTeachingPeriodId: _teachingPeriodIdParam(state),
            ),
          ),
          GoRoute(
            path: RoutePaths.dataManagement,
            builder: (context, state) => const DataManagementPage(),
          ),
          GoRoute(
            path: RoutePaths.audit,
            builder: (context, state) => AuditPage(
              initialTeachingPeriodId: _teachingPeriodIdParam(state),
            ),
          ),
          GoRoute(
            path: RoutePaths.profile,
            builder: (context, state) => const ProfilePage(),
          ),
          GoRoute(
            path: RoutePaths.more,
            builder: (context, state) => const MobileMorePage(),
          ),
        ],
      ),
    ],
  );

  static int? _teachingPeriodIdParam(GoRouterState state) {
    final raw = state.uri.queryParameters['teachingPeriodId'];
    return raw == null ? null : int.tryParse(raw);
  }

  String? _redirect(BuildContext context, GoRouterState state) {
    final status = _authProvider.status;
    if (status == AuthStatus.initial) return null;

    final onAuthScreen =
        state.matchedLocation == RoutePaths.login ||
        state.matchedLocation == RoutePaths.register ||
        state.matchedLocation == RoutePaths.forgotPassword;

    final authenticated = status == AuthStatus.authenticated;

    if (!authenticated && !onAuthScreen) return RoutePaths.login;
    if (authenticated && onAuthScreen) return RoutePaths.dashboard;
    return null;
  }
}
