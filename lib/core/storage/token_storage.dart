import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Holds the session's JWT pair.
///
/// Never printed, never logged, never persisted outside secure storage.
class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  final String accessToken;
  final String refreshToken;

  /// Absolute expiry instant for [accessToken], computed from the
  /// backend's `expiresIn` (seconds) at the moment it was issued.
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// True when the token will expire within the next few seconds — used
  /// to proactively refresh instead of racing a 401.
  bool get isNearExpiry =>
      DateTime.now().isAfter(expiresAt.subtract(const Duration(seconds: 10)));
}

/// Secure, platform-appropriate persistence for JWTs.
///
/// - Android: Keystore-backed encrypted storage (`flutter_secure_storage`).
/// - Web: WebCrypto-backed encrypted storage; the encryption key itself is
///   a non-extractable `CryptoKey` kept in IndexedDB, so the value is not
///   plain `localStorage`. This is a best-effort mitigation — the backend
///   remains the sole authority on session validity (see API contract).
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'edusistem.access_token';
  static const _refreshTokenKey = 'edusistem.refresh_token';
  static const _expiresAtKey = 'edusistem.expires_at';

  Future<void> save(AuthTokens tokens) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: tokens.accessToken),
      _storage.write(key: _refreshTokenKey, value: tokens.refreshToken),
      _storage.write(
        key: _expiresAtKey,
        value: tokens.expiresAt.toIso8601String(),
      ),
    ]);
  }

  Future<AuthTokens?> read() async {
    final values = await Future.wait([
      _storage.read(key: _accessTokenKey),
      _storage.read(key: _refreshTokenKey),
      _storage.read(key: _expiresAtKey),
    ]);
    final accessToken = values[0];
    final refreshToken = values[1];
    final expiresAtRaw = values[2];
    if (accessToken == null || refreshToken == null || expiresAtRaw == null) {
      return null;
    }
    final expiresAt = DateTime.tryParse(expiresAtRaw);
    if (expiresAt == null) return null;
    return AuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
    );
  }

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _expiresAtKey),
    ]);
  }
}
