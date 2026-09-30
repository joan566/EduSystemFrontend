import 'package:edusistem_front/core/errors/app_exception.dart';
import 'package:edusistem_front/core/storage/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_backend.dart';

AuthTokens _tokens(String who) => AuthTokens(
  accessToken: 'access-$who',
  refreshToken: 'refresh-$who',
  expiresAt: DateTime.now().add(const Duration(hours: 1)),
);

void main() {
  test("a refresh started in A's session never lands in B's", () async {
    final backend = FakeBackend();
    final seenTokens = <String?>[];
    backend.on('GET', '/subjects', (r) {
      final auth = r.headers['Authorization'] as String?;
      seenTokens.add(auth);
      if (auth == 'Bearer access-A') throw const FakeHttpError(401);
      return pageOf(const [], r);
    });
    backend.on(
      'POST',
      '/auth/refresh',
      (_) => {
        'accessToken': 'access-A2',
        'refreshToken': 'refresh-A2',
        'expiresIn': 3600,
      },
    );
    final refresh = backend.hold('POST', '/auth/refresh');
    final api = backend.client();
    await api.setSession(_tokens('A'));

    // A's request expires and starts a refresh that hangs...
    final request = api.get('/subjects');
    await pumpEventQueue();

    // ...meanwhile A logs out and B signs in.
    await api.clearSession();
    await api.setSession(_tokens('B'));

    refresh.complete();
    await expectLater(request, throwsA(isA<AppException>()));

    // B's session is untouched and A's request was not replayed as B.
    expect(api.currentTokens?.accessToken, 'access-B');
    expect(seenTokens, ['Bearer access-A']);
  });

  test('a normal refresh still retries the request once', () async {
    final backend = FakeBackend();
    backend.on('GET', '/subjects', (r) {
      if (r.headers['Authorization'] == 'Bearer access-A') {
        throw const FakeHttpError(401);
      }
      return pageOf(const [], r);
    });
    backend.on(
      'POST',
      '/auth/refresh',
      (_) => {
        'accessToken': 'access-A2',
        'refreshToken': 'refresh-A2',
        'expiresIn': 3600,
      },
    );
    final api = backend.client();
    await api.setSession(_tokens('A'));

    final response = await api.get('/subjects');
    expect(response.statusCode, 200);
    expect(api.currentTokens?.accessToken, 'access-A2');
  });
}
