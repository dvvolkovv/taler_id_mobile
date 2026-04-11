import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import '../api/dio_client.dart';
import '../config/app_config.dart';
import '../di/service_locator.dart';

/// Represents a single call line.
class CallLine {
  final lk.Room room;
  final String roomName;
  final String? conversationId;
  final String? e2eeKey;
  String? calleeName;
  String? calleeAvatar;
  bool isOnHold;
  /// Mic state before the line was put on hold.
  bool wasMuted = false;
  /// When the call was connected (for duration display).
  DateTime? connectedAt;

  CallLine({
    required this.room,
    required this.roomName,
    this.conversationId,
    this.e2eeKey,
    this.calleeName,
    this.calleeAvatar,
    this.isOnHold = false,
  });
}

class CallStateService {
  static final instance = CallStateService._();
  CallStateService._();

  static const maxLines = 3;

  /// All active call lines, keyed by roomName.
  final Map<String, CallLine> _lines = {};
  /// Currently active (foreground) line.
  String? _activeRoomName;

  bool _bgConnecting = false;
  Completer<bool>? _bgCompleter;

  /// Rooms where the AI voice twin has taken over. These calls must survive
  /// a stale `call_ended` broadcast from the original human callee (their
  /// CallKit/push banner expired, they dismissed it, etc.) — we don't want
  /// Dashboard/CallKit cleanup to deactivate the iOS audio session while the
  /// caller is still talking to the AI twin.
  final Set<String> _aiTwinActiveRooms = {};
  void markAiTwinActive(String roomName) => _aiTwinActiveRooms.add(roomName);
  void unmarkAiTwinActive(String roomName) => _aiTwinActiveRooms.remove(roomName);
  bool isAiTwinRoom(String roomName) => _aiTwinActiveRooms.contains(roomName);

  final _stateCtrl = StreamController<bool>.broadcast();
  // Re-emit the current state to every new subscriber so the dashboard's
  // "active call" banner reappears correctly after the voice screen is
  // closed and the dashboard is rebuilt.
  Stream<bool> get stateStream async* {
    yield isInCall;
    yield* _stateCtrl.stream;
  }

  /// Emits the active roomName whenever the active line changes externally
  /// (e.g. CallKit accept of a second call). VoiceCallScreen subscribes to
  /// this to detect switches it didn't initiate.
  final _activeRoomCtrl = StreamController<String?>.broadcast();
  Stream<String?> get activeRoomStream => _activeRoomCtrl.stream;

  // ── Legacy single-room API (backward compatible) ─────────────────

  lk.Room? get room => activeLine?.room;
  String? get roomName => _activeRoomName;
  String? get conversationId => activeLine?.conversationId;
  String? get e2eeKey => activeLine?.e2eeKey;

  bool get isInCall => _lines.isNotEmpty;
  bool get isBackgroundConnecting => _bgConnecting;

  // ── Multi-line API ───────────────────────────────────────────────

  CallLine? get activeLine => _activeRoomName != null ? _lines[_activeRoomName] : null;
  List<CallLine> get allLines => _lines.values.toList();
  int get lineCount => _lines.length;
  bool get hasHeldLines => _lines.values.any((l) => l.isOnHold);
  bool get canAddLine => _lines.length < maxLines;

  Future<bool> waitForBackgroundConnect() async {
    if (!_bgConnecting || _bgCompleter == null) return isInCall;
    return _bgCompleter!.future;
  }

  void setRoom(lk.Room r, String name, String? convId, {String? e2eeKeyValue, String? calleeName, String? calleeAvatar}) {
    final line = CallLine(
      room: r,
      roomName: name,
      conversationId: convId,
      e2eeKey: e2eeKeyValue,
      calleeName: calleeName,
      calleeAvatar: calleeAvatar,
    );
    line.connectedAt = DateTime.now();
    _lines[name] = line;
    _activeRoomName = name;
    _stateCtrl.add(true);
    _activeRoomCtrl.add(name);
  }

  /// Put the active call on hold and switch to another line.
  Future<void> holdAndSwitch(String targetRoomName) async {
    final current = activeLine;
    if (current != null && current.roomName != targetRoomName) {
      // Save mic state before hold so it can be restored later.
      current.wasMuted = !(current.room.localParticipant?.isMicrophoneEnabled() ?? false);
      current.isOnHold = true;
      try {
        await current.room.localParticipant?.setMicrophoneEnabled(false);
        await current.room.localParticipant?.setCameraEnabled(false);
      } catch (_) {}
    }

    final target = _lines[targetRoomName];
    if (target != null) {
      target.isOnHold = false;
      _activeRoomName = targetRoomName;
      try {
        // Restore the mic state the user had before this line was held.
        await target.room.localParticipant?.setMicrophoneEnabled(!target.wasMuted);
      } catch (_) {}
      _stateCtrl.add(true);
      _activeRoomCtrl.add(targetRoomName);
    }
  }

  /// End a specific call line.
  Future<void> endLine(String name) async {
    final line = _lines.remove(name);
    if (line != null) {
      try { await line.room.disconnect(); } catch (_) {}
    }
    if (_activeRoomName == name) {
      // Switch to another held line if available
      if (_lines.isNotEmpty) {
        final next = _lines.values.first;
        _activeRoomName = next.roomName;
        next.isOnHold = false;
        try {
          await next.room.localParticipant?.setMicrophoneEnabled(!next.wasMuted);
        } catch (_) {}
        _activeRoomCtrl.add(next.roomName);
      } else {
        _activeRoomName = null;
        _activeRoomCtrl.add(null);
      }
    }
    _stateCtrl.add(_lines.isNotEmpty);
  }

  Future<void> endCall() async {
    final lines = List<CallLine>.from(_lines.values);
    _lines.clear();
    _activeRoomName = null;
    _bgConnecting = false;
    _stateCtrl.add(false);
    _activeRoomCtrl.add(null);
    for (final line in lines) {
      try { await line.room.disconnect(); } catch (_) {}
    }
  }

  void notifyEnded() {
    // Remove the active line (or all if unknown)
    if (_activeRoomName != null) {
      _lines.remove(_activeRoomName);
      if (_lines.isNotEmpty) {
        final next = _lines.values.first;
        _activeRoomName = next.roomName;
        next.isOnHold = false;
      } else {
        _activeRoomName = null;
      }
    } else {
      _lines.clear();
    }
    _bgConnecting = false;
    _stateCtrl.add(_lines.isNotEmpty);
  }

  /// Connect to a LiveKit room in the background after CallKit accept.
  Future<bool> connectInBackground(String rName, String? convId, {String? e2eeKey}) async {
    if (_lines.containsKey(rName)) return true;
    if (_lines.length >= maxLines) return false;
    if (_bgConnecting) return _bgCompleter?.future ?? Future.value(false);
    _bgConnecting = true;
    _bgCompleter = Completer<bool>();
    try {
      // Hold current active line, preserving mic state
      final current = activeLine;
      if (current != null) {
        current.wasMuted = !(current.room.localParticipant?.isMicrophoneEnabled() ?? false);
        current.isOnHold = true;
        try {
          await current.room.localParticipant?.setMicrophoneEnabled(false);
          await current.room.localParticipant?.setCameraEnabled(false);
        } catch (_) {}
      }

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
      try {
        await r.localParticipant?.setMicrophoneEnabled(true);
      } catch (_) {}
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        const audioChannel = MethodChannel('taler_id/audio');
        await audioChannel.invokeMethod('setAudioOutput', 'earpiece');
        await lk.Hardware.instance.setSpeakerphoneOn(false);
      } catch (_) {}
      debugPrint('[CallState] connectInBackground OK, room=$rName, e2ee=${e2eeKey != null}, lines=${_lines.length}');
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
