// Cover for the deep-link routing decision.
//
// Native OAuth login had been wired to /oauth/authorize since April, a path no
// environment has ever served — the OIDC authorization endpoint is /oauth/auth.
// So the app never once intercepted a sign-in link, and every partner login fell
// through to the browser (2026-08-03, found while integrating Linkeon).

import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/router/deep_link_handler.dart';

void main() {
  DeepLinkTarget? resolve(String url) => DeepLinkHandler.resolve(Uri.parse(url));

  group('OAuth links', () {
    const hosts = [
      'id.taler.tirol',
      'staging.id.taler.tirol',
      'api.talerid.io',
      'talerid.io',
    ];

    for (final host in hosts) {
      test('opens native consent for $host', () {
        final t = resolve('https://$host/oauth/auth?client_id=x&state=y');

        expect(t, isNotNull);
        expect(t!.location, '/oauth/authorize?client_id=x&state=y');
        // Pushed, so backing out returns the user where they were.
        expect(t.push, isTrue);
      });
    }

    test('leaves the continue URL of the browser flow alone', () {
      // /oauth/auth/{uid} is where the web consent page resumes. Matching the
      // path as a prefix would yank the user into the app mid-flow — the exact
      // breakage the browser fix was undoing.
      expect(resolve('https://api.talerid.io/oauth/auth/lMMqe4-xaPZO0loo'), isNull);
    });

    test('ignores an unknown host', () {
      expect(resolve('https://evil.example.com/oauth/auth?client_id=x'), isNull);
    });

    test('ignores the path that never existed', () {
      expect(resolve('https://api.talerid.io/oauth/authorize?client_id=x'), isNull);
    });

    test('carries no query through when there is none', () {
      expect(resolve('https://talerid.io/oauth/auth')!.location,
          '/oauth/authorize');
    });
  });

  group('other links still resolve', () {
    test('room code', () {
      final t = resolve('https://api.talerid.io/room/c5a9eeb5');
      expect(t!.location, '/dashboard/voice?publicCode=c5a9eeb5');
      expect(t.push, isFalse);
    });

    test('invite token', () {
      expect(resolve('https://id.taler.tirol/ui/invite.html?token=abc')!.location,
          '/invite?token=abc');
    });

    test('invite over the custom scheme', () {
      expect(resolve('talerid://invite?token=abc')!.location, '/invite?token=abc');
    });

    test('user profile over the custom scheme', () {
      expect(resolve('talerid://user/u-1')!.location, '/dashboard/user/u-1');
    });

    test('an invite link without a token is not acted on', () {
      expect(resolve('https://id.taler.tirol/ui/invite.html'), isNull);
    });

    test('an unrelated link is ignored', () {
      expect(resolve('https://id.taler.tirol/download/taler-id.apk'), isNull);
    });
  });

  group('duplicate delivery', () {
    setUp(DeepLinkHandler.resetDuplicateGuard);

    final uri = Uri.parse('https://api.talerid.io/oauth/auth?client_id=x');
    final t0 = DateTime(2026, 8, 3, 23, 9, 13);

    test('the cold-start double delivery is collapsed', () {
      // getInitialLink() and the stream both hand over the launching link,
      // which stacked two consent screens — cancelling one revealed another.
      expect(DeepLinkHandler.isDuplicate(uri, t0), isFalse);
      expect(DeepLinkHandler.isDuplicate(uri, t0.add(const Duration(milliseconds: 1))), isTrue);
    });

    test('opening the same link again later still works', () {
      expect(DeepLinkHandler.isDuplicate(uri, t0), isFalse);
      expect(DeepLinkHandler.isDuplicate(uri, t0.add(const Duration(seconds: 10))), isFalse);
    });

    test('a different link is never suppressed', () {
      expect(DeepLinkHandler.isDuplicate(uri, t0), isFalse);
      expect(
        DeepLinkHandler.isDuplicate(
          Uri.parse('https://talerid.io/room/abc'),
          t0.add(const Duration(milliseconds: 1)),
        ),
        isFalse,
      );
    });
  });
}
