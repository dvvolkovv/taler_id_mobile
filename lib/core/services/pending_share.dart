import 'package:flutter/foundation.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

/// Holds a share from another app until the dashboard can show the
/// recipient picker.
///
/// One slot instead of a stream plus a cold-start copy: both used to reach
/// the dashboard, which then opened the picker twice, and a stream event
/// fired before anyone listened was lost (2026-10-31). A newer share replaces
/// one nobody has taken; [take] hands it out exactly once.
class PendingShare {
  final ValueNotifier<List<SharedMediaFile>?> _files = ValueNotifier(null);

  /// The waiting share; null when there is none.
  ValueListenable<List<SharedMediaFile>?> get files => _files;

  void offer(List<SharedMediaFile> files) {
    if (files.isEmpty) return;
    _files.value = List.unmodifiable(files);
  }

  List<SharedMediaFile>? take() {
    final files = _files.value;
    _files.value = null;
    return files;
  }
}
