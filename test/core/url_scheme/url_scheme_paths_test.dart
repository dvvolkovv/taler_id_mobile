import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/url_scheme/url_scheme_paths.dart';

void main() {
  test('chat URI translates to messenger route', () {
    expect(UrlSchemePaths.translate(Uri.parse('talerid://chat/abc-123')),
           '/dashboard/messenger/chat/abc-123');
  });

  test('profile URI translates to profile route', () {
    expect(UrlSchemePaths.translate(Uri.parse('talerid://profile/u-7')),
           '/dashboard/profile/u-7');
  });

  test('calendar host with no path maps to calendar route', () {
    expect(UrlSchemePaths.translate(Uri.parse('talerid://calendar')),
           '/dashboard/calendar');
  });

  test('assistant host maps to assistant route', () {
    expect(UrlSchemePaths.translate(Uri.parse('talerid://assistant')),
           '/dashboard/assistant');
  });

  test('oauth-callback preserves query string', () {
    expect(UrlSchemePaths.translate(Uri.parse('talerid://oauth-callback?code=abc&state=xyz')),
           '/oauth/desktop-callback?code=abc&state=xyz');
  });

  test('unknown scheme returns null', () {
    expect(UrlSchemePaths.translate(Uri.parse('https://example.com')), isNull);
  });

  test('unknown talerid host returns null', () {
    expect(UrlSchemePaths.translate(Uri.parse('talerid://unknown/path')), isNull);
  });
}
