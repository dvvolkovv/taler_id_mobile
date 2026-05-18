// lib/core/platform/voip_push_desktop.dart
import 'voip_push.dart';

/// Desktop no-op implementation of [VoipPushPlatform].
///
/// Desktop platforms (macOS, Windows, Linux) have no native VoIP push
/// mechanism in Phase 1.  Phase 2 may wire up a local-notification bridge
/// for macOS, but for now all methods are silent no-ops.
class VoipPushDesktop implements VoipPushPlatform {
  @override
  Future<String?> getToken() async => null;

  @override
  Stream<Map<String, dynamic>> get incomingPayloads => const Stream.empty();
}
