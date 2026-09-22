/// Breaks the [ApiClient] <-> `AuthProvider` circular dependency: the
/// client needs a callback to run when a refresh fails, but that callback
/// is a method on the provider, which itself needs the client. This is
/// constructed first (no dependencies), wired into [ApiClient], and its
/// [handler] is set to `authProvider.forceLogout` once that provider
/// exists — see `main.dart`.
class SessionExpiryNotifier {
  Future<void> Function()? handler;

  Future<void> notify() async {
    await handler?.call();
  }
}
