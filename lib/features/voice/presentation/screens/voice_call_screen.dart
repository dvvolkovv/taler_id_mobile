import 'dart:async';
import 'dart:io' show Platform;
import 'package:audioplayers/audioplayers.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:go_router/go_router.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/service_locator.dart';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/services/call_state_service.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_state.dart';
import '../../../messenger/data/datasources/messenger_remote_datasource.dart';
import '../../../messenger/domain/entities/user_search_entity.dart';

class VoiceCallScreen extends StatefulWidget {
  final String? roomName; // null = create new room with AI
  final String? conversationId; // for sending call_ended when hanging up
  final bool isIncoming; // opened from FCM push notification
  final String? calleeName; // name of the person being called (outgoing)
  final String? e2eeKey; // E2EE shared key for human-to-human calls (null = no E2EE)
  final String? publicCode; // public room code — join without auth via /voice/rooms/public/{code}/join
  const VoiceCallScreen({
    super.key,
    this.roomName,
    this.conversationId,
    this.isIncoming = false,
    this.calleeName,
    this.e2eeKey,
    this.publicCode,
  });

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen>
    with WidgetsBindingObserver {
  lk.Room? _room;
  bool _connecting = true;
  bool _muted = false;
  String _audioOutputType = 'earpiece'; // earpiece, speaker, bluetooth, headphones
  bool _reconnecting = false;
  bool _manualReconnecting = false;
  int _reconnectAttempts = 0;
  static const _kMaxReconnectAttempts = 8;
  static const _kReconnectDelays = [2, 3, 4, 5, 8, 10, 15, 20];
  final AudioPlayer _ringPlayer = AudioPlayer();
  bool _ringbackActive = false;
  Timer? _ringbackTimer;

  static const _outputIcons = <String, IconData>{
    'earpiece': Icons.phone_in_talk_rounded,
    'speaker': Icons.volume_up_rounded,
    'bluetooth': Icons.bluetooth_audio_rounded,
    'headphones': Icons.headphones_rounded,
  };

  static const _outputLabels = <String, String>{
    'earpiece': 'Телефон',
    'speaker': 'Динамик',
    'bluetooth': 'Bluetooth',
    'headphones': 'Наушники',
  };
  String? _error;
  bool _ringing = false; // outgoing: ringback playing, waiting for callee to answer
  bool _navigatedAway = false;
  bool _aiRecording = false;
  bool _isRecording = false; // simple recording (no AI analysis)
  String? _roomName; // actual room name (resolved after connect)
  String? _publicRoomCreatorName; // owner name fetched from GET /voice/rooms/public/{code}
  String? _publicRoomCreatorAvatar; // owner avatar URL
  String? _publicRoomTitle; // room title
  final List<lk.RemoteParticipant> _participants = [];
  lk.EventsListener<lk.RoomEvent>? _eventsListener;
  StreamSubscription? _callEndedSub;
  Timer? _emptyRoomTimer;

  // Server-side translation state
  String _preferredLang = 'ru';
  bool _translationEnabled = false;
  bool _translationActive = false; // translator agent is running

  static const Map<String, String> _translationLangs = {
    'ru': 'Русский',
    'en': 'English',
    'de': 'Deutsch',
    'fr': 'Français',
    'es': 'Español',
    'it': 'Italiano',
    'pt': 'Português',
    'tr': 'Türkçe',
    'zh': '中文',
    'ja': '日本語',
    'ko': '한국어',
    'ar': 'العربية',
  };

  // Video state
  bool _cameraOn = false;
  bool _screenShareFullscreen = false;
  String? _screenShareParticipantName;
  bool _isFrontCamera = true;
  final TransformationController _screenShareTransformCtrl = TransformationController();

  static const _audioChannel = MethodChannel('taler_id/audio');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Listen for audio interruptions from native (parallel call from phone/other app)
    _audioChannel.setMethodCallHandler(_onNativeAudioEvent);
    // Listen for call_ended socket event — the other party hung up
    _callEndedSub = sl<MessengerRemoteDataSource>()
        .callEndedStream
        .listen((roomName) {
      if (!mounted || _navigatedAway) return;
      final ourRoom = _roomName ?? CallStateService.instance.roomName;
      if (ourRoom == roomName) {
        _hangUp();
      }
    });
    _initCall();
  }

  /// Initialise the call — either resume an existing background-connected room,
  /// wait for a background connect in progress, or start a fresh connection.
  Future<void> _initCall() async {
    final cs = CallStateService.instance;

    // If background connect is still in progress, wait for it (up to 5s)
    if (cs.isBackgroundConnecting) {
      debugPrint('[VoiceCall] waiting for background connect...');
      await cs.waitForBackgroundConnect().timeout(
        const Duration(seconds: 5),
        onTimeout: () => false,
      );
    }

    // Resume existing room if already connected (e.g. from background connect)
    if (cs.isInCall && cs.room != null) {
      _room = cs.room;
      _roomName = cs.roomName;
      _connecting = false;
      _participants.addAll(_room!.remoteParticipants.values);
      // Detect if recorder is already in the room
      _aiRecording = _participants.any((p) => p.identity == 'meeting-recorder');
      _room!.addListener(_onRoomChanged);
      _subscribeRoomEvents();
      // Manually subscribe to tracks — background connect may have missed subscriptions
      for (final p in _room!.remoteParticipants.values) {
        for (final pub in [...p.audioTrackPublications, ...p.videoTrackPublications]) {
          if (!pub.subscribed) {
            try { pub.subscribe(); } catch (_) {}
          }
        }
      }
      // End CallKit and restore audio — must be properly sequenced
      if (widget.isIncoming) {
        await _restoreAudioAfterCallKit();
      }
      // Notify other devices this device answered (dismiss their CallKit)
      if (widget.isIncoming && widget.conversationId != null && _roomName != null) {
        try {
          sl<MessengerRemoteDataSource>().sendCallAnswered(widget.conversationId!, _roomName!);
        } catch (_) {}
      }
      if (mounted) setState(() {});
      WakelockPlus.enable();
    } else {
      _connect();
    }
  }

  Future<dynamic> _onNativeAudioEvent(MethodCall call) async {
    if (call.method == 'audioInterrupted') {
      _playInterruptionBeeps();
    } else if (call.method == 'audioResumed') {
      // Reactivate audio focus so LiveKit resumes after parallel call ends
      try {
        await _audioChannel.invokeMethod('requestAudioFocus');
      } catch (_) {}
      // Re-enable microphone — OS may have disabled it during interruption
      try {
        await _room?.localParticipant?.setMicrophoneEnabled(true);
      } catch (_) {}
      // Re-subscribe to remote audio tracks that may have been paused
      if (_room != null) {
        for (final p in _room!.remoteParticipants.values) {
          for (final pub in p.audioTrackPublications) {
            if (!pub.subscribed) {
              try { pub.subscribe(); } catch (_) {}
            }
          }
        }
      }
      if (mounted) setState(() {});
    }
    return null;
  }

  Future<void> _playInterruptionBeeps() async {
    for (int i = 0; i < 3; i++) {
      if (!mounted) return;
      try {
        await _ringPlayer.play(AssetSource('audio/ringback.wav'), volume: 0.7);
        await Future.delayed(const Duration(milliseconds: 180));
        await _ringPlayer.stop();
        if (i < 2) await Future.delayed(const Duration(milliseconds: 350));
      } catch (_) {}
    }
  }

  /// End CallKit and properly restore the audio session for LiveKit.
  /// Must be async and properly sequenced: endAllCalls() triggers iOS to
  /// deactivate the audio session. We must WAIT for that to complete, then
  /// re-activate the session for LiveKit.
  Future<void> _restoreAudioAfterCallKit() async {
    debugPrint('[VoiceCall] _restoreAudioAfterCallKit: starting');
    try {
      await FlutterCallkitIncoming.endAllCalls();
      debugPrint('[VoiceCall] _restoreAudioAfterCallKit: endAllCalls done');
    } catch (e) {
      debugPrint('[VoiceCall] _restoreAudioAfterCallKit: endAllCalls error: $e');
    }
    // Wait for CallKit to fully release the audio session.
    // iOS CXProvider.reportCall(endedAt:) triggers async audio deactivation
    // and DashboardScreen's actionCallDecline handler may also fire endCall.
    // 1 second is enough for both to complete.
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted || _navigatedAway) return;
    // Re-activate audio session for LiveKit — retry multiple times
    // because iOS audio deactivation timing is unpredictable.
    // Check _navigatedAway on each retry to stop if user already hung up.
    for (final delay in [0, 500, 1000, 2000]) {
      if (delay > 0) {
        await Future.delayed(Duration(milliseconds: delay));
        if (!mounted || _navigatedAway) return;
      }
      try {
        await _audioChannel.invokeMethod('requestAudioFocus');
      } catch (_) {}
      try {
        await _room?.localParticipant?.setMicrophoneEnabled(true);
      } catch (_) {}
    }
    debugPrint('[VoiceCall] _restoreAudioAfterCallKit: complete');
  }

  Future<void> _connect() async {
    debugPrint('[VoiceCall] _connect() called, isIncoming=${widget.isIncoming}, room=${widget.roomName}');
    if (widget.isIncoming) {
      // Release the CallKit-owned audio session before LiveKit connects.
      // When accepting from locked screen, CallKit activates the audio session
      // but continues to "own" it — this blocks LiveKit's WebRTC audio stack.
      try {
        await FlutterCallkitIncoming.endAllCalls();
        debugPrint('[VoiceCall] endAllCalls() done');
      } catch (e) {
        debugPrint('[VoiceCall] endAllCalls() error: $e');
      }
      // Wait for CallKit to fully release the audio session
      await Future.delayed(const Duration(milliseconds: 1000));
      // Re-activate audio session independently for LiveKit
      try {
        await _audioChannel.invokeMethod('requestAudioFocus');
      } catch (_) {}
    }
    // Play ringback tone for outgoing calls to user (not incoming, not AI assistant)
    if (!widget.isIncoming && widget.roomName != null) {
      if (mounted) setState(() => _ringing = true);
      _startRingback();
    }
    try {
      final client = sl<DioClient>();
      late Map<String, dynamic> res;

      if (widget.publicCode != null) {
        // 1. Fetch public room info (no auth required)
        Map<String, dynamic>? roomInfo;
        try {
          final rawDio = dio_pkg.Dio(dio_pkg.BaseOptions(baseUrl: ApiConstants.baseUrl));
          final infoResp = await rawDio.get('/voice/rooms/public/${widget.publicCode}');
          roomInfo = Map<String, dynamic>.from(infoResp.data as Map);
        } catch (_) {}

        if (!mounted) return;

        // 2. Show join dialog — room info + optional password
        final joinResult = await _showJoinRoomDialog(roomInfo);
        if (joinResult == null || !mounted) {
          _navigateBack();
          return;
        }
        final roomPassword = joinResult['password'] as String?;

        // 3. Try authenticated join first, fall back to guest
        try {
          res = await client.post(
            '/voice/rooms/public/${widget.publicCode}/join-auth',
            data: roomPassword != null && roomPassword.isNotEmpty
                ? {'password': roomPassword}
                : {},
            fromJson: (d) => Map<String, dynamic>.from(d as Map),
          );
        } catch (_) {
          // Not logged in or auth failed — ask for guest name then join
          final guestName = await _askForGuestName();
          if (guestName == null || !mounted) return;
          final rawDio = dio_pkg.Dio(dio_pkg.BaseOptions(baseUrl: ApiConstants.baseUrl));
          final resp = await rawDio.post(
            '/voice/rooms/public/${widget.publicCode}/join',
            data: {
              'name': guestName,
              if (roomPassword != null && roomPassword.isNotEmpty) 'password': roomPassword,
            },
          );
          res = Map<String, dynamic>.from(resp.data as Map);
        }
      } else if (widget.roomName == null) {
        res = await client.post(
          '/voice/rooms',
          data: {},
          fromJson: (d) => Map<String, dynamic>.from(d as Map),
        );
      } else {
        res = await client.post(
          '/voice/rooms/${widget.roomName}/join',
          data: {},
          fromJson: (d) => Map<String, dynamic>.from(d as Map),
        );
      }

      final token = res['token'] as String;
      _roomName = (res['roomName'] as String?) ?? widget.roomName ?? 'room-${DateTime.now().millisecondsSinceEpoch}';
      debugPrint('[VoiceCall] API join OK, roomName=$_roomName, e2ee=${widget.e2eeKey != null}');
      // Configure E2EE for human-to-human calls
      lk.E2EEOptions? e2eeOptions;
      final e2eeKey = widget.e2eeKey ?? CallStateService.instance.e2eeKey;
      if (e2eeKey != null) {
        final keyProvider = await lk.BaseKeyProvider.create(sharedKey: true);
        await keyProvider.setSharedKey(e2eeKey);
        e2eeOptions = lk.E2EEOptions(keyProvider: keyProvider);
      }

      _room = lk.Room(
        roomOptions: lk.RoomOptions(
          e2eeOptions: e2eeOptions,
          defaultAudioPublishOptions: const lk.AudioPublishOptions(
            audioBitrate: 32000,
          ),
        ),
      );

      _room!.addListener(_onRoomChanged);
      _subscribeRoomEvents();

      await _room!.connect(
        '${AppConfig.baseUrl.replaceFirst('https://', 'wss://')}/livekit/',
        token,
        connectOptions: const lk.ConnectOptions(autoSubscribe: false),
      );
      debugPrint('[VoiceCall] LiveKit connected, state=${_room!.connectionState}');

      // Register in global state so call persists across navigation
      CallStateService.instance.setRoom(
        _room!,
        _roomName!,
        widget.conversationId,
        e2eeKeyValue: e2eeKey,
      );

      // Notify other devices: this device answered the call (dismiss CallKit on others)
      if (widget.isIncoming && widget.conversationId != null) {
        try {
          sl<MessengerRemoteDataSource>().sendCallAnswered(widget.conversationId!, _roomName!);
        } catch (_) {}
      }

      // Initial participants
      setState(() {
        _participants.addAll(_room!.remoteParticipants.values);
      });

      // With autoSubscribe:false, manually subscribe to existing tracks
      for (final p in _room!.remoteParticipants.values) {
        if (p.identity == 'voice-translator') {
          // Subscribe only to the translation track matching user's preferred language
          if (_translationEnabled) {
            for (final pub in p.audioTrackPublications) {
              if (pub.name == 'translation-$_preferredLang') {
                try { pub.subscribe(); } catch (_) {}
              }
            }
          }
          continue;
        }
        for (final pub in [...p.audioTrackPublications, ...p.videoTrackPublications]) {
          try { pub.subscribe(); } catch (_) {}
        }
      }

      // If there are already human participants in the room, stop ringback immediately
      if (_participants.any((p) => p.identity != 'ai-assistant')) {
        _stopRingback();
      }

      // Request audio focus BEFORE enabling microphone — ensures the audio session
      // is active (critical after endAllCalls() deactivated it for incoming calls).
      try {
        await _audioChannel.invokeMethod('requestAudioFocus');
      } catch (_) {}

      // Enable microphone; may fail on iOS simulator — don't treat as fatal
      try {
        await _room!.localParticipant?.setMicrophoneEnabled(true);
      } catch (_) {}

      setState(() => _connecting = false);
      WakelockPlus.enable();

      // Force earpiece mode — LiveKit may override speakerphone asynchronously on Android.
      // Call twice: once early, once after LiveKit audio stack fully initialises.
      _forceEarpiece();
    } catch (e) {
      debugPrint('[VoiceCall] _connect() error: $e');
      setState(() {
        _error = e.toString();
        _connecting = false;
      });
    }
  }

  /// Sets audio output to earpiece. Called multiple times with increasing delays
  /// to override LiveKit/WebRTC's async speakerphone activation on Android.
  /// Uses both LiveKit Hardware API and native channel for reliable control.
  Future<void> _forceEarpiece() async {
    for (final delay in [100, 300, 700, 1500, 3000]) {
      await Future.delayed(Duration(milliseconds: delay));
      if (!mounted) return;
      // Only force earpiece if user hasn't manually switched to another output
      if (_audioOutputType == 'earpiece') {
        try {
          await lk.Hardware.instance.setSpeakerphoneOn(false);
        } catch (_) {}
        try {
          await _audioChannel.invokeMethod('setAudioOutput', 'earpiece');
        } catch (_) {}
      }
    }
  }

  void _subscribeRoomEvents() {
    final room = _room;
    if (room == null) return;
    _eventsListener = room.createListener();
    _eventsListener!
      ..on<lk.RoomReconnectingEvent>((_) {
        if (mounted) setState(() => _reconnecting = true);
      })
      ..on<lk.RoomReconnectedEvent>((_) async {
        if (!mounted) return;
        _reconnectAttempts = 0;
        // Restore mic and audio focus after LiveKit auto-reconnect
        try { await _room?.localParticipant?.setMicrophoneEnabled(!_muted); } catch (_) {}
        try { await _audioChannel.invokeMethod('requestAudioFocus'); } catch (_) {}
        _forceEarpiece();
        setState(() => _reconnecting = false);
      })
      ..on<lk.RoomDisconnectedEvent>((_) {
        // LiveKit gave up — start our own reconnect loop
        if (mounted && !_navigatedAway && !_manualReconnecting) {
          if (mounted) setState(() => _reconnecting = false);
          _startManualReconnect();
        }
      })
      ..on<lk.LocalTrackPublishedEvent>((event) {
        debugPrint('[VoiceCall] LocalTrackPublished: sid=${event.publication.sid} '
            'muted=${event.publication.muted} kind=${event.publication.kind}');
        if (mounted) setState(() {});
      })
      ..on<lk.LocalTrackUnpublishedEvent>((_) {
        if (mounted) setState(() {});
      })
      ..on<lk.TrackSubscribedEvent>((event) {
        if (mounted) setState(() {});
      })
      ..on<lk.TrackUnsubscribedEvent>((_) {
        if (mounted) setState(() {});
      })
      ..on<lk.TrackMutedEvent>((_) {
        if (mounted) setState(() {});
      })
      ..on<lk.TrackUnmutedEvent>((_) {
        if (mounted) setState(() {});
      })
      ..on<lk.ParticipantConnectedEvent>((event) async {
        // Only stop ringback when a HUMAN answers — AI agent joins first for withAi rooms
        if (event.participant.identity != 'ai-assistant') {
          _stopRingback();
        }
        // Auto-detect meeting recorder joining
        if (event.participant.identity == 'meeting-recorder') {
          if (mounted) setState(() => _aiRecording = true);
        }
      })
      ..on<lk.TrackPublishedEvent>((event) {
        if (event.participant.identity == 'voice-translator') {
          final wantedName = 'translation-$_preferredLang';
          if (_translationEnabled && event.publication.name == wantedName) {
            try { event.publication.subscribe(); } catch (_) {}
          }
          return;
        }
        try { event.publication.subscribe(); } catch (_) {}
      })
      ..on<lk.ParticipantDisconnectedEvent>((event) {
        if (!mounted || _navigatedAway) return;
        // Auto-detect meeting recorder leaving
        if (event.participant.identity == 'meeting-recorder') {
          if (mounted) setState(() => _aiRecording = false);
        }
        // Just update UI — each participant leaves on their own
        if (mounted) setState(() {});
      })
      ..on<lk.RoomMetadataChangedEvent>((event) {
        // When another participant enables translator, backend updates room metadata
        // to signal all participants to disable E2EE
        try {
          final metadata = event.metadata;
          if (metadata != null && metadata.contains('e2ee_disabled')) {
            final room = _room;
            if (room?.e2eeManager != null) {
              room!.setE2EEEnabled(false);
              debugPrint('[VoiceCall] E2EE disabled via room metadata signal');
            }
          }
        } catch (_) {}
      });
  }

  void _onRoomChanged() {
    if (!mounted) return;
    final room = _room;
    if (room == null) return;

    if (room.connectionState == lk.ConnectionState.disconnected) {
      if (_navigatedAway || _reconnecting || _manualReconnecting) return;
      // Connection dropped without LiveKit's reconnect starting — try ours
      _startManualReconnect();
      return;
    }

    // Sync participants list from room state
    if (mounted) {
      setState(() {
        _participants
          ..clear()
          ..addAll(room.remoteParticipants.values);
      });
      // Stop ringback if human participants appeared
      if (_ringing && _participants.any((p) => p.identity != 'ai-assistant')) {
        _stopRingback();
      }
      // Auto-hangup when all remote participants left (call was active)
      if (_participants.isEmpty && !_connecting && !_ringing && !_reconnecting && !_manualReconnecting) {
        _emptyRoomTimer ??= Timer(const Duration(seconds: 3), () {
          if (!mounted || _navigatedAway) return;
          if (_participants.isEmpty) {
            debugPrint('[VoiceCall] All participants left — auto hanging up');
            _hangUp();
          }
        });
      } else {
        _emptyRoomTimer?.cancel();
        _emptyRoomTimer = null;
      }
    }
  }

  Future<void> _startManualReconnect() async {
    if (_manualReconnecting || _navigatedAway || !mounted) return;
    final roomName = _roomName;
    if (roomName == null) {
      CallStateService.instance.notifyEnded();
      _navigateBack();
      return;
    }
    _manualReconnecting = true;
    if (mounted) setState(() => _reconnecting = true);
    _playReconnectBeep();

    while (_reconnectAttempts < _kMaxReconnectAttempts && mounted && !_navigatedAway) {
      final delay = _kReconnectDelays[_reconnectAttempts.clamp(0, _kReconnectDelays.length - 1)];
      _reconnectAttempts++;
      await Future.delayed(Duration(seconds: delay));
      if (!mounted || _navigatedAway) break;

      try {
        final res = await sl<DioClient>().post<Map<String, dynamic>>(
          '/voice/rooms/$roomName/join',
          data: {},
          fromJson: (d) => Map<String, dynamic>.from(d as Map),
        );
        final token = res['token'] as String;

        // Teardown old room
        _eventsListener?.dispose();
        _eventsListener = null;
        _room?.removeListener(_onRoomChanged);

        // Re-apply E2EE on reconnect
        lk.E2EEOptions? reconnectE2eeOptions;
        final reconnectKey = widget.e2eeKey ?? CallStateService.instance.e2eeKey;
        if (reconnectKey != null) {
          final kp = await lk.BaseKeyProvider.create(sharedKey: true);
          await kp.setSharedKey(reconnectKey);
          reconnectE2eeOptions = lk.E2EEOptions(keyProvider: kp);
        }

        // Fresh room instance
        final newRoom = lk.Room(
          roomOptions: lk.RoomOptions(
            e2eeOptions: reconnectE2eeOptions,
            defaultAudioPublishOptions: const lk.AudioPublishOptions(audioBitrate: 32000),
          ),
        );
        _room = newRoom;
        newRoom.addListener(_onRoomChanged);
        _subscribeRoomEvents();

        await newRoom.connect(
          '${AppConfig.baseUrl.replaceFirst('https://', 'wss://')}/livekit/',
          token,
          connectOptions: const lk.ConnectOptions(autoSubscribe: false),
        );

        CallStateService.instance.setRoom(newRoom, roomName, widget.conversationId, e2eeKeyValue: reconnectKey);

        try { await newRoom.localParticipant?.setMicrophoneEnabled(!_muted); } catch (_) {}
        if (_cameraOn) { try { await newRoom.localParticipant?.setCameraEnabled(true); } catch (_) {} }
        try { await _audioChannel.invokeMethod('requestAudioFocus'); } catch (_) {}
        _forceEarpiece();

        _manualReconnecting = false;
        _reconnectAttempts = 0;
        if (mounted) {
          setState(() {
            _reconnecting = false;
            _participants
              ..clear()
              ..addAll(newRoom.remoteParticipants.values);
          });
        }
        return; // success
      } catch (_) {
        if (mounted && !_navigatedAway) _playReconnectBeep();
      }
    }

    // All attempts exhausted
    _manualReconnecting = false;
    if (mounted && !_navigatedAway) {
      CallStateService.instance.notifyEnded();
      _navigateBack();
    }
  }

  // Ringback with proper phone-like pattern: ~2s ring, ~4s silence, repeat
  void _startRingback() {
    _ringbackActive = true;
    _scheduleNextRing();
  }

  void _scheduleNextRing() {
    if (!_ringbackActive || !mounted) return;
    _ringPlayer.setReleaseMode(ReleaseMode.stop);
    _ringPlayer.play(AssetSource('audio/ringback.wav'), volume: 0.6).catchError((_) {});
    // ringback.wav is ~2.1s; after it plays, wait ~4s silence, then ring again
    _ringbackTimer = Timer(const Duration(milliseconds: 6200), () {
      if (_ringbackActive && mounted) _scheduleNextRing();
    });
  }

  void _stopRingback() {
    _ringbackActive = false;
    _ringbackTimer?.cancel();
    _ringbackTimer = null;
    _ringPlayer.stop().catchError((_) {});
    if (mounted) setState(() => _ringing = false);
  }

  Future<void> _playReconnectBeep() async {
    try {
      await _ringPlayer.stop();
      await _ringPlayer.play(AssetSource('audio/ringback.wav'), volume: 0.5);
      await Future.delayed(const Duration(milliseconds: 300));
      await _ringPlayer.stop();
    } catch (_) {}
  }

  void _navigateBack() {
    if (_navigatedAway || !mounted) return;
    _navigatedAway = true;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RouteConstants.assistant);
    }
  }

  /// Show a dialog with room info (host avatar, name, title) and optional password field.
  /// Returns {'password': '...'} on confirm, or null if cancelled.
  Future<Map<String, dynamic>?> _showJoinRoomDialog(Map<String, dynamic>? roomInfo) async {
    if (!mounted) return null;

    final creatorName = roomInfo?['creatorName'] as String?;
    final creatorAvatar = roomInfo?['creatorAvatar'] as String?;
    final title = roomInfo?['title'] as String?;
    final requiresPassword = roomInfo?['requiresPassword'] as bool? ?? false;

    if (creatorName != null && creatorName.isNotEmpty) {
      setState(() => _publicRoomCreatorName = creatorName);
    }
    if (creatorAvatar != null) {
      setState(() => _publicRoomCreatorAvatar = creatorAvatar);
    }
    if (title != null && title.isNotEmpty) {
      setState(() => _publicRoomTitle = title);
    }

    final colors = AppColors.of(context);
    final passwordController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Host avatar
            CircleAvatar(
              radius: 36,
              backgroundColor: colors.primary.withOpacity(0.15),
              backgroundImage: creatorAvatar != null ? NetworkImage(creatorAvatar) : null,
              child: creatorAvatar == null
                  ? Text(
                      (creatorName ?? '?')[0].toUpperCase(),
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 10),
            if (creatorName != null && creatorName.isNotEmpty) ...[
              Text(
                creatorName,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'приглашает вас в комнату',
                style: TextStyle(color: colors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              title?.isNotEmpty == true ? title! : 'Комната',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            if (requiresPassword) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.lock_outline, size: 14, color: colors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Защищена паролем',
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                autofocus: true,
                obscureText: true,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Пароль',
                  hintStyle: TextStyle(color: colors.textSecondary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onSubmitted: (_) =>
                    Navigator.of(ctx).pop({'password': passwordController.text}),
              ),
            ],
            const SizedBox(height: 4),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text('Отмена', style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop({'password': passwordController.text}),
            child: Text(
              'Войти',
              style: TextStyle(color: colors.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    passwordController.dispose();
    return result;
  }

  /// Ask the user to enter their display name before joining as guest.
  /// Returns the name, or null if the user cancelled.
  Future<String?> _askForGuestName() async {
    if (!mounted) return null;
    // If ProfileBloc is available and loaded, use the real name automatically.
    try {
      final pState = context.read<ProfileBloc>().state;
      if (pState is ProfileLoaded) {
        final full = [pState.user.firstName, pState.user.lastName]
            .where((s) => s != null && s.isNotEmpty)
            .join(' ');
        if (full.isNotEmpty) return full;
      }
    } catch (_) {}

    // Otherwise prompt the user for a name.
    final colors = AppColors.of(context);
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Войти в комнату',
                style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
            if (_publicRoomCreatorName != null) ...[
              const SizedBox(height: 4),
              Text(
                _publicRoomCreatorName!,
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Ваше имя',
            hintStyle: TextStyle(color: colors.textSecondary),
          ),
          onSubmitted: (v) {
            final t = v.trim();
            if (t.isNotEmpty) Navigator.of(ctx).pop(t);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text('Отмена', style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final t = controller.text.trim();
              if (t.isNotEmpty) Navigator.of(ctx).pop(t);
            },
            child: Text('Войти', style: TextStyle(color: colors.primary)),
          ),
        ],
      ),
    );
    controller.dispose();
    return name;
  }

  Future<void> _toggleMute() async {
    final newMuted = !_muted;
    await _room?.localParticipant?.setMicrophoneEnabled(!newMuted);
    setState(() => _muted = newMuted);
  }

  Future<void> _toggleCamera() async {
    if (!_cameraOn) {
      final status = await Permission.camera.request();
      debugPrint('[VoiceCall] Camera permission: $status');
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Разрешите доступ к камере в Настройках → Конфиденциальность → Камера → TalerID'),
              action: SnackBarAction(
                label: 'Открыть',
                onPressed: openAppSettings,
              ),
              duration: const Duration(seconds: 6),
            ),
          );
        }
        return;
      }
    }
    final newCameraOn = !_cameraOn;
    debugPrint('[VoiceCall] setCameraEnabled($newCameraOn) start, localParticipant=${_room?.localParticipant?.identity}');
    try {
      // iOS: switch AVAudioSession before camera toggle.
      // Default voiceChat mode blocks RTCCameraVideoCapturer initialization.
      if (Platform.isIOS) {
        if (newCameraOn) {
          await _audioChannel.invokeMethod('setAudioSessionForVideo');
          debugPrint('[VoiceCall] setAudioSessionForVideo called');
          // Give iOS audio session time to settle before starting camera capture
          await Future.delayed(const Duration(milliseconds: 300));
        } else {
          await _audioChannel.invokeMethod('requestAudioFocus');
        }
      }
      await _room?.localParticipant?.setCameraEnabled(newCameraOn);
      debugPrint('[VoiceCall] setCameraEnabled($newCameraOn) done, pubs=${_room?.localParticipant?.videoTrackPublications.length}');
      if (mounted) setState(() => _cameraOn = newCameraOn);

      // Verify local video track appeared after enabling camera
      if (newCameraOn && mounted) {
        await Future.delayed(const Duration(milliseconds: 500));
        final pubs = _room?.localParticipant?.videoTrackPublications ?? [];
        final hasTrack = pubs.any((p) => p.track != null);
        debugPrint('[VoiceCall] Post-enable track check: hasTrack=$hasTrack, pubs=${pubs.length}');
        if (!hasTrack && mounted) {
          // Track did not appear — retry once
          debugPrint('[VoiceCall] No video track found, retrying setCameraEnabled');
          try {
            await _room?.localParticipant?.setCameraEnabled(false);
            await Future.delayed(const Duration(milliseconds: 200));
            await _room?.localParticipant?.setCameraEnabled(true);
          } catch (retryErr) {
            debugPrint('[VoiceCall] Camera retry error: $retryErr');
          }
          if (mounted) setState(() {});
        }
      }
    } catch (e) {
      debugPrint('[VoiceCall] Camera toggle error: $e');
      // Reset state if camera failed to enable
      if (newCameraOn && mounted) {
        setState(() => _cameraOn = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Не удалось включить камеру: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _flipCamera() async {
    if (!_cameraOn) return;
    final newFront = !_isFrontCamera;
    try {
      final pubs = _room?.localParticipant?.videoTrackPublications ?? [];
      final videoTrack = pubs.firstWhereOrNull((p) => p.track != null)?.track as lk.LocalVideoTrack?;
      if (videoTrack != null) {
        await videoTrack.restartTrack(
          lk.CameraCaptureOptions(
            cameraPosition: newFront ? lk.CameraPosition.front : lk.CameraPosition.back,
          ),
        );
      }
      if (mounted) setState(() => _isFrontCamera = newFront);
    } catch (e) {
      debugPrint('[VoiceCall] flipCamera error: $e');
    }
  }

  Future<void> _toggleSimpleRecorder() async {
    final roomName = _roomName;
    if (roomName == null) return;
    final client = sl<DioClient>();
    try {
      if (!_isRecording) {
        await client.dio.post('/voice/rooms/$roomName/recorder/start',
            data: {'withAi': false});
      } else {
        await client.dio.post('/voice/rooms/$roomName/recorder/stop');
      }
      if (mounted) setState(() => _isRecording = !_isRecording);
    } catch (e) {
      debugPrint('[VoiceCall] Recorder error: $e');
    }
  }

  Future<void> _toggleAiRecorder() async {
    final roomName = _roomName;
    if (roomName == null) return;
    final client = sl<DioClient>();

    try {
      if (!_aiRecording) {
        await client.dio.post('/voice/rooms/$roomName/recorder/start',
            data: {'withAi': true});
      } else {
        await client.dio.post('/voice/rooms/$roomName/recorder/stop');
      }
      if (mounted) setState(() => _aiRecording = !_aiRecording);
    } catch (e) {
      debugPrint('[VoiceCall] AI recorder error: $e');
    }
  }

  bool get _hasAnyVideo {
    if (_cameraOn) return true;
    return _participants.any((p) =>
        p.videoTrackPublications.any((pub) => pub.subscribed && pub.track != null));
  }

  /// Find the first remote screen share track (if any).
  lk.VideoTrack? get _remoteScreenShareTrack {
    for (final p in _participants) {
      for (final pub in p.videoTrackPublications) {
        if (pub.source == lk.TrackSource.screenShareVideo &&
            pub.subscribed &&
            pub.track != null) {
          return pub.track as lk.VideoTrack;
        }
      }
    }
    return null;
  }

  String? get _remoteScreenShareOwner {
    for (final p in _participants) {
      for (final pub in p.videoTrackPublications) {
        if (pub.source == lk.TrackSource.screenShareVideo &&
            pub.subscribed &&
            pub.track != null) {
          return p.name?.isNotEmpty == true ? p.name! : p.identity;
        }
      }
    }
    return null;
  }

  Future<void> _showAudioOutputPicker() async {
    List<Map<String, String>> outputs = [
      {'id': 'earpiece', 'name': 'Телефон', 'type': 'earpiece'},
      {'id': 'speaker', 'name': 'Динамик', 'type': 'speaker'},
    ];
    try {
      final raw = await _audioChannel.invokeMethod<List>('getAudioOutputs');
      if (raw != null) {
        outputs = raw.map((e) => Map<String, String>.from(e as Map)).toList();
      }
    } catch (_) {}
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.of(context).card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.of(context).border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Аудиовыход',
              style: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...outputs.map((o) {
              final type = o['type'] ?? o['id'] ?? '';
              final name = o['name'] ?? type;
              final icon = _outputIcons[type] ?? Icons.volume_up_rounded;
              final isSelected = _audioOutputType == type;
              return ListTile(
                leading: Icon(icon, color: isSelected ? AppColors.of(context).primary : AppColors.of(context).textSecondary),
                title: Text(
                  name,
                  style: TextStyle(
                    color: isSelected ? AppColors.of(context).primary : AppColors.of(context).textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                trailing: isSelected ? Icon(Icons.check_rounded, color: AppColors.of(context).primary) : null,
                onTap: () async {
                  Navigator.pop(context);
                  await _setAudioOutput(type);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _setAudioOutput(String type) async {
    setState(() => _audioOutputType = type);
    // Apply immediately
    await _applyAudioOutput(type);
    // Re-apply with delays to override LiveKit/WebRTC async overrides
    for (final delay in [200, 600, 1500]) {
      await Future.delayed(Duration(milliseconds: delay));
      if (!mounted || _audioOutputType != type) return;
      await _applyAudioOutput(type);
    }
  }

  Future<void> _applyAudioOutput(String type) async {
    try {
      final speakerOn = type == 'speaker';
      await lk.Hardware.instance.setSpeakerphoneOn(speakerOn);
    } catch (_) {}
    try {
      await _audioChannel.invokeMethod('setAudioOutput', type);
    } catch (_) {}
  }

  void _minimizeCall() {
    if (_navigatedAway || !mounted) return;
    _navigatedAway = true;
    // Navigate to dashboard without ending the call
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RouteConstants.messenger);
    }
  }

  Future<void> _hangUp() async {
    // Mark as navigated away FIRST — stops any async retries
    // (e.g. _restoreAudioAfterCallKit) from re-activating audio
    _navigatedAway = true;
    _emptyRoomTimer?.cancel();
    // Stop ringback if still playing (call not answered)
    _stopRingback();
    // Disable microphone first to release audio track
    try {
      await _room?.localParticipant?.setMicrophoneEnabled(false);
    } catch (_) {}
    // Notify the other party that the call ended
    final convId = widget.conversationId ?? CallStateService.instance.conversationId;
    final rName = _roomName ?? CallStateService.instance.roomName;
    if (convId != null && rName != null) {
      try {
        sl<MessengerRemoteDataSource>().sendCallEnded(convId, rName);
      } catch (_) {}
    }
    // Disconnect from LiveKit FIRST — must happen while network/audio is still active
    // so the server receives the leave signal immediately.
    await CallStateService.instance.endCall();
    // Now release audio focus & deactivate session
    try {
      await _audioChannel.invokeMethod('abandonAudioFocus');
    } catch (_) {}
    try {
      await _audioChannel.invokeMethod('deactivateAudioSession');
    } catch (_) {}
    // Tell CallKit the call ended (releases iOS background audio session)
    try {
      await FlutterCallkitIncoming.endAllCalls();
    } catch (_) {}
    _navigateBack();
  }

  Future<void> _addParticipant() async {
    final convId = widget.conversationId ?? CallStateService.instance.conversationId;
    final rName = _roomName ?? CallStateService.instance.roomName;
    if (rName == null) return;

    // Show user search bottom sheet
    final selected = await showModalBottomSheet<UserSearchEntity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.of(context).card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _UserSearchSheet(),
    );
    if (selected == null || !mounted) return;

    try {
      final client = sl<DioClient>();
      // Join the room (this creates a new token for the invitee)
      await client.post(
        '/voice/rooms/$rName/join',
        data: {},
        fromJson: (d) => Map<String, dynamic>.from(d as Map),
      );
      // Send call invite to selected user via messenger
      if (convId != null) {
        sl<MessengerRemoteDataSource>().sendCallInvite(convId, rName, inviteeId: selected.id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Приглашение отправлено ${selected.username != null ? "@${selected.username}" : selected.email}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppColors.of(context).error),
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _room != null && !_connecting) {
      _reactivateAudio();
    }
  }

  Future<void> _reactivateAudio() async {
    // Re-activate AVAudioSession after returning from lock screen / background
    try { await _audioChannel.invokeMethod('requestAudioFocus'); } catch (_) {}
    // Re-enable mic (LiveKit may have suspended the track while backgrounded)
    try { await _room?.localParticipant?.setMicrophoneEnabled(!_muted); } catch (_) {}
    // Restore earpiece mode if applicable
    if (_audioOutputType == 'earpiece') _forceEarpiece();
  }

  // ─── Translation ───────────────────────────────────────

  // ── Server-side translation helpers ──


  /// Subscribe to translation-{lang} track from voice-translator, unsubscribe others
  void _updateTranslationTrackSubscription() {
    final room = _room;
    if (room == null) return;
    final translator = room.remoteParticipants.values
        .where((p) => p.identity == 'voice-translator')
        .firstOrNull;
    if (translator == null) return;

    for (final pub in translator.audioTrackPublications) {
      final wantedName = 'translation-$_preferredLang';
      if (_translationEnabled && pub.name == wantedName) {
        if (!pub.subscribed) {
          try { pub.subscribe(); } catch (_) {}
        }
      } else {
        if (pub.subscribed) {
          try { pub.unsubscribe(); } catch (_) {}
        }
      }
    }
  }

  Future<void> _toggleTranslation(bool enabled) async {
    // Set flags BEFORE starting translator so TrackPublishedEvent handler knows to subscribe
    if (mounted) {
      setState(() {
        _translationEnabled = enabled;
        _translationActive = enabled;
      });
    }
    if (enabled) {
      // Disable E2EE so the translator agent can hear unencrypted audio
      await _disableE2EEForTranslator();
      await _startServerTranslator();
    }
    _updateTranslationTrackSubscription();
  }

  Future<void> _disableE2EEForTranslator() async {
    final room = _room;
    if (room == null) return;
    if (room.e2eeManager == null) return; // E2EE not active
    try {
      await room.setE2EEEnabled(false);
      debugPrint('[Translation] E2EE disabled for translator');
    } catch (e) {
      debugPrint('[Translation] Failed to disable E2EE: $e');
    }
    // Ask backend to disable E2EE for all other participants in the room
    final roomName = _roomName;
    if (roomName != null) {
      try {
        await sl<DioClient>().post(
          '/voice/rooms/$roomName/disable-e2ee',
          data: {},
          fromJson: (d) => d,
        );
      } catch (e) {
        debugPrint('[Translation] Failed to notify others to disable E2EE: $e');
      }
    }
  }

  Future<void> _startServerTranslator() async {
    final roomName = _roomName;
    if (roomName == null) return;
    try {
      final client = sl<DioClient>();
      // Start translator agent for the room
      await client.post(
        '/voice/rooms/$roomName/translator/start',
        data: {},
        fromJson: (d) => d,
      );
      // Set preferred language on the server
      await _setServerLang(roomName, _preferredLang);
      debugPrint('[Translation] Server translator started for $roomName');
    } catch (e) {
      debugPrint('[Translation] Failed to start server translator: $e');
    }
  }

  Future<void> _setServerLang(String roomName, String lang) async {
    try {
      final client = sl<DioClient>();
      await client.post(
        '/voice/rooms/$roomName/set-lang',
        data: {'lang': lang},
        fromJson: (d) => d,
      );
    } catch (e) {
      debugPrint('[Translation] Failed to set server lang: $e');
    }
  }

  Future<void> _setPreferredLang(String lang) async {
    setState(() {
      _preferredLang = lang;
    });
    // Unsubscribe from old tracks immediately
    _updateTranslationTrackSubscription();
    // Update language on server (this triggers session recreation + new track publish)
    final roomName = _roomName;
    if (roomName != null && _translationEnabled) {
      await _setServerLang(roomName, lang);
    }
    // Retry subscription — the new track may take time to appear
    for (final delay in [500, 1500, 3000, 5000]) {
      Future.delayed(Duration(milliseconds: delay), () {
        if (mounted && _preferredLang == lang) {
          _updateTranslationTrackSubscription();
        }
      });
    }
  }

  Future<void> _showLangPicker() async {
    final colors = AppColors.of(context);
    var searchQuery = '';
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final filtered = _translationLangs.entries.where((e) =>
            searchQuery.isEmpty ||
            e.value.toLowerCase().contains(searchQuery.toLowerCase()) ||
            e.key.toLowerCase().contains(searchQuery.toLowerCase()),
          ).toList();
          return SafeArea(
            child: DraggableScrollableSheet(
              initialChildSize: 0.7,
              maxChildSize: 0.9,
              minChildSize: 0.4,
              expand: false,
              builder: (_, scrollController) => Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Переводить на',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      autofocus: false,
                      style: TextStyle(color: colors.textPrimary, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Поиск языка...',
                        hintStyle: TextStyle(color: colors.textSecondary),
                        prefixIcon: Icon(Icons.search, color: colors.textSecondary),
                        filled: true,
                        fillColor: colors.surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (v) => setModalState(() => searchQuery = v),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        ...filtered.map((e) => ListTile(
                          leading: Icon(
                            Icons.language_rounded,
                            color: _preferredLang == e.key ? colors.primary : colors.textSecondary,
                          ),
                          title: Text(
                            e.value,
                            style: TextStyle(
                              color: _preferredLang == e.key ? colors.primary : colors.textPrimary,
                              fontWeight: _preferredLang == e.key ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          trailing: _preferredLang == e.key
                              ? Icon(Icons.check_rounded, color: colors.primary)
                              : null,
                          onTap: () {
                            Navigator.pop(context);
                            _setPreferredLang(e.key);
                            if (!_translationEnabled) _toggleTranslation(true);
                          },
                        )),
                        SwitchListTile(
                          title: Text(
                            'Включить перевод',
                            style: TextStyle(color: colors.textPrimary),
                          ),
                          value: _translationEnabled,
                          activeColor: colors.primary,
                          onChanged: (v) {
                            Navigator.pop(context);
                            _toggleTranslation(v);
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _callEndedSub?.cancel();
    _ringbackTimer?.cancel();
    _emptyRoomTimer?.cancel();
    _ringbackActive = false;
    _audioChannel.setMethodCallHandler(null);
    WakelockPlus.disable();
    _eventsListener?.dispose();
    _room?.removeListener(_onRoomChanged);
    _ringPlayer.dispose();
    _screenShareTransformCtrl.dispose();
    // Restore portrait if we were in landscape for screen share
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    // Translation cleanup — server-side, nothing local to stop
    // Do NOT disconnect room — call continues in background via CallStateService
    super.dispose();
  }

  bool _participantHasMic(lk.RemoteParticipant p) {
    return p.audioTrackPublications.isNotEmpty &&
        p.audioTrackPublications
            .any((pub) => pub.muted == false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        title: Text(
          widget.calleeName ??
          (widget.publicCode != null && _publicRoomCreatorName != null
              ? 'Комната ${_publicRoomCreatorName}'
              : 'Голосовой звонок'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _minimizeCall,
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            onPressed: _addParticipant,
            tooltip: 'Добавить участника',
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildBody(),
          if (_reconnecting)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Переподключение...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOutgoingCallCenter({required String statusText}) {
    final colors = AppColors.of(context);
    final name = widget.calleeName ?? _publicRoomCreatorName;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: colors.primary.withOpacity(0.15),
            child: name != null && name.isNotEmpty
                ? Text(
                    name[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  )
                : Icon(Icons.person_rounded, size: 48, color: colors.primary),
          ),
          const SizedBox(height: 20),
          if (name != null && name.isNotEmpty)
            Text(
              name,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            statusText,
            style: TextStyle(color: colors.textSecondary, fontSize: 15),
          ),
          if (_connecting) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_connecting) {
      final statusText = widget.publicCode != null && _publicRoomCreatorName != null
          ? 'Комната ${_publicRoomCreatorName}'
          : 'Подключение...';
      return _buildOutgoingCallCenter(statusText: statusText);
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.of(context).error,
              ),
              const SizedBox(height: 16),
              Text(
                'Ошибка подключения',
                style: TextStyle(
                  color: AppColors.of(context).textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(
                  color: AppColors.of(context).textSecondary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _hangUp,
                child: const Text('Закрыть'),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        // Status
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppColors.of(context).card,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: (_aiRecording || _isRecording) ? Colors.red : Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _ringing ? 'Вызов...' : 'Звонок активен',
                style: TextStyle(
                  color: AppColors.of(context).textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (_isRecording) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6, height: 6,
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'REC',
                        style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
              if (_aiRecording) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6, height: 6,
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'AI REC',
                        style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        // Participants list or video grid (with screen share support)
        Expanded(
          child: _screenShareFullscreen
              ? _buildScreenShareFullscreen()
              : _remoteScreenShareTrack != null
                  ? _buildScreenShareLayout()
                  : _hasAnyVideo
                      ? _buildVideoGrid()
                      : _buildParticipantsList(),
        ),
        // Self participant indicator (audio mode only)
        if (!_hasAnyVideo && !_screenShareFullscreen)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            color: AppColors.of(context).card,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.of(context).primary,
                child: Icon(
                  Icons.person_rounded,
                  color: Colors.black,
                ),
              ),
              title: Text(
                'Вы',
                style: TextStyle(
                  color: AppColors.of(context).textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: Icon(
                _muted
                    ? Icons.mic_off_rounded
                    : Icons.mic_rounded,
                color: _muted ? AppColors.of(context).error : Colors.green,
              ),
            ),
          ),
        ),
        // Controls — two rows for small screens (hidden in fullscreen screen share)
        if (!_screenShareFullscreen)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Secondary row: Record, AI Record, Translate, Audio Output, [Flip Camera]
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ControlButton(
                    icon: _isRecording ? Icons.stop_circle_rounded : Icons.fiber_manual_record_rounded,
                    label: _isRecording ? 'Стоп' : 'Запись',
                    color: _isRecording
                        ? Colors.red.withOpacity(0.2)
                        : AppColors.of(context).card,
                    iconColor: _isRecording ? Colors.red : null,
                    onTap: (_aiRecording) ? null : _toggleSimpleRecorder,
                  ),
                  _ControlButton(
                    icon: _aiRecording ? Icons.smart_toy : Icons.smart_toy_outlined,
                    label: _aiRecording ? 'AI Стоп' : 'AI Запись',
                    color: _aiRecording
                        ? Colors.red.withOpacity(0.2)
                        : AppColors.of(context).card,
                    iconColor: _aiRecording ? Colors.red : null,
                    onTap: (_isRecording) ? null : _toggleAiRecorder,
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _ControlButton(
                        icon: Icons.translate_rounded,
                        label: _translationEnabled
                            ? _preferredLang.toUpperCase()
                            : 'Перевод',
                        color: _translationEnabled
                            ? AppColors.of(context).primary.withValues(alpha: 0.2)
                            : AppColors.of(context).card,
                        iconColor: _translationEnabled
                            ? AppColors.of(context).primary
                            : null,
                        onTap: _showLangPicker,
                      ),
                      if (_translationActive)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  _ControlButton(
                    icon: _outputIcons[_audioOutputType] ?? Icons.volume_up_rounded,
                    label: _outputLabels[_audioOutputType] ?? 'Аудио',
                    color: _audioOutputType != 'earpiece'
                        ? AppColors.of(context).primary.withValues(alpha: 0.2)
                        : AppColors.of(context).card,
                    onTap: _showAudioOutputPicker,
                  ),
                  if (_cameraOn)
                    _ControlButton(
                      icon: Icons.flip_camera_ios_rounded,
                      label: 'Повернуть',
                      color: AppColors.of(context).card,
                      onTap: _flipCamera,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Primary row: Mic, Camera, End Call
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ControlButton(
                    icon: _muted
                        ? Icons.mic_off_rounded
                        : Icons.mic_rounded,
                    label: _muted ? 'Включить' : 'Микрофон',
                    color: _muted ? AppColors.of(context).error : AppColors.of(context).card,
                    onTap: _toggleMute,
                  ),
                  _ControlButton(
                    icon: Icons.call_end_rounded,
                    label: 'Завершить',
                    color: AppColors.of(context).error,
                    onTap: _hangUp,
                    large: true,
                  ),
                  _ControlButton(
                    icon: _cameraOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                    label: _cameraOn ? 'Камера вкл.' : 'Камера',
                    color: _cameraOn
                        ? AppColors.of(context).primary.withValues(alpha: 0.2)
                        : AppColors.of(context).card,
                    onTap: _toggleCamera,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantsList() {
    return _participants.isEmpty
        ? _ringing
            ? _buildOutgoingCallCenter(statusText: 'Вызов...')
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_outline, size: 64, color: AppColors.of(context).textSecondary),
                    const SizedBox(height: 16),
                    Text(
                      'Ожидание участников...',
                      style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 16),
                    ),
                  ],
                ),
              )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _participants.length,
            itemBuilder: (_, i) {
              final p = _participants[i];
              if (p.identity == 'voice-translator') return const SizedBox.shrink();
              final isAI = p.identity == 'ai-assistant';
              final isRecorder = p.identity == 'meeting-recorder';
              final hasMic = _participantHasMic(p);
              final displayName = isAI
                  ? 'AI Ассистент'
                  : isRecorder
                      ? 'AI Запись'
                      : (p.name?.isNotEmpty == true ? p.name! : p.identity);
              return Card(
                color: AppColors.of(context).card,
                margin: const EdgeInsets.only(bottom: 12),
                shape: isRecorder
                    ? RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.red.withOpacity(0.5), width: 1.5),
                      )
                    : null,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isRecorder
                        ? Colors.red.withOpacity(0.15)
                        : isAI
                            ? AppColors.of(context).primary
                            : AppColors.of(context).surface,
                    child: Icon(
                      isRecorder ? Icons.fiber_manual_record_rounded : isAI ? Icons.smart_toy_rounded : Icons.person_rounded,
                      color: isRecorder ? Colors.red : isAI ? Colors.black : AppColors.of(context).textPrimary,
                      size: isRecorder ? 20 : 24,
                    ),
                  ),
                  title: Text(
                    displayName,
                    style: TextStyle(
                      color: isRecorder ? Colors.red : AppColors.of(context).textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: isRecorder
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('REC', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.w700)),
                        )
                      : isAI
                          ? Icon(Icons.graphic_eq_rounded, color: AppColors.of(context).primary)
                          : Icon(
                              hasMic ? Icons.mic_rounded : Icons.mic_off_rounded,
                              color: hasMic ? Colors.green : AppColors.of(context).textSecondary,
                            ),
                ),
              );
            },
          );
  }

  /// Screen share layout: large screen share on top, small participant strip at bottom.
  Widget _buildScreenShareLayout() {
    final screenTrack = _remoteScreenShareTrack;
    final ownerName = _remoteScreenShareOwner ?? '';

    return Column(
      children: [
        // Screen share view (takes most of the space)
        Expanded(
          flex: 3,
          child: GestureDetector(
            onTap: () => setState(() => _screenShareFullscreen = true),
            child: Container(
              color: Colors.black,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (screenTrack != null)
                    lk.VideoTrackRenderer(screenTrack),
                  // Screen share label
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.screen_share_rounded, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '$ownerName — экран',
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Fullscreen hint
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.fullscreen_rounded, color: Colors.white70, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Small participant thumbnails at bottom
        SizedBox(
          height: 110,
          child: _buildParticipantStrip(),
        ),
      ],
    );
  }

  /// Fullscreen screen share view with pinch-to-zoom and landscape support.
  Widget _buildScreenShareFullscreen() {
    final screenTrack = _remoteScreenShareTrack;
    final ownerName = _remoteScreenShareOwner ?? '';

    // If screen share ended, exit fullscreen
    if (screenTrack == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _exitScreenShareFullscreen();
      });
      return const SizedBox.shrink();
    }

    // Allow landscape when viewing screen share fullscreen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Pinch-to-zoom + pan on the screen share
          InteractiveViewer(
            transformationController: _screenShareTransformCtrl,
            minScale: 1.0,
            maxScale: 5.0,
            child: lk.VideoTrackRenderer(screenTrack),
          ),
          // Label
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.screen_share_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '$ownerName — экран',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
          // Exit fullscreen button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: GestureDetector(
              onTap: _exitScreenShareFullscreen,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _exitScreenShareFullscreen() {
    _screenShareTransformCtrl.value = Matrix4.identity();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    setState(() => _screenShareFullscreen = false);
  }

  /// Horizontal strip of participant thumbnails (used below screen share).
  Widget _buildParticipantStrip() {
    final tiles = <_VideoTileData>[];
    for (final p in _participants) {
      if (p.identity == 'voice-translator') continue;
      final track = p.videoTrackPublications
          .firstWhereOrNull((pub) =>
              pub.subscribed &&
              pub.track != null &&
              pub.source != lk.TrackSource.screenShareVideo)
          ?.track as lk.VideoTrack?;
      final isAI = p.identity == 'ai-assistant';
      final isRecorder = p.identity == 'meeting-recorder';
      final name = isAI
          ? 'AI Ассистент'
          : isRecorder
              ? 'AI Запись'
              : (p.name?.isNotEmpty == true ? p.name! : p.identity);
      tiles.add(_VideoTileData(name: name, track: track, hasMic: _participantHasMic(p), isLocal: false, isAI: isAI, isRecorder: isRecorder));
    }
    // Add local
    if (_cameraOn) {
      final localTrack = (_room?.localParticipant?.videoTrackPublications ?? [])
          .firstWhereOrNull((p) => p.track != null)?.track;
      tiles.add(_VideoTileData(
        name: _room?.localParticipant?.name ?? '',
        track: localTrack as lk.VideoTrack?,
        hasMic: !_muted,
        isLocal: true,
        isAI: false,
      ));
    }
    if (tiles.isEmpty) return const SizedBox.shrink();
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      itemCount: tiles.length,
      itemBuilder: (_, i) {
        final tile = tiles[i];
        return Container(
          width: 90,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              color: AppColors.of(context).surface,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (tile.track != null)
                    lk.VideoTrackRenderer(tile.track!)
                  else
                    Center(
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.of(context).card,
                        child: Text(
                          tile.name.isNotEmpty ? tile.name[0].toUpperCase() : '?',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.of(context).textPrimary),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 2,
                    left: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                      child: Text(
                        tile.isLocal ? 'Вы' : tile.name,
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoGrid({bool excludeScreenShare = false}) {
    // Collect all tiles: local + remote participants
    final localPubs = _room?.localParticipant?.videoTrackPublications ?? [];
    final localTrack = localPubs.firstWhereOrNull((p) => p.track != null)?.track;
    final localName = _room?.localParticipant?.name ?? _room?.localParticipant?.identity ?? '';

    // Build tile data list
    final tiles = <_VideoTileData>[];

    // Add remote participants
    for (final p in _participants) {
      if (p.identity == 'voice-translator') continue;
      // Pick camera track only (skip screen share tracks)
      final track = p.videoTrackPublications
          .firstWhereOrNull((pub) =>
              pub.subscribed &&
              pub.track != null &&
              pub.source != lk.TrackSource.screenShareVideo)
          ?.track as lk.VideoTrack?;
      final isAI = p.identity == 'ai-assistant';
      final isRecorder = p.identity == 'meeting-recorder';
      final name = isAI
          ? 'AI Ассистент'
          : isRecorder
              ? 'AI Запись'
              : (p.name?.isNotEmpty == true ? p.name! : p.identity);
      final hasMic = _participantHasMic(p);
      tiles.add(_VideoTileData(
        name: name,
        track: track,
        hasMic: hasMic,
        isLocal: false,
        isAI: isAI,
        isRecorder: isRecorder,
      ));
    }

    // Add local participant — only when camera is on (no avatar placeholder when camera off)
    if (_cameraOn) {
      tiles.add(_VideoTileData(
        name: localName,
        track: localTrack as lk.VideoTrack?,
        hasMic: !_muted,
        isLocal: true,
        isAI: false,
      ));
    }

    if (tiles.isEmpty) {
      return Container(
        color: Colors.black87,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.videocam_off_rounded, size: 64, color: Colors.white54),
              const SizedBox(height: 12),
              Text('Видео недоступно', style: TextStyle(color: Colors.white54, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    // Grid layout: adapt columns based on tile count
    final count = tiles.length;
    final crossAxisCount = count <= 1 ? 1 : count <= 4 ? 2 : 3;

    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: count <= 2 ? 3 / 4 : 3 / 4,
      ),
      itemCount: count,
      itemBuilder: (_, i) {
        final tile = tiles[i];
        return GestureDetector(
          onTap: tile.isLocal ? _flipCamera : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: AppColors.of(context).surface,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Video or avatar
                  if (tile.track != null)
                    lk.VideoTrackRenderer(tile.track!)
                  else
                    Center(
                      child: CircleAvatar(
                        radius: count <= 2 ? 40 : 28,
                        backgroundColor: tile.isRecorder
                            ? Colors.red.withOpacity(0.15)
                            : tile.isAI
                                ? AppColors.of(context).primary
                                : AppColors.of(context).card,
                        child: tile.isRecorder
                            ? Icon(Icons.fiber_manual_record_rounded, size: count <= 2 ? 32 : 22, color: Colors.red)
                            : tile.isAI
                                ? Icon(Icons.smart_toy_rounded, size: count <= 2 ? 36 : 24, color: Colors.black)
                                : Text(
                                tile.name.isNotEmpty ? tile.name[0].toUpperCase() : '?',
                                style: TextStyle(
                                  fontSize: count <= 2 ? 32 : 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.of(context).textPrimary,
                                ),
                              ),
                      ),
                    ),

                  // Name label at bottom
                  Positioned(
                    left: 6,
                    right: 6,
                    bottom: 6,
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              tile.isLocal ? '${tile.name} (вы)' : tile.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (!tile.hasMic)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.mic_off_rounded, size: 14, color: Colors.white),
                          ),
                      ],
                    ),
                  ),

                  // Recording badge for recorder tile
                  if (tile.isRecorder)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                            const Text('REC', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),

                  // Flip camera icon for local tile
                  if (tile.isLocal && tile.track != null)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white70, size: 16),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _VideoTileData {
  final String name;
  final lk.VideoTrack? track;
  final bool hasMic;
  final bool isLocal;
  final bool isAI;
  final bool isRecorder;

  const _VideoTileData({
    required this.name,
    required this.track,
    required this.hasMic,
    required this.isLocal,
    required this.isAI,
    this.isRecorder = false,
  });
}

class _UserSearchSheet extends StatefulWidget {
  @override
  State<_UserSearchSheet> createState() => _UserSearchSheetState();
}

class _UserSearchSheetState extends State<_UserSearchSheet> {
  final _ctrl = TextEditingController();
  List<UserSearchEntity> _results = [];
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    try {
      final results = await sl<MessengerRemoteDataSource>().searchUsers(q.trim());
      if (mounted) setState(() => _results = results);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      builder: (_, scrollCtrl) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.of(context).border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Добавить участника',
            style: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              style: TextStyle(color: AppColors.of(context).textPrimary),
              decoration: InputDecoration(
                hintText: 'Поиск по никнейму...',
                hintStyle: TextStyle(color: AppColors.of(context).textSecondary),
                prefixIcon: Icon(Icons.search, color: AppColors.of(context).textSecondary),
                filled: true,
                fillColor: AppColors.of(context).background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: _search,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: scrollCtrl,
                    itemCount: _results.length,
                    itemBuilder: (_, i) {
                      final u = _results[i];
                      final name = [u.firstName, u.lastName].where((s) => s != null && s.isNotEmpty).join(' ');
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.of(context).surface,
                          child: Icon(Icons.person_rounded, color: AppColors.of(context).textPrimary),
                        ),
                        title: Text(name.isNotEmpty ? name : u.email, style: TextStyle(color: AppColors.of(context).textPrimary)),
                        subtitle: u.username != null ? Text('@${u.username}', style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 12)) : null,
                        onTap: () => Navigator.pop(context, u),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool large;
  final Color? iconColor;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.large = false,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedIconColor = iconColor ?? (color.opacity < 0.9
        ? AppColors.of(context).primary
        : (color.computeLuminance() > 0.4
            ? AppColors.of(context).textPrimary
            : Colors.white));
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: large ? 72 : 56,
            height: large ? 72 : 56,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: onTap == null
                  ? AppColors.of(context).textSecondary.withValues(alpha: 0.4)
                  : resolvedIconColor,
              size: large ? 32 : 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: AppColors.of(context).textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
