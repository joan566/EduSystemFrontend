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

  static const students = '/app/students';
  static String studentDetail(int id) => '/app/students/$id';

  static const subjects = '/app/subjects';
  static const courses = '/app/courses';
  static const periods = '/app/periods';
  static const academicLevels = '/app/academic-levels';

  static const exams = '/app/exams';
  static const examCreate = '/app/exams/create';
  static String examDetail(int id) => '/app/exams/$id';
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
  static String activityDetail(int id) => '/app/activities/$id';

  static const attendance = '/app/attendance';
  static String attendanceSessionDetail(int id) => '/app/attendance/$id';

  static const grades = '/app/grades';
  static const dataManagement = '/app/data';
  static const audit = '/app/audit';
  static const profile = '/app/profile';
  static const more = '/app/more';
}
