import '../../domain/entities/subject_entity.dart';

class SubjectModel {
  static SubjectEntity fromJson(Map<String, dynamic> json) => SubjectEntity(
    id: json['id'] as int,
    name: json['name'] as String,
    description: json['description'] as String?,
  );

  static Map<String, dynamic> toRequest({required String name, String? description}) => {
    'name': name,
    if (description != null && description.isNotEmpty) 'description': description,
  };
}
