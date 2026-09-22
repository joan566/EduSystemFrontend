import '../../domain/entities/academic_level_entity.dart';

class AcademicLevelModel {
  static AcademicLevelEntity fromJson(Map<String, dynamic> json) => AcademicLevelEntity(
    id: json['id'] as int,
    name: json['name'] as String,
    description: json['description'] as String?,
  );

  static Map<String, dynamic> toRequest({required String name, String? description}) => {
    'name': name,
    if (description != null && description.isNotEmpty) 'description': description,
  };
}
