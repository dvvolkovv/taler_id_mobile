import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class ShareIntentService {
  static final ShareIntentService instance = ShareIntentService._();
  ShareIntentService._();

  final _pendingFilesCtrl = StreamController<List<SharedMediaFile>>.broadcast();
  Stream<List<SharedMediaFile>> get pendingFilesStream => _pendingFilesCtrl.stream;

  List<SharedMediaFile>? _initialFiles;
  List<SharedMediaFile>? get initialFiles => _initialFiles;

  StreamSubscription? _sub;

  void init() {
    // Handle files shared while app is running
    _sub = ReceiveSharingIntent.instance.getMediaStream().listen((files) {
      if (files.isNotEmpty) {
        debugPrint('[ShareIntent] Received ${files.length} files while running');
        _pendingFilesCtrl.add(files);
      }
    });

    // Handle files shared when app was closed
    ReceiveSharingIntent.instance.getInitialMedia().then((files) {
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
