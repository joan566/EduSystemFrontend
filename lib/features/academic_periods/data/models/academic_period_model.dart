import '../../../../core/utils/formatters.dart';
import '../../domain/entities/academic_period_entity.dart';

class AcademicPeriodModel {
  static AcademicPeriodEntity fromJson(Map<String, dynamic> json) => AcademicPeriodEntity(
    id: json['id'] as int,
    name: json['name'] as String,
    startDate: Formatters.parseApiDate(json['startDate'] as String),
    endDate: Formatters.parseApiDate(json['endDate'] as String),
  );

  static Map<String, dynamic> toRequest({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
  }) => {
    'name': name,
    'startDate': Formatters.toApiDate(startDate),
    'endDate': Formatters.toApiDate(endDate),
  };
}
