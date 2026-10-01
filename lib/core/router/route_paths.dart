import '../utils/formatters.dart';

/// Centralized route paths (§17). Only routes the backend actually
/// supports data for exist here.
class RoutePaths {
  RoutePaths._();

  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const verifyEmail = '/verify-email';

  static const app = '/app';
  static const dashboard = '/app/dashboard';

  static const teaching = '/app/teaching';
  static String teachingPeriodDetail(int id) => '/app/teaching/periods/$id';

  static const schedule = '/app/schedule';

  static const students = '/app/students';
  /// [tab]: 0 Información, 1 Historial académico, 2 Notas (desktop shows
  /// the information beside the tabs, so 0 opens its first tab there).
  static String studentDetail(int id, {int? tab}) =>
      tab == null ? '/app/students/$id' : '/app/students/$id?tab=$tab';

  static const subjects = '/app/subjects';

  /// Cursos filtered by a grade level (from Grados académicos).
  static String coursesForLevel(int gradeId) => '$courses?gradeId=$gradeId';
  static const courses = '/app/courses';
  static const periods = '/app/periods';
  static const academicLevels = '/app/academic-levels';

  static const exams = '/app/exams';
  static const examCreate = '/app/exams/create';
  static String examCreateForClass(int teachingPeriodId) =>
      '$examCreate?teachingPeriodId=$teachingPeriodId';
  /// [tab]: 0 Preguntas, 1 Hojas de respuesta, 2 Resultados.
  static String examDetail(int id, {int? tab}) =>
      tab == null ? '/app/exams/$id' : '/app/exams/$id?tab=$tab';
  static String examQuestions(int id) => '/app/exams/$id/questions';
  static String examAnswerSheets(int id) => '/app/exams/$id/answer-sheets';
  static String examScanning(int id) => '/app/exams/$id/scanning';
  static String submissionBatches(int examId) => '/app/exams/$examId/batches';
  static String submissionBatch(int examId, int batchId) =>
      '/app/exams/$examId/batches/$batchId';
  static String examResults(int id) => '/app/exams/$id/results';
  static String submissionDetail(int examId, int submissionId) =>
      '/app/exams/$examId/submissions/$submissionId';

  static const activities = '/app/activities';
  static String activitiesForClass(int teachingPeriodId) =>
      '$activities?teachingPeriodId=$teachingPeriodId';
  static String activityDetail(int id) => '/app/activities/$id';

  static const attendance = '/app/attendance';
  /// Attendance of a class, on [date] when given (else today).
  static String attendanceForClass(int teachingPeriodId, {DateTime? date}) =>
      '$attendance?teachingPeriodId=$teachingPeriodId'
      '${date == null ? '' : '&date=${Formatters.toApiDate(date)}'}';

  static const grades = '/app/grades';

  /// A student's grades in a class, evaluation by evaluation.
  static String studentGrades(int teachingPeriodId, int studentId) =>
      '$grades/$teachingPeriodId/students/$studentId';

  /// A student's grade in one evaluation (rubric, attachment, comment).
  static String gradeDetail(
    int teachingPeriodId,
    int studentId,
    int evaluationId,
  ) => '${studentGrades(teachingPeriodId, studentId)}/evaluations/$evaluationId';

  /// Grading setup of a class: scale, passing grade and category weights.
  static const gradingSettings = '/app/settings/grading';
  static String gradingSettingsForClass(int teachingPeriodId) =>
      '$gradingSettings?teachingPeriodId=$teachingPeriodId';
  static String gradesForClass(int teachingPeriodId) =>
      '$grades?teachingPeriodId=$teachingPeriodId';
  static const dataManagement = '/app/data';
  static const audit = '/app/audit';
  static String auditForClass(int teachingPeriodId) =>
      '$audit?teachingPeriodId=$teachingPeriodId';
  static const profile = '/app/profile';
  static const more = '/app/more';
}
