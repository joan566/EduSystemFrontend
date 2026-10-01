import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/app_version_policy.dart';
import '../models/app_version_policy_model.dart';

class AppVersionRemoteDataSource {
  AppVersionRemoteDataSource(this._client);

  final ApiClient _client;

  /// Public endpoint: sent without a token (see `AuthInterceptor`).
  Future<AppVersionPolicy> fetchPolicy() async {
    final response = await _client.get(ApiEndpoints.appVersion);
    return AppVersionPolicyModel.fromJson(response.data);
  }
}
