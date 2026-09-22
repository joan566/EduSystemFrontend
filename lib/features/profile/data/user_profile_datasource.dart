import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../auth/data/models/user_model.dart';
import '../../auth/domain/entities/user_entity.dart';

class UserProfileDataSource {
  UserProfileDataSource(this._client);

  final ApiClient _client;

  Future<UserEntity> updateProfile({required String firstName, required String lastName}) async {
    final response = await _client.put(
      ApiEndpoints.usersMe,
      data: {'firstName': firstName, 'lastName': lastName},
    );
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }
}
