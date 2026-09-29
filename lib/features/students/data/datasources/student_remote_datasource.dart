import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/state/list_state.dart';
import '../../domain/entities/student_entity.dart';
import '../models/student_model.dart';

class StudentRemoteDataSource {
  StudentRemoteDataSource(this._client);

  final ApiClient _client;

  Future<ApiPage<StudentEntity>> getPage({int page = 0, int size = 20, int? groupId, String? search}) async {
    final response = await _client.get(
      ApiEndpoints.students,
      queryParameters: {'page': page, 'size': size, 'groupId': groupId, 'search': search},
    );
    return ApiPage.fromJson(response.data as Map<String, dynamic>, StudentModel.fromJson);
  }

  Future<StudentDetailEntity> getById(int id) async {
    final response = await _client.get(ApiEndpoints.studentById(id));
    return StudentModel.detailFromJson(response.data as Map<String, dynamic>);
  }

  Future<void> withdraw(int studentId, int groupId) =>
      _client.post(ApiEndpoints.studentWithdrawal(studentId, groupId));
}
