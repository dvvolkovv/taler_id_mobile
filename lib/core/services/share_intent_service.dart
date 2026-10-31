import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../router/deep_link_handler.dart';
import 'pending_share.dart';

class ShareIntentService {
  static final ShareIntentService instance = ShareIntentService._();
  ShareIntentService._();

  /// Drops entries that are really one of our own deep links.
  ///
  /// The plugin reads the launching intent, and an App Link arrives as a VIEW
  /// intent carrying an https URI — which it offers up as shared content. So a
  /// room invite or a "sign in with Taler ID" link opened the "forward to chat"
  /// sheet with the URL as an attachment instead of the screen it addresses
  /// (2026-08-03). Those belong to DeepLinkHandler, which is asked here rather
  /// than duplicating the host list.
  @visibleForTesting
  static List<SharedMediaFile> withoutDeepLinks(List<SharedMediaFile> files) {
    return files.where((f) {
      final uri = Uri.tryParse(f.path);
      if (uri == null || !uri.hasScheme) return true;
      return DeepLinkHandler.resolve(uri) == null;
    }).toList(growable: false);
  }

  final _pending = PendingShare();

  /// The share waiting for the recipient picker; null when there is none.
  /// The dashboard listens and takes it once it can show the picker.
  ValueListenable<List<SharedMediaFile>?> get pending => _pending.files;

  StreamSubscription? _sub;

  void init() {
    // Shared while the app was running.
    _sub = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen((raw) => _offer(raw, 'while running'));
    // Shared into a closed app.
    ReceiveSharingIntent.instance
        .getInitialMedia()
        .then((raw) => _offer(raw, 'at launch'));
  }

  void _offer(List<SharedMediaFile> raw, String when) {
    final files = withoutDeepLinks(raw);
    if (files.isEmpty) return;
    debugPrint('[ShareIntent] Received ${files.length} files $when');
    _pending.offer(files);
  }

  /// Hands the pending share out once and drops the plugin's copy, so a
  /// restarted engine does not deliver the same files again.
  List<SharedMediaFile>? take() {
    final files = _pending.take();
    if (files != null) ReceiveSharingIntent.instance.reset();
    return files;
  }

  void dispose() {
    _sub?.cancel();
  }
}
