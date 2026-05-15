import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart' as wvf;

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

  @override
  void initState() {
    super.initState();
    if (Platform.isMacOS || Platform.isLinux) {
      _controller = wvf.WebViewController()
        ..setJavaScriptMode(wvf.JavaScriptMode.unrestricted)
        ..setNavigationDelegate(wvf.NavigationDelegate(
          onPageFinished: (url) {
            if (url.contains('/kyc/complete')) {
              widget.onComplete();
              if (mounted) Navigator.of(context).pop();
            }
          },
        ))
        ..loadRequest(Uri.parse(widget.webSdkUrl));
    }
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
