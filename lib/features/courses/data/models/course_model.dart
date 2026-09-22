import '../../domain/entities/course_entity.dart';

class CourseModel {
  static CourseEntity fromJson(Map<String, dynamic> json) => CourseEntity(
    id: json['id'] as int,
    gradeId: json['gradeId'] as int,
    gradeName: json['gradeName'] as String,
    name: json['name'] as String,
    academicYear: json['academicYear'] as int,
  );

  static Map<String, dynamic> toCreateRequest({
    required int gradeId,
    required String name,
    required int academicYear,
  }) => {'gradeId': gradeId, 'name': name, 'academicYear': academicYear};

  static Map<String, dynamic> toUpdateRequest({
    required String name,
    required int academicYear,
  }) => {'name': name, 'academicYear': academicYear};
}
