// Cover for which build is allowed to claim which domain.
//
// Every flavor used to declare all four hosts, on the assumption that a host
// the build isn't vouched for "simply never verifies". It verified: while
// api.talerid.io still served a stale assetlinks.json naming the aeza packages,
// the DEV build got itself verified for the DO domains — and Android caches a
// verification result, so correcting the served file did not revoke it. From
// then on a PROD sign-in link opened the DEV app, which asked the DEV backend
// about a grant issued on PROD and got 400 redirect_uri_mismatch (2026-08-04).
//
// A build declaring only its own host cannot be stolen this way, whatever any
// server happens to be serving at install time.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Hosts of `<data android:scheme="https" …>` entries in a manifest.
  Set<String> httpsHosts(String sourceSet) {
    final file = File('android/app/src/$sourceSet/AndroidManifest.xml');
    if (!file.existsSync()) return {};
    final xml = file.readAsStringSync();

    return RegExp(r'<data\s+android:scheme="https"[^>]*>')
        .allMatches(xml)
        .map((m) => RegExp(r'android:host="([^"]+)"').firstMatch(m.group(0)!))
        .whereType<RegExpMatch>()
        .map((m) => m.group(1)!)
        .toSet();
  }

  test('the shared manifest claims no domain', () {
    // Anything declared here lands in all three builds at once, which is how
    // the cross-track claim happened in the first place.
    expect(httpsHosts('main'), isEmpty);
  });

  test('each flavor claims only the backend it talks to', () {
    expect(httpsHosts('dev'), {'staging.id.taler.tirol'});
    expect(httpsHosts('prod'), {'id.taler.tirol'});
    expect(httpsHosts('talerid'), {'api.talerid.io', 'talerid.io'});
  });

  test('no domain is claimed by more than one flavor', () {
    final byFlavor = {
      for (final f in ['dev', 'prod', 'talerid']) f: httpsHosts(f),
    };

    for (final a in byFlavor.keys) {
      for (final b in byFlavor.keys) {
        if (a == b) continue;
        expect(
          byFlavor[a]!.intersection(byFlavor[b]!),
          isEmpty,
          reason: '$a and $b both claim a domain; whichever verifies first '
              'wins the link and then talks to the wrong backend',
        );
      }
    }
  });

  test('every flavor still declares the three deep-link paths', () {
    // Scoping the hosts must not quietly drop a filter.
    for (final flavor in ['dev', 'prod', 'talerid']) {
      final xml =
          File('android/app/src/$flavor/AndroidManifest.xml').readAsStringSync();

      expect(xml, contains('/room/'), reason: '$flavor lost the room links');
      expect(xml, contains('/ui/invite'), reason: '$flavor lost invite links');
      expect(xml, contains('/oauth/auth'), reason: '$flavor lost sign-in links');
      // /oauth/auth/{uid} continues the browser consent flow; matching it as a
      // prefix drags the user out of the browser mid-flow.
      expect(xml, isNot(contains('android:pathPrefix="/oauth/auth"')));
    }
  });
}
