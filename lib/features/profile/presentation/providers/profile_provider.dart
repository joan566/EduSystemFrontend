import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/user_profile_datasource.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider({required UserProfileDataSource dataSource, required AuthProvider authProvider})
    : _dataSource = dataSource,
      _authProvider = authProvider;

  final UserProfileDataSource _dataSource;
  final AuthProvider _authProvider;

  bool _saving = false;
  bool get saving => _saving;

  Future<AppException?> updateProfile({required String firstName, required String lastName}) async {
    _saving = true;
    notifyListeners();
    try {
      final user = await _dataSource.updateProfile(firstName: firstName, lastName: lastName);
      _authProvider.updateUser(user);
      return null;
    } on AppException catch (e) {
      return e;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }
}
