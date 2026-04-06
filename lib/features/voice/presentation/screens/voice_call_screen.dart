import 'dart:async';
import 'dart:convert';
import 'dart:io' show File, Platform, WebSocket;
import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:go_router/go_router.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
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
import '../../../../core/storage/cache_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_state.dart';
import '../../../messenger/data/datasources/messenger_remote_datasource.dart';
import '../../../messenger/domain/entities/user_search_entity.dart';
import '../../../../core/services/video_effects_service.dart';
import '../widgets/video_effects_picker.dart';
import '../widgets/pulsing_avatar.dart';
import '../../../../l10n/app_localizations.dart';

class VoiceCallScreen extends StatefulWidget {
  final String? roomName; // null = create new room with AI
  final String? conversationId; // for sending call_ended when hanging up
  final bool isIncoming; // opened from FCM push notification
  final String? calleeName; // name of the person being called (outgoing)
  final String? calleeAvatar; // avatar URL of the person being called
  final String? calleeId; // userId of the person being called (for avatar loading)
  final String? e2eeKey; // E2EE shared key for human-to-human calls (null = no E2EE)
  final String? publicCode; // public room code — join without auth via /voice/rooms/public/{code}/join
  const VoiceCallScreen({
    super.key,
    this.roomName,
    this.conversationId,
    this.isIncoming = false,
    this.calleeName,
    this.calleeAvatar,
    this.calleeId,
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
  bool _hadRemoteParticipant = false; // true once at least one remote participant joined
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

  static Map<String, String> _outputLabels(AppLocalizations l10n) => <String, String>{
    'earpiece': l10n.voiceAudioPhone,
    'speaker': l10n.voiceAudioSpeaker,
    'bluetooth': l10n.voiceAudioBluetooth,
    'headphones': l10n.voiceAudioHeadphones,
  };
  String? _error;
  bool _ringing = false; // outgoing: ringback playing, waiting for callee to answer
  bool _navigatedAway = false;
  bool _settingUp = true; // true during _initCall/_connect, prevents spurious actionCallEnded
  DateTime? _initTime; // used to ignore early call_ended events
  // ── Recording consent state ──
  bool _isRecording = false;
  String? _recordingInitiatorId;     // identity of who started recording
  String _recordingInitiatorName = '';
  bool _consentPending = false;      // initiator waiting for responses
  final Map<String, _ConsentEntry> _consentResponses = {};
  bool _recordingApproved = false;
  bool _consentDialogShowing = false;  // prevent duplicate dialogs
  bool _consentForTranscription = false; // true = consent is for protocol, false = for recording

  // ── Hold state ──
  bool _onHold = false;
  final AudioPlayer _holdPlayer = AudioPlayer();
  final Set<String> _processedMessageIds = {};  // dedup DataChannel messages

  // ── Transcription state ──
  bool _transcriptionActive = false;
  String? _transcriptionInitiatorId;
  String _transcriptionInitiatorName = '';
  String? _roomName; // actual room name (resolved after connect)
  String? _publicRoomCreatorName; // owner name fetched from GET /voice/rooms/public/{code}
  String? _publicRoomCreatorAvatar; // owner avatar URL
  String? _publicRoomTitle; // room title
  final List<lk.RemoteParticipant> _participants = [];
  final Set<String> _speakingIdentities = {}; // identities currently speaking
  final Map<String, String> _participantAvatars = {}; // identity -> avatar URL
  String? _calleeAvatarLoaded; // loaded from API when widget.calleeAvatar is null
  lk.EventsListener<lk.RoomEvent>? _eventsListener;
  StreamSubscription? _callEndedSub;
  StreamSubscription? _callkitEndedSub;
  StreamSubscription<String?>? _activeRoomSub;
  Timer? _emptyRoomTimer;

  // Dynamic callee info (updated on line switch)
  String? _currentCalleeName;
  String? _currentCalleeAvatar;

  // In-call assistant state
  bool _assistantActive = false;
  WebSocket? _assistantWs;
  final AudioRecorder _assistantRecorder = AudioRecorder();
  StreamSubscription<Uint8List>? _assistantRecordSub;
  bool _assistantSessionConfigured = false;
  String? _assistantPendingCallId;
  String? _assistantPendingCallName;
  final StringBuffer _assistantPendingArgs = StringBuffer();

  // Server-side translation state
  String _preferredLang = '';
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
    'pl': 'Polski',
    'sk': 'Slovenčina',
    'cs': 'Čeština',
    'nl': 'Nederlands',
    'sv': 'Svenska',
    'da': 'Dansk',
    'no': 'Norsk',
    'fi': 'Suomi',
    'uk': 'Українська',
    'el': 'Ελληνικά',
    'ro': 'Română',
    'hu': 'Magyar',
    'bg': 'Български',
    'hr': 'Hrvatski',
    'sr': 'Српски',
    'hi': 'हिन्दी',
    'th': 'ไทย',
    'vi': 'Tiếng Việt',
    'id': 'Bahasa Indonesia',
    'ms': 'Bahasa Melayu',
    'he': 'עברית',
    'fa': 'فارسی',
  };

  // Video state
  bool _cameraOn = false;
  bool _screenShareFullscreen = false;
  String? _screenShareParticipantName;
  bool _isFrontCamera = true;
  final TransformationController _screenShareTransformCtrl = TransformationController();

  static const _audioChannel = MethodChannel('taler_id/audio');

  /// Video effects supported on iOS 15+ only (Vision framework).
  bool get _videoEffectsSupported => Platform.isIOS || Platform.isAndroid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Listen for audio interruptions from native (parallel call from phone/other app)
    _audioChannel.setMethodCallHandler(_onNativeAudioEvent);
    _initTime = DateTime.now();
    // Listen for call_ended socket event — the other party hung up
    _callEndedSub = sl<MessengerRemoteDataSource>()
        .callEndedStream
        .listen((roomName) {
      if (!mounted || _navigatedAway) return;
      // Ignore call_ended in first 5 seconds — prevents race with assistant cleanup
      if (_initTime != null && DateTime.now().difference(_initTime!).inSeconds < 5) {
        debugPrint('[VoiceCall] Ignoring early call_ended (${DateTime.now().difference(_initTime!).inSeconds}s after init)');
        return;
      }
      final ourRoom = _roomName ?? CallStateService.instance.roomName;
      if (ourRoom == roomName) {
        _hangUp();
      }
    });
    // Listen for CallKit end — user pressed "End" on native CallKit UI.
    // Skip during _settingUp — endAllCalls() in _connect() fires actionCallEnded
    // which would immediately tear down the room we just connected to.
    _callkitEndedSub = NotificationService.callEvents.listen((CallEvent? event) {
      if (event == null || !mounted || _navigatedAway) return;
      if (event.event == Event.actionCallEnded) {
        if (_settingUp) {
          debugPrint('[VoiceCall] CallKit actionCallEnded SKIPPED (still setting up)');
          return;
        }
        if (_room != null) {
          debugPrint('[VoiceCall] CallKit actionCallEnded — calling _hangUp()');
          _hangUp();
        }
      }
    });
    _currentCalleeName = widget.calleeName;
    _currentCalleeAvatar = widget.calleeAvatar;
    // Listen for external line switches (e.g. accepting second call via CallKit)
    _activeRoomSub = CallStateService.instance.activeRoomStream.listen((newRoom) {
      if (!mounted || _navigatedAway || newRoom == null) return;
      if (newRoom != _roomName) {
        final line = CallStateService.instance.activeLine;
        if (line != null) _switchToLine(line);
      }
    });
    _initCall();
  }

  /// Initialise the call — either resume an existing background-connected room,
  /// wait for a background connect in progress, or start a fresh connection.
  Future<void> _initCall() async {
    final cs = CallStateService.instance;

    // Prevent calling same conversation that's already on another line
    if (widget.conversationId != null && cs.isInCall) {
      final existing = cs.allLines.where((l) => l.conversationId == widget.conversationId).firstOrNull;
      if (existing != null) {
        // Switch to existing line instead
        await cs.holdAndSwitch(existing.roomName);
        if (mounted) {
          context.pop();
          context.push('/dashboard/voice?room=${existing.roomName}&convId=${existing.conversationId}');
        }
        return;
      }
    }

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
      // Detect if recorder is already in the room (transcription mode)
      if (_participants.any((p) => p.identity == 'meeting-recorder')) {
        _transcriptionActive = true;
      }
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
      _settingUp = false;
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
      await _restoreAudioAfterInterruption();
    }
    return null;
  }

  /// Aggressively restore audio after an external phone call interruption.
  /// The key insight: simply calling setMicrophoneEnabled(true) does nothing
  /// if the track already thinks it's enabled. We must toggle off→on to force
  /// WebRTC to reconfigure its audio unit. Same for remote tracks — unsubscribe
  /// then resubscribe to force the audio pipeline to restart.
  Future<void> _restoreAudioAfterInterruption() async {
    debugPrint('[VoiceCall] _restoreAudioAfterInterruption: starting');
    // Retry with increasing delays — iOS audio session timing is unpredictable
    for (final delay in [0, 500, 1200, 2500]) {
      if (delay > 0) {
        await Future.delayed(Duration(milliseconds: delay));
        if (!mounted || _navigatedAway) return;
      }
      // 1. Reactivate native audio session
      try {
        await _audioChannel.invokeMethod('requestAudioFocus');
      } catch (_) {}
      // 2. Toggle microphone off→on to force WebRTC audio unit restart.
      //    Just setMicrophoneEnabled(true) is a no-op if already enabled.
      try {
        await _room?.localParticipant?.setMicrophoneEnabled(false);
        await Future.delayed(const Duration(milliseconds: 100));
        await _room?.localParticipant?.setMicrophoneEnabled(!_muted);
      } catch (_) {}
      // 3. Force re-subscribe remote audio tracks by toggling subscription.
      //    This makes WebRTC recreate the audio renderer for each track.
      if (_room != null) {
        for (final p in _room!.remoteParticipants.values) {
          for (final pub in p.audioTrackPublications) {
            try {
              pub.unsubscribe();
              await Future.delayed(const Duration(milliseconds: 50));
              pub.subscribe();
            } catch (_) {}
          }
        }
      }
    }
    // Restore audio output to what user had selected
    if (mounted && !_navigatedAway) {
      try {
        await _audioChannel.invokeMethod('setAudioOutput', _audioOutputType);
      } catch (_) {}
      if (_audioOutputType == 'earpiece') {
        try { await lk.Hardware.instance.setSpeakerphoneOn(false); } catch (_) {}
      } else if (_audioOutputType == 'speaker') {
        try { await lk.Hardware.instance.setSpeakerphoneOn(true); } catch (_) {}
      }
      setState(() {});
    }
    debugPrint('[VoiceCall] _restoreAudioAfterInterruption: complete');
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
    // Set audio output to earpiece — CallKit defaults to speaker.
    // Must be done AFTER mic is enabled because LiveKit reconfigures the
    // audio session when publishing the audio track. Add a delay to let
    // WebRTC finish its async audio session setup.
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted || _navigatedAway) return;
    try {
      await _audioChannel.invokeMethod('setAudioOutput', 'earpiece');
    } catch (_) {}
    try {
      await lk.Hardware.instance.setSpeakerphoneOn(false);
    } catch (_) {}
    if (mounted) setState(() {});
    debugPrint('[VoiceCall] _restoreAudioAfterCallKit: complete');
  }

  Future<void> _connect() async {
    debugPrint('[VoiceCall] _connect() called, isIncoming=${widget.isIncoming}, room=${widget.roomName}, calleeName=${widget.calleeName}, calleeAvatar=${widget.calleeAvatar}, calleeId=${widget.calleeId}');
    // Load avatars: callee (if not passed or empty) and own avatar
    if (widget.calleeAvatar == null || widget.calleeAvatar!.isEmpty) {
      _loadCalleeAvatar();
    }
    _loadMyAvatar();
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
      // Set earpiece — CallKit defaults to speaker
      try {
        await lk.Hardware.instance.setSpeakerphoneOn(false);
      } catch (_) {}
      try {
        await _audioChannel.invokeMethod('setAudioOutput', 'earpiece');
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
        calleeName: widget.calleeName,
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

      // Fetch avatars for all initial participants
      for (final p in _room!.remoteParticipants.values) {
        _fetchParticipantAvatar(p.identity);
      }

      // With autoSubscribe:false, manually subscribe to existing tracks
      for (final p in _room!.remoteParticipants.values) {
        if (p.identity == 'voice-translator') {
          // Subscribe to translation track only if user enabled translation
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

      // If meeting-recorder is already in the room, mark recording as active
      // and claim ownership so user can stop/restart it
      if (_participants.any((p) => p.identity == 'meeting-recorder')) {
        final myId = _room?.localParticipant?.identity;
        final l10n = AppLocalizations.of(context)!;
        final myName = _room?.localParticipant?.name ?? l10n.voiceParticipant;
        setState(() {
          _isRecording = true;
          _recordingApproved = true;
          _recordingInitiatorId = myId;
          _recordingInitiatorName = myName;
        });
      }

      // If there are already human participants in the room, stop ringback immediately
      if (_participants.any((p) => p.identity != 'ai-assistant')) {
        _stopRingback();
      }

      // Request audio focus BEFORE enabling microphone — ensures the audio session
      // is active (critical after endAllCalls() deactivated it for incoming calls).
      try {
        await _audioChannel.invokeMethod('requestAudioFocus')
            .timeout(const Duration(seconds: 8));
      } catch (_) {}

      // Enable microphone; may fail on iOS simulator — don't treat as fatal
      try {
        await _room!.localParticipant?.setMicrophoneEnabled(true)
            .timeout(const Duration(seconds: 8));
      } catch (_) {}

      _settingUp = false;
      setState(() => _connecting = false);
      WakelockPlus.enable();

      // Force earpiece mode — LiveKit may override speakerphone asynchronously on Android.
      // Call twice: once early, once after LiveKit audio stack fully initialises.
      _forceEarpiece();
      // Retry mic enable with delays — on iOS the audio session may be deactivated
      // right after WebRTC setup, causing a silent published track.
      // This mirrors _restoreAudioAfterCallKit's retry strategy.
      _retryMicEnable();
    } catch (e) {
      debugPrint('[VoiceCall] _connect() error: $e');
      _settingUp = false;
      setState(() {
        _error = e.toString();
        _connecting = false;
      });
    }
  }

  /// Sets audio output to earpiece. Called multiple times with increasing delays
  /// to override LiveKit/WebRTC's async speakerphone activation on Android.
  /// Uses both LiveKit Hardware API and native channel for reliable control.
  /// Retry enabling the microphone with increasing delays after connect.
  /// On iOS, the audio session may be briefly deactivated right after WebRTC
  /// setup — the track is published but silent until mic is re-enabled.
  Future<void> _retryMicEnable() async {
    for (final delay in [800, 2000, 4000]) {
      await Future.delayed(Duration(milliseconds: delay));
      if (!mounted || _navigatedAway) return;
      if (!_muted) {
        try { await _audioChannel.invokeMethod('requestAudioFocus'); } catch (_) {}
        try { await _room?.localParticipant?.setMicrophoneEnabled(true); } catch (_) {}
      }
    }
  }

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
        // Fetch avatar for new participant
        _fetchParticipantAvatar(event.participant.identity);
        final newId = event.participant.identity;
        final localId = _room?.localParticipant?.identity;
        final isHuman = newId != 'meeting-recorder' && newId != 'ai-assistant' && newId != 'voice-translator';

        if (isHuman && localId != null) {
          // Delay to let new participant's data channel initialize
          await Future.delayed(const Duration(seconds: 2));
          if (!mounted || _navigatedAway) return;

          // If consent is pending, add new participant and send request ONLY to them
          if (_consentPending && _recordingInitiatorId == localId) {
            _consentResponses[newId] = _ConsentEntry(event.participant.name ?? AppLocalizations.of(context)!.voiceParticipant);
            _sendDataTo([newId], {
              'type': 'recording_consent_request',
              'initiatorId': _recordingInitiatorId,
              'initiatorName': _recordingInitiatorName,
            });
          }

          // If recording is already active, send consent request ONLY to new participant
          if (_isRecording && _recordingApproved && _recordingInitiatorId == localId && !_consentPending) {
            _consentResponses.clear(); // clear old entries — only track new participant
            _consentResponses[newId] = _ConsentEntry(event.participant.name ?? AppLocalizations.of(context)!.voiceParticipant);
            setState(() => _consentPending = true);
            _sendDataTo([newId], {
              'type': 'recording_consent_request',
              'initiatorId': _recordingInitiatorId,
              'initiatorName': _recordingInitiatorName,
              'recordingActive': true,
            });
          }
        }
        // voice-translator joined — update subscription if user has translation enabled
        if (event.participant.identity == 'voice-translator') {
          if (_translationEnabled) _updateTranslationTrackSubscription();
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
        final identity = event.participant.identity;
        // If recording/transcription initiator left, end everything
        if (identity == _recordingInitiatorId && (_isRecording || _transcriptionActive || _consentPending)) {
          _resetRecordingState();
        }
        // Remove from consent tracking
        if (_consentPending && _consentResponses.containsKey(identity)) {
          _consentResponses.remove(identity);
          _checkAllConsented();
        }
        if (mounted) setState(() {});
      })
      ..on<lk.ActiveSpeakersChangedEvent>((event) {
        if (!mounted) return;
        final newSpeakers = event.speakers
            .where((p) => p.isSpeaking)
            .map((p) => p.identity)
            .toSet();
        if (!setEquals(_speakingIdentities, newSpeakers)) {
          setState(() {
            _speakingIdentities.clear();
            _speakingIdentities.addAll(newSpeakers);
          });
        }
      })
      ..on<lk.DataReceivedEvent>((event) {
        _handleDataReceived(event);
      })
      ..on<lk.RoomMetadataChangedEvent>((_) {});
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
      // Track if any real participant ever joined
      if (_participants.any((p) => p.identity != 'ai-assistant' && p.identity != 'meeting-recorder' && p.identity != 'voice-translator')) {
        _hadRemoteParticipant = true;
      }
      // Stop ringback if human participants appeared
      if (_ringing && _participants.any((p) => p.identity != 'ai-assistant')) {
        _stopRingback();
      }
      // Auto-hangup when all remote participants left (only if someone WAS here before)
      if (_participants.isEmpty && !_connecting && !_ringing && !_reconnecting && !_manualReconnecting && _hadRemoteParticipant) {
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

  Future<void> _toggleHold() async {
    if (_onHold) {
      // Resume: stop server-side hold music, re-subscribe to remote audio
      try {
        final client = sl<DioClient>();
        await client.post('/voice/rooms/$_roomName/hold-music/stop', data: {}, fromJson: (d) => d);
      } catch (_) {}
      for (final p in _room!.remoteParticipants.values) {
        for (final pub in p.audioTrackPublications) {
          if (pub.participant?.identity == 'hold-music') continue;
          try { pub.subscribe(); } catch (_) {}
        }
      }
      await _room?.localParticipant?.setMicrophoneEnabled(true);
      if (_cameraOn) await _room?.localParticipant?.setCameraEnabled(true);
      setState(() { _onHold = false; _muted = false; });
    } else {
      // Hold: mute mic, disable camera, mute incoming audio
      await _room?.localParticipant?.setMicrophoneEnabled(false);
      await _room?.localParticipant?.setCameraEnabled(false);
      // Unsubscribe from remote audio so we don't hear the other party
      for (final p in _room!.remoteParticipants.values) {
        for (final pub in p.audioTrackPublications) {
          try { pub.unsubscribe(); } catch (_) {}
        }
      }
      // Start server-side hold music for the other party (they hear music)
      // Initiator stays in silence — no local music
      try {
        final client = sl<DioClient>();
        await client.post('/voice/rooms/$_roomName/hold-music/start', data: {}, fromJson: (d) => d);
      } catch (_) {}
      setState(() { _onHold = true; _muted = true; });
    }
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
    try {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(RouteConstants.assistant);
      }
    } catch (e) {
      debugPrint('[VoiceCall] _navigateBack error (ignored): $e');
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
                AppLocalizations.of(context)!.voiceInvitesToRoom,
                style: TextStyle(color: colors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              title?.isNotEmpty == true ? title! : AppLocalizations.of(context)!.voiceRoom,
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
                    AppLocalizations.of(context)!.voicePasswordProtected,
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
                  hintText: AppLocalizations.of(context)!.voicePasswordHint,
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
            child: Text(AppLocalizations.of(context)!.cancel, style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop({'password': passwordController.text}),
            child: Text(
              AppLocalizations.of(context)!.voiceEnter,
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
            Text(AppLocalizations.of(context)!.voiceJoinRoom,
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
            hintText: AppLocalizations.of(context)!.voiceYourName,
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
            child: Text(AppLocalizations.of(context)!.cancel, style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final t = controller.text.trim();
              if (t.isNotEmpty) Navigator.of(ctx).pop(t);
            },
            child: Text(AppLocalizations.of(context)!.voiceEnter, style: TextStyle(color: colors.primary)),
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

  // ── In-call Assistant ──

  // PCM16 audio buffer for assistant speech playback
  final List<int> _assistantAudioBuffer = [];
  bool _assistantSpeaking = false;

  Future<void> _startAssistant() async {
    if (_assistantActive) return;

    setState(() {
      _assistantActive = true;
      _muted = true;
    });

    // Fully disable LiveKit microphone to release hardware
    await _room?.localParticipant?.setMicrophoneEnabled(false);
    // Wait for hardware to be released
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final token = await sl<SecureStorageService>().getAccessToken();
      final baseUrl = AppConfig.baseUrl.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://');
      final wsUrl = '$baseUrl/voice/realtime-proxy?token=$token';
      _assistantWs = await WebSocket.connect(wsUrl);

      _assistantWs!.listen(
        (data) => _handleAssistantMessage(data),
        onDone: () {
          if (mounted) _stopAssistant();
        },
        onError: (_) {
          if (mounted) _stopAssistant();
        },
      );

      // Wait for WebSocket handshake
      await Future.delayed(const Duration(milliseconds: 500));
      _configureAssistantSession();
      // Additional delay for session to be configured
      await Future.delayed(const Duration(milliseconds: 300));
      await _startAssistantRecording();
    } catch (e) {
      debugPrint('[InCallAssistant] Error: $e');
      _stopAssistant();
    }
  }

  String _buildCallAssistantPrompt(List<String> participantNames) {
    final locale = Localizations.localeOf(context).languageCode;
    final participantsJoined = participantNames.join(', ');

    if (locale == 'ru') {
      final participantsStr = participantNames.isEmpty
          ? ''
          : '\nУчастники текущего звонка: $participantsJoined';
      return '''Ты — голосовой ассистент во время звонка. Пользователь временно отключил микрофон в звонке, чтобы дать тебе команду. Будь кратким.
$participantsStr
Если пользователь просит добавить кого-то в звонок:
1. Вызови get_conversations чтобы получить список контактов
2. Найди нужного человека по имени или username (otherUserUsername)
3. Вызови send_call_invite с conversationId найденного диалога
4. Если не нашёл в диалогах — вызови search_contacts и повтори поиск

Отвечай коротко — пользователь в разгаре разговора.''';
    }

    final participantsStr = participantNames.isEmpty
        ? ''
        : '\nCurrent call participants: $participantsJoined';
    return '''You are a voice assistant during a call. The user has temporarily muted their microphone in the call to give you a command. Be brief.
$participantsStr
If the user asks to add someone to the call:
1. Call get_conversations to get the contact list
2. Find the needed person by name or username (otherUserUsername)
3. Call send_call_invite with the conversationId of the found conversation
4. If not found in conversations — call search_contacts and retry

Answer briefly — the user is in the middle of a conversation.''';
  }

  void _configureAssistantSession() {
    if (_assistantWs == null) return;

    // Get participant names for context
    final participantNames = _participants.map((p) => p.name ?? p.identity).toList();
    final instructions = _buildCallAssistantPrompt(participantNames);

    final sessionConfig = {
      'type': 'session.update',
      'session': {
        'modalities': ['text', 'audio'],
        'voice': 'sage',
        'input_audio_format': 'pcm16',
        'output_audio_format': 'pcm16',
        'instructions': instructions,
        'tools': [
          {
            'type': 'function',
            'name': 'get_conversations',
            'description': 'Get list of user conversations/chats. Returns array with id, otherUserName, otherUserUsername, otherUserId, type fields.',
            'parameters': {'type': 'object', 'properties': {}},
          },
          {
            'type': 'function',
            'name': 'search_contacts',
            'description': 'Search for users by name, username. Returns array with id, firstName, lastName, username.',
            'parameters': {
              'type': 'object',
              'properties': {
                'query': {'type': 'string', 'description': 'Search query (name or username, min 2 chars)'},
              },
              'required': ['query'],
            },
          },
          {
            'type': 'function',
            'name': 'send_call_invite',
            'description': 'Send call invite to a contact to join current call. Provide the conversationId of the direct chat with this person.',
            'parameters': {
              'type': 'object',
              'properties': {
                'conversationId': {'type': 'string', 'description': 'Conversation ID of the direct chat'},
                'name': {'type': 'string', 'description': 'Name of the person being invited'},
              },
              'required': ['conversationId'],
            },
          },
        ],
        'turn_detection': {
          'type': 'server_vad',
          'threshold': 0.5,
          'prefix_padding_ms': 300,
          'silence_duration_ms': 500,
        },
      },
    };

    _assistantWs!.add(jsonEncode(sessionConfig));
    _assistantSessionConfigured = true;
  }

  Future<void> _startAssistantRecording() async {
    if (_assistantWs == null) return;
    final tmpDir = await getTemporaryDirectory();
    final stream = await _assistantRecorder.startStream(RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 24000,
      numChannels: 1,
      autoGain: true,
      echoCancel: true,
      noiseSuppress: true,
    ));
    _assistantRecordSub = stream.listen((data) {
      if (_assistantWs != null && _assistantSessionConfigured) {
        _assistantWs!.add(jsonEncode({
          'type': 'input_audio_buffer.append',
          'audio': base64Encode(data),
        }));
      }
    });
  }

  void _handleAssistantMessage(dynamic raw) {
    if (raw is! String) return;
    final msg = jsonDecode(raw) as Map<String, dynamic>;
    final type = msg['type'] as String? ?? '';

    if (type == 'response.function_call_arguments.done') {
      final name = msg['name'] as String? ?? '';
      final args = msg['arguments'] as String? ?? '{}';
      final callId = msg['call_id'] as String? ?? '';
      _handleAssistantFunctionCall(name, args, callId);
    } else if (type == 'response.audio.delta') {
      // Buffer assistant audio response
      final audioB64 = msg['delta'] as String? ?? '';
      if (audioB64.isNotEmpty) {
        _assistantAudioBuffer.addAll(base64Decode(audioB64));
      }
    } else if (type == 'response.audio.done') {
      // Play buffered assistant audio
      _playAssistantAudio();
    } else if (type == 'response.audio_transcript.delta') {
      // Could show transcript overlay if needed
    }
  }

  Future<void> _playAssistantAudio() async {
    if (_assistantAudioBuffer.isEmpty) return;
    if (mounted) setState(() => _assistantSpeaking = true);

    try {
      // Convert PCM16 24kHz mono to WAV for playback
      final pcmData = Uint8List.fromList(_assistantAudioBuffer);
      _assistantAudioBuffer.clear();

      final wavHeader = _buildWavHeader(pcmData.length, 24000, 1, 16);
      final wavData = Uint8List(wavHeader.length + pcmData.length);
      wavData.setAll(0, wavHeader);
      wavData.setAll(wavHeader.length, pcmData);

      final tmpDir = await getTemporaryDirectory();
      final wavFile = File('${tmpDir.path}/assistant_response.wav');
      await wavFile.writeAsBytes(wavData);

      // Stop recording while playing to avoid feedback
      await _assistantRecordSub?.cancel();
      _assistantRecordSub = null;
      try { await _assistantRecorder.stop(); } catch (_) {}

      final player = AudioPlayer();
      await player.play(DeviceFileSource(wavFile.path));
      await player.onPlayerComplete.first;
      player.dispose();

      // Resume recording after playback
      if (_assistantActive && _assistantWs != null) {
        await _startAssistantRecording();
      }
    } catch (e) {
      debugPrint('[InCallAssistant] Audio playback error: $e');
    } finally {
      if (mounted) setState(() => _assistantSpeaking = false);
    }
  }

  Uint8List _buildWavHeader(int dataLength, int sampleRate, int channels, int bitsPerSample) {
    final byteRate = sampleRate * channels * bitsPerSample ~/ 8;
    final blockAlign = channels * bitsPerSample ~/ 8;
    final header = ByteData(44);
    // RIFF header
    header.setUint8(0, 0x52); header.setUint8(1, 0x49); header.setUint8(2, 0x46); header.setUint8(3, 0x46);
    header.setUint32(4, 36 + dataLength, Endian.little);
    header.setUint8(8, 0x57); header.setUint8(9, 0x41); header.setUint8(10, 0x56); header.setUint8(11, 0x45);
    // fmt chunk
    header.setUint8(12, 0x66); header.setUint8(13, 0x6D); header.setUint8(14, 0x74); header.setUint8(15, 0x20);
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little); // PCM
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);
    // data chunk
    header.setUint8(36, 0x64); header.setUint8(37, 0x61); header.setUint8(38, 0x74); header.setUint8(39, 0x61);
    header.setUint32(40, dataLength, Endian.little);
    return header.buffer.asUint8List();
  }

  Future<void> _handleAssistantFunctionCall(String name, String argsJson, String callId) async {
    try {
      final args = jsonDecode(argsJson) as Map<String, dynamic>;
      String output;

      if (name == 'get_conversations') {
        debugPrint('[InCallAssistant] get_conversations');
        final data = await sl<DioClient>().get<List<dynamic>>(
          '/messenger/conversations',
          fromJson: (d) => d as List<dynamic>,
        );
        output = jsonEncode(data);
      } else if (name == 'search_contacts') {
        final query = args['query'] as String? ?? '';
        debugPrint('[InCallAssistant] search_contacts: "$query"');
        final encoded = Uri.encodeComponent(query);
        final data = await sl<DioClient>().get<List<dynamic>>(
          '/messenger/users/search?q=$encoded',
          fromJson: (d) => d as List<dynamic>,
        );
        output = jsonEncode(data);
      } else if (name == 'send_call_invite') {
        final convId = args['conversationId'] as String? ?? '';
        final inviteeName = args['name'] as String? ?? '';
        debugPrint('[InCallAssistant] send_call_invite: convId=$convId, name=$inviteeName, room=$_roomName');
        if (_roomName != null && convId.isNotEmpty) {
          sl<MessengerRemoteDataSource>().sendCallInvite(convId, _roomName!);
          final l10n = AppLocalizations.of(context)!;
          output = jsonEncode({'ok': true, 'message': l10n.voiceInvitationSent(inviteeName.isNotEmpty ? inviteeName : l10n.voiceParticipant)});
        } else {
          output = jsonEncode({'ok': false, 'message': AppLocalizations.of(context)!.voiceNoActiveRoom});
        }
      } else {
        debugPrint('[InCallAssistant] unknown function: $name');
        output = jsonEncode({'error': 'Unknown function: $name'});
      }

      debugPrint('[InCallAssistant] $name result: ${output.length > 200 ? '${output.substring(0, 200)}...' : output}');
      _assistantWs?.add(jsonEncode({
        'type': 'conversation.item.create',
        'item': {
          'type': 'function_call_output',
          'call_id': callId,
          'output': output,
        },
      }));
      _assistantWs?.add(jsonEncode({'type': 'response.create'}));
    } catch (e) {
      debugPrint('[InCallAssistant] $name error: $e');
      _assistantWs?.add(jsonEncode({
        'type': 'conversation.item.create',
        'item': {
          'type': 'function_call_output',
          'call_id': callId,
          'output': jsonEncode({'error': e.toString()}),
        },
      }));
      _assistantWs?.add(jsonEncode({'type': 'response.create'}));
    }
  }

  Future<void> _stopAssistant() async {
    _assistantSessionConfigured = false;
    await _assistantRecordSub?.cancel();
    _assistantRecordSub = null;
    try { await _assistantRecorder.stop(); } catch (_) {}
    try { _assistantWs?.close(); } catch (_) {}
    _assistantWs = null;

    // Unmute mic back in the room
    if (_room != null && mounted) {
      await _room!.localParticipant?.setMicrophoneEnabled(true);
      setState(() {
        _assistantActive = false;
        _muted = false;
      });
    } else {
      if (mounted) setState(() => _assistantActive = false);
    }
  }

  Future<void> _toggleCamera() async {
    if (!_cameraOn) {
      final status = await Permission.camera.request();
      debugPrint('[VoiceCall] Camera permission: $status');
      if (!status.isGranted) {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.voiceCameraPermission),
              action: SnackBarAction(
                label: l10n.voiceOpenSettings,
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
      // Stop video effects processor before disabling camera
      final vfx = sl<VideoEffectsService>();
      if (!newCameraOn && vfx.current != VideoEffect.none) {
        await vfx.stopEffect();
      }

      await _room?.localParticipant?.setCameraEnabled(newCameraOn);
      debugPrint('[VoiceCall] setCameraEnabled($newCameraOn) done, pubs=${_room?.localParticipant?.videoTrackPublications.length}');
      if (mounted) setState(() => _cameraOn = newCameraOn);

      // Switch to speaker when video is enabled
      if (newCameraOn && mounted && _audioOutputType == 'earpiece') {
        _setAudioOutput('speaker');
      }

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
            content: Text(AppLocalizations.of(context)!.voiceCameraError(e.toString())),
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
      // Re-attach video effects processor to the new track
      final vfx = sl<VideoEffectsService>();
      if (vfx.current != VideoEffect.none) {
        await Future.delayed(const Duration(milliseconds: 300));
        await vfx.reattach();
      }
      if (mounted) setState(() => _isFrontCamera = newFront);
    } catch (e) {
      debugPrint('[VoiceCall] flipCamera error: $e');
    }
  }

  void _showVideoEffectsPicker() {
    final vfx = sl<VideoEffectsService>();
    // Get the native track ID for Android to find the correct LocalVideoTrack
    String? nativeTrackId;
    final pubs = _room?.localParticipant?.videoTrackPublications ?? [];
    final localVideoTrack = pubs.firstWhereOrNull((p) => p.track != null)?.track;
    if (localVideoTrack != null) {
      nativeTrackId = localVideoTrack.mediaStreamTrack.id;
      debugPrint('[VoiceCall] Video track ID for effects: $nativeTrackId');
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => VideoEffectsPicker(
        currentEffect: vfx.current,
        onSelect: (effect) async {
          Navigator.pop(context);
          try {
            await vfx.applyEffect(effect, trackId: nativeTrackId);
          } catch (e) {
            debugPrint('[VoiceCall] Video effect error: $e');
          }
          if (mounted) setState(() {});
        },
        onSelectCustom: (imageBytes) async {
          Navigator.pop(context);
          try {
            await vfx.applyCustomImage(imageBytes, trackId: nativeTrackId);
          } catch (e) {
            debugPrint('[VoiceCall] Custom background error: $e');
          }
          if (mounted) setState(() {});
        },
      ),
    );
  }

  // ═══════════════════════════════════════════
  // ── RECORDING WITH CONSENT ──
  // ═══════════════════════════════════════════

  void _toggleRecordingWithConsent({bool forTranscription = false}) {
    final localId = _room?.localParticipant?.identity;
    if (localId == null) return;

    // If we are the initiator and recording/consent is active — stop
    if (_recordingInitiatorId == localId && (_isRecording || _transcriptionActive || _consentPending)) {
      _endRecordingSession();
      return;
    }
    // If recording/transcription is active by someone else — can't stop
    if ((_recordingApproved || _transcriptionActive) && _recordingInitiatorId != localId) return;
    // Start consent flow
    _consentForTranscription = forTranscription;
    _requestRecordingConsent();
  }

  void _requestRecordingConsent() {
    final room = _room;
    if (room == null) return;
    debugPrint('[VoiceCall] _requestRecordingConsent: consentPending=$_consentPending isRecording=$_isRecording transcription=$_transcriptionActive initiator=$_recordingInitiatorId forTranscription=$_consentForTranscription');
    if (_consentPending || _isRecording || _transcriptionActive) return;
    final localId = room.localParticipant?.identity;
    final l10n = AppLocalizations.of(context)!;
    final localName = room.localParticipant?.name ?? l10n.voiceParticipant;

    final participants = room.remoteParticipants.values
        .where((p) => p.identity != 'meeting-recorder' && p.identity != 'voice-translator' && p.identity != 'ai-assistant')
        .toList();

    // If no other participants, start directly
    if (participants.isEmpty) {
      setState(() {
        _recordingInitiatorId = localId;
        _recordingInitiatorName = localName;
        _recordingApproved = true;
      });
      if (_consentForTranscription) {
        _startTranscription();
      } else {
        _startRecording();
      }
      _broadcastData({'type': 'recording_approved', 'initiatorId': localId, 'initiatorName': localName, 'forTranscription': _consentForTranscription});
      return;
    }

    setState(() {
      _consentPending = true;
      _recordingInitiatorId = localId;
      _recordingInitiatorName = localName;
      _consentResponses.clear();
      for (final p in participants) {
        _consentResponses[p.identity] = _ConsentEntry(p.name ?? l10n.voiceParticipant);
      }
    });

    // Send consent request with retries — data channel may not be ready
    _sendConsentRequestWithRetry(localId!, localName);
  }

  void _sendConsentRequestWithRetry(String initiatorId, String initiatorName, {bool recordingActive = false}) {
    // Send consent request multiple times with increasing delays
    // Data channel may not be ready immediately after (re)connecting
    for (int i = 0; i < 4; i++) {
      final delay = [0, 2, 4, 7][i];
      Future.delayed(Duration(seconds: delay), () {
        if (!mounted || _navigatedAway || !_consentPending) return;
        final anyPending = _consentResponses.values.any((e) => e.accepted == null);
        if (!anyPending && i > 0) return; // all responded — stop retrying
        debugPrint('[VoiceCall] Sending consent request attempt ${i + 1}/4 forTranscription=$_consentForTranscription');
        _broadcastData({
          'type': 'recording_consent_request',
          'initiatorId': initiatorId,
          'initiatorName': initiatorName,
          if (recordingActive) 'recordingActive': true,
          if (_consentForTranscription) 'forTranscription': true,
        });
      });
    }
  }

  void _handleDataReceived(lk.DataReceivedEvent event) {
    if (!mounted || _navigatedAway) return;
    try {
      final msg = jsonDecode(utf8.decode(event.data)) as Map<String, dynamic>;
      final type = msg['type'] as String?;
      final participant = event.participant;
      if (type == null) return;

      // Deduplicate messages
      final msgId = msg['msgId'] as String?;
      if (msgId != null) {
        if (_processedMessageIds.contains(msgId)) return;
        _processedMessageIds.add(msgId);
        // Keep set bounded
        if (_processedMessageIds.length > 200) {
          _processedMessageIds.clear();
        }
      }

      switch (type) {
        case 'recording_consent_request':
          _onConsentRequest(participant, msg);
          break;
        case 'recording_consent_response':
          _onConsentResponse(participant, msg);
          break;
        case 'recording_approved':
          _onRecordingApproved(msg);
          break;
        case 'recording_denied':
          _onRecordingDenied(msg);
          break;
        case 'recording_denied_late':
          _onRecordingDeniedLate(msg);
          break;
        case 'recording_ended':
          _onRecordingEnded(msg);
          break;
        case 'transcription_status':
          _onTranscriptionStatus(msg);
          break;
        case 'recording_status':
          // legacy web client broadcast — ignore in mobile
          break;
      }
    } catch (e) {
      debugPrint('[VoiceCall] DataReceived parse error: $e');
    }
  }

  void _onConsentRequest(lk.RemoteParticipant? participant, Map<String, dynamic> msg) {
    if (!mounted || _navigatedAway) return;
    final initiatorId = msg['initiatorId'] as String?;
    final initiatorName = msg['initiatorName'] as String? ?? AppLocalizations.of(context)!.voiceParticipant;
    final recordingAlreadyActive = msg['recordingActive'] as bool? ?? false;
    final forTranscription = msg['forTranscription'] as bool? ?? false;
    final localId = _room?.localParticipant?.identity;
    if (initiatorId == localId) return; // self
    if ((_isRecording || _transcriptionActive) && _recordingInitiatorId == initiatorId) return; // already active
    if (_recordingApproved && _recordingInitiatorId == initiatorId) return; // already approved
    if (_consentDialogShowing) return; // already showing dialog

    setState(() {
      _recordingInitiatorId = initiatorId;
      _recordingInitiatorName = initiatorName;
      _consentForTranscription = forTranscription;
    });

    _showConsentDialog(initiatorName, recordingActive: recordingAlreadyActive, forTranscription: forTranscription);
  }

  void _onConsentResponse(lk.RemoteParticipant? participant, Map<String, dynamic> msg) {
    if (!mounted || _navigatedAway) return;
    final localId = _room?.localParticipant?.identity;
    final identity = participant?.identity;
    final accepted = msg['accepted'] as bool? ?? false;
    final responderName = msg['responderName'] as String? ?? AppLocalizations.of(context)!.voiceParticipant;
    debugPrint('[VoiceCall] _onConsentResponse from=$identity accepted=$accepted initiator=$_recordingInitiatorId localId=$localId consentPending=$_consentPending keys=${_consentResponses.keys}');
    if (_recordingInitiatorId != localId || !_consentPending) return;

    if (identity != null && _consentResponses.containsKey(identity)) {
      setState(() {
        _consentResponses[identity] = _ConsentEntry(responderName, accepted: accepted);
      });
    }

    if (!accepted) {
      // If recording is already active, don't stop it — just notify
      if (_isRecording && _recordingApproved) {
        setState(() => _consentPending = false);
        _consentResponses.remove(identity);
        _broadcastData({
          'type': 'recording_denied_late',
          'initiatorId': localId,
          'declinedBy': responderName,
        });
        _showSnack('$responderName отклонил запись и покинет звонок');
        return;
      }
      setState(() => _consentPending = false);
      _broadcastData({'type': 'recording_denied', 'initiatorId': localId, 'declinedBy': responderName});
      _showSnack('$responderName отклонил запись');
      _resetRecordingState();
      return;
    }

    _checkAllConsented();
  }

  void _checkAllConsented() {
    if (!mounted || _navigatedAway || !_consentPending) return;
    final all = _consentResponses.values.toList();
    if (all.isEmpty) return;
    if (all.every((e) => e.accepted == true)) {
      setState(() {
        _consentPending = false;
        _recordingApproved = true;
      });
      // Only start if not already active (new participant consent)
      final l10n = AppLocalizations.of(context)!;
      if (!_isRecording && !_transcriptionActive) {
        if (_consentForTranscription) {
          _startTranscription();
          _showSnack(l10n.voiceAllAgreedRecording);
        } else {
          _startRecording();
          _showSnack(l10n.voiceAllAgreedRecording);
        }
      } else {
        _showSnack(l10n.voiceNewParticipantAgreed);
      }
      _broadcastData({
        'type': 'recording_approved',
        'initiatorId': _recordingInitiatorId,
        'initiatorName': _recordingInitiatorName,
        'forTranscription': _consentForTranscription,
      });
    }
  }

  void _onRecordingApproved(Map<String, dynamic> msg) {
    if (!mounted || _navigatedAway) return;
    final forTranscription = msg['forTranscription'] as bool? ?? false;
    setState(() {
      _recordingInitiatorId = msg['initiatorId'] as String?;
      _recordingInitiatorName = msg['initiatorName'] as String? ?? '';
      _recordingApproved = true;
      _consentForTranscription = forTranscription;
      if (forTranscription) {
        _transcriptionActive = true;
        _transcriptionInitiatorId = msg['initiatorId'] as String?;
        _transcriptionInitiatorName = msg['initiatorName'] as String? ?? '';
      }
    });
    if (_consentDialogShowing) {
      try { Navigator.of(context, rootNavigator: true).pop(); } catch (_) {}
    }
  }

  void _onRecordingDenied(Map<String, dynamic> msg) {
    if (!mounted || _navigatedAway) return;
    final declinedBy = msg['declinedBy'] as String?;
    if (_consentDialogShowing) {
      try { Navigator.of(context, rootNavigator: true).pop(); } catch (_) {}
    }
    _resetRecordingState();
    if (declinedBy != null) _showSnack('$declinedBy отклонил запись');
  }

  void _onRecordingDeniedLate(Map<String, dynamic> msg) {
    if (!mounted || _navigatedAway) return;
    final l10n = AppLocalizations.of(context)!;
    final declinedBy = msg['declinedBy'] as String? ?? l10n.voiceParticipant;
    final localName = _room?.localParticipant?.name ?? '';
    // If I'm the one who declined, I need to leave the call
    if (declinedBy == localName) {
      _showSnack(l10n.voiceDeclinedRecording);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && !_navigatedAway) _hangUp();
      });
    } else {
      _showSnack('$declinedBy отклонил запись и покинет звонок');
    }
  }

  void _onRecordingEnded(Map<String, dynamic> msg) {
    if (!mounted || _navigatedAway) return;
    if (_consentDialogShowing) {
      try { Navigator.of(context, rootNavigator: true).pop(); } catch (_) {}
    }
    final wasTranscription = _transcriptionActive;
    if ((_isRecording || _transcriptionActive) && _recordingInitiatorId == _room?.localParticipant?.identity) {
      _stopRecording();
    }
    _resetRecordingState();
    _showSnack(AppLocalizations.of(context)!.voiceRecordingEnded);
  }

  void _endRecordingSession() {
    final localId = _room?.localParticipant?.identity;
    if (_recordingInitiatorId != localId) return;
    if (_isRecording || _transcriptionActive) _stopRecording();
    _broadcastData({'type': 'recording_ended', 'initiatorId': localId});
    _resetRecordingState();
  }

  Future<void> _startRecording() async {
    final roomName = _roomName;
    if (roomName == null) return;
    try {
      await sl<DioClient>().dio.post('/voice/rooms/$roomName/recorder/start',
          data: {'withAi': false});
      if (mounted) setState(() => _isRecording = true);
    } catch (e) {
      debugPrint('[VoiceCall] Recorder start error: $e');
    }
  }

  Future<void> _startTranscription() async {
    final roomName = _roomName;
    if (roomName == null) return;
    final localId = _room?.localParticipant?.identity;
    final localName = _room?.localParticipant?.name ?? AppLocalizations.of(context)!.voiceParticipant;
    try {
      await sl<DioClient>().dio.post('/voice/rooms/$roomName/recorder/start',
          data: {'withAi': true});
      if (mounted) setState(() {
        _transcriptionActive = true;
        _transcriptionInitiatorId = localId;
        _transcriptionInitiatorName = localName;
      });
    } catch (e) {
      debugPrint('[VoiceCall] Transcription start error: $e');
    }
  }

  Future<void> _stopRecording() async {
    final roomName = _roomName;
    if (roomName == null) return;
    try {
      await sl<DioClient>().dio.post('/voice/rooms/$roomName/recorder/stop');
    } catch (e) {
      debugPrint('[VoiceCall] Recorder stop error: $e');
    }
    if (mounted) setState(() => _isRecording = false);
  }

  void _resetRecordingState() {
    if (!mounted || _navigatedAway) return;
    setState(() {
      _recordingInitiatorId = null;
      _recordingInitiatorName = '';
      _consentPending = false;
      _recordingApproved = false;
      _consentForTranscription = false;
      _consentResponses.clear();
      _isRecording = false;
      _transcriptionActive = false;
      _transcriptionInitiatorId = null;
      _transcriptionInitiatorName = '';
    });
  }

  void _showConsentDialog(String initiatorName, {bool recordingActive = false, bool forTranscription = false}) {
    if (_consentDialogShowing || _navigatedAway || !mounted) return;
    _consentDialogShowing = true;
    final l10n = AppLocalizations.of(context)!;
    final actionWord = forTranscription ? l10n.voiceTranscriptionWord : l10n.voiceRecordingWord;
    final declineLabel = recordingActive ? l10n.voiceDeclineAndLeave : l10n.notifDecline;
    final contentText = recordingActive
        ? ' ведёт $actionWord встречи.\nВаш голос будет записан.\nПри отказе вы покинете звонок.'
        : ' хочет начать $actionWord встречи.\nВаш голос будет записан.';
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      routeSettings: const RouteSettings(name: 'consent_dialog'),
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.of(context).card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.fiber_manual_record, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                recordingActive
                    ? l10n.voiceRecordingInProgress
                    : (forTranscription ? l10n.voiceTranscriptionRequest : l10n.voiceRecordingRequest),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 14, height: 1.5),
            children: [
              TextSpan(text: initiatorName, style: const TextStyle(fontWeight: FontWeight.w600)),
              TextSpan(text: contentText),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _respondToConsent(false);
            },
            child: Text(declineLabel, style: TextStyle(color: AppColors.of(context).error)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.of(context).primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _respondToConsent(true);
            },
            child: Text(l10n.voiceAgree),
          ),
        ],
      ),
    ).whenComplete(() {
      _consentDialogShowing = false;
    });
  }

  void _respondToConsent(bool accepted) {
    final localId = _room?.localParticipant?.identity;
    final localName = _room?.localParticipant?.name ?? AppLocalizations.of(context)!.voiceParticipant;
    _broadcastData({
      'type': 'recording_consent_response',
      'accepted': accepted,
      'responderId': localId,
      'responderName': localName,
    });
    if (accepted) {
      // Mark as approved so retry consent requests are ignored
      setState(() => _recordingApproved = true);
    } else {
      _resetRecordingState();
    }
  }

  // ═══════════════════════════════════════════
  // ── TRANSCRIPTION (ПРОТОКОЛИРОВАНИЕ) ──
  // ═══════════════════════════════════════════

  /// Uses the same consent flow as recording
  void _toggleTranscription() {
    _toggleRecordingWithConsent(forTranscription: true);
  }

  void _onTranscriptionStatus(Map<String, dynamic> msg) {
    if (!mounted || _navigatedAway) return;
    final active = msg['active'] as bool? ?? false;
    setState(() {
      _transcriptionActive = active;
      if (active) {
        _transcriptionInitiatorId = msg['initiatorId'] as String?;
        _transcriptionInitiatorName = msg['initiatorName'] as String? ?? '';
      } else {
        _transcriptionInitiatorId = null;
        _transcriptionInitiatorName = '';
      }
    });
  }

  // ── Shared helpers ──

  int _msgSeq = 0;
  void _broadcastData(Map<String, dynamic> msg) {
    final room = _room;
    if (room == null) return;
    // Add unique messageId for deduplication
    msg['msgId'] = '${room.localParticipant?.identity ?? ''}_${_msgSeq++}';
    final type = msg['type'];
    final remoteCount = room.remoteParticipants.length;
    debugPrint('[VoiceCall] broadcastData type=$type to $remoteCount participants');
    try {
      room.localParticipant?.publishData(
        utf8.encode(jsonEncode(msg)),
        reliable: true,
      );
    } catch (e) {
      debugPrint('[VoiceCall] broadcastData error: $e');
    }
  }

  /// Send data to specific participants only (not broadcast)
  void _sendDataTo(List<String> identities, Map<String, dynamic> msg) {
    final room = _room;
    if (room == null) return;
    msg['msgId'] = '${room.localParticipant?.identity ?? ''}_${_msgSeq++}';
    debugPrint('[VoiceCall] sendDataTo ${identities.join(',')} type=${msg['type']}');
    try {
      room.localParticipant?.publishData(
        utf8.encode(jsonEncode(msg)),
        reliable: true,
        destinationIdentities: identities,
      );
    } catch (e) {
      debugPrint('[VoiceCall] sendDataTo error: $e');
    }
  }

  void _showSnack(String text) {
    if (!mounted || _navigatedAway) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
    final l10n = AppLocalizations.of(context)!;
    List<Map<String, String>> outputs = [
      {'id': 'earpiece', 'name': l10n.voiceAudioPhone, 'type': 'earpiece'},
      {'id': 'speaker', 'name': l10n.voiceAudioSpeaker, 'type': 'speaker'},
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
              l10n.voiceAudioOutput,
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

  /// Switch the screen in-place to show a different call line.
  /// Tears down listeners for the old room and sets up the new one.
  void _switchToLine(CallLine line) {
    // Save current mute state to the outgoing line
    final cs = CallStateService.instance;
    final oldLine = cs.allLines.where((l) => l.roomName == _roomName).firstOrNull;
    if (oldLine != null) {
      oldLine.wasMuted = _muted;
    }

    // Dispose old room listeners
    _eventsListener?.dispose();
    _eventsListener = null;
    _room?.removeListener(_onRoomChanged);

    // Switch to new room
    _room = line.room;
    _roomName = line.roomName;
    _currentCalleeName = line.calleeName;
    _currentCalleeAvatar = line.calleeAvatar;

    // Sync participants from new room
    _participants
      ..clear()
      ..addAll(_room!.remoteParticipants.values);
    _speakingIdentities.clear();

    // Restore per-line state
    _muted = line.wasMuted;
    _onHold = false;
    _connecting = false;
    _error = null;
    _ringing = false;
    _reconnecting = false;
    _manualReconnecting = false;

    // Reset recording/transcription state (will be re-detected from room data)
    _isRecording = false;
    _recordingInitiatorId = null;
    _consentPending = false;
    _recordingApproved = false;
    _transcriptionActive = false;
    _transcriptionInitiatorId = null;

    // Detect if recorder is already in the new room
    if (_participants.any((p) => p.identity == 'meeting-recorder')) {
      _transcriptionActive = true;
    }

    // Stop assistant if active (it's per-room)
    if (_assistantActive) {
      _assistantSessionConfigured = false;
      _assistantRecordSub?.cancel();
      _assistantRecordSub = null;
      try { _assistantRecorder.stop(); } catch (_) {}
      try { _assistantWs?.close(); } catch (_) {}
      _assistantWs = null;
      _assistantActive = false;
    }

    // Re-subscribe to new room events
    _room!.addListener(_onRoomChanged);
    _subscribeRoomEvents();

    // Subscribe to tracks
    for (final p in _room!.remoteParticipants.values) {
      for (final pub in [...p.audioTrackPublications, ...p.videoTrackPublications]) {
        if (!pub.subscribed) {
          try { pub.subscribe(); } catch (_) {}
        }
      }
    }

    _hangingUp = false;
    if (mounted) setState(() {});
    debugPrint('[VoiceCall] switched to line: ${line.roomName}, callee: ${line.calleeName}');
  }

  void _minimizeCall() {
    if (_navigatedAway || !mounted) return;
    _navigatedAway = true;
    try {
      if (context.canPop()) {
        context.pop();
      } else {
        // No prior route to pop to (incoming call launched us directly);
        // fall back to the assistant home tab which also shows the active
        // call banner so the user can re-enter the call.
        context.go(RouteConstants.assistant);
      }
    } catch (e) {
      debugPrint('[VoiceCall] _minimizeCall error (ignored): $e');
    }
  }

  bool _hangingUp = false;

  /// End all calls and close the screen.
  Future<void> _hangUpAll() async {
    _hangingUp = true;
    // End every line via CallStateService
    final cs = CallStateService.instance;
    for (final line in List<CallLine>.from(cs.allLines)) {
      final convId = line.conversationId;
      if (convId != null) {
        try { sl<MessengerRemoteDataSource>().sendCallEnded(convId, line.roomName); } catch (_) {}
        try { sl<DioClient>().post('/messenger/call-ended', data: {'conversationId': convId, 'roomName': line.roomName}, fromJson: (d) => d); } catch (_) {}
      }
    }
    await cs.endCall();
    _room = null;
    _navigatedAway = true;
    // Release audio & navigate
    try { await _audioChannel.invokeMethod('abandonAudioFocus'); } catch (_) {}
    try { await _audioChannel.invokeMethod('deactivateAudioSession'); } catch (_) {}
    try { await FlutterCallkitIncoming.endAllCalls(); } catch (_) {}
    if (!mounted) return;
    try {
      if (context.canPop()) { context.pop(); } else { context.go(RouteConstants.messenger); }
    } catch (_) {}
  }

  Future<void> _hangUp() async {
    if (_hangingUp) return;
    _hangingUp = true;
    final cs = CallStateService.instance;
    debugPrint('[VoiceCall] _hangUp() called, _room=${_room != null}, _roomName=$_roomName, lines=${cs.lineCount}');
    _emptyRoomTimer?.cancel();
    _stopRingback();
    // Stop in-call assistant if active
    if (_assistantActive) {
      _assistantSessionConfigured = false;
      await _assistantRecordSub?.cancel();
      _assistantRecordSub = null;
      try { await _assistantRecorder.stop(); } catch (_) {}
      try { _assistantWs?.close(); } catch (_) {}
      _assistantWs = null;
      _assistantActive = false;
      _assistantSpeaking = false;
      _assistantAudioBuffer.clear();
    }
    // Close any open consent dialog before navigating
    if (_consentDialogShowing && mounted) {
      try {
        Navigator.of(context, rootNavigator: true).pop();
      } catch (_) {}
      _consentDialogShowing = false;
    }
    // Stop recording/transcription on server BEFORE disconnecting
    final localId = _room?.localParticipant?.identity;
    if (_recordingInitiatorId == localId && (_isRecording || _transcriptionActive)) {
      _broadcastData({'type': 'recording_ended', 'initiatorId': localId});
      await _stopRecording();
    } else if (_recordingInitiatorId == localId && _consentPending) {
      _broadcastData({'type': 'recording_denied', 'initiatorId': localId});
    }
    // Disable microphone first to release audio track
    try {
      await _room?.localParticipant?.setMicrophoneEnabled(false);
      debugPrint('[VoiceCall] mic disabled');
    } catch (e) {
      debugPrint('[VoiceCall] mic disable error: $e');
    }
    // Notify the other party that the call ended
    final convId = widget.conversationId ?? cs.conversationId;
    final rName = _roomName ?? cs.roomName;
    debugPrint('[VoiceCall] sendCallEnded convId=$convId, rName=$rName');
    if (convId != null && rName != null) {
      try { sl<MessengerRemoteDataSource>().sendCallEnded(convId, rName); } catch (_) {}
      try { sl<DioClient>().post('/messenger/call-ended', data: {'conversationId': convId, 'roomName': rName}, fromJson: (d) => d); } catch (_) {}
      debugPrint('[VoiceCall] sendCallEnded sent (socket+http)');
    }
    // Remove room listeners BEFORE disconnect
    _eventsListener?.dispose();
    _eventsListener = null;
    _room?.removeListener(_onRoomChanged);
    _room = null;

    // End only this line — CallStateService will auto-switch to next held line
    if (rName != null) {
      await cs.endLine(rName);
    } else {
      cs.notifyEnded();
    }

    // If other lines remain, switch to the next active line in-place
    if (cs.isInCall && cs.activeLine != null) {
      debugPrint('[VoiceCall] other lines remain (${cs.lineCount}), switching to ${cs.activeLine!.roomName}');
      _switchToLine(cs.activeLine!);
      return;
    }

    // No more lines — full cleanup and navigate away
    _navigatedAway = true;
    try { await _audioChannel.invokeMethod('abandonAudioFocus'); } catch (_) {}
    try { await _audioChannel.invokeMethod('deactivateAudioSession'); } catch (_) {}
    try { await FlutterCallkitIncoming.endAllCalls(); } catch (_) {}
    debugPrint('[VoiceCall] audio cleanup done, navigating back...');
    if (!mounted) {
      debugPrint('[VoiceCall] NOT mounted, cannot navigate');
      return;
    }
    try {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(RouteConstants.messenger);
      }
      debugPrint('[VoiceCall] navigation done');
    } catch (e) {
      debugPrint('[VoiceCall] navigation error (ignored): $e');
    }
  }

  void _copyRoomLink() {
    final code = widget.publicCode;
    final name = _roomName;
    if (code == null && name == null) return;
    final link = code != null
        ? '${ApiConstants.baseUrl}/room/$code'
        : '${ApiConstants.baseUrl}/room/$name';
    Clipboard.setData(ClipboardData(text: link));
    if (!mounted || _navigatedAway) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.voiceLinkCopied), duration: const Duration(seconds: 2)),
    );
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
      sl<MessengerRemoteDataSource>().sendCallInvite(convId ?? '', rName, inviteeId: selected.id);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.voiceInvitationSent(selected.username != null ? "@${selected.username}" : selected.email)),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorWithMessage(e.toString())), backgroundColor: AppColors.of(context).error),
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
      await _startServerTranslator();
    } else {
      await _stopServerTranslator();
    }
    _updateTranslationTrackSubscription();
  }

  Future<void> _startServerTranslator() async {
    final roomName = _roomName;
    if (roomName == null) return;
    try {
      final client = sl<DioClient>();
      await client.post(
        '/voice/rooms/$roomName/translator/start',
        data: {},
        fromJson: (d) => d,
      );
      await _setServerLang(roomName, _preferredLang);
      debugPrint('[Translation] Server translator started for $roomName');
    } catch (e) {
      debugPrint('[Translation] Failed to start server translator: $e');
    }
  }

  Future<void> _stopServerTranslator() async {
    final roomName = _roomName;
    if (roomName == null) return;
    try {
      await sl<DioClient>().post(
        '/voice/rooms/$roomName/translator/stop',
        data: {},
        fromJson: (d) => d,
      );
      debugPrint('[Translation] Server translator stopped for $roomName');
    } catch (e) {
      debugPrint('[Translation] Failed to stop server translator: $e');
    }
  }

  String get _sourceLang {
    final locale = Localizations.localeOf(context).languageCode;
    return _translationLangs.containsKey(locale) ? locale : 'ru';
  }

  Future<void> _setServerLang(String roomName, String lang) async {
    try {
      final client = sl<DioClient>();
      await client.post(
        '/voice/rooms/$roomName/set-lang',
        data: {'lang': lang, 'sourceLang': _sourceLang},
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
          final filtered = (_translationLangs.entries.where((e) =>
            searchQuery.isEmpty ||
            e.value.toLowerCase().contains(searchQuery.toLowerCase()) ||
            e.key.toLowerCase().contains(searchQuery.toLowerCase()),
          ).toList()..sort((a, b) => a.value.compareTo(b.value)));
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
                    AppLocalizations.of(context)!.voiceTranslateTo,
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
                        hintText: AppLocalizations.of(context)!.voiceSearchLanguage,
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
                            if (_preferredLang == e.key && _translationEnabled) {
                              _toggleTranslation(false);
                              setState(() => _preferredLang = '');
                            } else {
                              _setPreferredLang(e.key);
                              if (!_translationEnabled) _toggleTranslation(true);
                            }
                          },
                        )),
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
    _callkitEndedSub?.cancel();
    _activeRoomSub?.cancel();
    _ringbackTimer?.cancel();
    _emptyRoomTimer?.cancel();
    _ringbackActive = false;
    _audioChannel.setMethodCallHandler(null);
    // Stop video effects on dispose
    try { sl<VideoEffectsService>().stopEffect(); } catch (_) {}
    WakelockPlus.disable();
    _eventsListener?.dispose();
    _room?.removeListener(_onRoomChanged);
    _ringPlayer.dispose();
    _holdPlayer.stop().catchError((_) {});
    _holdPlayer.dispose();
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
        title: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return Text(
              _currentCalleeName ?? widget.calleeName ??
              (widget.publicCode != null && _publicRoomCreatorName != null
                  ? l10n.voiceRoomWithCreator(_publicRoomCreatorName!)
                  : l10n.voiceVoiceCall),
              overflow: TextOverflow.ellipsis,
            );
          },
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _minimizeCall,
        ),
        automaticallyImplyLeading: false,
        actions: [
          if (_roomName != null)
            IconButton(
              icon: const Icon(Icons.link_rounded),
              onPressed: _copyRoomLink,
              tooltip: AppLocalizations.of(context)!.voiceCopyLink,
            ),
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            onPressed: _addParticipant,
            tooltip: AppLocalizations.of(context)!.voiceAddParticipant,
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildBody(),
          if (_reconnecting)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.voiceReconnecting,
                      style: const TextStyle(
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
    final avatarUrl = (widget.calleeAvatar?.isNotEmpty == true ? widget.calleeAvatar : null) ?? _calleeAvatarLoaded ?? _publicRoomCreatorAvatar;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PulsingAvatar(
            radius: 48,
            glowColor: rainbowColorFor(widget.roomName ?? name ?? 'caller'),
            child: CircleAvatar(
              radius: 48,
              backgroundColor: colors.primary.withValues(alpha: 0.15),
              backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                  ? NetworkImage(avatarUrl)
                  : null,
              child: (avatarUrl == null || avatarUrl.isEmpty)
                  ? (name != null && name.isNotEmpty
                      ? Text(
                          name[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        )
                      : Icon(Icons.person_rounded, size: 48, color: colors.primary))
                  : null,
            ),
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

  Future<void> _switchLine(String targetRoomName) async {
    if (targetRoomName == _roomName) return;
    // Save current mute state
    final cs = CallStateService.instance;
    final oldLine = cs.allLines.where((l) => l.roomName == _roomName).firstOrNull;
    if (oldLine != null) oldLine.wasMuted = _muted;
    await cs.holdAndSwitch(targetRoomName);
    final line = cs.activeLine;
    if (line != null) _switchToLine(line);
  }

  Widget _buildLineSwitcher() {
    final cs = CallStateService.instance;
    final lines = cs.allLines;
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: colors.card,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: lines.map((line) {
            final isActive = line.roomName == _roomName;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: isActive ? null : () => _switchLine(line.roomName),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive
                        ? colors.primary.withValues(alpha: 0.15)
                        : colors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive ? colors.primary : colors.textSecondary.withValues(alpha: 0.3),
                      width: isActive ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green : Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        line.calleeName ?? line.roomName.substring(0, 8),
                        style: TextStyle(
                          color: isActive ? colors.primary : colors.textSecondary,
                          fontSize: 13,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      if (!isActive) ...[
                        const SizedBox(width: 6),
                        Text(
                          l10n.voiceOnHold,
                          style: TextStyle(
                            color: colors.textSecondary.withValues(alpha: 0.6),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_connecting) {
      final l10n = AppLocalizations.of(context)!;
      final statusText = widget.publicCode != null && _publicRoomCreatorName != null
          ? l10n.voiceRoomWithCreator(_publicRoomCreatorName!)
          : l10n.voiceConnecting;
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
                AppLocalizations.of(context)!.voiceConnectionError,
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
                child: Text(AppLocalizations.of(context)!.voiceClose),
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
                  color: (_isRecording || (_consentPending && !_consentForTranscription)) ? Colors.red
                      : (_transcriptionActive || (_consentPending && _consentForTranscription)) ? const Color(0xFF10B981)
                      : Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _ringing ? AppLocalizations.of(context)!.voiceCalling : AppLocalizations.of(context)!.voiceCallActive,
                style: TextStyle(
                  color: AppColors.of(context).textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (_isRecording || (_consentPending && !_consentForTranscription)) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6, height: 6,
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        (_consentPending && !_consentForTranscription) ? AppLocalizations.of(context)!.voiceWaitingUpper : AppLocalizations.of(context)!.voiceRec,
                        style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
              if (_transcriptionActive || (_consentPending && _consentForTranscription)) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6, height: 6,
                        decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        (_consentPending && _consentForTranscription) ? AppLocalizations.of(context)!.voiceWaitingUpper : AppLocalizations.of(context)!.voiceRec,
                        style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        // Line switcher chips (visible only when multiple lines are active)
        if (CallStateService.instance.lineCount > 1)
          _buildLineSwitcher(),
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
        // Self is now shown as a circular avatar in _buildParticipantsList
        // Controls — two rows for small screens (hidden in fullscreen screen share)
        if (!_screenShareFullscreen)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Secondary row: Record, AI Record, Translate, Audio Output, [Flip Camera], [Bg]
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ControlButton(
                    icon: (_isRecording || _transcriptionActive || (_consentPending && !_consentForTranscription))
                        ? Icons.stop_circle_rounded
                        : Icons.fiber_manual_record_rounded,
                    label: (_consentPending && !_consentForTranscription) ? AppLocalizations.of(context)!.voiceWaiting : ((_isRecording || _transcriptionActive) ? AppLocalizations.of(context)!.voiceStop : AppLocalizations.of(context)!.voiceRecord),
                    color: (_isRecording || _transcriptionActive || (_consentPending && !_consentForTranscription))
                        ? Colors.red.withValues(alpha: 0.2)
                        : AppColors.of(context).card,
                    iconColor: (_isRecording || _transcriptionActive || (_consentPending && !_consentForTranscription)) ? Colors.red : null,
                    onTap: ((_consentPending && _consentForTranscription) ||
                            ((_isRecording || _transcriptionActive || _recordingApproved) && _recordingInitiatorId != _room?.localParticipant?.identity))
                        ? null
                        : () => _toggleRecordingWithConsent(),
                  ),
                  // Протокол кнопка убрана — запись и протокол объединены
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _ControlButton(
                        icon: Icons.translate_rounded,
                        label: _translationEnabled
                            ? _preferredLang.toUpperCase()
                            : AppLocalizations.of(context)!.voiceTranslation,
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
                    label: _outputLabels(AppLocalizations.of(context)!)[_audioOutputType] ?? AppLocalizations.of(context)!.voiceAudio,
                    color: _audioOutputType != 'earpiece'
                        ? AppColors.of(context).primary.withValues(alpha: 0.2)
                        : AppColors.of(context).card,
                    onTap: _showAudioOutputPicker,
                  ),
                  if (_cameraOn) ...[
                    _ControlButton(
                      icon: Icons.flip_camera_ios_rounded,
                      label: AppLocalizations.of(context)!.voiceFlipCamera,
                      color: AppColors.of(context).card,
                      onTap: _flipCamera,
                    ),
                    if (_videoEffectsSupported)
                    _ControlButton(
                      icon: Icons.blur_on_rounded,
                      label: AppLocalizations.of(context)!.voiceBackground,
                      color: sl<VideoEffectsService>().current != VideoEffect.none
                          ? AppColors.of(context).primary.withValues(alpha: 0.2)
                          : AppColors.of(context).card,
                      onTap: _showVideoEffectsPicker,
                    ),
                  ],
                ],
              ),
              ),
              const SizedBox(height: 12),
              // Assistant active indicator
              if (_assistantActive)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.of(context).primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.of(context).primary.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.smart_toy_rounded, size: 16, color: AppColors.of(context).primary),
                        const SizedBox(width: 6),
                        Text(
                          _assistantSpeaking ? AppLocalizations.of(context)!.voiceAssistantSpeakingStatus : AppLocalizations.of(context)!.voiceAssistantListeningStatus,
                          style: TextStyle(color: AppColors.of(context).primary, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              // Controls: secondary row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ControlButton(
                    icon: _muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    label: _muted ? AppLocalizations.of(context)!.voiceUnmute : AppLocalizations.of(context)!.voiceMic,
                    color: _muted ? AppColors.of(context).error : AppColors.of(context).card,
                    onTap: _assistantActive ? null : _toggleMute,
                  ),
                  _ControlButton(
                    icon: Icons.smart_toy_rounded,
                    label: _assistantActive ? AppLocalizations.of(context)!.voiceStop : AppLocalizations.of(context)!.voiceAssistantLabel,
                    color: _assistantActive ? AppColors.of(context).primary : AppColors.of(context).card,
                    onTap: _assistantActive ? _stopAssistant : _startAssistant,
                  ),
                  _ControlButton(
                    icon: _cameraOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                    label: _cameraOn ? AppLocalizations.of(context)!.voiceCameraOn : AppLocalizations.of(context)!.voiceCameraLabel,
                    color: _cameraOn ? AppColors.of(context).primary.withValues(alpha: 0.2) : AppColors.of(context).card,
                    onTap: _toggleCamera,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // End call button — centered.
              // Long-press shows menu to end all calls when multiple lines are active.
              Center(
                child: GestureDetector(
                  onLongPress: CallStateService.instance.lineCount > 1 ? () {
                    final l10n = AppLocalizations.of(context)!;
                    final colors = AppColors.of(context);
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: colors.card,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      builder: (ctx) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 8),
                            Container(
                              width: 40, height: 4,
                              decoration: BoxDecoration(
                                color: colors.textSecondary.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ListTile(
                              leading: Icon(Icons.call_end_rounded, color: colors.error),
                              title: Text(l10n.voiceEndThisCall, style: TextStyle(color: colors.textPrimary)),
                              onTap: () { Navigator.pop(ctx); _hangUp(); },
                            ),
                            ListTile(
                              leading: Icon(Icons.call_end_rounded, color: colors.error),
                              title: Text(l10n.voiceEndAllCalls, style: TextStyle(color: colors.error, fontWeight: FontWeight.w600)),
                              onTap: () { Navigator.pop(ctx); _hangUpAll(); },
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    );
                  } : null,
                  child: _ControlButton(
                    icon: Icons.call_end_rounded,
                    label: AppLocalizations.of(context)!.voiceEndCall,
                    color: AppColors.of(context).error,
                    onTap: _hangUp,
                    large: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Fetch avatar URL for a participant by their identity (user ID).
  /// Load callee avatar from conversation participants when calleeAvatar is not passed.
  /// Load callee avatar by fetching their profile.
  Future<void> _loadCalleeAvatar() async {
    String? targetUserId = widget.calleeId;

    // If calleeId not passed, find it from conversation participants
    if ((targetUserId == null || targetUserId.isEmpty) && widget.conversationId != null) {
      try {
        final myId = await sl<SecureStorageService>().getUserId();
        final convs = await sl<DioClient>().get<List<dynamic>>(
          '/messenger/conversations',
          fromJson: (d) => (d as List),
        );
        final conv = convs.cast<Map<String, dynamic>>().where((c) => c['id'] == widget.conversationId).firstOrNull;
        if (conv != null) {
          // Try otherUserId first
          final otherId = conv['otherUserId'] as String?;
          if (otherId != null && otherId.isNotEmpty) {
            targetUserId = otherId;
          } else if (myId != null) {
            // Fallback: find other participant from participantIds
            final pIds = (conv['participantIds'] as List?)?.cast<String>() ?? [];
            targetUserId = pIds.where((id) => id != myId).firstOrNull;
          }
          // Also check if conversation already has avatar
          final otherAvatar = conv['otherUserAvatar'] as String?;
          if (otherAvatar != null && otherAvatar.isNotEmpty && mounted) {
            setState(() => _calleeAvatarLoaded = otherAvatar);
            return;
          }
        }
      } catch (e) {
        debugPrint('[VoiceCall] Error getting conversation: $e');
      }
    }

    if (targetUserId == null || targetUserId.isEmpty) return;
    try {
      final res = await sl<DioClient>().get<Map<String, dynamic>>(
        '/profile/$targetUserId',
        fromJson: (d) => Map<String, dynamic>.from(d as Map),
      );
      final avatarUrl = res['avatarUrl'] as String?;
      if (avatarUrl != null && avatarUrl.isNotEmpty && mounted) {
        setState(() {
          _calleeAvatarLoaded = avatarUrl;
          _participantAvatars[targetUserId!] = avatarUrl;
        });
      }
    } catch (e) {
      debugPrint('[VoiceCall] Error loading callee avatar: $e');
    }
  }

  Future<void> _fetchParticipantAvatar(String identity) async {
    if (_participantAvatars.containsKey(identity)) return;
    if (identity == 'ai-assistant' || identity == 'meeting-recorder' || identity == 'voice-translator') return;
    try {
      debugPrint('[VoiceCall] Fetching avatar for identity: $identity');
      final res = await sl<DioClient>().get<Map<String, dynamic>>(
        '/profile/$identity',
        fromJson: (d) => Map<String, dynamic>.from(d as Map),
      );
      debugPrint('[VoiceCall] Profile response for $identity: $res');
      final avatarUrl = res['avatarUrl'] as String?;
      if (avatarUrl != null && avatarUrl.isNotEmpty && mounted) {
        debugPrint('[VoiceCall] Setting avatar for $identity: $avatarUrl');
        setState(() => _participantAvatars[identity] = avatarUrl);
      } else {
        debugPrint('[VoiceCall] No avatar in response for $identity');
      }
    } catch (e) {
      debugPrint('[VoiceCall] Error fetching avatar for $identity: $e');
    }
  }

  String? _myAvatarUrl;

  /// Get current user's avatar URL from ProfileBloc, CacheService, or loaded value.
  String? _getMyAvatarUrl() {
    if (_myAvatarUrl != null) return _myAvatarUrl;
    // Try ProfileBloc
    try {
      final pState = context.read<ProfileBloc>().state;
      if (pState is ProfileLoaded) {
        _myAvatarUrl = pState.user.avatarUrl;
        return _myAvatarUrl;
      }
    } catch (_) {}
    // Try CacheService
    try {
      final cached = sl<CacheService>().getProfile();
      if (cached != null) {
        _myAvatarUrl = cached['avatarUrl'] as String?;
        return _myAvatarUrl;
      }
    } catch (_) {}
    return null;
  }

  /// Load my avatar from API if not available from cache/bloc.
  Future<void> _loadMyAvatar() async {
    if (_getMyAvatarUrl() != null) return;
    try {
      final res = await sl<DioClient>().get<Map<String, dynamic>>(
        '/profile',
        fromJson: (d) => Map<String, dynamic>.from(d as Map),
      );
      final avatarUrl = res['avatarUrl'] as String?;
      if (avatarUrl != null && avatarUrl.isNotEmpty && mounted) {
        setState(() => _myAvatarUrl = avatarUrl);
      }
    } catch (_) {}
  }

  Widget _buildParticipantsList() {
    if (_participants.isEmpty) {
      return _ringing
          ? _buildOutgoingCallCenter(statusText: AppLocalizations.of(context)!.voiceCalling)
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_outline, size: 64, color: AppColors.of(context).textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.voiceWaitingParticipants,
                    style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 16),
                  ),
                ],
              ),
            );
    }

    final colors = AppColors.of(context);
    final totalCount = _participants.where((p) => p.identity != 'voice-translator').length + 1; // +1 for self
    final avatarRadius = totalCount <= 2 ? 48.0 : 36.0;
    final fontSize = totalCount <= 2 ? 32.0 : 24.0;
    final myAvatarUrl = _getMyAvatarUrl();
    final myName = _room?.localParticipant?.name ?? '';
    final myIdentity = _room?.localParticipant?.identity ?? '';
    final mySpeaking = _speakingIdentities.contains(myIdentity);

    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 24,
        runSpacing: 24,
        children: [
          // Local user (self)
          _buildParticipantAvatar(
            identity: myIdentity,
            displayName: myName.isNotEmpty ? myName : AppLocalizations.of(context)!.voiceYou,
            avatarUrl: myAvatarUrl,
            avatarRadius: avatarRadius,
            fontSize: fontSize,
            hasMic: !_muted,
            isSpeaking: mySpeaking,
            isLocal: true,
            colors: colors,
          ),
          // Remote participants
          ..._participants
              .where((p) => p.identity != 'voice-translator' && p.identity != 'hold-music')
              .map((p) {
            final isAI = p.identity == 'ai-assistant';
            final isRecorder = p.identity == 'meeting-recorder';
            final hasMic = _participantHasMic(p);
            final speaking = _speakingIdentities.contains(p.identity);
            final l10n = AppLocalizations.of(context)!;
            final displayName = isAI
                ? l10n.voiceAiAssistant
                : isRecorder
                    ? l10n.voiceRecord
                    : (p.name?.isNotEmpty == true ? p.name! : p.identity);
            // Get avatar from fetched avatars or calleeAvatar fallback
            String? avatarUrl = _participantAvatars[p.identity];
            // For callee in 1-on-1 calls, use the calleeAvatar passed via route
            if (avatarUrl == null && !isAI && !isRecorder && _participants.where((pp) => pp.identity != 'voice-translator' && pp.identity != 'meeting-recorder' && pp.identity != 'ai-assistant').length == 1) {
              avatarUrl = (widget.calleeAvatar?.isNotEmpty == true ? widget.calleeAvatar : null) ?? _calleeAvatarLoaded;
            }

            return _buildParticipantAvatar(
              identity: p.identity,
              displayName: displayName,
              avatarUrl: avatarUrl,
              avatarRadius: avatarRadius,
              fontSize: fontSize,
              hasMic: hasMic,
              isSpeaking: speaking,
              isAI: isAI,
              isRecorder: isRecorder,
              colors: colors,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildParticipantAvatar({
    required String identity,
    required String displayName,
    String? avatarUrl,
    required double avatarRadius,
    required double fontSize,
    required bool hasMic,
    required bool isSpeaking,
    bool isAI = false,
    bool isRecorder = false,
    bool isLocal = false,
    required AppColorsExtension colors,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            PulsingAvatar(
              radius: avatarRadius,
              glowColor: isRecorder ? Colors.red : isAI ? colors.primary : rainbowColorFor(identity),
              isSpeaking: isSpeaking,
              child: CircleAvatar(
                radius: avatarRadius,
                backgroundColor: isRecorder
                    ? Colors.red.withValues(alpha: 0.15)
                    : isAI
                        ? colors.primary
                        : colors.surface,
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty && !isAI && !isRecorder
                    ? NetworkImage(avatarUrl)
                    : null,
                child: (avatarUrl == null || avatarUrl.isEmpty || isAI || isRecorder)
                    ? isRecorder
                        ? Icon(Icons.fiber_manual_record_rounded, color: Colors.red, size: fontSize)
                        : isAI
                            ? Icon(Icons.smart_toy_rounded, color: Colors.black, size: fontSize)
                            : Text(
                                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: colors.textPrimary),
                              )
                    : null,
              ),
            ),
            // Mic indicator
            if (!isRecorder)
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: hasMic ? Colors.green : colors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.background, width: 2),
                  ),
                  child: Icon(
                    hasMic ? Icons.mic_rounded : Icons.mic_off_rounded,
                    size: 14,
                    color: hasMic ? Colors.white : colors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          isLocal ? AppLocalizations.of(context)!.voiceYou : displayName,
          style: TextStyle(
            color: isRecorder ? Colors.red : colors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
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
      if (p.identity == 'voice-translator' || p.identity == 'hold-music') continue;
      final track = p.videoTrackPublications
          .firstWhereOrNull((pub) =>
              pub.subscribed &&
              pub.track != null &&
              pub.source != lk.TrackSource.screenShareVideo)
          ?.track as lk.VideoTrack?;
      final isAI = p.identity == 'ai-assistant';
      final isRecorder = p.identity == 'meeting-recorder';
      final l10n = AppLocalizations.of(context)!;
      final name = isAI
          ? l10n.voiceAiAssistant
          : isRecorder
              ? l10n.voiceRecord
              : (p.name?.isNotEmpty == true ? p.name! : p.identity);
      tiles.add(_VideoTileData(name: name, identity: p.identity, track: track, hasMic: _participantHasMic(p), isLocal: false, isAI: isAI, isRecorder: isRecorder, isSpeaking: _speakingIdentities.contains(p.identity)));
    }
    // Add local
    final localIdentity = _room?.localParticipant?.identity ?? '';
    if (_cameraOn) {
      final localTrack = (_room?.localParticipant?.videoTrackPublications ?? [])
          .firstWhereOrNull((p) => p.track != null)?.track;
      tiles.add(_VideoTileData(
        name: _room?.localParticipant?.name ?? '',
        identity: localIdentity,
        track: localTrack as lk.VideoTrack?,
        hasMic: !_muted,
        isLocal: true,
        isAI: false,
        isSpeaking: _speakingIdentities.contains(localIdentity),
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
                    lk.VideoTrackRenderer(tile.track!, fit: rtc.RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)
                  else
                    Center(
                      child: PulsingAvatar(
                        radius: 20,
                        glowColor: tile.isAI ? AppColors.of(context).primary : rainbowColorFor(tile.identity.isNotEmpty ? tile.identity : tile.name),
                        isSpeaking: tile.isSpeaking,
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.of(context).card,
                          child: Text(
                            tile.name.isNotEmpty ? tile.name[0].toUpperCase() : '?',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.of(context).textPrimary),
                          ),
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
                        tile.isLocal ? AppLocalizations.of(context)!.voiceYou : tile.name,
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
      if (p.identity == 'voice-translator' || p.identity == 'hold-music') continue;
      // Pick camera track only (skip screen share tracks)
      final track = p.videoTrackPublications
          .firstWhereOrNull((pub) =>
              pub.subscribed &&
              pub.track != null &&
              pub.source != lk.TrackSource.screenShareVideo)
          ?.track as lk.VideoTrack?;
      final isAI = p.identity == 'ai-assistant';
      final isRecorder = p.identity == 'meeting-recorder';
      final l10n = AppLocalizations.of(context)!;
      final name = isAI
          ? l10n.voiceAiAssistant
          : isRecorder
              ? l10n.voiceRecord
              : (p.name?.isNotEmpty == true ? p.name! : p.identity);
      final hasMic = _participantHasMic(p);
      tiles.add(_VideoTileData(
        name: name,
        identity: p.identity,
        track: track,
        hasMic: hasMic,
        isLocal: false,
        isAI: isAI,
        isRecorder: isRecorder,
        isSpeaking: _speakingIdentities.contains(p.identity),
      ));
    }

    // Add local participant — only when camera is on (no avatar placeholder when camera off)
    final localIdentity = _room?.localParticipant?.identity ?? '';
    if (_cameraOn) {
      tiles.add(_VideoTileData(
        name: localName,
        identity: localIdentity,
        track: localTrack as lk.VideoTrack?,
        hasMic: !_muted,
        isLocal: true,
        isAI: false,
        isSpeaking: _speakingIdentities.contains(localIdentity),
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
              Text(AppLocalizations.of(context)!.voiceVideoUnavailable, style: TextStyle(color: Colors.white54, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    // Grid layout: adapt columns based on tile count
    final count = tiles.length;
    final crossAxisCount = count <= 1 ? 1 : count <= 4 ? 2 : 3;

    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final aspectRatio = isLandscape
        ? (count <= 2 ? 4 / 3 : 4 / 3)
        : (count <= 2 ? 3 / 4 : 3 / 4);

    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: aspectRatio,
      ),
      itemCount: count,
      itemBuilder: (_, i) {
        final tile = tiles[i];
        final speakingColor = tile.isRecorder ? Colors.red : tile.isAI ? AppColors.of(context).primary : rainbowColorFor(tile.identity.isNotEmpty ? tile.identity : tile.name);
        return GestureDetector(
          onTap: tile.isLocal ? _flipCamera : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: tile.isSpeaking && tile.track != null
                  ? Border.all(color: speakingColor, width: 3)
                  : null,
            ),
            child: ClipRRect(
            borderRadius: BorderRadius.circular(tile.isSpeaking && tile.track != null ? 9 : 12),
            child: Container(
              color: AppColors.of(context).surface,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Video or avatar
                  if (tile.track != null)
                    lk.VideoTrackRenderer(tile.track!, fit: rtc.RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)
                  else
                    Center(
                      child: PulsingAvatar(
                        radius: count <= 2 ? 40 : 28,
                        glowColor: tile.isRecorder ? Colors.red : tile.isAI ? AppColors.of(context).primary : rainbowColorFor(tile.identity.isNotEmpty ? tile.identity : tile.name),
                        isSpeaking: tile.isSpeaking,
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
          ),
        );
      },
    );
  }
}

class _VideoTileData {
  final String name;
  final String identity;
  final lk.VideoTrack? track;
  final bool hasMic;
  final bool isLocal;
  final bool isAI;
  final bool isRecorder;
  final bool isSpeaking;

  const _VideoTileData({
    required this.name,
    this.identity = '',
    required this.track,
    required this.hasMic,
    required this.isLocal,
    required this.isAI,
    this.isRecorder = false,
    this.isSpeaking = false,
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
            AppLocalizations.of(context)!.voiceAddParticipant,
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
                hintText: AppLocalizations.of(context)!.voiceSearchNickname,
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

class _ConsentEntry {
  final String name;
  bool? accepted; // null = waiting
  _ConsentEntry(this.name, {this.accepted});
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool large;
  final Color? iconColor;
  final bool active;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.large = false,
    this.iconColor,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    // A button is "neutral" (card-background) whenever its color matches the
    // theme's card surface — this happens in both light (white) and dark
    // (navy) themes. Neutral buttons get a subtle surface, not a gradient.
    final isNeutral = color.value == appColors.card.value ||
        color.opacity < 0.9;
    final isColoredAction = !isNeutral;
    final resolvedIconColor = iconColor ?? (isNeutral
        ? appColors.primary
        : (color.computeLuminance() > 0.4
            ? appColors.textPrimary
            : Colors.white));
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: large ? 72 : 56,
            height: large ? 72 : 56,
            decoration: BoxDecoration(
              gradient: isColoredAction
                  ? RadialGradient(
                      center: const Alignment(-0.3, -0.4),
                      radius: 1.1,
                      colors: [
                        Color.lerp(color, Colors.white, 0.18)!,
                        color,
                        Color.lerp(color, Colors.black, 0.3)!,
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    )
                  : null,
              color: isColoredAction ? null : color,
              shape: BoxShape.circle,
              border: active
                  ? Border.all(color: Colors.white, width: 2.5)
                  : (isNeutral
                      ? Border.all(
                          color: appColors.primary.withValues(alpha: 0.2),
                          width: 1,
                        )
                      : null),
              boxShadow: isColoredAction
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: large ? 22 : 14,
                        spreadRadius: large ? 2 : 0,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: appColors.primary.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),
            child: Icon(
              icon,
              color: onTap == null
                  ? appColors.textSecondary.withValues(alpha: 0.4)
                  : (isColoredAction ? Colors.white : resolvedIconColor),
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
