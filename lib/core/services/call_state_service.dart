import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import '../api/dio_client.dart';
import '../config/app_config.dart';
import '../di/service_locator.dart';

class CallStateService {
  static final instance = CallStateService._();
  CallStateService._();

  lk.Room? room;
  String? roomName;
  String? conversationId;
  String? e2eeKey;
  bool _bgConnecting = false;
  Completer<bool>? _bgCompleter;

  final _stateCtrl = StreamController<bool>.broadcast();
  Stream<bool> get stateStream => _stateCtrl.stream;

  bool get isInCall =>
      room != null &&
      room!.connectionState != lk.ConnectionState.disconnected;

  /// True if a background connect is in progress.
  bool get isBackgroundConnecting => _bgConnecting;

  /// Wait for an in-progress background connect to finish.
  /// Returns true if successfully connected, false otherwise.
  Future<bool> waitForBackgroundConnect() async {
    if (!_bgConnecting || _bgCompleter == null) return isInCall;
    return _bgCompleter!.future;
  }

  void setRoom(lk.Room r, String name, String? convId, {String? e2eeKeyValue}) {
    room = r;
    roomName = name;
    conversationId = convId;
    e2eeKey = e2eeKeyValue;
    _stateCtrl.add(true);
  }

  Future<void> endCall() async {
    final r = room;
    room = null;
    roomName = null;
    conversationId = null;
    e2eeKey = null;
    _bgConnecting = false;
    _stateCtrl.add(false);
    // Disconnect AFTER clearing state — await so the server receives the signal
    try {
      await r?.disconnect();
    } catch (_) {}
  }

  void notifyEnded() {
    room = null;
    roomName = null;
    conversationId = null;
    e2eeKey = null;
    _bgConnecting = false;
    _stateCtrl.add(false);
  }

  /// Connect to a LiveKit room in the background after CallKit accept.
  /// This establishes the audio connection immediately so the caller sees
  /// the callee join the room — even while CallKit's native UI is still showing.
  /// VoiceCallScreen will detect the existing room in initState and resume it.
  Future<bool> connectInBackground(String rName, String? convId, {String? e2eeKey}) async {
    if (isInCall) return true;
    if (_bgConnecting) return _bgCompleter?.future ?? Future.value(false);
    _bgConnecting = true;
    _bgCompleter = Completer<bool>();
    try {
      final client = sl<DioClient>();
      final res = await client.post<Map<String, dynamic>>(
        '/voice/rooms/$rName/join',
        data: {},
        fromJson: (d) => Map<String, dynamic>.from(d as Map),
      );
      final token = res['token'] as String;
      final r = lk.Room();

      lk.E2EEOptions? e2eeOptions;
      if (e2eeKey != null) {
        final keyProvider = await lk.BaseKeyProvider.create(sharedKey: true);
        await keyProvider.setSharedKey(e2eeKey);
        e2eeOptions = lk.E2EEOptions(keyProvider: keyProvider);
      }

      await r.connect(
        '${AppConfig.baseUrl.replaceFirst('https://', 'wss://')}/livekit/',
        token,
        roomOptions: lk.RoomOptions(
          e2eeOptions: e2eeOptions,
          defaultAudioPublishOptions: const lk.AudioPublishOptions(audioBitrate: 32000),
        ),
      );
      setRoom(r, rName, convId, e2eeKeyValue: e2eeKey);
      // Enable microphone — CallKit's audio session is active so this should work
      try {
        await r.localParticipant?.setMicrophoneEnabled(true);
      } catch (_) {}
      debugPrint('[CallState] connectInBackground OK, room=$rName, e2ee=${e2eeKey != null}');
      _bgConnecting = false;
      _bgCompleter?.complete(true);
      _bgCompleter = null;
      return true;
    } catch (e) {
      debugPrint('[CallState] connectInBackground failed: $e');
      _bgConnecting = false;
      _bgCompleter?.complete(false);
      _bgCompleter = null;
      return false;
    }
  }
}
