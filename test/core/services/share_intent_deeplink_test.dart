// An App Link arrives as a VIEW intent carrying an https URI, and the sharing
// plugin reads the launching intent and offers it up as shared content. So the
// first deep link that ever reached the app opened the "forward to chat" sheet
// with the URL as an attachment, instead of the screen it addresses
// (2026-08-03, found while testing the Linkeon sign-in flow).

import 'package:flutter_test/flutter_test.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:taler_id_mobile/core/services/share_intent_service.dart';

SharedMediaFile file(String path) =>
    SharedMediaFile(path: path, type: SharedMediaType.text);

void main() {
  List<String> kept(List<String> paths) =>
      ShareIntentService.withoutDeepLinks(paths.map(file).toList())
          .map((f) => f.path)
          .toList();

  test('our own deep links are not treated as shared content', () {
    expect(
      kept([
        'https://api.talerid.io/oauth/auth?client_id=linkeon-partner-web',
        'https://talerid.io/room/c5a9eeb5',
        'https://id.taler.tirol/ui/invite.html?token=abc',
        'talerid://user/u-1',
      ]),
      isEmpty,
    );
  });

  test('genuinely shared content still comes through', () {
    const shared = [
      '/data/user/0/tirol.taler/cache/photo.jpg',
      'https://example.com/an-article',
      'Просто текст без ссылки',
    ];
    expect(kept(shared), shared);
  });

  test('a link to a host we do not own is shareable', () {
    // Only what DeepLinkHandler would act on is withheld.
    expect(
      kept(['https://evil.example.com/oauth/auth?client_id=x']),
      ['https://evil.example.com/oauth/auth?client_id=x'],
    );
  });

  test('the browser continue-URL is shareable, since the app ignores it', () {
    const url = 'https://api.talerid.io/oauth/auth/lMMqe4-xaPZO0loo';
    expect(kept([url]), [url]);
  });

  test('a mixed batch keeps only the real attachments', () {
    expect(
      kept([
        'https://talerid.io/room/abc',
        '/tmp/doc.pdf',
      ]),
      ['/tmp/doc.pdf'],
    );
  });
}
