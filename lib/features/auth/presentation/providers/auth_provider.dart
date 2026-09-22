import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

enum AuthStatus { initial, authenticating, authenticated, unauthenticated }

/// Owns the session lifecycle for the whole app: restores a persisted
/// session at boot, drives login/logout, and is the `refreshListenable`
/// the router uses to redirect on 401 (§103, §15).
///
/// Extends [ChangeNotifier] directly (not a generic base) since auth state
/// is small and doesn't repeat the loading/success/error pattern other
/// list-oriented providers share.
class AuthProvider extends ChangeNotifier {
  AuthProvider({required AuthRepository repository, required ApiClient apiClient})
    : _repository = repository,
      _apiClient = apiClient;

  final AuthRepository _repository;
  final ApiClient _apiClient;

  AuthStatus _status = AuthStatus.initial;
  UserEntity? _user;
  AppException? _error;
  bool _sessionExpired = false;

  AuthStatus get status => _status;
  UserEntity? get user => _user;
  AppException? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// True right after the session was force-closed by a failed refresh —
  /// the login screen reads this once to show "Tu sesión ha expirado.".
  bool consumeSessionExpiredFlag() {
    final value = _sessionExpired;
    _sessionExpired = false;
    return value;
  }

  /// Called once at app startup.
  Future<void> restoreSession() async {
    final tokens = await _apiClient.restoreSession();
    if (tokens == null || tokens.isExpired) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      _user = await _repository.getCurrentUser();
      _status = AuthStatus.authenticated;
    } on AppException {
      await _apiClient.clearSession();
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  /// Wired into [ApiClient] as `onSessionExpired`: fires when a refresh
  /// attempt fails, so the router redirects to /login without leaving the
  /// user on a broken authenticated screen.
  Future<void> forceLogout() async {
    if (_status != AuthStatus.authenticated) return;
    _user = null;
    _status = AuthStatus.unauthenticated;
    _sessionExpired = true;
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) =>
      _guard(() async {
        final (_, user) = await _repository.login(email: email, password: password);
        _user = user;
        _status = AuthStatus.authenticated;
      });

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) => _guard(() async {
    final (_, user) = await _repository.register(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
    );
    _user = user;
    _status = AuthStatus.authenticated;
  });

  Future<void> logout() async {
    _status = AuthStatus.authenticating;
    notifyListeners();
    try {
      await _repository.logout();
    } catch (_) {
      // Local session is cleared regardless of whether the network call
      // succeeded — the backend revokes on a best-effort basis.
    }
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _guard(() async {
    final (_, user) = await _repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    _user = user;
    _status = AuthStatus.authenticated;
  });

  Future<bool> forgotPassword(String email) =>
      _guard(() => _repository.forgotPassword(email), keepStatus: true);

  Future<bool> verifyCode({required String email, required String code}) =>
      _guard(() => _repository.verifyCode(email: email, code: code), keepStatus: true);

  Future<bool> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) => _guard(
    () => _repository.resetPassword(email: email, code: code, newPassword: newPassword),
    keepStatus: true,
  );

  void updateUser(UserEntity user) {
    _user = user;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> _guard(
    Future<void> Function() action, {
    bool keepStatus = false,
  }) async {
    final previousStatus = _status;
    if (!keepStatus) _status = AuthStatus.authenticating;
    _error = null;
    notifyListeners();
    try {
      await action();
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _status = keepStatus ? previousStatus : AuthStatus.unauthenticated;
      _error = e;
      notifyListeners();
      return false;
    }
  }
}
