import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../router/deep_link_handler.dart';

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

  final _pendingFilesCtrl = StreamController<List<SharedMediaFile>>.broadcast();
  Stream<List<SharedMediaFile>> get pendingFilesStream => _pendingFilesCtrl.stream;

  List<SharedMediaFile>? _initialFiles;
  List<SharedMediaFile>? get initialFiles => _initialFiles;

  StreamSubscription? _sub;

  void init() {
    // Handle files shared while app is running
    _sub = ReceiveSharingIntent.instance.getMediaStream().listen((raw) {
      final files = withoutDeepLinks(raw);
      if (files.isNotEmpty) {
        debugPrint('[ShareIntent] Received ${files.length} files while running');
        _pendingFilesCtrl.add(files);
      }
    });

    // Handle files shared when app was closed
    ReceiveSharingIntent.instance.getInitialMedia().then((raw) {
      final files = withoutDeepLinks(raw);
      if (files.isNotEmpty) {
        debugPrint('[ShareIntent] Received ${files.length} initial files');
        _initialFiles = files;
        _pendingFilesCtrl.add(files);
      }
    });
  }

  void clearFiles() {
    _initialFiles = null;
    ReceiveSharingIntent.instance.reset();
  }

  void dispose() {
    _sub?.cancel();
    _pendingFilesCtrl.close();
  }
}
