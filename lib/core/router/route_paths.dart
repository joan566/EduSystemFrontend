/// Centralized route paths (§17). Only routes the backend actually
/// supports data for exist here.
class RoutePaths {
  RoutePaths._();

  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';

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
  static String attendanceForClass(int teachingPeriodId) =>
      '$attendance?teachingPeriodId=$teachingPeriodId';
  static String attendanceSessionDetail(int id) => '/app/attendance/$id';

  static const grades = '/app/grades';
  static String gradesForClass(int teachingPeriodId) =>
      '$grades?teachingPeriodId=$teachingPeriodId';
  static const dataManagement = '/app/data';
  static const audit = '/app/audit';
  static String auditForClass(int teachingPeriodId) =>
      '$audit?teachingPeriodId=$teachingPeriodId';
  static const profile = '/app/profile';
  static const more = '/app/more';
}
