import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart' as wvf;

/// In-app WebView that hosts the KYC WebSDK wizard at
/// `${SUMSUB_BASE_URL}/idensic/sdk/checkup?accessToken=<token>`.
///
/// Bridges WebSDK `window.postMessage` events into Dart via a JavaScript
/// channel — on `idCheck.onApplicantSubmitted` /
/// `idCheck.onApplicantStatusChanged` we close the WebView and let the caller
/// poll `/kyc/status`.
class KycWebViewScreen extends StatefulWidget {
  final String webSdkUrl;
  final VoidCallback onComplete;
  const KycWebViewScreen({
    super.key,
    required this.webSdkUrl,
    required this.onComplete,
  });

  @override
  State<KycWebViewScreen> createState() => _KycWebViewScreenState();
}

class _KycWebViewScreenState extends State<KycWebViewScreen> {
  wvf.WebViewController? _controller;
  bool _completed = false;

  static const _idCheckBridgeJs = r'''
    (function () {
      if (window.__talerKycBridgeInstalled) return;
      window.__talerKycBridgeInstalled = true;
      window.addEventListener('message', function (e) {
        try {
          var d = e.data;
          if (d == null) return;
          var payload = typeof d === 'string' ? d : JSON.stringify(d);
          if (window.KycBridge && window.KycBridge.postMessage) {
            window.KycBridge.postMessage(payload);
          }
        } catch (_) {}
      });
    })();
  ''';

  @override
  void initState() {
    super.initState();
    if (Platform.isWindows) return;
    _controller = wvf.WebViewController()
      ..setJavaScriptMode(wvf.JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'KycBridge',
        onMessageReceived: _onBridgeMessage,
      )
      ..setNavigationDelegate(wvf.NavigationDelegate(
        onPageFinished: (url) async {
          await _controller?.runJavaScript(_idCheckBridgeJs);
          // Legacy fallback: some WebSDK builds navigate to /kyc/complete on
          // submit instead of emitting postMessage.
          if (url.contains('/kyc/complete')) _signalComplete();
        },
      ))
      ..loadRequest(Uri.parse(widget.webSdkUrl));
  }

  void _onBridgeMessage(wvf.JavaScriptMessage msg) {
    if (_completed) return;
    final raw = msg.message;
    Map<String, dynamic>? data;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) data = decoded;
    } catch (_) {}
    final type = data?['type'] as String? ?? '';
    debugPrint('[KycWebView] idCheck event: $type');
    switch (type) {
      case 'idCheck.onApplicantSubmitted':
      case 'idCheck.onApplicantStatusChanged':
      case 'idCheck.applicantStatus':
        _signalComplete();
        break;
      case 'idCheck.onError':
        // Close the wizard — bloc will surface the polled status as a fallback.
        _signalComplete();
        break;
      default:
        break;
    }
  }

  void _signalComplete() {
    if (_completed || !mounted) return;
    _completed = true;
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Верификация'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Platform.isWindows
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Верификация через web-форму на Windows будет добавлена в следующем релизе. '
                  'Пока используйте мобильное приложение Taler ID для прохождения KYC.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : _controller == null
              ? const Center(child: CircularProgressIndicator())
              : wvf.WebViewWidget(controller: _controller!),
    );
  }
}
