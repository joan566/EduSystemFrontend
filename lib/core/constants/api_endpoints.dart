/// All REST paths, relative to `AppConfig.apiBaseUrl` (which already
/// includes `/api/v1`). Centralized so no feature hardcodes a path string.
class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const register = '/auth/register';
  static const login = '/auth/login';
  static const refresh = '/auth/refresh';
  static const logout = '/auth/logout';
  static const me = '/auth/me';
  static const changePassword = '/auth/change-password';
  static const forgotPassword = '/auth/forgot-password';
  static const verifyCode = '/auth/verify-code';
  static const resetPassword = '/auth/reset-password';
  static const account = '/auth/account';

  // App version policy (public)
  static const appVersion = '/app/version';

  // Users
  static const usersMe = '/users/me';

  // Catalog
  static const grades = '/grades';
  static String gradeById(int id) => '/grades/$id';

  static const groups = '/groups';
  static String groupById(int id) => '/groups/$id';

  static const academicPeriods = '/academic-periods';
  static String academicPeriodById(int id) => '/academic-periods/$id';

  static const subjects = '/subjects';
  static String subjectById(int id) => '/subjects/$id';

  // Teaching
  static const teachingAssignments = '/teaching-assignments';
  static String teachingAssignmentById(int id) => '/teaching-assignments/$id';
  static String teachingAssignmentActive(int id) =>
      '/teaching-assignments/$id/active';

  static const teachingPeriods = '/teaching-periods';
  static String teachingPeriodById(int id) => '/teaching-periods/$id';
  static String teachingPeriodSummary(int id) =>
      '/teaching-periods/$id/summary';
  static String gradingConfiguration(int teachingPeriodId) =>
      '/teaching-periods/$teachingPeriodId/grading-configuration';
  static String studentGradeReport(int teachingPeriodId, int studentId) =>
      '/teaching-periods/$teachingPeriodId/students/$studentId/grade-report';
  static String studentObservation(int teachingPeriodId, int studentId) =>
      '/teaching-periods/$teachingPeriodId/students/$studentId/observation';
  static String gradeDetail(int evaluationId, int studentId) =>
      '/evaluations/$evaluationId/students/$studentId/grade-detail';
  static String evaluationRubric(int evaluationId) =>
      '/evaluations/$evaluationId/rubric';
  static String rubricScores(int evaluationId, int studentId) =>
      '/evaluations/$evaluationId/students/$studentId/rubric-scores';
  static String gradeAttachment(int evaluationId, int studentId) =>
      '/evaluations/$evaluationId/students/$studentId/attachment';
  static String periodGrades(int teachingPeriodId) =>
      '/teaching-periods/$teachingPeriodId/period-grades';

  static String teachingPeriodSchedules(int teachingPeriodId) =>
      '/teaching-periods/$teachingPeriodId/schedules';
  static String teachingPeriodScheduleById(
    int teachingPeriodId,
    int scheduleId,
  ) => '/teaching-periods/$teachingPeriodId/schedules/$scheduleId';

  // Schedule (teacher's agenda across all classes)
  static const scheduleToday = '/schedule/today';
  static const schedule = '/schedule';

  // Students
  static const students = '/students';
  static String studentById(int id) => '/students/$id';
  static String studentWithdrawal(int studentId, int groupId) =>
      '/students/$studentId/groups/$groupId/withdrawal';

  // Evaluations
  static const evaluationCategories = '/evaluation-categories';
  static const evaluations = '/evaluations';
  static String evaluationById(int id) => '/evaluations/$id';

  // Grading scales
  static const gradingScales = '/grading-scales';
  static String gradingScaleById(int id) => '/grading-scales/$id';

  // Exams
  static const exams = '/exams';
  static String examById(int examId) => '/exams/$examId';
  static String examQuestions(int examId) => '/exams/$examId/questions';
  static String answerSheet(int examId, int studentId) =>
      '/exams/$examId/answer-sheet/$studentId';
  static String answerSheets(int examId) => '/exams/$examId/answer-sheets';
  static String submissions(int examId) => '/exams/$examId/submissions';
  static String submissionById(int examId, int submissionId) =>
      '/exams/$examId/submissions/$submissionId';
  static String submissionImage(int examId, int submissionId) =>
      '/exams/$examId/submissions/$submissionId/image';
  static String submissionAnswer(
    int examId,
    int submissionId,
    int questionNumber,
  ) => '/exams/$examId/submissions/$submissionId/answers/$questionNumber';
  static String submissionFinalGrade(int examId, int submissionId) =>
      '/exams/$examId/submissions/$submissionId/final-grade';
  static String submissionBatches(int examId) =>
      '/exams/$examId/submissions/batches';
  static String submissionBatchById(int examId, int batchId) =>
      '/exams/$examId/submissions/batches/$batchId';

  // Activities
  static const activities = '/activities';
  static String activityById(int id) => '/activities/$id';
  static String activityGrades(int id) => '/activities/$id/grades';
  static String activityStudentGrade(int id, int studentId) =>
      '/activities/$id/grades/$studentId';

  // Attendance
  static const attendanceSessions = '/attendance-sessions';
  static const attendanceDay = '/attendance-sessions/day';
  static String attendanceSessionById(int id) => '/attendance-sessions/$id';
  static String attendanceRecords(int id) => '/attendance-sessions/$id/records';

  // Imports
  static const importStudentsTemplate = '/imports/students/template';
  static const importStudents = '/imports/students';
  static const imports = '/imports';
  static String importById(int id) => '/imports/$id';
  static String importErrorReport(int id) => '/imports/$id/error-report';
  static String importTeachingPeriod(int teachingPeriodId) =>
      '/imports/teaching-periods/$teachingPeriodId';
  static const importSchoolSetupTemplate = '/imports/school-setup/template';
  static const importSchoolSetup = '/imports/school-setup';

  // Exports
  static const exportStudents = '/exports/students';
  static const exportGrades = '/exports/grades';
  static const exportAttendance = '/exports/attendance';
  static String exportTeachingPeriodFull(int teachingPeriodId) =>
      '/exports/teaching-periods/$teachingPeriodId/full';

  // Audit
  static const auditLogs = '/audit-logs';
}
