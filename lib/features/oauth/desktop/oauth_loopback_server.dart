import 'dart:async';
import 'dart:io';
import 'oauth_loopback_pages.dart';

class OAuthLoopbackResult {
  final String? code;
  final String? state;
  final String? error;
  const OAuthLoopbackResult({this.code, this.state, this.error});
  bool get isSuccess => code != null;
}

class OAuthLoopbackServer {
  HttpServer? _server;

  /// Binds to an ephemeral 127.0.0.1 port and waits up to [timeout] for a
  /// `GET /cb?code=...&state=...` request. Returns the parsed result.
  /// Throws [TimeoutException] if no callback arrives.
  Future<OAuthLoopbackResult> awaitCallback({
    Duration timeout = const Duration(minutes: 5),
  }) async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final completer = Completer<OAuthLoopbackResult>();

    _server!.listen((req) async {
      if (req.uri.path != '/cb') {
        req.response.statusCode = HttpStatus.notFound;
        await req.response.close();
        return;
      }
      final code = req.uri.queryParameters['code'];
      final state = req.uri.queryParameters['state'];
      final error = req.uri.queryParameters['error'];
      final result = OAuthLoopbackResult(code: code, state: state, error: error);

      req.response.headers.contentType = ContentType.html;
      req.response.write(result.isSuccess
          ? OAuthLoopbackPages.success
          : OAuthLoopbackPages.error(error ?? 'unknown'));
      await req.response.close();

      if (!completer.isCompleted) completer.complete(result);
    });

    try {
      return await completer.future.timeout(timeout);
    } finally {
      await _server?.close(force: true);
      _server = null;
    }
  }

  int? get port => _server?.port;
  String? get redirectUri =>
      _server == null ? null : 'http://127.0.0.1:${_server!.port}/cb';
}
