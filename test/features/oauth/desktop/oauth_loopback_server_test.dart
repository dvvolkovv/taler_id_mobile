import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/oauth/desktop/oauth_loopback_server.dart';

void main() {
  test('binds to ephemeral port and accepts /cb?code=', () async {
    final server = OAuthLoopbackServer();
    final future = server.awaitCallback(timeout: const Duration(seconds: 5));

    // Wait until server is bound and exposes a port
    await Future.delayed(const Duration(milliseconds: 100));
    expect(server.port, isNotNull);

    // Hit /cb with a fake code
    final client = HttpClient();
    final req = await client.getUrl(
        Uri.parse('http://127.0.0.1:${server.port}/cb?code=test_code_123&state=abc'));
    final resp = await req.close();
    await resp.drain();
    client.close();

    final result = await future;
    expect(result.isSuccess, isTrue);
    expect(result.code, 'test_code_123');
    expect(result.state, 'abc');
  });

  test('returns error when error= query param present', () async {
    final server = OAuthLoopbackServer();
    final future = server.awaitCallback(timeout: const Duration(seconds: 5));
    await Future.delayed(const Duration(milliseconds: 100));

    final client = HttpClient();
    final req = await client.getUrl(
        Uri.parse('http://127.0.0.1:${server.port}/cb?error=access_denied'));
    final resp = await req.close();
    await resp.drain();
    client.close();

    final result = await future;
    expect(result.isSuccess, isFalse);
    expect(result.error, 'access_denied');
  });

  test('times out if no callback arrives', () async {
    final server = OAuthLoopbackServer();
    expect(
      () => server.awaitCallback(timeout: const Duration(milliseconds: 200)),
      throwsA(isA<TimeoutException>()),
    );
  });

  test('returns 404 for non-/cb paths', () async {
    final server = OAuthLoopbackServer();
    final future = server.awaitCallback(timeout: const Duration(seconds: 2));
    await Future.delayed(const Duration(milliseconds: 100));

    final client = HttpClient();
    final req = await client
        .getUrl(Uri.parse('http://127.0.0.1:${server.port}/other'));
    final resp = await req.close();
    expect(resp.statusCode, 404);
    await resp.drain();
    client.close();

    // Server should still be waiting for /cb; will time out
    expect(() => future, throwsA(isA<TimeoutException>()));
  });
}
