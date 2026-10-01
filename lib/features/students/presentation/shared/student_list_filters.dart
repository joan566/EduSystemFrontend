import '../../../teaching/domain/entities/teaching_period_entity.dart';
import '../../../teaching/presentation/shared/class_labels.dart';
import '../../domain/entities/student_entity.dart';

/// Enrollment status of a student's current course.
enum StudentStatusFilter { all, active, withdrawn }

enum StudentSort { lastName, firstName, code, recentEnrollment }

String studentSortLabel(StudentSort sort) => switch (sort) {
  StudentSort.lastName => 'Apellido (A–Z)',
  StudentSort.firstName => 'Nombre (A–Z)',
  StudentSort.code => 'Código',
  StudentSort.recentEnrollment => 'Más recientes',
};

String studentStatusLabel(StudentStatusFilter status) => switch (status) {
  StudentStatusFilter.all => 'Todos',
  StudentStatusFilter.active => 'Activos',
  StudentStatusFilter.withdrawn => 'Retirados',
};

/// The Students screen's filters. Course and search go to the API; status
/// and order apply to the loaded page. Owned by the page entry point so
/// they survive a layout switch.
class StudentListFilters {
  const StudentListFilters({
    this.groupId,
    this.search = '',
    this.status = StudentStatusFilter.all,
    this.sort = StudentSort.lastName,
  });

  final int? groupId;
  final String search;
  final StudentStatusFilter status;
  final StudentSort sort;

  StudentListFilters copyWith({
    int? Function()? groupId,
    String? search,
    StudentStatusFilter? status,
    StudentSort? sort,
  }) => StudentListFilters(
    groupId: groupId == null ? this.groupId : groupId(),
    search: search ?? this.search,
    status: status ?? this.status,
    sort: sort ?? this.sort,
  );

  List<StudentEntity> apply(List<StudentEntity> students) {
    final result = students.where((s) {
      final enrollment = s.currentEnrollment;
      return switch (status) {
        StudentStatusFilter.all => true,
        StudentStatusFilter.active => enrollment?.active ?? false,
        StudentStatusFilter.withdrawn => !(enrollment?.active ?? false),
      };
    }).toList();
    int byText(String a, String b) =>
        a.toLowerCase().compareTo(b.toLowerCase());
    switch (sort) {
      case StudentSort.lastName:
        break; // The API's own order.
      case StudentSort.firstName:
        result.sort((a, b) => byText(a.fullName, b.fullName));
      case StudentSort.code:
        result.sort((a, b) => a.studentCode.compareTo(b.studentCode));
      case StudentSort.recentEnrollment:
        final never = DateTime(0);
        result.sort(
          (a, b) => (b.currentEnrollment?.enrolledAt ?? never).compareTo(
            a.currentEnrollment?.enrolledAt ?? never,
          ),
        );
    }
    return result;
  }
}

/// A course (group) the teacher teaches, as a filter option.
class CourseOption {
  const CourseOption({required this.groupId, required this.label});

  final int groupId;
  final String label;
}

/// The teacher's courses from their classes, newest year first, then in
/// natural grade order; the year is added only where two courses share a
/// name (e.g. 5° A in 2025 and 2026).
List<CourseOption> teacherCourses(List<TeachingPeriodEntity> classes) {
  final byGroup = <int, TeachingPeriodEntity>{
    for (final c in classes) c.groupId: c,
  };
  final groups = byGroup.values.toList()
    ..sort((a, b) {
      final byYear = b.academicYear.compareTo(a.academicYear);
      if (byYear != 0) return byYear;
      final byGrade = compareGradeNames(a.gradeName, b.gradeName);
      return byGrade != 0 ? byGrade : a.courseLabel.compareTo(b.courseLabel);
    });
  final labels = courseLabels([
    for (final g in groups)
      (
        groupId: g.groupId,
        gradeName: g.gradeName,
        groupName: g.groupName,
        academicYear: g.academicYear,
      ),
  ]);
  return [
    for (final g in groups)
      CourseOption(groupId: g.groupId, label: labels[g.groupId]!),
  ];
}
